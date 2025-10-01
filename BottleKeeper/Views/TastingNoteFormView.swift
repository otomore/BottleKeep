import SwiftUI

struct TastingNoteFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let bottle: Bottle

    @State private var aroma: String = ""
    @State private var taste: String = ""
    @State private var finish: String = ""
    @State private var overall: String = ""
    @State private var rating: Int16 = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("香り") {
                    TextEditor(text: $aroma)
                        .frame(minHeight: 80)
                }

                Section("味わい") {
                    TextEditor(text: $taste)
                        .frame(minHeight: 80)
                }

                Section("余韻") {
                    TextEditor(text: $finish)
                        .frame(minHeight: 80)
                }

                Section("総合評価") {
                    TextEditor(text: $overall)
                        .frame(minHeight: 80)

                    HStack {
                        Text("評価:")
                        StarRatingView(rating: $rating)
                    }
                }
            }
            .navigationTitle("テイスティングノート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTastingNote()
                    }
                }
            }
            .onAppear {
                loadExistingNote()
            }
        }
    }

    private func loadExistingNote() {
        // 既存のノートを読み込む（構造化形式の場合）
        if let notes = bottle.notes, notes.contains("【香り】") {
            let components = notes.components(separatedBy: "\n\n")
            for component in components {
                if component.hasPrefix("【香り】") {
                    aroma = component.replacingOccurrences(of: "【香り】\n", with: "")
                } else if component.hasPrefix("【味わい】") {
                    taste = component.replacingOccurrences(of: "【味わい】\n", with: "")
                } else if component.hasPrefix("【余韻】") {
                    finish = component.replacingOccurrences(of: "【余韻】\n", with: "")
                } else if component.hasPrefix("【総合】") {
                    overall = component.replacingOccurrences(of: "【総合】\n", with: "")
                }
            }
        }
        rating = bottle.rating
    }

    private func saveTastingNote() {
        var note = ""

        if !aroma.isEmpty {
            note += "【香り】\n\(aroma)\n\n"
        }

        if !taste.isEmpty {
            note += "【味わい】\n\(taste)\n\n"
        }

        if !finish.isEmpty {
            note += "【余韻】\n\(finish)\n\n"
        }

        if !overall.isEmpty {
            note += "【総合】\n\(overall)"
        }

        bottle.notes = note.trimmingCharacters(in: .whitespacesAndNewlines)
        bottle.rating = rating
        bottle.updatedAt = Date()

        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            print("テイスティングノートの保存に失敗: \(nsError), \(nsError.userInfo)")
        }
    }
}

#Preview {
    let context = CoreDataManager.preview.container.viewContext
    let bottle = Bottle(context: context)
    bottle.id = UUID()
    bottle.name = "山崎 12年"
    bottle.distillery = "サントリー"

    return TastingNoteFormView(bottle: bottle)
        .environment(\.managedObjectContext, context)
}
