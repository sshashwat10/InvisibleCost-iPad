# PASTE THIS ENTIRE SCRIPT INTO UNREAL EDITOR'S PYTHON CONSOLE
# Go to: Window > Developer Tools > Output Log
# At the bottom, click "Cmd" dropdown and select "Python"
# Then paste this entire script and press Enter

import unreal
import math
import os

print("=" * 60)
print("CREATING INVISIBLE COST ASSETS FOR VISION PRO")
print("=" * 60)

EXPORT_DIR = "/Users/shashwatshlok/Projects/InvisibleCost-VisionPro/Packages/RealityKitContent/Sources/RealityKitContent/Resources"
if not os.path.exists(EXPORT_DIR):
    os.makedirs(EXPORT_DIR)

# Get subsystem
eas = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)

# Load meshes
cube = unreal.load_asset("/Engine/BasicShapes/Cube")
sphere = unreal.load_asset("/Engine/BasicShapes/Sphere")
cylinder = unreal.load_asset("/Engine/BasicShapes/Cylinder")

def spawn(name, mesh, loc, rot=(0,0,0), scl=(1,1,1)):
    a = eas.spawn_actor_from_class(unreal.StaticMeshActor, unreal.Vector(*loc), unreal.Rotator(*rot))
    if a:
        a.set_actor_label(name)
        a.set_actor_scale3d(unreal.Vector(*scl))
        mc = a.get_component_by_class(unreal.StaticMeshComponent)
        if mc and mesh:
            mc.set_static_mesh(mesh)
        return a
    return None

# Delete old IC_ actors
for a in unreal.EditorLevelLibrary.get_all_level_actors():
    if a.get_actor_label().startswith("IC_"):
        unreal.EditorLevelLibrary.destroy_actor(a)

created = []

# Central Assembly
c = spawn("IC_Central", sphere, (0,0,200), scl=(80,80,80))
if c: created.append(c)

# Light Beam
b = spawn("IC_Beam", cylinder, (0,0,600), scl=(30,30,600))
if b: created.append(b)

# Notification Windows
for i in range(8):
    ang = i/8.0 * 2 * math.pi
    x, y = math.cos(ang)*400, math.sin(ang)*400
    w = spawn(f"IC_Window_{i+1}", cube, (x,y,200+i*20), rot=(0,math.degrees(ang)+180,0), scl=(100,60,4))
    if w: created.append(w)

# Data Particles  
for i in range(12):
    ang = i/12.0 * 2 * math.pi
    x, y = math.cos(ang)*150, math.sin(ang)*150
    p = spawn(f"IC_Particle_{i+1}", sphere, (x,y,200+math.sin(ang)*30), scl=(10,10,10))
    if p: created.append(p)

# Human Figure (Light Shards)
spawn("IC_Head", cube, (0,-400,350), scl=(25,6,35))
for i in range(3):
    spawn(f"IC_Torso_{i+1}", cube, ((-1)**i*12,-400,280-i*30), rot=(0,0,(-1)**i*5), scl=(20,5,30))
spawn("IC_LArm", cube, (-55,-400,290), rot=(0,0,-35), scl=(10,5,50))
spawn("IC_RArm", cube, (55,-400,290), rot=(0,0,35), scl=(10,5,50))
spawn("IC_LLeg", cube, (-25,-400,140), rot=(0,0,5), scl=(12,5,70))
spawn("IC_RLeg", cube, (25,-400,140), rot=(0,0,-5), scl=(12,5,70))

unreal.EditorLevelLibrary.save_current_level()

print(f"\nCreated {len(created)} assets!")
print(f"\nNOW DO THIS:")
print(f"1. In Outliner, filter by 'IC_'")
print(f"2. Select all IC_ actors (Ctrl+A after filtering)")
print(f"3. File > Export Selected")
print(f"4. Change format to USD (.usd)")
print(f"5. Save to: {EXPORT_DIR}")
print("=" * 60)







