from . import BridgePanel
from . import MeshyIcon
import bpy

modules = (
    MeshyIcon,
    BridgePanel,
)

def register():
    for module in modules:
        module.register()


def unregister():
    for module in reversed(modules):
        module.unregister()