import SwiftUI
import RealityKit

/// The Invisible Cost - Vision Pro Immersive Experience
/// 1:1 replica of iPad experience in 3D spatial computing
struct ImmersiveNarrativeView: View {
    @Environment(ExperienceViewModel.self) private var viewModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    // Audio
    private let audioManager = AudioManager.shared
    
    // Scene root
    @State private var experienceRoot = Entity()
    @State private var sceneLoaded = false
    @State private var animationTime: Float = 0
    
    // === WOW FACTOR STATES ===
    @State private var glitchOffset: SIMD3<Float> = .zero
    @State private var starWarpFactor: Float = 0
    @State private var breathingFactor: Float = 1.0
    @State private var dataStreamParticles: [Entity] = [] // Rising data in vignettes
    
    // === SCENE ELEMENTS ===
    
    // Ambient Atmosphere
    @State private var ambientParticles: [Entity] = []
    @State private var nebulaClouds: [Entity] = []
    // godRays removed - RealityKit transparency issue
    
    // Narrator frame elements - FLOATING WORK WINDOWS (matches iPad)
    @State private var narratorTextEntity: Entity?
    @State private var workWindows: [Entity] = []
    @State private var scanLines: [Entity] = []
    @State private var narratorWindowsParent = Entity()
    
    // Vignette windows (3 sectors with cards)
    @State private var vignetteWindowsParent = Entity()
    @State private var financeCards: [Entity] = []
    @State private var supplyCards: [Entity] = []
    @State private var healthcareCards: [Entity] = []
    @State private var sectorGlows: [Entity] = []
    @State private var sectorParticles: [Entity] = []
    @State private var dataStreams: [Entity] = [] // NEW: Data bits streaming in
    
    // Agentic Orchestration
    @State private var orchestratorEntity: Entity?
    @State private var agentEntities: [Entity] = []
    @State private var connectionArcs: [Entity] = []
    @State private var energyArcs: [Entity] = [] // NEW: Lightning crackle
    @State private var taskOrb: Entity?
    @State private var solutionCrystal: Entity?
    @State private var shockwaveRing: Entity?    // NEW: Synthesis impact
    
    // Human Return (Restoration)
    @State private var restorationGlow: Entity?
    @State private var humanFigure: Entity?
    @State private var humanFigureBillboard: Entity?  // NEW: Billboard with leader image
    @State private var debrisParticles: [Entity] = []
    @State private var lightRays: [Entity] = []
    @State private var energyArcsRestoration: [Entity] = []
    
    // CTA Portal
    @State private var portalRings: [Entity] = []
    @State private var portalGlow: Entity?
    @State private var beaconPulses: [Entity] = []
    @State private var portalVortex: [Entity] = [] // NEW: Swirling maelstrom
    
    // Agentic Orchestration - original positions for coalescing animation
    @State private var nodeOriginalPositions: [SIMD3<Float>] = []
    
    // === WOW FACTOR STATE ===
    // Removed: sectorShockwaves, hyperdriveLines - caused rendering issues
    @State private var cardGlintTimer: Float = 0
    
    var body: some View {
        RealityView { content, attachments in
            content.add(experienceRoot)
            await buildScene()
            
            // Attach text overlays - positioned BELOW the 3D sphere
            // Text at y=1.3 (chest level), 3D sphere at y=2.0 (above head)
            if let textOverlay = attachments.entity(for: "NarrativeText") {
                textOverlay.position = [0, 1.3, -1.2]  // Lower position, avoids sphere overlap
                textOverlay.components.set(BillboardComponent())
                experienceRoot.addChild(textOverlay)
            }
            
        } update: { _, _ in
            // Updates handled by timer
        } attachments: {
            Attachment(id: "NarrativeText") {
                NarrativeTextOverlay()
                    .environment(viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.clear)
                    .glassBackgroundEffect(displayMode: .never)
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                audioManager.resetTriggers()
                if viewModel.currentPhase == .waiting {
                    viewModel.startExperience()
                    print("▶️ Experience started!")
                }
                startUpdateLoop()
            }
        }
        .onDisappear {
            audioManager.stopAllAudio()
        }
    }
    
    // MARK: - Update Loop (60fps)
    
    private func startUpdateLoop() {
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            Task { @MainActor in
                guard sceneLoaded else { return }
                
                let dt: Float = 1.0/60.0
                animationTime += dt
                viewModel.update(deltaTime: Double(dt))
                audioManager.playAudioForPhase(viewModel.currentPhase, progress: viewModel.phaseProgress)
                animateScene(dt: dt)
            }
        }
    }
    
    // MARK: - Scene Construction
    
    @MainActor
    private func buildScene() async {
        print("🎬 Building Vision Pro immersive scene...")
        
        // Build all phases
        await buildAmbientParticles()
        await buildFloatingWorkWindows()  // NEW: Matches iPad narrator frame
        await buildVignetteCards()
        await buildAgenticOrchestration()
        await buildHumanReturn()
        await buildCTAPortal()
        // buildWowEffects removed - caused white bar rendering issues
        addSceneLighting()
        
        sceneLoaded = true
        print("✅ Scene built successfully")
    }
    
    // MARK: - Floating Work Windows (Narrator Frame - matches iPad)
    // Creates 3D work windows floating AROUND the user (360°) like iPad's NarratorFrameAnimation
    // FPP PARADIGM: User is surrounded by overwhelming work windows, not watching from outside
    
    @MainActor
    private func buildFloatingWorkWindows() async {
        narratorWindowsParent.name = "NarratorWindows"
        narratorWindowsParent.position = [0, 1.6, -2.5]
        experienceRoot.addChild(narratorWindowsParent)
        
        // Create 20 floating work windows distributed in 3D space
        for i in 0..<20 {
            let windowParent = Entity()
            windowParent.name = "WorkWindow_\(i)"
            
            // Random 3D position in a dome around the user
            let angle = Float.random(in: 0...(2 * Float.pi))
            let heightAngle = Float.random(in: -0.4...0.6)  // Mostly in front and above
            let distance = Float.random(in: 2.0...4.5)
            
            windowParent.position = [
                cos(angle) * distance * cos(heightAngle),
                sin(heightAngle) * distance * 0.5,
                sin(angle) * distance * cos(heightAngle) * 0.6 - 1.5  // Bias toward front
            ]
            
            // Window frame (glass panel) - macOS-style window
            let windowWidth: Float = Float.random(in: 0.3...0.5)
            let windowHeight: Float = Float.random(in: 0.2...0.35)
            
            // Main glass panel
            let panelMesh = MeshResource.generateBox(width: windowWidth, height: windowHeight, depth: 0.005, cornerRadius: 0.01)
            var panelMat = PhysicallyBasedMaterial()
            panelMat.baseColor = .init(tint: UIColor(white: 0.1, alpha: 0.8))
            panelMat.roughness = 0.3
            panelMat.metallic = 0.2
            panelMat.blending = .transparent(opacity: .init(floatLiteral: 0.85))
            let panel = ModelEntity(mesh: panelMesh, materials: [panelMat])
            windowParent.addChild(panel)
            
            // Title bar
            let titleBarMesh = MeshResource.generateBox(width: windowWidth - 0.01, height: 0.025, depth: 0.006, cornerRadius: 0.005)
            var titleMat = UnlitMaterial()
            titleMat.color = .init(tint: UIColor(white: 0.15, alpha: 0.9))
            let titleBar = ModelEntity(mesh: titleBarMesh, materials: [titleMat])
            titleBar.position = [0, windowHeight / 2 - 0.02, 0.003]
            windowParent.addChild(titleBar)
            
            // Traffic light buttons (red, yellow, green)
            let buttonColors: [UIColor] = [
                UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.7),
                UIColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 0.7),
                UIColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 0.7)
            ]
            for (bi, color) in buttonColors.enumerated() {
                let btnMesh = MeshResource.generateSphere(radius: 0.006)
                var btnMat = UnlitMaterial()
                btnMat.color = .init(tint: color)
                let btn = ModelEntity(mesh: btnMesh, materials: [btnMat])
                btn.position = [-windowWidth/2 + 0.025 + Float(bi) * 0.015, windowHeight/2 - 0.02, 0.006]
                windowParent.addChild(btn)
            }
            
            // === WINDOW CONTENT (Charts, Graphs, Data, Icons) ===
            let contentType = i % 5  // Cycle through different content types
            
            switch contentType {
            case 0:  // BAR CHART
                let barCount = 4
                for bi in 0..<barCount {
                    let barHeight = Float.random(in: 0.03...0.1)
                    let barMesh = MeshResource.generateBox(width: 0.02, height: barHeight, depth: 0.003, cornerRadius: 0.002)
                    var barMat = UnlitMaterial()
                    let barColors: [UIColor] = [
                        UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 0.8),
                        UIColor(red: 0.3, green: 0.8, blue: 0.5, alpha: 0.8),
                        UIColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 0.8),
                        UIColor(red: 0.8, green: 0.3, blue: 0.5, alpha: 0.8)
                    ]
                    barMat.color = .init(tint: barColors[bi])
                    let bar = ModelEntity(mesh: barMesh, materials: [barMat])
                    bar.position = [
                        -windowWidth/2 + 0.04 + Float(bi) * 0.035,
                        windowHeight/2 - 0.12 - barHeight/2,
                        0.004
                    ]
                    windowParent.addChild(bar)
                }
                
            case 1:  // LINE GRAPH
                for li in 0..<5 {
                    let pointMesh = MeshResource.generateSphere(radius: 0.006)
                    var pointMat = UnlitMaterial()
                    pointMat.color = .init(tint: UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.9))
                    let point = ModelEntity(mesh: pointMesh, materials: [pointMat])
                    let yOffset = Float.random(in: -0.04...0.04)
                    point.position = [
                        -windowWidth/2 + 0.03 + Float(li) * 0.025,
                        windowHeight/2 - 0.1 + yOffset,
                        0.004
                    ]
                    windowParent.addChild(point)
                    
                    // Connect with lines
                    if li > 0 {
                        let lineMesh = MeshResource.generateBox(width: 0.025, height: 0.002, depth: 0.002)
                        var lineMat = UnlitMaterial()
                        lineMat.color = .init(tint: UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.6))
                        let line = ModelEntity(mesh: lineMesh, materials: [lineMat])
                        line.position = point.position - [0.0125, 0, 0]
                        windowParent.addChild(line)
                    }
                }
                
            case 2:  // EMAIL/MESSAGE LIST
                for ei in 0..<3 {
                    // Avatar circle
                    let avatarMesh = MeshResource.generateSphere(radius: 0.012)
                    var avatarMat = UnlitMaterial()
                    let avatarColors: [UIColor] = [
                        UIColor(red: 0.8, green: 0.4, blue: 0.3, alpha: 0.9),
                        UIColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 0.9),
                        UIColor(red: 0.5, green: 0.7, blue: 0.4, alpha: 0.9)
                    ]
                    avatarMat.color = .init(tint: avatarColors[ei])
                    let avatar = ModelEntity(mesh: avatarMesh, materials: [avatarMat])
                    avatar.position = [
                        -windowWidth/2 + 0.03,
                        windowHeight/2 - 0.07 - Float(ei) * 0.04,
                        0.004
                    ]
                    windowParent.addChild(avatar)
                    
                    // Subject line
                    let subjectMesh = MeshResource.generateBox(width: 0.08, height: 0.006, depth: 0.002, cornerRadius: 0.002)
                    var subjectMat = UnlitMaterial()
                    subjectMat.color = .init(tint: UIColor(white: 0.5, alpha: 0.7))
                    let subject = ModelEntity(mesh: subjectMesh, materials: [subjectMat])
                    subject.position = avatar.position + [0.06, 0.008, 0]
                    windowParent.addChild(subject)
                    
                    // Preview line
                    let previewMesh = MeshResource.generateBox(width: 0.06, height: 0.004, depth: 0.002, cornerRadius: 0.001)
                    var previewMat = UnlitMaterial()
                    previewMat.color = .init(tint: UIColor(white: 0.35, alpha: 0.5))
                    let preview = ModelEntity(mesh: previewMesh, materials: [previewMat])
                    preview.position = avatar.position + [0.05, -0.008, 0]
                    windowParent.addChild(preview)
                }
                
            case 3:  // PIE CHART
                for pi in 0..<4 {
                    let segmentMesh = MeshResource.generateSphere(radius: 0.025)
                    var segmentMat = UnlitMaterial()
                    let pieColors: [UIColor] = [
                        UIColor(red: 0.9, green: 0.5, blue: 0.2, alpha: 0.8),
                        UIColor(red: 0.2, green: 0.7, blue: 0.8, alpha: 0.8),
                        UIColor(red: 0.6, green: 0.3, blue: 0.7, alpha: 0.8),
                        UIColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 0.8)
                    ]
                    segmentMat.color = .init(tint: pieColors[pi])
                    let segment = ModelEntity(mesh: segmentMesh, materials: [segmentMat])
                    let angle = Float(pi) * Float.pi / 2
                    segment.position = [
                        -windowWidth/4 + cos(angle) * 0.02,
                        windowHeight/2 - 0.1 + sin(angle) * 0.02,
                        0.004
                    ]
                    segment.scale = SIMD3<Float>(repeating: 0.6 + Float(pi) * 0.15)
                    windowParent.addChild(segment)
                }
                
            default:  // SPREADSHEET/TABLE
                for row in 0..<3 {
                    for col in 0..<4 {
                        let cellMesh = MeshResource.generateBox(width: 0.025, height: 0.015, depth: 0.002, cornerRadius: 0.002)
                        var cellMat = UnlitMaterial()
                        cellMat.color = .init(tint: UIColor(white: row == 0 ? 0.4 : 0.25, alpha: 0.6))
                        let cell = ModelEntity(mesh: cellMesh, materials: [cellMat])
                        cell.position = [
                            -windowWidth/2 + 0.025 + Float(col) * 0.03,
                            windowHeight/2 - 0.07 - Float(row) * 0.02,
                            0.004
                        ]
                        windowParent.addChild(cell)
                    }
                }
            }
            
            // Content lines (fake text/data) - smaller, below graphics
            let lineCount = Int.random(in: 2...4)
            for li in 0..<lineCount {
                let lineWidth = Float.random(in: 0.06...windowWidth * 0.5)
                let lineMesh = MeshResource.generateBox(width: lineWidth, height: 0.006, depth: 0.002, cornerRadius: 0.002)
                var lineMat = UnlitMaterial()
                lineMat.color = .init(tint: UIColor(white: 0.3, alpha: 0.5))
                let line = ModelEntity(mesh: lineMesh, materials: [lineMat])
                line.position = [
                    -windowWidth/2 + 0.02 + lineWidth/2,
                    windowHeight/2 - 0.06 - Float(li) * 0.025,
                    0.003
                ]
                windowParent.addChild(line)
            }
            
            // Border glow
            let borderMesh = MeshResource.generateBox(width: windowWidth + 0.01, height: windowHeight + 0.01, depth: 0.001, cornerRadius: 0.015)
            var borderMat = UnlitMaterial()
            borderMat.color = .init(tint: UIColor(white: 0.4, alpha: 0.3))
            let border = ModelEntity(mesh: borderMesh, materials: [borderMat])
            border.position.z = -0.003
            windowParent.addChild(border)
            
            // Random initial rotation for variety
            windowParent.orientation = simd_quatf(
                angle: Float.random(in: -0.15...0.15),
                axis: normalize([Float.random(in: -1...1), 1, Float.random(in: -1...1)])
            )
            
            windowParent.scale = .zero  // Start hidden
            narratorWindowsParent.addChild(windowParent)
            workWindows.append(windowParent)
        }
        
        // REMOVED: Scan lines were causing visual artifacts (Screenshot 1 issue)
        // The scan lines effect doesn't translate well to VR - creates distracting horizontal lines
        // Instead, we rely on the work windows themselves to create the "overwhelming work" feeling
        
        // Scan lines removed - they caused horizontal line artifacts in VR
    }
    
    // MARK: - Ambient Star Field (Clean black background with subtle stars)
    
    @MainActor
    private func buildAmbientParticles() async {
        // === PURE BLACK BACKGROUND - No large spheres or nebulas ===
        // VR handles black void naturally - no backdrop needed
        
        // === DISTANT STAR FIELD (Small, subtle) ===
        for _ in 0..<100 {
            let size = Float.random(in: 0.003...0.008)
            let starMesh = MeshResource.generateSphere(radius: size)
            var starMat = UnlitMaterial()
            let brightness = Float.random(in: 0.4...0.9)
            starMat.color = .init(tint: UIColor(white: CGFloat(brightness), alpha: 1.0))
            let star = ModelEntity(mesh: starMesh, materials: [starMat])
            star.position = [Float.random(in: -15...15), Float.random(in: -8...10), Float.random(in: -15...(-5))]
            experienceRoot.addChild(star)
        }
        
        // === MID-FIELD STARS (Twinkle animation) ===
        for i in 0..<50 {
            let starMesh = MeshResource.generateSphere(radius: 0.01)
            var starMat = UnlitMaterial()
            starMat.color = .init(tint: .white)
            let star = ModelEntity(mesh: starMesh, materials: [starMat])
            star.name = "StarMid_\(i)"
            star.position = [Float.random(in: -8...8), Float.random(in: -5...6), Float.random(in: -10...(-3))]
            experienceRoot.addChild(star)
            ambientParticles.append(star)
        }
        
        // God rays removed - RealityKit transparency issue causes them to render as solid white bars
    }
    
    // MARK: - Vignette Sectors (FPP IMMERSIVE - User is SURROUNDED)
    // FPP PARADIGM: User is inside an ambient glow sphere, not watching from outside
    // Creates the feeling of being immersed in each sector's "world"
    
    @MainActor
    private func buildVignetteCards() async {
        vignetteWindowsParent.name = "VignetteSectors"
        vignetteWindowsParent.position = [0, 1.6, 0]  // Centered on user
        experienceRoot.addChild(vignetteWindowsParent)
        
        // Sector configurations - VIBRANT, SATURATED COLORS
        let sectors: [(name: String, color: UIColor, accent: UIColor)] = [
            ("FINANCE", 
             UIColor(red: 0.1, green: 0.4, blue: 0.95, alpha: 1.0),   // Bright blue
             UIColor(red: 0.2, green: 0.55, blue: 1.0, alpha: 1.0)),
            
            ("SUPPLY_CHAIN",
             UIColor(red: 1.0, green: 0.55, blue: 0.1, alpha: 1.0),   // Bright orange
             UIColor(red: 1.0, green: 0.65, blue: 0.2, alpha: 1.0)),
            
            ("HEALTHCARE",
             UIColor(red: 0.1, green: 0.85, blue: 0.45, alpha: 1.0),  // Bright green
             UIColor(red: 0.2, green: 0.95, blue: 0.55, alpha: 1.0))
        ]
        
        for (sectorIndex, sector) in sectors.enumerated() {
            let sectorParent = Entity()
            sectorParent.name = "Sector_\(sector.name)"
            sectorParent.position = .zero
            sectorParent.scale = .zero
            vignetteWindowsParent.addChild(sectorParent)
            sectorGlows.append(sectorParent)
            
            // === SIMPLE LENS FLARE using POINT LIGHTS for real glow ===
            let haloCenter: SIMD3<Float> = [0, 0, -2.2]  // In front of user
            
            // 1. MAIN POINT LIGHT - This creates the actual glow effect
            let mainLight = Entity()
            mainLight.name = "FlareLight_\(sectorIndex)"
            var mainLightComp = PointLightComponent()
            mainLightComp.intensity = Float(80000)  // Bright!
            mainLightComp.color = sector.accent
            mainLightComp.attenuationRadius = Float(4.0)
            mainLight.components.set(mainLightComp)
            mainLight.position = haloCenter
            mainLight.scale = .zero
            sectorParent.addChild(mainLight)
            
            // 2. TINY BRIGHT CORE - emissive material for actual glow
            let coreMesh = MeshResource.generateSphere(radius: 0.015)
            var coreMat = PhysicallyBasedMaterial()
            coreMat.baseColor = .init(tint: .white)
            coreMat.emissiveColor = .init(color: sector.accent)
            coreMat.emissiveIntensity = 5.0
            let core = ModelEntity(mesh: coreMesh, materials: [coreMat])
            core.name = "FlareCore_\(sectorIndex)"
            core.position = haloCenter
            core.scale = .zero
            sectorParent.addChild(core)
            
            // Streak plane removed - rendered as solid bar, not glow
            
            // 4. LEFT COLOR FRINGE - point light
            let leftLight = Entity()
            leftLight.name = "FringeLeft_\(sectorIndex)"
            var leftLightComp = PointLightComponent()
            leftLightComp.intensity = Float(15000)
            // Cooler color (blue-shifted)
            var sectorR: CGFloat = 0, sectorG: CGFloat = 0, sectorB: CGFloat = 0, sectorA: CGFloat = 0
            sector.accent.getRed(&sectorR, green: &sectorG, blue: &sectorB, alpha: &sectorA)
            let leftColor = UIColor(
                red: max(0, sectorR - 0.3),
                green: sectorG,
                blue: min(1.0, sectorB + 0.5),
                alpha: 1.0
            )
            leftLightComp.color = leftColor
            leftLightComp.attenuationRadius = Float(1.5)
            leftLight.components.set(leftLightComp)
            leftLight.position = haloCenter + [-0.7, 0, 0]
            leftLight.scale = .zero
            sectorParent.addChild(leftLight)
            
            // 5. RIGHT COLOR FRINGE - point light
            let rightLight = Entity()
            rightLight.name = "FringeRight_\(sectorIndex)"
            var rightLightComp = PointLightComponent()
            rightLightComp.intensity = Float(15000)
            // Warmer color (red-shifted)
            let rightColor = UIColor(
                red: min(1.0, sectorR + 0.5),
                green: max(0, sectorG - 0.2),
                blue: max(0, sectorB - 0.4),
                alpha: 1.0
            )
            rightLightComp.color = rightColor
            rightLightComp.attenuationRadius = Float(1.5)
            rightLight.components.set(rightLightComp)
            rightLight.position = haloCenter + [0.7, 0, 0]
            rightLight.scale = .zero
            sectorParent.addChild(rightLight)
            
            // CENTER DOT removed - was visible in the middle of text
            
            // === POINT LIGHT at halo center (illuminates scene) ===
            let haloLight = Entity()
            var haloLightComp = PointLightComponent()
            haloLightComp.intensity = Float(40000)
            haloLightComp.color = sector.accent
            haloLightComp.attenuationRadius = Float(4.0)
            haloLight.components.set(haloLightComp)
            haloLight.position = haloCenter
            sectorParent.addChild(haloLight)
            
            // === FPP: AMBIENT SPHERE OF PARTICLES SURROUNDING USER (360°) ===
            for i in 0..<50 {
                let size = Float.random(in: 0.015...0.035)  // Larger particles
                let pMesh = MeshResource.generateSphere(radius: size)
                var pMat = UnlitMaterial()
                let alpha = Float.random(in: 0.5...0.9)  // Brighter
                pMat.color = .init(tint: sector.accent.withAlphaComponent(CGFloat(alpha)))
                
                let particle = ModelEntity(mesh: pMesh, materials: [pMat])
                particle.name = "AmbientParticle_\(sectorIndex)_\(i)"
                
                // Distribute in a SPHERE around user
                let theta = Float.random(in: 0...(2 * Float.pi))
                let phi = Float.random(in: 0.3...2.8)
                let r = Float.random(in: 1.5...4.5)
                
                particle.position = [
                    r * sin(phi) * cos(theta),
                    r * cos(phi),
                    r * sin(phi) * sin(theta)
                ]
                
                particle.scale = .zero
                sectorParent.addChild(particle)
                sectorParticles.append(particle)
            }
            
            // === FPP: WARM AMBIENT LIGHTS (creates the "glow" feeling) ===
            for i in 0..<4 {
                let lightAngle = Float(i) * (Float.pi / 2) + Float.random(in: -0.3...0.3)
                let light = Entity()
                var lightComp = PointLightComponent()
                lightComp.intensity = Float(30000)
                lightComp.color = sector.accent
                lightComp.attenuationRadius = Float(6.0)
                light.components.set(lightComp)
                light.position = [
                    cos(lightAngle) * 3.0,
                    Float.random(in: 0...2.0),
                    sin(lightAngle) * 3.0
                ]
                sectorParent.addChild(light)
            }
            
            // === FPP: FLOATING DATA BITS drifting past user ===
            for i in 0..<15 {
                let bitMesh = MeshResource.generateBox(size: 0.01)
                var bitMat = UnlitMaterial()
                bitMat.color = .init(tint: sector.accent.withAlphaComponent(0.6))
                let bit = ModelEntity(mesh: bitMesh, materials: [bitMat])
                bit.name = "DataBit_\(sectorIndex)_\(i)"
                
                // Random position around user
                let theta = Float.random(in: 0...(2 * Float.pi))
                let phi = Float.random(in: 0.5...2.5)
                let r = Float.random(in: 1.5...4.0)
                
                bit.position = [
                    r * sin(phi) * cos(theta),
                    r * cos(phi),
                    r * sin(phi) * sin(theta)
                ]
                bit.scale = .zero
                sectorParent.addChild(bit)
                dataStreams.append(bit)
            }
        }
    }
    
    // MARK: - Agentic Orchestration (FPP IMMERSIVE - User is INSIDE the forming network)
    // FPP PARADIGM: Points appear all AROUND the user, then coalesce to a central orb
    // User experiences being INSIDE the AI network forming around them
    
    // Agent shape types matching iPad
    enum AgentShapeType { case diamond, triangle, star, octagon, shield, circle }
    
    @MainActor
    private func buildAgenticOrchestration() async {
        // === FPP: NODES APPEAR ALL AROUND USER, THEN COALESCE TO FRONT ===
        // Phase 1: Dots appear in a large sphere AROUND user (immersive)
        // Phase 2: Connections form between dots
        // Phase 3: Whole thing shrinks and moves to front of user's vision
        
        // User is at origin [0, 1.6, 0] (approximate eye level)
        let userCenter: SIMD3<Float> = [0, 1.6, 0]
        let surroundRadius: Float = 2.5  // Dots start at 2.5m around user
        // Final position BEHIND text overlay (text at z=-1.0, sphere at z=-2.0)
        let coalescedCenter: SIMD3<Float> = [0, 1.8, -2.0]
        let coalescedRadius: Float = 0.35  // Final small sphere size
        
        // Main container - starts at user center, will move during animation
        let sphereParent = Entity()
        sphereParent.name = "Orchestrator"
        sphereParent.position = userCenter  // Start centered on user
        experienceRoot.addChild(sphereParent)
        orchestratorEntity = sphereParent
        
        // Teal color palette (BRIGHTER, more vibrant)
        let primaryTeal = UIColor(red: 0.0, green: 0.7, blue: 0.8, alpha: 1.0)
        let glowTeal = UIColor(red: 0.15, green: 0.9, blue: 1.0, alpha: 1.0)
        let brightCyan = UIColor(red: 0.3, green: 1.0, blue: 1.0, alpha: 1.0)
        
        // Generate 48 points on sphere using golden spiral (more points = smoother sphere)
        let numPoints = 48
        let goldenRatio = (1.0 + sqrt(5.0)) / 2.0
        
        var spherePoints: [(x: Float, y: Float, z: Float)] = []
        
        for i in 0..<numPoints {
            let theta = Float(2.0 * .pi * Double(i) / goldenRatio)
            let phi = Float(acos(1.0 - 2.0 * (Double(i) + 0.5) / Double(numPoints)))
            
            // Convert to cartesian (on unit sphere)
            let x = sin(phi) * cos(theta)
            let y = cos(phi)
            let z = sin(phi) * sin(theta)
            
            spherePoints.append((x, y, z))
        }
        
        // Create node entities - start AROUND user at surroundRadius
        nodeOriginalPositions.removeAll()
        for (i, point) in spherePoints.enumerated() {
            // Main node - SMALL dot like iPad
            let nodeMesh = MeshResource.generateSphere(radius: 0.025)  // Visible at distance
            var nodeMat = UnlitMaterial()
            nodeMat.color = .init(tint: brightCyan)
            
            let node = ModelEntity(mesh: nodeMesh, materials: [nodeMat])
            node.name = "SphereNode_\(i)"
            
            // Start at large radius AROUND user (360° immersive)
            let originalPos: SIMD3<Float> = [
                point.x * surroundRadius,
                point.y * surroundRadius,
                point.z * surroundRadius
            ]
            node.position = originalPos
            nodeOriginalPositions.append(originalPos)
            
            node.scale = .zero  // Hidden initially
            sphereParent.addChild(node)
            agentEntities.append(node)
            
            // Small subtle glow around each node
            let glowMesh = MeshResource.generateSphere(radius: 0.04)  // Visible at distance
            var glowMat = UnlitMaterial()
            glowMat.color = .init(tint: glowTeal.withAlphaComponent(0.15))
            let glow = ModelEntity(mesh: glowMesh, materials: [glowMat])
            glow.name = "NodeGlow_\(i)"
            glow.position = originalPos
            glow.scale = .zero
            sphereParent.addChild(glow)
        }
        
        // Create connection lines - start at surround radius, will shrink with nodes
        // Store unit vectors for each connection so animation can reposition them
        for i in 0..<numPoints {
            for j in (i+1)..<numPoints {
                let p1 = spherePoints[i]
                let p2 = spherePoints[j]
                
                // Calculate distance on unit sphere
                let dx = p1.x - p2.x
                let dy = p1.y - p2.y
                let dz = p1.z - p2.z
                let dist = sqrt(dx*dx + dy*dy + dz*dz)
                
                // Connect points that are close enough
                if dist < 0.65 {
                    // Create at surround radius (will be animated to coalescedRadius)
                    let startPos = SIMD3<Float>(p1.x * surroundRadius, p1.y * surroundRadius, p1.z * surroundRadius)
                    let endPos = SIMD3<Float>(p2.x * surroundRadius, p2.y * surroundRadius, p2.z * surroundRadius)
                    let midPoint = (startPos + endPos) / 2
                    let length = simd_length(endPos - startPos)
                    
                    let lineMesh = MeshResource.generateCylinder(height: length, radius: 0.003)
                    var lineMat = UnlitMaterial()
                    lineMat.color = .init(tint: primaryTeal.withAlphaComponent(0.6))
                    
                    let line = ModelEntity(mesh: lineMesh, materials: [lineMat])
                    line.name = "Connection_\(i)_\(j)"
                    
                    // Position relative to sphere parent (which is already at coalescedCenter)
                    line.position = midPoint
                    
                    // Calculate rotation to align cylinder
                    let direction = simd_normalize(endPos - startPos)
                    let up = SIMD3<Float>(0, 1, 0)
                    
                    if abs(simd_dot(direction, up)) > 0.999 {
                        line.orientation = direction.y > 0 ? simd_quatf(angle: 0, axis: [0, 1, 0]) : simd_quatf(angle: .pi, axis: [1, 0, 0])
                    } else {
                        let rotAxis = simd_normalize(simd_cross(up, direction))
                        let angle = acos(simd_dot(up, direction))
                        line.orientation = simd_quatf(angle: angle, axis: rotAxis)
                    }
                    
                    line.scale = .zero  // Hidden initially
                    sphereParent.addChild(line)
                    connectionArcs.append(line)
                }
            }
        }
        
        // === CENTRAL ORB with MULTI-LAYER GLOW (appears during coalesce) ===
        let orbParent = Entity()
        orbParent.name = "CentralOrbParent"
        orbParent.position = .zero  // Centered in sphere parent (which is at coalescedCenter)
        orbParent.scale = .zero
        sphereParent.addChild(orbParent)
        taskOrb = orbParent
        
        // Core (bright white-cyan center)
        let coreMesh = MeshResource.generateSphere(radius: 0.06)
        var coreMat = UnlitMaterial()
        coreMat.color = .init(tint: UIColor(red: 0.9, green: 1.0, blue: 1.0, alpha: 1.0))
        let core = ModelEntity(mesh: coreMesh, materials: [coreMat])
        core.name = "OrbCore"
        orbParent.addChild(core)
        
        // Inner glow layer
        let innerGlowMesh = MeshResource.generateSphere(radius: 0.09)
        var innerGlowMat = UnlitMaterial()
        innerGlowMat.color = .init(tint: brightCyan.withAlphaComponent(0.7))
        let innerGlow = ModelEntity(mesh: innerGlowMesh, materials: [innerGlowMat])
        innerGlow.name = "OrbInnerGlow"
        orbParent.addChild(innerGlow)
        
        // Mid glow layer
        let midGlowMesh = MeshResource.generateSphere(radius: 0.13)
        var midGlowMat = UnlitMaterial()
        midGlowMat.color = .init(tint: glowTeal.withAlphaComponent(0.4))
        let midGlow = ModelEntity(mesh: midGlowMesh, materials: [midGlowMat])
        midGlow.name = "OrbMidGlow"
        orbParent.addChild(midGlow)
        
        // Outer glow layer (soft bloom)
        let outerGlowMesh = MeshResource.generateSphere(radius: 0.2)
        var outerGlowMat = UnlitMaterial()
        outerGlowMat.color = .init(tint: primaryTeal.withAlphaComponent(0.2))
        let outerGlow = ModelEntity(mesh: outerGlowMesh, materials: [outerGlowMat])
        outerGlow.name = "OrbOuterGlow"
        orbParent.addChild(outerGlow)
        
        // Orbiting energy particles
        for i in 0..<8 {
            let angle = Float(i) * (Float.pi * 2 / 8)
            let particleMesh = MeshResource.generateSphere(radius: 0.015)
            var particleMat = UnlitMaterial()
            particleMat.color = .init(tint: brightCyan)
            let particle = ModelEntity(mesh: particleMesh, materials: [particleMat])
            particle.name = "OrbParticle_\(i)"
            particle.position = [cos(angle) * 0.15, sin(angle) * 0.15, 0]
            orbParent.addChild(particle)
        }
        
        // Light source (bright, illuminates scene)
        let light = Entity()
        var lightComp = PointLightComponent()
        lightComp.intensity = Float(80000)
        lightComp.color = glowTeal
        lightComp.attenuationRadius = Float(4.0)
        light.components.set(lightComp)
        light.position = .zero  // Centered in sphere parent
        sphereParent.addChild(light)
        
        sphereParent.scale = .zero  // Start hidden
    }
    
    // MARK: - Human Return (FPP IMMERSIVE - Light emanates FROM user, burdens float away)
    // FPP PARADIGM: NO human figure - the user IS the human
    // Instead: warm light emanates from user's chest area outward, particles of burden float away
    
    @MainActor
    private func buildHumanReturn() async {
        // Teal color theme (matches iPad)
        let glowTeal = UIColor(red: 0.1, green: 0.8, blue: 0.95, alpha: 1.0)
        
        // === FPP: NO FIGURE - User IS the human ===
        // We don't need humanFigure or humanFigureBillboard
        humanFigure = nil
        humanFigureBillboard = nil
        
        // === SIMPLE LENS FLARE FOR HUMAN RETURN using POINT LIGHTS ===
        let glowParent = Entity()
        glowParent.name = "RestorationGlow"
        glowParent.position = [0, 1.3, 0]  // At user's chest level
        
        // 1. MAIN POINT LIGHT - This creates the actual glow effect
        let mainLight = Entity()
        mainLight.name = "RestoreLight"
        var mainLightComp = PointLightComponent()
        mainLightComp.intensity = Float(100000)  // Bright!
        mainLightComp.color = glowTeal
        mainLightComp.attenuationRadius = Float(5.0)
        mainLight.components.set(mainLightComp)
        mainLight.scale = .zero
        glowParent.addChild(mainLight)
        
        // 2. TINY BRIGHT CORE - emissive material for actual glow
        let coreMesh = MeshResource.generateSphere(radius: 0.02)
        var coreMat = PhysicallyBasedMaterial()
        coreMat.baseColor = .init(tint: .white)
        coreMat.emissiveColor = .init(color: glowTeal)
        coreMat.emissiveIntensity = 6.0
        let core = ModelEntity(mesh: coreMesh, materials: [coreMat])
        core.name = "RestoreFlareCore"
        core.scale = .zero
        glowParent.addChild(core)
        
        // Streak plane removed - rendered as solid bar, not glow
        
        // 4. LEFT COLOR FRINGE - point light (blue-shifted)
        let leftLight = Entity()
        leftLight.name = "RestoreFringeLeft"
        var leftLightComp = PointLightComponent()
        leftLightComp.intensity = Float(20000)
        leftLightComp.color = UIColor(red: 0.2, green: 0.4, blue: 0.95, alpha: 1.0)
        leftLightComp.attenuationRadius = Float(2.0)
        leftLight.components.set(leftLightComp)
        leftLight.position = [-0.9, 0, 0]
        leftLight.scale = .zero
        glowParent.addChild(leftLight)
        
        // 5. RIGHT COLOR FRINGE - point light (warmer cyan)
        let rightLight = Entity()
        rightLight.name = "RestoreFringeRight"
        var rightLightComp = PointLightComponent()
        rightLightComp.intensity = Float(20000)
        rightLightComp.color = UIColor(red: 0.0, green: 0.95, blue: 0.6, alpha: 1.0)
        rightLightComp.attenuationRadius = Float(2.0)
        rightLight.components.set(rightLightComp)
        rightLight.position = [0.9, 0, 0]
        rightLight.scale = .zero
        glowParent.addChild(rightLight)
        
        // 6. CENTER DOT - small emissive sphere
        let centerMesh = MeshResource.generateSphere(radius: 0.01)
        var centerMat = PhysicallyBasedMaterial()
        centerMat.baseColor = .init(tint: .white)
        centerMat.emissiveColor = .init(color: .white)
        centerMat.emissiveIntensity = 10.0
        let centerDot = ModelEntity(mesh: centerMesh, materials: [centerMat])
        centerDot.name = "RestoreCenter"
        centerDot.scale = .zero
        glowParent.addChild(centerDot)
        
        // Point Light at user's chest (illuminates the scene from their position)
        let restLight = Entity()
        var restLightComp = PointLightComponent()
        restLightComp.intensity = Float(60000)
        restLightComp.color = glowTeal
        restLightComp.attenuationRadius = Float(6.0)
        restLight.components.set(restLightComp)
        glowParent.addChild(restLight)
        
        glowParent.scale = .zero
        experienceRoot.addChild(glowParent)
        restorationGlow = glowParent
        
        // === FPP: BURDEN PARTICLES floating AWAY from user in all directions ===
        for i in 0..<30 {
            let debrisMesh = MeshResource.generateBox(width: 0.03, height: 0.03, depth: 0.03)
            var debrisMat = PhysicallyBasedMaterial()
            debrisMat.baseColor = .init(tint: UIColor(white: 0.2, alpha: 1.0))
            debrisMat.roughness = 0.8
            debrisMat.emissiveColor = .init(color: UIColor(red: 1.0, green: 0.3, blue: 0.1, alpha: 1.0))
            debrisMat.emissiveIntensity = 0.5
            
            let debris = ModelEntity(mesh: debrisMesh, materials: [debrisMat])
            debris.name = "Debris_\(i)"
            
            // Start close to user, will animate outward
            let theta = Float.random(in: 0...(2 * Float.pi))
            let phi = Float.random(in: 0.3...2.8)
            let startRadius = Float.random(in: 0.5...1.0)
            
            debris.position = [
                cos(theta) * sin(phi) * startRadius,
                1.3 + cos(phi) * startRadius,  // Centered on user's chest
                sin(theta) * sin(phi) * startRadius
            ]
            
            debris.orientation = simd_quatf(angle: Float.random(in: 0...Float.pi * 2), axis: normalize([1, 1, 1]))
            debris.scale = .zero
            experienceRoot.addChild(debris)
            debrisParticles.append(debris)
        }
        
        // === FPP: RISING PARTICLES around user (sense of liberation, rising up) ===
        for i in 0..<20 {
            let particleMesh = MeshResource.generateSphere(radius: 0.015)
            var particleMat = UnlitMaterial()
            particleMat.color = .init(tint: glowTeal.withAlphaComponent(0.6))
            
            let particle = ModelEntity(mesh: particleMesh, materials: [particleMat])
            particle.name = "Rising_\(i)"
            
            // Distributed around user at various heights
            let theta = Float.random(in: 0...(2 * Float.pi))
            let radius = Float.random(in: 1.0...3.0)
            
            particle.position = [
                cos(theta) * radius,
                Float.random(in: -1.0...0.5),  // Start below/at user level
                sin(theta) * radius
            ]
            particle.scale = .zero
            experienceRoot.addChild(particle)
            // Reuse an array - these will rise during animation
        }
    }
    
    // MARK: - CTA Portal (FPP IMMERSIVE - Horizon of possibility user could step INTO)
    // FPP PARADIGM: Portal appears IN FRONT of user, inviting them forward into the future
    
    @MainActor
    private func buildCTAPortal() async {
        // Portal is a GOLDEN HORIZON ahead of the user - beckoning forward
        let horizonCenter: SIMD3<Float> = [0, 1.6, -3.0]  // Closer, more present
        
        // Colors for dramatic gold/amber theme
        let brightGold = UIColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0)
        let warmGold = UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
        
        // === SIMPLE LENS FLARE CTA using POINT LIGHTS ===
        let horizonParent = Entity()
        horizonParent.name = "PortalGlow"
        horizonParent.position = horizonCenter
        horizonParent.scale = .zero
        experienceRoot.addChild(horizonParent)
        portalGlow = horizonParent
        
        // 1. MAIN POINT LIGHT - This creates the actual glow effect
        let mainLight = Entity()
        mainLight.name = "CTALight"
        var mainLightComp = PointLightComponent()
        mainLightComp.intensity = Float(120000)  // Very bright!
        mainLightComp.color = warmGold
        mainLightComp.attenuationRadius = Float(6.0)
        mainLight.components.set(mainLightComp)
        horizonParent.addChild(mainLight)
        
        // 2. TINY BRIGHT CORE - emissive material for actual glow
        let coreMesh = MeshResource.generateSphere(radius: 0.025)
        var coreMat = PhysicallyBasedMaterial()
        coreMat.baseColor = .init(tint: .white)
        coreMat.emissiveColor = .init(color: brightGold)
        coreMat.emissiveIntensity = 8.0
        let core = ModelEntity(mesh: coreMesh, materials: [coreMat])
        core.name = "CTAFlareCore"
        horizonParent.addChild(core)
        
        // Streak plane removed - rendered as solid bar, not glow
        
        // 4. LEFT COLOR FRINGE - point light (blue-shifted)
        let leftLight = Entity()
        leftLight.name = "CTAFringeLeft"
        var leftLightComp = PointLightComponent()
        leftLightComp.intensity = Float(25000)
        leftLightComp.color = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
        leftLightComp.attenuationRadius = Float(2.5)
        leftLight.components.set(leftLightComp)
        leftLight.position = [-1.0, 0, 0]
        horizonParent.addChild(leftLight)
        
        // 5. RIGHT COLOR FRINGE - point light (red-shifted)
        let rightLight = Entity()
        rightLight.name = "CTAFringeRight"
        var rightLightComp = PointLightComponent()
        rightLightComp.intensity = Float(25000)
        rightLightComp.color = UIColor(red: 1.0, green: 0.4, blue: 0.2, alpha: 1.0)
        rightLightComp.attenuationRadius = Float(2.5)
        rightLight.components.set(rightLightComp)
        rightLight.position = [1.0, 0, 0]
        horizonParent.addChild(rightLight)
        
        // 6. CENTER DOT - small emissive sphere
        let centerMesh = MeshResource.generateSphere(radius: 0.012)
        var centerMat = PhysicallyBasedMaterial()
        centerMat.baseColor = .init(tint: .white)
        centerMat.emissiveColor = .init(color: .white)
        centerMat.emissiveIntensity = 12.0
        let centerDot = ModelEntity(mesh: centerMesh, materials: [centerMat])
        centerDot.name = "CTACenter"
        horizonParent.addChild(centerDot)
        
        // Point light at horizon (additional)
        let horizonLight = Entity()
        var horizonLightComp = PointLightComponent()
        horizonLightComp.intensity = Float(80000)
        horizonLightComp.color = warmGold
        horizonLightComp.attenuationRadius = Float(6.0)
        horizonLight.components.set(horizonLightComp)
        horizonParent.addChild(horizonLight)
        
        // === SPIRAL GALAXY EFFECT (particles arranged in spiral arms) ===
        for arm in 0..<3 {
            let armOffset = Float(arm) * (Float.pi * 2 / 3)
            for i in 0..<20 {
                let t = Float(i) / 20.0
                let spiralAngle = armOffset + t * Float.pi * 2
                let spiralRadius = 0.3 + t * 0.8
                
                let particleMesh = MeshResource.generateSphere(radius: 0.012 - t * 0.006)
                var particleMat = UnlitMaterial()
                let alpha = 0.7 - t * 0.4
                particleMat.color = .init(tint: warmGold.withAlphaComponent(CGFloat(max(0.15, alpha))))
                
                let particle = ModelEntity(mesh: particleMesh, materials: [particleMat])
                particle.name = "Spiral_\(arm)_\(i)"
                particle.position = [
                    cos(spiralAngle) * spiralRadius,
                    sin(spiralAngle) * spiralRadius * 0.3,  // Flattened
                    -t * 0.3  // Slight depth
                ]
                particle.scale = .zero
                horizonParent.addChild(particle)
            }
        }
        
        // === MINIMAL RECEDING RINGS (just 3 subtle rings, positioned BEHIND/ABOVE text) ===
        // Text is at approx [0, 1.5-1.7, -1.0], so position particles at edges of view
        for ring in 0..<3 {
            let ringDepth = Float(ring) * 1.2 + 1.5  // Further behind horizon
            let ringRadius = 0.8 + Float(ring) * 0.3
            let numParticles = 8  // Much fewer particles
            
            for i in 0..<numParticles {
                let angle = Float(i) * (Float.pi * 2 / Float(numParticles)) + Float(ring) * 0.3
                let particleMesh = MeshResource.generateSphere(radius: 0.012)
                var particleMat = UnlitMaterial()
                let alpha = 0.4 - Float(ring) * 0.1
                particleMat.color = .init(tint: warmGold.withAlphaComponent(CGFloat(max(0.1, alpha))))
                
                let particle = ModelEntity(mesh: particleMesh, materials: [particleMat])
                particle.name = "PortalRing_\(ring)_\(i)"
                particle.position = horizonCenter + [
                    cos(angle) * ringRadius,
                    sin(angle) * ringRadius * 0.6,  // More vertical spread
                    -ringDepth
                ]
                particle.scale = .zero
                experienceRoot.addChild(particle)
                portalRings.append(particle)
            }
        }
        
        // === SPARSE AMBIENT PARTICLES (positioned at EDGES, away from center text) ===
        for i in 0..<12 {
            let particleMesh = MeshResource.generateSphere(radius: Float.random(in: 0.012...0.018))
            var particleMat = UnlitMaterial()
            particleMat.color = .init(tint: warmGold.withAlphaComponent(CGFloat(Float.random(in: 0.25...0.45))))
            
            let particle = ModelEntity(mesh: particleMesh, materials: [particleMat])
            particle.name = "FutureParticle_\(i)"
            
            // Position at EDGES of view, not center where text is
            let angle = Float(i) * (Float.pi * 2 / 12)
            let radius = Float.random(in: 1.5...3.0)  // Further from center
            particle.position = [
                cos(angle) * radius,
                1.5 + sin(angle) * 0.8,  // Spread vertically too
                Float.random(in: -5.0...(-3.0))  // Far ahead/behind
            ]
            particle.scale = .zero
            experienceRoot.addChild(particle)
            beaconPulses.append(particle)
        }
        
        // Removed portalVortex rays - too cluttered
        
        // === POWERFUL HORIZON LIGHT (beckoning forward) ===
        let portalLight = Entity()
        var lightComp = PointLightComponent()
        lightComp.intensity = Float(150000)
        lightComp.color = .init(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
        lightComp.attenuationRadius = Float(15.0)
        portalLight.components.set(lightComp)
        portalLight.position = horizonCenter
        experienceRoot.addChild(portalLight)
    }
    
    // MARK: - Scene Lighting (Studio Setup)
    
    private func addSceneLighting() {
        // 1. Key Light (Warm, from top-right)
        let keyLight = Entity()
        var keyComp = PointLightComponent()
        keyComp.intensity = Float(80000)
        keyComp.color = .init(red: 1.0, green: 0.9, blue: 0.8, alpha: 1.0)
        keyComp.attenuationRadius = Float(25)
        keyLight.components.set(keyComp)
        keyLight.position = [2, 4, 2]
        experienceRoot.addChild(keyLight)
        
        // 2. Fill Light (Cool, from left)
        let fillLight = Entity()
        var fillComp = PointLightComponent()
        fillComp.intensity = Float(40000)
        fillComp.color = .init(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        fillComp.attenuationRadius = Float(20)
        fillLight.components.set(fillComp)
        fillLight.position = [-3, 1, 1]
        experienceRoot.addChild(fillLight)
        
        // 3. Rim Light (Bright, from behind)
        let rimLight = Entity()
        var rimComp = PointLightComponent()
        rimComp.intensity = Float(100000)
        rimComp.color = .init(white: 1.0, alpha: 1.0)
        rimComp.attenuationRadius = Float(15)
        rimLight.components.set(rimComp)
        rimLight.position = [0, 3, -6] // Behind the scene objects
        experienceRoot.addChild(rimLight)
        
        // 4. Ambient Environment (IBL Simulation)
        // Since we can't easily load an HDR here without asset, we use a weak fill light
        let ambientFill = Entity()
        var ambientComp = PointLightComponent()
        ambientComp.intensity = Float(10000)
        ambientComp.color = .init(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        ambientComp.attenuationRadius = Float(15.0)
        ambientFill.components.set(ambientComp)
        ambientFill.position = [0, 5, 0]
        experienceRoot.addChild(ambientFill)
    }
    
    // MARK: - Animation Loop
    
    @MainActor
    private func animateScene(dt: Float) {
        guard sceneLoaded else { return }
        
        let phase = viewModel.currentPhase
        let progress = Float(viewModel.phaseProgress)
        
        // === DYNAMIC LIGHTING ===
        if let keyLight = experienceRoot.children.first(where: { $0.components.has(PointLightComponent.self) }) {
            keyLight.position.x = 2 + sin(animationTime * 0.5) * 0.5
        }
        
        // === ATMOSPHERIC DRIFT (Nebula & Rays) ===
        for (i, nebula) in nebulaClouds.enumerated() {
            nebula.orientation *= simd_quatf(angle: dt * 0.02 * (i % 2 == 0 ? 1 : -1), axis: [0, 1, 0])
            nebula.scale = SIMD3<Float>(repeating: 1.0 + sin(animationTime * 0.2 + Float(i)) * 0.05)
        }
        // === AMBIENT STARS ===
        for (i, star) in ambientParticles.enumerated() {
            let driftX = sin(animationTime * 0.2 + Float(i) * 0.1) * 0.0005
            let driftY = cos(animationTime * 0.15 + Float(i) * 0.15) * 0.0005
            star.position += [driftX, driftY, 0]
            
            if star.name.hasPrefix("StarMid") {
                let twinkle = 0.8 + sin(animationTime * 3 + Float(i)) * 0.4
                star.scale = SIMD3<Float>(repeating: twinkle)
            }
            
            // Warp effect during CTA (stars pulled toward portal)
            if phase == .stillnessCTA {
                let pull = normalize([0, 1.6, -2.3] - star.position)  // Portal center
                star.position += pull * dt * progress * 0.5
            }
        }
        
        // Phase-specific animations
        switch phase {
        case .microColdOpen:
            animateMicroColdOpen(progress: progress, dt: dt)
            
        case .narratorFrame:
            animateNarratorFrame(progress: progress, dt: dt)
            
        case .spatialOverwhelm, .realityCrack, .humanFragment:
            animateVignettes(progress: progress, dt: dt, subPhase: phase)
            
        case .patternBreak:
            animatePatternBreak(progress: progress, dt: dt)
            
        case .agenticOrchestration:
            animateAgenticOrchestration(progress: progress, dt: dt)
            
        case .humanReturn:
            animateHumanReturn(progress: progress, dt: dt)
            
        case .personalization:
            animatePersonalization(progress: progress, dt: dt)
            
        case .stillnessCTA:
            animateCTA(progress: progress, dt: dt)
            
        case .waiting:
            // Scene not yet active - keep everything hidden
            break
            
        case .complete:
            // Experience finished - gentle fade of remaining elements
            animateComplete(dt: dt)
        }
    }
    
    // MARK: - Complete Animation (Gentle Fade)
    
    @MainActor
    private func animateComplete(dt: Float) {
        // Gently fade all elements
        let fadeSpeed: Float = 0.5
        
        for ring in portalRings {
            ring.scale = SIMD3<Float>(repeating: max(0, ring.scale.x - dt * fadeSpeed))
        }
        portalGlow?.scale = SIMD3<Float>(repeating: max(0, (portalGlow?.scale.x ?? 0) - dt * fadeSpeed))
        
        for pulse in beaconPulses {
            pulse.scale = SIMD3<Float>(repeating: max(0, pulse.scale.x - dt * fadeSpeed))
        }
    }
    
    // MARK: - Micro Cold Open Animation (Black void with ambient particles)
    
    @MainActor
    private func animateMicroColdOpen(progress: Float, dt: Float) {
        // Fade in ambient particles gradually
        let fadeIn = smoothstep(progress)
        
        for (i, star) in ambientParticles.enumerated() {
            let stagger = Float(i) * 0.01
            let starProgress = smoothstep(max(0, fadeIn - stagger))
            star.scale = SIMD3<Float>(repeating: starProgress)
        }
        
        // Nebula slowly becomes visible
        for nebula in nebulaClouds {
            nebula.scale = SIMD3<Float>(repeating: fadeIn * 0.5)
        }
    }
    
    // MARK: - Narrator Frame Animation (Floating Work Windows - matches iPad)
    
    @MainActor
    private func animateNarratorFrame(progress: Float, dt: Float) {
        let entranceFade = self.entranceFade(progress: progress)
        let exitFade = self.exitFade(progress: progress)
        let phaseFade = entranceFade * exitFade
        
        // === WORK WINDOWS - Staggered entrance, floating motion ===
        for (i, window) in workWindows.enumerated() {
            let stagger = Float(i) * 0.03
            let windowProgress = smoothstep(max(0, min(1, (progress - stagger) * 2.5)))
            
            // Scale in with overshoot
            let targetScale = easeOutBack(windowProgress) * phaseFade
            window.scale = SIMD3<Float>(repeating: targetScale * 0.8)
            
            // Floating motion (like iPad's gentle drift)
            let floatX = sin(animationTime * 0.3 + Float(i) * 0.5) * 0.02
            let floatY = cos(animationTime * 0.25 + Float(i) * 0.7) * 0.015
            let floatZ = sin(animationTime * 0.2 + Float(i) * 0.3) * 0.01
            window.position += [floatX * dt, floatY * dt, floatZ * dt]
            
            // Gentle rotation wobble
            window.orientation *= simd_quatf(
                angle: sin(animationTime * 0.5 + Float(i)) * dt * 0.02,
                axis: [0, 1, 0]
            )
            
            // Opacity decreases as progress increases (windows fading as story progresses)
            _ = 1.0 - progress * 0.6  // fadeOut - computed but not used
        }
        
        // === SCAN LINES - Subtle scrolling effect ===
        for scan in scanLines {
            scan.scale = SIMD3<Float>(repeating: phaseFade * 0.5)
            // Move down slowly
            scan.position.y -= dt * 0.1
            if scan.position.y < -1.5 {
                scan.position.y = 1.5
            }
        }
        
        // === AMBIENT PARTICLES - More active during narrator frame ===
        for (i, star) in ambientParticles.enumerated() {
            let twinkle = 0.7 + sin(animationTime * 2.5 + Float(i) * 0.3) * 0.3
            star.scale = SIMD3<Float>(repeating: twinkle * phaseFade)
        }
    }
    
    // MARK: - Vignette Animation (FPP IMMERSIVE - User SURROUNDED by sector ambiance)
    
    @MainActor
    private func animateVignettes(progress: Float, dt: Float, subPhase: NarrativePhase) {
        let sectorIndex: Int
        let localProgress: Float
        
        switch subPhase {
        case .spatialOverwhelm: sectorIndex = 0; localProgress = progress
        case .realityCrack: sectorIndex = 1; localProgress = progress
        case .humanFragment: sectorIndex = 2; localProgress = progress
        default: return
        }
        
        // Apply phase fade for smooth transitions
        let fade = phaseFade(progress: localProgress)
        
        // === HIDE WORK WINDOWS from narrator frame ===
        for window in workWindows {
            window.scale = SIMD3<Float>(repeating: max(0, window.scale.x - dt * 2.0))
        }
        // scanLines are no longer created
        
        // === HIDE ALL OTHER SECTORS with smooth fade ===
        for (i, sector) in sectorGlows.enumerated() {
            if i != sectorIndex {
                sector.scale = SIMD3<Float>(repeating: max(0, sector.scale.x - dt * 3.0))
            }
        }
        
        // === FPP: ANIMATE FLOATING DATA BITS drifting around user ===
        for (i, bit) in dataStreams.enumerated() {
            let bitSector = i / 20  // 20 bits per sector
            if bitSector == sectorIndex {
                // Gentle orbital motion around user
                let orbitSpeed = 0.3 + Float(i % 5) * 0.1
                bit.scale = SIMD3<Float>(repeating: fade)
                
                // Orbit around Y axis (user is at center)
                let currentAngle = atan2(bit.position.z, bit.position.x)
                let radius = sqrt(bit.position.x * bit.position.x + bit.position.z * bit.position.z)
                let newAngle = currentAngle + dt * orbitSpeed
                bit.position.x = cos(newAngle) * radius
                bit.position.z = sin(newAngle) * radius
                
                // Gentle vertical bobbing
                bit.position.y += sin(animationTime * 1.5 + Float(i)) * dt * 0.2
            } else {
                bit.scale = .zero
            }
        }
        
        // === FPP: ANIMATE SECTOR ELEMENTS ===
        if sectorIndex < sectorGlows.count {
            let sectorParent = sectorGlows[sectorIndex]
            
            // Smooth entrance
            let entranceProgress = smoothstep(min(1.0, localProgress * 2.5))
            sectorParent.scale = SIMD3<Float>(repeating: 1.0)
            
            for child in sectorParent.children {
                // === MAIN LIGHT - intensity pulse ===
                if child.name.hasPrefix("FlareLight_") {
                    let lightProgress = smoothstep(entranceProgress * 1.2)
                    child.scale = SIMD3<Float>(repeating: lightProgress * fade)
                    
                    // Pulse the light intensity
                    if var lightComp = child.components[PointLightComponent.self] {
                        let pulse = 0.7 + sin(animationTime * 2.5) * 0.3
                        lightComp.intensity = Float(80000 * lightProgress * pulse * fade)
                        child.components.set(lightComp)
                    }
                }
                
                // === CORE - bright center with dramatic pulse ===
                if child.name.hasPrefix("FlareCore_") {
                    let coreProgress = smoothstep(entranceProgress * 1.5)
                    let pulse = 0.85 + sin(animationTime * 3.5) * 0.15
                    child.scale = SIMD3<Float>(repeating: min(1.0, coreProgress) * pulse * fade)
                }
                
                // Streak animation removed - planes caused rendering issues
                
                // === FRINGES - subtle pulse ===
                if child.name.hasPrefix("FringeLeft_") || child.name.hasPrefix("FringeRight_") {
                    let fringeProgress = smoothstep(max(0, (entranceProgress - 0.15) * 1.5))
                    let pulse = 0.75 + sin(animationTime * 2.0) * 0.25
                    child.scale = SIMD3<Float>(repeating: fringeProgress * pulse * fade)
                    
                    // Pulse the light intensity
                    if var lightComp = child.components[PointLightComponent.self] {
                        lightComp.intensity = Float(15000 * fringeProgress * pulse * fade)
                        child.components.set(lightComp)
                    }
                }
                
                // CENTER DOT removed - was visible in the middle of text
                
                // === AMBIENT PARTICLES - gentle drift ===
                if child.name.hasPrefix("AmbientParticle") {
                    let parts = child.name.split(separator: "_")
                    let i = Int(parts.last ?? "0") ?? 0
                    
                    let stagger = Float(i) * 0.02
                    let particleProgress = smoothstep(max(0, min(1, (entranceProgress - stagger) * 2.0)))
                    let pulse = 0.6 + sin(animationTime * 1.2 + Float(i) * 0.4) * 0.3
                    child.scale = SIMD3<Float>(repeating: particleProgress * pulse * fade)
                    
                    // Slow drift
                    let driftX = sin(animationTime * 0.15 + Float(i) * 0.3) * dt * 0.08
                    let driftY = cos(animationTime * 0.12 + Float(i) * 0.2) * dt * 0.06
                    let driftZ = sin(animationTime * 0.1 + Float(i) * 0.5) * dt * 0.08
                    child.position += [driftX, driftY, driftZ]
                }
            }
        }
        
        // === CARDS (text handled by overlay, no 3D cards needed) ===
        let cards = sectorIndex == 0 ? financeCards : (sectorIndex == 1 ? supplyCards : healthcareCards)
        for (i, card) in cards.enumerated() {
            let stagger = 0.3 + Float(i) * 0.1
            let cardProg = max(0, min(1, (localProgress - stagger) * 3))
            card.scale = SIMD3<Float>(repeating: easeOutBack(cardProg) * fade)
            card.position.y = -0.35 + sin(animationTime * 1.5 + Float(i)) * 0.01
        }
        
        // === PARTICLES ===
        for (i, particle) in sectorParticles.enumerated() {
            let particleSector = i / 30  // OPTIMIZED: 30 particles per sector
            if particleSector == sectorIndex {
                particle.scale = SIMD3<Float>(repeating: min(1.0, localProgress * 2))
                particle.orientation *= simd_quatf(angle: dt * (0.5 + Float(i % 10) * 0.05), axis: [0, 1, 0])
            }
        }
    }
    
    // MARK: - Pattern Break Animation (matches iPad: Light BG, Fading Windows, Question)
    // Creates the dramatic "white flash" moment before Agentic Orchestration
    
    @MainActor
    private func animatePatternBreak(progress: Float, dt: Float) {
        // Exit fade for smooth transition to agentic
        let exitFade = self.exitFade(progress: progress)
        _ = self.entranceFade(progress: progress)  // entranceFade computed but not used
        
        // === HIDE ALL WORK WINDOWS ===
        for window in workWindows {
            window.scale = SIMD3<Float>(repeating: max(0, window.scale.x - dt * 3.0))
        }
        
        // Fade out all sector elements - work windows dissolving (matches iPad)
        let decaySpeed = 2.5 + progress * 4.0  // Faster decay to clear the space
        for sector in sectorGlows {
            sector.scale = SIMD3<Float>(repeating: max(0, sector.scale.x - dt * decaySpeed))
        }
        for card in financeCards + supplyCards + healthcareCards {
            // Cards fade with slight rotation (like iPad's 3D perspective fade)
            card.scale = SIMD3<Float>(repeating: max(0, card.scale.x - dt * decaySpeed * 1.2))
            card.orientation *= simd_quatf(angle: dt * 0.5 * progress, axis: [0.5, 1, 0])
        }
        for particle in sectorParticles {
            particle.scale = SIMD3<Float>(repeating: max(0, particle.scale.x - dt * 2.5))
        }
        
        // Data streams fade out too
        for bit in dataStreams {
            bit.scale = SIMD3<Float>(repeating: max(0, bit.scale.x - dt * 3.0))
        }
        
        // === WHITE LIGHT BLOOM (The "Pattern Break" moment - like iPad's white background) ===
        // Stars get MUCH BRIGHTER - creating the "white flash" effect
        let brightnessRamp = smoothstep(progress)
        let whiteFlash = brightnessRamp * 5.0  // Intense brightening
        
        for (i, star) in ambientParticles.enumerated() {
            let intensity: Float = 1.0 + whiteFlash
            let pulse = sin(animationTime * 4 + Float(i) * 0.2) * 0.4 * brightnessRamp
            star.scale = SIMD3<Float>(repeating: (intensity + pulse) * exitFade)
            
            // Stars drift toward center (focus effect)
            let centerPull = normalize([0, 1.6, -2.0] - star.position) * dt * brightnessRamp * 0.3
            star.position += centerPull
        }
        
        // Nebulas BLOOM outward and brighten dramatically
        for nebula in nebulaClouds {
            let expandFactor = 1.0 + brightnessRamp * 2.0  // Much bigger expansion
            nebula.scale = SIMD3<Float>(repeating: expandFactor)
            
            // Rotate outward for "explosion" feel
            nebula.orientation *= simd_quatf(angle: dt * 0.3 * brightnessRamp, axis: [0, 1, 0])
        }
        
        // Shockwave rings removed - caused rendering issues
    }
    
    // MARK: - Agentic Orchestration Animation (FPP - User INSIDE network that coalesces)
    
    @MainActor
    private func animateAgenticOrchestration(progress: Float, dt: Float) {
        // === FPP ANIMATION: Dots around user → Connect → Shrink to front → PERSIST ===
        
        // Phase 1: Points appear ALL AROUND user (0-20%)
        let pointsPhase = min(1.0, progress / 0.20)
        
        // Phase 2: Connections form (15-40%)
        let connectPhase = min(1.0, max(0, (progress - 0.15) / 0.25))
        
        // Phase 3: Shrink and move to front (35-60%)
        let shrinkPhase = min(1.0, max(0, (progress - 0.35) / 0.25))
        
        // Phase 4: Central orb appears (55-75%)
        let orbPhase = min(1.0, max(0, (progress - 0.55) / 0.20))
        
        // Phase 5: Text visible, sphere persists (70%+)
        // NO EXIT FADE - sphere structure persists until next phase
        
        // === POSITIONS ===
        // Text overlay is at [0, 1.55, -1.0] - sphere ABOVE and BEHIND
        let userCenter: SIMD3<Float> = [0, 1.6, 0]
        let coalescedCenter: SIMD3<Float> = [0, 2.0, -2.2]  // Higher and further back
        let surroundRadius: Float = 2.5
        let coalescedRadius: Float = 0.4
        
        // === SPHERE CONTAINER - moves from user to front ===
        guard let sphere = orchestratorEntity else { return }
        sphere.scale = SIMD3<Float>(repeating: 1.0)
        
        // Interpolate position from user center to coalesced center
        let shrinkEase = easeInOutQuad(shrinkPhase)
        sphere.position = simd_mix(userCenter, coalescedCenter, SIMD3<Float>(repeating: shrinkEase))
        
        // Continuous rotation (faster once formed, persists in text phase)
        let rotationSpeed: Float = shrinkPhase > 0.5 ? 0.25 : 0.1
        sphere.orientation *= simd_quatf(angle: dt * rotationSpeed, axis: [0, 1, 0])
        
        // Calculate current radius (shrinks during shrinkPhase)
        let currentRadius = simd_mix(surroundRadius, coalescedRadius, shrinkEase)
        let radiusRatio = currentRadius / surroundRadius  // 1.0 → ~0.16
        
        // === NODE POINTS (appear, shrink, PERSIST) ===
        let numNodes = agentEntities.count
        for (i, node) in agentEntities.enumerated() {
            // Staggered appearance
            let stagger = Float(i) / Float(max(1, numNodes))
            let nodeProg = smoothstep(max(0, min(1, (pointsPhase - stagger * 0.5) * 2.5)))
            
            // Pop-in with overshoot
            let nodeScale = easeOutBack(nodeProg)
            
            // Gentle pulse when fully visible
            let pulse = nodeProg > 0.8 ? (1.0 + sin(animationTime * 2.0 + Float(i) * 0.4) * 0.1) : 1.0
            
            // Nodes persist at final size - NO EXIT FADE
            let finalScale = max(0.4, radiusRatio)  // Don't shrink too small
            node.scale = SIMD3<Float>(repeating: nodeScale * pulse * finalScale)
            
            // Update position based on current radius
            if i < nodeOriginalPositions.count {
                let originalPos = nodeOriginalPositions[i]
                let unitDir = simd_normalize(originalPos)
                node.position = unitDir * currentRadius
            }
        }
        
        // === NODE GLOW HALOS (follow nodes, persist) ===
        for child in sphere.children where child.name.hasPrefix("NodeGlow_") {
            if let indexStr = child.name.split(separator: "_").last,
               let i = Int(indexStr),
               i < nodeOriginalPositions.count {
                
                let stagger = Float(i) / Float(max(1, numNodes))
                let nodeProg = smoothstep(max(0, min(1, (pointsPhase - stagger * 0.5) * 2.5)))
                
                let glowScale = nodeProg * 0.5
                let pulse = 0.9 + sin(animationTime * 1.5 + Float(i) * 0.3) * 0.1
                let finalScale = max(0.4, radiusRatio)
                child.scale = SIMD3<Float>(repeating: glowScale * pulse * finalScale)
                
                // Update position to match node
                let originalPos = nodeOriginalPositions[i]
                let unitDir = simd_normalize(originalPos)
                child.position = unitDir * currentRadius
            }
        }
        
        // === CONNECTION LINES (appear, shrink WITH POSITION, persist) ===
        for (i, connection) in connectionArcs.enumerated() {
            let numConnections = connectionArcs.count
            let stagger = Float(i) / Float(max(1, numConnections))
            let connProg = smoothstep(max(0, min(1, (connectPhase - stagger * 0.3) * 2.5)))
            
            // Connections SCALE with the shrinking sphere - affects both size and position
            connection.scale = SIMD3<Float>(repeating: connProg * radiusRatio)
            
            // Also update connection position proportionally
            let originalPos = connection.position
            if simd_length(originalPos) > 0.01 {
                let unitDir = simd_normalize(originalPos)
                connection.position = unitDir * currentRadius
            }
        }
        
        // === CENTRAL ORB (Appears after sphere shrinks, persists) ===
        if let orb = taskOrb {
            let orbScale = easeOutBack(smoothstep(orbPhase))
            let orbPulse = 1.0 + sin(animationTime * 1.5) * 0.15 * orbPhase
            orb.scale = SIMD3<Float>(repeating: orbScale * orbPulse * 1.5)  // Larger orb
            orb.position = .zero
        }
    }
    
    // MARK: - Human Return Animation (FPP - Light emanates from user, burdens dissolve)
    
    @MainActor
    private func animateHumanReturn(progress: Float, dt: Float) {
        // Smooth entrance fade
        let entranceFade = self.entranceFade(progress: progress)
        let exitFade = self.exitFade(progress: progress)
        let fade = entranceFade * exitFade
        
        // === FADE OUT AGENTIC ELEMENTS ===
        if let orch = orchestratorEntity, orch.scale.x > 0.01 {
            orch.scale = SIMD3<Float>(repeating: max(0, orch.scale.x - dt * 1.5))
        }
        if let orb = taskOrb, orb.scale.x > 0.01 {
            orb.scale = SIMD3<Float>(repeating: max(0, orb.scale.x - dt * 1.5))
        }
        for arc in connectionArcs {
            arc.scale = SIMD3<Float>(repeating: max(0, arc.scale.x - dt * 2.0))
        }
        for agent in agentEntities {
            agent.scale = SIMD3<Float>(repeating: max(0, agent.scale.x - dt * 2.0))
        }
        
        // === SIMPLE LENS FLARE ANIMATION ===
        if progress > 0.1 {
            let glowRaw = (progress - 0.1) / 0.3
            let glowProgress = smoothstep(min(1.0, glowRaw))
            restorationGlow?.scale = SIMD3<Float>(repeating: 1.0)  // Parent always visible
            
            // Animate lens flare elements
            if let glow = restorationGlow {
                for child in glow.children {
                    // Main light - intensity pulse
                    if child.name == "RestoreLight" {
                        child.scale = SIMD3<Float>(repeating: glowProgress * fade)
                        if var lightComp = child.components[PointLightComponent.self] {
                            let pulse = 0.7 + sin(animationTime * 2.5) * 0.3
                            lightComp.intensity = Float(100000 * glowProgress * pulse * fade)
                            child.components.set(lightComp)
                        }
                    }
                    
                    // Core - bright center with pulse
                    if child.name == "RestoreFlareCore" {
                        let coreProgress = smoothstep(glowProgress * 1.5)
                        let pulse = 0.85 + sin(animationTime * 3.5) * 0.15
                        child.scale = SIMD3<Float>(repeating: min(1.0, coreProgress) * pulse * fade)
                    }
                    
                    // Streak animation removed - planes caused rendering issues
                    
                    // Fringes - pulse
                    if child.name == "RestoreFringeLeft" || child.name == "RestoreFringeRight" {
                        let fringeProgress = smoothstep(max(0, (glowProgress - 0.15) * 1.5))
                        let pulse = 0.75 + sin(animationTime * 2.0) * 0.25
                        child.scale = SIMD3<Float>(repeating: fringeProgress * pulse * fade)
                        
                        if var lightComp = child.components[PointLightComponent.self] {
                            lightComp.intensity = Float(20000 * fringeProgress * pulse * fade)
                            child.components.set(lightComp)
                        }
                    }
                    
                    // Center dot - bright pulse
                    if child.name == "RestoreCenter" {
                        let centerProgress = smoothstep(glowProgress)
                        let pulse = 0.85 + sin(animationTime * 4.0) * 0.4
                        child.scale = SIMD3<Float>(repeating: centerProgress * pulse * fade)
                    }
                }
            }
        }
        
        // === FPP: LIGHT RAYS (now handled above as RayParticle_) ===
        // lightRays array now contains RayParticle entities, animated above
        
        // === FPP: EXPANDING RINGS (now handled above as GlowRing_) ===
        // energyArcs array now contains GlowRing entities, animated above
        
        // === FPP: BURDEN DEBRIS floating AWAY from user ===
        for (i, debris) in debrisParticles.enumerated() {
            let stagger = Float(i) * 0.02
            let debrisProgress = smoothstep(max(0, min(1, progress * 2 - stagger)))
            
            if progress < 0.4 {
                // Debris appears
                debris.scale = SIMD3<Float>(repeating: debrisProgress * 0.8)
            } else {
                // Debris floats AWAY from user and fades
                let fadeProgress = (progress - 0.4) / 0.5
                let fadeScale = max(0, 1.0 - smoothstep(fadeProgress))
                debris.scale = SIMD3<Float>(repeating: fadeScale * 0.8)
                
                // Move outward from user (radially)
                let direction = simd_normalize(debris.position - SIMD3<Float>(0, 1.3, 0))
                debris.position += direction * dt * 0.8 * fadeProgress
                
                // Rise up as they fade
                debris.position.y += dt * 0.3 * fadeProgress
                
                // Tumble
                debris.orientation *= simd_quatf(angle: dt * 0.5, axis: normalize([Float(i % 3) + 0.1, 1, Float(i % 2) + 0.1]))
            }
        }
        
        // === FPP: RISING PARTICLES (sense of liberation) ===
        // Find and animate any Rising particles in the scene
        for child in experienceRoot.children where child.name.hasPrefix("Rising_") {
            let i = Int(child.name.split(separator: "_").last ?? "0") ?? 0
            let particleProgress = smoothstep(min(1.0, progress * 1.5))
            
            child.scale = SIMD3<Float>(repeating: particleProgress * fade)
            
            // Rise upward
            child.position.y += dt * 0.4
            
            // Reset when too high
            if child.position.y > 4.0 {
                let theta = Float.random(in: 0...(2 * Float.pi))
                let radius = Float.random(in: 1.0...3.0)
                child.position = [cos(theta) * radius, -1.0, sin(theta) * radius]
            }
        }
    }
    
    // MARK: - Personalization Animation (FPP - Animated impact reveal with ambient glow)
    
    @MainActor
    private func animatePersonalization(progress: Float, dt: Float) {
        let entranceFade = self.entranceFade(progress: progress)
        let exitFade = self.exitFade(progress: progress)
        let fade = entranceFade * exitFade
        
        // === BLUE GLOW INTENSIFIES as impact is revealed ===
        let glowIntensity = smoothstep(progress)
        
        // Restoration glow transitions to blue (impact reveal color)
        if let glow = restorationGlow {
            glow.scale = SIMD3<Float>(repeating: fade)
            
            // Animate light intensity based on reveal progress
            for child in glow.children where child.name == "RestoreLight" {
                if var lightComp = child.components[PointLightComponent.self] {
                    let pulse = 0.8 + sin(animationTime * 2.0) * 0.2
                    lightComp.intensity = Float(80000 * glowIntensity * pulse * fade)
                    // Shift color toward blue as impact is revealed
                    let blueShift = progress
                    lightComp.color = UIColor(
                        red: 0.1 * CGFloat(1 - blueShift),
                        green: 0.4 + 0.3 * CGFloat(blueShift),
                        blue: 0.8 + 0.2 * CGFloat(blueShift),
                        alpha: 1.0
                    )
                    child.components.set(lightComp)
                }
                child.scale = SIMD3<Float>(repeating: glowIntensity * fade)
            }
            
            // Core pulses with the animated number
            for child in glow.children where child.name == "RestoreFlareCore" {
                let numberPulse = 0.9 + sin(animationTime * 3.5) * 0.2
                child.scale = SIMD3<Float>(repeating: glowIntensity * numberPulse * fade)
            }
        }
        
        // Keep rays gently emanating
        for (i, ray) in lightRays.enumerated() {
            let rayPulse = 0.85 + sin(animationTime * 0.4 + Float(i) * 0.3) * 0.15
            ray.scale = SIMD3<Float>(repeating: rayPulse * fade)
        }
        
        // Rings gently pulse and rotate
        for (i, arc) in energyArcs.enumerated() {
            let ringPulse = 0.9 + sin(animationTime * 0.6 + Float(i) * 0.1) * 0.1
            arc.scale = SIMD3<Float>(repeating: ringPulse * fade)
        }
        
        // Debris completely faded
        for debris in debrisParticles {
            debris.scale = SIMD3<Float>(repeating: max(0, debris.scale.x - dt * 1.5))
        }
        
        // === AMBIENT STARS pulse in sync with impact reveal ===
        let impactPulse = sin(Float.pi * progress) * 0.3  // Peak at 50% progress
        for (i, star) in ambientParticles.enumerated() {
            let starPulse = 1.0 + impactPulse * (1.0 + sin(Float(i) * 0.5) * 0.3)
            star.scale = SIMD3<Float>(repeating: starPulse)
        }
    }
    
    // MARK: - CTA Animation (FPP - Horizon beckons user forward into the future)
    
    @MainActor
    private func animateCTA(progress: Float, dt: Float) {
        // Smooth entrance fade
        let entranceFade = self.entranceFade(progress: progress)
        
        // === FADE OUT RESTORATION ELEMENTS ===
        restorationGlow?.scale = SIMD3<Float>(repeating: max(0, (restorationGlow?.scale.x ?? 0) - dt * 0.8))
        for ray in lightRays {
            ray.scale = SIMD3<Float>(repeating: max(0, ray.scale.x - dt * 1.0))
        }
        for arc in energyArcs {
            arc.scale = SIMD3<Float>(repeating: max(0, arc.scale.x - dt * 1.0))
        }
        for debris in debrisParticles {
            debris.scale = SIMD3<Float>(repeating: max(0, debris.scale.x - dt * 1.5))
        }
        
        // === FPP: HORIZON GLOW (hollow rings) grows and beckons ===
        let glowRaw = min(1.0, progress * 1.5)
        let glowProgress = smoothstep(glowRaw)
        portalGlow?.scale = SIMD3<Float>(repeating: 1.0)  // Parent always visible
        
        // Horizon moves slightly closer as we progress (inviting forward)
        portalGlow?.position.z = -4.0 + progress * 0.5
        
        // Animate lens flare elements
        if let horizon = portalGlow {
            for child in horizon.children {
                // === MAIN LIGHT - intensity pulse ===
                if child.name == "CTALight" {
                    child.scale = SIMD3<Float>(repeating: glowProgress * entranceFade)
                    if var lightComp = child.components[PointLightComponent.self] {
                        let pulse = 0.7 + sin(animationTime * 2.0) * 0.3
                        lightComp.intensity = Float(120000 * glowProgress * pulse * entranceFade)
                        child.components.set(lightComp)
                    }
                }
                
                // === CORE - bright center with dramatic pulse ===
                if child.name == "CTAFlareCore" {
                    let coreProgress = smoothstep(glowProgress * 1.6)
                    let pulse = 0.88 + sin(animationTime * 3.0) * 0.12
                    child.scale = SIMD3<Float>(repeating: min(1.0, coreProgress) * pulse * entranceFade)
                }
                
                // Streak animation removed - planes caused rendering issues
                
                // === FRINGES - pulse ===
                if child.name == "CTAFringeLeft" || child.name == "CTAFringeRight" {
                    let fringeProgress = smoothstep(max(0, (glowProgress - 0.1) * 1.5))
                    let pulse = 0.75 + sin(animationTime * 2.0) * 0.25
                    child.scale = SIMD3<Float>(repeating: fringeProgress * pulse * entranceFade)
                    
                    if var lightComp = child.components[PointLightComponent.self] {
                        lightComp.intensity = Float(25000 * fringeProgress * pulse * entranceFade)
                        child.components.set(lightComp)
                    }
                }
                
                // === CENTER DOT - bright pulse ===
                if child.name == "CTACenter" {
                    let centerProgress = smoothstep(glowProgress)
                    let pulse = 0.85 + sin(animationTime * 4.0) * 0.4
                    child.scale = SIMD3<Float>(repeating: centerProgress * pulse * entranceFade)
                }
                
                // Spiral arms - rotate entire spiral
                if child.name.hasPrefix("Spiral_") {
                    let parts = child.name.split(separator: "_")
                    guard parts.count >= 3 else { continue }
                    let arm = Int(parts[1]) ?? 0
                    let i = Int(parts[2]) ?? 0
                    
                    let spiralProgress = smoothstep(max(0, (glowProgress - 0.2) * 1.5))
                    let pulse = 0.7 + sin(animationTime * 1.8 + Float(i) * 0.2 + Float(arm) * 0.8) * 0.3
                    child.scale = SIMD3<Float>(repeating: spiralProgress * pulse * entranceFade)
                    
                    // Rotate entire spiral around Z axis
                    let t = Float(i) / 20.0
                    let armOffset = Float(arm) * (Float.pi * 2 / 3)
                    let spiralAngle = armOffset + t * Float.pi * 2 + animationTime * 0.2
                    let spiralRadius = 0.3 + t * 0.8
                    child.position = [
                        cos(spiralAngle) * spiralRadius,
                        sin(spiralAngle) * spiralRadius * 0.3,
                        -t * 0.3
                    ]
                }
            }
        }
        
        // === FPP: PORTAL RINGS receding into distance - staggered reveal ===
        for (i, particle) in portalRings.enumerated() {
            // Parse ring and particle index from name
            var ringIndex = i / 18  // Approximate particles per ring
            if particle.name.hasPrefix("PortalRing_") {
                let parts = particle.name.split(separator: "_")
                if parts.count >= 2 {
                    ringIndex = Int(parts[1]) ?? (i / 18)
                }
            }
            
            let stagger = Float(ringIndex) * 0.06
            let particleProgress = smoothstep(max(0, min(1, (progress - stagger) * 2.0)))
            
            // Pulse
            let pulse = 0.7 + sin(animationTime * 1.5 + Float(i) * 0.12) * 0.25
            particle.scale = SIMD3<Float>(repeating: particleProgress * pulse * entranceFade)
            
            // Gentle rotation around the portal axis
            let rotSpeed = 0.08 + Float(ringIndex) * 0.015
            let currentAngle = atan2(particle.position.y - 1.5, particle.position.x)
            let radius = sqrt(pow(particle.position.x, 2) + pow(particle.position.y - 1.5, 2))
            let newAngle = currentAngle + dt * rotSpeed
            particle.position.x = cos(newAngle) * radius
            particle.position.y = 1.5 + sin(newAngle) * radius * 0.6
        }
        
        // Portal vortex rays removed - too cluttered
        
        // === FPP: FUTURE PARTICLES drifting toward user ===
        for (i, particle) in beaconPulses.enumerated() {
            let particlePhase = smoothstep(max(0, min(1, (progress - 0.1) * 1.3)))
            particle.scale = SIMD3<Float>(repeating: particlePhase * entranceFade)
            
            // Drift toward user
            particle.position.z += dt * 0.5
            
            // Reset when past user
            if particle.position.z > 1.0 {
                let theta = Float.random(in: 0...(2 * Float.pi))
                let radius = Float.random(in: 0.5...2.0)
                particle.position = [
                    cos(theta) * radius,
                    1.5 + Float.random(in: -0.5...0.5),
                    Float.random(in: -6.0...(-4.0))
                ]
            }
            
            // Gentle pulse
            let pulse = 0.8 + sin(animationTime * 2.0 + Float(i) * 0.3) * 0.2
            if particle.scale.x > 0.01 {
                particle.scale *= pulse
            }
        }
        
        // === STARS WARP TOWARD HORIZON (Hyperspace effect) ===
        if progress > 0.4 {
            let warpIntensity = smoothstep((progress - 0.4) / 0.6)
            for (i, star) in ambientParticles.enumerated() {
                let horizonDir = normalize([0, 1.5, -4.0] - star.position)
                star.position += horizonDir * dt * warpIntensity * 0.4
                
                // Stretch toward horizon
                star.scale.z = 1.0 + warpIntensity * 2.0
            }
        }
    }

    // MARK: - Agent Shape Mesh Creation
    
    private func createAgentMesh(shape: AgentShapeType) -> MeshResource {
        switch shape {
        case .diamond:
            // Tall diamond shape (stretched box rotated)
            return MeshResource.generateBox(width: 0.05, height: 0.07, depth: 0.05, cornerRadius: 0.005)
            
        case .triangle:
            // Forward-pointing triangle (cone approximation)
            return MeshResource.generateCone(height: 0.06, radius: 0.04)
            
        case .star:
            // Star approximated with stretched box (cross pattern would need custom mesh)
            return MeshResource.generateBox(width: 0.08, height: 0.04, depth: 0.04, cornerRadius: 0.01)
            
        case .octagon:
            // Octagon approximated with cylinder with many sides
            return MeshResource.generateCylinder(height: 0.04, radius: 0.045)
            
        case .shield:
            // Shield shape approximated with rounded box
            return MeshResource.generateBox(width: 0.05, height: 0.065, depth: 0.03, cornerRadius: 0.015)
            
        case .circle:
            // Standard sphere
            return MeshResource.generateSphere(radius: 0.04)
        }
    }
    
    // MARK: - Easing Functions (matches iPad for 1:1 parity)
    
    /// Ease out with overshoot - great for pop-in effects
    private func easeOutBack(_ t: Float) -> Float {
        let c1: Float = 1.70158
        let c3: Float = c1 + 1
        return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
    }
    
    /// Smoothstep - smooth acceleration and deceleration (S-curve)
    private func smoothstep(_ t: Float) -> Float {
        let clamped = min(1.0, max(0, t))
        return clamped * clamped * (3 - 2 * clamped)
    }
    
    /// Ease out cubic - fast start, slow end
    private func easeOutCubic(_ t: Float) -> Float {
        return 1 - pow(1 - t, 3)
    }
    
    /// Ease in out quad - gentle S-curve
    private func easeInOutQuad(_ t: Float) -> Float {
        return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }
    
    /// Phase entrance fade (first 10% of phase)
    private func entranceFade(progress: Float) -> Float {
        return smoothstep(min(1.0, progress / 0.10))
    }
    
    /// Phase exit fade (last 10% of phase)
    private func exitFade(progress: Float) -> Float {
        return progress > 0.90 ? smoothstep(1.0 - (progress - 0.90) / 0.10) : 1.0
    }
    
    /// Combined phase fade for smooth transitions
    private func phaseFade(progress: Float) -> Float {
        return entranceFade(progress: progress) * exitFade(progress: progress)
    }
    
    // MARK: - Image Loading Helper
    
    /// Loads an image from the app bundle (for textures)
    private func loadImageFromBundle(_ name: String) -> UIImage? {
        // Try Asset Catalog first
        if let image = UIImage(named: name) {
            return image
        }
        
        // Try bundle path with common extensions
        let extensions = ["png", "jpg", "jpeg"]
        for ext in extensions {
            if let path = Bundle.main.path(forResource: name, ofType: ext),
               let image = UIImage(contentsOfFile: path) {
                return image
            }
        }
        
        print("⚠️ Could not load image: \(name)")
        return nil
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveNarrativeView()
        .environment(ExperienceViewModel())
}
