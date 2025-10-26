import json
import os
import bpy
import zipfile
from bpy.props import BoolProperty, IntProperty
from bpy.types import Context
import requests
from pathlib import Path
from threading import Thread
from queue import Queue, Empty
import socketserver
from http.server import BaseHTTPRequestHandler
from time import sleep
from typing import TypedDict
from .Utils import logger
from .MeshyIcon import get_meshy_icon
import shutil

# global variables
_server_stop = False
queue: "Queue[MeshTransfer]" = Queue()


class MeshTransfer(TypedDict):
    file_format: str
    path: str


class MeshyBridgeProps(bpy.types.PropertyGroup):
    bridge_running: BoolProperty(default=False)  # type: ignore


class BaseClass:
    @staticmethod
    def get_props() -> MeshyBridgeProps:
        return getattr(bpy.context.window_manager, "meshy_bridge_props")  # type: ignore


class BlenderMinimalServer(BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        origin = self.headers.get("Origin", "")

        allowed_origins = [
            "https://www.meshy.ai",
            "https://app-staging.meshy.ai",
            "http://localhost:3700",
        ]
        if origin in allowed_origins:
            self.send_header("Access-Control-Allow-Origin", origin)
        else:
            self.send_header("Access-Control-Allow-Origin", "https://www.meshy.ai")

        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")  # Allow any header
        self.send_header("Access-Control-Max-Age", "86400")  # 24 hours

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self):

        if self.path == "/status" or self.path == "/ping":
            self.send_response(200)
            self._send_cors_headers()
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(
                json.dumps(
                    {
                        "status": "ok",
                        "dcc": "blender",
                        "version": bpy.app.version_string,
                    }
                ).encode()
            )
        else:
            self.send_response(404)
            self._send_cors_headers()
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"status": "path not found"}')

    def do_POST(self):
        """Handle POST requests with URLs."""
        logger.info(f"POST request received: {self.path}")

        if self.path == "/import":
            try:
                # 读取请求内容
                content_length = int(self.headers.get("Content-Length", 0))
                logger.info(f"Reading content length: {content_length}")
                chunks = []
                remaining = content_length
                while remaining > 0:
                    chunk_size = min(remaining, 1024)
                    chunk = self.rfile.read(chunk_size)
                    if not chunk:
                        break
                    chunks.append(chunk)
                    remaining -= len(chunk)

                body = b"".join(chunks).decode("utf-8")
                data = json.loads(body)
                
                model_url = data.get("url")
                model_name = data.get("name", "Meshy_Model")
                
                if not model_url:
                    raise ValueError("No model URL provided")

                logger.info(f"Initiating download from {model_url}")
                response = requests.get(model_url, stream=True)
                response.raise_for_status()

                temp_file_path = os.path.join(bpy.app.tempdir, "bridge_model_temp")
                file_size = int(response.headers.get("content-length", 0))
                downloaded_size = 0

                with open(temp_file_path, "wb") as f:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            downloaded_size += len(chunk)
                            if file_size:
                                print(f"Download progress: {(downloaded_size / file_size) * 100:.1f}%")

                print(f"Download complete: {temp_file_path}")
                
                file_format = "unknown"
                try:
                    with open(temp_file_path, "rb") as f:
                        if f.read(4) == b'PK\x03\x04':
                            file_format = "zip"
                        else:
                            f.seek(0)
                            if f.read(4) == b'glTF':
                                file_format = "glb"
                except Exception as e:
                    logger.error(f"Error detecting file format: {str(e)}")
                    
                if file_format == "unknown":
                    file_format = "zip"
                    logger.warning("Could not detect file format, defaulting to zip")
                    
                logger.info(f"Detected file format: {file_format}")
                
                final_file_path = os.path.join(bpy.app.tempdir, f"bridge_model.{file_format}")
                if os.path.exists(final_file_path):
                    os.remove(final_file_path)
                os.rename(temp_file_path, final_file_path)
                
                mesh_transfer = {
                    "file_format": file_format,
                    "path": final_file_path,
                    "name": model_name,
                }
                queue.put(mesh_transfer, block=False)

                self.send_response(200)
                self._send_cors_headers()
                self.send_header("Content-type", "application/json")
                self.end_headers()
                self.wfile.write(
                    json.dumps(
                        {"status": "ok", "message": f"File queued for import as {file_format}"}
                    ).encode()
                )

            except Exception as e:
                logger.error(f"Error: {str(e)}")
                import traceback
                traceback.print_exc()
                self.send_error_response(str(e))
        else:
            self.send_response(404)
            self._send_cors_headers()
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"status": "path not found"}')


def guard_job(server: socketserver.TCPServer):
    global _server_stop

    while not _server_stop:
        sleep(0.2)

    server.shutdown()
    logger.info("joining guard")


def run_server():
    with socketserver.TCPServer(("", 5324), BlenderMinimalServer) as server:
        guard = Thread(target=guard_job, args=[server])
        guard.start()

        logger.info("[ Bridge ] listening on port 5324")
        server.serve_forever()

        server.server_close()
    logger.info("joining server")


class MeshyBridgeStopOperator(bpy.types.Operator):
    bl_idname = "meshy.bridge_stop"
    bl_label = "Stop Bridge"
    bl_description = "Stops the Meshy Bridge server"
    bl_options = {"REGISTER"}

    def execute(self, context: Context | None):
        props = getattr(context.window_manager, "meshy_bridge_props")
        props.bridge_running = False

        # kill the server
        global _server_stop
        _server_stop = True
        return {"FINISHED"}


class MeshyBridgeStartOperator(bpy.types.Operator):
    bl_idname = "meshy.bridge_start"
    bl_label = "Start Bridge"
    bl_description = "Starts the Meshy Bridge server"
    bl_options = {"REGISTER"}

    props: MeshyBridgeProps
    _timer = None

    def import_glb(self, path: str, name: str):
        bpy.ops.import_scene.gltf(
            filepath=path,
            bone_heuristic="FORTUNE",
        )

        # Merge vertices by distance
        # 只对 mesh 类型做操作
        active_obj = bpy.context.view_layer.objects.active
        if active_obj and active_obj.type == "MESH":
            bpy.ops.object.mode_set(mode="EDIT")
            bpy.ops.mesh.select_all(action="SELECT")
            bpy.ops.mesh.remove_doubles()
            bpy.ops.object.mode_set(mode="OBJECT")

        # rename active object to the name of the model
        old_name = bpy.context.view_layer.objects.active.name
        new_name = f"Meshy_{name}_{old_name}" if name else f"Meshy_{old_name}"
        bpy.context.view_layer.objects.active.name = new_name

        # check active object material, if not, create a material that display color attribute
        active_object = bpy.context.view_layer.objects.active
        if active_object.type == "MESH" and len(active_object.material_slots) == 0:
            material = bpy.data.materials.new("Meshy_Material")
            active_object.data.materials.append(material)
            material.use_nodes = True
            bsdf_node = None
            for node in material.node_tree.nodes:
                if node.type == "BSDF_PRINCIPLED":
                    bsdf_node = node
                    break
            attribute_node = material.node_tree.nodes.new(type="ShaderNodeAttribute")
            attribute_node.attribute_name = "Color"
            material.node_tree.links.new(
                attribute_node.outputs["Color"],
                bsdf_node.inputs["Base Color"],
            )

    def process_mesh_transfer(self, transfer: MeshTransfer):
        logger.info(f"Processing mesh transfer: {transfer}")
        try:
            match transfer["file_format"]:
                case "glb":
                    self.import_glb(transfer["path"], transfer["name"])
                case "zip":
                    # unzip the file to zip_glb_dir
                    zip_dir = os.path.join(bpy.app.tempdir, "zip")
                    # mkdir if not exists
                    os.makedirs(zip_dir, exist_ok=True)
                    print(f"Unzipping {transfer['path']} to {zip_dir}")
                    with zipfile.ZipFile(transfer["path"], "r") as zip_ref:
                        zip_ref.extractall(zip_dir)
                    
                    # 查找并打印所有解压的文件（调试用）
                    print("解压文件列表:")
                    for root, dirs, files in os.walk(zip_dir):
                        for file in files:
                            print(f" - {os.path.join(root, file)}")
                    
                    # import first glb file in zip_dir, recursively
                    glb_found = False
                    for root, dirs, files in os.walk(zip_dir):
                        for file in files:
                            if file.endswith(".glb"):
                                glb_path = os.path.join(root, file)
                                print(f"找到GLB文件: {glb_path}")
                                try:
                                    self.import_glb(glb_path, transfer["name"])
                                    glb_found = True
                                    print("GLB导入成功")
                                except Exception as e:
                                    print(f"GLB导入失败: {str(e)}")
                                break
                        if glb_found:
                            break
                    
                    if not glb_found:
                        print("ZIP中未找到GLB文件")
                    
                    # 使用shutil安全删除目录
                    try:
                        print(f"清理解压目录: {zip_dir}")
                        shutil.rmtree(zip_dir, ignore_errors=True)
                        print("清理完成")
                    except Exception as e:
                        print(f"清理目录时出错: {str(e)}")

                case _:
                    logger.info(f"Unsupported format: {transfer['file_format']}")
        except Exception as e:
            logger.error(f"Error processing mesh: {str(e)}")
        finally:
            # Clean up the temp file
            try:
                if os.path.exists(transfer["path"]):
                    os.remove(transfer["path"])
            except Exception as e:
                logger.error(f"Error cleaning up: {str(e)}")

    def modal(self, context, event):
        if event.type in {"ESC"}:
            self.cancel(context)
            return {"CANCELLED"}

        if event.type == "TIMER":
            if self.props.bridge_running:
                try:
                    # Check queue size
                    qsize = queue.qsize()
                    if qsize > 0:
                        print(f"Queue size: {qsize}")

                    while True:
                        try:
                            item = queue.get(block=False)
                            print(f"Got item from queue: {item}")
                            self.process_mesh_transfer(item)
                            queue.task_done()
                        except Empty:
                            break
                except Exception as e:
                    print(f"Error in modal timer: {str(e)}")
            else:
                print("Bridge not running, cancelling...")
                self.cancel(context)
                return {"CANCELLED"}

        return {"PASS_THROUGH"}

    def execute(self, context):
        global _server_stop

        print("Starting bridge...")
        self.props = getattr(context.window_manager, "meshy_bridge_props")

        self.props.bridge_running = True
        _server_stop = False

        self.thread = Thread(target=run_server, daemon=True)
        self.thread.start()

        print("Server thread started")

        assert context
        wm = context.window_manager
        self._timer = wm.event_timer_add(0.1, window=context.window)
        wm.modal_handler_add(self)

        return {"RUNNING_MODAL"}

    def cancel(self, context):
        global _server_stop

        _server_stop = True
        try:
            self.thread.join()

            if self.thread.is_alive():
                raise Exception("Thread still alive")
        except Exception as e:
            logger.error(f"Error during shutdown: {str(e)}")

        assert context
        wm = context.window_manager
        wm.event_timer_remove(self._timer)


class MeshyBridgePanel(bpy.types.Panel):
    bl_idname = "MESHY_PT_bridge"
    bl_label = "Meshy Bridge"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "Meshy"

    def draw_header_preset(self, context):
        layout = self.layout
        layout.label(text="", icon_value=get_meshy_icon())

    def draw(self, context):
        props = getattr(context.window_manager, "meshy_bridge_props")
        layout = self.layout
        col = layout.box().column(align=True)
        # col.operator("wm.url_open", text="Documentation").url = (
        #     "https://docs.meshy.ai/blender-plugin/bridge"
        # )
        if props.bridge_running:
            col.operator(
                "meshy.bridge_stop",
                text="Bridge ON",
                icon="BLENDER",
                depress=True,
            )
        else:
            col.operator("meshy.bridge_start", text="Run Bridge", icon="BLENDER")


classes = (
    MeshyBridgeProps,
    MeshyBridgeStartOperator,
    MeshyBridgeStopOperator,
)


def register():
    for cls in classes:
        bpy.utils.register_class(cls)
    bpy.utils.register_class(MeshyBridgePanel)

    bpy.types.WindowManager.meshy_bridge_props = bpy.props.PointerProperty(
        type=MeshyBridgeProps
    )


def unregister():
    for cls in reversed(classes):
        bpy.utils.unregister_class(cls)
    bpy.utils.unregister_class(MeshyBridgePanel)

    del bpy.types.WindowManager.meshy_bridge_props
