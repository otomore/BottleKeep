import SwiftUI

struct AccessibilitySettingsView: View {
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("increaseContrast") private var increaseContrast = false
    @AppStorage("boldText") private var boldText = false
    @AppStorage("buttonShapes") private var buttonShapes = false
    @AppStorage("differentiateWithoutColor") private var differentiateWithoutColor = false
    @AppStorage("smartInvert") private var smartInvert = false
    @AppStorage("classicInvert") private var classicInvert = false
    @AppStorage("reduceTransparency") private var reduceTransparency = false

    // VoiceOver設定
    @AppStorage("voiceOverHints") private var voiceOverHints = true
    @AppStorage("voiceOverNavigationStyle") private var voiceOverNavigationStyle = "default"
    @AppStorage("customVoiceOverLabels") private var customVoiceOverLabels = true

    // 触覚フィードバック設定
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("hapticIntensity") private var hapticIntensity = 1.0

    // 読み上げ設定
    @AppStorage("speakSelection") private var speakSelection = false
    @AppStorage("speakScreen") private var speakScreen = false
    @AppStorage("speakingRate") private var speakingRate = 0.5

    var body: some View {
        NavigationStack {
            List {
                // 視覚的アクセシビリティ
                visualAccessibilitySection

                // VoiceOver設定
                voiceOverSection

                // 聴覚的アクセシビリティ
                auditoryAccessibilitySection

                // 運動機能アクセシビリティ
                motorAccessibilitySection

                // 認知的アクセシビリティ
                cognitiveAccessibilitySection

                // カスタマイズ
                customizationSection
            }
            .navigationTitle("アクセシビリティ")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var visualAccessibilitySection: some View {
        Section {
            Toggle("コントラストを上げる", isOn: $increaseContrast)
                .accessibilityHint("テキストと背景のコントラストを強くします")

            Toggle("太字テキスト", isOn: $boldText)
                .accessibilityHint("テキストを太字にして読みやすくします")

            Toggle("ボタンの形を表示", isOn: $buttonShapes)
                .accessibilityHint("ボタンに境界線を追加して識別しやすくします")

            Toggle("色以外でも区別", isOn: $differentiateWithoutColor)
                .accessibilityHint("色だけでなく形や記号でも情報を区別します")

            Toggle("透明度を下げる", isOn: $reduceTransparency)
                .accessibilityHint("背景の透明効果を減らして見やすくします")

            Toggle("スマート反転", isOn: $smartInvert)
                .accessibilityHint("画像や動画以外の色を反転します")

            Toggle("クラシック反転", isOn: $classicInvert)
                .accessibilityHint("すべての色を反転します")

        } header: {
            Text("視覚")
        } footer: {
            Text("視覚的な表示を調整してアプリを使いやすくします。")
        }
    }

    @ViewBuilder
    private var voiceOverSection: some View {
        Section {
            Toggle("VoiceOverヒント", isOn: $voiceOverHints)
                .accessibilityHint("VoiceOver使用時に操作のヒントを提供します")

            Picker("ナビゲーションスタイル", selection: $voiceOverNavigationStyle) {
                Text("デフォルト").tag("default")
                Text("グループ化").tag("grouped")
                Text("詳細").tag("detailed")
            }
            .accessibilityHint("VoiceOverでの画面の読み上げ順序を設定します")

            Toggle("カスタムラベル", isOn: $customVoiceOverLabels)
                .accessibilityHint("UI要素に分かりやすいカスタムラベルを使用します")

            NavigationLink("VoiceOver練習モード") {
                VoiceOverPracticeView()
            }
            .accessibilityHint("VoiceOverの操作を練習できます")

        } header: {
            Text("VoiceOver")
        } footer: {
            Text("VoiceOver使用時の読み上げ動作を設定します。")
        }
    }

    @ViewBuilder
    private var auditoryAccessibilitySection: some View {
        Section {
            Toggle("選択項目の読み上げ", isOn: $speakSelection)
                .accessibilityHint("選択したテキストを音声で読み上げます")

            Toggle("画面の読み上げ", isOn: $speakScreen)
                .accessibilityHint("画面全体の内容を音声で読み上げます")

            VStack(alignment: .leading, spacing: 8) {
                Text("読み上げ速度")
                    .font(.headline)

                Slider(value: $speakingRate, in: 0.1...2.0, step: 0.1) {
                    Text("読み上げ速度")
                } minimumValueLabel: {
                    Text("遅い")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("速い")
                        .font(.caption)
                }
                .accessibilityValue("\(Int(speakingRate * 10))段階中\(Int(speakingRate * 10))番目")

                Text("現在の速度: \(String(format: "%.1f", speakingRate))x")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button("読み上げテスト") {
                testSpeech()
            }
            .accessibilityHint("現在の設定で読み上げをテストします")

        } header: {
            Text("聴覚")
        } footer: {
            Text("音声読み上げに関する設定です。")
        }
    }

    @ViewBuilder
    private var motorAccessibilitySection: some View {
        Section {
            Toggle("触覚フィードバック", isOn: $hapticFeedback)
                .accessibilityHint("操作時に触覚フィードバックを提供します")

            if hapticFeedback {
                VStack(alignment: .leading, spacing: 8) {
                    Text("触覚フィードバック強度")
                        .font(.headline)

                    Slider(value: $hapticIntensity, in: 0.1...2.0, step: 0.1) {
                        Text("強度")
                    } minimumValueLabel: {
                        Text("弱")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("強")
                            .font(.caption)
                    }

                    Button("フィードバックテスト") {
                        testHapticFeedback()
                    }
                    .font(.caption)
                }
            }

            NavigationLink("スイッチコントロール設定") {
                SwitchControlSettingsView()
            }
            .accessibilityHint("外部スイッチでの操作設定を行います")

        } header: {
            Text("運動機能")
        } footer: {
            Text("身体の動きに関連するアクセシビリティ機能です。")
        }
    }

    @ViewBuilder
    private var cognitiveAccessibilitySection: some View {
        Section {
            Toggle("アニメーションを減らす", isOn: $reduceMotion)
                .accessibilityHint("画面のアニメーションや動きを減らします")

            NavigationLink("ガイドアクセス設定") {
                GuidedAccessSettingsView()
            }
            .accessibilityHint("アプリの特定の機能に集中できるよう設定します")

            NavigationLink("ショートカット設定") {
                AccessibilityShortcutsView()
            }
            .accessibilityHint("アクセシビリティ機能への素早いアクセス方法を設定します")

        } header: {
            Text("認知機能")
        } footer: {
            Text("集中力や学習に関するサポート機能です。")
        }
    }

    @ViewBuilder
    private var customizationSection: some View {
        Section {
            NavigationLink("カスタムジェスチャー") {
                CustomGesturesView()
            }
            .accessibilityHint("独自のジェスチャーを作成・設定します")

            NavigationLink("音声コマンド") {
                VoiceCommandsView()
            }
            .accessibilityHint("音声でアプリを操作するコマンドを設定します")

            Button("アクセシビリティ診断") {
                runAccessibilityAudit()
            }
            .accessibilityHint("現在のアクセシビリティ設定を確認します")

            Button("設定をリセット") {
                resetAccessibilitySettings()
            }
            .foregroundColor(.red)
            .accessibilityHint("すべてのアクセシビリティ設定を初期値に戻します")

        } header: {
            Text("カスタマイズ")
        } footer: {
            Text("個人のニーズに合わせてアクセシビリティ機能をカスタマイズします。")
        }
    }

    // MARK: - Helper Methods

    private func testSpeech() {
        // 実際の実装では AVSpeechSynthesizer を使用
        #if targetEnvironment(simulator)
        print("読み上げテスト: これはテスト音声です")
        #endif
    }

    private func testHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred(intensity: CGFloat(hapticIntensity))
    }

    private func runAccessibilityAudit() {
        // アクセシビリティ診断の実行
        print("アクセシビリティ診断を実行")
    }

    private func resetAccessibilitySettings() {
        reduceMotion = false
        increaseContrast = false
        boldText = false
        buttonShapes = false
        differentiateWithoutColor = false
        smartInvert = false
        classicInvert = false
        reduceTransparency = false
        voiceOverHints = true
        voiceOverNavigationStyle = "default"
        customVoiceOverLabels = true
        hapticFeedback = true
        hapticIntensity = 1.0
        speakSelection = false
        speakScreen = false
        speakingRate = 0.5
    }
}

// MARK: - Additional Views

struct VoiceOverPracticeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("VoiceOver練習モード")
                    .font(.title)
                    .accessibilityAddTraits(.isHeader)

                Text("この画面では、BottleKeepアプリでのVoiceOver操作を練習できます。")
                    .accessibilityHint("アプリの操作方法を学習できます")

                VStack(alignment: .leading, spacing: 16) {
                    practiceSection(title: "基本操作", items: [
                        "右にスワイプ: 次の項目に移動",
                        "左にスワイプ: 前の項目に移動",
                        "ダブルタップ: 項目を選択",
                        "3本指でスワイプ: ページをスクロール"
                    ])

                    practiceSection(title: "BottleKeep特有の操作", items: [
                        "ボトル一覧: 左右スワイプで各ボトルを確認",
                        "評価: ダブルタップで星の数を変更",
                        "写真: ダブルタップで拡大表示",
                        "メニュー: 3本指ダブルタップで操作メニュー"
                    ])
                }

                Button("練習を開始") {
                    // 練習モードを開始
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("インタラクティブな練習セッションを開始します")
            }
            .padding()
        }
        .navigationTitle("VoiceOver練習")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func practiceSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .accessibilityLabel(item)
            }
        }
    }
}

struct SwitchControlSettingsView: View {
    var body: some View {
        List {
            Text("スイッチコントロール設定は開発中です")
        }
        .navigationTitle("スイッチコントロール")
    }
}

struct GuidedAccessSettingsView: View {
    var body: some View {
        List {
            Text("ガイドアクセス設定は開発中です")
        }
        .navigationTitle("ガイドアクセス")
    }
}

struct AccessibilityShortcutsView: View {
    var body: some View {
        List {
            Text("ショートカット設定は開発中です")
        }
        .navigationTitle("ショートカット")
    }
}

struct CustomGesturesView: View {
    var body: some View {
        List {
            Text("カスタムジェスチャー設定は開発中です")
        }
        .navigationTitle("カスタムジェスチャー")
    }
}

struct VoiceCommandsView: View {
    var body: some View {
        List {
            Text("音声コマンド設定は開発中です")
        }
        .navigationTitle("音声コマンド")
    }
}

#Preview {
    AccessibilitySettingsView()
}