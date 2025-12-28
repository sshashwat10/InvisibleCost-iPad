import SwiftUI
import RealityKit
import RealityKitContent

/// The Invisible Cost - Pure RealityKit Cinematic Experience
struct ImmersiveNarrativeView: View {
    @Environment(ExperienceViewModel.self) private var viewModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @State private var experienceRoot = Entity()
    @State private var sceneLoaded = false
    @State private var updateTimer: Timer?
    @State private var lastUpdateTime = Date()
    @State private var animationTime: Float = 0
    
    // Scene elements
    @State private var windows: [Entity] = []
    @State private var windowsParent = Entity()
    @State private var particles: [Entity] = [] // Replaces rings
    @State private var particlesParent = Entity()
    @State private var bloomLight: ModelEntity? // Replaces shards
    
    // Exit Arc Attachments
    @State private var exitCenter: Entity?
    @State private var exitLeft: Entity?
    @State private var exitRight: Entity?
    
    var body: some View {
        RealityView { content, attachments in
            content.add(experienceRoot)
            await buildScene()
            
            // Positioning for main narrative text
            if let textOverlay = attachments.entity(for: "NarrativeText") {
                textOverlay.position = [0, 1.6, -1.2]
                textOverlay.components.set(BillboardComponent())
                experienceRoot.addChild(textOverlay)
            }
            
            // Positioning for Exit CTA Arc (Wraps around user)
            if let center = attachments.entity(for: "ExitCenter") {
                center.position = [0, 1.6, -1.8]
                center.components.set(BillboardComponent())
                experienceRoot.addChild(center)
                exitCenter = center
            }
            
            if let left = attachments.entity(for: "ExitLeft") {
                left.position = [-1.8, 1.6, -1.4]
                left.components.set(BillboardComponent())
                // Slight yaw to wrap the arc, but keep upright
                left.orientation = simd_quatf(angle: .pi / 8, axis: [0, 1, 0])
                experienceRoot.addChild(left)
                exitLeft = left
            }
            
            if let right = attachments.entity(for: "ExitRight") {
                right.position = [1.8, 1.6, -1.4]
                right.components.set(BillboardComponent())
                right.orientation = simd_quatf(angle: -.pi / 8, axis: [0, 1, 0])
                experienceRoot.addChild(right)
                exitRight = right
            }
            
        } attachments: {
            Attachment(id: "NarrativeText") {
                NarrativeTextOverlay()
                    .environment(viewModel)
            }
            
            Attachment(id: "ExitCenter") {
                ExitCenterCTA()
                    .environment(viewModel)
            }
            
            Attachment(id: "ExitLeft") {
                ExitSideText(text: "Agentic automation returns")
                    .environment(viewModel)
            }
            
            Attachment(id: "ExitRight") {
                ExitSideText(text: "to the people who matter.")
                    .environment(viewModel)
            }
        }
        .onAppear {
            startUpdateLoop()
            if viewModel.currentPhase == .waiting {
                viewModel.startExperience()
            }
        }
        .onDisappear {
            stopUpdateLoop()
            cleanupScene()
        }
    }
    
    // MARK: - Build Scene
    
    @MainActor
    private func buildScene() async {
        print("🎬 Building RealityKit scene...")
        
        // Glowing materials
        let windowMat = makeGlowMaterial(base: [0.15, 0.18, 0.25], glow: [0.1, 0.15, 0.25], intensity: 1.5)
        let titleBlueMat = makeGlowMaterial(base: [0.3, 0.6, 1.0], glow: [0.5, 0.8, 1.0], intensity: 3.0)
        let titleRedMat = makeGlowMaterial(base: [1.0, 0.4, 0.3], glow: [1.0, 0.6, 0.4], intensity: 3.0)
        
        // Windows container - centered on user
        windowsParent.name = "WindowsParent"
        windowsParent.position = [0, 0, 0] // User center
        experienceRoot.addChild(windowsParent)
        
        // Create dense clutter of windows, front-biased but still 360°
        let totalWindows = 140
        let frontCount = Int(Float(totalWindows) * 0.85) // heavy front bias
        let surroundCount = totalWindows - frontCount
        var configs: [(SIMD3<Float>, Bool)] = []
        
        func generatePosition(front: Bool) -> SIMD3<Float> {
            var pos: SIMD3<Float>
            repeat {
                // Azimuth: bias to front (z negative) when requested
                let theta = front
                ? Float.random(in: -.pi...0)          // front hemisphere
                : Float.random(in: 0...(2 * .pi))     // anywhere
                
                // Elevation: avoid extreme top/bottom
                let phi = Float.random(in: (0.35 * .pi)...(0.65 * .pi))
                // Front windows slightly closer for clutter
                let radius = front
                ? Float.random(in: 1.3...3.0)
                : Float.random(in: 1.5...3.6)
                
                let x = radius * sin(phi) * cos(theta)
                let y = radius * cos(phi) + 1.6
                let z = radius * sin(phi) * sin(theta)
                pos = SIMD3<Float>(x, y, z)
                
                // Safe zone: keep clear of central text block in front
            } while (pos.z < -0.4 && pos.z > -2.4) && (abs(pos.x) < 1.2) && (pos.y > 0.9 && pos.y < 2.4)
            
            return pos
        }
        
        for _ in 0..<frontCount {
            configs.append((generatePosition(front: true), Bool.random()))
        }
        for _ in 0..<surroundCount {
            configs.append((generatePosition(front: false), Bool.random()))
        }
        
        let windowConfigs: [(SIMD3<Float>, Bool)] = configs.shuffled()
        
        for (i, (pos, isAlert)) in windowConfigs.enumerated() {
            let window = createNotificationWindow(
                bodyMat: windowMat,
                titleMat: isAlert ? titleRedMat : titleBlueMat,
                index: i
            )
            window.position = pos
            // Look at user (0, 1.6, 0) but ONLY rotate around Y axis (vertical billboard)
            let dx = 0 - pos.x
            let dz = 0 - pos.z 
            let angle = atan2(dx, dz)
            window.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
            
            window.scale = [0, 0, 0]  // Start invisible
            windowsParent.addChild(window)
            windows.append(window)
        }
        
        // Particles Container (Data Dust)
        particlesParent.name = "ParticlesParent"
        particlesParent.position = [0, 1.6, 0] // Centered on user head
        experienceRoot.addChild(particlesParent)
        
        let particleMesh = MeshResource.generateSphere(radius: 0.008)
        let particleMat = UnlitMaterial(color: .white)
        
        for _ in 0..<500 {
            let p = ModelEntity(mesh: particleMesh, materials: [particleMat])
            let theta = Float.random(in: 0...(2 * .pi))
            let phi = Float.random(in: 0...(2 * .pi))
            let r = Float.random(in: 1.3...4.0) // Wide distribution, avoid text center
            
            p.position = [r * sin(phi) * cos(theta), r * cos(phi), r * sin(phi) * sin(theta)]
            p.scale = [0, 0, 0]
            particlesParent.addChild(p)
            particles.append(p)
        }
        
        // Bloom Light Effect
        let bloomMesh = MeshResource.generateSphere(radius: 1.0)
        var bloomMat = PhysicallyBasedMaterial()
        bloomMat.baseColor = .init(tint: .white)
        bloomMat.emissiveColor = .init(color: .white)
        bloomMat.emissiveIntensity = 20.0
        bloomMat.blending = .transparent(opacity: 0.8)
        
        let bloom = ModelEntity(mesh: bloomMesh, materials: [bloomMat])
        bloom.name = "BloomLight"
        bloom.position = [0, 1.6, -1.0] // Bias bloom in front of user
        bloom.scale = [0, 0, 0]
        bloom.components.set(OpacityComponent(opacity: 0.0))
        experienceRoot.addChild(bloom)
        bloomLight = bloom
        
        addSceneLighting()
        
        sceneLoaded = true
        print("✅ Scene ready: \(windows.count) windows, \(particles.count) particles, bloom ready")
    }
    
    private func makeGlowMaterial(base: SIMD3<Float>, glow: SIMD3<Float>, intensity: Float) -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: .init(red: CGFloat(base.x), green: CGFloat(base.y), blue: CGFloat(base.z), alpha: 1))
        mat.roughness = .init(floatLiteral: 0.2)
        mat.metallic = .init(floatLiteral: 0.05)
        mat.emissiveColor = .init(color: .init(red: CGFloat(glow.x), green: CGFloat(glow.y), blue: CGFloat(glow.z), alpha: 1))
        mat.emissiveIntensity = intensity
        return mat
    }
    
    private func createNotificationWindow(bodyMat: PhysicallyBasedMaterial, titleMat: PhysicallyBasedMaterial, index: Int) -> Entity {
        let parent = Entity()
        parent.name = "Window_\(index)"
        let bodyMesh = MeshResource.generateBox(width: 0.4, height: 0.28, depth: 0.015, cornerRadius: 0.012)
        let body = ModelEntity(mesh: bodyMesh, materials: [bodyMat])
        parent.addChild(body)
        
        let titleMesh = MeshResource.generateBox(width: 0.36, height: 0.04, depth: 0.02, cornerRadius: 0.008)
        let title = ModelEntity(mesh: titleMesh, materials: [titleMat])
        title.position = [0, 0.11, 0.005]
        parent.addChild(title)
        
        let lineMat = makeGlowMaterial(base: [0.3, 0.35, 0.45], glow: [0.2, 0.25, 0.35], intensity: 1.0)
        for j in 0..<3 {
            let w: Float = 0.28 - Float(j) * 0.05
            let lineMesh = MeshResource.generateBox(width: w, height: 0.015, depth: 0.018, cornerRadius: 0.003)
            let line = ModelEntity(mesh: lineMesh, materials: [lineMat])
            line.position = [-0.025, -0.015 - Float(j) * 0.05, 0.005]
            parent.addChild(line)
        }
        
        addWindowContent(to: parent, index: index)
        return parent
    }
    
    /// Procedural UI primitives to suggest various “unnecessary work” screens
    private func addWindowContent(to parent: Entity, index: Int) {
        let content = Entity()
        content.position = [0, -0.04, 0.009]
        parent.addChild(content)
        
        // Palette (cool neutrals + a warm accent)
        let rowBase = UnlitMaterial(color: .init(red: 0.18, green: 0.22, blue: 0.30, alpha: 1))
        let rowAlt  = UnlitMaterial(color: .init(red: 0.20, green: 0.26, blue: 0.34, alpha: 1))
        let accent  = UnlitMaterial(color: .init(red: 0.98, green: 0.78, blue: 0.52, alpha: 1))
        let badge   = UnlitMaterial(color: .init(red: 0.55, green: 0.78, blue: 1.00, alpha: 1))
        
        // Helper to add a row
        func addRow(y: Float, alt: Bool, hasBadge: Bool) {
            let mat = alt ? rowAlt : rowBase
            let row = ModelEntity(mesh: MeshResource.generateBox(width: 0.30, height: 0.028, depth: 0.004, cornerRadius: 0.004),
                                  materials: [mat])
            row.position = [0.0, y, 0]
            content.addChild(row)
            
            // Leading icon stub
            let icon = ModelEntity(mesh: MeshResource.generateBox(width: 0.02, height: 0.02, depth: 0.004, cornerRadius: 0.003),
                                   materials: [badge])
            icon.position = [-0.13, 0, 0.003]
            row.addChild(icon)
            
            // Optional badge/pill on the right
            if hasBadge {
                let pill = ModelEntity(mesh: MeshResource.generateBox(width: 0.06, height: 0.018, depth: 0.003, cornerRadius: 0.006),
                                       materials: [accent])
                pill.position = [0.12, 0, 0.003]
                row.addChild(pill)
            }
        }
        
        // Template builders
        func buildDashboard() {
            addRow(y: 0.05, alt: false, hasBadge: true)
            addRow(y: 0.015, alt: true, hasBadge: false)
            addRow(y: -0.02, alt: false, hasBadge: true)
            
            // Mini chart
            let chart = Entity()
            chart.position = [-0.095, -0.065, 0]
            content.addChild(chart)
            let barWidths: [Float] = [0.012, 0.012, 0.012, 0.012]
            let barHeights: [Float] = [
                0.020 + Float.random(in: 0...0.01),
                0.030 + Float.random(in: 0...0.01),
                0.018 + Float.random(in: 0...0.01),
                0.026 + Float.random(in: 0...0.01)
            ]
            for (i, h) in barHeights.enumerated() {
                let bar = ModelEntity(mesh: MeshResource.generateBox(width: barWidths[i], height: h, depth: 0.003, cornerRadius: 0.002),
                                      materials: [badge])
                bar.position = [Float(i) * 0.018, h * 0.5, 0.002]
                chart.addChild(bar)
            }
            
            // Bottom CTA chips
            let chipLeft = ModelEntity(mesh: MeshResource.generateBox(width: 0.09, height: 0.022, depth: 0.003, cornerRadius: 0.007),
                                       materials: [rowAlt])
            chipLeft.position = [-0.06, -0.105, 0.002]
            content.addChild(chipLeft)
            
            let chipRight = ModelEntity(mesh: MeshResource.generateBox(width: 0.09, height: 0.022, depth: 0.003, cornerRadius: 0.007),
                                        materials: [rowBase])
            chipRight.position = [0.06, -0.105, 0.002]
            content.addChild(chipRight)
        }
        
        func buildEmailList() {
            // Sender + subject rows
            addRow(y: 0.06, alt: false, hasBadge: true)
            addRow(y: 0.025, alt: true, hasBadge: false)
            addRow(y: -0.01, alt: false, hasBadge: false)
            addRow(y: -0.045, alt: true, hasBadge: true) // unread
            // Footer buttons
            let reply = ModelEntity(mesh: MeshResource.generateBox(width: 0.08, height: 0.022, depth: 0.003, cornerRadius: 0.006),
                                    materials: [rowAlt])
            reply.position = [-0.05, -0.1, 0.002]
            content.addChild(reply)
            let archive = ModelEntity(mesh: MeshResource.generateBox(width: 0.08, height: 0.022, depth: 0.003, cornerRadius: 0.006),
                                      materials: [rowBase])
            archive.position = [0.05, -0.1, 0.002]
            content.addChild(archive)
        }
        
        func buildEmailDetail() {
            // Subject bar
            let subject = ModelEntity(mesh: MeshResource.generateBox(width: 0.30, height: 0.03, depth: 0.004, cornerRadius: 0.004),
                                      materials: [rowBase])
            subject.position = [0, 0.07, 0]
            content.addChild(subject)
            // Sender/recipient pills
            let from = ModelEntity(mesh: MeshResource.generateBox(width: 0.12, height: 0.02, depth: 0.003, cornerRadius: 0.006),
                                   materials: [badge])
            from.position = [-0.08, 0.035, 0.002]
            content.addChild(from)
            let to = ModelEntity(mesh: MeshResource.generateBox(width: 0.12, height: 0.02, depth: 0.003, cornerRadius: 0.006),
                                 materials: [rowAlt])
            to.position = [0.08, 0.035, 0.002]
            content.addChild(to)
            // Body lines
            addRow(y: 0.0, alt: false, hasBadge: false)
            addRow(y: -0.03, alt: true, hasBadge: false)
            addRow(y: -0.06, alt: false, hasBadge: false)
            // CTA
            let replyAll = ModelEntity(mesh: MeshResource.generateBox(width: 0.14, height: 0.024, depth: 0.003, cornerRadius: 0.007),
                                       materials: [accent])
            replyAll.position = [0, -0.1, 0.002]
            content.addChild(replyAll)
        }
        
        func buildCalendarInvite() {
            let title = ModelEntity(mesh: MeshResource.generateBox(width: 0.30, height: 0.03, depth: 0.004, cornerRadius: 0.004),
                                    materials: [rowBase])
            title.position = [0, 0.07, 0]
            content.addChild(title)
            // Time/location rows
            addRow(y: 0.035, alt: true, hasBadge: false)
            addRow(y: 0.0, alt: false, hasBadge: false)
            // Attendee chips
            let attA = ModelEntity(mesh: MeshResource.generateBox(width: 0.08, height: 0.02, depth: 0.003, cornerRadius: 0.006),
                                   materials: [badge])
            attA.position = [-0.08, -0.035, 0.002]
            content.addChild(attA)
            let attB = ModelEntity(mesh: MeshResource.generateBox(width: 0.08, height: 0.02, depth: 0.003, cornerRadius: 0.006),
                                   materials: [rowAlt])
            attB.position = [0.0, -0.035, 0.002]
            content.addChild(attB)
            let attC = ModelEntity(mesh: MeshResource.generateBox(width: 0.08, height: 0.02, depth: 0.003, cornerRadius: 0.006),
                                   materials: [rowBase])
            attC.position = [0.08, -0.035, 0.002]
            content.addChild(attC)
            // Accept/Maybe/Decline
            let accept = ModelEntity(mesh: MeshResource.generateBox(width: 0.08, height: 0.022, depth: 0.003, cornerRadius: 0.006),
                                     materials: [accent])
            accept.position = [-0.07, -0.085, 0.002]
            content.addChild(accept)
            let maybe = ModelEntity(mesh: MeshResource.generateBox(width: 0.08, height: 0.022, depth: 0.003, cornerRadius: 0.006),
                                    materials: [rowAlt])
            maybe.position = [0.0, -0.085, 0.002]
            content.addChild(maybe)
            let decline = ModelEntity(mesh: MeshResource.generateBox(width: 0.08, height: 0.022, depth: 0.003, cornerRadius: 0.006),
                                      materials: [rowBase])
            decline.position = [0.07, -0.085, 0.002]
            content.addChild(decline)
        }
        
        func buildForm() {
            // Stacked inputs with “required” chips
            addRow(y: 0.055, alt: false, hasBadge: true)
            addRow(y: 0.02, alt: true, hasBadge: true)
            addRow(y: -0.015, alt: false, hasBadge: true)
            addRow(y: -0.05, alt: true, hasBadge: false)
            // Resend / Submit buttons
            let resend = ModelEntity(mesh: MeshResource.generateBox(width: 0.1, height: 0.024, depth: 0.003, cornerRadius: 0.007),
                                     materials: [rowAlt])
            resend.position = [-0.06, -0.095, 0.002]
            content.addChild(resend)
            let submit = ModelEntity(mesh: MeshResource.generateBox(width: 0.1, height: 0.024, depth: 0.003, cornerRadius: 0.007),
                                     materials: [accent])
            submit.position = [0.06, -0.095, 0.002]
            content.addChild(submit)
        }
        
        // Pick a template for this window
        switch index % 5 {
        case 0: buildDashboard()
        case 1: buildEmailList()
        case 2: buildEmailDetail()
        case 3: buildCalendarInvite()
        default: buildForm()
        }
    }
    
    private func addSceneLighting() {
        let keyLight = Entity()
        var keyComp = PointLightComponent()
        keyComp.intensity = 80000
        keyComp.color = .white
        keyComp.attenuationRadius = 30
        keyLight.components.set(keyComp)
        keyLight.position = [0, 5, -1]
        experienceRoot.addChild(keyLight)
        
        let fillLight = Entity()
        var fillComp = PointLightComponent()
        fillComp.intensity = 40000
        fillComp.color = .init(red: 0.85, green: 0.9, blue: 1.0, alpha: 1)
        fillComp.attenuationRadius = 25
        fillLight.components.set(fillComp)
        fillLight.position = [0, 1.5, -4]
        experienceRoot.addChild(fillLight)
    }
    
    private func startUpdateLoop() {
        lastUpdateTime = Date()
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { _ in
            let now = Date()
            let dt = Float(min(now.timeIntervalSince(self.lastUpdateTime), 0.05))
            self.lastUpdateTime = now
            self.animationTime += dt
            self.viewModel.updateProgress(deltaTime: Double(dt))
            self.animateSceneFrame(dt: dt)
        }
        RunLoop.main.add(timer, forMode: .common)
        updateTimer = timer
    }
    
    private func animateSceneFrame(dt: Float) {
        Task { @MainActor in animateScene(dt: dt) }
    }
    
    @MainActor
    private func animateScene(dt: Float) {
        guard sceneLoaded else { return }
        let phase = viewModel.currentPhase
        let progress = Float(viewModel.phaseProgress)
        
        switch phase {
        case .spatialOverwhelm:
            for (i, window) in windows.enumerated() {
                // Faster, denser pop-in immediately as text appears
                let delay = Float(i) * 0.05
                let localProgress = max(0, min(1, (progress * 5.0) - delay))
                let eased = easeOutBack(localProgress)
                // Ensure early visibility with a floor scale
                window.scale = SIMD3<Float>(repeating: max(0.35, eased))
                let bob = sin(animationTime * 1.5 + Float(i) * 0.8) * 0.015
                window.position.y += bob * dt * 2
                
                // Extra keep-out from center text and gentle outward drift
                let textCenter = SIMD3<Float>(0, 1.6, -1.2)
                let toWindow = window.position - textCenter
                let dist = length(toWindow)
                let minRadius: Float = 1.4
                if dist < minRadius {
                    let push = normalize(toWindow + SIMD3<Float>(0.0001, 0.0001, 0.0001)) * (minRadius - dist)
                    window.position += push * 0.5
                }
                // Slowly drift outward to clear space for upcoming text
                let outward = normalize(window.position + SIMD3<Float>(0.0001, 0.0001, 0.0001)) * dt * 0.08
                window.position += outward
            }
            
        case .realityCrack:
            let tremble = sin(animationTime * 30.0) * 0.002
            windowsParent.position.x += tremble
            // Keep windows fully visible until shatter
            for window in windows {
                window.scale = SIMD3<Float>(repeating: 1.0)
            }
            
        case .humanFragment:
            // Align bloom/shatter with the "142 were unnecessary." line
            let triggerPoint: Float = 0.20 // start bloom a bit earlier so it's visible
            let bloomProgress = max(0, min(1, (progress - triggerPoint) * 4.0)) // faster ramp
            let shatterDelay: Float = 0.03
            let shatterProgress = max(0, min(1, (progress - (triggerPoint + shatterDelay)) * 6.0))
            
            if bloomProgress > 0 {
                if bloomProgress < 0.55 {
                    // Smaller, front-biased bloom to keep it in front of user
                    let s = easeOutBack(bloomProgress * 1.8) * 32.0
                    bloomLight?.scale = SIMD3<Float>(repeating: s)
                    bloomLight?.components.set(OpacityComponent(opacity: 1.0))
                } else {
                    let fade = max(0, 1.0 - ((bloomProgress - 0.55) * 1.4))
                    bloomLight?.components.set(OpacityComponent(opacity: fade))
                    bloomLight?.scale = SIMD3<Float>(repeating: 32.0 + bloomProgress * 6.0)
                }
            } else {
                bloomLight?.scale = .zero
            }
            
            // Hold windows visible until shatter kicks in
            for window in windows {
                let scale = max(0, 1.0 - shatterProgress)
                window.scale = SIMD3<Float>(repeating: scale)
            }
            
            // Subtle tremble leading into bloom
            if bloomProgress <= 0 {
                let tremble = sin(animationTime * 38.0) * 0.003
                windowsParent.position.x += tremble
            }
            
        case .dataChoreography:
            // DATA DUST: Chaos -> Sphere Shell (per spec: assembling from floating data points)
            let chaosToOrder = max(0, min(1, (progress - 0.35) * 4.5)) 
            
            // Let the bloom linger briefly into this phase, then fade
            if progress < 0.2 {
                let fade = max(0, 1.0 - (progress / 0.2))
                bloomLight?.components.set(OpacityComponent(opacity: fade))
                bloomLight?.scale = SIMD3<Float>(repeating: 32.0 + progress * 8.0)
            } else {
                bloomLight?.components.set(OpacityComponent(opacity: 0.0))
                bloomLight?.scale = .zero
            }
            
            for (i, p) in particles.enumerated() {
                let delay = Float(i) * 0.0015
                let appearProgress = max(0, min(1, (progress * 8.0) - delay))
                let twinkle = 0.5 + sin(animationTime * 14.0 + Float(i)) * 0.5
                p.scale = SIMD3<Float>(repeating: easeOutBack(appearProgress) * twinkle * 0.8)
                
                if chaosToOrder > 0 {
                    // Golden-angle sphere shell radius 2.0
                    let seed = Float(i)
                    let theta = seed * 2.39996
                    let y = 1 - (seed / Float(particles.count - 1)) * 2
                    let r = sqrt(max(0, 1 - y * y)) * 2.0
                    let targetPos = SIMD3<Float>(cos(theta) * r, y * 2.0, sin(theta) * r)
                    p.position = simd_mix(p.position, targetPos, SIMD3<Float>(repeating: dt * 2.5))
                } else {
                    p.position += SIMD3<Float>(sin(animationTime + Float(i)), cos(animationTime + Float(i) * 0.5), sin(animationTime * 0.8 + Float(i))) * 0.005
                }
            }
            particlesParent.orientation *= simd_quatf(angle: dt * 0.4 * chaosToOrder, axis: [0, 1, 0])
            for window in windows { window.scale = .zero }
            bloomLight?.scale = .zero
            
        case .humanRestoration:
            bloomLight?.scale = .zero
            let axis = normalize(SIMD3<Float>(1, 1, 0))
            for p in particles {
                p.scale *= (1.0 + sin(animationTime * 2.5) * 0.1)
            }
            particlesParent.orientation *= simd_quatf(angle: dt * 0.15, axis: axis)
            
        case .exitMoment:
            let fade = max(0.3, 1.0 - progress * 0.7)
            for p in particles { p.scale = SIMD3<Float>(repeating: fade) }
            particlesParent.orientation *= simd_quatf(angle: dt * 0.3, axis: [0, 1, 0])
            
        default: break
        }
    }
    
    private func easeOutBack(_ t: Float) -> Float {
        let c1: Float = 1.70158
        let c3 = c1 + 1
        return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
    }
    
    private func stopUpdateLoop() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func cleanupScene() {
        for child in experienceRoot.children { child.removeFromParent() }
        windows.removeAll()
        particles.removeAll()
        bloomLight = nil
        exitCenter = nil
        exitLeft = nil
        exitRight = nil
        sceneLoaded = false
    }
}
