import Foundation
import CoreMotion
import Combine

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var roll: Double = 0.0  // 横の傾き（-π ~ π）
    @Published var pitch: Double = 0.0 // 前後の傾き（-π ~ π）

    init() {
        startMotionUpdates()
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available")
            return
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0 // 30 Hz
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }

            DispatchQueue.main.async {
                self?.roll = motion.attitude.roll
                self?.pitch = motion.attitude.pitch
            }
        }
    }

    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }

    deinit {
        stopMotionUpdates()
    }
}
