import Foundation
import CoreMotion
import Combine

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()

    // 傾き
    @Published var roll: Double = 0.0  // 横の傾き（-π ~ π）
    @Published var pitch: Double = 0.0 // 前後の傾き（-π ~ π）

    // 加速度（揺れの検知用）
    @Published var accelerationMagnitude: Double = 0.0

    // 物理シミュレーション用の内部状態
    private var targetRoll: Double = 0.0
    private var currentRoll: Double = 0.0
    private var rollVelocity: Double = 0.0

    private var timer: Timer?

    // 物理パラメータ
    private let stiffness: Double = 180.0  // バネの強さ
    private let damping: Double = 12.0     // 減衰
    private let mass: Double = 1.0         // 質量

    init() {
        startMotionUpdates()
        startPhysicsSimulation()
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available")
            return
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }
            guard let self = self else { return }

            // 傾きの目標値を更新
            self.targetRoll = motion.attitude.roll
            self.pitch = motion.attitude.pitch

            // 加速度の大きさを計算（揺れの検知用）
            let userAccel = motion.userAcceleration
            let magnitude = sqrt(
                userAccel.x * userAccel.x +
                userAccel.y * userAccel.y +
                userAccel.z * userAccel.z
            )

            DispatchQueue.main.async {
                self.accelerationMagnitude = magnitude
            }
        }
    }

    private func startPhysicsSimulation() {
        // 60 FPSで物理シミュレーションを実行
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updatePhysics()
        }
    }

    private func updatePhysics() {
        let dt = 1.0 / 60.0 // タイムステップ

        // スプリング物理演算（フックの法則 + 減衰）
        let displacement = targetRoll - currentRoll
        let springForce = stiffness * displacement
        let dampingForce = -damping * rollVelocity
        let acceleration = (springForce + dampingForce) / mass

        // 速度と位置を更新
        rollVelocity += acceleration * dt
        currentRoll += rollVelocity * dt

        // 公開値を更新
        DispatchQueue.main.async { [weak self] in
            self?.roll = self?.currentRoll ?? 0.0
        }
    }

    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stopMotionUpdates()
    }
}
