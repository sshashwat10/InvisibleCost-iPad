import SwiftUI
import Foundation

// MARK: - Narrator Frame Animation (00:07-00:37)
struct NarratorFrameAnimation: View {
    var progress: Double
    @Environment(MotionManager.self) private var motion
    @State private var notifications: [Int] = (0..<25).map { _ in Int.random(in: 0...1000) }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                
                // Redundant windows distributed across the ENTIRE screen (not just center)
                ZStack {
                    ForEach(0..<notifications.count, id: \.self) { i in
                        WorkWindowView(index: i)
                            .frame(width: CGFloat.random(in: 250...400), height: CGFloat.random(in: 200...300))
                            // Start wide across the whole screen, then drift
                            .offset(
                                x: CGFloat(sin(Double(i) * 1.7) * (geo.size.width * 0.6)) + CGFloat(motion.roll * 40),
                                y: CGFloat(cos(Double(i) * 1.3) * (geo.size.height * 0.6)) + CGFloat(motion.pitch * 40)
                            )
                            .scaleEffect(0.6 + progress * 0.4)
                            .opacity(0.4 + (1.0 - progress) * 0.6)
                    }
                }
                .drawingGroup()
                
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
                    VStack(spacing: 10) {
                        Text("You made 247 decisions today.")
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                            .foregroundColor(.red.opacity(0.8))
                        Text("142 were unnecessary.")
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                            .foregroundColor(.red)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
    
    var body: some View {
        ZStack {
            Color.black
            
            // Abstract emotional flashes for Finance, Supply Chain, Healthcare
            Group {
                if progress < 0.33 {
                    VignetteContent(title: "FINANCE", subtitle: "Reconciliation Fatigue", icon: "chart.bar.xaxis")
                } else if progress < 0.66 {
                    VignetteContent(title: "SUPPLY CHAIN", subtitle: "Inventory Friction", icon: "shippingbox")
                } else {
                    VignetteContent(title: "HEALTHCARE", subtitle: "Administrative Burden", icon: "cross.case")
                }
            }
            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 1.1)), 
                                  removal: .opacity.combined(with: .scale(scale: 0.9))))
            .animation(.easeInOut(duration: 1.0), value: progress)
        }
    }
}

struct VignetteContent: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.6))
            
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .default))
                .tracking(8)
                .foregroundColor(.white.opacity(0.8))
            
            Text(subtitle)
                .font(.system(size: 32, weight: .light, design: .serif))
                .italic()
                .foregroundColor(.white)
        }
    }
}

// MARK: - Pattern Break View (01:15-01:45)
struct PatternBreakView: View {
    var progress: Double
    
    var body: some View {
        ZStack {
            Color.white
            
            Text("What if this work... wasn't your work?")
                .font(.system(size: 52, weight: .light, design: .serif))
                .foregroundColor(.black)
                .opacity(progress > 0.05 ? 1 : 0) // 1.5s beat at start
                .scaleEffect(progress > 0.05 ? 1.0 : 0.95)
                .animation(.easeOut(duration: 2.0).delay(1.5), value: progress)
        }
    }
}

// MARK: - Agentic Orchestration (01:45-02:45)
struct AgenticOrchestrationAnimation: View {
    var progress: Double
    @Environment(MotionManager.self) private var motion
    @State private var particles = (0..<120).map { i in 
        (pos: CGPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1)), 
         id: i) 
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                
                // Clutter (Windows) collapsing into Clarity (Particles/Blue Glow)
                ZStack {
                    ForEach(particles, id: \.id) { particle in
                        Group {
                            if progress < 0.6 {
                                // The "Clutter" Windows
                                WorkWindowView(index: particle.id)
                                    .frame(width: 150, height: 100)
                                    .scaleEffect(1.0 - progress)
                                    .opacity(0.8 * (1.0 - progress * 1.6))
                                    .offset(x: CGFloat(motion.roll * 20), y: CGFloat(motion.pitch * 20))
                            }
                            
                            // The "Clarity" Particles (Wow factor: Glow + Parallax)
                            Circle()
                                .fill(progress > 0.4 ? Color.blue : Color.white.opacity(0.6))
                                .frame(width: progress > 0.5 ? 6 : 3, height: progress > 0.5 ? 6 : 3)
                        }
                        .position(
                            x: lerp(start: particle.pos.x * geo.size.width + CGFloat(motion.roll * 50), 
                                    end: geo.size.width/2 + CGFloat(sin(Double(particle.id) + progress * 10) * 50 * (1-progress)), 
                                    t: progress),
                            y: lerp(start: particle.pos.y * geo.size.height + CGFloat(motion.pitch * 50), 
                                    end: geo.size.height/2 + CGFloat(cos(Double(particle.id) + progress * 10) * 50 * (1-progress)), 
                                    t: progress)
                        )
                    }
                }
                .drawingGroup() // Mandatory for 120+ particles at 60fps
                
                // Central "Clarity" Ring (Refined: Pulsing Core)
                if progress > 0.4 {
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                            .frame(width: 250 * progress, height: 250 * progress)
                        
                        Circle()
                            .fill(RadialGradient(colors: [.blue.opacity(0.4), .clear], center: .center, startRadius: 0, endRadius: 100))
                            .frame(width: 300 * progress, height: 300 * progress)
                    }
                    .position(x: geo.size.width/2, y: geo.size.height/2)
                    .opacity((progress - 0.4) * 2.5)
                }
                
                if progress > 0.6 {
                    Text("AGENTIC ORCHESTRATION")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(10)
                        .foregroundColor(.blue)
                        .opacity((progress - 0.6) * 2.5)
                }
            }
        }
    }
    
    private func lerp(start: CGFloat, end: CGFloat, t: Double) -> CGFloat {
        start + (end - start) * CGFloat(t)
    }
}

// MARK: - Human Return (02:45-03:30)
struct HumanReturnAnimation: View {
    var progress: Double
    
    var body: some View {
        ZStack {
            Color.white
            
            VStack(spacing: 30) {
                Image(systemName: "person.and.arrow.left.and.arrow.right")
                    .font(.system(size: 100, weight: .ultraLight))
                    .foregroundColor(.blue.opacity(0.6))
                    .scaleEffect(0.7 + progress * 0.3)
                    // Removed rotationEffect per user request
                
                Text("RESTORATION")
                    .font(.system(size: 20, weight: .bold))
                    .tracking(12)
                    .foregroundColor(.gray)
                    .opacity(progress > 0.2 ? 1 : 0)
                
                VStack(spacing: 15) {
                    Text("Human potential returned.")
                        .font(.system(size: 40, weight: .light, design: .serif))
                        .foregroundColor(.black)
                        .offset(y: progress > 0.3 ? 0 : 20)
                    
                    Text("Reviewing insights. Approving paths.")
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(.blue)
                        .opacity(progress > 0.6 ? 1 : 0)
                        .offset(y: progress > 0.6 ? 0 : 10)
                }
                .opacity(progress > 0.3 ? 1 : 0)
            }
            .scaleEffect(0.9 + progress * 0.1)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
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
            
            VStack(spacing: 60) {
                // 1.5-second white pause handled by opacity check (30s phase * 0.05 = 1.5s)
                VStack(spacing: 20) {
                    Text("Agentic automation returns invisible work to the people who matter.")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
                    Text("What could your organization become with invisible work returned?")
                        .font(.system(size: 24, weight: .regular, design: .default))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .opacity(progress > 0.05 ? 1 : 0) 
                .animation(.easeIn(duration: 2.0).delay(1.5), value: progress)
                
                if progress > 0.5 || isComplete {
                    VStack(spacing: 15) {
                        Text("WANT THE IMMERSIVE VERSION?")
                            .font(.caption)
                            .tracking(4)
                            .foregroundColor(.blue)
                        
                        Text("Ask for the Vision Pro demo.")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: progress)
                }
            }
            .padding(100)
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

