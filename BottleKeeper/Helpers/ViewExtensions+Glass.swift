import SwiftUI

/// Liquid Glassスタイルのエフェクトを提供する拡張
/// 現在はフォールバック実装（.ultraThinMaterial）を使用
extension View {
    /// アダプティブガラスエフェクトを適用
    /// - Parameters:
    ///   - tint: ティント色（オプション）
    ///   - interactive: インタラクティブモード（将来の拡張用）
    func adaptiveGlassEffect(
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        self
            .background {
                ZStack {
                    // 背景ブラー
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)

                    // ティント色
                    if let tint = tint {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(tint.opacity(0.15))
                    }

                    // 光沢効果
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear,
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    /// プライマリガラスエフェクト（青色）
    func primaryGlassEffect() -> some View {
        adaptiveGlassEffect(tint: .blue.opacity(0.3))
    }

    /// セカンダリガラスエフェクト（グレー）
    func secondaryGlassEffect() -> some View {
        adaptiveGlassEffect(tint: .gray.opacity(0.2))
    }

    /// アクセントガラスエフェクト（ブラウン）
    func accentGlassEffect() -> some View {
        adaptiveGlassEffect(tint: .brown.opacity(0.25), interactive: true)
    }
}
