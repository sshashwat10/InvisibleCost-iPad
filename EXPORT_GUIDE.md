# Exporting Unreal Assets to Vision Pro

This guide explains how to export the Invisible Cost assets from Unreal Engine to the visionOS project.

## Quick Start (3 Steps)

### Step 1: Export from Unreal Editor

1. **Open Unreal Editor** with the MCPGameProject
2. **Select all Invisible Cost actors** in the Outliner:
   - Search for: `NotificationWindow`, `LightShard`, `DataParticle`, `LightBeam`, `CentralAssembly`
   - Or use Edit → Select All (Ctrl+A) then filter
3. **Export as USD**:
   - File → Export Selected...
   - Choose format: **USD (*.usd)** or **USDZ (*.usdz)**
   - Save to: `/Users/shashwatshlok/Projects/InvisibleCost-VisionPro/Packages/RealityKitContent/Sources/RealityKitContent/Resources/`

### Step 2: Verify Assets

After export, you should have these files in the Resources folder:

```
Resources/
├── NotificationWindow.usdz
├── LightShard.usdz
├── DataParticle.usdz
├── LightBeam.usdz
├── CentralAssembly.usdz
└── InvisibleCost_Scene.usda (optional - full scene)
```

### Step 3: Build and Run

```bash
# Open in Xcode
open /Users/shashwatshlok/Projects/InvisibleCost-VisionPro/InvisibleCost.xcodeproj

# Select: Apple Vision Pro (Simulator or Device)
# Build: Cmd+B
# Run: Cmd+R
```

---

## Detailed Export Instructions

### Method A: Individual Asset Export (Recommended)

For each asset type, export separately:

#### 1. Notification Windows
```
1. In Outliner, search "NotificationWindow"
2. Select all 12 notification window actors
3. Right-click → Asset Actions → Export
4. Save as: NotificationWindow.usdz
```

#### 2. Light Shards
```
1. Search "LightShard"
2. Select all shard actors
3. Export as: LightShard.usdz
```

#### 3. Data Particles
```
1. Search "DataParticle"
2. Select all particle actors
3. Export as: DataParticle.usdz
```

#### 4. Light Beam
```
1. Search "LightBeam"
2. Select LightBeam_Central
3. Export as: LightBeam.usdz
```

#### 5. Central Assembly
```
1. Search "CentralAssembly"
2. Select CentralAssembly_Core
3. Export as: CentralAssembly.usdz
```

### Method B: Full Scene Export

Export everything at once:

1. File → Export All
2. Format: USD Stage (*.usda)
3. Save as: `InvisibleCost_Scene.usda`
4. Copy to Resources folder

### Method C: Python Script (Advanced)

Run the export script in Unreal:

1. Edit → Execute Python Script
2. Navigate to: `/Users/shashwatshlok/mcp-servers/unreal-mcp/MCPGameProject/Content/Scripts/export_invisible_cost_assets.py`
3. Click Open

---

## USD Export Settings

When exporting, use these settings for best Vision Pro compatibility:

| Setting | Value |
|---------|-------|
| File Format | USDZ (compressed) or USD/USDA |
| Include Materials | ✅ Yes |
| Bake Materials | ✅ Yes |
| Export Textures | ✅ Yes |
| Stage Up Axis | Y |
| Meters Per Unit | 0.01 (1cm = 1 Unreal Unit) |

---

## Fallback Behavior

The visionOS app is designed to work with or without Unreal assets:

- **With assets**: Loads exported USDZ files from RealityKitContent
- **Without assets**: Uses procedural geometry (built-in fallbacks)

This means you can run the app immediately while iterating on Unreal exports.

---

## Troubleshooting

### Asset Not Loading

1. Check file exists in `Resources/` folder
2. Verify file extension is `.usdz` or `.usda`
3. Clean build: Cmd+Shift+K, then Cmd+B
4. Check Xcode console for loading errors

### Scale Issues

Unreal uses centimeters, RealityKit uses meters:
- Divide Unreal scale by 100
- Or set "Meters Per Unit" to 0.01 when exporting

### Material Issues

RealityKit supports:
- PBR materials (metallic/roughness)
- Unlit materials
- Transparent materials

Unsupported Unreal materials will fallback to default gray.

---

## Asset Checklist

| Asset | Unreal Name | Expected File | Status |
|-------|-------------|---------------|--------|
| Notification Windows | NotificationWindow_01-12 | NotificationWindow.usdz | ⬜ |
| Light Shards | LightShard_* | LightShard.usdz | ⬜ |
| Data Particles | DataParticle_01-08 | DataParticle.usdz | ⬜ |
| Light Beam | LightBeam_Central | LightBeam.usdz | ⬜ |
| Central Assembly | CentralAssembly_Core | CentralAssembly.usdz | ⬜ |
| Full Scene | (all actors) | InvisibleCost_Scene.usda | ⬜ |

---

## Next Steps After Export

1. **Test in Simulator**: Run on visionOS Simulator first
2. **Adjust Scale**: If assets are too big/small, adjust in Unreal and re-export
3. **Add Materials**: Create Unreal materials with emissive properties for glow effects
4. **Add Animations**: Use Level Sequences for animated exports
5. **Deploy to Device**: Build to physical Vision Pro for final testing

