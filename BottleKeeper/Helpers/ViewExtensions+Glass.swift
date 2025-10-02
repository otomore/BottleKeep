import SwiftUI

/// Glassmorphism（Liquid Glass）スタイルのエフェクトを提供する拡張
///
/// Glassmorphismの主要な特性:
/// 1. 半透明性（Translucency）- 背景が透けて見える
/// 2. 背景ブラー（Background Blur）- フロストガラス効果
/// 3. 境界線（Stroke）- 深さと厚みを強調する微妙なボーダー
/// 4. グラデーション（Gradient）- 光の反射を模倣
extension View {
    /// 真のGlassmorphismエフェクトを適用
    /// - Parameters:
    ///   - tint: ティント色（オプション）
    ///   - cornerRadius: 角丸の半径
    func adaptiveGlassEffect(
        tint: Color? = nil,
        cornerRadius: CGFloat = 12
    ) -> some View {
        self
            .background {
                ZStack {
                    // 1. 背景ブラー（frosted glass effect）
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // 2. ティント色（半透明）
                    if let tint = tint {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(tint.opacity(0.1))
                    }

                    // 3. 光沢グラデーション（上部が明るく、下部が暗い）
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.25), location: 0.0),
                            .init(color: Color.white.opacity(0.05), location: 0.5),
                            .init(color: Color.clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
            }
            // 4. 境界線（重要！Glassmorphismの特徴）
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            // 5. 柔らかい影（浮遊効果）
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    /// プライマリガラスエフェクト（青色ティント）
    func primaryGlassEffect() -> some View {
        adaptiveGlassEffect(tint: .blue)
    }

    /// セカンダリガラスエフェクト（ニュートラル）
    func secondaryGlassEffect() -> some View {
        adaptiveGlassEffect(tint: nil)
    }

    /// アクセントガラスエフェクト（琥珀色ティント - ウイスキーテーマ）
    func accentGlassEffect() -> some View {
        adaptiveGlassEffect(tint: Color(red: 0.8, green: 0.5, blue: 0.2))
    }
}
