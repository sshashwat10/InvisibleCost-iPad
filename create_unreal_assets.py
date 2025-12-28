#!/usr/bin/env python3
"""
Create Invisible Cost Assets in Unreal Engine via Remote Execution
This script connects to a running Unreal Editor instance and creates the assets
"""

import sys
import time

# Add UE's Python plugin path to find remote_execution module
sys.path.insert(0, "/Users/Shared/Epic Games/UE_5.7/Engine/Plugins/Experimental/PythonScriptPlugin/Content/Python")

from remote_execution import RemoteExecution, MODE_EXEC_FILE

# The Python code to execute inside Unreal
UNREAL_CODE = '''
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
    label = a.get_actor_label()
    if label and label.startswith("IC_"):
        unreal.EditorLevelLibrary.destroy_actor(a)

created = []

# Central Assembly - glowing orb
c = spawn("IC_Central", sphere, (0,0,200), scl=(80,80,80))
if c: created.append(c)

# Light Beam - vertical column
b = spawn("IC_Beam", cylinder, (0,0,600), scl=(30,30,600))
if b: created.append(b)

# Notification Windows - floating screens
for i in range(8):
    ang = i/8.0 * 2 * math.pi
    x, y = math.cos(ang)*400, math.sin(ang)*400
    w = spawn(f"IC_Window_{i+1}", cube, (x,y,200+i*20), rot=(0,math.degrees(ang)+180,0), scl=(100,60,4))
    if w: created.append(w)

# Data Particles - orbiting spheres  
for i in range(12):
    ang = i/12.0 * 2 * math.pi
    x, y = math.cos(ang)*150, math.sin(ang)*150
    p = spawn(f"IC_Particle_{i+1}", sphere, (x,y,200+math.sin(ang)*30), scl=(10,10,10))
    if p: created.append(p)

# Human Figure (Light Shards)
shards = []
s = spawn("IC_Head", cube, (0,-400,350), scl=(25,6,35))
if s: shards.append(s)

for i in range(3):
    s = spawn(f"IC_Torso_{i+1}", cube, ((-1)**i*12,-400,280-i*30), rot=(0,0,(-1)**i*5), scl=(20,5,30))
    if s: shards.append(s)

s = spawn("IC_LArm", cube, (-55,-400,290), rot=(0,0,-35), scl=(10,5,50))
if s: shards.append(s)
s = spawn("IC_RArm", cube, (55,-400,290), rot=(0,0,35), scl=(10,5,50))
if s: shards.append(s)
s = spawn("IC_LLeg", cube, (-25,-400,140), rot=(0,0,5), scl=(12,5,70))
if s: shards.append(s)
s = spawn("IC_RLeg", cube, (25,-400,140), rot=(0,0,-5), scl=(12,5,70))
if s: shards.append(s)

print(f"Created {len(created)} main assets")
print(f"Created {len(shards)} human silhouette shards")

# Save the level
unreal.EditorLevelLibrary.save_current_level()
print("Level saved!")

# Now export to USD
print("\\nExporting to USD...")

all_ic_actors = [a for a in unreal.EditorLevelLibrary.get_all_level_actors() 
                  if a.get_actor_label() and a.get_actor_label().startswith("IC_")]

if all_ic_actors:
    unreal.EditorLevelLibrary.set_selected_level_actors(all_ic_actors)
    print(f"Selected {len(all_ic_actors)} actors for export")
    
    # Try USD export
    export_path = os.path.join(EXPORT_DIR, "InvisibleCost_Scene.usda")
    
    # Create export options
    task = unreal.AssetExportTask()
    task.object = unreal.EditorLevelLibrary.get_editor_world()
    task.filename = export_path
    task.selected = True
    task.replace_identical = True
    task.prompt = False
    task.automated = True
    
    # Export
    result = unreal.Exporter.run_asset_export_task(task)
    if result:
        print(f"Exported to: {export_path}")
    else:
        print("Export may have failed - check Unreal logs")
        print(f"Please manually export selected actors to: {EXPORT_DIR}")

print("=" * 60)
print("DONE!")
print("=" * 60)
'''

def main():
    print("Connecting to Unreal Editor...")
    print("(Make sure Python Remote Execution is enabled in Unreal: Edit > Project Settings > Plugins > Python > Enable Remote Execution)")
    print()
    
    remote_exec = RemoteExecution()
    remote_exec.start()
    
    # Wait for node discovery
    print("Discovering Unreal Editor instances...")
    for i in range(10):
        time.sleep(1)
        nodes = remote_exec.remote_nodes
        if nodes:
            print(f"Found {len(nodes)} Unreal instance(s)!")
            break
        print(f"  Waiting... ({i+1}/10)")
    else:
        print("\nERROR: No Unreal Editor found!")
        print("Please ensure:")
        print("  1. Unreal Editor is running with your project open")
        print("  2. Python plugin is enabled: Edit > Plugins > Python Editor Script Plugin")
        print("  3. Remote Execution is enabled: Edit > Project Settings > Plugins > Python > Enable Remote Execution")
        remote_exec.stop()
        return 1
    
    # Connect to first node
    node = nodes[0]
    node_id = node['node_id']
    print(f"Connecting to: {node_id}")
    
    try:
        remote_exec.open_command_connection(node_id)
        print("Connected!")
        
        print("\nExecuting asset creation script in Unreal...")
        print("-" * 60)
        
        result = remote_exec.run_command(UNREAL_CODE, unattended=True, exec_mode=MODE_EXEC_FILE)
        
        if result.get('success'):
            print(result.get('output', 'Command executed successfully'))
        else:
            print(f"Error: {result.get('result', 'Unknown error')}")
            
    except Exception as e:
        print(f"Error: {e}")
        return 1
    finally:
        remote_exec.stop()
    
    print("\n" + "=" * 60)
    print("Assets created in Unreal!")
    print("Check the level and export if needed.")
    print("=" * 60)
    return 0

if __name__ == '__main__':
    sys.exit(main())







