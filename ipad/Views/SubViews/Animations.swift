import SwiftUI
import Foundation

// MARK: - Narrator Frame Animation (00:07-00:37)
struct NarratorFrameAnimation: View {
    var progress: Double
    @Environment(MotionManager.self) private var motion
    @State private var windowStates: [(id: Int, pos: CGPoint, size: CGSize)] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                
                // Redundant windows distributed across the ENTIRE screen
                ZStack {
                    ForEach(windowStates, id: \.id) { state in
                        WorkWindowView(index: state.id)
                            .frame(width: state.size.width, height: state.size.height)
                            .position(
                                x: state.pos.x + CGFloat(motion.roll * Double(state.id % 10 + 5)),
                                y: state.pos.y + CGFloat(motion.pitch * Double(state.id % 10 + 5))
                            )
                            .scaleEffect(0.6 + progress * 0.4)
                            .opacity(0.4 + (1.0 - progress) * 0.6)
                    }
                }
                .drawingGroup()
                .onAppear {
                    if windowStates.isEmpty {
                        windowStates = (0..<30).map { i in
                            (id: i,
                             pos: CGPoint(
                                x: CGFloat.random(in: 0...geo.size.width),
                                y: CGFloat.random(in: 0...geo.size.height)
                             ),
                             size: CGSize(
                                width: CGFloat.random(in: 250...450),
                                height: CGFloat.random(in: 200...350)
                             ))
                        }
                    }
                }
                
                // Narrator Text
                VStack(spacing: 30) {
                    Text("Every organization carries a hidden cost.")
                        .font(.system(size: 42, weight: .light, design: .serif))
                        .foregroundColor(.white)
                        .opacity(progress > 0.1 ? 1 : 0)
                        .offset(y: progress > 0.1 ? 0 : 20)
                    
                    Text("Most leaders never see it.")
                        .font(.system(size: 42, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .opacity(progress > 0.4 ? 1 : 0)
                        .offset(y: progress > 0.4 ? 0 : 20)
                    
                    if progress > 0.7 {
                        // Visual decision counter with impact
                        VStack(spacing: 20) {
                            HStack(spacing: 40) {
                                // Decisions made
                                VStack(spacing: 8) {
                                    Text("247")
                                        .font(.system(size: 56, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("decisions today")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                
                                // Unnecessary ones (red accent)
                                VStack(spacing: 8) {
                                    Text("142")
                                        .font(.system(size: 56, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                                    Text("were unnecessary")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.5))
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.4), lineWidth: 1)
                                        )
                                )
                            }
                            
                            // Progress bar showing waste
                            VStack(spacing: 8) {
                                GeometryReader { barGeo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.2))
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(red: 1.0, green: 0.4, blue: 0.4))
                                            .frame(width: barGeo.size.width * 0.575) // 142/247
                                    }
                                }
                                .frame(width: 300, height: 8)
                                
                                Text("57% of your decisions could be automated")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                
                // Accelerating Timestamps (Spec requirement)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(TimestampGenerator.getTime(for: progress))
                            .font(.system(size: 120, weight: .thin, design: .monospaced))
                            .foregroundColor(.white.opacity(0.1))
                            .padding(40)
                    }
                }
            }
            .animation(.easeOut(duration: 1.5), value: progress)
        }
    }
}

struct TimestampGenerator {
    static func getTime(for progress: Double) -> String {
        let totalMinutes = Int(progress * 1440) // Accelerate through a full day
        let hours = (totalMinutes / 60) % 24
        let minutes = totalMinutes % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

// MARK: - Human Vignettes Animation (00:37-01:15)
struct HumanVignettesAnimation: View {
    var progress: Double
    @Environment(MotionManager.self) private var motion
    
    // Department color themes
    private let departmentColors: [DepartmentTheme] = [
        DepartmentTheme(
            primary: Color(red: 0.2, green: 0.5, blue: 0.9),      // Finance: Blue
            accent: Color(red: 0.3, green: 0.6, blue: 1.0),
            glow: Color(red: 0.1, green: 0.3, blue: 0.7)
        ),
        DepartmentTheme(
            primary: Color(red: 0.95, green: 0.6, blue: 0.2),     // Supply Chain: Orange
            accent: Color(red: 1.0, green: 0.7, blue: 0.3),
            glow: Color(red: 0.7, green: 0.4, blue: 0.1)
        ),
        DepartmentTheme(
            primary: Color(red: 0.2, green: 0.75, blue: 0.5),     // Healthcare: Green
            accent: Color(red: 0.3, green: 0.85, blue: 0.6),
            glow: Color(red: 0.1, green: 0.5, blue: 0.3)
        )
    ]
    
    // Which vignette is currently active (0, 1, or 2)
    private var currentVignette: Int {
        if progress < 0.33 { return 0 }
        else if progress < 0.66 { return 1 }
        else { return 2 }
    }
    
    // Progress within the current vignette (0 to 1)
    private var localProgress: Double {
        let segment = progress.truncatingRemainder(dividingBy: 0.33) / 0.33
        return min(1.0, segment)
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let theme = departmentColors[currentVignette]
            
            ZStack {
                // Animated gradient background with department color
                Color.black
                    .overlay(
                        RadialGradient(
                            colors: [
                                theme.glow.opacity(0.35),
                                Color.black
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 450
                        )
                        .scaleEffect(1.0 + sin(time * 0.5) * 0.08)
                    )
                    .animation(.easeInOut(duration: 0.8), value: currentVignette)
                
                // Floating particles in department color
                Canvas { context, size in
                    let particleColor = theme.primary
                    for i in 0..<25 {
                        let angle = time * 0.2 + Double(i) * 0.5
                        let radius = 150.0 + Double(i) * 12
                        let x = size.width / 2 + CGFloat(cos(angle) * radius)
                        let y = size.height / 2 + CGFloat(sin(angle * 0.7) * radius * 0.6)
                        let opacity = 0.15 + sin(time * 1.5 + Double(i)) * 0.1
                        let particleSize: CGFloat = 3 + CGFloat(i % 3)
                        
                        context.fill(
                            Circle().path(in: CGRect(x: x - particleSize/2, y: y - particleSize/2, 
                                                     width: particleSize, height: particleSize)),
                            with: .color(particleColor.opacity(opacity))
                        )
                    }
                }
                
                // Current vignette content with staggered animations
                VignetteContent(
                    title: vignetteData[currentVignette].title,
                    subtitle: vignetteData[currentVignette].subtitle,
                    icon: vignetteData[currentVignette].icon,
                    metrics: vignetteData[currentVignette].metrics,
                    theme: theme,
                    localProgress: localProgress,
                    time: time
                )
                .id(currentVignette) // Force view recreation for transitions
                .transition(.asymmetric(
                    insertion: .opacity
                        .combined(with: .scale(scale: 0.8))
                        .combined(with: .offset(x: 50, y: 0)),
                    removal: .opacity
                        .combined(with: .scale(scale: 1.05))
                        .combined(with: .offset(x: -50, y: 0))
                ))
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: currentVignette)
        }
    }
    
    // Data for each vignette
    private var vignetteData: [(title: String, subtitle: String, icon: String, metrics: [(value: String, label: String)])] {
        [
            (title: "FINANCE", subtitle: "Reconciliation Fatigue", icon: "chart.bar.xaxis",
             metrics: [("4.7h", "daily reconciliation"), ("340", "manual entries"), ("23", "systems touched")]),
            (title: "SUPPLY CHAIN", subtitle: "Inventory Friction", icon: "shippingbox",
             metrics: [("3.2h", "tracking overhead"), ("89%", "manual updates"), ("$2.4M", "annual waste")]),
            (title: "HEALTHCARE", subtitle: "Administrative Burden", icon: "cross.case",
             metrics: [("5.1h", "paperwork daily"), ("67%", "non-clinical tasks"), ("142", "forms per week")])
        ]
    }
}

struct DepartmentTheme {
    let primary: Color
    let accent: Color
    let glow: Color
}

struct VignetteContent: View {
    let title: String
    let subtitle: String
    let icon: String
    let metrics: [(value: String, label: String)]
    let theme: DepartmentTheme
    let localProgress: Double
    let time: Double
    
    var body: some View {
        VStack(spacing: 28) {
            // Icon with animated glow in department color
            ZStack {
                // Pulsing outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.primary.opacity(0.4), theme.primary.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 110
                        )
                    )
                    .frame(width: 220, height: 220)
                    .scaleEffect(1.0 + sin(time * 2) * 0.1)
                
                // Inner glow ring
                Circle()
                    .stroke(theme.accent.opacity(0.5), lineWidth: 2.5)
                    .frame(width: 140, height: 140)
                    .scaleEffect(1.0 + sin(time * 1.5 + 0.5) * 0.06)
                
                // Second ring
                Circle()
                    .stroke(theme.primary.opacity(0.25), lineWidth: 1.5)
                    .frame(width: 170, height: 170)
                    .scaleEffect(1.0 + sin(time * 1.2) * 0.04)
                
                // Icon with department color tint
                Image(systemName: icon)
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(theme.accent)
                    .shadow(color: theme.primary.opacity(0.5), radius: 10)
                    .scaleEffect(localProgress > 0.1 ? 1.0 : 0.6)
                    .opacity(localProgress > 0.05 ? 1.0 : 0.0)
                
                // Warning indicator
                Circle()
                    .fill(theme.accent)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Image(systemName: "exclamationmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                    )
                    .offset(x: 50, y: -50)
                    .scaleEffect(1.0 + sin(time * 3) * 0.15)
                    .opacity(localProgress > 0.15 ? 1.0 : 0.0)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: localProgress)
            
            // Title with slide-in and department color
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .default))
                .tracking(14)
                .foregroundColor(theme.accent)
                .shadow(color: theme.primary.opacity(0.3), radius: 8)
                .offset(y: localProgress > 0.2 ? 0 : 15)
                .opacity(localProgress > 0.15 ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: localProgress)
            
            // Subtitle with fade-in
            Text(subtitle)
                .font(.system(size: 30, weight: .light, design: .serif))
                .italic()
                .foregroundColor(.white)
                .offset(y: localProgress > 0.3 ? 0 : 10)
                .opacity(localProgress > 0.25 ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: localProgress)
            
            // Metrics with staggered entry and department theming
            HStack(spacing: 20) {
                ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                    PainMetricView(
                        value: metric.value,
                        label: metric.label,
                        theme: theme
                    )
                    .offset(y: localProgress > (0.35 + Double(index) * 0.08) ? 0 : 25)
                    .opacity(localProgress > (0.3 + Double(index) * 0.08) ? 1.0 : 0.0)
                    .scaleEffect(localProgress > (0.35 + Double(index) * 0.08) ? 1.0 : 0.9)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.12), value: localProgress)
                }
            }
            .padding(.top, 12)
        }
    }
}

struct PainMetricView: View {
    let value: String
    let label: String
    let theme: DepartmentTheme
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(theme.accent)
                .shadow(color: theme.primary.opacity(0.3), radius: 4)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.glow.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.primary.opacity(0.35), lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Pattern Break View (01:15-01:45)
struct PatternBreakView: View {
    var progress: Double
    @State private var workItems: [(id: Int, x: CGFloat, y: CGFloat, opacity: Double)] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white
                
                // Fading work windows in background representing "the work"
                ForEach(workItems, id: \.id) { item in
                    MiniWorkWindow()
                        .frame(width: 120, height: 80)
                        .position(x: item.x, y: item.y)
                        .opacity(item.opacity * (1.0 - progress * 1.2)) // Fade out as question appears
                }
                
                // Main question with visual context
                VStack(spacing: 35) {
                    // Visual representation of "this work"
                    if progress > 0.1 {
                        HStack(spacing: 15) {
                            ForEach(0..<5, id: \.self) { i in
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(width: 50, height: 35)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 40, height: 4)
                                }
                                .opacity(1.0 - progress * 0.8)
                            }
                        }
                        .transition(.opacity)
                    }
                    
                    Text("What if this work...")
                        .font(.system(size: 48, weight: .light, design: .serif))
                        .foregroundColor(.black)
                        .opacity(progress > 0.15 ? 1 : 0)
                    
                    Text("wasn't your work?")
                        .font(.system(size: 48, weight: .medium, design: .serif))
                        .foregroundColor(.black)
                        .opacity(progress > 0.35 ? 1 : 0)
                        .offset(y: progress > 0.35 ? 0 : 10)
                }
                .animation(.easeOut(duration: 1.5), value: progress)
            }
            .onAppear {
                if workItems.isEmpty {
                    workItems = (0..<12).map { i in
                        (id: i,
                         x: CGFloat.random(in: 80...(geo.size.width - 80)),
                         y: CGFloat.random(in: 80...(geo.size.height - 80)),
                         opacity: Double.random(in: 0.5...0.8)) // More visible
                    }
                }
            }
        }
    }
}

struct MiniWorkWindow: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 3) {
                Circle().fill(Color.gray.opacity(0.6)).frame(width: 5, height: 5)
                Circle().fill(Color.gray.opacity(0.6)).frame(width: 5, height: 5)
                Circle().fill(Color.gray.opacity(0.6)).frame(width: 5, height: 5)
                Spacer()
            }
            .padding(8)
            .background(Color.gray.opacity(0.25))
            
            VStack(alignment: .leading, spacing: 5) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.35))
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 70, height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 4)
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(Color.gray.opacity(0.12))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Agentic Orchestration (01:45-02:45)
/// Neural Network Formation: geometric nodes → intelligent connections → unified blue orchestration
struct AgenticOrchestrationAnimation: View {
    var progress: Double
    @Environment(MotionManager.self) private var motion
    
    // Geometric hexagonal grid nodes (aesthetic pattern)
    private let nodes: [(x: CGFloat, y: CGFloat, tier: Int)] = {
        var result: [(CGFloat, CGFloat, Int)] = []
        // Center node
        result.append((0.5, 0.5, 0))
        // Inner ring (6 nodes, hexagonal)
        for i in 0..<6 {
            let angle = Double(i) * (.pi / 3) - .pi / 6
            result.append((CGFloat(cos(angle) * 0.12 + 0.5), CGFloat(sin(angle) * 0.12 + 0.5), 1))
        }
        // Middle ring (12 nodes)
        for i in 0..<12 {
            let angle = Double(i) * (.pi / 6) 
            result.append((CGFloat(cos(angle) * 0.26 + 0.5), CGFloat(sin(angle) * 0.26 + 0.5), 2))
        }
        // Outer ring (18 nodes)
        for i in 0..<18 {
            let angle = Double(i) * (.pi / 9) + .pi / 18
            result.append((CGFloat(cos(angle) * 0.42 + 0.5), CGFloat(sin(angle) * 0.42 + 0.5), 3))
        }
        return result
    }()
    
    // Teal color palette
    private let primaryBlue = Color(red: 0.0, green: 0.6, blue: 0.7)
    private let glowBlue = Color(red: 0.1, green: 0.75, blue: 0.85)
    private let darkBlue = Color(red: 0.0, green: 0.4, blue: 0.5)
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                // Animation phases
                let nodeAppear = min(1.0, progress / 0.3)
                let connectionDraw = min(1.0, max(0, (progress - 0.12) / 0.45))
                let unifyPhase = min(1.0, max(0, (progress - 0.5) / 0.35))
                let pulseActive = progress > 0.45
                
                // Calculate node screen positions
                let nodePositions = nodes.map { n in
                    (pos: CGPoint(x: n.x * size.width, y: n.y * size.height), tier: n.tier)
                }
                
                // 1) DRAW CONNECTIONS (elegant lines linking nodes)
                if connectionDraw > 0 {
                    for i in 0..<nodes.count {
                        for j in (i+1)..<nodes.count {
                            let p1 = nodePositions[i].pos
                            let p2 = nodePositions[j].pos
                            let t1 = nodePositions[i].tier
                            let t2 = nodePositions[j].tier
                            let dist = hypot(p2.x - p1.x, p2.y - p1.y)
                            
                            // Connect nodes: same tier or adjacent tiers only
                            let tierDiff = abs(t1 - t2)
                            let maxDist = size.width * (tierDiff <= 1 ? 0.22 : 0.12)
                            
                            if dist < maxDist && tierDiff <= 1 {
                                let connectionIndex = Double(i + j)
                                let connectionProgress = min(1.0, max(0, (connectionDraw - connectionIndex * 0.008) * 2.0))
                                
                                if connectionProgress > 0 {
                                    var line = Path()
                                    line.move(to: p1)
                                    line.addLine(to: p2)
                                    
                                    let lineOpacity = 0.1 + 0.35 * connectionProgress + 0.15 * unifyPhase
                                    context.stroke(line, with: .color(primaryBlue.opacity(lineOpacity)), lineWidth: 1.0)
                                    
                                    // Data pulse traveling along connection
                                    if pulseActive {
                                        let pulseT = fmod(time * 1.2 + connectionIndex * 0.07, 1.0)
                                        let pulseX = p1.x + (p2.x - p1.x) * CGFloat(pulseT)
                                        let pulseY = p1.y + (p2.y - p1.y) * CGFloat(pulseT)
                                        
                                        context.fill(
                                            Circle().path(in: CGRect(x: pulseX - 2.5, y: pulseY - 2.5, width: 5, height: 5)),
                                            with: .color(glowBlue.opacity(0.85))
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 2) DRAW NODES (geometric hexagons for inner tiers, circles for outer)
                for (i, node) in nodePositions.enumerated() {
                    let nodeIndex = Double(i)
                    let tierDelay = Double(node.tier) * 0.06
                    let nodeOpacity = min(1.0, max(0, (nodeAppear - tierDelay - nodeIndex * 0.008) * 2.5))
                    
                    if nodeOpacity > 0 {
                        // Size based on tier (inner = larger)
                        let baseSize: CGFloat = node.tier == 0 ? 12 : (node.tier == 1 ? 8 : (node.tier == 2 ? 6 : 5))
                        let growthBonus: CGFloat = unifyPhase > 0 ? 2 * CGFloat(unifyPhase) : 0
                        let nodeSize = baseSize + growthBonus
                        
                        // Gentle float animation
                        let floatX = CGFloat(sin(time * 1.5 + nodeIndex * 0.4)) * 2
                        let floatY = CGFloat(cos(time * 1.1 + nodeIndex * 0.6)) * 2
                        let nodePos = CGPoint(x: node.pos.x + floatX, y: node.pos.y + floatY)
                        
                        // Outer glow
                        context.fill(
                            Circle().path(in: CGRect(x: nodePos.x - nodeSize * 1.5, y: nodePos.y - nodeSize * 1.5, width: nodeSize * 3, height: nodeSize * 3)),
                            with: .color(glowBlue.opacity(0.12 * nodeOpacity * (1 + unifyPhase * 0.5)))
                        )
                        
                        // Inner hexagon for tier 0-1, circle for others
                        if node.tier <= 1 {
                            var hex = Path()
                            for h in 0..<6 {
                                let angle = Double(h) * (.pi / 3) - .pi / 6
                                let hx = nodePos.x + CGFloat(cos(angle)) * nodeSize * 0.8
                                let hy = nodePos.y + CGFloat(sin(angle)) * nodeSize * 0.8
                                if h == 0 { hex.move(to: CGPoint(x: hx, y: hy)) }
                                else { hex.addLine(to: CGPoint(x: hx, y: hy)) }
                            }
                            hex.closeSubpath()
                            context.fill(hex, with: .color(primaryBlue.opacity(0.85 * nodeOpacity)))
                            context.stroke(hex, with: .color(glowBlue.opacity(0.9 * nodeOpacity)), lineWidth: 1.2)
                        } else {
                            context.fill(
                                Circle().path(in: CGRect(x: nodePos.x - nodeSize/2, y: nodePos.y - nodeSize/2, width: nodeSize, height: nodeSize)),
                                with: .color(primaryBlue.opacity(0.8 * nodeOpacity))
                            )
                        }
                    }
                }
                
                // 3) CENTRAL HUB (larger hexagon, emerges as the orchestrator)
                if unifyPhase > 0.15 {
                    let hubReveal = min(1.0, (unifyPhase - 0.15) * 2.0)
                    let hubPulse = 1.0 + sin(time * 2.5) * 0.06
                    let hubSize: CGFloat = 45 * CGFloat(hubReveal) * CGFloat(hubPulse)
                    
                    // Radial glow
                    context.fill(
                        Circle().path(in: CGRect(x: center.x - hubSize * 2, y: center.y - hubSize * 2, width: hubSize * 4, height: hubSize * 4)),
                        with: .radialGradient(
                            Gradient(colors: [glowBlue.opacity(0.35 * hubReveal), .clear]),
                            center: center, startRadius: 0, endRadius: hubSize * 2
                        )
                    )
                    
                    // Hub hexagon
                    var hubHex = Path()
                    for h in 0..<6 {
                        let angle = Double(h) * (.pi / 3) - .pi / 6
                        let hx = center.x + CGFloat(cos(angle)) * hubSize
                        let hy = center.y + CGFloat(sin(angle)) * hubSize
                        if h == 0 { hubHex.move(to: CGPoint(x: hx, y: hy)) }
                        else { hubHex.addLine(to: CGPoint(x: hx, y: hy)) }
                    }
                    hubHex.closeSubpath()
                    
                    context.fill(hubHex, with: .color(primaryBlue.opacity(0.9 * hubReveal)))
                    context.stroke(hubHex, with: .color(glowBlue), lineWidth: 2.5)
                    
                    // Inner hexagon detail
                    var innerHex = Path()
                    for h in 0..<6 {
                        let angle = Double(h) * (.pi / 3) - .pi / 6
                        let hx = center.x + CGFloat(cos(angle)) * hubSize * 0.5
                        let hy = center.y + CGFloat(sin(angle)) * hubSize * 0.5
                        if h == 0 { innerHex.move(to: CGPoint(x: hx, y: hy)) }
                        else { innerHex.addLine(to: CGPoint(x: hx, y: hy)) }
                    }
                    innerHex.closeSubpath()
                    context.stroke(innerHex, with: .color(Color.white.opacity(0.4 * hubReveal)), lineWidth: 1.2)
                }
            }
            // Scale down when pulsing to make room for text - compact to avoid overlap
            .scaleEffect(progress > 0.5 ? 0.58 : 1.0)
            .offset(y: progress > 0.5 ? -90 : 0)
            .animation(.easeInOut(duration: 0.8), value: progress > 0.5)
            .background(Color.black)
        }
        .overlay {
            // Text overlay centered on screen with glow
            if progress > 0.55 {
                let textOpacity = min(1.0, (progress - 0.55) * 2.5)
                
                VStack {
                    Spacer()
                    Text("AGENTIC ORCHESTRATION")
                        .font(.system(size: 28, weight: .bold))
                        .tracking(8)
                        .foregroundColor(glowBlue)
                        .shadow(color: glowBlue, radius: 15)
                        .shadow(color: glowBlue.opacity(0.6), radius: 25)
                        .shadow(color: primaryBlue.opacity(0.4), radius: 40)
                        .opacity(textOpacity)
                        .frame(maxWidth: .infinity)
                    Spacer()
                        .frame(height: 80)
                }
            }
        }
    }
}

// MARK: - Human Return (02:45-03:30)
/// Cinematic reveal: Human silhouette emerges from the network, potential restored
struct HumanReturnAnimation: View {
    var progress: Double
    
    // Colors - deeper teal/cyan for differentiation
    private let accentBlue = Color(red: 0.0, green: 0.6, blue: 0.75)   // Teal
    private let glowBlue = Color(red: 0.1, green: 0.7, blue: 0.85)     // Lighter teal glow
    private let warmWhite = Color(red: 0.98, green: 0.98, blue: 0.96)
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            ZStack {
                // Gradient background: transitions from dark to light
                LinearGradient(
                    colors: [
                        Color(white: 0.02 + 0.96 * progress),
                        Color(white: 0.05 + 0.93 * progress)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Animated energy arcs behind the figure
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height * 0.38)
                    
                    // Smooth color blend factor (0 = white/gray, 1 = teal)
                    let colorBlend = min(1.0, max(0, (progress - 0.3) / 0.5)) // Gradual from 0.3 to 0.8
                    
                    // Draw flowing arc lines emanating from center
                    let arcCount = 8
                    for i in 0..<arcCount {
                        let arcProgress = min(1.0, max(0, (progress - 0.15 - Double(i) * 0.03) * 2.0))
                        if arcProgress > 0 {
                            let baseAngle = Double(i) * (.pi / Double(arcCount)) - .pi / 2
                            let wobble = sin(time * 1.5 + Double(i)) * 0.05
                            let startAngle = baseAngle - 0.4 + wobble
                            let endAngle = baseAngle + 0.4 + wobble
                            let radius: CGFloat = 120 + CGFloat(i) * 18
                            
                            var arc = Path()
                            arc.addArc(center: center, radius: radius * CGFloat(arcProgress),
                                       startAngle: .radians(startAngle), endAngle: .radians(endAngle), clockwise: false)
                            
                            let opacity = 0.15 + 0.25 * arcProgress - Double(i) * 0.02
                            // Smooth color transition using blend
                            let arcColor = Color(
                                red: 0.7 * (1 - colorBlend) + 0.0 * colorBlend,
                                green: 0.7 * (1 - colorBlend) + 0.6 * colorBlend,
                                blue: 0.7 * (1 - colorBlend) + 0.75 * colorBlend
                            )
                            context.stroke(arc, with: .color(arcColor.opacity(opacity)), lineWidth: 2)
                        }
                    }
                    
                    // Lower arcs (mirrored)
                    for i in 0..<arcCount {
                        let arcProgress = min(1.0, max(0, (progress - 0.2 - Double(i) * 0.03) * 2.0))
                        if arcProgress > 0 {
                            let baseAngle = Double(i) * (.pi / Double(arcCount)) + .pi / 2
                            let wobble = sin(time * 1.3 + Double(i) + 2) * 0.05
                            let startAngle = baseAngle - 0.35 + wobble
                            let endAngle = baseAngle + 0.35 + wobble
                            let radius: CGFloat = 110 + CGFloat(i) * 16
                            
                            var arc = Path()
                            arc.addArc(center: center, radius: radius * CGFloat(arcProgress),
                                       startAngle: .radians(startAngle), endAngle: .radians(endAngle), clockwise: false)
                            
                            let opacity = 0.12 + 0.2 * arcProgress - Double(i) * 0.015
                            let arcColor = Color(
                                red: 0.7 * (1 - colorBlend) + 0.0 * colorBlend,
                                green: 0.7 * (1 - colorBlend) + 0.6 * colorBlend,
                                blue: 0.7 * (1 - colorBlend) + 0.75 * colorBlend
                            )
                            context.stroke(arc, with: .color(arcColor.opacity(opacity)), lineWidth: 1.5)
                        }
                    }
                }
                
                // Central human figure silhouette
                VStack(spacing: 0) {
                    // Smooth color blend for figure
                    let figureBlend = min(1.0, max(0, (progress - 0.25) / 0.5))
                    let figureColor = Color(
                        red: 0.5 * (1 - figureBlend) + 0.0 * figureBlend,
                        green: 0.5 * (1 - figureBlend) + 0.6 * figureBlend,
                        blue: 0.5 * (1 - figureBlend) + 0.75 * figureBlend
                    )
                    
                    // Figure icon with glow
                    ZStack {
                        // Outer glow ring
                        Image(systemName: "figure.stand")
                            .font(.system(size: 120, weight: .ultraLight))
                            .foregroundColor(glowBlue.opacity(0.25 * progress))
                            .blur(radius: 30)
                            .scaleEffect(1.15)
                        
                        // Inner glow
                        Image(systemName: "figure.stand")
                            .font(.system(size: 120, weight: .ultraLight))
                            .foregroundColor(accentBlue.opacity(0.4 * progress))
                            .blur(radius: 15)
                            .scaleEffect(1.05)
                        
                        // Main figure - smooth color transition
                        Image(systemName: "figure.stand")
                            .font(.system(size: 120, weight: .ultraLight))
                            .foregroundColor(figureColor)
                            .scaleEffect(0.8 + progress * 0.2)
                    }
                    .opacity(min(1.0, progress * 2.5))
                    
                    Spacer().frame(height: 40)
                    
                    // Text content with smooth color transitions
                    let textBlend = min(1.0, max(0, (progress - 0.35) / 0.4))
                    let labelColor = Color(
                        red: 0.5 * (1 - textBlend) + 0.0 * textBlend,
                        green: 0.5 * (1 - textBlend) + 0.6 * textBlend,
                        blue: 0.5 * (1 - textBlend) + 0.75 * textBlend
                    )
                    
                    VStack(spacing: 16) {
                        Text("RESTORATION")
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(12)
                            .foregroundColor(labelColor)
                            .opacity(min(1.0, max(0, (progress - 0.2) * 3)))
                        
                        Text("Human potential returned.")
                            .font(.system(size: 32, weight: .light, design: .serif))
                            .foregroundColor(Color(white: 1.0 - progress * 0.9)) // White to dark gray
                            .opacity(min(1.0, max(0, (progress - 0.3) * 2.5)))
                            .offset(y: progress > 0.3 ? 0 : 15)
                        
                        Text("Reviewing insights. Approving paths.")
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(glowBlue)
                            .opacity(min(1.0, max(0, (progress - 0.55) * 2.5)))
                            .offset(y: progress > 0.55 ? 0 : 10)
                    }
                    .multilineTextAlignment(.center)
                }
                .padding(.bottom, 70)
            }
        }
    }
}

// MARK: - Personalization View (03:30-04:30)
struct PersonalizationView: View {
    @Bindable var viewModel: ExperienceViewModel
    
    var body: some View {
        ZStack {
            // Wow factor: Animated background gradient
            LinearGradient(colors: [.black, Color.blue.opacity(0.15), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 50) {
                Text("How many hours of invisible work does your team lose each week?")
                    .font(.system(size: 34, weight: .light, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 80)
                
                // Wow factor: Glassmorphism container
                VStack(spacing: 40) {
                    VStack(spacing: 10) {
                        Text("\(Int(viewModel.lostHoursPerWeek)) hours")
                            .font(.system(size: 90, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                            .contentTransition(.numericText()) // Smooth number changes
                        
                        Slider(value: $viewModel.lostHoursPerWeek, in: 0...100, step: 1)
                            .tint(.blue)
                            .padding(.horizontal, 50)
                    }
                    
                    HStack(spacing: 60) {
                        MetricView(label: "TEAM SIZE", value: "\(Int(viewModel.teamSize))", color: .gray)
                        MetricView(label: "ANNUAL IMPACT", value: "$\(formatLargeNumber(viewModel.annualImpact))", color: .green)
                    }
                }
                .padding(40)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 100)
                
                Text("Premium simplicity for VIP interaction.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
        }
    }
    
    private func formatLargeNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US") // Ensure international/western grouping for Davos
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
}

struct MetricView: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .tracking(4)
                .foregroundColor(.white.opacity(0.5))
            
            Text(value)
                .font(.system(size: 36, weight: .medium, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

// MARK: - Final CTA View (04:30-05:00)
struct FinalCTAView: View {
    var progress: Double
    var isComplete: Bool
    
    var body: some View {
        ZStack {
            Color.white
            
            VStack(spacing: 50) {
                Spacer()
                
                // Main message - appears after brief white pause
                VStack(spacing: 25) {
                    Text("Agentic automation returns invisible work to the people who matter.")
                        .font(.system(size: 30, weight: .light, design: .serif))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("What could your organization become with invisible work returned?")
                        .font(.system(size: 22, weight: .regular, design: .default))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(progress > 0.05 ? 1 : 0)
                .offset(y: progress > 0.05 ? 0 : 20)
                .animation(.easeOut(duration: 1.5).delay(1.0), value: progress > 0.05)
                
                Spacer()
                    .frame(height: 40)
                
                // CTA button - appears after main message
                VStack(spacing: 12) {
                    Button(action: {
                        // Action for Vision Pro demo
                    }) {
                        Text("Ask for the Vision Pro demo.")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.horizontal, 35)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 1.5)
                            )
                    }
                }
                .opacity(progress > 0.5 || isComplete ? 1 : 0)
                .offset(y: progress > 0.5 || isComplete ? 0 : 15)
                .animation(.easeOut(duration: 0.8).delay(0.3), value: progress > 0.5)
                
                Spacer()
            }
            .padding(.horizontal, 60)
        }
    }
}

// MARK: - Helpers

struct WorkWindowView: View {
    let index: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // Title Bar
            HStack(spacing: 6) {
                Circle().fill(Color.red.opacity(0.5)).frame(width: 6, height: 6)
                Circle().fill(Color.yellow.opacity(0.5)).frame(width: 6, height: 6)
                Circle().fill(Color.green.opacity(0.5)).frame(width: 6, height: 6)
                Spacer()
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 4)
                Spacer()
            }
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(Color.white.opacity(0.05))
            
            // Mock Content
            VStack(alignment: .leading, spacing: 10) {
                if index % 3 == 0 {
                    // Chart variant
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(0..<6) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 15, height: CGFloat.random(in: 20...60))
                        }
                    }
                } else if index % 3 == 1 {
                    // Text/Email variant
                    ForEach(0..<4) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)
                            .frame(maxWidth: CGFloat.random(in: 60...150))
                    }
                } else {
                    // Grid/Data variant
                    GridPatternView()
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .compositingGroup()
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

struct GridPatternView: View {
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<5) { _ in
                HStack(spacing: 4) {
                    ForEach(0..<4) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 30, height: 10)
                    }
                }
            }
        }
    }
}

struct NotificationShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 12, height: 12))
        return path
    }
}

