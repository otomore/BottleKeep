import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("selectedColorScheme") private var selectedColorScheme = "system"
    @AppStorage("accentColor") private var accentColorName = "default"
    @AppStorage("appIcon") private var selectedAppIcon = "default"
    @AppStorage("useCompactMode") private var useCompactMode = false
    @AppStorage("showBottlePhotos") private var showBottlePhotos = true
    @AppStorage("useLargeText") private var useLargeText = false
    @AppStorage("highContrastMode") private var highContrastMode = false

    @Environment(\.colorScheme) private var systemColorScheme

    private let accentColors: [(String, Color)] = [
        ("default", .accentColor),
        ("blue", .blue),
        ("green", .green),
        ("orange", .orange),
        ("red", .red),
        ("purple", .purple),
        ("pink", .pink),
        ("teal", .teal),
        ("brown", Color(red: 0.6, green: 0.4, blue: 0.2))  // ウイスキー色
    ]

    private let appIcons = [
        ("default", "BottleKeepIcon"),
        ("dark", "BottleKeepIcon-Dark"),
        ("vintage", "BottleKeepIcon-Vintage"),
        ("minimal", "BottleKeepIcon-Minimal")
    ]

    var body: some View {
        NavigationStack {
            List {
                // カラーテーマセクション
                colorSchemeSection

                // アクセントカラーセクション
                accentColorSection

                // アプリアイコンセクション
                appIconSection

                // レイアウト設定
                layoutSection

                // テキスト設定
                textSection

                // アクセシビリティ設定
                accessibilitySection

                // プレビューセクション
                previewSection
            }
            .navigationTitle("外観設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var colorSchemeSection: some View {
        Section {
            Picker("カラーテーマ", selection: $selectedColorScheme) {
                HStack {
                    Image(systemName: "iphone")
                    Text("システム設定に従う")
                }
                .tag("system")

                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                    Text("ライトモード")
                }
                .tag("light")

                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.indigo)
                    Text("ダークモード")
                }
                .tag("dark")
            }
            .pickerStyle(.navigationLink)
        } header: {
            Text("カラーテーマ")
        } footer: {
            Text("アプリの基本的な見た目を設定します。システム設定に従う場合、iOSの設定に合わせて自動的に変更されます。")
        }
    }

    @ViewBuilder
    private var accentColorSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(accentColors, id: \.0) { colorName, color in
                        Button {
                            accentColorName = colorName
                        } label: {
                            Circle()
                                .fill(color.gradient)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.primary, lineWidth: accentColorName == colorName ? 2 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            if accentColorName != "default" {
                Button("デフォルトに戻す") {
                    accentColorName = "default"
                }
                .foregroundColor(.secondary)
            }
        } header: {
            Text("アクセントカラー")
        } footer: {
            Text("アプリ内のボタンやハイライトに使用される色を設定します。")
        }
    }

    @ViewBuilder
    private var appIconSection: some View {
        Section {
            ForEach(appIcons, id: \.0) { iconName, iconImageName in
                HStack {
                    Image(iconImageName)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)

                    VStack(alignment: .leading) {
                        Text(iconDisplayName(iconName))
                            .font(.headline)
                        Text(iconDescription(iconName))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if selectedAppIcon == iconName {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedAppIcon = iconName
                    changeAppIcon(to: iconName)
                }
            }
        } header: {
            Text("アプリアイコン")
        } footer: {
            Text("ホーム画面に表示されるアプリアイコンを選択できます。")
        }
    }

    @ViewBuilder
    private var layoutSection: some View {
        Section {
            Toggle("コンパクトモード", isOn: $useCompactMode)
            Toggle("ボトル写真を表示", isOn: $showBottlePhotos)
        } header: {
            Text("レイアウト")
        } footer: {
            Text("コンパクトモードでは、リスト表示がより密になります。")
        }
    }

    @ViewBuilder
    private var textSection: some View {
        Section {
            Toggle("大きなテキスト", isOn: $useLargeText)
        } header: {
            Text("テキスト")
        } footer: {
            Text("アプリ全体でより大きなフォントサイズを使用します。")
        }
    }

    @ViewBuilder
    private var accessibilitySection: some View {
        Section {
            Toggle("高コントラストモード", isOn: $highContrastMode)

            NavigationLink("音声読み上げ設定") {
                VoiceOverSettingsView()
            }

            NavigationLink("ジェスチャー設定") {
                GestureSettingsView()
            }
        } header: {
            Text("アクセシビリティ")
        } footer: {
            Text("視覚的なアクセシビリティを向上させる設定です。")
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        Section {
            VStack(spacing: 16) {
                // ボトルカードのプレビュー
                BottlePreviewCard()

                // ボタンのプレビュー
                HStack {
                    Button("プライマリ") {}
                        .buttonStyle(.borderedProminent)
                    Button("セカンダリ") {}
                        .buttonStyle(.bordered)
                    Button("テキスト") {}
                        .buttonStyle(.plain)
                }

                // 統計カードのプレビュー
                StatisticPreviewCard()
            }
            .padding(.vertical)
        } header: {
            Text("プレビュー")
        } footer: {
            Text("現在の設定でのアプリの見た目を確認できます。")
        }
    }

    // MARK: - Helper Methods

    private func iconDisplayName(_ iconName: String) -> String {
        switch iconName {
        case "default":
            return "デフォルト"
        case "dark":
            return "ダーク"
        case "vintage":
            return "ヴィンテージ"
        case "minimal":
            return "ミニマル"
        default:
            return iconName
        }
    }

    private func iconDescription(_ iconName: String) -> String {
        switch iconName {
        case "default":
            return "標準のアイコン"
        case "dark":
            return "ダークテーマに最適"
        case "vintage":
            return "クラシックなデザイン"
        case "minimal":
            return "シンプルなデザイン"
        default:
            return ""
        }
    }

    private func changeAppIcon(to iconName: String) {
        guard UIApplication.shared.supportsAlternateIcons else { return }

        let iconFileName = iconName == "default" ? nil : "Icon-\(iconName)"

        UIApplication.shared.setAlternateIconName(iconFileName) { error in
            if let error = error {
                print("アプリアイコンの変更に失敗: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview Components

struct BottlePreviewCard: View {
    @AppStorage("accentColor") private var accentColorName = "default"
    @AppStorage("useCompactMode") private var useCompactMode = false
    @AppStorage("useLargeText") private var useLargeText = false

    var body: some View {
        VStack(alignment: .leading, spacing: useCompactMode ? 4 : 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("山崎 12年")
                        .font(useLargeText ? .title2 : .headline)
                        .fontWeight(.semibold)

                    Text("サントリー")
                        .font(useLargeText ? .body : .subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    HStack {
                        ForEach(0..<5) { i in
                            Image(systemName: i < 4 ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }

                    Text("¥15,000")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if !useCompactMode {
                Text("日本のシングルモルトウイスキーの代表格")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct StatisticPreviewCard: View {
    @AppStorage("accentColor") private var accentColorName = "default"
    @AppStorage("useLargeText") private var useLargeText = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("総ボトル数")
                    .font(useLargeText ? .body : .caption)
                    .foregroundColor(.secondary)
                Text("42本")
                    .font(useLargeText ? .title : .title2)
                    .fontWeight(.bold)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("平均評価")
                    .font(useLargeText ? .body : .caption)
                    .foregroundColor(.secondary)
                Text("4.2⭐")
                    .font(useLargeText ? .title : .title2)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Additional Settings Views

struct VoiceOverSettingsView: View {
    @AppStorage("voiceOverEnabled") private var voiceOverEnabled = false
    @AppStorage("speakBottleNames") private var speakBottleNames = true
    @AppStorage("speakRatings") private var speakRatings = true
    @AppStorage("speakPrices") private var speakPrices = false

    var body: some View {
        List {
            Section {
                Toggle("VoiceOver サポート", isOn: $voiceOverEnabled)

                if voiceOverEnabled {
                    Toggle("ボトル名を読み上げ", isOn: $speakBottleNames)
                    Toggle("評価を読み上げ", isOn: $speakRatings)
                    Toggle("価格を読み上げ", isOn: $speakPrices)
                }
            } header: {
                Text("音声読み上げ")
            } footer: {
                Text("VoiceOverユーザー向けの音声読み上げ設定です。")
            }
        }
        .navigationTitle("音声読み上げ設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GestureSettingsView: View {
    @AppStorage("swipeToDelete") private var swipeToDelete = true
    @AppStorage("pullToRefresh") private var pullToRefresh = true
    @AppStorage("tapToExpand") private var tapToExpand = true
    @AppStorage("longPressActions") private var longPressActions = true

    var body: some View {
        List {
            Section {
                Toggle("スワイプで削除", isOn: $swipeToDelete)
                Toggle("引っ張って更新", isOn: $pullToRefresh)
                Toggle("タップで展開", isOn: $tapToExpand)
                Toggle("長押しアクション", isOn: $longPressActions)
            } header: {
                Text("ジェスチャー")
            } footer: {
                Text("タッチジェスチャーの動作を設定します。")
            }
        }
        .navigationTitle("ジェスチャー設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AppearanceSettingsView()
}