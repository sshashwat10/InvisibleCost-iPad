import SwiftUI
import Foundation

// MARK: - Narrator Frame Animation (00:07-00:37)
struct NarratorFrameAnimation: View {
    var progress: Double
    @State private var notifications: [Int] = Array(0..<20)
    
    var body: some View {
        ZStack {
            Color.black
            
            // Abstract overlapping windows and notifications
            ForEach(notifications, id: \.self) { i in
                NotificationShape()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    .frame(width: 250, height: 180)
                    .offset(x: CGFloat(sin(Double(i) * 0.5 + progress * 2) * 300),
                            y: CGFloat(cos(Double(i) * 0.3 + progress * 3) * 400))
                    .scaleEffect(0.5 + progress * 0.5)
                    .opacity(0.2 + (1.0 - progress) * 0.3)
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
    @State private var particles = (0..<100).map { _ in CGPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1)) }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                
                // Chaos collapsing into clarity
                ForEach(0..<particles.count, id: \.self) { i in
                    Circle()
                        .fill(progress > 0.5 ? Color.blue.opacity(0.8) : Color.white.opacity(0.4))
                        .frame(width: progress > 0.5 ? 6 : 3, height: progress > 0.5 ? 6 : 3)
                        .position(
                            x: lerp(start: particles[i].x * geo.size.width, end: geo.size.width/2 + CGFloat(sin(Double(i) + progress * 10) * 50 * (1-progress)), t: progress),
                            y: lerp(start: particles[i].y * geo.size.height, end: geo.size.height/2 + CGFloat(cos(Double(i) + progress * 10) * 50 * (1-progress)), t: progress)
                        )
                        .blur(radius: (1.0 - progress) * 2)
                        .opacity(progress > 0.9 ? (1.0 - progress) * 10 : 1)
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
                    .foregroundColor(.blue.opacity(0.4))
                    .scaleEffect(0.8 + progress * 0.2)
                
                Text("RESTORATION")
                    .font(.system(size: 20, weight: .bold))
                    .tracking(12)
                    .foregroundColor(.gray)
                
                VStack(spacing: 15) {
                    Text("Human potential returned.")
                        .font(.system(size: 40, weight: .light, design: .serif))
                        .foregroundColor(.black)
                    
                    Text("Reviewing insights. Approving paths.")
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(.blue)
                        .opacity(progress > 0.5 ? 1 : 0)
                }
            }
            .opacity(progress * 2)
        }
    }
}

// MARK: - Personalization View (03:30-04:30)
struct PersonalizationView: View {
    @Bindable var viewModel: ExperienceViewModel
    
    var body: some View {
        VStack(spacing: 50) {
            Text("How many hours of invisible work does your team lose each week?")
                .font(.system(size: 34, weight: .light, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 80)
            
            VStack(spacing: 10) {
                Text("\(Int(viewModel.lostHoursPerWeek)) hours")
                    .font(.system(size: 90, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                
                Slider(value: $viewModel.lostHoursPerWeek, in: 0...100, step: 1)
                    .tint(.blue)
                    .padding(.horizontal, 150)
            }
            
            HStack(spacing: 60) {
                MetricView(label: "TEAM SIZE", value: "\(Int(viewModel.teamSize))", color: .gray)
                MetricView(label: "ANNUAL IMPACT", value: "$\(formatLargeNumber(viewModel.annualImpact))", color: .green)
            }
            .padding(.top, 40)
            
            Text("Premium simplicity for VIP interaction.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
        }
        .padding()
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

struct NotificationShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 12, height: 12))
        return path
    }
}

