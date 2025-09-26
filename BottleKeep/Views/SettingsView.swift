import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var dataManager = DataExportImportManager.shared
    @State private var showingExportOptions = false
    @State private var showingImportPicker = false
    @State private var showingBackupOptions = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isProcessing = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            List {
                Section("iCloud") {
                    HStack {
                        Image(systemName: "icloud")
                        Text("iCloud同期")
                        Spacer()
                        Text("オン")
                            .foregroundColor(.secondary)
                    }
                }

                Section("データ管理") {
                    Button(action: { showingExportOptions = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("データをエクスポート")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(isProcessing)

                    Button(action: { showingImportPicker = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.green)
                            Text("データをインポート")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(isProcessing)

                    Button(action: { showingBackupOptions = true }) {
                        HStack {
                            Image(systemName: "externaldrive")
                                .foregroundColor(.orange)
                            Text("バックアップ・復元")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(isProcessing)
                }

                Section("外観・アクセシビリティ") {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        HStack {
                            Image(systemName: "paintbrush")
                                .foregroundColor(.purple)
                            Text("外観設定")
                        }
                    }

                    NavigationLink(destination: AccessibilitySettingsView()) {
                        HStack {
                            Image(systemName: "accessibility")
                                .foregroundColor(.blue)
                            Text("アクセシビリティ")
                        }
                    }
                }

                Section("通知") {
                    NavigationLink(destination: NotificationSettingsView()) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(.red)
                            Text("通知設定")
                        }
                    }
                }

                Section("アプリについて") {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "heart")
                        Text("開発者")
                        Spacer()
                        Text("BottleKeep Team")
                            .foregroundColor(.secondary)
                    }
                }

                if isProcessing {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("処理中...")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("設定")
            .confirmationDialog("データをエクスポート", isPresented: $showingExportOptions) {
                Button("ボトル一覧 (CSV)") {
                    Task { await exportBottlesCSV() }
                }
                Button("ウィッシュリスト (CSV)") {
                    Task { await exportWishlistCSV() }
                }
                Button("全データ (JSON)") {
                    Task { await exportAllData() }
                }
                Button("キャンセル", role: .cancel) {}
            }
            .confirmationDialog("バックアップ・復元", isPresented: $showingBackupOptions) {
                Button("データをバックアップ") {
                    Task { await createBackup() }
                }
                Button("バックアップから復元") {
                    showingImportPicker = true
                }
                Button("キャンセル", role: .cancel) {}
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.commaSeparatedText, .json, .plainText],
                allowsMultipleSelection: false
            ) { result in
                Task { await handleImportFile(result: result) }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                if let url = exportURL {
                    Button("シェア") {
                        shareFile(url: url)
                    }
                }
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Export Functions

    private func exportBottlesCSV() async {
        isProcessing = true
        do {
            let url = try await dataManager.exportBottlesToCSV()
            await MainActor.run {
                exportURL = url
                alertTitle = "エクスポート完了"
                alertMessage = "ボトルデータをCSV形式で保存しました"
                showingAlert = true
                isProcessing = false
            }
        } catch {
            await MainActor.run {
                exportURL = nil
                alertTitle = "エクスポートエラー"
                alertMessage = error.localizedDescription
                showingAlert = true
                isProcessing = false
            }
        }
    }

    private func exportWishlistCSV() async {
        isProcessing = true
        do {
            let url = try await dataManager.exportWishlistToCSV()
            await MainActor.run {
                exportURL = url
                alertTitle = "エクスポート完了"
                alertMessage = "ウィッシュリストをCSV形式で保存しました"
                showingAlert = true
                isProcessing = false
            }
        } catch {
            await MainActor.run {
                exportURL = nil
                alertTitle = "エクスポートエラー"
                alertMessage = error.localizedDescription
                showingAlert = true
                isProcessing = false
            }
        }
    }

    private func exportAllData() async {
        isProcessing = true
        do {
            let url = try await dataManager.exportAllDataToJSON()
            await MainActor.run {
                exportURL = url
                alertTitle = "エクスポート完了"
                alertMessage = "全データをJSON形式で保存しました"
                showingAlert = true
                isProcessing = false
            }
        } catch {
            await MainActor.run {
                exportURL = nil
                alertTitle = "エクスポートエラー"
                alertMessage = error.localizedDescription
                showingAlert = true
                isProcessing = false
            }
        }
    }

    private func createBackup() async {
        isProcessing = true
        do {
            let url = try await dataManager.exportAllDataToJSON()
            await MainActor.run {
                exportURL = url
                alertTitle = "バックアップ完了"
                alertMessage = "データのバックアップを作成しました"
                showingAlert = true
                isProcessing = false
            }
        } catch {
            await MainActor.run {
                exportURL = nil
                alertTitle = "バックアップエラー"
                alertMessage = error.localizedDescription
                showingAlert = true
                isProcessing = false
            }
        }
    }

    // MARK: - Import Functions

    private func handleImportFile(result: Result<[URL], Error>) async {
        isProcessing = true

        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                await showError("ファイルが選択されていません")
                return
            }

            do {
                let importResult: ImportResult

                if url.pathExtension.lowercased() == "json" {
                    importResult = try await dataManager.importDataFromJSON(url: url)
                } else {
                    importResult = try await dataManager.importBottlesFromCSV(url: url)
                }

                await MainActor.run {
                    alertTitle = importResult.isSuccess ? "インポート完了" : "インポート完了（一部エラー）"
                    alertMessage = importResult.summary
                    if !importResult.errors.isEmpty {
                        alertMessage += "\n\nエラー詳細:\n" + importResult.errors.prefix(3).joined(separator: "\n")
                    }
                    showingAlert = true
                    isProcessing = false
                }
            } catch {
                await showError(error.localizedDescription)
            }

        case .failure(let error):
            await showError(error.localizedDescription)
        }
    }

    private func showError(_ message: String) async {
        await MainActor.run {
            exportURL = nil
            alertTitle = "エラー"
            alertMessage = message
            showingAlert = true
            isProcessing = false
        }
    }

    private func shareFile(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

#Preview {
    SettingsView()
}