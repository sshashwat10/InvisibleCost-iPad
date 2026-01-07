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
                                .font(.custom("Outfit", size: 38).weight(.light))
                                .foregroundColor(.white.opacity(0.15))
                                .blur(radius: 20)
                            
                            Text("Every organization carries a hidden cost.")
                                .font(.custom("Outfit", size: 38).weight(.light))
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
                                .font(.custom("Outfit", size: 38).weight(.medium))
                                .foregroundColor(Color.red.opacity(0.3))
                                .blur(radius: 25)
                            
                            Text("Most leaders never see it.")
                                .font(.custom("Outfit", size: 38).weight(.medium))
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
                                        .font(.custom("Outfit", size: 22).weight(.ultraLight))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("247")
                                        .font(.custom("Outfit", size: 28).weight(.light))
                                        .foregroundColor(.white)
                                    
                                    Text("decisions today.")
                                        .font(.custom("Outfit", size: 22).weight(.ultraLight))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                // Dramatic red stat
                                HStack(spacing: 8) {
                                    Text("142")
                                        .font(.custom("Outfit", size: 48).weight(.medium))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color(red: 1.0, green: 0.4, blue: 0.4), Color(red: 1.0, green: 0.2, blue: 0.2)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(color: Color.red.opacity(0.5), radius: 15)
                                    
                                    Text("were unnecessary")
                                        .font(.custom("Outfit", size: 24).weight(.light))
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
                                        .font(.custom("Outfit", size: 13).weight(.light))
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
                                .font(.custom("Outfit", size: 100).weight(.thin))
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
                    .font(.custom("Outfit", size: 18).weight(.medium))
                    .tracking(16)
                    .foregroundColor(theme.accent.opacity(0.3))
                    .blur(radius: 10)
                
                Text(title)
                    .font(.custom("Outfit", size: 18).weight(.medium))
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
                    .font(.custom("Outfit", size: 32).weight(.ultraLight))
                    .italic()
                    .foregroundColor(.white.opacity(0.2))
                    .blur(radius: 15)
                
                Text(subtitle)
                    .font(.custom("Outfit", size: 32).weight(.ultraLight))
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
                .font(.custom("Outfit", size: 24).weight(.light))
                .foregroundColor(theme.accent)
                .shadow(color: theme.primary.opacity(0.3), radius: 4)
            Text(label)
                .font(.custom("Outfit", size: 11).weight(.light))
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
                                .font(.custom("Outfit", size: 44).weight(.ultraLight))
                                .foregroundColor(.black)
                                .opacity(progress > 0.15 ? 1 : 0)
                                .offset(y: progress > 0.15 ? 0 : 25)
                                .blur(radius: progress > 0.15 ? 0 : 8)
                            
                            Text("wasn't your work?")
                                .font(.custom("Outfit", size: 44).weight(.light))
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
/// INTERCONNECTED NODES: A 3D rotating sphere of connected nodes
/// Points appear, connect to nearby neighbors, form a mesh network
struct AgenticOrchestrationAnimation: View {
    var progress: Double
    @Environment(MotionManager.self) private var motion
    
    // Smooth fade-out at the end for seamless transition
    private var exitFade: Double {
        progress > 0.90 ? 1.0 - ((progress - 0.90) / 0.10) : 1.0  // Fade out last 10%
    }
    
    // Teal color palette - clean and techy
    private let primaryTeal = Color(red: 0.0, green: 0.6, blue: 0.7)
    private let glowTeal = Color(red: 0.1, green: 0.8, blue: 0.9)
    private let darkTeal = Color(red: 0.0, green: 0.35, blue: 0.45)
    
    // Gold/Electric colors for dramatic text
    private let coreGold = Color(red: 1.0, green: 0.85, blue: 0.4)
    private let electricBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    private let hotWhite = Color.white
    
    // 3D sphere points (distributed on a sphere using golden spiral)
    private let spherePoints: [(theta: Double, phi: Double)] = {
        var points: [(Double, Double)] = []
        let n = 32 // Number of points
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
            
            // Animation phases with smoother easing
            let pointsAppear = min(1.0, progress / 0.25)        // 0-25%: points appear
            let connectPhase = min(1.0, max(0, (progress - 0.20) / 0.25)) // 20-45%: connections
            let pulsePhase = min(1.0, max(0, (progress - 0.40) / 0.20))   // 40-60%: pulse
            
            // Smoother shrink: longer duration with easeInOut curve
            let shrinkRaw = min(1.0, max(0, (progress - 0.50) / 0.25))  // 50-75%: shrink (longer)
            let shrinkPhase = shrinkRaw * shrinkRaw * (3 - 2 * shrinkRaw) // smoothstep easing
            
            // Text appears after shrink is well underway
            let textRaw = min(1.0, max(0, (progress - 0.65) / 0.20))    // 65-85%: text (delayed)
            let textPhase = textRaw * textRaw * (3 - 2 * textRaw) // smoothstep easing
            
            // Sphere scale with gentler curve
            let sphereScale = 1.0 - shrinkPhase * 0.5
            let sphereOffsetY = shrinkPhase * -100
            let sphereOpacity = 1.0 - shrinkPhase * 0.5 // fade less so glow is visible
            
            // Intensify glow as sphere shrinks (power-up effect)
            let shrinkGlow = shrinkPhase * 0.6  // Extra glow intensity during shrink
            
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Ambient background particles
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
                
                // 3D SPHERE with interconnected nodes
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2 + CGFloat(sphereOffsetY))
                    let baseRadius: CGFloat = min(size.width, size.height) * 0.30
                    let sphereRadius = baseRadius * CGFloat(sphereScale)
                    
                    // Apply opacity for smooth fade
                    context.opacity = sphereOpacity
                    
                    // Rotation for 3D effect
                    let rotationY = time * 0.2
                    let rotationX = sin(time * 0.1) * 0.2
                    
                    // Calculate 3D positions
                    var screenPoints: [(pos: CGPoint, z: Double, visible: Bool)] = []
                    
                    for (i, point) in spherePoints.enumerated() {
                        let pointProgress = min(1.0, max(0, (pointsAppear * Double(spherePoints.count) - Double(i)) * 1.5))
                        
                        if pointProgress > 0 {
                            var x3d = sin(point.phi) * cos(point.theta + rotationY)
                            var y3d = cos(point.phi)
                            var z3d = sin(point.phi) * sin(point.theta + rotationY)
                            
                            // Apply X rotation
                            let y3dRotated = y3d * cos(rotationX) - z3d * sin(rotationX)
                            let z3dRotated = y3d * sin(rotationX) + z3d * cos(rotationX)
                            y3d = y3dRotated
                            z3d = z3dRotated
                            
                            // Project to 2D
                            let perspective = 1.0 + z3d * 0.3
                            let screenX = center.x + CGFloat(x3d * Double(sphereRadius) * perspective)
                            let screenY = center.y + CGFloat(y3d * Double(sphereRadius) * perspective * 0.9)
                            
                            screenPoints.append((CGPoint(x: screenX, y: screenY), z3d, pointProgress > 0.5))
                        } else {
                            screenPoints.append((.zero, 0, false))
                        }
                    }
                    
                    // Outer glow - intensifies as sphere shrinks (power-up effect)
                    let baseGlowIntensity = 0.2 + pulsePhase * 0.15 + shrinkGlow
                    let glowRadius = sphereRadius * (1.6 + shrinkGlow * 1.5)  // Glow expands as it shrinks
                    
                    // Primary glow
                    context.fill(
                        Circle().path(in: CGRect(x: center.x - glowRadius, y: center.y - glowRadius,
                                                  width: glowRadius * 2, height: glowRadius * 2)),
                        with: .radialGradient(
                            Gradient(colors: [glowTeal.opacity(baseGlowIntensity), primaryTeal.opacity(baseGlowIntensity * 0.5), .clear]),
                            center: center, startRadius: 0, endRadius: glowRadius
                        )
                    )
                    
                    // Extra bright core glow when shrinking
                    if shrinkGlow > 0.1 {
                        let coreGlowRadius = sphereRadius * 0.8
                        let coreIntensity = shrinkGlow * 1.2
                        context.fill(
                            Circle().path(in: CGRect(x: center.x - coreGlowRadius, y: center.y - coreGlowRadius,
                                                      width: coreGlowRadius * 2, height: coreGlowRadius * 2)),
                            with: .radialGradient(
                                Gradient(colors: [Color.white.opacity(coreIntensity * 0.5), glowTeal.opacity(coreIntensity), .clear]),
                                center: center, startRadius: 0, endRadius: coreGlowRadius
                            )
                        )
                    }
                    
                    // Draw connections between nearby points (mesh network)
                    if connectPhase > 0 {
                        for i in 0..<screenPoints.count {
                            guard screenPoints[i].visible else { continue }
                            
                            for j in (i+1)..<screenPoints.count {
                                guard screenPoints[j].visible else { continue }
                                
                                let p1 = screenPoints[i]
                                let p2 = screenPoints[j]
                                let dist = hypot(p2.pos.x - p1.pos.x, p2.pos.y - p1.pos.y)
                                
                                // Connect nearby points
                                let maxDist = sphereRadius * 0.6
                                if dist < maxDist {
                                    let connectionIndex = Double(i + j) / Double(spherePoints.count * 2)
                                    let connProgress = min(1.0, max(0, (connectPhase - connectionIndex * 0.5) * 2.5))
                                    
                                    if connProgress > 0 {
                                        var line = Path()
                                        line.move(to: p1.pos)
                                        
                                        let endX = p1.pos.x + (p2.pos.x - p1.pos.x) * CGFloat(connProgress)
                                        let endY = p1.pos.y + (p2.pos.y - p1.pos.y) * CGFloat(connProgress)
                                        line.addLine(to: CGPoint(x: endX, y: endY))
                                        
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
                    
                    // Draw nodes
                    for (i, point) in screenPoints.enumerated() {
                        guard point.visible else { continue }
                        
                        let pointProgress = min(1.0, max(0, (pointsAppear * Double(spherePoints.count) - Double(i)) * 1.5))
                        let depth = (point.z + 1) / 2
                        let baseSize: CGFloat = 4 + CGFloat(depth) * 4
                        let nodeSize = baseSize * CGFloat(pointProgress)
                        
                        // Glow
                        let nodeGlowSize = nodeSize * (1.5 + CGFloat(pulsePhase) * 0.5)
                        context.fill(
                            Circle().path(in: CGRect(x: point.pos.x - nodeGlowSize, y: point.pos.y - nodeGlowSize,
                                                      width: nodeGlowSize * 2, height: nodeGlowSize * 2)),
                            with: .color(glowTeal.opacity((0.15 + pulsePhase * 0.1) * (0.5 + depth * 0.5)))
                        )
                        
                        // Core
                        context.fill(
                            Circle().path(in: CGRect(x: point.pos.x - nodeSize / 2, y: point.pos.y - nodeSize / 2,
                                                      width: nodeSize, height: nodeSize)),
                            with: .color(glowTeal.opacity(0.7 + depth * 0.3))
                        )
                        
                        // Pulse center
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
                    
                    // Central core
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
                
                // ═══════════════════════════════════════════════════════════════
                // DRAMATIC TEXT - "AGENTIC ORCHESTRATION" with gold power
                // ═══════════════════════════════════════════════════════════════
                if textPhase > 0 {
                    VStack(spacing: 12) {
                        Spacer()
                        
                        // Main title with epic reveal - loads in dramatically
                        ZStack {
                            // Outer glow layer
                            Text("AGENTIC ORCHESTRATION")
                                .font(.custom("Outfit", size: 32).weight(.medium))
                                .tracking(8)
                                .foregroundColor(coreGold.opacity(0.3))
                                .blur(radius: 20)
                            
                            // Mid glow
                            Text("AGENTIC ORCHESTRATION")
                                .font(.custom("Outfit", size: 32).weight(.medium))
                                .tracking(8)
                                .foregroundColor(electricBlue.opacity(0.5))
                                .blur(radius: 10)
                            
                            // Main text with gradient
                            Text("AGENTIC ORCHESTRATION")
                                .font(.custom("Outfit", size: 32).weight(.medium))
                                .tracking(8)
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
                        .scaleEffect(0.95 + textPhase * 0.05)
                        .offset(y: (1 - textPhase) * 20)

                        // Tagline - appears slightly after main text
                        let taglinePhase = min(1.0, max(0, (textPhase - 0.4) / 0.6))
                        Text("Intelligence that orchestrates. Agents that deliver.")
                            .font(.custom("Outfit", size: 16).weight(.ultraLight))
                            .foregroundColor(.white.opacity(0.7))
                            .opacity(taglinePhase)
                            .offset(y: (1 - taglinePhase) * 15)
                        
                        Spacer()
                            .frame(height: 80)
                    }
                }
            }
            .drawingGroup()
        }
        .opacity(exitFade)
    }
}

// MARK: - Human Return (02:45-03:30)
/// Original animation with teal/blue arcs, particles, and figure
struct HumanReturnAnimation: View {
    var progress: Double
    
    // Smooth fade-in at the start for seamless transition
    private var entranceFade: Double {
        min(1.0, progress / 0.08) // Fade in over first 8% of phase
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            HumanReturnContent(progress: progress, time: timeline.date.timeIntervalSinceReferenceDate)
        }
        .opacity(entranceFade)
    }
}

// Extracted to help compiler
private struct HumanReturnContent: View {
    let progress: Double
    let time: Double
    
    // Colors - teal/cyan theme
    private let accentBlue = Color(red: 0.0, green: 0.6, blue: 0.75)
    private let glowBlue = Color(red: 0.1, green: 0.7, blue: 0.85)
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background gradient (bottom layer)
                backgroundView
                
                // Light rays (under everything)
                lightRaysView(size: geo.size)
                    .zIndex(0)
                
                // Energy arcs (under figure and text)
                arcsView(size: geo.size)
                    .zIndex(1)
                
                // Central figure and text (on top of everything)
                figureView(size: geo.size)
                    .zIndex(10)
            }
        }
        .drawingGroup()
    }
    
    private var backgroundView: some View {
        // Smooth eased progress for background transition
        let easedProgress = progress * progress * (3 - 2 * progress) // smoothstep
        
        return LinearGradient(
            colors: [
                Color(white: 0.02 + 0.96 * easedProgress),
                Color(white: 0.04 + 0.94 * easedProgress),
                Color(white: 0.06 + 0.92 * easedProgress)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private func lightRaysView(size: CGSize) -> some View {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.35)
        
        return Canvas { context, _ in
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
                context.stroke(ray, with: .color(glowBlue.opacity(rayOpacity)), lineWidth: rayWidth)
            }
        }
        .blur(radius: 30)
    }
    
    private func arcsView(size: CGSize) -> some View {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.38)
        
        return Canvas { context, _ in
            // Upper arcs
            for i in 0..<10 {
                let arcProgress = min(1.0, max(0, (progress - 0.1 - Double(i) * 0.025) * 2.2))
                if arcProgress > 0 {
                    let baseAngle = Double(i) * (.pi / 10) - .pi / 2
                    let wobble = sin(time * 1.8 + Double(i)) * 0.06
                    let startAngle = baseAngle - 0.45 + wobble
                    let endAngle = baseAngle + 0.45 + wobble
                    let radius: CGFloat = 100 + CGFloat(i) * 20
                    
                    var arc = Path()
                    arc.addArc(center: center, radius: radius * CGFloat(arcProgress),
                               startAngle: .radians(startAngle), endAngle: .radians(endAngle), clockwise: false)
                    
                    let opacity = 0.2 + 0.3 * arcProgress - Double(i) * 0.02
                    context.stroke(arc, with: .color(accentBlue.opacity(opacity)), lineWidth: 2.5)
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
    }
    
    private func figureView(size: CGSize) -> some View {
        // Smoothstep easing function for natural motion
        func smoothstep(_ t: Double) -> Double {
            let clamped = min(1.0, max(0, t))
            return clamped * clamped * (3 - 2 * clamped)
        }
        
        // Image fades in gradually starting at 15% progress
        let imageRaw = min(1.0, max(0, (progress - 0.15) / 0.35))  // 15-50%: image fades in
        let imageOpacity = smoothstep(imageRaw)
        let imageScale = 0.85 + imageOpacity * 0.15  // Subtle scale from 0.85 to 1.0
        
        // Text fades in after image
        let labelRaw = min(1.0, max(0, (progress - 0.25) / 0.25))  // 25-50%: label
        let labelOpacity = smoothstep(labelRaw)
        
        let titleRaw = min(1.0, max(0, (progress - 0.35) / 0.25))  // 35-60%: title
        let titleOpacity = smoothstep(titleRaw)
        
        let subtitleRaw = min(1.0, max(0, (progress - 0.55) / 0.25))  // 55-80%: subtitle
        let subtitleOpacity = smoothstep(subtitleRaw)
        
        return VStack(spacing: 0) {
            // Human figure - smooth fade in
            if let uiImage = UIImage(named: "leader") ?? loadBundleImage("leader") {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 250)
                    .scaleEffect(imageScale)
                    .opacity(imageOpacity)
            }
            
            Spacer().frame(height: 50)
            
            // Text - staggered fade in
            VStack(spacing: 16) {
                Text("RESTORATION")
                    .font(.custom("Outfit", size: 13).weight(.medium))
                    .tracking(10)
                    .foregroundColor(accentBlue)
                    .opacity(labelOpacity)
                    .offset(y: (1 - labelOpacity) * 10)
                
                Text("Human potential returned.")
                    .font(.custom("Outfit", size: 32).weight(.ultraLight))
                    .foregroundColor(Color(white: 1.0 - progress * 0.85))
                    .opacity(titleOpacity)
                    .offset(y: (1 - titleOpacity) * 15)
                
                Text("Reviewing insights. Approving paths.")
                    .font(.custom("Outfit", size: 18).weight(.light))
                    .foregroundColor(glowBlue)
                    .opacity(subtitleOpacity)
                    .offset(y: (1 - subtitleOpacity) * 10)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.bottom, 70)
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
                            .font(.custom("Outfit", size: 32).weight(.ultraLight))
                            .foregroundColor(accentBlue.opacity(0.3))
                            .blur(radius: 15)
                        
                        Text("How many hours of invisible work does your team lose each week?")
                            .font(.custom("Outfit", size: 32).weight(.ultraLight))
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
                                        .font(.custom("Outfit", size: 100).weight(.ultraLight))
                                        .foregroundColor(accentBlue.opacity(0.3))
                                        .blur(radius: 20)
                                    
                                    Text("\(Int(viewModel.lostHoursPerWeek))")
                                        .font(.custom("Outfit", size: 100).weight(.ultraLight))
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
                                    .font(.custom("Outfit", size: 14).weight(.medium))
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
                .font(.custom("Outfit", size: 12).weight(.medium))
                .tracking(5)
                .foregroundColor(.white.opacity(0.4))
            
            ZStack {
                Text(value)
                    .font(.custom("Outfit", size: 32).weight(.light))
                    .foregroundColor(color.opacity(0.3))
                    .blur(radius: 8)
                
                Text(value)
                    .font(.custom("Outfit", size: 32).weight(.light))
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
    
    var body: some View {
        TimelineView(.animation) { timeline in
            FinalCTAContent(progress: progress, time: timeline.date.timeIntervalSinceReferenceDate)
        }
    }
}

// Extracted to help compiler
private struct FinalCTAContent: View {
    let progress: Double
    let time: Double
    
    // Colors
    private let signalGold = Color(red: 0.95, green: 0.8, blue: 0.4)
    private let pureWhite = Color.white
    private let voidBlack = Color(red: 0.02, green: 0.02, blue: 0.04)
    
    // Computed phases
    private var pulsePhase: Double { min(1.0, progress / 0.20) }
    private var text1Phase: Double { min(1.0, max(0, (progress - 0.15) / 0.20)) }
    private var text2Phase: Double { min(1.0, max(0, (progress - 0.30) / 0.20)) }
    private var questionPhase: Double { min(1.0, max(0, (progress - 0.45) / 0.20)) }
    private var ctaPhase: Double { min(1.0, max(0, (progress - 0.60) / 0.25)) }
    
    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let centerY = geo.size.height * 0.35
            
            ZStack {
                // Background
                voidBlack.ignoresSafeArea()
                
                // Signal pulses
                signalLayer(centerX: centerX, centerY: centerY)
                
                // Text and CTAs
                contentLayer(geo: geo)
            }
        }
        .drawingGroup()
    }
    
    private func signalLayer(centerX: CGFloat, centerY: CGFloat) -> some View {
        Canvas { context, _ in
            let center = CGPoint(x: centerX, y: centerY)
            
            // Pulse rings
            for ring in 0..<4 {
                let ringDelay = Double(ring) * 0.25
                let pulseT = fmod(time * 0.4 + ringDelay, 1.0)
                let ringRadius = 20 + CGFloat(pulseT) * 200
                let ringOpacity = (1 - pulseT) * pulsePhase * 0.3
                
                var ringPath = Path()
                ringPath.addEllipse(in: CGRect(x: center.x - ringRadius, y: center.y - ringRadius,
                                               width: ringRadius * 2, height: ringRadius * 2))
                context.stroke(ringPath, with: .color(signalGold.opacity(ringOpacity)), lineWidth: 1.5)
            }
            
            // Central beacon
            let beaconSize: CGFloat = 10
            context.fill(
                Circle().path(in: CGRect(x: center.x - 30, y: center.y - 30, width: 60, height: 60)),
                with: .radialGradient(
                    Gradient(colors: [signalGold.opacity(0.3 * pulsePhase), .clear]),
                    center: center, startRadius: 0, endRadius: 30
                )
            )
            context.fill(
                Circle().path(in: CGRect(x: center.x - beaconSize/2, y: center.y - beaconSize/2,
                                         width: beaconSize, height: beaconSize)),
                with: .color(signalGold.opacity(pulsePhase))
            )
        }
    }
    
    private func contentLayer(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer().frame(height: geo.size.height * 0.48)
            
            textSection
            
            Spacer().frame(height: 50)
            
            ctaSection
            
            Spacer()
        }
        .padding(.horizontal, 50)
    }
    
    @ViewBuilder
    private var textSection: some View {
        VStack(spacing: 24) {
            if text1Phase > 0 {
                Text("One decision.")
                    .font(.custom("Outfit", size: 28).weight(.ultraLight))
                    .foregroundColor(pureWhite.opacity(0.9))
                    .opacity(text1Phase)
            }
            
            if text2Phase > 0 {
                Text("Infinite possibility.")
                    .font(.custom("Outfit", size: 34).weight(.light))
                    .foregroundStyle(LinearGradient(colors: [signalGold, pureWhite], startPoint: .leading, endPoint: .trailing))
                    .opacity(text2Phase)
            }
            
            if questionPhase > 0 {
                Rectangle()
                    .fill(signalGold.opacity(0.3))
                    .frame(width: 60, height: 1)
                    .opacity(questionPhase)
                    .padding(.vertical, 8)
                
                Text("Where will you lead?")
                    .font(.custom("Outfit", size: 18).weight(.light))
                    .foregroundColor(pureWhite.opacity(0.6))
                    .opacity(questionPhase)
            }
        }
        .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    private var ctaSection: some View {
        if ctaPhase > 0 {
            HStack(spacing: 40) {
                // Vision Pro
                visionProCTA
                
                // Demo
                demoCTA
            }
            .opacity(ctaPhase)
            .offset(y: (1 - ctaPhase) * 20)
        }
    }
    
    private var visionProCTA: some View {
        VStack(spacing: 10) {
            Image(systemName: "visionpro")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(pureWhite.opacity(0.8))
            
            Text("EXPERIENCE")
                .font(.custom("Outfit", size: 10).weight(.medium))
                .tracking(4)
                .foregroundColor(pureWhite.opacity(0.5))
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
        .background(RoundedRectangle(cornerRadius: 16).stroke(pureWhite.opacity(0.2), lineWidth: 1))
    }
    
    private var demoCTA: some View {
        Button(action: { print("🎯 Live Demo requested") }) {
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
                    .font(.custom("Outfit", size: 10).weight(.medium))
                    .tracking(4)
                    .foregroundColor(signalGold.opacity(0.8))
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 30)
            .background(RoundedRectangle(cornerRadius: 16).stroke(signalGold.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
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

/// Elegant human silhouette - professional business figure
struct HumanSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        
        // Head - slightly oval, professional proportion
        let headRadius = w * 0.22
        let headCenterY = rect.minY + headRadius * 1.1
        path.addEllipse(in: CGRect(
            x: cx - headRadius,
            y: headCenterY - headRadius,
            width: headRadius * 2,
            height: headRadius * 2.1
        ))
        
        // Neck
        let neckTop = headCenterY + headRadius * 1.05
        let neckWidth = w * 0.12
        
        // Shoulders and body - smooth professional silhouette
        let shoulderY = neckTop + h * 0.06
        let shoulderWidth = w * 0.48
        let waistY = shoulderY + h * 0.28
        let waistWidth = w * 0.28
        let hipY = waistY + h * 0.08
        let hipWidth = w * 0.32
        let bottomY = rect.maxY
        
        // Right side of body
        path.move(to: CGPoint(x: cx + neckWidth, y: neckTop))
        
        // Right shoulder curve
        path.addQuadCurve(
            to: CGPoint(x: cx + shoulderWidth, y: shoulderY + h * 0.05),
            control: CGPoint(x: cx + shoulderWidth * 0.7, y: shoulderY - h * 0.02)
        )
        
        // Right arm hint (slight inward curve at waist level)
        path.addQuadCurve(
            to: CGPoint(x: cx + waistWidth, y: waistY),
            control: CGPoint(x: cx + shoulderWidth * 0.95, y: waistY - h * 0.1)
        )
        
        // Right hip
        path.addQuadCurve(
            to: CGPoint(x: cx + hipWidth, y: hipY),
            control: CGPoint(x: cx + waistWidth * 0.9, y: hipY - h * 0.02)
        )
        
        // Right leg - elegant taper
        path.addQuadCurve(
            to: CGPoint(x: cx + w * 0.12, y: bottomY),
            control: CGPoint(x: cx + hipWidth * 0.8, y: bottomY - h * 0.1)
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: cx - w * 0.12, y: bottomY))
        
        // Left leg
        path.addQuadCurve(
            to: CGPoint(x: cx - hipWidth, y: hipY),
            control: CGPoint(x: cx - hipWidth * 0.8, y: bottomY - h * 0.1)
        )
        
        // Left hip
        path.addQuadCurve(
            to: CGPoint(x: cx - waistWidth, y: waistY),
            control: CGPoint(x: cx - waistWidth * 0.9, y: hipY - h * 0.02)
        )
        
        // Left arm hint
        path.addQuadCurve(
            to: CGPoint(x: cx - shoulderWidth, y: shoulderY + h * 0.05),
            control: CGPoint(x: cx - shoulderWidth * 0.95, y: waistY - h * 0.1)
        )
        
        // Left shoulder curve
        path.addQuadCurve(
            to: CGPoint(x: cx - neckWidth, y: neckTop),
            control: CGPoint(x: cx - shoulderWidth * 0.7, y: shoulderY - h * 0.02)
        )
        
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Bundle Image Helper
/// Loads an image from the app bundle (for images not in Asset Catalog)
private func loadBundleImage(_ name: String) -> UIImage? {
    // Try common image extensions
    let extensions = ["jpg", "jpeg", "png"]
    for ext in extensions {
        if let path = Bundle.main.path(forResource: name, ofType: ext),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
    }
    return nil
}

// MARK: - Automation Anywhere Simple Reveal
/// Clean, elegant logo reveal with subtle halo
/// Simple fade in/out with minimal effects
struct AutomationAnywhereRevealAnimation: View {
    var progress: Double

    // Brand colors
    private let brandOrange = Color(red: 1.0, green: 0.5, blue: 0.1)
    private let brandGold = Color(red: 1.0, green: 0.75, blue: 0.3)

    // Smoothstep for smooth transitions
    private func smoothstep(_ t: Double) -> Double {
        let clamped = min(1.0, max(0, t))
        return clamped * clamped * (3 - 2 * clamped)
    }

    // Logo fades in cleanly from 5% to 25%
    private var logoOpacity: Double {
        smoothstep(min(1.0, max(0, (progress - 0.05) / 0.20)))
    }

    // Subtle background halo - fades with logo
    private var haloOpacity: Double {
        let fadeIn = smoothstep(min(1.0, max(0, (progress - 0.05) / 0.25)))
        let fadeOut = progress > 0.75 ? smoothstep(1.0 - (progress - 0.75) / 0.25) : 1.0
        return fadeIn * fadeOut * 0.3
    }

    // Tagline fades in smoothly from 50% to 65%
    private var textOpacity: Double {
        smoothstep(min(1.0, max(0, (progress - 0.50) / 0.15)))
    }

    // Exit fade over last 10% - delayed to hold longer on screen
    private var exitFade: Double {
        progress > 0.90 ? smoothstep(1.0 - (progress - 0.90) / 0.10) : 1.0
    }

    var body: some View {
        ZStack {
            // Black background
            Color.black.ignoresSafeArea()

            // Subtle halo glow behind logo
            RadialGradient(
                colors: [
                    brandOrange.opacity(haloOpacity * 0.4),
                    brandGold.opacity(haloOpacity * 0.2),
                    .clear
                ],
                center: .center,
                startRadius: 80,
                endRadius: 400
            )
            .blur(radius: 80)

            // Logo and text
            VStack(spacing: 40) {
                // Logo - clean fade in, no blur overlay
                if let logoImage = loadBundleImage("logo") {
                    Image(uiImage: logoImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300)
                        .opacity(logoOpacity * exitFade)
                } else {
                    // Fallback text logo
                    VStack(spacing: 6) {
                        Text("AUTOMATION")
                            .font(.custom("Outfit", size: 38).weight(.light))
                            .tracking(6)
                        Text("ANYWHERE")
                            .font(.custom("Outfit", size: 38).weight(.semibold))
                            .tracking(6)
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [brandOrange, brandGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(logoOpacity * exitFade)
                }

                // Tagline - "Agentic AI without BS." matching website style
                HStack(spacing: 0) {
                    Text("Agentic AI ")
                        .font(.custom("Outfit", size: 32).weight(.bold))
                        .foregroundColor(brandOrange)
                    Text("without BS.")
                        .font(.custom("Outfit", size: 32).weight(.medium))
                        .foregroundColor(.white)
                }
                .opacity(textOpacity * exitFade)
                .offset(y: (1 - textOpacity) * 10) // Subtle slide up as it fades in
            }
        }
    }
}

