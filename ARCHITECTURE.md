# The Invisible Cost - Technical Architecture

## Vision Pro Spatial Narrative Experience (Tier 2)

### Overview

A 4-minute immersive narrative experience for Apple Vision Pro, showcasing "agentic automation" through emotional visual storytelling. The experience uses a **hybrid architecture** with Unreal Engine for advanced rendering and visionOS for hosting and interaction.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        VISION PRO DEVICE                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    visionOS App Layer                      │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐  │  │
│  │  │ LaunchView  │  │   Immersive  │  │  NarrativeText  │  │  │
│  │  │  (SwiftUI)  │  │ NarrativeView│  │    Overlay      │  │  │
│  │  └─────────────┘  └──────────────┘  └─────────────────┘  │  │
│  │         │                │                   │            │  │
│  │         ▼                ▼                   ▼            │  │
│  │  ┌───────────────────────────────────────────────────┐   │  │
│  │  │              ExperienceViewModel                   │   │  │
│  │  │  • Phase state machine                             │   │  │
│  │  │  • Progress tracking                               │   │  │
│  │  │  • Overwhelm intensity                             │   │  │
│  │  └───────────────────────────────────────────────────┘   │  │
│  │         │                         │                       │  │
│  │         ▼                         ▼                       │  │
│  │  ┌─────────────┐          ┌─────────────┐                │  │
│  │  │AudioManager │          │UnrealBridge │                │  │
│  │  │(Spatial)    │          │(TCP/JSON)   │                │  │
│  │  └─────────────┘          └─────────────┘                │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                   │                              │
│                                   ▼                              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   RealityKit Layer                         │  │
│  │  • 3D Entity rendering                                     │  │
│  │  • Particle systems                                        │  │
│  │  • Lighting                                                │  │
│  │  • Spatial audio positioning                               │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                   │
                                   │ Network (TCP:9998)
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                      UNREAL ENGINE 5.7                           │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   UnrealMCP Plugin                       │    │
│  │  • Scene state management                                │    │
│  │  • Blueprint automation                                  │    │
│  │  • Render texture export                                 │    │
│  └─────────────────────────────────────────────────────────┘    │
│                               │                                  │
│                               ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Scene States                          │    │
│  │  • idle         - Dark, minimal                          │    │
│  │  • overwhelm    - Chaotic notifications, pressure        │    │
│  │  • pattern_break- White beam, freeze                     │    │
│  │  • human_fragment- Shard dissolution                     │    │
│  │  • data_choreography - Assembly animation                │    │
│  │  • restoration  - Warm light, cohesion                   │    │
│  │  • exit         - Soft fade, CTA                         │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## File Structure

```
InvisibleCost-VisionPro/
├── InvisibleCost/
│   ├── InvisibleCostApp.swift       # App entry, scene configuration
│   ├── Info.plist                   # Permissions (camera, hands)
│   ├── Assets.xcassets/             # App icons, colors
│   ├── Models/
│   │   ├── ExperienceModel.swift    # Phase state machine
│   │   ├── AudioManager.swift       # Spatial audio narration
│   │   └── UnrealBridge.swift       # Unreal communication
│   └── Views/
│       ├── LaunchView.swift         # Entry window UI
│       ├── ImmersiveNarrativeView.swift  # Main 3D experience
│       └── NarrativeTextOverlay.swift    # Phase text displays
├── Packages/
│   └── RealityKitContent/
│       └── Sources/
│           └── RealityKitContent/
│               └── RealityKitContent.swift  # 3D asset loading
├── ARCHITECTURE.md                  # This file
└── README.md                        # Project overview
```

---

## Narrative Phases

| Phase | Duration | Visual | Audio |
|-------|----------|--------|-------|
| **Spatial Overwhelm** | 25s | Floating notifications swarm, one shatters | Chaos, pressure |
| **Reality Crack** | 12s | White beam, everything freezes | Silence |
| **Human Fragment** | 25s | Light shards fragment outward | Tension |
| **Data Choreography** | 35s | Data points assemble into central object | Assembly |
| **Human Restoration** | 35s | Shards converge, warm light returns | Warmth |
| **Exit Moment** | 30s | Soft fade, CTA text | Resolution |

**Total Runtime: ~2:42**

---

## Unreal Integration Path

### Current State (Phase 1 - Pure RealityKit)
The visionOS app runs entirely with RealityKit procedural geometry:
- Notification windows: `MeshResource.generatePlane`
- Light shards: `MeshResource.generateBox`
- Data particles: `MeshResource.generateSphere`
- Lighting: `PointLightComponent`, `DirectionalLightComponent`

### Future State (Phase 2 - Unreal Render-to-Texture)

#### Option A: Animated USD Export
1. Create scenes in Unreal with Level Sequences
2. Export as animated USD/USDZ
3. Load in RealityKit via `Entity(named:in:)`
4. Play animations via `AnimationPlaybackController`

```swift
// Example loading Unreal-exported asset
let scene = try await Entity(named: "OverwhelmScene", in: realityKitContentBundle)
experienceRoot.addChild(scene)
```

#### Option B: Pixel Streaming
1. Unreal renders scene in real-time
2. Stream pixels to visionOS via WebRTC
3. Display as texture on RealityKit plane
4. Sync state via `UnrealBridge`

```swift
// UnrealBridge commands
unrealBridge.transitionTo(state: .overwhelm, duration: 1.0)
unrealBridge.updateProgress(0.5, phase: .spatialOverwhelm)
```

### Communication Protocol

```json
// visionOS → Unreal: Scene transition
{
  "type": "transition",
  "state": "overwhelm",
  "duration": 1.0
}

// visionOS → Unreal: Progress update
{
  "type": "progress",
  "phase": 1,
  "progress": 0.75
}

// Unreal → visionOS: Scene ready
{
  "type": "scene_ready",
  "state": "overwhelm"
}
```

---

## MCP Integration

The Unreal MCP plugin enables AI-assisted scene authoring:

```bash
# Start MCP server
cd /Users/shashwatshlok/mcp-servers/unreal-mcp/Python
python3 unreal_mcp_server.py
```

### Example Commands (via Cursor AI)

```
"Create 12 floating notification windows in a chaotic sphere around the player"
"Add a human silhouette made of 50 light shards at position 0, 1.2, -2.5"
"Create a data choreography with 30 orbiting particles"
```

---

## Build & Run

### Prerequisites
- Xcode 15.2+
- visionOS 1.0+ SDK
- Apple Vision Pro or Simulator

### Steps

1. **Open in Xcode**
   ```bash
   open InvisibleCost-VisionPro/InvisibleCost.xcodeproj
   ```

2. **Select Target**
   - Scheme: InvisibleCost
   - Destination: Apple Vision Pro (simulator or device)

3. **Build & Run** (⌘R)

### Audio Assets (Optional)
Place narration files in `InvisibleCost/Resources/`:
- `narration_overwhelm.m4a`
- `narration_crack.m4a`
- `narration_fragment.m4a`
- `narration_choreography.m4a`
- `narration_restoration.m4a`
- `narration_exit.m4a`

---

## Performance Targets

| Metric | Target | Rationale |
|--------|--------|-----------|
| Frame Rate | 90 fps | visionOS requirement |
| Memory | < 1.5 GB | Device thermal limits |
| Draw Calls | < 100 | Battery conservation |
| Entity Count | < 200 | Smooth animation |

---

## Next Steps

1. **Audio Production**: Record narration voiceovers per phase
2. **Unreal Scenes**: Build high-fidelity scene states in UE 5.7
3. **USD Export**: Test animated USD pipeline from Unreal → RealityKit
4. **Device Testing**: Validate on physical Vision Pro hardware
5. **Davos Polish**: Final timing, comfort, and emotional tuning

---

## Team Notes

**For Designers**: Focus on Unreal scene authoring. The visionOS app will automatically sync to your scene states.

**For Developers**: The `UnrealBridge` class is ready for pixel streaming integration when the render pipeline is finalized.

**For Audio**: Spatial audio positioning is handled automatically. Just deliver mono M4A files.

