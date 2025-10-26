import os
import bpy

meshy_icon = None


def get_meshy_icon():
    return meshy_icon["meshy_icon"].icon_id


def register():
    import bpy.utils.previews

    global meshy_icon
    meshy_icon = bpy.utils.previews.new()
    my_icons_dir = os.path.join(os.path.dirname(__file__), "icons")
    meshy_icon.load(
        "meshy_icon", os.path.join(my_icons_dir, "Meshy_Icon_64.png"), "IMAGE"
    )


def unregister():
    bpy.utils.previews.remove(meshy_icon)
