import SwiftUI

// MARK: - Emotional Intro View
/// 15-second snappy emotional intro that establishes context before interaction
/// Implements the "Weight Before the Choice" concept - TIGHTENED for impact
///
/// Timeline (15 seconds total):
/// - 0-5%: Quick fade from darkness
/// - 5-20%: Work windows appear and overwhelm
/// - 20-50%: First narration ("Every organization carries a hidden cost")
/// - 50-80%: Second narration ("Most leaders never see it")
/// - 80-100%: Quick warm transition to industry selection

struct EmotionalIntroView: View {
    let progress: Double
    @Environment(MotionManager.self) private var motion

    // State for window positions (generated once)
    @State private var windowStates: [FloatingWindowState] = []
    @State private var particleSeeds: [Double] = []

    // Animation phase calculations - TIGHTENED for snappier feel
    private var darkToPresencePhase: Double { min(1.0, progress / 0.05) }           // 0-0.75s
    private var overwhelmPhase: Double { max(0, min(1.0, (progress - 0.05) / 0.15)) } // 0.75-3s
    private var weightPhase: Double { max(0, min(1.0, (progress - 0.20) / 0.30)) }    // 3-7.5s
    private var recognitionPhase: Double { max(0, min(1.0, (progress - 0.50) / 0.30)) } // 7.5-12s
    private var invitationPhase: Double { max(0, min(1.0, (progress - 0.80) / 0.20)) } // 12-15s

    // Colors
    private let voidBlack = Color(red: 0.02, green: 0.02, blue: 0.04)
    private let coolBlue = Color(red: 0.15, green: 0.2, blue: 0.35)
    private let warmGold = Color(red: 0.95, green: 0.8, blue: 0.4)

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            GeometryReader { geo in
                ZStack {
                    // Background gradient - shifts from cold to warm
                    backgroundLayer(time: time)

                    // Particle field
                    particleLayer(time: time, size: geo.size)

                    // Floating work windows
                    windowsLayer(time: time, size: geo.size)

                    // Vignette overlay
                    vignetteLayer(size: geo.size)

                    // Scan lines for documentary feel
                    scanLinesLayer(time: time, size: geo.size)

                    // Text content
                    textContentLayer(time: time)
                }
            }
        }
        .onAppear {
            initializeAnimationState()
        }
    }

    // MARK: - Background Layer

    private func backgroundLayer(time: Double) -> some View {
        let warmth = invitationPhase * 0.3

        return ZStack {
            // Base darkness
            voidBlack.ignoresSafeArea()

            // Cool undertone during weight phase
            if weightPhase > 0 && invitationPhase < 1 {
                RadialGradient(
                    colors: [
                        coolBlue.opacity(0.15 * weightPhase * (1 - invitationPhase)),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 600
                )
                .ignoresSafeArea()
            }

            // Warm glow during invitation phase
            if invitationPhase > 0 {
                RadialGradient(
                    colors: [
                        warmGold.opacity(0.2 * invitationPhase),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
                .scaleEffect(1.0 + sin(time * 0.5) * 0.1)
            }
        }
    }

    // MARK: - Particle Layer

    private func particleLayer(time: Double, size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let particleCount = 60
            let emergenceProgress = darkToPresencePhase
            let heavinessProgress = weightPhase * 0.5 // Particles slow down
            let organizationProgress = invitationPhase // Particles organize

            for i in 0..<particleCount {
                let seed = particleSeeds.count > i ? particleSeeds[i] : Double(i) * 1.618

                // Base movement speed slows during weight phase
                let baseSpeed = 0.15 - heavinessProgress * 0.08

                // Position calculation
                var x: CGFloat
                var y: CGFloat

                if organizationProgress > 0 {
                    // During invitation, particles organize toward center
                    let targetX = canvasSize.width / 2 + CGFloat(cos(seed * 2.5)) * 100
                    let targetY = canvasSize.height / 2 + CGFloat(sin(seed * 1.8)) * 80
                    let chaosX = (sin(time * baseSpeed + seed * 2) * 0.5 + 0.5) * canvasSize.width
                    let chaosY = (cos(time * baseSpeed * 0.7 + seed * 1.5) * 0.5 + 0.5) * canvasSize.height
                    x = chaosX + (targetX - chaosX) * CGFloat(organizationProgress)
                    y = chaosY + (targetY - chaosY) * CGFloat(organizationProgress)
                } else {
                    x = (sin(time * baseSpeed + seed * 2) * 0.5 + 0.5) * canvasSize.width
                    y = (cos(time * baseSpeed * 0.7 + seed * 1.5) * 0.5 + 0.5) * canvasSize.height
                }

                // Pulse animation
                let pulse = sin(time * 2 + seed) * 0.5 + 0.5
                let particleSize: CGFloat = 1.5 + CGFloat(pulse) * 2.5

                // Opacity based on emergence
                let baseOpacity = 0.05 + pulse * 0.1
                let opacity = baseOpacity * emergenceProgress

                // Color shifts during invitation
                let color: Color
                if invitationPhase > 0 {
                    color = Color(
                        red: 0.95 * invitationPhase + 1.0 * (1 - invitationPhase),
                        green: 0.8 * invitationPhase + 1.0 * (1 - invitationPhase),
                        blue: 0.4 * invitationPhase + 1.0 * (1 - invitationPhase)
                    )
                } else {
                    color = .white
                }

                context.fill(
                    Circle().path(in: CGRect(
                        x: x - particleSize / 2,
                        y: y - particleSize / 2,
                        width: particleSize,
                        height: particleSize
                    )),
                    with: .color(color.opacity(opacity))
                )
            }
        }
    }

    // MARK: - Floating Windows Layer

    private func windowsLayer(time: Double, size: CGSize) -> some View {
        ZStack {
            ForEach(windowStates) { state in
                FloatingWorkWindow(
                    windowState: state,
                    time: time,
                    motion: motion,
                    overwhelmPhase: overwhelmPhase,
                    weightPhase: weightPhase,
                    recognitionPhase: recognitionPhase,
                    invitationPhase: invitationPhase
                )
            }
        }
        .drawingGroup()
    }

    // MARK: - Vignette Layer

    private func vignetteLayer(size: CGSize) -> some View {
        RadialGradient(
            colors: [
                .clear,
                voidBlack.opacity(0.5 + weightPhase * 0.3)
            ],
            center: .center,
            startRadius: size.width * 0.25,
            endRadius: size.width * 0.7
        )
    }

    // MARK: - Scan Lines Layer

    private func scanLinesLayer(time: Double, size: CGSize) -> some View {
        Canvas { context, canvasSize in
            // Only show scan lines during overwhelm and weight phases
            let scanOpacity = overwhelmPhase * (1 - invitationPhase) * 0.03

            if scanOpacity > 0.001 {
                for line in stride(from: 0, to: canvasSize.height, by: 4) {
                    let lineOpacity = scanOpacity + sin(time * 0.5 + line * 0.01) * 0.01
                    context.stroke(
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: line))
                            p.addLine(to: CGPoint(x: canvasSize.width, y: line))
                        },
                        with: .color(Color.white.opacity(lineOpacity)),
                        lineWidth: 0.5
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Text Content Layer

    private func textContentLayer(time: Double) -> some View {
        VStack(spacing: 40) {
            Spacer()

            // First narration text: "Every organization carries a hidden cost."
            ZStack {
                // Glow
                Text("Every organization carries a hidden cost.")
                    .font(.system(size: 36, design: .rounded).weight(.light))
                    .foregroundColor(.white.opacity(0.15))
                    .blur(radius: 20)

                // Main text
                Text("Every organization carries a hidden cost.")
                    .font(.system(size: 36, design: .rounded).weight(.light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .white.opacity(0.3), radius: 15)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 60)
            .opacity(weightPhase > 0 ? min(1.0, weightPhase * 2) : 0)
            .offset(y: weightPhase > 0 ? 0 : 30)
            .animation(.easeOut(duration: 0.8), value: weightPhase > 0)

            // Second narration text: "Most leaders never see it."
            ZStack {
                // Red undertone glow
                Text("Most leaders never see it.")
                    .font(.system(size: 36, design: .rounded).weight(.medium))
                    .foregroundColor(Color.red.opacity(0.25))
                    .blur(radius: 25)

                // Main text
                Text("Most leaders never see it.")
                    .font(.system(size: 36, design: .rounded).weight(.medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(red: 1, green: 0.92, blue: 0.92)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.red.opacity(0.35), radius: 20)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 60)
            .opacity(recognitionPhase > 0 ? min(1.0, recognitionPhase * 2) : 0)
            .offset(y: recognitionPhase > 0 ? 0 : 30)
            .animation(.easeOut(duration: 0.8), value: recognitionPhase > 0)

            // Transition text: "Let's make it visible."
            if invitationPhase > 0.3 {
                Text("Let's make it visible.")
                    .font(.system(size: 28, design: .rounded).weight(.light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [warmGold, .white],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: warmGold.opacity(0.5), radius: 15)
                    .opacity(min(1.0, (invitationPhase - 0.3) * 2))
                    .scaleEffect(0.9 + invitationPhase * 0.1)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Skip Button Layer

    // MARK: - Initialization

    private func initializeAnimationState() {
        // Generate window states if not already done
        if windowStates.isEmpty {
            windowStates = (0..<18).map { i in
                FloatingWindowState(
                    id: i,
                    position: CGPoint(
                        x: CGFloat.random(in: 0.1...0.9),
                        y: CGFloat.random(in: 0.1...0.9)
                    ),
                    size: CGSize(
                        width: CGFloat.random(in: 180...320),
                        height: CGFloat.random(in: 120...220)
                    ),
                    windowType: WorkWindowType.allCases.randomElement() ?? .spreadsheet,
                    seed: Double.random(in: 0...100)
                )
            }
        }

        // Generate particle seeds
        if particleSeeds.isEmpty {
            particleSeeds = (0..<60).map { _ in Double.random(in: 0...100) }
        }
    }
}

// MARK: - Floating Window State

struct FloatingWindowState: Identifiable {
    let id: Int
    let position: CGPoint   // Normalized 0-1
    let size: CGSize
    let windowType: WorkWindowType
    let seed: Double
}

// MARK: - Work Window Types

enum WorkWindowType: CaseIterable {
    case spreadsheet
    case email
    case dashboard
    case calendar
    case form
}

// MARK: - Floating Work Window

struct FloatingWorkWindow: View {
    let windowState: FloatingWindowState
    let time: Double
    let motion: MotionManager
    let overwhelmPhase: Double
    let weightPhase: Double
    let recognitionPhase: Double
    let invitationPhase: Double

    private var windowOpacity: Double {
        // Fade in during overwhelm, stay during weight, fade during recognition
        let fadeIn = min(1.0, overwhelmPhase * 1.5)
        let fadeOut = max(0.1, 1.0 - recognitionPhase * 0.7)
        let dissolve = max(0, 1.0 - invitationPhase * 1.5)
        return fadeIn * fadeOut * dissolve * 0.6
    }

    private var weightOffset: CGFloat {
        // Windows press down during weight phase
        CGFloat(weightPhase * 30)
    }

    var body: some View {
        GeometryReader { geo in
            let baseX = geo.size.width * windowState.position.x
            let baseY = geo.size.height * windowState.position.y

            // Parallax from device motion
            let parallaxX = CGFloat(motion.roll * Double(windowState.id % 10 + 3))
            let parallaxY = CGFloat(motion.pitch * Double(windowState.id % 10 + 3))

            // Floating animation
            let floatX = CGFloat(sin(time * 0.25 + windowState.seed)) * 8
            let floatY = CGFloat(cos(time * 0.2 + windowState.seed * 0.7)) * 6

            // Dissolution direction during invitation (float upward)
            let dissolutionY = -invitationPhase * 100

            WorkWindowContent(windowType: windowState.windowType, seed: windowState.seed)
                .frame(width: windowState.size.width, height: windowState.size.height)
                .position(
                    x: baseX + parallaxX + floatX,
                    y: baseY + parallaxY + floatY + weightOffset + CGFloat(dissolutionY)
                )
                .opacity(windowOpacity)
                .rotation3DEffect(
                    .degrees(sin(time * 0.4 + windowState.seed * 0.3) * 3),
                    axis: (x: 1, y: 0, z: 0)
                )
                .blur(radius: invitationPhase * 8)
        }
    }
}

// MARK: - Work Window Content

struct WorkWindowContent: View {
    let windowType: WorkWindowType
    let seed: Double

    private let windowBg = Color(red: 0.12, green: 0.12, blue: 0.15)
    private let accentBlue = Color(red: 0.3, green: 0.5, blue: 0.8)

    var body: some View {
        VStack(spacing: 0) {
            // Window header
            HStack {
                Circle().fill(Color.red.opacity(0.6)).frame(width: 8, height: 8)
                Circle().fill(Color.yellow.opacity(0.6)).frame(width: 8, height: 8)
                Circle().fill(Color.green.opacity(0.6)).frame(width: 8, height: 8)
                Spacer()
                Text(windowTitle)
                    .font(.system(size: 10, design: .rounded).weight(.medium))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))

            // Window content
            windowContent
                .padding(10)
        }
        .background(windowBg.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 15, y: 5)
    }

    private var windowTitle: String {
        switch windowType {
        case .spreadsheet: return "Financial Report Q4.xlsx"
        case .email: return "Inbox (147 unread)"
        case .dashboard: return "Operations Dashboard"
        case .calendar: return "Calendar - Today"
        case .form: return "Expense Report Form"
        }
    }

    @ViewBuilder
    private var windowContent: some View {
        switch windowType {
        case .spreadsheet:
            spreadsheetContent
        case .email:
            emailContent
        case .dashboard:
            dashboardContent
        case .calendar:
            calendarContent
        case .form:
            formContent
        }
    }

    private var spreadsheetContent: some View {
        VStack(spacing: 2) {
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { col in
                        Rectangle()
                            .fill(col == 0 ? accentBlue.opacity(0.2) : Color.white.opacity(0.05))
                            .frame(height: 14)
                    }
                }
            }
        }
    }

    private var emailContent: some View {
        VStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { _ in
                HStack {
                    Circle()
                        .fill(accentBlue.opacity(0.3))
                        .frame(width: 20, height: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 80, height: 6)
                    }
                    Spacer()
                }
            }
        }
    }

    private var dashboardContent: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(accentBlue.opacity(0.15))
                        .frame(height: 40)
                }
            }
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
            }
        }
    }

    private var calendarContent: some View {
        VStack(spacing: 4) {
            HStack {
                ForEach(["M", "T", "W", "T", "F"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 8, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { col in
                        Rectangle()
                            .fill(
                                (row == 1 && col == 2) ? accentBlue.opacity(0.4) : Color.white.opacity(0.05)
                            )
                            .frame(height: 20)
                    }
                }
            }
        }
    }

    private var formContent: some View {
        VStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { _ in
                HStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 60, height: 8)
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EmotionalIntroView(progress: 0.5)
        .environment(MotionManager())
}
