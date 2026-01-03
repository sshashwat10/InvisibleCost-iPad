import SwiftUI
import Foundation

// ============================================================================
// PERFORMANCE OPTIMIZATION FOR 60FPS
// ============================================================================
// All animations use:
// - TimelineView(.animation) for display-refresh-synced updates
// - Canvas for GPU-accelerated custom drawing
// - .drawingGroup() for Metal rasterization of complex view hierarchies
// - Reduced particle counts balanced for visual quality vs performance
// - Pre-calculated static data where possible
// ============================================================================

// MARK: - Custom Slider (iOS 26 Beta Fix)

/// Custom slider to fix iOS 26 beta SystemSlider rendering bug
struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let accentColor: Color
    
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let thumbX = width * normalizedValue
            
            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 8)
                
                // Filled track
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.8), accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, thumbX), height: 8)
                
                // Glow under filled track
                Capsule()
                    .fill(accentColor)
                    .frame(width: max(8, thumbX), height: 8)
                    .blur(radius: 8)
                    .opacity(0.5)
                
                // Thumb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, accentColor.opacity(0.8)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 14
                        )
                    )
                    .frame(width: 28, height: 28)
                    .shadow(color: accentColor.opacity(0.6), radius: isDragging ? 15 : 8)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .scaleEffect(isDragging ? 1.15 : 1.0)
                    .offset(x: thumbX - 14)
                    .animation(.spring(response: 0.3), value: isDragging)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * Double(gesture.location.x / width)
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        isDragging = false
                        // Snap to nearest integer
                        value = round(value)
                    }
            )
        }
        .frame(height: 40)
    }
}

// MARK: - Shared Wow Effects

/// Animated shimmer overlay for text
struct ShimmerEffect: ViewModifier {
    let animation: Animation
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.4), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .scaleEffect(x: 2)
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(animation.repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

/// Glowing text with animated pulse
struct GlowingText: View {
    let text: String
    let font: Font
    let color: Color
    let glowColor: Color
    let glowRadius: CGFloat
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let pulse = 1.0 + sin(time * 2) * 0.15
            
            ZStack {
                // Outer glow
                Text(text)
                    .font(font)
                    .foregroundColor(glowColor)
                    .blur(radius: glowRadius * CGFloat(pulse))
                
                // Inner glow
                Text(text)
                    .font(font)
                    .foregroundColor(glowColor.opacity(0.6))
                    .blur(radius: glowRadius * 0.5)
                
                // Main text
                Text(text)
                    .font(font)
                    .foregroundColor(color)
            }
        }
    }
}

/// Animated counter that counts up
struct AnimatedCounter: View {
    let target: Int
    let duration: Double
    let font: Font
    let color: Color
    
    @State private var displayValue: Int = 0
    @State private var hasStarted = false
    
    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText())
            .onAppear {
                if !hasStarted {
                    hasStarted = true
                    animateCount()
                }
            }
    }
    
    private func animateCount() {
        let steps = 30
        let stepDuration = duration / Double(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.easeOut(duration: 0.1)) {
                    displayValue = Int(Double(target) * Double(i) / Double(steps))
                }
            }
        }
    }
}

/// Floating particles background
struct FloatingParticles: View {
    let count: Int
    let color: Color
    let speed: Double
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                for i in 0..<count {
                    let seed = Double(i) * 1.618
                    let x = (sin(time * speed * 0.3 + seed * 2) * 0.5 + 0.5) * size.width
                    let y = (cos(time * speed * 0.2 + seed * 1.5) * 0.5 + 0.5) * size.height
                    let pulse = sin(time * 2 + seed) * 0.5 + 0.5
                    let particleSize: CGFloat = 2 + CGFloat(pulse) * 3
                    
                    context.fill(
                        Circle().path(in: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                        with: .color(color.opacity(0.1 + pulse * 0.15))
                    )
                }
            }
        }
    }
}

// MARK: - Narrator Frame Animation (00:07-00:37)
struct NarratorFrameAnimation: View {
    var progress: Double
    @Environment(MotionManager.self) private var motion
    @State private var windowStates: [(id: Int, pos: CGPoint, size: CGSize)] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            GeometryReader { geo in
                ZStack {
                    // Deep gradient background
                    LinearGradient(
                        colors: [
                            Color(red: 0.02, green: 0.02, blue: 0.06),
                            Color(red: 0.05, green: 0.03, blue: 0.1),
                            Color.black
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Animated particle field (digital noise)
                    Canvas { context, size in
                        for i in 0..<35 {
                            let x = (sin(time * 0.15 + Double(i) * 0.7) * 0.5 + 0.5) * size.width
                            let y = (cos(time * 0.1 + Double(i) * 0.5) * 0.5 + 0.5) * size.height
                            let pulse = sin(time * 2 + Double(i)) * 0.5 + 0.5
                            let particleSize: CGFloat = 2 + CGFloat(pulse) * 2
                            
                            context.fill(
                                Circle().path(in: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                                with: .color(Color.white.opacity(0.08 + pulse * 0.07))
                            )
                        }
                        
                        // Subtle scan lines
                        for line in stride(from: 0, to: size.height, by: 4) {
                            let lineOpacity = 0.02 + sin(time * 0.5 + line * 0.01) * 0.01
                            context.stroke(
                                Path { p in
                                    p.move(to: CGPoint(x: 0, y: line))
                                    p.addLine(to: CGPoint(x: size.width, y: line))
                                },
                                with: .color(Color.white.opacity(lineOpacity)),
                                lineWidth: 0.5
                            )
                        }
                    }
                    
                    // Redundant windows distributed across the ENTIRE screen
                    ZStack {
                        ForEach(windowStates, id: \.id) { state in
                            WorkWindowView(index: state.id)
                                .frame(width: state.size.width, height: state.size.height)
                                .position(
                                    x: state.pos.x + CGFloat(motion.roll * Double(state.id % 10 + 5)) + CGFloat(sin(time * 0.3 + Double(state.id))) * 5,
                                    y: state.pos.y + CGFloat(motion.pitch * Double(state.id % 10 + 5)) + CGFloat(cos(time * 0.2 + Double(state.id))) * 5
                                )
                                .scaleEffect(0.6 + progress * 0.4)
                                .opacity(0.5 + (1.0 - progress) * 0.5)
                                .rotation3DEffect(.degrees(sin(time * 0.5 + Double(state.id) * 0.3) * 2), axis: (x: 1, y: 0, z: 0))
                        }
                    }
                    .drawingGroup()
                    .onAppear {
                        if windowStates.isEmpty {
                            windowStates = (0..<25).map { i in // Optimized for 60fps
                                (id: i,
                                 pos: CGPoint(
                                    x: CGFloat.random(in: 0...geo.size.width),
                                    y: CGFloat.random(in: 0...geo.size.height)
                                 ),
                                 size: CGSize(
                                    width: CGFloat.random(in: 200...400),
                                    height: CGFloat.random(in: 150...300)
                                 ))
                            }
                        }
                    }
                    
                    // Vignette overlay
                    RadialGradient(
                        colors: [.clear, Color.black.opacity(0.7)],
                        center: .center,
                        startRadius: geo.size.width * 0.3,
                        endRadius: geo.size.width * 0.8
                    )
                    
                    // Narrator Text with MAXIMUM wow factor
                    VStack(spacing: 40) {
                        // First line with typewriter shimmer effect
                        ZStack {
                            Text("Every organization carries a hidden cost.")
                                .font(.system(size: 38, weight: .light, design: .serif))
                                .foregroundColor(.white.opacity(0.15))
                                .blur(radius: 20)
                            
                            Text("Every organization carries a hidden cost.")
                                .font(.system(size: 38, weight: .light, design: .serif))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.8), .white],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .white.opacity(0.4), radius: 15)
                        }
                        .opacity(progress > 0.1 ? 1 : 0)
                        .offset(y: progress > 0.1 ? 0 : 40)
                        .scaleEffect(progress > 0.1 ? 1.0 : 0.9)
                        .blur(radius: progress > 0.1 ? 0 : 8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress > 0.1)
                        
                        // Second line with dramatic red undertone
                        ZStack {
                            Text("Most leaders never see it.")
                                .font(.system(size: 38, weight: .bold, design: .serif))
                                .foregroundColor(Color.red.opacity(0.3))
                                .blur(radius: 25)
                            
                            Text("Most leaders never see it.")
                                .font(.system(size: 38, weight: .bold, design: .serif))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 1, green: 0.9, blue: 0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color.red.opacity(0.4), radius: 20)
                        }
                        .opacity(progress > 0.4 ? 1 : 0)
                        .offset(y: progress > 0.4 ? 0 : 40)
                        .scaleEffect(progress > 0.4 ? 1.0 : 0.9)
                        .blur(radius: progress > 0.4 ? 0 : 8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress > 0.4)
                        
                        if progress > 0.7 {
                            // REDESIGNED: Clean stat display - centered below text
                            VStack(spacing: 25) {
                                // Single line stat display
                                HStack(spacing: 8) {
                                    Text("You made")
                                        .font(.system(size: 22, weight: .light))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("247")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("decisions today.")
                                        .font(.system(size: 22, weight: .light))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                // Dramatic red stat
                                HStack(spacing: 8) {
                                    Text("142")
                                        .font(.system(size: 48, weight: .black, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color(red: 1.0, green: 0.4, blue: 0.4), Color(red: 1.0, green: 0.2, blue: 0.2)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(color: Color.red.opacity(0.5), radius: 15)
                                    
                                    Text("were unnecessary")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.5))
                                }
                                
                                // Animated progress bar showing waste
                                VStack(spacing: 10) {
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white.opacity(0.15))
                                            .frame(width: 320, height: 10)
                                        
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(red: 1.0, green: 0.4, blue: 0.3), Color(red: 1.0, green: 0.2, blue: 0.2)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: 320 * 0.575, height: 10)
                                            .shadow(color: Color.red.opacity(0.5), radius: 8)
                                    }
                                    
                                    Text("57% of your decisions could be automated")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                        .tracking(1)
                                }
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.92)).combined(with: .offset(y: 20)))
                        }
                    }
                    .animation(.easeOut(duration: 1.0), value: progress)
                    
                    // Accelerating Timestamps with subtle glow
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(TimestampGenerator.getTime(for: progress))
                                .font(.system(size: 100, weight: .ultraLight, design: .monospaced))
                                .foregroundColor(.white.opacity(0.08))
                                .shadow(color: .white.opacity(0.05), radius: 30)
                                .padding(35)
                        }
                    }
                }
            }
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
                
                // ENHANCED floating particles + geometric patterns
                Canvas { context, size in
                    let particleColor = theme.primary
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    
                    // Outer rotating ring
                    for i in 0..<36 {
                        let angle = Double(i) * (.pi / 18) + time * 0.1
                        let radius: CGFloat = min(size.width, size.height) * 0.42
                        let x = center.x + CGFloat(cos(angle)) * radius
                        let y = center.y + CGFloat(sin(angle)) * radius
                        let pulse = sin(time * 2 + Double(i) * 0.2) * 0.5 + 0.5
                        
                        context.fill(
                            Circle().path(in: CGRect(x: x - 2, y: y - 2, width: 4, height: 4)),
                            with: .color(theme.accent.opacity(0.2 + pulse * 0.15))
                        )
                    }
                    
                    // Inner orbiting particles
                    for i in 0..<40 {
                        let angle = time * 0.25 + Double(i) * 0.4
                        let radius = 120.0 + Double(i) * 10 + sin(time + Double(i)) * 20
                        let x = center.x + CGFloat(cos(angle) * radius)
                        let y = center.y + CGFloat(sin(angle * 0.7) * radius * 0.6)
                        let pulse = sin(time * 1.8 + Double(i)) * 0.5 + 0.5
                        let particleSize: CGFloat = 2 + CGFloat(pulse) * 4
                        
                        // Glow behind particle
                        context.fill(
                            Circle().path(in: CGRect(x: x - particleSize * 1.5, y: y - particleSize * 1.5, 
                                                     width: particleSize * 3, height: particleSize * 3)),
                            with: .color(particleColor.opacity(0.05 * pulse))
                        )
                        
                        context.fill(
                            Circle().path(in: CGRect(x: x - particleSize/2, y: y - particleSize/2, 
                                                     width: particleSize, height: particleSize)),
                            with: .color(particleColor.opacity(0.2 + pulse * 0.2))
                        )
                    }
                    
                    // Connecting lines between nearby particles
                    for i in 0..<20 {
                        let angle1 = time * 0.15 + Double(i) * 0.6
                        let angle2 = time * 0.15 + Double(i + 1) * 0.6
                        let radius = 180.0 + Double(i) * 8
                        
                        let x1 = center.x + CGFloat(cos(angle1) * radius)
                        let y1 = center.y + CGFloat(sin(angle1 * 0.7) * radius * 0.6)
                        let x2 = center.x + CGFloat(cos(angle2) * radius)
                        let y2 = center.y + CGFloat(sin(angle2 * 0.7) * radius * 0.6)
                        
                        var line = Path()
                        line.move(to: CGPoint(x: x1, y: y1))
                        line.addLine(to: CGPoint(x: x2, y: y2))
                        
                        context.stroke(line, with: .color(theme.primary.opacity(0.08)), lineWidth: 1)
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
            .drawingGroup() // Metal-accelerated rendering for 60fps
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
        VStack(spacing: 32) {
            // ULTRA-ENHANCED Icon with layered glow effects
            ZStack {
                // Outermost breathing glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.primary.opacity(0.5), theme.primary.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .scaleEffect(1.0 + sin(time * 1.5) * 0.12)
                    .blur(radius: 10)
                
                // Rotating outer ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [theme.accent, theme.primary.opacity(0.3), theme.accent],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(time * 20))
                
                // Pulsing middle ring
                Circle()
                    .stroke(theme.accent.opacity(0.6), lineWidth: 3)
                    .frame(width: 150, height: 150)
                    .scaleEffect(1.0 + sin(time * 2) * 0.08)
                
                // Inner glow ring
                Circle()
                    .stroke(theme.primary.opacity(0.4), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(1.0 + sin(time * 1.8 + 1) * 0.06)
                
                // Icon background glow
                Circle()
                    .fill(theme.glow.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .blur(radius: 15)
                
                // Main Icon with dramatic entrance
                Image(systemName: icon)
                    .font(.system(size: 55, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accent, theme.primary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: theme.accent.opacity(0.8), radius: 15)
                    .shadow(color: theme.primary.opacity(0.5), radius: 25)
                    .scaleEffect(localProgress > 0.1 ? 1.0 : 0.4)
                    .rotationEffect(.degrees(localProgress > 0.1 ? 0 : -20))
                    .opacity(localProgress > 0.05 ? 1.0 : 0.0)
                
                // Animated warning badge with pulse
                ZStack {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 28, height: 28)
                        .shadow(color: theme.accent, radius: 10)
                    
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.black)
                }
                .offset(x: 55, y: -55)
                .scaleEffect(1.0 + sin(time * 4) * 0.2)
                .opacity(localProgress > 0.15 ? 1.0 : 0.0)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: localProgress)
            
            // GLOWING Title with department color
            ZStack {
                Text(title)
                    .font(.system(size: 18, weight: .black))
                    .tracking(16)
                    .foregroundColor(theme.accent.opacity(0.3))
                    .blur(radius: 10)
                
                Text(title)
                    .font(.system(size: 18, weight: .black))
                    .tracking(16)
                    .foregroundColor(theme.accent)
                    .shadow(color: theme.primary.opacity(0.5), radius: 12)
            }
            .offset(y: localProgress > 0.2 ? 0 : 20)
            .opacity(localProgress > 0.15 ? 1.0 : 0.0)
            .scaleEffect(localProgress > 0.2 ? 1.0 : 0.9)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: localProgress)
            
            // DRAMATIC Subtitle with glow
            ZStack {
                Text(subtitle)
                    .font(.system(size: 32, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(.white.opacity(0.2))
                    .blur(radius: 15)
                
                Text(subtitle)
                    .font(.system(size: 32, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.3), radius: 10)
            }
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
    @State private var workItems: [(id: Int, x: CGFloat, y: CGFloat, opacity: Double, rotation: Double)] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            GeometryReader { geo in
                ZStack {
                    // Gradient white background with subtle warmth
                    LinearGradient(
                        colors: [
                            Color(white: 0.98),
                            Color(white: 1.0),
                            Color(white: 0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Subtle animated light rays
                    Canvas { context, size in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        let rayCount = 12
                        
                        for i in 0..<rayCount {
                            let angle = Double(i) * (2 * .pi / Double(rayCount)) + time * 0.05
                            let rayLength = size.width * 0.8
                            let rayWidth: CGFloat = 80
                            
                            let endX = center.x + CGFloat(cos(angle)) * rayLength
                            let endY = center.y + CGFloat(sin(angle)) * rayLength
                            
                            var ray = Path()
                            ray.move(to: center)
                            ray.addLine(to: CGPoint(x: endX, y: endY))
                            
                            let rayOpacity = 0.02 + sin(time * 0.3 + Double(i)) * 0.01
                            context.stroke(ray, with: .color(Color.gray.opacity(rayOpacity)), lineWidth: rayWidth)
                        }
                    }
                    .blur(radius: 40)
                    
                    // Fading work windows with 3D perspective
                    ForEach(workItems, id: \.id) { item in
                        MiniWorkWindow()
                            .frame(width: 140, height: 95)
                            .position(x: item.x, y: item.y)
                            .opacity(item.opacity * (1.0 - progress * 1.3))
                            .rotation3DEffect(
                                .degrees(item.rotation + progress * 20),
                                axis: (x: 0.5, y: 1, z: 0),
                                perspective: 0.5
                            )
                            .scaleEffect(1.0 - progress * 0.15)
                    }
                
                    // Main question with visual context
                    VStack(spacing: 40) {
                        // Visual representation of "this work" - animated cards
                        if progress > 0.1 {
                            HStack(spacing: 18) {
                                ForEach(0..<5, id: \.self) { i in
                                    VStack(spacing: 5) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.18))
                                            .frame(width: 55, height: 38)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.gray.opacity(0.12), lineWidth: 1)
                                            )
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.gray.opacity(0.12))
                                            .frame(width: 42, height: 4)
                                    }
                                    .opacity(1.0 - progress * 0.9)
                                    .offset(y: CGFloat(sin(time + Double(i) * 0.5)) * 3)
                                    .rotation3DEffect(.degrees(Double(i - 2) * 3), axis: (x: 0, y: 1, z: 0))
                                }
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                        
                        // Main question text with dramatic reveal
                        VStack(spacing: 15) {
                            Text("What if this work...")
                                .font(.system(size: 44, weight: .light, design: .serif))
                                .foregroundColor(.black)
                                .opacity(progress > 0.15 ? 1 : 0)
                                .offset(y: progress > 0.15 ? 0 : 25)
                                .blur(radius: progress > 0.15 ? 0 : 8)
                            
                            Text("wasn't your work?")
                                .font(.system(size: 44, weight: .semibold, design: .serif))
                                .foregroundColor(.black)
                                .shadow(color: .black.opacity(0.1), radius: 10)
                                .opacity(progress > 0.35 ? 1 : 0)
                                .offset(y: progress > 0.35 ? 0 : 25)
                                .blur(radius: progress > 0.35 ? 0 : 8)
                                .scaleEffect(progress > 0.35 ? 1.0 : 0.95)
                        }
                    }
                    .animation(.easeOut(duration: 1.2), value: progress)
                }
                .drawingGroup() // Metal-accelerated rendering for 60fps
                .onAppear {
                    if workItems.isEmpty {
                        workItems = (0..<15).map { i in
                            (id: i,
                             x: CGFloat.random(in: 60...(geo.size.width - 60)),
                             y: CGFloat.random(in: 60...(geo.size.height - 60)),
                             opacity: Double.random(in: 0.5...0.85),
                             rotation: Double.random(in: -8...8))
                        }
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
/// THE AWAKENING: AI agents come to life, organize chaos, sync as one
/// This is the centerpiece of the Davos experience
struct AgenticOrchestrationAnimation: View {
    var progress: Double
    @Environment(MotionManager.self) private var motion
    
    // Color palette - electric and alive
    private let coreGold = Color(red: 1.0, green: 0.85, blue: 0.4)
    private let electricBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    private let plasmaGreen = Color(red: 0.3, green: 0.95, blue: 0.7)
    private let deepPurple = Color(red: 0.4, green: 0.2, blue: 0.8)
    private let hotWhite = Color.white
    
    // Agent definitions - each has unique character, shape, and personality
    enum AgentShape { case hexagon, diamond, triangle, star, octagon, shield, circle }
    enum AgentRole { case orchestrator, analyst, executor, connector, innovator, optimizer, harmonizer }
    
    private struct Agent {
        let id: Int
        let role: AgentRole
        let shape: AgentShape
        let baseAngle: Double
        let orbitRadius: Double
        let speed: Double
        let primaryColor: Color
        let accentColor: Color
        let size: CGFloat
        let pulseOffset: Double
        let hasRings: Bool         // Orbital rings around agent
        let hasAntenna: Bool       // Top antenna/beacon
        let eyeCount: Int          // 1, 2, or 3 "eyes"
    }
    
    // Create 7 distinct agents with unique visual personalities
    private let agents: [Agent] = [
        // ORCHESTRATOR - Central brain, golden, hexagonal with 3 eyes, has antenna
        Agent(id: 0, role: .orchestrator, shape: .hexagon, baseAngle: 0, orbitRadius: 0.18, speed: 0.5,
              primaryColor: Color(red: 1.0, green: 0.85, blue: 0.3), accentColor: Color(red: 1.0, green: 0.95, blue: 0.6),
              size: 28, pulseOffset: 0, hasRings: true, hasAntenna: true, eyeCount: 3),
        
        // ANALYST - Blue diamond, analytical, 2 scanning eyes
        Agent(id: 1, role: .analyst, shape: .diamond, baseAngle: 0.9, orbitRadius: 0.30, speed: 0.4,
              primaryColor: Color(red: 0.2, green: 0.5, blue: 1.0), accentColor: Color(red: 0.5, green: 0.8, blue: 1.0),
              size: 22, pulseOffset: 0.3, hasRings: false, hasAntenna: true, eyeCount: 2),
        
        // EXECUTOR - Green triangle pointing forward, action-oriented, 1 focused eye
        Agent(id: 2, role: .executor, shape: .triangle, baseAngle: 1.8, orbitRadius: 0.34, speed: 0.7,
              primaryColor: Color(red: 0.2, green: 0.9, blue: 0.5), accentColor: Color(red: 0.5, green: 1.0, blue: 0.7),
              size: 24, pulseOffset: 0.5, hasRings: false, hasAntenna: false, eyeCount: 1),
        
        // CONNECTOR - Coral star shape, reaches out, multiple connection points
        Agent(id: 3, role: .connector, shape: .star, baseAngle: 2.6, orbitRadius: 0.36, speed: 0.45,
              primaryColor: Color(red: 1.0, green: 0.5, blue: 0.3), accentColor: Color(red: 1.0, green: 0.7, blue: 0.5),
              size: 26, pulseOffset: 0.2, hasRings: true, hasAntenna: false, eyeCount: 2),
        
        // INNOVATOR - Purple octagon, complex, has orbital rings
        Agent(id: 4, role: .innovator, shape: .octagon, baseAngle: 3.5, orbitRadius: 0.28, speed: 0.55,
              primaryColor: Color(red: 0.7, green: 0.3, blue: 0.95), accentColor: Color(red: 0.9, green: 0.6, blue: 1.0),
              size: 20, pulseOffset: 0.7, hasRings: true, hasAntenna: true, eyeCount: 3),
        
        // OPTIMIZER - Cyan shield, protective, efficient, 2 eyes
        Agent(id: 5, role: .optimizer, shape: .shield, baseAngle: 4.4, orbitRadius: 0.32, speed: 0.6,
              primaryColor: Color(red: 0.2, green: 0.85, blue: 0.95), accentColor: Color(red: 0.6, green: 0.95, blue: 1.0),
              size: 22, pulseOffset: 0.4, hasRings: false, hasAntenna: false, eyeCount: 2),
        
        // HARMONIZER - Rose circle, smooth, balancing, single calm eye
        Agent(id: 6, role: .harmonizer, shape: .circle, baseAngle: 5.3, orbitRadius: 0.26, speed: 0.35,
              primaryColor: Color(red: 1.0, green: 0.6, blue: 0.75), accentColor: Color(red: 1.0, green: 0.85, blue: 0.9),
              size: 20, pulseOffset: 0.6, hasRings: true, hasAntenna: false, eyeCount: 1)
    ]
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            // ═══════════════════════════════════════════════════════════════
            // THE AWAKENING - Animation Phases
            // ═══════════════════════════════════════════════════════════════
            let darknessPhase = max(0, 1.0 - progress * 10)                    // 0-10%: darkness fades
            let heartbeatPhase = min(1.0, max(0, progress * 5))                // 0-20%: initial pulse
            let awakenPhase = min(1.0, max(0, (progress - 0.08) / 0.25))       // 8-33%: agents wake up
            let chaosPhase = min(1.0, max(0, (progress - 0.05) / 0.30))        // 5-35%: chaos visible
            let organizePhase = min(1.0, max(0, (progress - 0.25) / 0.30))     // 25-55%: agents organize
            let connectPhase = min(1.0, max(0, (progress - 0.35) / 0.25))      // 35-60%: connections form
            let syncPhase = min(1.0, max(0, (progress - 0.55) / 0.15))         // 55-70%: all sync together
            let textPhase = min(1.0, max(0, (progress - 0.62) / 0.20))         // 62-82%: text appears
            let gloryPhase = min(1.0, max(0, (progress - 0.75) / 0.25))        // 75-100%: final glory
            
            // Heartbeat pulse effect
            let heartbeat = sin(time * 3.5) * 0.5 + 0.5
            let syncPulse = syncPhase > 0.5 ? sin(time * 6) * 0.5 + 0.5 : 0
            
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2 - 40)
                let baseRadius = min(geo.size.width, geo.size.height) * 0.35
                
                ZStack {
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 1: Deep space background
                    // ═══════════════════════════════════════════════════════════════
                    Color.black.ignoresSafeArea()
                    
                    // Subtle nebula effect
                    Canvas { context, size in
                        // Deep space gradient
                        context.fill(
                            Path(CGRect(origin: .zero, size: size)),
                            with: .radialGradient(
                                Gradient(colors: [
                                    Color(red: 0.05, green: 0.02, blue: 0.1).opacity(0.8),
                                    Color.black
                                ]),
                                center: center,
                                startRadius: 0,
                                endRadius: max(size.width, size.height) * 0.8
                            )
                        )
                    }
                    .opacity(1 - darknessPhase)
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 2: Chaos particles (the invisible cost - disorganized work)
                    // ═══════════════════════════════════════════════════════════════
                    Canvas { context, size in
                        let chaosCount = 60
                        for i in 0..<chaosCount {
                            let seed = Double(i) * 2.718
                            
                            // Initial chaotic positions
                            var x = sin(seed * 3.7 + time * 0.3) * size.width * 0.45 + size.width / 2
                            var y = cos(seed * 2.3 + time * 0.25) * size.height * 0.4 + size.height / 2
                            
                            // As organize phase progresses, particles get pulled to agents
                            if organizePhase > 0 {
                                let targetAgent = i % agents.count
                                let agentAngle = agents[targetAgent].baseAngle + time * agents[targetAgent].speed * 0.3
                                let agentRadius = baseRadius * CGFloat(agents[targetAgent].orbitRadius) * 2.5
                                let targetX = center.x + cos(agentAngle) * agentRadius
                                let targetY = center.y + sin(agentAngle) * agentRadius * 0.6
                                
                                // Smooth pull toward agent
                                let pullStrength = organizePhase * organizePhase // Ease-in
                                x = x + (targetX - CGFloat(x)) * pullStrength
                                y = y + (targetY - CGFloat(y)) * pullStrength
                            }
                            
                            // Particles fade as they're organized
                            let particleOpacity = chaosPhase * (1 - organizePhase * 0.8)
                            let particleSize: CGFloat = 2 + CGFloat(sin(time + seed) * 0.5 + 0.5) * 2
                            
                            // Chaos particles are dim red/orange (stress colors)
                            let chaosColor = Color(
                                red: 0.8 + sin(seed) * 0.2,
                                green: 0.3 + cos(seed) * 0.1,
                                blue: 0.2
                            )
                            
                            context.fill(
                                Circle().path(in: CGRect(x: x - particleSize, y: y - particleSize, 
                                                         width: particleSize * 2, height: particleSize * 2)),
                                with: .color(chaosColor.opacity(particleOpacity * 0.4))
                            )
                        }
                    }
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 3: Central core pulse (the heartbeat of intelligence)
                    // ═══════════════════════════════════════════════════════════════
                    Canvas { context, size in
                        let pulseIntensity = heartbeatPhase * (0.3 + heartbeat * 0.7)
                        let syncBoost = 1 + syncPhase * 0.5
                        
                        // Outer glow rings
                        for ring in 0..<4 {
                            let ringDelay = Double(ring) * 0.15
                            let ringPulse = sin(time * 2.5 - ringDelay * 3) * 0.3 + 0.7
                            let ringRadius = baseRadius * CGFloat(0.15 + Double(ring) * 0.08) * CGFloat(syncBoost) * CGFloat(ringPulse)
                            
                            context.fill(
                                Circle().path(in: CGRect(x: center.x - ringRadius, y: center.y - ringRadius,
                                                         width: ringRadius * 2, height: ringRadius * 2)),
                                with: .radialGradient(
                                    Gradient(colors: [
                                        coreGold.opacity(pulseIntensity * 0.4 / Double(ring + 1)),
                                        electricBlue.opacity(pulseIntensity * 0.2 / Double(ring + 1)),
                                        .clear
                                    ]),
                                    center: center,
                                    startRadius: 0,
                                    endRadius: ringRadius
                                )
                            )
                        }
                        
                        // Core bright center
                        let coreSize = baseRadius * 0.08 * CGFloat(1 + heartbeat * 0.3) * CGFloat(syncBoost)
                        context.fill(
                            Circle().path(in: CGRect(x: center.x - coreSize, y: center.y - coreSize,
                                                     width: coreSize * 2, height: coreSize * 2)),
                            with: .radialGradient(
                                Gradient(colors: [hotWhite, coreGold, .clear]),
                                center: center,
                                startRadius: 0,
                                endRadius: coreSize
                            )
                        )
                    }
                    .opacity(heartbeatPhase)
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 4: The Agents - awakening one by one with PURPOSE
                    // Each agent has unique shape, eyes, rings, and antenna
                    // ═══════════════════════════════════════════════════════════════
                    Canvas { context, size in
                        for (index, agent) in agents.enumerated() {
                            // Each agent awakens sequentially
                            let awakeDelay = Double(index) * 0.10
                            let agentAwake = min(1.0, max(0, (awakenPhase - awakeDelay) * 2.0))
                            
                            if agentAwake > 0 {
                                // Agent position - purposeful orbital movement
                                let orbitSpeed = agent.speed * (1 + syncPhase * 0.5)
                                let angle = agent.baseAngle + time * orbitSpeed * 0.4
                                let orbitRadius = baseRadius * CGFloat(agent.orbitRadius) * 2.5 * CGFloat(1 - syncPhase * 0.3)
                                
                                // Slight vertical compression for 3D feel
                                let agentX = center.x + cos(angle) * orbitRadius
                                let agentY = center.y + sin(angle) * orbitRadius * 0.55
                                let agentCenter = CGPoint(x: agentX, y: agentY)
                                
                                // Agent size with pulse
                                let agentPulse = sin(time * 2.5 + agent.pulseOffset * 6) * 0.12 + 0.88
                                let syncPulseBoost = syncPhase > 0 ? (1 + syncPulse * 0.25) : 1.0
                                let finalSize = agent.size * CGFloat(agentAwake) * CGFloat(agentPulse) * CGFloat(syncPulseBoost)
                                
                                // ══════════════════════════════════════════════════
                                // ORBITAL RINGS (if agent has them)
                                // ══════════════════════════════════════════════════
                                if agent.hasRings && agentAwake > 0.5 {
                                    for ringIndex in 0..<2 {
                                        let ringRadius = finalSize * CGFloat(1.4 + Double(ringIndex) * 0.3)
                                        let ringRotation = time * (1.5 - Double(ringIndex) * 0.5) + Double(agent.id)
                                        
                                        // Tilted ellipse ring
                                        var ringPath = Path()
                                        ringPath.addEllipse(in: CGRect(x: agentX - ringRadius, y: agentY - ringRadius * 0.3,
                                                                       width: ringRadius * 2, height: ringRadius * 0.6))
                                        
                                        context.stroke(
                                            ringPath.applying(CGAffineTransform(rotationAngle: CGFloat(ringRotation * 0.3))),
                                            with: .color(agent.accentColor.opacity(0.5 * agentAwake)),
                                            lineWidth: 1.5
                                        )
                                    }
                                }
                                
                                // ══════════════════════════════════════════════════
                                // OUTER GLOW
                                // ══════════════════════════════════════════════════
                                let glowSize = finalSize * 2.5
                                context.fill(
                                    Circle().path(in: CGRect(x: agentX - glowSize, y: agentY - glowSize,
                                                             width: glowSize * 2, height: glowSize * 2)),
                                    with: .radialGradient(
                                        Gradient(colors: [
                                            agent.primaryColor.opacity(0.5 * agentAwake),
                                            agent.primaryColor.opacity(0.15 * agentAwake),
                                            .clear
                                        ]),
                                        center: agentCenter,
                                        startRadius: 0,
                                        endRadius: glowSize
                                    )
                                )
                                
                                // ══════════════════════════════════════════════════
                                // AGENT BODY SHAPE
                                // ══════════════════════════════════════════════════
                                let bodyPath = createAgentShape(agent.shape, center: agentCenter, size: finalSize)
                                
                                // Body fill with gradient
                                context.fill(
                                    bodyPath,
                                    with: .radialGradient(
                                        Gradient(colors: [agent.accentColor, agent.primaryColor, agent.primaryColor.opacity(0.7)]),
                                        center: CGPoint(x: agentX, y: agentY - finalSize * 0.2),
                                        startRadius: 0,
                                        endRadius: finalSize
                                    )
                                )
                                
                                // Body outline
                                context.stroke(
                                    bodyPath,
                                    with: .color(agent.accentColor.opacity(0.8)),
                                    lineWidth: 2
                                )
                                
                                // ══════════════════════════════════════════════════
                                // EYES (scanning/processing indicators)
                                // ══════════════════════════════════════════════════
                                let eyeSize = finalSize * 0.18
                                let eyeY = agentY - finalSize * 0.05
                                let eyePulse = sin(time * 4 + agent.pulseOffset * 5) * 0.3 + 0.7
                                
                                if agent.eyeCount == 1 {
                                    // Single centered eye
                                    drawAgentEye(context: context, x: agentX, y: eyeY, size: eyeSize * 1.3, 
                                                 color: agent.accentColor, pulse: eyePulse, time: time)
                                } else if agent.eyeCount == 2 {
                                    // Two eyes
                                    let eyeSpacing = finalSize * 0.25
                                    drawAgentEye(context: context, x: agentX - eyeSpacing, y: eyeY, size: eyeSize, 
                                                 color: agent.accentColor, pulse: eyePulse, time: time)
                                    drawAgentEye(context: context, x: agentX + eyeSpacing, y: eyeY, size: eyeSize, 
                                                 color: agent.accentColor, pulse: eyePulse, time: time)
                                } else if agent.eyeCount == 3 {
                                    // Three eyes (triangle formation)
                                    let eyeSpacing = finalSize * 0.22
                                    drawAgentEye(context: context, x: agentX, y: eyeY - eyeSize * 0.8, size: eyeSize, 
                                                 color: agent.accentColor, pulse: eyePulse, time: time)
                                    drawAgentEye(context: context, x: agentX - eyeSpacing, y: eyeY + eyeSize * 0.4, size: eyeSize * 0.85, 
                                                 color: agent.accentColor, pulse: eyePulse, time: time + 0.3)
                                    drawAgentEye(context: context, x: agentX + eyeSpacing, y: eyeY + eyeSize * 0.4, size: eyeSize * 0.85, 
                                                 color: agent.accentColor, pulse: eyePulse, time: time + 0.6)
                                }
                                
                                // ══════════════════════════════════════════════════
                                // ANTENNA (beacon/receiver)
                                // ══════════════════════════════════════════════════
                                if agent.hasAntenna && agentAwake > 0.6 {
                                    let antennaHeight = finalSize * 0.6
                                    let antennaBaseY = agentY - finalSize * 0.5
                                    let antennaTipY = antennaBaseY - antennaHeight
                                    
                                    // Antenna line
                                    var antennaPath = Path()
                                    antennaPath.move(to: CGPoint(x: agentX, y: antennaBaseY))
                                    antennaPath.addLine(to: CGPoint(x: agentX, y: antennaTipY))
                                    context.stroke(antennaPath, with: .color(agent.accentColor.opacity(0.8)), lineWidth: 2)
                                    
                                    // Antenna tip beacon (pulsing)
                                    let beaconSize = eyeSize * 0.8 * CGFloat(0.8 + sin(time * 5) * 0.2)
                                    context.fill(
                                        Circle().path(in: CGRect(x: agentX - beaconSize, y: antennaTipY - beaconSize,
                                                                 width: beaconSize * 2, height: beaconSize * 2)),
                                        with: .radialGradient(
                                            Gradient(colors: [hotWhite, agent.primaryColor, .clear]),
                                            center: CGPoint(x: agentX, y: antennaTipY),
                                            startRadius: 0,
                                            endRadius: beaconSize * 1.5
                                        )
                                    )
                                    
                                    // Signal waves from antenna
                                    if syncPhase > 0.3 {
                                        for wave in 0..<3 {
                                            let waveProgress = fmod(time * 1.5 + Double(wave) * 0.33, 1.0)
                                            let waveRadius = CGFloat(waveProgress) * finalSize * 0.6
                                            let waveOpacity = (1 - waveProgress) * 0.4 * syncPhase
                                            
                                            var wavePath = Path()
                                            wavePath.addArc(center: CGPoint(x: agentX, y: antennaTipY),
                                                           radius: waveRadius,
                                                           startAngle: .degrees(-60),
                                                           endAngle: .degrees(-120),
                                                           clockwise: true)
                                            context.stroke(wavePath, with: .color(agent.accentColor.opacity(waveOpacity)), lineWidth: 1.5)
                                        }
                                    }
                                }
                                
                                // ══════════════════════════════════════════════════
                                // MOTION TRAIL
                                // ══════════════════════════════════════════════════
                                if agentAwake > 0.5 {
                                    for trail in 1..<5 {
                                        let trailAngle = angle - Double(trail) * 0.06 * orbitSpeed
                                        let trailX = center.x + cos(trailAngle) * orbitRadius
                                        let trailY = center.y + sin(trailAngle) * orbitRadius * 0.55
                                        let trailSize = finalSize * CGFloat(0.6 - Double(trail) * 0.12)
                                        let trailOpacity = (1 - Double(trail) / 5) * 0.35
                                        
                                        context.fill(
                                            Circle().path(in: CGRect(x: trailX - trailSize / 2, y: trailY - trailSize / 2,
                                                                     width: trailSize, height: trailSize)),
                                            with: .color(agent.primaryColor.opacity(trailOpacity * agentAwake))
                                        )
                                    }
                                }
                            }
                        }
                    }
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 5: Connection arcs between agents (energy transfer)
                    // ═══════════════════════════════════════════════════════════════
                    Canvas { context, size in
                        if connectPhase > 0 {
                            // Calculate current agent positions
                            var agentPositions: [(pos: CGPoint, color: Color)] = []
                            for agent in agents {
                                let angle = agent.baseAngle + time * agent.speed * 0.4
                                let orbitRadius = baseRadius * CGFloat(agent.orbitRadius) * 2.5 * CGFloat(1 - syncPhase * 0.3)
                                let x = center.x + cos(angle) * orbitRadius
                                let y = center.y + sin(angle) * orbitRadius * 0.55
                                agentPositions.append((CGPoint(x: x, y: y), agent.primaryColor))
                            }
                            
                            // Draw connections
                            for i in 0..<agentPositions.count {
                                for j in (i+1)..<agentPositions.count {
                                    let p1 = agentPositions[i]
                                    let p2 = agentPositions[j]
                                    
                                    // Connection appears based on progress
                                    let connDelay = Double(i + j) * 0.08
                                    let connProgress = min(1.0, max(0, (connectPhase - connDelay) * 2.0))
                                    
                                    if connProgress > 0.1 {
                                        // Arc connection (curved, not straight)
                                        let midX = (p1.pos.x + p2.pos.x) / 2
                                        let midY = (p1.pos.y + p2.pos.y) / 2 - 30 // Curve upward
                                        
                                        var arcPath = Path()
                                        arcPath.move(to: p1.pos)
                                        arcPath.addQuadCurve(to: p2.pos, control: CGPoint(x: midX, y: midY))
                                        
                                        // Blend colors
                                        let blendColor = Color(
                                            red: 0.5,
                                            green: 0.7,
                                            blue: 0.9
                                        )
                                        
                                        context.stroke(arcPath, with: .color(blendColor.opacity(0.4 * connProgress)), lineWidth: 1.5)
                                        
                                        // Energy pulse traveling along connection
                                        let pulseT = fmod(time * 1.2 + Double(i + j) * 0.5, 1.0)
                                        let pulsePos = quadraticBezier(p1.pos, CGPoint(x: midX, y: midY), p2.pos, CGFloat(pulseT))
                                        
                                        context.fill(
                                            Circle().path(in: CGRect(x: pulsePos.x - 4, y: pulsePos.y - 4, width: 8, height: 8)),
                                            with: .radialGradient(
                                                Gradient(colors: [hotWhite.opacity(0.9 * connProgress), blendColor.opacity(0.5 * connProgress), .clear]),
                                                center: pulsePos,
                                                startRadius: 0,
                                                endRadius: 6
                                            )
                                        )
                                    }
                                }
                                
                                // Connection from agent to center (during sync)
                                if syncPhase > 0 {
                                    let p = agentPositions[i]
                                    
                                    var centerLine = Path()
                                    centerLine.move(to: p.pos)
                                    centerLine.addLine(to: center)
                                    
                                    context.stroke(centerLine, with: .color(coreGold.opacity(0.3 * syncPhase)), lineWidth: 1)
                                    
                                    // Energy flowing to center
                                    let flowT = fmod(time * 2 + Double(i) * 0.3, 1.0)
                                    let flowX = p.pos.x + (center.x - p.pos.x) * CGFloat(flowT)
                                    let flowY = p.pos.y + (center.y - p.pos.y) * CGFloat(flowT)
                                    
                                    context.fill(
                                        Circle().path(in: CGRect(x: flowX - 3, y: flowY - 3, width: 6, height: 6)),
                                        with: .color(p.color.opacity(0.7 * syncPhase * (1 - flowT)))
                                    )
                                }
                            }
                        }
                    }
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 6: Sync shockwave (the moment everything clicks)
                    // ═══════════════════════════════════════════════════════════════
                    Canvas { context, size in
                        if syncPhase > 0.3 {
                            // Expanding rings when agents sync
                            for ring in 0..<3 {
                                let ringProgress = fmod(time * 0.8 + Double(ring) * 0.33, 1.0)
                                let ringRadius = baseRadius * CGFloat(0.3 + ringProgress * 1.2)
                                let ringOpacity = (1 - ringProgress) * syncPhase * 0.4
                                
                                var ringPath = Path()
                                ringPath.addEllipse(in: CGRect(x: center.x - ringRadius, y: center.y - ringRadius * 0.55,
                                                               width: ringRadius * 2, height: ringRadius * 2 * 0.55))
                                
                                context.stroke(ringPath, with: .color(coreGold.opacity(ringOpacity)), lineWidth: 2 - CGFloat(ringProgress))
                            }
                        }
                    }
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 7: THE TEXT - "AGENTIC ORCHESTRATION" with power
                    // ═══════════════════════════════════════════════════════════════
                    if textPhase > 0 {
                        VStack(spacing: 12) {
                            Spacer()
                            
                            // Subtitle
                            Text("THIS IS")
                                .font(.system(size: 14, weight: .medium))
                                .tracking(8)
                                .foregroundColor(.white.opacity(0.5))
                                .opacity(textPhase)
                            
                            // Main title with epic reveal
                            ZStack {
                                // Outer glow layer
                                Text("AGENTIC ORCHESTRATION")
                                    .font(.system(size: 32, weight: .black))
                                    .tracking(6)
                                    .foregroundColor(coreGold.opacity(0.3))
                                    .blur(radius: 20)
                                
                                // Mid glow
                                Text("AGENTIC ORCHESTRATION")
                                    .font(.system(size: 32, weight: .black))
                                    .tracking(6)
                                    .foregroundColor(electricBlue.opacity(0.5))
                                    .blur(radius: 10)
                                
                                // Main text with gradient
                                Text("AGENTIC ORCHESTRATION")
                                    .font(.system(size: 32, weight: .black))
                                    .tracking(6)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [coreGold, hotWhite, electricBlue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: coreGold.opacity(0.8), radius: 15)
                                    .shadow(color: electricBlue.opacity(0.5), radius: 30)
                            }
                            .opacity(textPhase)
                            .scaleEffect(0.9 + textPhase * 0.1)
                            .offset(y: (1 - textPhase) * 30)
                            
                            // Tagline
                            Text("Intelligence that orchestrates. Agents that deliver.")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(.white.opacity(0.7))
                                .opacity(min(1, (textPhase - 0.3) * 2))
                                .offset(y: (1 - textPhase) * 20)
                            
                            Spacer()
                                .frame(height: 80)
                        }
                        .animation(.easeOut(duration: 0.8), value: textPhase > 0.5)
                    }
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 8: Glory phase - final flourish
                    // ═══════════════════════════════════════════════════════════════
                    if gloryPhase > 0 {
                        Canvas { context, size in
                            // Starburst rays from center
                            for ray in 0..<24 {
                                let rayAngle = Double(ray) * .pi * 2 / 24 + time * 0.1
                                let rayLength = baseRadius * CGFloat(1.5 + gloryPhase * 0.5)
                                let rayWidth: CGFloat = 1.5
                                
                                var rayPath = Path()
                                rayPath.move(to: center)
                                let endX = center.x + cos(rayAngle) * rayLength
                                let endY = center.y + sin(rayAngle) * rayLength * 0.55
                                rayPath.addLine(to: CGPoint(x: endX, y: endY))
                                
                                context.stroke(
                                    rayPath,
                                    with: .linearGradient(
                                        Gradient(colors: [coreGold.opacity(0.4 * gloryPhase), .clear]),
                                        startPoint: center,
                                        endPoint: CGPoint(x: endX, y: endY)
                                    ),
                                    lineWidth: rayWidth
                                )
                            }
                        }
                    }
                }
            }
            .drawingGroup() // Metal-accelerated rendering for 60fps
        }
    }
    
    // Helper function for bezier curve position
    private func quadraticBezier(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ t: CGFloat) -> CGPoint {
        let oneMinusT = 1 - t
        let x = oneMinusT * oneMinusT * p0.x + 2 * oneMinusT * t * p1.x + t * t * p2.x
        let y = oneMinusT * oneMinusT * p0.y + 2 * oneMinusT * t * p1.y + t * t * p2.y
        return CGPoint(x: x, y: y)
    }
    
    // Create unique agent body shapes
    private func createAgentShape(_ shape: AgentShape, center: CGPoint, size: CGFloat) -> Path {
        var path = Path()
        let cx = center.x
        let cy = center.y
        let r = size * 0.5
        
        switch shape {
        case .hexagon:
            // 6-sided polygon - leadership, authority
            for i in 0..<6 {
                let angle = Double(i) * .pi / 3 - .pi / 2
                let x = cx + cos(angle) * r
                let y = cy + sin(angle) * r
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            path.closeSubpath()
            
        case .diamond:
            // Diamond/rhombus - analytical, precise
            path.move(to: CGPoint(x: cx, y: cy - r * 1.2))
            path.addLine(to: CGPoint(x: cx + r * 0.8, y: cy))
            path.addLine(to: CGPoint(x: cx, y: cy + r * 1.2))
            path.addLine(to: CGPoint(x: cx - r * 0.8, y: cy))
            path.closeSubpath()
            
        case .triangle:
            // Triangle pointing right - action, forward motion
            path.move(to: CGPoint(x: cx + r * 1.1, y: cy))
            path.addLine(to: CGPoint(x: cx - r * 0.7, y: cy - r * 0.9))
            path.addLine(to: CGPoint(x: cx - r * 0.7, y: cy + r * 0.9))
            path.closeSubpath()
            
        case .star:
            // 5-pointed star - connection, reaching out
            for i in 0..<10 {
                let angle = Double(i) * .pi / 5 - .pi / 2
                let radius = i % 2 == 0 ? r * 1.1 : r * 0.5
                let x = cx + cos(angle) * radius
                let y = cy + sin(angle) * radius
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            path.closeSubpath()
            
        case .octagon:
            // 8-sided - complex, innovative
            for i in 0..<8 {
                let angle = Double(i) * .pi / 4 - .pi / 8
                let x = cx + cos(angle) * r
                let y = cy + sin(angle) * r
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            path.closeSubpath()
            
        case .shield:
            // Shield shape - protective, optimizing
            path.move(to: CGPoint(x: cx, y: cy - r * 1.1))
            path.addQuadCurve(to: CGPoint(x: cx + r, y: cy - r * 0.3), control: CGPoint(x: cx + r * 0.8, y: cy - r * 1.0))
            path.addLine(to: CGPoint(x: cx + r * 0.8, y: cy + r * 0.5))
            path.addQuadCurve(to: CGPoint(x: cx, y: cy + r * 1.1), control: CGPoint(x: cx + r * 0.4, y: cy + r * 1.0))
            path.addQuadCurve(to: CGPoint(x: cx - r * 0.8, y: cy + r * 0.5), control: CGPoint(x: cx - r * 0.4, y: cy + r * 1.0))
            path.addLine(to: CGPoint(x: cx - r, y: cy - r * 0.3))
            path.addQuadCurve(to: CGPoint(x: cx, y: cy - r * 1.1), control: CGPoint(x: cx - r * 0.8, y: cy - r * 1.0))
            path.closeSubpath()
            
        case .circle:
            // Perfect circle - harmony, balance
            path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        }
        
        return path
    }
    
    // Draw agent "eye" - glowing processing indicator
    private func drawAgentEye(context: GraphicsContext, x: CGFloat, y: CGFloat, size: CGFloat, color: Color, pulse: Double, time: Double) {
        let eyeCenter = CGPoint(x: x, y: y)
        
        // Outer glow
        context.fill(
            Circle().path(in: CGRect(x: x - size * 1.5, y: y - size * 1.5, width: size * 3, height: size * 3)),
            with: .radialGradient(
                Gradient(colors: [color.opacity(0.4 * pulse), .clear]),
                center: eyeCenter,
                startRadius: 0,
                endRadius: size * 1.5
            )
        )
        
        // Eye socket
        context.fill(
            Circle().path(in: CGRect(x: x - size, y: y - size, width: size * 2, height: size * 2)),
            with: .color(Color.black.opacity(0.6))
        )
        
        // Inner iris
        let irisSize = size * 0.7
        context.fill(
            Circle().path(in: CGRect(x: x - irisSize, y: y - irisSize, width: irisSize * 2, height: irisSize * 2)),
            with: .radialGradient(
                Gradient(colors: [hotWhite, color]),
                center: eyeCenter,
                startRadius: 0,
                endRadius: irisSize
            )
        )
        
        // Scanning line effect
        let scanY = y + sin(time * 3) * size * 0.5
        var scanLine = Path()
        scanLine.move(to: CGPoint(x: x - size * 0.8, y: scanY))
        scanLine.addLine(to: CGPoint(x: x + size * 0.8, y: scanY))
        context.stroke(scanLine, with: .color(hotWhite.opacity(0.6 * pulse)), lineWidth: 1)
    }
}

// MARK: - Human Return (02:45-03:30)
/// Cinematic reveal: Human silhouette emerges from the network, potential restored
// MARK: - Human Return: "GRAVITY RELEASE"
/// Figure weighted by chains that dissolve, then rises into light - anti-gravity liberation
struct HumanReturnAnimation: View {
    var progress: Double
    
    // Colors - cinematic palette
    private let chainGray = Color(red: 0.35, green: 0.35, blue: 0.4)
    private let liberationGold = Color(red: 1.0, green: 0.85, blue: 0.5)
    private let skyLight = Color(red: 0.7, green: 0.85, blue: 1.0)
    private let deepDark = Color(red: 0.03, green: 0.03, blue: 0.06)
    
    // Chain/anchor data - visible weights holding figure down
    private struct ChainAnchor {
        let id: Int
        let attachX: CGFloat      // Where it attaches to figure (-1 to 1, relative)
        let attachY: CGFloat      // Vertical attachment point
        let icon: String          // The weight icon
        let dissolveDelay: Double // When it starts dissolving
    }
    
    private let chains: [ChainAnchor] = [
        ChainAnchor(id: 0, attachX: -0.6, attachY: 0.3, icon: "envelope.badge", dissolveDelay: 0.10),
        ChainAnchor(id: 1, attachX: 0.6, attachY: 0.35, icon: "clock.badge.exclamationmark", dissolveDelay: 0.15),
        ChainAnchor(id: 2, attachX: -0.3, attachY: 0.5, icon: "doc.on.doc", dissolveDelay: 0.20),
        ChainAnchor(id: 3, attachX: 0.35, attachY: 0.55, icon: "chart.bar.doc.horizontal", dissolveDelay: 0.25),
        ChainAnchor(id: 4, attachX: 0.0, attachY: 0.7, icon: "tray.2.fill", dissolveDelay: 0.30),
    ]
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            // Animation phases - cinematic timing
            let chainsPhase = min(1.0, progress / 0.35)                    // 0-35%: chains visible, dissolving
            let dissolvePhase = min(1.0, max(0, (progress - 0.15) / 0.35)) // 15-50%: chains dissolve
            let risePhase = min(1.0, max(0, (progress - 0.40) / 0.35))     // 40-75%: figure rises
            let gloryPhase = min(1.0, max(0, (progress - 0.65) / 0.35))    // 65-100%: full liberation
            let textPhase = min(1.0, max(0, (progress - 0.50) / 0.30))     // 50-80%: text appears
            
            GeometryReader { geo in
                let centerX = geo.size.width / 2
                let centerY = geo.size.height * 0.45
                let figureSize: CGFloat = 130
                
                // Figure rises as chains dissolve
                let figureRiseY = centerY - (risePhase * 80) - sin(time * 0.8) * (risePhase * 10)
                
                ZStack {
                    // ═══════════════════════════════════════════════════════════════
                    // BACKGROUND: Dark abyss to light sky
                    // ═══════════════════════════════════════════════════════════════
                    LinearGradient(
                        colors: [
                            deepDark.opacity(1 - gloryPhase * 0.95),
                            Color(white: 0.1 + gloryPhase * 0.85),
                            skyLight.opacity(gloryPhase)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .ignoresSafeArea()
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 1: Light source above (destination)
                    // ═══════════════════════════════════════════════════════════════
                    Canvas { context, size in
                        // Growing light from above
                        let lightY = size.height * 0.15
                        let lightRadius = size.width * 0.5 * CGFloat(0.3 + gloryPhase * 0.7)
                        
                        context.fill(
                            Ellipse().path(in: CGRect(x: centerX - lightRadius,
                                                      y: lightY - lightRadius * 0.4,
                                                      width: lightRadius * 2,
                                                      height: lightRadius * 0.8)),
                            with: .radialGradient(
                                Gradient(colors: [
                                    liberationGold.opacity(0.5 * (0.2 + gloryPhase * 0.8)),
                                    skyLight.opacity(0.3 * (0.2 + gloryPhase * 0.8)),
                                    .clear
                                ]),
                                center: CGPoint(x: centerX, y: lightY),
                                startRadius: 0,
                                endRadius: lightRadius
                            )
                        )
                        
                        // Light rays descending
                        if gloryPhase > 0.2 {
                            for ray in 0..<8 {
                                let rayAngle = Double(ray) * .pi / 4 + .pi / 8
                                let rayLength = size.height * 0.5 * CGFloat(gloryPhase)
                                
                                var rayPath = Path()
                                rayPath.move(to: CGPoint(x: centerX, y: lightY))
                                let endX = centerX + cos(rayAngle) * rayLength * 0.5
                                let endY = lightY + sin(rayAngle) * rayLength
                                rayPath.addLine(to: CGPoint(x: endX, y: endY))
                                
                                context.stroke(
                                    rayPath,
                                    with: .linearGradient(
                                        Gradient(colors: [liberationGold.opacity(0.2 * gloryPhase), .clear]),
                                        startPoint: CGPoint(x: centerX, y: lightY),
                                        endPoint: CGPoint(x: endX, y: endY)
                                    ),
                                    lineWidth: 25
                                )
                            }
                        }
                    }
                    .blur(radius: 20)
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 2: The Chains - visible weights pulling down
                    // ═══════════════════════════════════════════════════════════════
                    Canvas { context, size in
                        for chain in chains {
                            // Calculate how dissolved this chain is
                            let chainDissolve = min(1.0, max(0, (dissolvePhase - chain.dissolveDelay) / 0.25))
                            
                            if chainDissolve < 1.0 {
                                // Chain attachment point on figure
                                let attachX = centerX + chain.attachX * (figureSize * 0.3)
                                let attachY = figureRiseY + chain.attachY * figureSize
                                
                                // Anchor point below (in the abyss)
                                let anchorY = size.height * 0.85
                                let anchorX = attachX + chain.attachX * 30
                                
                                // Draw chain links from figure down to anchor
                                let chainLength = anchorY - attachY
                                let linkCount = 8
                                let linkSpacing = chainLength / CGFloat(linkCount)
                                
                                for link in 0..<linkCount {
                                    let linkY = attachY + CGFloat(link) * linkSpacing
                                    let linkX = attachX + (anchorX - attachX) * (CGFloat(link) / CGFloat(linkCount))
                                    
                                    // Links dissolve from bottom up
                                    let linkDissolve = chainDissolve * (CGFloat(linkCount - link) / CGFloat(linkCount))
                                    let linkOpacity = (1 - linkDissolve) * 0.6
                                    
                                    if linkOpacity > 0 {
                                        // Chain link oval
                                        var linkPath = Path()
                                        linkPath.addEllipse(in: CGRect(x: linkX - 4, y: linkY - 8, width: 8, height: 16))
                                        context.stroke(linkPath, with: .color(chainGray.opacity(linkOpacity)), lineWidth: 2)
                                    }
                                }
                                
                                // The anchor/weight at bottom
                                let anchorOpacity = (1 - chainDissolve) * 0.7
                                if anchorOpacity > 0 {
                                    // Anchor glow
                                    context.fill(
                                        Circle().path(in: CGRect(x: anchorX - 25, y: anchorY - 25, width: 50, height: 50)),
                                        with: .radialGradient(
                                            Gradient(colors: [chainGray.opacity(anchorOpacity * 0.3), .clear]),
                                            center: CGPoint(x: anchorX, y: anchorY),
                                            startRadius: 0,
                                            endRadius: 25
                                        )
                                    )
                                }
                            }
                            
                            // Dissolution particles rising from broken chains
                            if chainDissolve > 0 && chainDissolve < 1.0 {
                                let attachX = centerX + chain.attachX * (figureSize * 0.3)
                                let attachY = figureRiseY + chain.attachY * figureSize
                                
                                for p in 0..<5 {
                                    let seed = Double(chain.id * 10 + p)
                                    let particleT = fmod(time * 1.5 + seed * 0.2, 1.0)
                                    let px = attachX + CGFloat(sin(seed * 3)) * 20
                                    let py = attachY + CGFloat(particleT) * 60 - 30
                                    let pSize: CGFloat = 2 + CGFloat(sin(time * 3 + seed)) * 1
                                    
                                    context.fill(
                                        Circle().path(in: CGRect(x: px - pSize, y: py - pSize, width: pSize * 2, height: pSize * 2)),
                                        with: .color(liberationGold.opacity(0.5 * chainDissolve * (1 - particleT)))
                                    )
                                }
                            }
                        }
                    }
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 3: The Human Figure - rising into light
                    // ═══════════════════════════════════════════════════════════════
                    ZStack {
                        // Figure glow (grows as it rises)
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        liberationGold.opacity(0.3 * risePhase),
                                        skyLight.opacity(0.15 * risePhase),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                        
                        // The figure
                        Image(systemName: "figure.arms.open")
                            .font(.system(size: figureSize, weight: .ultraLight))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4 + gloryPhase * 0.5),
                                        skyLight.opacity(0.6 + gloryPhase * 0.4)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: liberationGold.opacity(0.4 * gloryPhase), radius: 25)
                            // Slight float/bob animation when free
                            .offset(y: risePhase > 0.5 ? sin(time * 1.2) * 5 : 0)
                    }
                    .position(x: centerX, y: figureRiseY)
                    .opacity(min(1.0, progress * 3))
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 4: Rising particles around figure (anti-gravity debris)
                    // ═══════════════════════════════════════════════════════════════
                    if risePhase > 0.2 {
                        Canvas { context, size in
                            for i in 0..<25 {
                                let seed = Double(i) * 1.618
                                let particleT = fmod(time * 0.6 + seed * 0.15, 1.0)
                                
                                // Particles rise from around figure
                                let startX = centerX + CGFloat(sin(seed * 7)) * 100
                                let startY = figureRiseY + 80
                                let endY = size.height * 0.1
                                
                                let px = startX + CGFloat(sin(time * 0.5 + seed)) * 20
                                let py = startY + (endY - startY) * CGFloat(particleT)
                                let pSize: CGFloat = 1.5 + CGFloat(fmod(seed * 2, 1.0)) * 2
                                
                                let fadeIn = min(1.0, particleT * 4)
                                let fadeOut = particleT > 0.7 ? (particleT - 0.7) / 0.3 : 0
                                
                                context.fill(
                                    Circle().path(in: CGRect(x: px - pSize, y: py - pSize, width: pSize * 2, height: pSize * 2)),
                                    with: .color(skyLight.opacity(0.4 * (risePhase - 0.2) * fadeIn * (1 - fadeOut)))
                                )
                            }
                        }
                    }
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 5: Text - screen text DIFFERENT from narration
                    // ═══════════════════════════════════════════════════════════════
                    if textPhase > 0 {
                        VStack(spacing: 16) {
                            Spacer()
                            
                            // Screen text: Short, punchy (Narration provides context)
                            Text("RELEASED")
                                .font(.system(size: 14, weight: .bold))
                                .tracking(10)
                                .foregroundColor(skyLight.opacity(0.7))
                                .opacity(textPhase)
                            
                            Text("Rise.")
                                .font(.system(size: 42, weight: .light, design: .serif))
                                .foregroundColor(gloryPhase > 0.5 ? .black.opacity(0.85) : .white.opacity(0.9))
                                .opacity(textPhase)
                                .offset(y: (1 - textPhase) * 20)
                            
                            if textPhase > 0.5 {
                                Text("Your genius awaits.")
                                    .font(.system(size: 20, weight: .regular, design: .serif))
                                    .foregroundColor(liberationGold)
                                    .opacity(min(1, (textPhase - 0.5) * 3))
                            }
                            
                            Spacer().frame(height: 100)
                        }
                    }
                }
            }
            .drawingGroup()
        }
    }
}

// MARK: - Personalization View (03:30-04:30)
struct PersonalizationView: View {
    @Bindable var viewModel: ExperienceViewModel
    
    private let accentBlue = Color(red: 0.3, green: 0.5, blue: 1.0)
    private let glowBlue = Color(red: 0.4, green: 0.6, blue: 1.0)
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            ZStack {
                // ULTRA animated background
                ZStack {
                    Color.black
                    
                    // Animated gradient orbs
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [accentBlue.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 300
                            )
                        )
                        .frame(width: 600, height: 600)
                        .offset(x: sin(time * 0.3) * 100, y: cos(time * 0.2) * 50 - 100)
                        .blur(radius: 60)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.green.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 250
                            )
                        )
                        .frame(width: 500, height: 500)
                        .offset(x: cos(time * 0.25) * 80 + 100, y: sin(time * 0.35) * 60 + 150)
                        .blur(radius: 50)
                    
                    // Floating particles
                    FloatingParticles(count: 50, color: accentBlue, speed: 1.0)
                }
                .ignoresSafeArea()
                
                VStack(spacing: 45) {
                    // GLOWING question text
                    ZStack {
                        Text("How many hours of invisible work does your team lose each week?")
                            .font(.system(size: 32, weight: .light, design: .serif))
                            .foregroundColor(accentBlue.opacity(0.3))
                            .blur(radius: 15)
                        
                        Text("How many hours of invisible work does your team lose each week?")
                            .font(.system(size: 32, weight: .light, design: .serif))
                            .foregroundColor(.white)
                            .shadow(color: .white.opacity(0.2), radius: 10)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 70)
                    
                    // MEGA Glassmorphism container with glow
                    ZStack {
                        // Outer glow
                        RoundedRectangle(cornerRadius: 30)
                            .fill(accentBlue.opacity(0.1))
                            .blur(radius: 30)
                            .padding(-20)
                        
                        VStack(spacing: 35) {
                            VStack(spacing: 15) {
                                // MASSIVE glowing number
                                ZStack {
                                    Text("\(Int(viewModel.lostHoursPerWeek))")
                                        .font(.system(size: 100, weight: .bold, design: .rounded))
                                        .foregroundColor(accentBlue.opacity(0.3))
                                        .blur(radius: 20)
                                    
                                    Text("\(Int(viewModel.lostHoursPerWeek))")
                                        .font(.system(size: 100, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [glowBlue, accentBlue],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(color: accentBlue.opacity(0.6), radius: 20)
                                        .contentTransition(.numericText())
                                }
                                
                                Text("HOURS PER WEEK")
                                    .font(.system(size: 14, weight: .bold))
                                    .tracking(6)
                                    .foregroundColor(.white.opacity(0.5))
                                
                                // Custom slider (fixes iOS 26 beta bug)
                                CustomSlider(
                                    value: $viewModel.lostHoursPerWeek,
                                    range: 0...100,
                                    accentColor: accentBlue
                                )
                                .padding(.horizontal, 40)
                            }
                            
                            // Divider line with glow
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, accentBlue.opacity(0.3), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 1)
                                .padding(.horizontal, 30)
                            
                            HStack(spacing: 80) {
                                EnhancedMetricView(label: "TEAM SIZE", value: "\(Int(viewModel.teamSize))", color: .white, time: time)
                                EnhancedMetricView(label: "ANNUAL IMPACT", value: "$\(formatLargeNumber(viewModel.annualImpact))", color: Color.green, time: time)
                            }
                        }
                        .padding(45)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(.ultraThinMaterial.opacity(0.5))
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.white.opacity(0.03))
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(
                                    LinearGradient(
                                        colors: [accentBlue.opacity(0.3), .white.opacity(0.1), accentBlue.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .padding(.horizontal, 80)
                }
                .padding()
            }
            .drawingGroup() // Metal-accelerated rendering for 60fps
        }
    }
    
    private func formatLargeNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
}

struct EnhancedMetricView: View {
    let label: String
    let value: String
    let color: Color
    let time: Double
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .tracking(5)
                .foregroundColor(.white.opacity(0.4))
            
            ZStack {
                Text(value)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundColor(color.opacity(0.3))
                    .blur(radius: 8)
                
                Text(value)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.5), radius: 10)
            }
            .scaleEffect(1.0 + sin(time * 2) * 0.02)
        }
    }
}

// MARK: - Final CTA View: "THE SIGNAL"
/// Minimal, elegant, pulse-based - the quiet power after the spectacle
struct FinalCTAView: View {
    var progress: Double
    var isComplete: Bool
    
    // Colors - refined, premium
    private let signalGold = Color(red: 0.95, green: 0.8, blue: 0.4)
    private let pureWhite = Color.white
    private let voidBlack = Color(red: 0.02, green: 0.02, blue: 0.04)
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            // Animation phases - elegant timing
            let pulsePhase = min(1.0, progress / 0.20)                    // 0-20%: First pulse
            let text1Phase = min(1.0, max(0, (progress - 0.15) / 0.20))   // 15-35%: First text
            let text2Phase = min(1.0, max(0, (progress - 0.30) / 0.20))   // 30-50%: Second text
            let questionPhase = min(1.0, max(0, (progress - 0.45) / 0.20)) // 45-65%: Question
            let ctaPhase = min(1.0, max(0, (progress - 0.60) / 0.25))     // 60-85%: CTAs
            let glowPhase = min(1.0, max(0, (progress - 0.75) / 0.25))    // 75-100%: Final glow
            
            GeometryReader { geo in
                let centerX = geo.size.width / 2
                let centerY = geo.size.height * 0.35
                
                ZStack {
                    // ═══════════════════════════════════════════════════════════════
                    // BACKGROUND: Pure black - cinema darkness
                    // ═══════════════════════════════════════════════════════════════
                    voidBlack.ignoresSafeArea()
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 1: The Signal - expanding pulse rings
                    // ═══════════════════════════════════════════════════════════════
                    Canvas { context, size in
                        let center = CGPoint(x: centerX, y: centerY)
                        
                        // Multiple pulse rings emanating from center
                        for ring in 0..<4 {
                            let ringDelay = Double(ring) * 0.25
                            let pulseT = fmod(time * 0.4 + ringDelay, 1.0)
                            let ringRadius = 20 + CGFloat(pulseT) * 200
                            let ringOpacity = (1 - pulseT) * pulsePhase * 0.3
                            
                            var ringPath = Path()
                            ringPath.addEllipse(in: CGRect(x: center.x - ringRadius,
                                                           y: center.y - ringRadius,
                                                           width: ringRadius * 2,
                                                           height: ringRadius * 2))
                            
                            context.stroke(ringPath, with: .color(signalGold.opacity(ringOpacity)), lineWidth: 1.5)
                        }
                        
                        // Central beacon - the origin point
                        let beaconPulse = sin(time * 2) * 0.3 + 0.7
                        let beaconSize: CGFloat = 8 + CGFloat(beaconPulse) * 4
                        
                        // Outer glow
                        context.fill(
                            Circle().path(in: CGRect(x: center.x - 30, y: center.y - 30, width: 60, height: 60)),
                            with: .radialGradient(
                                Gradient(colors: [signalGold.opacity(0.3 * pulsePhase), .clear]),
                                center: center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        
                        // Core beacon
                        context.fill(
                            Circle().path(in: CGRect(x: center.x - beaconSize/2,
                                                     y: center.y - beaconSize/2,
                                                     width: beaconSize, height: beaconSize)),
                            with: .color(signalGold.opacity(pulsePhase))
                        )
                    }
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 2: Minimal ambient particles (subtle, not distracting)
                    // ═══════════════════════════════════════════════════════════════
                    if glowPhase > 0 {
                        Canvas { context, size in
                            for i in 0..<15 {
                                let seed = Double(i) * 1.618
                                let x = CGFloat(fmod(seed * 137.5, 1.0)) * size.width
                                let y = CGFloat(fmod(seed * 89.3, 1.0)) * size.height * 0.6 + size.height * 0.1
                                let twinkle = sin(time * 1.5 + seed * 3) * 0.5 + 0.5
                                let pSize: CGFloat = 1 + CGFloat(fmod(seed * 2, 1.0))
                                
                                context.fill(
                                    Circle().path(in: CGRect(x: x - pSize, y: y - pSize, width: pSize * 2, height: pSize * 2)),
                                    with: .color(pureWhite.opacity(0.15 * glowPhase * twinkle))
                                )
                            }
                        }
                    }
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 3: Text reveals - one line at a time
                    // ═══════════════════════════════════════════════════════════════
                    VStack(spacing: 0) {
                        Spacer().frame(height: geo.size.height * 0.48)
                        
                        VStack(spacing: 24) {
                            // First line - Screen text (Narration says something different)
                            if text1Phase > 0 {
                                Text("One decision.")
                                    .font(.system(size: 28, weight: .light, design: .serif))
                                    .foregroundColor(pureWhite.opacity(0.9))
                                    .opacity(text1Phase)
                                    .offset(y: (1 - text1Phase) * 15)
                            }
                            
                            // Second line
                            if text2Phase > 0 {
                                Text("Infinite possibility.")
                                    .font(.system(size: 34, weight: .medium, design: .serif))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [signalGold, pureWhite],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .opacity(text2Phase)
                                    .offset(y: (1 - text2Phase) * 15)
                            }
                            
                            // Subtle separator
                            if questionPhase > 0 {
                                Rectangle()
                                    .fill(signalGold.opacity(0.3))
                                    .frame(width: 60, height: 1)
                                    .opacity(questionPhase)
                                    .padding(.vertical, 8)
                            }
                            
                            // Question - different from narration
                            if questionPhase > 0 {
                                Text("Where will you lead?")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(pureWhite.opacity(0.6))
                                    .opacity(questionPhase)
                                    .offset(y: (1 - questionPhase) * 10)
                            }
                        }
                        .multilineTextAlignment(.center)
                        
                        Spacer().frame(height: 50)
                        
                        // ═══════════════════════════════════════════════════════════════
                        // LAYER 4: Minimal CTAs - elegant, understated
                        // ═══════════════════════════════════════════════════════════════
                        if ctaPhase > 0 {
                            HStack(spacing: 40) {
                                // Vision Pro
                                VStack(spacing: 10) {
                                    Image(systemName: "visionpro")
                                        .font(.system(size: 32, weight: .ultraLight))
                                        .foregroundColor(pureWhite.opacity(0.8))
                                    
                                    Text("EXPERIENCE")
                                        .font(.system(size: 10, weight: .medium))
                                        .tracking(4)
                                        .foregroundColor(pureWhite.opacity(0.5))
                                }
                                .padding(.vertical, 20)
                                .padding(.horizontal, 30)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(pureWhite.opacity(0.2), lineWidth: 1)
                                )
                                
                                // Live Demo
                                Button(action: {
                                    print("🎯 Live Demo requested")
                                }) {
                                    VStack(spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .stroke(signalGold.opacity(0.5), lineWidth: 1)
                                                .frame(width: 44, height: 44)
                                            
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(signalGold)
                                        }
                                        
                                        Text("DEMO")
                                            .font(.system(size: 10, weight: .medium))
                                            .tracking(4)
                                            .foregroundColor(signalGold.opacity(0.8))
                                    }
                                    .padding(.vertical, 20)
                                    .padding(.horizontal, 30)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(signalGold.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .opacity(ctaPhase)
                            .offset(y: (1 - ctaPhase) * 20)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 50)
                    
                    // ═══════════════════════════════════════════════════════════════
                    // LAYER 5: Final ambient glow (subtle warmth)
                    // ═══════════════════════════════════════════════════════════════
                    if glowPhase > 0.5 {
                        RadialGradient(
                            colors: [
                                signalGold.opacity(0.05 * (glowPhase - 0.5) * 2),
                                .clear
                            ],
                            center: UnitPoint(x: 0.5, y: 0.35),
                            startRadius: 0,
                            endRadius: geo.size.width * 0.6
                        )
                        .ignoresSafeArea()
                    }
                }
            }
            .drawingGroup()
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

