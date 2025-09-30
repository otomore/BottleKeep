import SwiftUI

struct DrinkingLogFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let bottle: Bottle

    @State private var date = Date()
    @State private var volume: String = "30"
    @State private var notes: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("飲酒情報")) {
                    DatePicker("日時", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "ja_JP"))

                    HStack {
                        Text("飲酒量")
                        Spacer()
                        TextField("30", text: $volume)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("ml")
                    }

                    // 残量表示
                    VStack(alignment: .leading, spacing: 4) {
                        Text("現在の残量: \(bottle.remainingVolume)ml")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let volumeInt = Int32(volume), volumeInt > 0 {
                            let newRemaining = max(0, bottle.remainingVolume - volumeInt)
                            Text("記録後の残量: \(newRemaining)ml")
                                .font(.caption)
                                .foregroundColor(volumeInt > bottle.remainingVolume ? .red : .green)
                        }
                    }
                }

                Section(header: Text("メモ（任意）")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                Section(header: Text("ボトル情報")) {
                    HStack {
                        Text("銘柄")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(bottle.wrappedName)
                    }

                    HStack {
                        Text("アルコール度数")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(String(format: "%.1f", bottle.abv))%")
                    }
                }
            }
            .navigationTitle("飲酒ログを記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveDrinkingLog()
                    }
                }
            }
            .alert("エラー", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func saveDrinkingLog() {
        // 入力検証
        guard let volumeInt = Int32(volume), volumeInt > 0 else {
            alertMessage = "飲酒量を正しく入力してください"
            showingAlert = true
            return
        }

        if volumeInt > bottle.volume {
            alertMessage = "飲酒量がボトルの容量を超えています"
            showingAlert = true
            return
        }

        // 飲酒ログを作成
        let log = DrinkingLog(context: viewContext)
        log.id = UUID()
        log.date = date
        log.volume = volumeInt
        log.notes = notes.isEmpty ? nil : notes
        log.createdAt = Date()
        log.bottle = bottle

        // ボトルの残量を更新
        bottle.remainingVolume = max(0, bottle.remainingVolume - volumeInt)
        bottle.updatedAt = Date()

        // 未開栓の場合は開栓日を設定
        if !bottle.isOpened {
            bottle.openedDate = date
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            alertMessage = "保存に失敗しました: \(nsError.localizedDescription)"
            showingAlert = true
        }
    }
}

#Preview {
    NavigationView {
        DrinkingLogFormView(bottle: {
            let context = CoreDataManager.preview.container.viewContext
            let bottle = Bottle(context: context)
            bottle.id = UUID()
            bottle.name = "山崎 12年"
            bottle.distillery = "サントリー"
            bottle.abv = 43.0
            bottle.volume = 700
            bottle.remainingVolume = 500
            return bottle
        }())
    }
    .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}
