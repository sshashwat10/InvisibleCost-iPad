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
/// 3D SPHERE: points appear one by one → connect → pulse → shrink → text
struct AgenticOrchestrationAnimation: View {
    var progress: Double
    @Environment(MotionManager.self) private var motion
    
    // Teal color palette
    private let primaryTeal = Color(red: 0.0, green: 0.6, blue: 0.7)
    private let glowTeal = Color(red: 0.1, green: 0.8, blue: 0.9)
    private let darkTeal = Color(red: 0.0, green: 0.35, blue: 0.45)
    
    // 3D sphere points (distributed on a sphere using golden spiral - optimized for 60fps)
    private let spherePoints: [(theta: Double, phi: Double)] = {
        var points: [(Double, Double)] = []
        let n = 32 // Number of points (balanced for visual quality and performance)
        let goldenRatio = (1 + sqrt(5)) / 2
        
        for i in 0..<n {
            let theta = 2 * .pi * Double(i) / goldenRatio
            let phi = acos(1 - 2 * (Double(i) + 0.5) / Double(n))
            points.append((theta, phi))
        }
        return points
    }()
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            // Animation phases (0-1 over the progress)
            let pointsAppear = min(1.0, progress / 0.25)        // 0-25%: points appear one by one
            let connectPhase = min(1.0, max(0, (progress - 0.20) / 0.25)) // 20-45%: connections draw
            let pulsePhase = min(1.0, max(0, (progress - 0.40) / 0.20))   // 40-60%: pulsing intensifies
            let shrinkPhase = min(1.0, max(0, (progress - 0.55) / 0.15))  // 55-70%: sphere shrinks
            let textPhase = min(1.0, max(0, (progress - 0.60) / 0.15))    // 60-75%: text appears
            
            // Sphere scale (shrinks when text appears)
            let sphereScale = 1.0 - shrinkPhase * 0.45
            let sphereOffsetY = shrinkPhase * -80
            
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Ambient background particles (reduced for 60fps)
                Canvas { context, size in
                    for i in 0..<25 {
                        let seed = Double(i) * 1.618
                        let x = (sin(time * 0.12 + seed * 2) * 0.5 + 0.5) * size.width
                        let y = (cos(time * 0.08 + seed * 1.5) * 0.5 + 0.5) * size.height
                        let pulse = sin(time * 1.2 + seed) * 0.5 + 0.5
                        let particleSize: CGFloat = 1.5 + CGFloat(pulse) * 2
                        
                        context.fill(
                            Circle().path(in: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                            with: .color(primaryTeal.opacity(0.06 + pulse * 0.06))
                        )
                    }
                }
                
                // 3D SPHERE with points, connections, and pulses
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2 + CGFloat(sphereOffsetY))
                    let baseRadius: CGFloat = min(size.width, size.height) * 0.30
                    let sphereRadius = baseRadius * CGFloat(sphereScale)
                    
                    // Rotation over time for 3D effect
                    let rotationY = time * 0.2
                    let rotationX = sin(time * 0.1) * 0.2
                    
                    // Calculate 3D positions of all points
                    var screenPoints: [(pos: CGPoint, z: Double, visible: Bool)] = []
                    
                    for (i, point) in spherePoints.enumerated() {
                        // Point appears based on progress (one by one)
                        let pointProgress = min(1.0, max(0, (pointsAppear * Double(spherePoints.count) - Double(i)) * 1.5))
                        
                        if pointProgress > 0 {
                            // 3D sphere position
                            var x3d = sin(point.phi) * cos(point.theta + rotationY)
                            var y3d = cos(point.phi)
                            var z3d = sin(point.phi) * sin(point.theta + rotationY)
                            
                            // Apply X rotation
                            let y3dRotated = y3d * cos(rotationX) - z3d * sin(rotationX)
                            let z3dRotated = y3d * sin(rotationX) + z3d * cos(rotationX)
                            y3d = y3dRotated
                            z3d = z3dRotated
                            
                            // Project to 2D with perspective
                            let perspective = 1.0 + z3d * 0.3
                            let screenX = center.x + CGFloat(x3d * Double(sphereRadius) * perspective)
                            let screenY = center.y + CGFloat(y3d * Double(sphereRadius) * perspective * 0.9)
                            
                            screenPoints.append((CGPoint(x: screenX, y: screenY), z3d, pointProgress > 0.5))
                        } else {
                            screenPoints.append((.zero, 0, false))
                        }
                    }
                    
                    // Outer glow
                    let glowRadius = sphereRadius * 1.6
                    context.fill(
                        Circle().path(in: CGRect(x: center.x - glowRadius, y: center.y - glowRadius,
                                                  width: glowRadius * 2, height: glowRadius * 2)),
                        with: .radialGradient(
                            Gradient(colors: [primaryTeal.opacity(0.2 + pulsePhase * 0.15), .clear]),
                            center: center, startRadius: 0, endRadius: glowRadius
                        )
                    )
                    
                    // Draw connections between nearby points
                    if connectPhase > 0 {
                        for i in 0..<screenPoints.count {
                            guard screenPoints[i].visible else { continue }
                            
                            for j in (i+1)..<screenPoints.count {
                                guard screenPoints[j].visible else { continue }
                                
                                let p1 = screenPoints[i]
                                let p2 = screenPoints[j]
                                let dist = hypot(p2.pos.x - p1.pos.x, p2.pos.y - p1.pos.y)
                                
                                // Only connect nearby points (creates mesh effect)
                                let maxDist = sphereRadius * 0.6
                                if dist < maxDist {
                                    // Connection appears based on distance (closer = earlier)
                                    let connectionIndex = Double(i + j) / Double(spherePoints.count * 2)
                                    let connProgress = min(1.0, max(0, (connectPhase - connectionIndex * 0.5) * 2.5))
                                    
                                    if connProgress > 0 {
                                        var line = Path()
                                        line.move(to: p1.pos)
                                        
                                        // Partial line draw effect
                                        let endX = p1.pos.x + (p2.pos.x - p1.pos.x) * CGFloat(connProgress)
                                        let endY = p1.pos.y + (p2.pos.y - p1.pos.y) * CGFloat(connProgress)
                                        line.addLine(to: CGPoint(x: endX, y: endY))
                                        
                                        // Depth-based opacity
                                        let avgZ = (p1.z + p2.z) / 2
                                        let depthOpacity = 0.15 + max(0, avgZ) * 0.2
                                        
                                        context.stroke(line, with: .color(primaryTeal.opacity(depthOpacity * connProgress)), lineWidth: 0.8)
                                        
                                        // Pulse traveling along connection
                                        if pulsePhase > 0.3 {
                                            let pulseT = fmod(time * 1.5 + connectionIndex * 3, 1.0)
                                            let pulseX = p1.pos.x + (p2.pos.x - p1.pos.x) * CGFloat(pulseT)
                                            let pulseY = p1.pos.y + (p2.pos.y - p1.pos.y) * CGFloat(pulseT)
                                            
                                            context.fill(
                                                Circle().path(in: CGRect(x: pulseX - 2, y: pulseY - 2, width: 4, height: 4)),
                                                with: .color(glowTeal.opacity(0.7 * pulsePhase))
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Draw points (nodes)
                    for (i, point) in screenPoints.enumerated() {
                        guard point.visible else { continue }
                        
                        let pointProgress = min(1.0, max(0, (pointsAppear * Double(spherePoints.count) - Double(i)) * 1.5))
                        
                        // Depth-based sizing
                        let depth = (point.z + 1) / 2
                        let baseSize: CGFloat = 4 + CGFloat(depth) * 4
                        let nodeSize = baseSize * CGFloat(pointProgress)
                        
                        // Glow (stronger when pulsing)
                        let glowSize = nodeSize * (1.5 + CGFloat(pulsePhase) * 0.5)
                        context.fill(
                            Circle().path(in: CGRect(x: point.pos.x - glowSize, y: point.pos.y - glowSize,
                                                      width: glowSize * 2, height: glowSize * 2)),
                            with: .color(glowTeal.opacity((0.15 + pulsePhase * 0.1) * (0.5 + depth * 0.5)))
                        )
                        
                        // Core node
                        context.fill(
                            Circle().path(in: CGRect(x: point.pos.x - nodeSize / 2, y: point.pos.y - nodeSize / 2,
                                                      width: nodeSize, height: nodeSize)),
                            with: .color(glowTeal.opacity(0.7 + depth * 0.3))
                        )
                        
                        // Bright center for pulsing effect
                        if pulsePhase > 0.2 {
                            let pulseIntensity = sin(time * 3 + Double(i) * 0.3) * 0.5 + 0.5
                            let brightSize = nodeSize * 0.5 * CGFloat(pulseIntensity * pulsePhase)
                            context.fill(
                                Circle().path(in: CGRect(x: point.pos.x - brightSize / 2, y: point.pos.y - brightSize / 2,
                                                          width: brightSize, height: brightSize)),
                                with: .color(Color.white.opacity(0.8 * pulsePhase * pulseIntensity))
                            )
                        }
                    }
                    
                    // Central core (appears during pulse phase)
                    if pulsePhase > 0 {
                        let coreSize = sphereRadius * 0.12 * CGFloat(pulsePhase)
                        let corePulse = 1.0 + sin(time * 4) * 0.15
                        
                        context.fill(
                            Circle().path(in: CGRect(x: center.x - coreSize * CGFloat(corePulse),
                                                      y: center.y - coreSize * CGFloat(corePulse),
                                                      width: coreSize * 2 * CGFloat(corePulse),
                                                      height: coreSize * 2 * CGFloat(corePulse))),
                            with: .radialGradient(
                                Gradient(colors: [glowTeal, primaryTeal.opacity(0.6), .clear]),
                                center: center, startRadius: 0, endRadius: coreSize * CGFloat(corePulse)
                            )
                        )
                    }
                }
                
                // Text overlay (appears after shrink)
                if textPhase > 0 {
                    VStack {
                        Spacer()
                        
                        ZStack {
                            Text("AGENTIC ORCHESTRATION")
                                .font(.system(size: 24, weight: .bold))
                                .tracking(12)
                                .foregroundColor(glowTeal.opacity(0.3))
                                .blur(radius: 15)
                            
                            Text("AGENTIC ORCHESTRATION")
                                .font(.system(size: 24, weight: .bold))
                                .tracking(12)
                                .foregroundColor(glowTeal)
                                .shadow(color: glowTeal, radius: 20)
                                .shadow(color: primaryTeal.opacity(0.5), radius: 35)
                        }
                        .opacity(textPhase)
                        .offset(y: (1 - textPhase) * 20)
                        
                        Spacer()
                            .frame(height: 100)
                    }
                }
            }
            .drawingGroup() // Metal-accelerated rendering for 60fps
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
                // Gradient background: transitions from dark to light with warmth
                LinearGradient(
                    colors: [
                        Color(white: 0.02 + 0.96 * progress),
                        Color(white: 0.04 + 0.94 * progress),
                        Color(white: 0.06 + 0.92 * progress)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Cinematic light rays from behind figure
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height * 0.35)
                    let colorBlend = min(1.0, max(0, (progress - 0.3) / 0.5))
                    
                    // Light rays emanating from center
                    let rayCount = 24
                    for i in 0..<rayCount {
                        let angle = Double(i) * (2 * .pi / Double(rayCount)) + time * 0.02
                        let rayLength = size.width * (0.4 + sin(time * 0.5 + Double(i)) * 0.1)
                        let rayWidth: CGFloat = 25 + CGFloat(sin(time + Double(i) * 0.3)) * 10
                        
                        let endX = center.x + CGFloat(cos(angle)) * rayLength
                        let endY = center.y + CGFloat(sin(angle)) * rayLength
                        
                        var ray = Path()
                        ray.move(to: center)
                        ray.addLine(to: CGPoint(x: endX, y: endY))
                        
                        let rayOpacity = (0.03 + sin(time * 0.8 + Double(i)) * 0.02) * progress
                        let rayColor = Color(
                            red: 0.8 * (1 - colorBlend) + 0.1 * colorBlend,
                            green: 0.8 * (1 - colorBlend) + 0.7 * colorBlend,
                            blue: 0.8 * (1 - colorBlend) + 0.85 * colorBlend
                        )
                        context.stroke(ray, with: .color(rayColor.opacity(rayOpacity)), lineWidth: rayWidth)
                    }
                }
                .blur(radius: 30)
                
                // Animated energy arcs behind the figure
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height * 0.38)
                    let colorBlend = min(1.0, max(0, (progress - 0.3) / 0.5))
                    
                    // Draw flowing arc lines emanating from center
                    let arcCount = 10
                    for i in 0..<arcCount {
                        let arcProgress = min(1.0, max(0, (progress - 0.1 - Double(i) * 0.025) * 2.2))
                        if arcProgress > 0 {
                            let baseAngle = Double(i) * (.pi / Double(arcCount)) - .pi / 2
                            let wobble = sin(time * 1.8 + Double(i)) * 0.06
                            let startAngle = baseAngle - 0.45 + wobble
                            let endAngle = baseAngle + 0.45 + wobble
                            let radius: CGFloat = 100 + CGFloat(i) * 20
                            
                            var arc = Path()
                            arc.addArc(center: center, radius: radius * CGFloat(arcProgress),
                                       startAngle: .radians(startAngle), endAngle: .radians(endAngle), clockwise: false)
                            
                            let opacity = 0.2 + 0.3 * arcProgress - Double(i) * 0.02
                            let arcColor = Color(
                                red: 0.6 * (1 - colorBlend) + 0.0 * colorBlend,
                                green: 0.6 * (1 - colorBlend) + 0.6 * colorBlend,
                                blue: 0.6 * (1 - colorBlend) + 0.75 * colorBlend
                            )
                            context.stroke(arc, with: .color(arcColor.opacity(opacity)), lineWidth: 2.5)
                        }
                    }
                    
                    // Lower arcs (mirrored)
                    for i in 0..<arcCount {
                        let arcProgress = min(1.0, max(0, (progress - 0.15 - Double(i) * 0.025) * 2.2))
                        if arcProgress > 0 {
                            let baseAngle = Double(i) * (.pi / Double(arcCount)) + .pi / 2
                            let wobble = sin(time * 1.4 + Double(i) + 2) * 0.06
                            let startAngle = baseAngle - 0.4 + wobble
                            let endAngle = baseAngle + 0.4 + wobble
                            let radius: CGFloat = 90 + CGFloat(i) * 18
                            
                            var arc = Path()
                            arc.addArc(center: center, radius: radius * CGFloat(arcProgress),
                                       startAngle: .radians(startAngle), endAngle: .radians(endAngle), clockwise: false)
                            
                            let opacity = 0.15 + 0.25 * arcProgress - Double(i) * 0.015
                            let arcColor = Color(
                                red: 0.6 * (1 - colorBlend) + 0.0 * colorBlend,
                                green: 0.6 * (1 - colorBlend) + 0.6 * colorBlend,
                                blue: 0.6 * (1 - colorBlend) + 0.75 * colorBlend
                            )
                            context.stroke(arc, with: .color(arcColor.opacity(opacity)), lineWidth: 2)
                        }
                    }
                    
                    // Particle sparkles
                    for i in 0..<20 {
                        let particleProgress = min(1.0, max(0, (progress - 0.2) * 2))
                        if particleProgress > 0 {
                            let angle = Double(i) * (2 * .pi / 20) + time * 0.3
                            let radius = 80 + CGFloat(i) * 12 + CGFloat(sin(time * 2 + Double(i))) * 20
                            let x = center.x + CGFloat(cos(angle)) * radius * CGFloat(particleProgress)
                            let y = center.y + CGFloat(sin(angle)) * radius * CGFloat(particleProgress)
                            let particleSize: CGFloat = 3 + CGFloat(sin(time * 3 + Double(i))) * 2
                            
                            context.fill(
                                Circle().path(in: CGRect(x: x - particleSize/2, y: y - particleSize/2, width: particleSize, height: particleSize)),
                                with: .color(glowBlue.opacity(0.4 * particleProgress))
                            )
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
            .drawingGroup() // Metal-accelerated rendering for 60fps
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

// MARK: - Final CTA View (04:30-05:00)
struct FinalCTAView: View {
    var progress: Double
    var isComplete: Bool
    
    private let accentTeal = Color(red: 0.0, green: 0.6, blue: 0.7)
    private let glowTeal = Color(red: 0.1, green: 0.8, blue: 0.9)
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            GeometryReader { geo in
                ZStack {
                    // Elegant light background
                    ZStack {
                        LinearGradient(
                            colors: [Color(white: 0.97), Color.white, Color(white: 0.98)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        // Soft moving orbs
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [accentTeal.opacity(0.12), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 350
                                )
                            )
                            .frame(width: 700, height: 700)
                            .offset(x: sin(time * 0.15) * 80 - 150, y: cos(time * 0.1) * 60 - 80)
                        
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.orange.opacity(0.08), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 250
                                )
                            )
                            .frame(width: 500, height: 500)
                            .offset(x: cos(time * 0.12) * 100 + 180, y: sin(time * 0.15) * 80 + 120)
                    }
                    
                    // Animated network of connections (visual aid: interconnectedness)
                    Canvas { context, size in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        
                        // Create a network of people icons (visual aid for "people who matter")
                        let peopleCount = 12
                        var peoplePositions: [CGPoint] = []
                        
                        for i in 0..<peopleCount {
                            let angle = Double(i) * (2 * .pi / Double(peopleCount)) + time * 0.05
                            let radius: CGFloat = 180 + CGFloat(i % 3) * 40
                            let x = center.x + CGFloat(cos(angle)) * radius
                            let y = center.y + CGFloat(sin(angle)) * radius * 0.5 - 20
                            peoplePositions.append(CGPoint(x: x, y: y))
                            
                            // Draw connection lines to center (work returning to people)
                            if progress > 0.3 {
                                let lineProgress = min(1.0, (progress - 0.3 - Double(i) * 0.02) * 3)
                                if lineProgress > 0 {
                                    var line = Path()
                                    line.move(to: center)
                                    let endX = center.x + (x - center.x) * CGFloat(lineProgress)
                                    let endY = center.y + (y - center.y) * CGFloat(lineProgress)
                                    line.addLine(to: CGPoint(x: endX, y: endY))
                                    
                                    context.stroke(line, with: .color(accentTeal.opacity(0.15 * lineProgress)), lineWidth: 1)
                                    
                                    // Pulse traveling outward
                                    let pulseT = fmod(time * 0.8 + Double(i) * 0.15, 1.0)
                                    let pulseX = center.x + (x - center.x) * CGFloat(pulseT)
                                    let pulseY = center.y + (y - center.y) * CGFloat(pulseT)
                                    
                                    context.fill(
                                        Circle().path(in: CGRect(x: pulseX - 3, y: pulseY - 3, width: 6, height: 6)),
                                        with: .color(glowTeal.opacity(0.5 * (1 - pulseT)))
                                    )
                                }
                            }
                            
                            // Draw people dots (appear sequentially)
                            if progress > 0.4 {
                                let dotProgress = min(1.0, (progress - 0.4 - Double(i) * 0.015) * 4)
                                if dotProgress > 0 {
                                    // Glow
                                    context.fill(
                                        Circle().path(in: CGRect(x: x - 12, y: y - 12, width: 24, height: 24)),
                                        with: .color(accentTeal.opacity(0.1 * dotProgress))
                                    )
                                    // Core dot
                                    context.fill(
                                        Circle().path(in: CGRect(x: x - 5, y: y - 5, width: 10, height: 10)),
                                        with: .color(accentTeal.opacity(0.6 * dotProgress))
                                    )
                                }
                            }
                        }
                        
                        // Connect people to each other (community/organization)
                        if progress > 0.5 {
                            for i in 0..<peoplePositions.count {
                                let next = (i + 1) % peoplePositions.count
                                let p1 = peoplePositions[i]
                                let p2 = peoplePositions[next]
                                
                                var line = Path()
                                line.move(to: p1)
                                line.addLine(to: p2)
                                
                                let connectionProgress = min(1.0, (progress - 0.5 - Double(i) * 0.01) * 3)
                                context.stroke(line, with: .color(accentTeal.opacity(0.08 * connectionProgress)), lineWidth: 0.5)
                            }
                        }
                        
                        // Central glow (representing the organization/value)
                        let centerGlow = min(1.0, progress / 0.3) * (1.0 + sin(time * 2) * 0.1)
                        context.fill(
                            Circle().path(in: CGRect(x: center.x - 60, y: center.y - 60, width: 120, height: 120)),
                            with: .radialGradient(
                                Gradient(colors: [accentTeal.opacity(0.2 * centerGlow), .clear]),
                                center: center, startRadius: 0, endRadius: 60
                            )
                        )
                    }
                    
                    VStack(spacing: 40) {
                        Spacer()
                        
                        // Visual aid: Transformation icon
                        ZStack {
                            // Outer ring
                            Circle()
                                .stroke(accentTeal.opacity(0.2), lineWidth: 2)
                                .frame(width: 100, height: 100)
                                .scaleEffect(1.0 + sin(time * 1.5) * 0.05)
                            
                            // Inner icon representing transformation
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [accentTeal, glowTeal],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .rotationEffect(.degrees(time * 10))
                        }
                        .opacity(progress > 0.05 ? 1 : 0)
                        .scaleEffect(progress > 0.05 ? 1.0 : 0.5)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress > 0.05)
                        
                        // Main message
                        VStack(spacing: 16) {
                            Text("Agentic automation returns invisible work")
                                .font(.system(size: 28, weight: .light, design: .serif))
                                .foregroundColor(.black.opacity(0.85))
                                .opacity(progress > 0.15 ? 1 : 0)
                                .offset(y: progress > 0.15 ? 0 : 30)
                                .animation(.spring(response: 0.9, dampingFraction: 0.8), value: progress > 0.15)
                            
                            Text("to the people who matter.")
                                .font(.system(size: 28, weight: .semibold, design: .serif))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [accentTeal.opacity(0.9), accentTeal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .opacity(progress > 0.25 ? 1 : 0)
                                .offset(y: progress > 0.25 ? 0 : 30)
                                .scaleEffect(progress > 0.25 ? 1.0 : 0.95)
                                .animation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.1), value: progress > 0.25)
                        }
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        
                        // Visual separator line
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, accentTeal.opacity(0.3), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 200, height: 1)
                            .opacity(progress > 0.4 ? 1 : 0)
                            .animation(.easeOut(duration: 0.6), value: progress > 0.4)
                        
                        // Question
                        Text("What could your organization become?")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.gray)
                            .opacity(progress > 0.45 ? 1 : 0)
                            .offset(y: progress > 0.45 ? 0 : 15)
                            .animation(.easeOut(duration: 0.6).delay(0.1), value: progress > 0.45)
                        
                        Spacer()
                            .frame(height: 30)
                        
                        // Vision Pro callout (NOT a button - just elegant display)
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "visionpro")
                                    .font(.system(size: 28, weight: .light))
                                    .foregroundColor(accentTeal)
                                
                                Text("Experience the full immersion")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            
                            Text("VISION PRO")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(6)
                                .foregroundColor(accentTeal.opacity(0.6))
                        }
                        .padding(.vertical, 25)
                        .padding(.horizontal, 45)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.8))
                                .shadow(color: accentTeal.opacity(0.15), radius: 25, y: 10)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(accentTeal.opacity(0.2), lineWidth: 1)
                        )
                        .opacity(progress > 0.6 || isComplete ? 1 : 0)
                        .offset(y: progress > 0.6 || isComplete ? 0 : 20)
                        .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.15), value: progress > 0.6)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 50)
                }
                .drawingGroup() // Metal-accelerated rendering for 60fps
            }
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

