import SwiftUI
import CoreMotion

@Observable
class MotionManager {
    private let motionManager = CMMotionManager()
    var roll: Double = 0
    var pitch: Double = 0
    
    init() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let motion = motion else { return }
                self?.roll = motion.attitude.roll
                self?.pitch = motion.attitude.pitch
            }
        }
    }
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}

