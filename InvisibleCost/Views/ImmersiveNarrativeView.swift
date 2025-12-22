import SwiftUI
import RealityKit

/// The Invisible Cost - Tier 2 Vision Pro Experience
/// Per spec: Spatial Overwhelm → Reality Crack → Human Fragment → Data Choreography → Human Restoration → Exit
struct ImmersiveNarrativeView: View {
    @Environment(ExperienceViewModel.self) private var viewModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @State private var sceneRoot = Entity()
    @State private var floatingWindows: [Entity] = []
    @State private var shatterParticles: [Entity] = []
    @State private var lightBeam: Entity?
    @State private var shardParticles: [Entity] = []   // replaces human figures
    @State private var dataPoints: [Entity] = []
    @State private var centralObject: Entity?
    @State private var ctaArc: Entity?
    @State private var skyboxModel: ModelEntity?
    @State private var shockwaveBurst: [Entity] = []
    @State private var sceneBuilt = false
    @State private var closeNotification: Entity?
    
    var body: some View {
        RealityView { content, attachments in
            sceneRoot.name = "InvisibleCostScene"
            content.add(sceneRoot)
            
            await buildScene()
            sceneBuilt = true
            
            if let textAttachment = attachments.entity(for: "narrativeText") {
                textAttachment.position = [0, 1.6, -1.3]
                sceneRoot.addChild(textAttachment)
            }
            
        } update: { content, attachments in
        } attachments: {
            Attachment(id: "narrativeText") {
                NarrativeTextOverlay()
                    .environment(viewModel)
            }
        }
        .task {
            await runExperienceLoop()
        }
    }
    
    // MARK: - Scene Setup
    
    @MainActor
    private func buildScene() async {
        // Dark environment
        let skybox = Entity()
        let mesh = MeshResource.generateSphere(radius: 50)
        let material = UnlitMaterial(color: UIColor(red: 0.01, green: 0.01, blue: 0.02, alpha: 1))
        let model = ModelEntity(mesh: mesh, materials: [material])
        skyboxModel = model
        model.scale = SIMD3<Float>(repeating: -1)
        skybox.addChild(model)
        sceneRoot.addChild(skybox)
        
        // Create notification windows
        for i in 0..<40 {
            let window = createNotificationWindow(index: i, total: 40)
            sceneRoot.addChild(window)
            floatingWindows.append(window)
        }
        
        // Create one "close" notification that will shatter
        closeNotification = createCloseNotification()
        sceneRoot.addChild(closeNotification!)
    }
    
    @MainActor
    private func createNotificationWindow(index: Int, total: Int) -> Entity {
        let entity = Entity()
        entity.name = "Window_\(index)"
        
        let layer = index % 3
        let baseRadius: Float = [1.5, 2.2, 2.9][layer]
        
        let angleRange = Float.pi * 1.4
        let angleOffset = -angleRange / 2
        let theta = angleOffset + (Float(index) / Float(total)) * angleRange + Float.random(in: -0.12...0.12)
        
        let y = Float.random(in: 0.6...2.3)
        let x = baseRadius * sin(theta)
        let z = -baseRadius * cos(theta)
        
        entity.position = [x, y, z]
        
        let width = Float.random(in: 0.25...0.4)
        let height = Float.random(in: 0.15...0.25)
        let cardMesh = MeshResource.generateBox(width: width, height: height, depth: 0.005, cornerRadius: 0.01)
        
        let colors: [UIColor] = [
            UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.8),
            UIColor(red: 0.55, green: 0.2, blue: 0.65, alpha: 0.8),
            UIColor(red: 0.85, green: 0.25, blue: 0.25, alpha: 0.8),
            UIColor(red: 0.2, green: 0.65, blue: 0.4, alpha: 0.8),
            UIColor(red: 0.85, green: 0.55, blue: 0.1, alpha: 0.8),
        ]
        let color = colors.randomElement()!
        
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: color)
        mat.roughness = .init(floatLiteral: 0.1)
        mat.metallic = .init(floatLiteral: 0.25)
        mat.emissiveColor = .init(color: color)
        mat.emissiveIntensity = 0.4
        
        let cardModel = ModelEntity(mesh: cardMesh, materials: [mat])
        entity.addChild(cardModel)
        
        entity.look(at: [0, 1.5, 0], from: entity.position, relativeTo: nil)
        
        entity.components[WindowAnimData.self] = WindowAnimData(
            originalPos: entity.position,
            speed: Float.random(in: 0.3...0.7),
            phase: Float.random(in: 0...(2 * .pi))
        )
        
        cardModel.scale = [0, 0, 0]
        return entity
    }
    
    @MainActor
    private func createCloseNotification() -> Entity {
        let entity = Entity()
        entity.name = "CloseNotification"
        entity.position = [0.3, 1.5, -1.0] // Close to user, slightly right
        
        let cardMesh = MeshResource.generateBox(width: 0.35, height: 0.22, depth: 0.005, cornerRadius: 0.01)
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 0.9))
        mat.roughness = .init(floatLiteral: 0.1)
        mat.emissiveColor = .init(color: UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1))
        mat.emissiveIntensity = 0.5
        
        let cardModel = ModelEntity(mesh: cardMesh, materials: [mat])
        entity.addChild(cardModel)
        entity.look(at: [0, 1.5, 0], from: entity.position, relativeTo: nil)
        
        cardModel.scale = [0, 0, 0]
        return entity
    }
    
    @MainActor
    private func createLightBeam() -> Entity {
        let beam = Entity()
        beam.name = "LightBeam"
        beam.position = [0, 1.5, -2.0]
        
        // Match bar width roughly to text width (~0.6–0.7m)
        let coreMesh = MeshResource.generateBox(width: 0.7, height: 8, depth: 0.02)
        let coreMat = UnlitMaterial(color: UIColor.white.withAlphaComponent(0.9))
        let core = ModelEntity(mesh: coreMesh, materials: [coreMat])
        beam.addChild(core)

        // Subtle glow plane behind bar
        let glowMesh = MeshResource.generateBox(width: 1.1, height: 8.2, depth: 0.01)
        let glowMat = UnlitMaterial(color: UIColor.white.withAlphaComponent(0.08))
        let glow = ModelEntity(mesh: glowMesh, materials: [glowMat])
        glow.position = [0, 0, -0.02]
        beam.addChild(glow)

        beam.scale = [0, 0, 0]
        return beam
    }
    
    // Shockwave burst replacing the flat ring
    @MainActor
    private func createShockwaveBurst(at position: SIMD3<Float>) {
        for _ in 0..<30 {
            let p = Entity()
            p.position = position
            let size = Float.random(in: 0.015...0.03)
            let mesh = MeshResource.generateSphere(radius: size)
            let mat = UnlitMaterial(color: UIColor.white.withAlphaComponent(0.4))
            let model = ModelEntity(mesh: mesh, materials: [mat])
            p.addChild(model)
            let dir = normalize(SIMD3<Float>(
                Float.random(in: -1...1),
                Float.random(in: -0.2...1),
                Float.random(in: -1...1)
            ))
            p.components[ShatterData.self] = ShatterData(velocity: dir * Float.random(in: 0.8...1.6))
            sceneRoot.addChild(p)
            shockwaveBurst.append(p)
        }
    }
    
    // MARK: - Light shard metaphors (replaces human figures)
    @MainActor
    private func createShardParticle() -> Entity {
        let shard = Entity()
        let size = Float.random(in: 0.05...0.12)
        let mesh = MeshResource.generateBox(width: size * 0.4, height: size, depth: size * 0.02, cornerRadius: size * 0.05)
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.35))
        mat.emissiveColor = .init(color: UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1))
        mat.emissiveIntensity = 0.35
        mat.roughness = .init(floatLiteral: 0.4)
        let model = ModelEntity(mesh: mesh, materials: [mat])
        shard.addChild(model)
        shard.scale = [0, 0, 0]
        return shard
    }
    
    @MainActor
    private func createDataPoint(index: Int, centerPos: SIMD3<Float>) -> Entity {
        let point = Entity()
        point.name = "DataPoint_\(index)"
        
        // Start scattered
        let theta = Float.random(in: 0...(2 * .pi))
        let phi = Float.random(in: 0.3...2.8)
        let radius = Float.random(in: 1.5...3.5)
        
        let startPos = centerPos + SIMD3<Float>(
            radius * sin(phi) * cos(theta),
            radius * cos(phi) * 0.5,
            radius * sin(phi) * sin(theta) * 0.7
        )
        point.position = startPos
        
        let size = Float.random(in: 0.015...0.03)
        let mesh = MeshResource.generateSphere(radius: size)
        let color = UIColor(
            red: CGFloat.random(in: 0...0.1),
            green: CGFloat.random(in: 0.7...0.9),
            blue: CGFloat.random(in: 0.8...1.0),
            alpha: 0.9
        )
        let mat = UnlitMaterial(color: color)
        let model = ModelEntity(mesh: mesh, materials: [mat])
        point.addChild(model)
        
        point.components[DataPointData.self] = DataPointData(startPos: startPos, targetPos: centerPos)
        
        return point
    }
    
    @MainActor
    private func createCentralObject() -> Entity {
        let obj = Entity()
        obj.name = "CentralObject"
        obj.position = [0, 1.5, -2.2]
        
        // Geometric core - icosahedron-like (approximated with sphere)
        let coreMesh = MeshResource.generateSphere(radius: 0.18)
        var coreMat = PhysicallyBasedMaterial()
        coreMat.baseColor = .init(tint: UIColor(red: 0, green: 0.8, blue: 0.85, alpha: 1))
        coreMat.roughness = .init(floatLiteral: 0.02)
        coreMat.metallic = .init(floatLiteral: 0.9)
        coreMat.emissiveColor = .init(color: UIColor(red: 0, green: 0.85, blue: 0.9, alpha: 1))
        coreMat.emissiveIntensity = 0.6
        
        let core = ModelEntity(mesh: coreMesh, materials: [coreMat])
        core.name = "Core"
        obj.addChild(core)
        
        // Outer shell
        let shellMesh = MeshResource.generateSphere(radius: 0.25)
        var shellMat = PhysicallyBasedMaterial()
        shellMat.baseColor = .init(tint: UIColor(red: 0, green: 0.5, blue: 0.6, alpha: 0.2))
        shellMat.emissiveColor = .init(color: UIColor(red: 0, green: 0.6, blue: 0.7, alpha: 1))
        shellMat.emissiveIntensity = 0.25
        
        let shell = ModelEntity(mesh: shellMesh, materials: [shellMat])
        obj.addChild(shell)
        
        obj.scale = [0, 0, 0]
        return obj
    }
    
    // MARK: - Animation Loop
    
    @MainActor
    private func runExperienceLoop() async {
        let frameRate: UInt64 = 60
        let frameDuration: UInt64 = 1_000_000_000 / frameRate
        
        while viewModel.isExperienceActive && viewModel.currentPhase != .complete {
            let deltaTime = 1.0 / Double(frameRate)
            viewModel.updateProgress(deltaTime: deltaTime)
            await animatePhase()
            try? await Task.sleep(nanoseconds: frameDuration)
        }
    }
    
    @MainActor
    private func animatePhase() async {
        let time = viewModel.totalElapsedTime
        let progress = viewModel.phaseProgress
        
        switch viewModel.currentPhase {
        case .spatialOverwhelm:
            animateSpatialOverwhelm(time: time, progress: progress)
        case .realityCrack:
            await animateRealityCrack(time: time, progress: progress)
        case .humanFragment:
            await animateLightFragment(time: time, progress: progress)
        case .dataChoreography:
            await animateDataChoreography(time: time, progress: progress)
        case .humanRestoration:
            animateLightRestoration(time: time, progress: progress)
        case .exitMoment:
            animateExitMoment(time: time, progress: progress)
        default:
            break
        }
    }
    
    // MARK: - Phase: Spatial Overwhelm
    
    @MainActor
    private func animateSpatialOverwhelm(time: TimeInterval, progress: Double) {
        let intensity = Float(viewModel.overwhelmIntensity)
        
        // Animate notification windows
        for (i, window) in floatingWindows.enumerated() {
            guard let anim = window.components[WindowAnimData.self],
                  let model = window.children.first else { continue }
            
            // Staggered fade in
            let stagger = Double(i) / Double(floatingWindows.count) * 0.4
            let adjusted = max(0, progress - stagger) / (1.0 - stagger)
            let fadeIn = Float(min(1.0, adjusted * 2.5))
            model.scale = SIMD3<Float>(repeating: fadeIn)
            
            // Drift
            let drift = SIMD3<Float>(
                sin(Float(time) * anim.speed + anim.phase) * 0.03,
                cos(Float(time) * anim.speed * 0.6 + anim.phase) * 0.02,
                sin(Float(time) * anim.speed * 0.3) * 0.01
            )
            window.position = anim.originalPos + drift * (0.5 + intensity * 0.5)
            
            // Compress toward user
            window.position *= (1.0 - intensity * 0.06)
        }
        
        // Close notification drifts toward user
        if let close = closeNotification, let model = close.children.first {
            let closeProgress = Float(min(1.0, progress * 1.5))
            model.scale = SIMD3<Float>(repeating: closeProgress)
            
            // Drift closer
            let startPos = SIMD3<Float>(0.3, 1.5, -1.0)
            let endPos = SIMD3<Float>(0.15, 1.5, -0.6) // Very close
            close.position = mix(startPos, endPos, t: Float(progress))
            
            // Shatter effect at 80%
            if viewModel.notificationShattered && shatterParticles.isEmpty {
                createShatterEffect(at: close.position)
                close.isEnabled = false
            }
        }
    }
    
    @MainActor
    private func createShatterEffect(at position: SIMD3<Float>) {
        // Create small particles that fly outward
        for _ in 0..<30 {
            let particle = Entity()
            particle.position = position
            
            let size = Float.random(in: 0.008...0.02)
            let mesh = MeshResource.generateBox(width: size, height: size, depth: size * 0.5)
            let mat = UnlitMaterial(color: UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 0.8))
            let model = ModelEntity(mesh: mesh, materials: [mat])
            particle.addChild(model)
            
            // Random velocity direction
            let vel = SIMD3<Float>(
                Float.random(in: -1...1),
                Float.random(in: -0.5...1),
                Float.random(in: -1...1)
            )
            particle.components[ShatterData.self] = ShatterData(velocity: normalize(vel) * Float.random(in: 0.5...1.5))
            
            sceneRoot.addChild(particle)
            shatterParticles.append(particle)
        }
    }
    
    // MARK: - Phase: Reality Crack
    
    @MainActor
    private func animateRealityCrack(time: TimeInterval, progress: Double) async {
        // Create beam
        if lightBeam == nil {
            lightBeam = createLightBeam()
            sceneRoot.addChild(lightBeam!)
        }
        // Shockwave burst once
        if shockwaveBurst.isEmpty {
            createShockwaveBurst(at: [0, 1.5, -2.0])
        }
        
        // Beam scales in
        let beamScale = Float(min(1.3, progress * 5))
        lightBeam?.scale = [beamScale, 1, beamScale]
        lightBeam?.isEnabled = true
        
        // Shockwave particles expand and fade
        for burst in shockwaveBurst {
            if let data = burst.components[ShatterData.self],
               let model = burst.children.first as? ModelEntity {
                burst.position += data.velocity * 0.016
                let fade = Float(max(0, 0.4 - progress * 0.4))
                model.scale = SIMD3<Float>(repeating: fade)
            }
        }
        
        // Windows freeze and fade
        let fadeOut = Float(max(0, 1.0 - progress * 2))
        for window in floatingWindows {
            if let model = window.children.first {
                model.scale = SIMD3<Float>(repeating: fadeOut)
            }
        }
        
        // Darken skybox slightly for drama
        if let sky = skyboxModel, var mat = sky.model?.materials.first as? UnlitMaterial {
            let base = CGFloat(0.01)
            let darken = max(0, base - CGFloat(progress) * 0.008)
            mat.color = .init(tint: UIColor(red: darken, green: darken, blue: darken + 0.01, alpha: 1))
            sky.model?.materials = [mat]
        }
        
        // Animate shatter particles outward then fade
        for particle in shatterParticles {
            if let data = particle.components[ShatterData.self],
               let model = particle.children.first {
                particle.position += data.velocity * 0.016 // ~60fps
                let fade = Float(max(0, 1.0 - progress * 1.5))
                model.scale = SIMD3<Float>(repeating: fade)
            }
        }
    }
    
    // MARK: - Phase: Human Fragment
    
    @MainActor
    private func animateLightFragment(time: TimeInterval, progress: Double) async {
        // Hide windows and beam
        if shardParticles.isEmpty {
            for window in floatingWindows { window.isEnabled = false }
            for particle in shatterParticles { particle.isEnabled = false }
            lightBeam?.isEnabled = false
            
            // Spawn shards in a cluster in front of the user
            for _ in 0..<60 {
                let shard = createShardParticle()
                let spread: Float = 1.2
                shard.position = [
                    Float.random(in: -spread...spread),
                    1.3 + Float.random(in: -0.4...0.4),
                    -2.4 + Float.random(in: -0.3...0.3)
                ]
                sceneRoot.addChild(shard)
                shardParticles.append(shard)
            }
        }
        
        // Animate shards drifting outward (fragmentation metaphor)
        let driftStrength = Float(0.35 * (1.0 - progress * 0.4))
        let fadeIn = Float(min(1.0, progress * 2))
        
        for shard in shardParticles {
            if let model = shard.children.first as? ModelEntity {
                model.scale = SIMD3<Float>(repeating: fadeIn)
            }
            // drift outward
            shard.position += SIMD3<Float>(
                Float.random(in: -driftStrength...driftStrength),
                Float.random(in: -driftStrength * 0.5...driftStrength * 0.5),
                Float.random(in: -driftStrength * 0.4...driftStrength * 0.4)
            ) * 0.01
            // slow spin
            shard.orientation = simd_quatf(angle: Float(time) * 0.3, axis: normalize([Float.random(in: -1...1), 1, Float.random(in: -1...1)]))
        }
    }
    
    // MARK: - Phase: Data Choreography
    
    @MainActor
    private func animateDataChoreography(time: TimeInterval, progress: Double) async {
        let centerPos = SIMD3<Float>(0, 1.5, -2.2)
        
        // Create central object and data points
        if centralObject == nil {
            centralObject = createCentralObject()
            sceneRoot.addChild(centralObject!)
            
            // Create data points
            for i in 0..<120 {
                let point = createDataPoint(index: i, centerPos: centerPos)
                sceneRoot.addChild(point)
                dataPoints.append(point)
            }
        }
        
        // Central object grows and rotates
        let objScale = Float(min(1.0, progress * 1.3)) * 0.65
        centralObject?.scale = SIMD3<Float>(repeating: objScale)
        centralObject?.orientation = simd_quatf(angle: Float(time) * 0.2, axis: normalize([0.1, 1, 0.05]))
        
        // Data points converge
        for point in dataPoints {
            guard let data = point.components[DataPointData.self],
                  let model = point.children.first else { continue }
            
            let t = Float(min(1.0, progress * 1.25))
            let newPos = mix(data.startPos, data.targetPos, t: t)
            
            // Spiral motion with easing
            let ease = (1 - t) * (1 - t)
            let spiral = SIMD3<Float>(
                cos(Float(time) * 3 + data.startPos.x * 2) * ease * 0.35,
                sin(Float(time) * 2.5 + data.startPos.y * 2) * ease * 0.25,
                sin(Float(time) * 2 + data.startPos.z) * ease * 0.2
            )
            point.position = newPos + spiral
            
            // Fade as they reach center
            let dist = length(point.position - centerPos)
            if dist < 0.3 {
                model.scale = SIMD3<Float>(repeating: max(0, (dist - 0.05) / 0.25))
            }
        }
        
        // Increase central object glow
        if let core = centralObject?.findEntity(named: "Core") as? ModelEntity,
           var mat = core.model?.materials.first as? PhysicallyBasedMaterial {
            mat.emissiveIntensity = 0.5 + Float(progress) * 0.5
            core.model?.materials = [mat]
        }
    }
    
    // MARK: - Phase: Human Restoration
    
    @MainActor
    private func animateLightRestoration(time: TimeInterval, progress: Double) {
        // Hide data points
        for point in dataPoints {
            point.isEnabled = false
        }
        
        // Shards converge and dissolve into the central object (human restoration metaphor)
        let centerPos = SIMD3<Float>(0, 1.5, -2.2)
        for shard in shardParticles {
            if let model = shard.children.first as? ModelEntity {
                let toCenter = centerPos - shard.position
                shard.position += toCenter * 0.02
                
                // Fade as it nears center
                let dist = length(toCenter)
                let fade = Float(max(0, min(1, dist / 0.5)))
                model.scale = SIMD3<Float>(repeating: fade)
            }
        }
        
        // Central object pulses and warms up
        if let obj = centralObject {
            let pulse = 0.6 + sin(Float(time) * 1.5) * 0.02
            obj.scale = SIMD3<Float>(repeating: pulse)
            obj.orientation = simd_quatf(angle: Float(time) * 0.1, axis: [0, 1, 0])
            
            if let core = obj.findEntity(named: "Core") as? ModelEntity,
               var mat = core.model?.materials.first as? PhysicallyBasedMaterial {
                mat.emissiveColor = .init(color: UIColor(red: 0.1, green: 0.9, blue: 0.85, alpha: 1))
                mat.emissiveIntensity = 0.8 + Float(progress) * 0.4
                core.model?.materials = [mat]
            }
        }
    }
    
    // MARK: - Phase: Exit Moment
    
    @MainActor
    private func animateExitMoment(time: TimeInterval, progress: Double) {
        // Gentle ambient motion on central object
        if let obj = centralObject {
            let pulse = 0.6 + sin(Float(time) * 1.2) * 0.015
            obj.scale = SIMD3<Float>(repeating: pulse)
            obj.orientation = simd_quatf(angle: Float(time) * 0.08, axis: [0, 1, 0])
        }
        
        // Volumetric CTA arc - glowing points around the user
        if ctaArc == nil {
            ctaArc = createCTAArc()
            if let arc = ctaArc {
                sceneRoot.addChild(arc)
            }
        }
    }
    
    // MARK: - CTA Arc
    @MainActor
    private func createCTAArc() -> Entity {
        let arc = Entity()
        let radius: Float = 2.1
        let count = 28
        let startAngle: Float = -.pi * 0.65
        let endAngle: Float = .pi * 0.65
        
        for i in 0..<count {
            let t = Float(i) / Float(count - 1)
            let angle = startAngle + (endAngle - startAngle) * t
            let radialJitter = Float.random(in: -0.12...0.12)
            let r = radius + radialJitter
            let x = r * sin(angle)
            let z = -r * cos(angle)
            let y: Float = 1.4 + sin(angle * 1.7) * 0.18 + Float.random(in: -0.05...0.05)
            
            let point = Entity()
            point.position = [x, y, z]
            
            let size = Float.random(in: 0.012...0.025)
            let mesh = MeshResource.generateSphere(radius: size)
            let mat = UnlitMaterial(color: UIColor(red: 0.9, green: 0.85, blue: 0.6, alpha: 0.9))
            let model = ModelEntity(mesh: mesh, materials: [mat])
            point.addChild(model)
            
            arc.addChild(point)
        }
        return arc
    }
}

// MARK: - Components

struct WindowAnimData: Component {
    var originalPos: SIMD3<Float>
    var speed: Float
    var phase: Float
}

struct DataPointData: Component {
    var startPos: SIMD3<Float>
    var targetPos: SIMD3<Float>
}

struct ShatterData: Component {
    var velocity: SIMD3<Float>
}

// MARK: - Helper

func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, t: Float) -> SIMD3<Float> {
    return a + (b - a) * t
}

#Preview(immersionStyle: .full) {
    ImmersiveNarrativeView()
        .environment(ExperienceViewModel())
}
