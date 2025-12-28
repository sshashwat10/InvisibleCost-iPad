#!/bin/bash
# Complete automation script for Invisible Cost Vision Pro Assets
# This script builds the Unreal plugin and creates all assets

set -e

echo "=============================================="
echo "INVISIBLE COST - ASSET CREATION AUTOMATION"
echo "=============================================="
echo ""

PROJECT_DIR="/Users/shashwatshlok/Projects/InvisibleCost-VisionPro"
UNREAL_PROJECT="/Users/shashwatshlok/mcp-servers/unreal-mcp/MCPGameProject"
UE_PATH="/Users/Shared/Epic Games/UE_5.7"

# Step 1: Kill Unreal if running
echo "Step 1: Closing Unreal Editor if running..."
pkill -9 UnrealEditor 2>/dev/null || true
sleep 2

# Step 2: Build the Unreal project with our updated plugin
echo "Step 2: Building Unreal project..."
echo "(This will compile the MCP plugin with static mesh support)"

# Use Unreal Build Tool
"$UE_PATH/Engine/Build/BatchFiles/Mac/Build.sh" \
    MCPGameProjectEditor \
    Mac \
    Development \
    -Project="$UNREAL_PROJECT/MCPGameProject.uproject" \
    -WaitMutex \
    -FromMsBuild

echo "Build complete!"

# Step 3: Launch Unreal Editor with the project
echo "Step 3: Launching Unreal Editor..."
open -a "$UE_PATH/Engine/Binaries/Mac/UnrealEditor.app" "$UNREAL_PROJECT/MCPGameProject.uproject" &

echo "Waiting for Unreal to fully load (60 seconds)..."
sleep 60

# Step 4: Wait for MCP server to be accessible
echo "Step 4: Checking MCP connection..."
for i in {1..30}; do
    if nc -z localhost 9998 2>/dev/null; then
        echo "MCP server is ready!"
        break
    fi
    echo "  Waiting for MCP server... ($i/30)"
    sleep 2
done

# Step 5: Create assets using Python script
echo "Step 5: Creating assets in Unreal..."
python3 << 'PYTHON_SCRIPT'
import socket
import json
import time
import math

def send_mcp_command(cmd_type, params):
    """Send a command to Unreal MCP server"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        sock.connect(('127.0.0.1', 9998))
        sock.settimeout(30)
        
        message = json.dumps({
            "type": cmd_type,
            **params
        })
        sock.sendall((message + "\n").encode('utf-8'))
        
        response = b""
        while True:
            try:
                chunk = sock.recv(4096)
                if not chunk:
                    break
                response += chunk
                if response.endswith(b"\n"):
                    break
            except socket.timeout:
                break
        
        if response:
            return json.loads(response.decode('utf-8'))
    except Exception as e:
        print(f"Error: {e}")
    finally:
        sock.close()
    return None

# Create assets with meshes
print("Creating Invisible Cost assets...")

# Meshes
CUBE = "/Engine/BasicShapes/Cube.Cube"
SPHERE = "/Engine/BasicShapes/Sphere.Sphere"
CYLINDER = "/Engine/BasicShapes/Cylinder.Cylinder"

# Central Assembly
print("  Creating Central Assembly...")
send_mcp_command("spawn_actor", {
    "name": "IC_Central",
    "type": "StaticMeshActor",
    "location": [0, 0, 200],
    "static_mesh": SPHERE
})

# Light Beam
print("  Creating Light Beam...")
send_mcp_command("spawn_actor", {
    "name": "IC_LightBeam",
    "type": "StaticMeshActor", 
    "location": [0, 0, 600],
    "static_mesh": CYLINDER
})

# Notification Windows
print("  Creating Notification Windows...")
for i in range(8):
    angle = (i / 8.0) * 2 * math.pi
    x = math.cos(angle) * 400
    y = math.sin(angle) * 400
    send_mcp_command("spawn_actor", {
        "name": f"IC_Window_{i+1:02d}",
        "type": "StaticMeshActor",
        "location": [x, y, 200 + i*20],
        "rotation": [0, math.degrees(angle) + 180, 0],
        "static_mesh": CUBE
    })
    time.sleep(0.5)

# Data Particles
print("  Creating Data Particles...")
for i in range(12):
    angle = (i / 12.0) * 2 * math.pi
    x = math.cos(angle) * 150
    y = math.sin(angle) * 150
    send_mcp_command("spawn_actor", {
        "name": f"IC_Particle_{i+1:02d}",
        "type": "StaticMeshActor",
        "location": [x, y, 200 + math.sin(angle) * 30],
        "static_mesh": SPHERE
    })
    time.sleep(0.3)

# Human silhouette shards
print("  Creating Human Silhouette...")
send_mcp_command("spawn_actor", {"name": "IC_Head", "type": "StaticMeshActor", "location": [0, -400, 350], "static_mesh": CUBE})
send_mcp_command("spawn_actor", {"name": "IC_Torso_1", "type": "StaticMeshActor", "location": [12, -400, 280], "static_mesh": CUBE})
send_mcp_command("spawn_actor", {"name": "IC_Torso_2", "type": "StaticMeshActor", "location": [-12, -400, 250], "static_mesh": CUBE})
send_mcp_command("spawn_actor", {"name": "IC_Torso_3", "type": "StaticMeshActor", "location": [12, -400, 220], "static_mesh": CUBE})
send_mcp_command("spawn_actor", {"name": "IC_LArm", "type": "StaticMeshActor", "location": [-55, -400, 290], "rotation": [0, 0, -35], "static_mesh": CUBE})
send_mcp_command("spawn_actor", {"name": "IC_RArm", "type": "StaticMeshActor", "location": [55, -400, 290], "rotation": [0, 0, 35], "static_mesh": CUBE})
send_mcp_command("spawn_actor", {"name": "IC_LLeg", "type": "StaticMeshActor", "location": [-25, -400, 140], "rotation": [0, 0, 5], "static_mesh": CUBE})
send_mcp_command("spawn_actor", {"name": "IC_RLeg", "type": "StaticMeshActor", "location": [25, -400, 140], "rotation": [0, 0, -5], "static_mesh": CUBE})

print("\nAssets created!")
print("Now you need to export them from Unreal:")
print("1. In Outliner, filter by 'IC_'")
print("2. Select all, File > Export Selected > USD format")
print(f"3. Save to: {'/Users/shashwatshlok/Projects/InvisibleCost-VisionPro/Packages/RealityKitContent/Sources/RealityKitContent/Resources/'}")
PYTHON_SCRIPT

echo ""
echo "=============================================="
echo "ASSET CREATION COMPLETE!"
echo ""
echo "Assets are now in Unreal Editor."
echo "The Vision Pro project at:"
echo "  $PROJECT_DIR"
echo ""
echo "Already has procedural fallbacks that will work"
echo "even without the Unreal assets!"
echo ""
echo "To run the Vision Pro app:"
echo "  1. Open Xcode: open $PROJECT_DIR/InvisibleCost.xcodeproj"
echo "  2. Select Vision Pro Simulator"
echo "  3. Click Run (Cmd+R)"
echo "=============================================="







