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
    @State private var godRays: [Entity] = []
    
    // Narrator frame elements
    @State private var narratorTextEntity: Entity?
    
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
    @State private var debrisParticles: [Entity] = []
    @State private var lightRays: [Entity] = []
    @State private var energyArcsRestoration: [Entity] = []
    
    // CTA Portal
    @State private var portalRings: [Entity] = []
    @State private var portalGlow: Entity?
    @State private var beaconPulses: [Entity] = []
    @State private var portalVortex: [Entity] = [] // NEW: Swirling maelstrom
    
    // === WOW FACTOR STATE ===
    @State private var sectorShockwaves: [Entity] = []
    @State private var cardGlintTimer: Float = 0
    @State private var hyperdriveLines: [Entity] = []
    
    var body: some View {
        RealityView { content, attachments in
            content.add(experienceRoot)
            await buildScene()
            
            // Attach text overlays - positioned CLOSER to user, in front of all 3D elements
            if let textOverlay = attachments.entity(for: "NarrativeText") {
                textOverlay.position = [0, 1.6, -1.2] // Closer to user (was -1.8)
                textOverlay.components.set(BillboardComponent())
                experienceRoot.addChild(textOverlay)
            }
            
        } update: { _, _ in
            // Updates handled by timer
        } attachments: {
            Attachment(id: "NarrativeText") {
                NarrativeTextOverlay()
                    .environment(viewModel)
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
        await buildVignetteCards()
        await buildAgenticOrchestration()
        await buildHumanReturn()
        await buildCTAPortal()
        await buildWowEffects()
        addSceneLighting()
        
        sceneLoaded = true
        print("✅ Scene built successfully")
    }
    
    // MARK: - Ambient Star Field (Immersive Depth)
    
    @MainActor
    private func buildAmbientParticles() async {
        // Layer 1: Distant background dust
        for _ in 0..<400 {
            let starMesh = MeshResource.generateSphere(radius: 0.003)
            var starMat = UnlitMaterial()
            let brightness = Float.random(in: 0.2...0.6)
            starMat.color = .init(tint: UIColor(white: CGFloat(brightness), alpha: 1.0))
            let star = ModelEntity(mesh: starMesh, materials: [starMat])
            star.position = [Float.random(in: -15...15), Float.random(in: -8...10), Float.random(in: -12...(-5))]
            experienceRoot.addChild(star)
        }
        
        // Layer 2: Mid-field stars (Twinkle)
        for i in 0..<150 {
            let starMesh = MeshResource.generateSphere(radius: 0.006)
            var starMat = UnlitMaterial()
            starMat.color = .init(tint: UIColor(white: 1.0, alpha: 0.8))
            let star = ModelEntity(mesh: starMesh, materials: [starMat])
            star.name = "StarMid_\(i)"
            star.position = [Float.random(in: -8...8), Float.random(in: -4...6), Float.random(in: -10...(-3))]
            experienceRoot.addChild(star)
            ambientParticles.append(star)
        }
        
        // Layer 3: NEBULA CLOUDS (Massive, colorful gas)
        let nebulaColors: [UIColor] = [
            UIColor(red: 0.1, green: 0.2, blue: 0.5, alpha: 1.0), // Deep blue
            UIColor(red: 0.3, green: 0.1, blue: 0.4, alpha: 1.0), // Purple
            UIColor(red: 0.0, green: 0.3, blue: 0.3, alpha: 1.0)  // Teal
        ]
        
        for i in 0..<6 {
            let size = Float.random(in: 0.5...1.2) // Reduced for VR - was 4-8m!
            let nebulaMesh = MeshResource.generateSphere(radius: size)
            var nebulaMat = UnlitMaterial()
            nebulaMat.color = .init(tint: nebulaColors[i % 3].withAlphaComponent(0.03))
            nebulaMat.blending = .transparent(opacity: 0.03)
            
            let nebula = ModelEntity(mesh: nebulaMesh, materials: [nebulaMat])
            nebula.name = "Nebula_\(i)"
            nebula.position = [Float.random(in: -3...3), Float.random(in: -2...3), Float.random(in: -6...(-4))] // Closer and smaller spread
            experienceRoot.addChild(nebula)
            nebulaClouds.append(nebula)
        }
        
        // Layer 4: GOD RAYS (Piercing light from above) - Reduced for VR
        for i in 0..<8 {
            let rayMesh = MeshResource.generateBox(width: 0.01, height: 3.0, depth: 0.05, cornerRadius: 0.005) // Was 20m tall!
            var rayMat = UnlitMaterial()
            rayMat.color = .init(tint: .init(white: 1.0, alpha: 0.04))
            rayMat.blending = .transparent(opacity: 0.04)
            
            let ray = ModelEntity(mesh: rayMesh, materials: [rayMat])
            ray.name = "GodRay_\(i)"
            ray.position = [Float.random(in: -5...5), 5.0, Float.random(in: -8...(-2))]
            ray.orientation = simd_quatf(angle: Float.random(in: -0.3...0.3), axis: [0, 0, 1])
            experienceRoot.addChild(ray)
            godRays.append(ray)
        }
    }
    
    // MARK: - Vignette Sectors (Premium Glass & Light)
    
    @MainActor
    private func buildVignetteCards() async {
        vignetteWindowsParent.name = "VignetteSectors"
        vignetteWindowsParent.position = [0, 1.6, -2.0]
        experienceRoot.addChild(vignetteWindowsParent)
        
        // Sector configurations
        let sectors: [(name: String, subtitle: String, icon: String, color: UIColor, accent: UIColor, glow: UIColor, metrics: [(String, String)])] = [
            ("FINANCE", "Reconciliation Fatigue", "chart.bar.xaxis",
             UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0),
             UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0),
             UIColor(red: 0.1, green: 0.3, blue: 0.7, alpha: 1.0),
             [("4.7h", "daily reconciliation"), ("340", "manual entries"), ("23", "systems touched")]),
            
            ("SUPPLY CHAIN", "Inventory Friction", "shippingbox",
             UIColor(red: 0.95, green: 0.6, blue: 0.2, alpha: 1.0),
             UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0),
             UIColor(red: 0.7, green: 0.4, blue: 0.1, alpha: 1.0),
             [("3.2h", "tracking overhead"), ("89%", "manual updates"), ("$2.4M", "annual waste")]),
            
            ("HEALTHCARE", "Administrative Burden", "cross.case",
             UIColor(red: 0.2, green: 0.75, blue: 0.5, alpha: 1.0),
             UIColor(red: 0.3, green: 0.85, blue: 0.6, alpha: 1.0),
             UIColor(red: 0.1, green: 0.5, blue: 0.3, alpha: 1.0),
             [("5.1h", "paperwork daily"), ("67%", "non-clinical"), ("142", "forms/week")])
        ]
        
        for (sectorIndex, sector) in sectors.enumerated() {
            let sectorParent = Entity()
            sectorParent.name = "Sector_\(sector.name)"
            sectorParent.position = .zero
            sectorParent.scale = .zero
            vignetteWindowsParent.addChild(sectorParent)
            sectorGlows.append(sectorParent)
            
            // === VOLUMETRIC ATMOSPHERE ===
            // Multiple layers of transparency to simulate volume
            for i in 0..<3 {
                let size = 0.5 + Float(i) * 0.15
                let fogMesh = MeshResource.generateSphere(radius: size)
                var fogMat = UnlitMaterial()
                fogMat.color = .init(tint: sector.glow.withAlphaComponent(0.05))
                let fog = ModelEntity(mesh: fogMesh, materials: [fogMat])
                fog.name = "FogLayer_\(i)"
                sectorParent.addChild(fog)
            }
            
            // === RINGS (Sci-Fi UI Style) ===
            // Main ring
            let ringMesh = MeshResource.generateBox(width: 0.5, height: 0.002, depth: 0.5, cornerRadius: 0.25)
            var ringMat = UnlitMaterial() // Unlit for sharp UI look
            ringMat.color = .init(tint: sector.accent.withAlphaComponent(0.6))
            let outerRing = ModelEntity(mesh: ringMesh, materials: [ringMat])
            outerRing.name = "OuterRing"
            sectorParent.addChild(outerRing)
            
            // Pulse ring
            let midMesh = MeshResource.generateBox(width: 0.42, height: 0.004, depth: 0.42, cornerRadius: 0.21)
            var midMat = UnlitMaterial()
            midMat.color = .init(tint: sector.color.withAlphaComponent(0.3))
            let midRing = ModelEntity(mesh: midMesh, materials: [midMat])
            midRing.name = "MiddleRing"
            sectorParent.addChild(midRing)
            
            // === ICON CORE ===
            // Use a physical sphere for the core to catch light
            let iconMesh = MeshResource.generateSphere(radius: 0.1)
            var iconMat = PhysicallyBasedMaterial()
            iconMat.baseColor = .init(tint: sector.color)
            iconMat.emissiveColor = .init(color: sector.accent)
            iconMat.emissiveIntensity = 4.0
            iconMat.roughness = 0.2
            iconMat.metallic = 0.8
            let iconCore = ModelEntity(mesh: iconMesh, materials: [iconMat])
            iconCore.name = "IconGlow"
            sectorParent.addChild(iconCore)
            
            // === SECTOR LIGHT ===
            let light = Entity()
            var lightComp = PointLightComponent()
            lightComp.intensity = Float(40000)
            lightComp.color = sector.color
            lightComp.attenuationRadius = Float(2.5)
            light.components.set(lightComp)
            sectorParent.addChild(light)
            
            // === PREMIUM GLASS CARDS ===
            for (cardIndex, metric) in sector.metrics.enumerated() {
                let cardParent = Entity()
                
                // Frosted Glass Body
                let cardMesh = MeshResource.generateBox(width: 0.24, height: 0.14, depth: 0.01, cornerRadius: 0.012)
                var glassMat = PhysicallyBasedMaterial()
                glassMat.baseColor = .init(tint: sector.color.withAlphaComponent(0.1))
                glassMat.roughness = 0.4     // Frosted look
                glassMat.metallic = 0.1
                glassMat.blending = .transparent(opacity: .init(floatLiteral: 0.3))
                
                let card = ModelEntity(mesh: cardMesh, materials: [glassMat])
                cardParent.addChild(card)
                
                // Emissive Edge Glow
                let edgeMesh = MeshResource.generateBox(width: 0.244, height: 0.144, depth: 0.004, cornerRadius: 0.014)
                var edgeMat = UnlitMaterial()
                edgeMat.color = .init(tint: sector.accent.withAlphaComponent(0.6))
                let edge = ModelEntity(mesh: edgeMesh, materials: [edgeMat])
                edge.position.z = -0.002
                cardParent.addChild(edge)
                
                // Positioning
                let spacing: Float = 0.28
                let xPos = Float(cardIndex - 1) * spacing
                cardParent.position = [xPos, -0.35, 0.1] // Closer to viewer
                cardParent.scale = .zero
                sectorParent.addChild(cardParent)
                
                // Store
                switch sectorIndex {
                case 0: financeCards.append(cardParent)
                case 1: supplyCards.append(cardParent)
                default: healthcareCards.append(cardParent)
                }
            }
            
            // === DATA STREAMS (Bits flying in) ===
            for i in 0..<30 {
                let bitMesh = MeshResource.generateBox(size: 0.005)
                var bitMat = UnlitMaterial()
                bitMat.color = .init(tint: sector.accent.withAlphaComponent(0.8))
                let bit = ModelEntity(mesh: bitMesh, materials: [bitMat])
                bit.name = "DataBit_\(sectorIndex)_\(i)"
                
                // Start far away
                bit.position = [
                    Float.random(in: -5...5),
                    Float.random(in: -2...5),
                    -8.0
                ]
                bit.scale = .zero
                sectorParent.addChild(bit)
                dataStreams.append(bit)
            }
            
            // === PARTICLE SWARM (Dynamic flow) ===
            // Create 60 particles per sector for rich density
            for p in 0..<60 {
                let size = Float.random(in: 0.003...0.008)
                let pMesh = MeshResource.generateSphere(radius: size)
                var pMat = UnlitMaterial()
                pMat.color = .init(tint: sector.accent.withAlphaComponent(CGFloat(Float.random(in: 0.4...0.9))))
                
                let particle = ModelEntity(mesh: pMesh, materials: [pMat])
                particle.name = "Particle"
                
                // Random spherical distribution
                let theta = Float.random(in: 0...(2 * Float.pi))
                let phi = Float.random(in: 0...(Float.pi))
                let r = Float.random(in: 0.4...0.7)
                
                particle.position = [
                    r * sin(phi) * cos(theta),
                    r * sin(phi) * sin(theta) * 0.4, // Flattened disk-like
                    r * cos(phi) * 0.4
                ]
                
                particle.scale = .zero
                sectorParent.addChild(particle)
                sectorParticles.append(particle)
            }
            
            // === DATA STREAM (Rising Digital Rain) ===
            // 30 tiny specks that rise continuously
            for _ in 0..<30 {
                let streamMesh = MeshResource.generateBox(width: 0.002, height: 0.015, depth: 0.002)
                var streamMat = UnlitMaterial()
                streamMat.color = .init(tint: sector.accent.withAlphaComponent(0.6))
                
                let stream = ModelEntity(mesh: streamMesh, materials: [streamMat])
                stream.name = "DataStream"
                
                // Random position within the sector column
                stream.position = [
                    Float.random(in: -0.3...0.3),
                    Float.random(in: -0.5...0.5),
                    Float.random(in: -0.1...0.1)
                ]
                stream.scale = .zero // Hidden initially
                sectorParent.addChild(stream)
                // We'll animate these in the update loop
            }
        }
    }
    
    // MARK: - Agentic Orchestration (Premium Gemstone Aesthetic)
    
    // Agent shape types matching iPad
    enum AgentShapeType { case diamond, triangle, star, octagon, shield, circle }
    
    @MainActor
    private func buildAgenticOrchestration() async {
        // === CENTRAL ORCHESTRATOR (Complex Gem Structure) ===
        let orchestrator = Entity()
        orchestrator.name = "Orchestrator"
        orchestrator.position = [0, 1.6, -2.0] // Closer to user
        experienceRoot.addChild(orchestrator)
        orchestratorEntity = orchestrator
        
        // 1. Inner Energy Core (Intense Emissive)
        let energyMesh = MeshResource.generateSphere(radius: 0.08)
        var energyMat = PhysicallyBasedMaterial()
        energyMat.baseColor = .init(tint: .init(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0))
        energyMat.emissiveColor = .init(color: .init(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0))
        energyMat.emissiveIntensity = 8.0
        let energyCore = ModelEntity(mesh: energyMesh, materials: [energyMat])
        energyCore.name = "EnergyCore"
        orchestrator.addChild(energyCore)
        
        // 2. Outer Glass Shell (Hexagonal Prism)
        let shellMesh = MeshResource.generateBox(width: 0.18, height: 0.18, depth: 0.1, cornerRadius: 0.03)
        var shellMat = PhysicallyBasedMaterial()
        shellMat.baseColor = .init(tint: .init(red: 1.0, green: 0.9, blue: 0.6, alpha: 0.1))
        shellMat.roughness = .init(floatLiteral: 0.05) // Polished glass
        shellMat.metallic = .init(floatLiteral: 0.8)   // Reflective
        shellMat.blending = .transparent(opacity: .init(floatLiteral: 0.4))
        shellMat.clearcoat = .init(floatLiteral: 1.0)
        let glassShell = ModelEntity(mesh: shellMesh, materials: [shellMat])
        glassShell.name = "Core" // Keeping name for animation logic
        glassShell.orientation = simd_quatf(angle: Float.pi / 4, axis: [0, 0, 1])
        orchestrator.addChild(glassShell)
        
        // 3. Floating Data Rings (Holographic)
        for ring in 0..<4 {
            let radius = 0.28 + Float(ring) * 0.09
            let ringMesh = MeshResource.generateBox(width: radius * 2, height: 0.003, depth: radius * 2, cornerRadius: radius)
            var ringMat = UnlitMaterial()
            ringMat.color = .init(tint: .init(red: 1.0, green: 0.85, blue: 0.4, alpha: 0.4))
            let ringEntity = ModelEntity(mesh: ringMesh, materials: [ringMat])
            ringEntity.name = "OrbitalRing_\(ring)"
            orchestrator.addChild(ringEntity)
        }
        
        // 4. Volumetric Glow (Atmosphere) - Small for VR
        let glowMesh = MeshResource.generateSphere(radius: 0.15)
        var glowMat = UnlitMaterial()
        glowMat.color = .init(tint: .init(red: 1.0, green: 0.8, blue: 0.3, alpha: 0.08))
        let glowEntity = ModelEntity(mesh: glowMesh, materials: [glowMat])
        glowEntity.name = "OrchestratorGlow_0"
        orchestrator.addChild(glowEntity)
        
        // 5. Antenna Array (High-Tech)
        let antennaMesh = MeshResource.generateBox(width: 0.008, height: 0.15, depth: 0.008, cornerRadius: 0.004)
        var antennaMat = PhysicallyBasedMaterial()
        antennaMat.emissiveColor = .init(color: .init(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0))
        antennaMat.emissiveIntensity = 4.0
        let antenna = ModelEntity(mesh: antennaMesh, materials: [antennaMat])
        antenna.name = "Antenna"
        antenna.position = [0, 0.15, 0]
        orchestrator.addChild(antenna)
        
        let tipMesh = MeshResource.generateSphere(radius: 0.02)
        let tip = ModelEntity(mesh: tipMesh, materials: [antennaMat])
        tip.name = "AntennaTip"
        tip.position = [0, 0.22, 0]
        orchestrator.addChild(tip)
        
        // 6. Eyes (Sentience)
        for eye in 0..<3 {
            let eyeAngle = Float(eye) * (Float.pi * 2 / 3)
            let eyeMesh = MeshResource.generateSphere(radius: 0.025)
            var eyeMat = PhysicallyBasedMaterial()
            eyeMat.emissiveColor = .init(color: .white)
            eyeMat.emissiveIntensity = 10.0
            let eyeEntity = ModelEntity(mesh: eyeMesh, materials: [eyeMat])
            eyeEntity.name = "Eye_\(eye)"
            eyeEntity.position = [cos(eyeAngle) * 0.06, sin(eyeAngle) * 0.06, 0.06]
            orchestrator.addChild(eyeEntity)
        }
        
        // Light Source
        let light = Entity()
        var lightComp = PointLightComponent()
        lightComp.intensity = Float(80000)
        lightComp.color = .init(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
        lightComp.attenuationRadius = Float(4.0)
        light.components.set(lightComp)
        orchestrator.addChild(light)
        
        // === 6 SPECIALIST AGENTS (Premium Materials) ===
        let agentConfigs: [(name: String, shape: AgentShapeType, color: UIColor, hasRings: Bool, hasAntenna: Bool, eyeCount: Int)] = [
            ("Analyst", .diamond, UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0), false, true, 2),
            ("Executor", .triangle, UIColor(red: 0.2, green: 0.9, blue: 0.5, alpha: 1.0), false, false, 1),
            ("Connector", .star, UIColor(red: 1.0, green: 0.5, blue: 0.3, alpha: 1.0), true, false, 2),
            ("Innovator", .octagon, UIColor(red: 0.75, green: 0.35, blue: 1.0, alpha: 1.0), true, true, 2),
            ("Optimizer", .shield, UIColor(red: 0.2, green: 0.9, blue: 1.0, alpha: 1.0), false, true, 1),
            ("Harmonizer", .circle, UIColor(red: 1.0, green: 0.55, blue: 0.75, alpha: 1.0), true, false, 3)
        ]
        
        for (i, config) in agentConfigs.enumerated() {
            let angle = (Float(i) * Float.pi / 3.0) - (Float.pi / 2.0)
            let radius: Float = 0.55
            
            let agentParent = Entity()
            agentParent.name = "Agent_\(config.name)"
            agentParent.position = [cos(angle) * radius, 0, sin(angle) * radius * 0.6]
            
            // 1. Inner Core (Emissive)
            let coreMesh = MeshResource.generateSphere(radius: 0.035)
            var coreMat = PhysicallyBasedMaterial()
            coreMat.emissiveColor = .init(color: config.color)
            coreMat.emissiveIntensity = Float(5.0)
            let agentCore = ModelEntity(mesh: coreMesh, materials: [coreMat])
            agentParent.addChild(agentCore)
            
            // 2. Glass Shell (Shape)
            let agentMesh = createAgentMesh(shape: config.shape)
            var glassMat = PhysicallyBasedMaterial()
            glassMat.baseColor = .init(tint: config.color.withAlphaComponent(0.2))
            glassMat.roughness = .init(floatLiteral: 0.1)
            glassMat.metallic = .init(floatLiteral: 0.9)
            glassMat.blending = .transparent(opacity: .init(floatLiteral: 0.5))
            glassMat.clearcoat = .init(floatLiteral: 1.0)
            
            let agentShell = ModelEntity(mesh: agentMesh, materials: [glassMat])
            agentShell.name = "Shape"
            agentParent.addChild(agentShell)
            
            // 3. Data Aura (Glow)
            let auraMesh = MeshResource.generateSphere(radius: 0.12)
            var auraMat = UnlitMaterial()
            auraMat.color = .init(tint: config.color.withAlphaComponent(0.15))
            let aura = ModelEntity(mesh: auraMesh, materials: [auraMat])
            aura.name = "Glow"
            agentParent.addChild(aura)
            
            // 4. Eyes
            for eye in 0..<config.eyeCount {
                let eyeAngle = Float(eye) * (Float.pi * 2 / Float(max(1, config.eyeCount)))
                let eyeMesh = MeshResource.generateSphere(radius: 0.01)
                var eyeMat = PhysicallyBasedMaterial()
                eyeMat.emissiveColor = .init(color: .white)
                eyeMat.emissiveIntensity = 8.0
                let eyeEntity = ModelEntity(mesh: eyeMesh, materials: [eyeMat])
                eyeEntity.name = "Eye_\(eye)"
                eyeEntity.position = [cos(eyeAngle) * 0.025, sin(eyeAngle) * 0.025, 0.04]
                agentParent.addChild(eyeEntity)
            }
            
            // 5. Antenna
            if config.hasAntenna {
                let antMesh = MeshResource.generateBox(width: 0.004, height: 0.08, depth: 0.004, cornerRadius: 0.002)
                var antMat = UnlitMaterial()
                antMat.color = .init(tint: config.color)
                let ant = ModelEntity(mesh: antMesh, materials: [antMat])
                ant.name = "Antenna"
                ant.position = [0, 0.08, 0]
                agentParent.addChild(ant)
            }
            
            // 6. Orbital Ring
            if config.hasRings {
                let ringMesh = MeshResource.generateBox(width: 0.16, height: 0.002, depth: 0.16, cornerRadius: 0.08)
                var ringMat = UnlitMaterial()
                ringMat.color = .init(tint: config.color.withAlphaComponent(0.4))
                let ring = ModelEntity(mesh: ringMesh, materials: [ringMat])
                ring.name = "Orbit"
                agentParent.addChild(ring)
            }
            
        // 7. Light
        let agentLight = Entity()
        var lightComp = PointLightComponent()
        lightComp.intensity = 15000
        lightComp.color = config.color
        lightComp.attenuationRadius = 1.0
        agentLight.components.set(lightComp)
        agentParent.addChild(agentLight)
        
        // 8. ENERGY ARCS (Lightning crackle - hidden initially)
        for i in 0..<3 {
            let arcMesh = MeshResource.generateBox(width: radius * 0.8, height: 0.002, depth: 0.002, cornerRadius: 0.001)
            var arcMat = UnlitMaterial()
            arcMat.color = .init(tint: config.color.withAlphaComponent(0.9))
            let arc = ModelEntity(mesh: arcMesh, materials: [arcMat])
            arc.name = "EnergyArc_\(i)"
            arc.position = [cos(angle) * radius * 0.45, Float.random(in: -0.05...0.05), sin(angle) * radius * 0.45 * 0.6]
            arc.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
            arc.scale = .zero
            orchestrator.addChild(arc)
            energyArcs.append(arc)
        }
        
        agentParent.scale = .zero
        orchestrator.addChild(agentParent)
        agentEntities.append(agentParent)
        
        // Connection Arc (Holographic Beam)
        let beamMesh = MeshResource.generateCylinder(height: radius * 0.9, radius: 0.003)
        var beamMat = UnlitMaterial()
        beamMat.color = .init(tint: config.color.withAlphaComponent(0.6))
        let beam = ModelEntity(mesh: beamMesh, materials: [beamMat])
        beam.name = "Arc_\(i)"
        // Cylinder is Y-up, we need it horizontal pointing to center
        beam.position = [cos(angle) * radius * 0.5, 0, sin(angle) * radius * 0.5 * 0.6]
        
        // Calculate rotation to point from center to agent
        // Cylinder default is Y axis. We rotate 90 deg Z to make it X axis.
        let alignRot = simd_quatf(angle: -Float.pi/2, axis: [0,0,1])
        let dirRot = simd_quatf(angle: angle, axis: [0,1,0])
        beam.orientation = dirRot * alignRot
        
        beam.scale = .zero
        orchestrator.addChild(beam)
        connectionArcs.append(beam)
    }
    
    // === SHOCKWAVE RING (Impact visual) ===
    let shockMesh = MeshResource.generateBox(width: 0.1, height: 0.005, depth: 0.1, cornerRadius: 0.05)
    var shockMat = UnlitMaterial()
    shockMat.color = .init(tint: .init(white: 1.0, alpha: 0.8))
    shockMat.blending = .transparent(opacity: .init(floatLiteral: 0.8))
    let shock = ModelEntity(mesh: shockMesh, materials: [shockMat])
    shock.name = "Shockwave"
    shock.position = [0, 0, 0]
    shock.scale = .zero
    orchestrator.addChild(shock)
    shockwaveRing = shock
    
    orchestrator.scale = .zero
        
        // === TASK ORB ===
        let taskParent = Entity()
        taskParent.name = "TaskOrb"
        taskParent.position = [-1.0, 1.6, -2.0]
        
        let taskMesh = MeshResource.generateSphere(radius: 0.08)
        var taskMat = PhysicallyBasedMaterial()
        taskMat.baseColor = .init(tint: UIColor(red: 1.0, green: 0.5, blue: 0.3, alpha: 1.0))
        taskMat.emissiveColor = .init(color: UIColor(red: 1.0, green: 0.4, blue: 0.2, alpha: 1.0))
        taskMat.emissiveIntensity = 4.0
        
        let taskCore = ModelEntity(mesh: taskMesh, materials: [taskMat])
        taskParent.addChild(taskCore)
        
        taskParent.scale = .zero
        experienceRoot.addChild(taskParent)
        taskOrb = taskParent
        
        // === SOLUTION CRYSTAL ===
        let crystalParent = Entity()
        crystalParent.name = "SolutionCrystal"
        crystalParent.position = [0, 1.6, -2.0]
        
        let crystalMesh = MeshResource.generateSphere(radius: 0.12)
        var crystalMat = PhysicallyBasedMaterial()
        crystalMat.baseColor = .init(tint: UIColor(red: 0.3, green: 0.95, blue: 1.0, alpha: 1.0))
        crystalMat.emissiveColor = .init(color: UIColor(red: 0.4, green: 1.0, blue: 1.0, alpha: 1.0))
        crystalMat.emissiveIntensity = Float(6.0)
        crystalMat.roughness = .init(floatLiteral: 0.05)
        crystalMat.metallic = .init(floatLiteral: 0.9)
        
        let crystalCore = ModelEntity(mesh: crystalMesh, materials: [crystalMat])
        crystalParent.addChild(crystalCore)
        
        // Crystal rays
        for ray in 0..<8 {
            let rayAngle = Float(ray) * Float.pi / 4.0
            let rayMesh = MeshResource.generateBox(width: 0.35, height: 0.004, depth: 0.015, cornerRadius: 0.002)
            var rayMat = UnlitMaterial()
            rayMat.color = .init(tint: UIColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.35))
            rayMat.blending = .transparent(opacity: .init(floatLiteral: 0.3))
            
            let rayEntity = ModelEntity(mesh: rayMesh, materials: [rayMat])
            rayEntity.orientation = simd_quatf(angle: rayAngle, axis: [0, 0, 1])
            crystalParent.addChild(rayEntity)
        }
        
        // Crystal light
        let crystalLight = Entity()
        var crystalLightComp = PointLightComponent()
        crystalLightComp.intensity = Float(80000)
        crystalLightComp.color = .init(red: 0.4, green: 1.0, blue: 1.0, alpha: 1.0)
        crystalLightComp.attenuationRadius = Float(4.0)
        crystalLight.components.set(crystalLightComp)
        crystalParent.addChild(crystalLight)
        
        crystalParent.scale = .zero
        experienceRoot.addChild(crystalParent)
        solutionCrystal = crystalParent
    }
    
    // MARK: - Human Return (The Ascension - Volumetric & Cinematic)
    
    @MainActor
    private func buildHumanReturn() async {
        // === RESTORATION CORE (The Igniting Star) ===
        let glowParent = Entity()
        glowParent.name = "RestorationGlow"
        glowParent.position = [0, 1.6, -2.0]
        
        // 1. Blinding Core
        let coreMesh = MeshResource.generateSphere(radius: 0.08)
        var coreMat = PhysicallyBasedMaterial()
        coreMat.emissiveColor = .init(color: UIColor(red: 0.2, green: 0.9, blue: 1.0, alpha: 1.0))
        coreMat.emissiveIntensity = 15.0 // Blindingly bright
        let coreGlow = ModelEntity(mesh: coreMesh, materials: [coreMat])
        coreGlow.name = "Core"
        glowParent.addChild(coreGlow)
        
        // 2. Volumetric God Rays (Rotating Shafts) - Smaller for VR
        for i in 0..<16 {
            // Smaller, tapering light shafts for VR
            let rayMesh = MeshResource.generateCone(height: 0.6, radius: 0.03)
            var rayMat = UnlitMaterial()
            let rayAlpha: Float = 0.05
            rayMat.color = .init(tint: UIColor(red: 0.4, green: 0.9, blue: 1.0, alpha: CGFloat(rayAlpha)))
            rayMat.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(scale: rayAlpha, texture: nil))
            
            let ray = ModelEntity(mesh: rayMesh, materials: [rayMat])
            ray.name = "GodRay_\(i)"
            // Point outward from center
            ray.position = .zero
            
            // Random rotations to create a "starburst"
            let angleZ = Float(i) * (Float.pi * 2 / 16)
            let angleX = Float.random(in: -0.5...0.5)
            ray.orientation = simd_quatf(angle: angleZ, axis: [0, 0, 1]) * simd_quatf(angle: angleX, axis: [1, 0, 0])
            
            // Offset to start from center (cone pivot is at bottom)
            ray.position = [0, 0, 0]
            
            glowParent.addChild(ray)
            lightRays.append(ray)
        }
        
        // 3. Shockwave Ripples (Refractive Energy) - Smaller for VR
        for ring in 0..<6 {
            let radius = 0.1 + Float(ring) * 0.06
            let ringMesh = MeshResource.generateBox(width: radius * 2, height: 0.01, depth: radius * 2, cornerRadius: radius)
            var ringMat = PhysicallyBasedMaterial()
            ringMat.baseColor = .init(tint: UIColor(red: 0.5, green: 1.0, blue: 1.0, alpha: 0.1))
            ringMat.roughness = .init(floatLiteral: 0.0)
            ringMat.metallic = .init(floatLiteral: 0.9)
            ringMat.emissiveColor = .init(color: UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0))
            ringMat.emissiveIntensity = 2.0
            ringMat.blending = .transparent(opacity: .init(floatLiteral: 0.3))
            
            let ripple = ModelEntity(mesh: ringMesh, materials: [ringMat])
            ripple.name = "Ripple_\(ring)"
            glowParent.addChild(ripple)
            energyArcs.append(ripple)
        }
        
        // Restoration Point Light
        let restLight = Entity()
        var restLightComp = PointLightComponent()
        restLightComp.intensity = Float(60000)
        restLightComp.color = .init(red: 0.2, green: 0.9, blue: 1.0, alpha: 1.0)
        restLightComp.attenuationRadius = Float(5.0)
        restLight.components.set(restLightComp)
        glowParent.addChild(restLight)
        
        glowParent.scale = .zero
        experienceRoot.addChild(glowParent)
        restorationGlow = glowParent
        
        // === BURNING DEBRIS (Shards of Burden) ===
        for i in 0..<40 {
            // Jagged shards
            let debrisMesh = MeshResource.generateBox(width: 0.04, height: 0.04, depth: 0.04) // Placeholder for jagged rock
            var debrisMat = PhysicallyBasedMaterial()
            debrisMat.baseColor = .init(tint: .black)
            debrisMat.roughness = 0.8
            // Inner molten glow
            debrisMat.emissiveColor = .init(color: .init(red: 1.0, green: 0.3, blue: 0.1, alpha: 1.0))
            debrisMat.emissiveIntensity = 0.0 // Starts cold, heats up
            
            let debris = ModelEntity(mesh: debrisMesh, materials: [debrisMat])
            debris.name = "Debris_\(i)"
            
            // Random chaotic positions around the user/scene
            let angle = Float(i) * 0.5
            let radius = Float.random(in: 0.5...1.5)
            debris.position = [
                cos(angle) * radius,
                1.6 + Float.random(in: -0.8...0.8),
                sin(angle) * radius - 2.0
            ]
            
            // Random rotation
            let randomRot = simd_quatf(angle: Float.random(in: 0...10), axis: normalize([1, 1, 1]))
            debris.orientation = randomRot
            
            debris.scale = .zero
            experienceRoot.addChild(debris)
            debrisParticles.append(debris)
        }
    }
    
    // MARK: - CTA Portal (The Warp Gate - Deep & Hypnotic)
    
    @MainActor
    private func buildCTAPortal() async {
        let portalCenter: SIMD3<Float> = [0, 1.6, -2.0]
        
        // 1. Infinity Tunnel Rings (Depth Perception)
        // Creating 12 rings receding into distance - SUBTLE SIZE for VR
        for i in 0..<12 {
            // Rings get smaller and further back
            let depthFactor = Float(i) * 0.3
            let radius = 0.25 * (1.0 - Float(i) * 0.05) // Much smaller for VR
            
            // Complex ring geometry (Torus)
            let ringMesh = MeshResource.generateBox(width: radius * 2, height: 0.02, depth: radius * 2, cornerRadius: radius)
            var ringMat = PhysicallyBasedMaterial()
            ringMat.baseColor = .init(tint: UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0))
            ringMat.emissiveColor = .init(color: UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0))
            ringMat.emissiveIntensity = 2.0 + Float(i) * 0.5 // Brightness increases with depth
            ringMat.metallic = .init(floatLiteral: 1.0)
            ringMat.roughness = .init(floatLiteral: 0.2)
            
            let ring = ModelEntity(mesh: ringMesh, materials: [ringMat])
            ring.name = "PortalRing_\(i)"
            // Positioned deeper into scene
            ring.position = [portalCenter.x, portalCenter.y, portalCenter.z - depthFactor]
            // Slight tilt for dynamic look
            ring.orientation = simd_quatf(angle: Float.pi / 2, axis: [1, 0, 0]) 
            
            ring.scale = .zero
            experienceRoot.addChild(ring)
            portalRings.append(ring)
        }
        
        // 2. Event Horizon (Liquid Surface) - Small for VR
        let horizonMesh = MeshResource.generateSphere(radius: 0.15)
        var horizonMat = PhysicallyBasedMaterial()
        horizonMat.baseColor = .init(tint: .black)
        horizonMat.roughness = 0.0
        horizonMat.metallic = 1.0
        horizonMat.emissiveColor = .init(color: .init(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0))
        horizonMat.emissiveIntensity = 1.0
        horizonMat.blending = .transparent(opacity: .init(floatLiteral: 0.8))
        
        let horizon = ModelEntity(mesh: horizonMesh, materials: [horizonMat])
        horizon.name = "PortalGlow"
        horizon.position = [portalCenter.x, portalCenter.y, portalCenter.z - 6.0] // Deep inside
        horizon.scale = .zero
        experienceRoot.addChild(horizon)
        portalGlow = horizon
        
        // 3. Beacon Pulses (Signal Waves)
        for i in 0..<5 {
            let pulseMesh = MeshResource.generateSphere(radius: 0.1)
            var pulseMat = UnlitMaterial()
            pulseMat.color = .init(tint: .init(red: 1.0, green: 0.9, blue: 0.8, alpha: 0.3))
            
            let pulse = ModelEntity(mesh: pulseMesh, materials: [pulseMat])
            pulse.name = "BeaconPulse_\(i)"
            pulse.position = portalCenter
            pulse.scale = .zero
            experienceRoot.addChild(pulse)
            beaconPulses.append(pulse)
        }
        
        // === PORTAL VORTEX (Swirling Maelstrom) ===
        for i in 0..<40 {
            let pMesh = MeshResource.generateSphere(radius: Float.random(in: 0.005...0.015))
            var pMat = UnlitMaterial()
            let pAlpha = Float.random(in: 0.2...0.7)
            pMat.color = .init(tint: UIColor(red: 1.0, green: 0.9, blue: 0.5, alpha: CGFloat(pAlpha)))
            pMat.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(scale: pAlpha, texture: nil))
            
            let p = ModelEntity(mesh: pMesh, materials: [pMat])
            p.name = "Vortex_\(i)"
            let angle = Float.random(in: 0...(2 * Float.pi))
            let r = Float.random(in: 0.1...0.5)
            p.position = portalCenter + [cos(angle) * r, sin(angle) * r, Float.random(in: -0.2...0.2)]
            p.scale = .zero
            experienceRoot.addChild(p)
            portalVortex.append(p)
        }
        
        // Portal Light
        let portalLight = Entity()
        var lightComp = PointLightComponent()
        lightComp.intensity = Float(100000)
        lightComp.color = .init(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)
        lightComp.attenuationRadius = Float(10.0)
        portalLight.components.set(lightComp)
        portalLight.position = portalCenter
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
        for (i, ray) in godRays.enumerated() {
            let shimmer = 0.8 + sin(animationTime * 1.5 + Float(i)) * 0.2
            ray.scale.x = shimmer
            ray.position.x += sin(animationTime * 0.3 + Float(i)) * 0.001
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
            
            // Warp effect during CTA
            if phase == .stillnessCTA {
                let pull = normalize([0, 1.6, -2.5] - star.position)
                star.position += pull * dt * progress * 0.5
            }
        }
        
        // Phase-specific animations
        switch phase {
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
            
        default:
            break
        }
    }
    
    // MARK: - Vignette Animation (3 Sectors - One at a Time)
    
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
        
        // === HIDE ALL OTHER SECTORS ===
        for (i, sector) in sectorGlows.enumerated() {
            if i != sectorIndex {
                sector.scale = SIMD3<Float>(repeating: max(0, sector.scale.x - dt * 2.0))
            }
        }
        
        // === ANIMATE DATA STREAM ===
        for (i, bit) in dataStreams.enumerated() {
            let bitSector = i / 30
            if bitSector == sectorIndex {
                let speed = 2.0 + Float(i % 5) * 0.5
                bit.scale = [1, 1, 1]
                bit.position.z += dt * speed
                
                // Spiral motion
                bit.position.x += sin(animationTime * 2 + Float(i)) * 0.01
                bit.position.y += cos(animationTime * 2 + Float(i)) * 0.01
                
                // Reset if reached viewer or sector
                if bit.position.z > -2.5 {
                    bit.position.z = -8.0
                    bit.position.x = Float.random(in: -2...2)
                    bit.position.y = Float.random(in: 0...3)
                }
            } else {
                bit.scale = .zero
            }
        }
        
        // === ANIMATE CURRENT SECTOR ===
        if sectorIndex < sectorGlows.count {
            let sectorParent = sectorGlows[sectorIndex]
            let sectorScale = easeOutBack(min(1.0, localProgress * 2.5))
            sectorParent.scale = SIMD3<Float>(repeating: sectorScale)
            
            for child in sectorParent.children {
                if child.name.hasPrefix("FogLayer") {
                    let i = Int(child.name.split(separator: "_").last ?? "0") ?? 0
                    child.scale = SIMD3<Float>(repeating: 1.0 + sin(animationTime * 0.8 + Float(i)) * 0.1)
                }
                if child.name == "OuterRing" { child.orientation *= simd_quatf(angle: dt * 0.6, axis: [0, 1, 0]) }
                if child.name == "MiddleRing" { child.scale = SIMD3<Float>(repeating: 1.0 + sin(animationTime * 2.5) * 0.1) }
                if child.name == "IconGlow" { child.orientation *= simd_quatf(angle: dt * 0.3, axis: [0, 1, 0]) }
            }
        }
        
        // === CARDS ===
        let cards = sectorIndex == 0 ? financeCards : (sectorIndex == 1 ? supplyCards : healthcareCards)
        for (i, card) in cards.enumerated() {
            let stagger = 0.3 + Float(i) * 0.1
            let cardProg = max(0, min(1, (localProgress - stagger) * 3))
            card.scale = SIMD3<Float>(repeating: easeOutBack(cardProg))
            card.position.y = -0.35 + sin(animationTime * 1.5 + Float(i)) * 0.01
        }
        
        // === PARTICLES ===
        for (i, particle) in sectorParticles.enumerated() {
            let particleSector = i / 60
            if particleSector == sectorIndex {
                particle.scale = SIMD3<Float>(repeating: min(1.0, localProgress * 2))
                particle.orientation *= simd_quatf(angle: dt * (0.5 + Float(i % 10) * 0.05), axis: [0, 1, 0])
            }
        }
    }
    
    // MARK: - Pattern Break Animation (The Glitch / Shift)
    
    @MainActor
    private func animatePatternBreak(progress: Float, dt: Float) {
        // Fade out all sector elements smoothly
        for sector in sectorGlows {
            sector.scale = SIMD3<Float>(repeating: max(0, sector.scale.x - dt * 1.5))
        }
        for card in financeCards + supplyCards + healthcareCards {
            card.scale = SIMD3<Float>(repeating: max(0, card.scale.x - dt * 1.5))
        }
        for particle in sectorParticles {
            particle.scale = SIMD3<Float>(repeating: max(0, particle.scale.x - dt * 0.8))
        }
        
        // Stars intensify and SHAKE - building tension
        let shakeAmount = 0.05 * progress // Increase shake as we near the break
        
        for (i, star) in ambientParticles.enumerated() {
            let intensity: Float = 1.0 + progress * 2.0 // Get very bright
            let pulse = sin(animationTime * 10 + Float(i)) * 0.5 * progress // Fast strobe
            star.scale = SIMD3<Float>(repeating: intensity + pulse)
            
            // Jitter position to simulate instability
            let jitter = SIMD3<Float>(
                Float.random(in: -shakeAmount...shakeAmount),
                Float.random(in: -shakeAmount...shakeAmount),
                Float.random(in: -shakeAmount...shakeAmount)
            )
            
            // Apply jitter on top of base position (needs careful state management, simplified here)
            // Ideally we'd store base pos, but for now we just add noise to movement
            star.position += jitter * dt * 5.0
        }
        
        // Dramatic "Audio-Visual" Pulse at the end
        if progress > 0.8 {
            let flash = sin(animationTime * 20) * 0.5 + 0.5
            // Maybe pulse the environment light if possible
        }
    }
    
    // MARK: - Agentic Orchestration Animation (iPad Parity)
    
    @MainActor
    private func animateAgenticOrchestration(progress: Float, dt: Float) {
        let agentAppear = min(1.0, progress / 0.2) // Faster appear
        let taskPhase = min(1.0, max(0, (progress - 0.2) / 0.5))
        let gloryPhase = min(1.0, max(0, (progress - 0.7) / 0.3))
        
        // === ORCHESTRATOR ===
        let orchPulse = 1.0 + sin(animationTime * 2.0) * 0.1
        orchestratorEntity?.scale = SIMD3<Float>(repeating: easeOutBack(agentAppear) * orchPulse)
        
        if let orch = orchestratorEntity {
            for child in orch.children {
                if child.name == "Core" { child.orientation *= simd_quatf(angle: dt * 0.4, axis: [0, 1, 0]) }
                if child.name == "EnergyCore" { 
                    child.scale = SIMD3<Float>(repeating: 1.0 + sin(animationTime * 8) * 0.1) // Vibrating energy
                }
                if child.name.hasPrefix("Eye") { child.scale = SIMD3<Float>(repeating: 0.8 + sin(animationTime * 4) * 0.2) }
                if child.name == "AntennaTip" { child.scale = SIMD3<Float>(repeating: 1.0 + sin(animationTime * 12) * 0.5) }
                if child.name.hasPrefix("OrbitalRing") {
                    let i = Int(child.name.split(separator: "_").last ?? "0") ?? 0
                    child.orientation *= simd_quatf(angle: dt * (1.0 - Float(i) * 0.2), axis: [0, 1, 0])
                }
            }
        }
        
        // === LIGHTNING ARCS ===
        for arc in energyArcs {
            if taskPhase > 0.1 && taskPhase < 0.9 {
                arc.scale = [1, 1, 1]
                // Random crackle visibility
                arc.isEnabled = Float.random(in: 0...1) > 0.7
                arc.position.y = sin(animationTime * 20) * 0.05
            } else {
                arc.scale = .zero
            }
        }
        
        // === SHOCKWAVE ===
        if taskPhase > 0.8 && taskPhase < 1.0 {
            let shockProg = (taskPhase - 0.8) / 0.2
            shockwaveRing?.scale = SIMD3<Float>(repeating: 0.1 + shockProg * 10.0)
            shockwaveRing?.isEnabled = true
        } else {
            shockwaveRing?.isEnabled = false
        }
        
        // === AGENTS ===
        for (i, agent) in agentEntities.enumerated() {
            let stagger = Float(i) * 0.05
            let agentProg = max(0, min(1, (agentAppear - stagger) * 2.5))
            var scale = easeOutBack(agentProg)
            
            if taskPhase > 0.1 && taskPhase < 0.9 {
                scale *= (1.0 + sin(animationTime * 6 + Float(i)) * 0.2)
            }
            agent.scale = SIMD3<Float>(repeating: scale)
            
            for child in agent.children {
                if child.name == "Shape" { child.orientation *= simd_quatf(angle: dt * 0.5, axis: [0, 1, 0]) }
                if child.name == "Orbit" { child.orientation *= simd_quatf(angle: dt * 2.0, axis: [0, 1, 0]) }
            }
        }
        
        // === CONNECTIONS ===
        for arc in connectionArcs {
            if agentAppear > 0.4 {
                let arcProg = min(1.0, (agentAppear - 0.4) * 3)
                arc.scale = SIMD3<Float>(repeating: easeOutBack(arcProg))
            }
        }
        
        // === TASK ORB & CRYSTAL ===
        if taskPhase > 0 && taskPhase < 0.6 {
            let p = taskPhase / 0.6
            taskOrb?.scale = SIMD3<Float>(repeating: (1.2 - p * 0.8) * (1.0 + sin(animationTime * 15) * 0.1))
            taskOrb?.position = [-1.0 + 1.0 * p, 1.6 + sin(p * Float.pi) * 0.2, -2.0]
        } else {
            taskOrb?.scale = .zero
        }
        
        if taskPhase > 0.7 {
            let p = (taskPhase - 0.7) / 0.3
            solutionCrystal?.scale = SIMD3<Float>(repeating: easeOutBack(p) * (1.0 + sin(animationTime * 3) * 0.1))
            solutionCrystal?.orientation *= simd_quatf(angle: dt * 0.6, axis: [0, 1, 0])
        }
        
        // === GLORY ===
        if gloryPhase > 0 {
            let glow = 1.0 + sin(animationTime * 2) * 0.2 * gloryPhase
            orchestratorEntity?.scale *= glow
            solutionCrystal?.scale *= glow
            for agent in agentEntities { agent.scale *= glow }
        }
    }
    
    // MARK: - Human Return Animation
    
    @MainActor
    private func animateHumanReturn(progress: Float, dt: Float) {
        // Fade out agentic elements smoothly
        if let orch = orchestratorEntity, orch.scale.x > 0.01 {
            orch.scale = SIMD3<Float>(repeating: max(0, orch.scale.x - dt * 0.8))
        }
        if let crystal = solutionCrystal, crystal.scale.x > 0.01 {
            crystal.scale = SIMD3<Float>(repeating: max(0, crystal.scale.x - dt * 0.8))
        }
        for arc in connectionArcs {
            arc.scale = SIMD3<Float>(repeating: max(0, arc.scale.x - dt * 1.0))
        }
        for agent in agentEntities {
            agent.scale = SIMD3<Float>(repeating: max(0, agent.scale.x - dt * 1.0))
        }
        
        // Debris appears first (chains showing)
        let debrisPhase = min(1.0, progress * 3)
        for (i, debris) in debrisParticles.enumerated() {
            let stagger = Float(i) * 0.03
            let debrisAppear = max(0, min(1, (debrisPhase - stagger) * 2))
            
            if progress < 0.5 {
                // Show debris
                debris.scale = SIMD3<Float>(repeating: debrisAppear)
            } else {
                // Debris floats up and fades
                let fadeProgress = (progress - 0.5) * 2
                let fadeScale = max(0, 1.0 - fadeProgress)
                debris.scale = SIMD3<Float>(repeating: fadeScale)
                debris.position.y += dt * 0.4 * fadeProgress
                debris.position.x += sin(Float(i)) * dt * 0.08
                debris.orientation *= simd_quatf(angle: dt * 0.8, axis: normalize([Float(i % 3) + 0.1, 1, Float(i % 2) + 0.1]))
            }
        }
        
        // Restoration glow appears mid-way
        if progress > 0.3 {
            let glowProgress = (progress - 0.3) / 0.4
            let glowScale = easeOutBack(min(1.0, glowProgress))
            let glowPulse = 1.0 + sin(animationTime * 1.5) * 0.15
            restorationGlow?.scale = SIMD3<Float>(repeating: glowScale * glowPulse)
        }
        
        // Light rays (subtle)
        if progress > 0.4 {
            let rayPhase = (progress - 0.4) / 0.4
            for (i, ray) in lightRays.enumerated() {
                let rayProgress = min(1.0, rayPhase)
                let rayPulse = 0.9 + sin(animationTime * 0.4 + Float(i) * 0.5) * 0.1
                ray.scale = SIMD3<Float>(repeating: rayProgress * rayPulse)
                ray.orientation *= simd_quatf(angle: dt * 0.015, axis: [0, 0, 1])
            }
        }
        
        // Energy rings expand
        if progress > 0.5 {
            let ringPhase = (progress - 0.5) / 0.5
            for (i, arc) in energyArcs.enumerated() {
                let stagger = Float(i) * 0.08
                let arcProgress = max(0, min(1, (ringPhase - stagger) * 2))
                arc.scale = SIMD3<Float>(repeating: easeOutBack(arcProgress))
                arc.orientation *= simd_quatf(angle: dt * (0.25 - Float(i) * 0.04), axis: [0, 1, 0])
            }
        }
    }
    
    // MARK: - Personalization Animation
    
    @MainActor
    private func animatePersonalization(progress: Float, dt: Float) {
        // Keep glow with gentle pulse (scale 1.0 base)
        let calmPulse = 1.0 + sin(animationTime * 1.0) * 0.12
        restorationGlow?.scale = SIMD3<Float>(repeating: calmPulse)
        
        // Keep rays pulsing gently
        for (i, ray) in lightRays.enumerated() {
            let rayPulse = 0.9 + sin(animationTime * 0.5 + Float(i) * 0.4) * 0.1
            ray.scale = SIMD3<Float>(repeating: rayPulse)
        }
        
        // Energy rings rotate
        for (i, arc) in energyArcs.enumerated() {
            arc.orientation *= simd_quatf(angle: dt * (0.2 - Float(i) * 0.03), axis: [0, 1, 0])
        }
        
        // Debris should be gone
        for debris in debrisParticles {
            debris.scale = SIMD3<Float>(repeating: max(0, debris.scale.x - dt * 1.0))
        }
    }
    
    // MARK: - CTA Animation
    
    @MainActor
    private func animateCTA(progress: Float, dt: Float) {
        // Fade restoration elements
        restorationGlow?.scale = SIMD3<Float>(repeating: max(0, (restorationGlow?.scale.x ?? 0) - dt * 0.4))
        for ray in lightRays {
            ray.scale = SIMD3<Float>(repeating: max(0, ray.scale.x - dt * 0.5))
        }
        for arc in energyArcs {
            arc.scale = SIMD3<Float>(repeating: max(0, arc.scale.x - dt * 0.5))
        }
        
        // Portal rings appear
        for (i, ring) in portalRings.enumerated() {
            let ringDelay = Float(i) * 0.1
            let ringProgress = max(0, min(1, (progress - ringDelay) * 2))
            ring.scale = SIMD3<Float>(repeating: easeOutBack(ringProgress))
            
            let rotateSpeed: Float = 0.2 - Float(i) * 0.04
            let direction: Float = i % 2 == 0 ? 1 : -1
            ring.orientation *= simd_quatf(angle: dt * rotateSpeed * direction, axis: [0, 1, 0])
        }
        
        // Beacon pulses
        for (i, pulse) in beaconPulses.enumerated() {
            let pulseTime = fmod(animationTime * 0.4 + Float(i) * 0.25, 1.0)
            let pulseRadius = 0.05 + pulseTime * 2.0
            pulse.scale = SIMD3<Float>(repeating: pulseRadius * progress)
        }
        
        // Portal glow
        let glowProgress = min(1.0, progress * 1.5)
        let glowPulse = 1.0 + sin(animationTime * 1.2) * 0.15
        portalGlow?.scale = SIMD3<Float>(repeating: glowProgress * glowPulse)
    }
    
    // MARK: - Wow Effects Construction
    
    @MainActor
    private func buildWowEffects() async {
        // 1. Hyperdrive Lines (Speed sensation)
        for i in 0..<50 {
            let length = Float.random(in: 0.5...2.0)
            let lineMesh = MeshResource.generateBox(width: 0.005, height: 0.005, depth: length, cornerRadius: 0.002)
            var lineMat = UnlitMaterial()
            lineMat.color = .init(tint: UIColor(white: 1.0, alpha: 0.0)) // Hidden initially
            lineMat.blending = .transparent(opacity: .init(floatLiteral: 0.0))
            
            let line = ModelEntity(mesh: lineMesh, materials: [lineMat])
            line.name = "Hyperdrive_\(i)"
            
            // Random position in a tunnel
            let angle = Float.random(in: 0...(2 * Float.pi))
            let radius = Float.random(in: 2.0...5.0)
            line.position = [cos(angle) * radius, sin(angle) * radius + 1.6, Float.random(in: -5...5)]
            
            experienceRoot.addChild(line)
            hyperdriveLines.append(line)
        }
        
        // 2. Sector Shockwaves (One per sector, reusable)
        for i in 0..<3 {
            let waveMesh = MeshResource.generateBox(width: 1.0, height: 0.005, depth: 1.0, cornerRadius: 0.5) // Flat ring-like
            var waveMat = UnlitMaterial()
            // Colors matching sectors: Finance (Blue), Supply (Orange), Healthcare (Green)
            let color: UIColor = i == 0 ? UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1) :
            (i == 1 ? UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1) :
             UIColor(red: 0.2, green: 0.8, blue: 0.5, alpha: 1))
            
            waveMat.color = .init(tint: color.withAlphaComponent(0.0))
            waveMat.blending = .transparent(opacity: .init(floatLiteral: 0.0))
            
            let wave = ModelEntity(mesh: waveMesh, materials: [waveMat])
            wave.name = "Shockwave_\(i)"
            wave.position = [0, 1.6, -2.0]
            wave.scale = .zero
            
            // Tilt slightly for drama
            wave.orientation = simd_quatf(angle: Float.pi / 6, axis: [1, 0, 0])
            
            experienceRoot.addChild(wave)
            sectorShockwaves.append(wave)
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
    
    // MARK: - Easing
    
    private func easeOutBack(_ t: Float) -> Float {
        let c1: Float = 1.70158
        let c3: Float = c1 + 1
        return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveNarrativeView()
        .environment(ExperienceViewModel())
}
