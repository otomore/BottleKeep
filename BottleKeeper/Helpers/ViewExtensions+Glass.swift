import SwiftUI
import Foundation

/// DateFormatterの共有インスタンスを提供
/// パフォーマンス最適化: DateFormatterの生成は重い処理のため、静的インスタンスを再利用
extension DateFormatter {
    /// ボトル関連の日付フォーマッター（中形式、時刻なし、日本語）
    static let bottleDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()

    /// 短い日付フォーマッター（年/月/日）
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()

    /// 日時フォーマッター（日付＋時刻）
    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}

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

    /// 枠線なしのシンプルなガラスエフェクト（洗練されたデザイン用）
    func subtleGlassEffect(
        tint: Color? = nil,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self
            .background {
                ZStack {
                    // 1. 背景ブラー
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // 2. ティント色（半透明）
                    if let tint = tint {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(tint.opacity(0.08))
                    }

                    // 3. 微妙な光沢グラデーション
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.15), location: 0.0),
                            .init(color: Color.white.opacity(0.03), location: 0.5),
                            .init(color: Color.clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
            }
            // 枠線なし - よりクリーンなデザイン
            // シャドウのみで深さを表現
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
}
