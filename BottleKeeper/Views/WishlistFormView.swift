import SwiftUI

struct WishlistFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let wishlistItem: WishlistItem?

    @State private var name = ""
    @State private var distillery = ""
    @State private var targetPrice = ""
    @State private var budget = ""
    @State private var priority: Int16 = 3
    @State private var notes = ""

    private var isEditing: Bool {
        wishlistItem != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("銘柄名", text: $name)
                    TextField("蒸留所", text: $distillery)
                }

                Section("価格情報") {
                    HStack {
                        Text("目標価格")
                        Spacer()
                        TextField("任意", text: $targetPrice)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                        Text("円")
                    }

                    HStack {
                        Text("予算上限")
                        Spacer()
                        TextField("任意", text: $budget)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                        Text("円")
                    }
                }

                Section("優先度") {
                    Picker("優先度", selection: $priority) {
                        Text("最低").tag(Int16(1))
                        Text("低").tag(Int16(2))
                        Text("中").tag(Int16(3))
                        Text("高").tag(Int16(4))
                        Text("最高").tag(Int16(5))
                    }
                    .pickerStyle(.segmented)
                }

                Section("メモ") {
                    TextField("メモ（任意）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "ウィッシュリスト編集" : "新規追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveWishlistItem()
                    }
                    .disabled(name.isEmpty || distillery.isEmpty)
                }
            }
        }
        .onAppear {
            if let item = wishlistItem {
                loadWishlistItemData(item)
            }
        }
    }

    private func loadWishlistItemData(_ item: WishlistItem) {
        name = item.wrappedName
        distillery = item.wrappedDistillery
        if let price = item.targetPrice {
            targetPrice = price.stringValue
        }
        if let budgetValue = item.budget {
            budget = budgetValue.stringValue
        }
        priority = item.priority
        notes = item.wrappedNotes
    }

    private func saveWishlistItem() {
        withAnimation {
            let targetItem: WishlistItem
            if let existingItem = wishlistItem {
                targetItem = existingItem
            } else {
                targetItem = WishlistItem(context: viewContext)
                targetItem.id = UUID()
                targetItem.createdAt = Date()
            }

            targetItem.name = name
            targetItem.distillery = distillery

            if !targetPrice.isEmpty, let price = Decimal(string: targetPrice) {
                targetItem.targetPrice = NSDecimalNumber(decimal: price)
            } else {
                targetItem.targetPrice = nil
            }

            if !budget.isEmpty, let budgetValue = Decimal(string: budget) {
                targetItem.budget = NSDecimalNumber(decimal: budgetValue)
            } else {
                targetItem.budget = nil
            }

            targetItem.priority = priority
            targetItem.notes = notes.isEmpty ? nil : notes
            targetItem.updatedAt = Date()

            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    WishlistFormView(wishlistItem: nil)
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}