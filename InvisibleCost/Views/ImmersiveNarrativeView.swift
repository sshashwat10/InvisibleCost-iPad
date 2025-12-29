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
    @State private var bloomLight: ModelEntity? // Replaces shards
    @State private var bloomShockwave: Entity?
    @State private var skyDome: Entity?
    
    @State private var dataDust: [Entity] = []
    
    // Pulse animation state for "wow"
    @State private var pulseAlpha: Float = 0
    
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
                textOverlay.position = [0, 1.6, -0.8] // Bring text closer to user
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
        
        // 1. Pre-generate shared meshes for massive optimization
        let bodyMesh = MeshResource.generateBox(width: 0.4, height: 0.28, depth: 0.015, cornerRadius: 0.012)
        let titleMesh = MeshResource.generateBox(width: 0.36, height: 0.04, depth: 0.02, cornerRadius: 0.008)
        let rowMesh = MeshResource.generateBox(width: 0.30, height: 0.028, depth: 0.004, cornerRadius: 0.004)
        let iconMesh = MeshResource.generateBox(width: 0.02, height: 0.02, depth: 0.004, cornerRadius: 0.003)
        let pillMesh = MeshResource.generateBox(width: 0.06, height: 0.018, depth: 0.003, cornerRadius: 0.006)
        
        // Glowing materials
        let windowMat = makeGlowMaterial(base: [0.15, 0.18, 0.25], glow: [0.1, 0.15, 0.25], intensity: 1.5, isGlass: true)
        let titleBlueMat = makeGlowMaterial(base: [0.3, 0.6, 1.0], glow: [0.5, 0.8, 1.0], intensity: 3.0)
        let titleRedMat = makeGlowMaterial(base: [1.0, 0.4, 0.3], glow: [1.0, 0.6, 0.4], intensity: 3.0)
        
        // Windows container - centered on user
        windowsParent.name = "WindowsParent"
        windowsParent.position = [0, 0, 0] // User center
        experienceRoot.addChild(windowsParent)
        
        // Create dense clutter of windows, front-biased but still 360°
        let totalWindows = 180
        let frontCount = 160 // Almost all in front
        let surroundCount = totalWindows - frontCount
        var configs: [(SIMD3<Float>, Bool)] = []
        
        func generatePosition(front: Bool) -> SIMD3<Float> {
            var pos: SIMD3<Float>
            repeat {
                // Azimuth: tighter front bias for "clutter"
                let theta = front
                ? Float.random(in: -(.pi * 0.8)...(-.pi * 0.2)) // tighter front arc
                : Float.random(in: 0...(2 * .pi))
                
                let phi = Float.random(in: (0.35 * .pi)...(0.65 * .pi))
                let radius = front
                ? Float.random(in: 1.4...4.0) // push min radius slightly out
                : Float.random(in: 1.5...4.5)
                
                let x = radius * sin(phi) * cos(theta)
                let y = radius * cos(phi) + 1.6
                let z = radius * sin(phi) * sin(theta)
                pos = SIMD3<Float>(x, y, z)
                
                // AGGRESSIVE safe zone: Keep a large window open for the text
            } while (pos.z < -0.2 && pos.z > -2.5) && (abs(pos.x) < 2.0) && (pos.y > 0.8 && pos.y < 2.4)
            
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
                bodyMesh: bodyMesh,
                titleMesh: titleMesh,
                rowMesh: rowMesh,
                iconMesh: iconMesh,
                pillMesh: pillMesh,
                index: i
            )
            window.position = pos
            // Initial orientation: billboarded to user
            let dx = 0 - pos.x
            let dz = 0 - pos.z 
            let angle = atan2(dx, dz)
            window.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
            
            window.scale = [0, 0, 0]
            windowsParent.addChild(window)
            windows.append(window)
        }
        
        // Bloom Light Effect - Softer, more localized glow
        let bloomMesh = MeshResource.generateSphere(radius: 1.0)
        var bloomMat = UnlitMaterial(color: .white)
        bloomMat.color = .init(tint: .init(white: 1.0, alpha: 0.4)) 
        
        let bloom = ModelEntity(mesh: bloomMesh, materials: [bloomMat])
        bloom.name = "BloomLight"
        bloom.position = [0, 1.6, -1.5] // Push back slightly more
        bloom.scale = [0, 0, 0]
        bloom.components.set(OpacityComponent(opacity: 0.0))
        experienceRoot.addChild(bloom)
        bloomLight = bloom
        
        // 1. Atmosphere - The Sky Dome
        let domeMesh = MeshResource.generateSphere(radius: 40.0)
        var domeMat = UnlitMaterial()
        domeMat.color = .init(tint: .init(red: 0.02, green: 0.02, blue: 0.05, alpha: 1.0))
        let dome = ModelEntity(mesh: domeMesh, materials: [domeMat])
        dome.scale = [-1, 1, 1] 
        experienceRoot.addChild(dome)
        skyDome = dome
        
        // 2. The Impact Shockwave
        let waveMesh = MeshResource.generatePlane(width: 1.0, height: 1.0)
        var waveMat = UnlitMaterial(color: .white)
        waveMat.color = .init(tint: .init(white: 1.0, alpha: 0.3))
        let wave = ModelEntity(mesh: waveMesh, materials: [waveMat])
        wave.position = [0, 1.6, -1.5]
        wave.scale = .zero
        wave.components.set(BillboardComponent())
        wave.components.set(OpacityComponent(opacity: 0.0))
        experienceRoot.addChild(wave)
        bloomShockwave = wave
        
        // 3. Ambient Data Dust
        let dustMesh = MeshResource.generateSphere(radius: 0.003)
        let dustMat = UnlitMaterial(color: .init(white: 0.8, alpha: 0.4))
        for _ in 0..<150 {
            let mote = ModelEntity(mesh: dustMesh, materials: [dustMat])
            let r = Float.random(in: 1.0...6.0)
            let theta = Float.random(in: 0...(2 * .pi))
            let phi = Float.random(in: 0...(.pi))
            mote.position = [
                r * sin(phi) * cos(theta),
                r * cos(phi) + 1.6,
                r * sin(phi) * sin(theta)
            ]
            mote.components.set(OpacityComponent(opacity: Float.random(in: 0.1...0.4)))
            experienceRoot.addChild(mote)
            dataDust.append(mote)
        }
         
        addSceneLighting()
        
        sceneLoaded = true
        
    }
    
    private func makeGlowMaterial(base: SIMD3<Float>, glow: SIMD3<Float>, intensity: Float, isGlass: Bool = false) -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: .init(red: CGFloat(base.x), green: CGFloat(base.y), blue: CGFloat(base.z), alpha: isGlass ? 0.4 : 1.0))
        mat.roughness = .init(floatLiteral: isGlass ? 0.8 : 0.2) // High roughness for frosted glass
        mat.metallic = .init(floatLiteral: isGlass ? 0.1 : 0.05)
        if isGlass {
            mat.blending = .transparent(opacity: 0.4)
        }
        mat.emissiveColor = .init(color: .init(red: CGFloat(glow.x), green: CGFloat(glow.y), blue: CGFloat(glow.z), alpha: 1))
        mat.emissiveIntensity = intensity
        return mat
    }
    
    private func createNotificationWindow(
        bodyMat: PhysicallyBasedMaterial,
        titleMat: PhysicallyBasedMaterial,
        bodyMesh: MeshResource,
        titleMesh: MeshResource,
        rowMesh: MeshResource,
        iconMesh: MeshResource,
        pillMesh: MeshResource,
        index: Int
    ) -> Entity {
        let parent = Entity()
        parent.name = "Window_\(index)"
        
        // Upgrade: Gaze Interaction (Hardware Magic)
        parent.components.set(HoverEffectComponent())
        parent.components.set(InputTargetComponent())
        // Collision is required for hover effects to work
        let collisionShape = ShapeResource.generateBox(width: 0.4, height: 0.28, depth: 0.02)
        parent.components.set(CollisionComponent(shapes: [collisionShape]))
        
        let body = ModelEntity(mesh: bodyMesh, materials: [bodyMat])
        parent.addChild(body)
        
        // Micro-Texture: Procedural Circuitry
        // Very thin, dim glowing lines to simulate a motherboard/digital grid
        let circuitMat = UnlitMaterial(color: .init(red: 0.4, green: 0.6, blue: 1.0, alpha: 0.15))
        let horizMesh = MeshResource.generateBox(width: 0.38, height: 0.001, depth: 0.001)
        let vertMesh = MeshResource.generateBox(width: 0.001, height: 0.26, depth: 0.001)
        
        for k in 0..<4 {
            let hLine = ModelEntity(mesh: horizMesh, materials: [circuitMat])
            hLine.position = [0, -0.1 + Float(k) * 0.06, 0.008]
            parent.addChild(hLine)
            
            let vLine = ModelEntity(mesh: vertMesh, materials: [circuitMat])
            vLine.position = [-0.15 + Float(k) * 0.1, 0, 0.008]
            parent.addChild(vLine)
        }
        
        let title = ModelEntity(mesh: titleMesh, materials: [titleMat])
        title.position = [0, 0.11, 0.005]
        parent.addChild(title)
        
        let lineMat = makeGlowMaterial(base: [0.3, 0.35, 0.45], glow: [0.2, 0.25, 0.35], intensity: 1.0)
        // Shared line mesh for tiny decorative lines
        let lineMesh = MeshResource.generateBox(width: 0.2, height: 0.015, depth: 0.018, cornerRadius: 0.003)
        for j in 0..<3 {
            let line = ModelEntity(mesh: lineMesh, materials: [lineMat])
            line.position = [-0.025, -0.015 - Float(j) * 0.05, 0.005]
            parent.addChild(line)
        }
        
        addWindowContent(
            to: parent,
            rowMesh: rowMesh,
            iconMesh: iconMesh,
            pillMesh: pillMesh,
            index: index
        )
        return parent
    }
    
    /// Procedural UI primitives to suggest various “unnecessary work” screens
    private func addWindowContent(
        to parent: Entity,
        rowMesh: MeshResource,
        iconMesh: MeshResource,
        pillMesh: MeshResource,
        index: Int
    ) {
        let content = Entity()
        content.position = [0, -0.04, 0.009]
        parent.addChild(content)
        
        // Palette (cool neutrals + a warm accent)
        let rowBase = UnlitMaterial(color: .init(red: 0.18, green: 0.22, blue: 0.30, alpha: 1))
        let rowAlt  = UnlitMaterial(color: .init(red: 0.20, green: 0.26, blue: 0.34, alpha: 1))
        let accent  = UnlitMaterial(color: .init(red: 0.98, green: 0.78, blue: 0.52, alpha: 1))
        let badge   = UnlitMaterial(color: .init(red: 0.55, green: 0.78, blue: 1.00, alpha: 1))
        
        // Helper to add a row with variable depth
        func addRow(y: Float, alt: Bool, hasBadge: Bool, z: Float = 0) {
            let mat = alt ? rowAlt : rowBase
            let row = ModelEntity(mesh: rowMesh, materials: [mat])
            row.position = [0.0, y, z] // Apply Z-depth
            content.addChild(row)
            
            // Leading icon stub - sit slightly in front of the row
            let icon = ModelEntity(mesh: iconMesh, materials: [badge])
            icon.position = [-0.13, 0, 0.005]
            row.addChild(icon)
            
            // Optional badge/pill on the right - sit even further out
            if hasBadge {
                let pill = ModelEntity(mesh: pillMesh, materials: [accent])
                pill.position = [0.12, 0, 0.008]
                row.addChild(pill)
            }
        }
        
        // Template builders with Z-layering
        func buildDashboard() {
            addRow(y: 0.05, alt: false, hasBadge: true, z: 0.0)
            addRow(y: 0.015, alt: true, hasBadge: false, z: 0.005)
            addRow(y: -0.02, alt: false, hasBadge: true, z: 0.01)
            
            // Mini chart - shared bar mesh
            let barMesh = MeshResource.generateBox(width: 0.012, height: 0.03, depth: 0.003, cornerRadius: 0.002)
            let chart = Entity()
            chart.position = [-0.095, -0.065, 0.012]
            content.addChild(chart)
            for i in 0..<4 {
                let bar = ModelEntity(mesh: barMesh, materials: [badge])
                let h = 0.5 + Float(i) * 0.1
                bar.scale.y = h
                bar.position = [Float(i) * 0.018, (0.03 * h) * 0.5, Float(i) * 0.002]
                chart.addChild(bar)
            }
            
            let chipMesh = MeshResource.generateBox(width: 0.09, height: 0.022, depth: 0.003, cornerRadius: 0.007)
            let chipLeft = ModelEntity(mesh: chipMesh, materials: [rowAlt])
            chipLeft.position = [-0.06, -0.105, 0.015]
            content.addChild(chipLeft)
            
            let chipRight = ModelEntity(mesh: chipMesh, materials: [rowBase])
            chipRight.position = [0.06, -0.105, 0.015]
            content.addChild(chipRight)
        }
        
        func buildEmailList() {
            // Sender + subject rows
            addRow(y: 0.06, alt: false, hasBadge: true, z: 0.0)
            addRow(y: 0.025, alt: true, hasBadge: false, z: 0.004)
            addRow(y: -0.01, alt: false, hasBadge: false, z: 0.008)
            addRow(y: -0.045, alt: true, hasBadge: true, z: 0.012)
            
            let btnMesh = MeshResource.generateBox(width: 0.08, height: 0.022, depth: 0.003, cornerRadius: 0.006)
            let reply = ModelEntity(mesh: btnMesh, materials: [rowAlt])
            reply.position = [-0.05, -0.1, 0.015]
            content.addChild(reply)
            let archive = ModelEntity(mesh: btnMesh, materials: [rowBase])
            archive.position = [0.05, -0.1, 0.015]
            content.addChild(archive)
        }
        
        func buildEmailDetail() {
            let subMesh = MeshResource.generateBox(width: 0.30, height: 0.03, depth: 0.004, cornerRadius: 0.004)
            let subject = ModelEntity(mesh: subMesh, materials: [rowBase])
            subject.position = [0, 0.07, 0.01]
            content.addChild(subject)
            
            let pillWideMesh = MeshResource.generateBox(width: 0.12, height: 0.02, depth: 0.003, cornerRadius: 0.006)
            let from = ModelEntity(mesh: pillWideMesh, materials: [badge])
            from.position = [-0.08, 0.035, 0.014]
            content.addChild(from)
            let to = ModelEntity(mesh: pillWideMesh, materials: [rowAlt])
            to.position = [0.08, 0.035, 0.014]
            content.addChild(to)
            
            addRow(y: 0.0, alt: false, hasBadge: false, z: 0.0)
            addRow(y: -0.03, alt: true, hasBadge: false, z: 0.004)
            addRow(y: -0.06, alt: false, hasBadge: false, z: 0.008)
            
            let replyAllMesh = MeshResource.generateBox(width: 0.14, height: 0.024, depth: 0.003, cornerRadius: 0.007)
            let replyAll = ModelEntity(mesh: replyAllMesh, materials: [accent])
            replyAll.position = [0, -0.1, 0.016]
            content.addChild(replyAll)
        }
        
        func buildCalendarInvite() {
            let subMesh = MeshResource.generateBox(width: 0.30, height: 0.03, depth: 0.004, cornerRadius: 0.004)
            let title = ModelEntity(mesh: subMesh, materials: [rowBase])
            title.position = [0, 0.07, 0.008]
            content.addChild(title)
            
            addRow(y: 0.035, alt: true, hasBadge: false, z: 0.0)
            addRow(y: 0.0, alt: false, hasBadge: false, z: 0.004)
            
            let attMesh = MeshResource.generateBox(width: 0.08, height: 0.02, depth: 0.003, cornerRadius: 0.006)
            let attA = ModelEntity(mesh: attMesh, materials: [badge])
            attA.position = [-0.08, -0.035, 0.012]
            content.addChild(attA)
            let attB = ModelEntity(mesh: attMesh, materials: [rowAlt])
            attB.position = [0.0, -0.035, 0.012]
            content.addChild(attB)
            let attC = ModelEntity(mesh: attMesh, materials: [rowBase])
            attC.position = [0.08, -0.035, 0.012]
            content.addChild(attC)
            
            let optMesh = MeshResource.generateBox(width: 0.08, height: 0.022, depth: 0.003, cornerRadius: 0.006)
            let accept = ModelEntity(mesh: optMesh, materials: [accent])
            accept.position = [-0.07, -0.085, 0.016]
            content.addChild(accept)
            let maybe = ModelEntity(mesh: optMesh, materials: [rowAlt])
            maybe.position = [0.0, -0.085, 0.016]
            content.addChild(maybe)
            let decline = ModelEntity(mesh: optMesh, materials: [rowBase])
            decline.position = [0.07, -0.085, 0.016]
            content.addChild(decline)
        }
        
        func buildForm() {
            addRow(y: 0.055, alt: false, hasBadge: true, z: 0.0)
            addRow(y: 0.02, alt: true, hasBadge: true, z: 0.004)
            addRow(y: -0.015, alt: false, hasBadge: true, z: 0.008)
            addRow(y: -0.05, alt: true, hasBadge: false, z: 0.012)
            
            let btnMesh = MeshResource.generateBox(width: 0.1, height: 0.024, depth: 0.003, cornerRadius: 0.007)
            let resend = ModelEntity(mesh: btnMesh, materials: [rowAlt])
            resend.position = [-0.06, -0.095, 0.016]
            content.addChild(resend)
            let submit = ModelEntity(mesh: btnMesh, materials: [accent])
            submit.position = [0.06, -0.095, 0.016]
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
        // Key Light - Main source from above
        let keyLight = Entity()
        keyLight.name = "KeyLight"
        var keyComp = PointLightComponent()
        keyComp.intensity = 100000
        keyComp.color = .white
        keyComp.attenuationRadius = 30
        keyLight.components.set(keyComp)
        keyLight.position = [0, 5, -1]
        experienceRoot.addChild(keyLight)
        
        // Fill Light - Soft cool blue from behind
        let fillLight = Entity()
        fillLight.name = "FillLight"
        var fillComp = PointLightComponent()
        fillComp.intensity = 50000
        fillComp.color = .init(red: 0.85, green: 0.9, blue: 1.0, alpha: 1)
        fillComp.attenuationRadius = 25
        fillLight.components.set(fillComp)
        fillLight.position = [0, 1.5, -4]
        experienceRoot.addChild(fillLight)
        
        // Rim Light - Backlight for silhouettes
        let rimLight = Entity()
        rimLight.name = "RimLight"
        var rimComp = PointLightComponent()
        rimComp.intensity = 80000
        rimComp.color = .init(red: 1.0, green: 0.8, blue: 0.6, alpha: 1)
        rimComp.attenuationRadius = 20
        rimLight.components.set(rimComp)
        rimLight.position = [0, 1.6, 5] // Behind the user
        experienceRoot.addChild(rimLight)
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
        
        // Scene-wide breathing pulse
        pulseAlpha = (sin(animationTime * 1.5) + 1.0) * 0.5 // 0 to 1
        
        switch phase {
        case .spatialOverwhelm:
            for (i, window) in windows.enumerated() {
                // Pop in even faster
                let delay = Float(i) * 0.04
                let localProgress = max(0, min(1, (progress * 6.0) - delay))
                let eased = easeOutBack(localProgress)
                window.scale = SIMD3<Float>(repeating: max(0.4, eased))
                let bob = sin(animationTime * 1.8 + Float(i) * 0.8) * 0.02
                window.position.y += bob * dt * 2
                
                // Keep-out from center text (Matching new text position [0, 1.6, -0.8])
                let textCenter = SIMD3<Float>(0, 1.6, -0.8)
                let toWindow = window.position - textCenter
                let dist = length(toWindow)
                let minRadius: Float = 1.8 // Push windows even further away
                if dist < minRadius {
                    let push = normalize(toWindow + SIMD3<Float>(0.0001, 0.0001, 0.0001)) * (minRadius - dist)
                    window.position += push * 0.8 // Stronger push
                }
                // Drift outward
                let outward = normalize(window.position + SIMD3<Float>(0.0001, 0.0001, 0.0001)) * dt * 0.1
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
            // Sync exactly with "142 were unnecessary" text appearing at 0.25
            let triggerPoint: Float = 0.25
            let bloomProgress = max(0, min(1, (progress - triggerPoint) * 5.0))
            let shatterProgress = max(0, min(1, (progress - triggerPoint) * 8.0)) 
            
            if bloomProgress > 0 {
                // Narrative Flare: Increase light intensity dramatically during bloom
                if let keyLight = experienceRoot.findEntity(named: "KeyLight") {
                    var comp = keyLight.components[PointLightComponent.self] ?? PointLightComponent()
                    let flare = 1.0 + (sin(bloomProgress * .pi) * 2.0) // 3x brighter at peak
                    comp.intensity = 100000 * flare
                    keyLight.components.set(comp)
                }
                
                if bloomProgress < 0.5 {
                    let s = easeOutBack(bloomProgress * 2.0) * 15.0
                    bloomLight?.scale = SIMD3<Float>(repeating: s)
                    bloomLight?.components.set(OpacityComponent(opacity: 0.8))
                    
                    // Shockwave expansion
                    let waveS = bloomProgress * 2.0 * 12.0
                    bloomShockwave?.scale = SIMD3<Float>(repeating: waveS)
                    bloomShockwave?.components.set(OpacityComponent(opacity: (0.5 - bloomProgress) * 0.6))
                } else {
                    let fade = max(0, 1.0 - ((bloomProgress - 0.5) * 2.0))
                    bloomLight?.components.set(OpacityComponent(opacity: fade * 0.8))
                    bloomLight?.scale = SIMD3<Float>(repeating: 15.0 + bloomProgress * 5.0)
                    bloomShockwave?.components.set(OpacityComponent(opacity: 0.0))
                }
            } else {
                bloomLight?.scale = .zero
                bloomLight?.components.set(OpacityComponent(opacity: 0.0))
                bloomShockwave?.scale = .zero
                
                // Reset lighting
                if let keyLight = experienceRoot.findEntity(named: "KeyLight") {
                    var comp = keyLight.components[PointLightComponent.self] ?? PointLightComponent()
                    comp.intensity = 100000
                    keyLight.components.set(comp)
                }
            }
            
            // "Shatter" windows by scaling them down into miniature cards
            for (i, window) in windows.enumerated() {
                let targetScale: Float = 0.22
                let scale = 1.0 - (shatterProgress * (1.0 - targetScale))
                window.scale = SIMD3<Float>(repeating: max(targetScale, scale))
                
                // Add a small chaotic push to the windows as they shatter
                if shatterProgress > 0 && shatterProgress < 1.0 {
                    let pushDir = normalize(window.position - SIMD3<Float>(0, 1.6, -1.5))
                    window.position += pushDir * dt * 2.0 * shatterProgress
                }
            }
            
            if bloomProgress <= 0 {
                let tremble = sin(animationTime * 40.0) * 0.003
                windowsParent.position.x += tremble
            }
            
        case .dataChoreography:
            // Reuse the scaled-down windows as the "data cards"
            let chaosToOrder = max(0, min(1, (progress - 0.2) * 5.0)) // Start ordering sooner
            
            bloomLight?.components.set(OpacityComponent(opacity: 0.0))
            bloomLight?.scale = .zero
            bloomShockwave?.scale = .zero
            textDimming?.components.set(OpacityComponent(opacity: progress < 0.3 ? (0.6 * (1.0 - progress/0.3)) : 0.0))
            
            for (i, window) in windows.enumerated() {
                let twinkle = 0.8 + sin(animationTime * 15.0 + Float(i)) * 0.2
                // Add a jitter/noise effect to the chaos
                let noiseX = sin(animationTime * 2.0 + Float(i)) * 0.01
                let noiseY = cos(animationTime * 1.8 + Float(i) * 0.5) * 0.01
                window.scale = SIMD3<Float>(repeating: 0.22 * twinkle)
                
                if chaosToOrder > 0 {
                    // Golden-angle sphere shell radius 2.2 (slightly wider for text)
                    let seed = Float(i)
                    let theta = seed * 2.39996
                    let y = 1 - (seed / Float(windows.count - 1)) * 2
                    let r = sqrt(max(0, 1 - y * y)) * 2.2
                    let targetPos = SIMD3<Float>(cos(theta) * r, y * 2.2 + 1.6, sin(theta) * r)
                    window.position = simd_mix(window.position, targetPos, SIMD3<Float>(repeating: dt * 2.8))
                    
                    // Re-billboard as they move to the shell
                    // Initial orientation: billboarded to user
                    let dx = 0 - window.position.x
                    let dz = 0 - window.position.z 
                    let angle = atan2(dx, dz)
                    window.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
                } else {
                    // Jittery chaos with noise
                    window.position += SIMD3<Float>(sin(animationTime * 1.5 + Float(i)), cos(animationTime * 1.2 + Float(i) * 0.5), sin(animationTime * 0.8 + Float(i))) * 0.006
                    window.position.x += noiseX
                    window.position.y += noiseY
                }
            }
            windowsParent.orientation *= simd_quatf(angle: dt * 0.35 * chaosToOrder, axis: [0, 1, 0])
            
        case .humanRestoration:
            let axis = normalize(SIMD3<Float>(1, 1, 0))
            for window in windows {
                window.scale *= (1.0 + sin(animationTime * 2.0) * 0.05)
            }
            windowsParent.orientation *= simd_quatf(angle: dt * 0.15, axis: axis)
            
            // Slow dust drift
            for mote in dataDust {
                mote.position += SIMD3<Float>(0, sin(animationTime * 0.5) * 0.001, 0)
            }
            
        case .exitMoment:
            let fade = max(0.4, 1.0 - progress * 0.6)
            for window in windows { 
                window.scale = SIMD3<Float>(repeating: 0.22 * fade) 
            }
            windowsParent.orientation *= simd_quatf(angle: dt * 0.3, axis: [0, 1, 0])
            
            for mote in dataDust {
                if let op = mote.components[OpacityComponent.self] {
                    mote.components.set(OpacityComponent(opacity: op.opacity * 0.95))
                }
            }
            
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
        dataDust.removeAll()
        bloomLight = nil
        bloomShockwave = nil
        skyDome = nil
        sceneLoaded = false
    }
}
