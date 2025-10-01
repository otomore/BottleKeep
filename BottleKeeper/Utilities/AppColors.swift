import SwiftUI

/// アプリ全体で使用するカラーシステム
struct AppColors {
    // MARK: - Liquid Colors (ウイスキーの液体色)

    /// ライトモード用のウイスキー液体色
    static let whiskyLiquidLight = [
        Color(red: 0.6, green: 0.4, blue: 0.2), // 濃い茶色
        Color(red: 0.8, green: 0.6, blue: 0.3)  // 薄い茶色
    ]

    /// ダークモード用のウイスキー液体色（より明るく、視認性向上）
    static let whiskyLiquidDark = [
        Color(red: 0.75, green: 0.55, blue: 0.35), // 濃い茶色（明るめ）
        Color(red: 0.9, green: 0.7, blue: 0.45)   // 薄い茶色（明るめ）
    ]

    /// 環境に応じた液体色を返す
    static func whiskyLiquid(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? whiskyLiquidDark : whiskyLiquidLight
    }

    // MARK: - Bottle Colors

    /// ライトモード用のボトル輪郭色
    static let bottleOutlineLight = Color.brown.opacity(0.5)

    /// ダークモード用のボトル輪郭色
    static let bottleOutlineDark = Color.brown.opacity(0.7)

    /// 環境に応じたボトル輪郭色
    static func bottleOutline(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? bottleOutlineDark : bottleOutlineLight
    }

    /// ライトモード用のボトル背景色
    static let bottleBackgroundLight = Color.brown.opacity(0.1)

    /// ダークモード用のボトル背景色
    static let bottleBackgroundDark = Color.brown.opacity(0.2)

    /// 環境に応じたボトル背景色
    static func bottleBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? bottleBackgroundDark : bottleBackgroundLight
    }

    // MARK: - Status Colors (残量ステータス色)

    /// 残量ステータスに応じた色
    static func remainingStatusColor(for percentage: Double, colorScheme: ColorScheme) -> Color {
        let baseColor = remainingColor(for: percentage)

        // ダークモードではやや明るく
        return colorScheme == .dark ? baseColor.opacity(0.9) : baseColor
    }

    /// 残量パーセンテージに応じた基本色（共通ロジック）
    static func remainingColor(for percentage: Double) -> Color {
        switch percentage {
        case 50...100:
            return .green
        case 20..<50:
            return .orange
        default:
            return .red
        }
    }

    /// プログレスバーの色（BottleDetailView用）
    static func progressColor(for percentage: Double) -> Color {
        remainingColor(for: percentage)
    }

    // MARK: - Chart Colors

    /// チャート用のカラーパレット（ライトモード）
    static let chartColorsLight: [Color] = [
        .blue,
        .green,
        .orange,
        .purple,
        .pink,
        .yellow,
        .cyan,
        .indigo
    ]

    /// チャート用のカラーパレット（ダークモード）
    static let chartColorsDark: [Color] = [
        Color.blue.opacity(0.8),
        Color.green.opacity(0.8),
        Color.orange.opacity(0.8),
        Color.purple.opacity(0.8),
        Color.pink.opacity(0.8),
        Color.yellow.opacity(0.8),
        Color.cyan.opacity(0.8),
        Color.indigo.opacity(0.8)
    ]

    /// 環境に応じたチャートカラー
    static func chartColors(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? chartColorsDark : chartColorsLight
    }

    // MARK: - Background Colors

    /// カード背景色
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(.systemGray6)
            : Color(.systemBackground)
    }

    /// セカンダリ背景色
    static func secondaryBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(.systemGray5)
            : Color(.secondarySystemBackground)
    }

    // MARK: - Text Colors

    /// プライマリテキスト色（基本的にはシステムのものを使用）
    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .black
    }

    /// セカンダリテキスト色
    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(.systemGray)
            : Color(.secondaryLabel)
    }
}

// MARK: - Color Extensions

extension Color {
    /// カラーの明度を調整
    func adjustBrightness(_ amount: Double) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return Color(
            red: min(red + amount, 1.0),
            green: min(green + amount, 1.0),
            blue: min(blue + amount, 1.0),
            opacity: Double(alpha)
        )
    }

    /// ダークモードに適した色を返す
    func adaptiveColor(for colorScheme: ColorScheme, brightnessAdjustment: Double = 0.2) -> Color {
        colorScheme == .dark ? adjustBrightness(brightnessAdjustment) : self
    }
}
