import SwiftUI
import CoreData

struct WishlistView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WishlistItem.priority, ascending: false),
                         NSSortDescriptor(keyPath: \WishlistItem.createdAt, ascending: false)],
        animation: .default)
    private var wishlistItems: FetchedResults<WishlistItem>

    @State private var showingAddItem = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(wishlistItems, id: \.id) { item in
                    WishlistRowView(item: item)
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("ウィッシュリスト")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                WishlistFormView()
            }
            .overlay {
                if wishlistItems.isEmpty {
                    VStack {
                        Image(systemName: "star")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("ウィッシュリストが空です")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("欲しいウイスキーを追加してみましょう")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { wishlistItems[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct WishlistRowView: View {
    let item: WishlistItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.wrappedName)
                        .font(.headline)
                    Text(item.wrappedDistillery)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(item.priorityLevel)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(priorityColor(for: item.priority).opacity(0.2))
                        .foregroundColor(priorityColor(for: item.priority))
                        .cornerRadius(4)

                    if let budget = item.budget {
                        Text("¥\(budget)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !item.wrappedNotes.isEmpty {
                Text(item.wrappedNotes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func priorityColor(for priority: Int16) -> Color {
        switch priority {
        case 5:
            return .red
        case 4:
            return .orange
        case 3:
            return .blue
        case 2:
            return .green
        case 1:
            return .gray
        default:
            return .gray
        }
    }
}

struct WishlistFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var distillery = ""
    @State private var priority: Int16 = 3
    @State private var budget = ""
    @State private var targetPrice = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("ボトル名", text: $name)
                    TextField("蒸留所", text: $distillery)
                }

                Section("購入計画") {
                    HStack {
                        Text("優先度")
                        Spacer()
                        Picker("優先度", selection: $priority) {
                            Text("最低").tag(Int16(1))
                            Text("低").tag(Int16(2))
                            Text("中").tag(Int16(3))
                            Text("高").tag(Int16(4))
                            Text("最高").tag(Int16(5))
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    HStack {
                        Text("予算")
                        Spacer()
                        TextField("任意", text: $budget)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                        Text("円")
                    }

                    HStack {
                        Text("目標価格")
                        Spacer()
                        TextField("任意", text: $targetPrice)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                        Text("円")
                    }
                }

                Section("メモ") {
                    TextField("メモ（任意）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("ウィッシュリスト追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveItem()
                    }
                    .disabled(name.isEmpty || distillery.isEmpty)
                }
            }
        }
    }

    private func saveItem() {
        withAnimation {
            let newItem = WishlistItem(context: viewContext)
            newItem.id = UUID()
            newItem.name = name
            newItem.distillery = distillery
            newItem.priority = priority

            if !budget.isEmpty, let budgetValue = Decimal(string: budget) {
                newItem.budget = NSDecimalNumber(decimal: budgetValue)
            }

            if !targetPrice.isEmpty, let targetValue = Decimal(string: targetPrice) {
                newItem.targetPrice = NSDecimalNumber(decimal: targetValue)
            }

            newItem.notes = notes.isEmpty ? nil : notes
            newItem.createdAt = Date()
            newItem.updatedAt = Date()

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
    WishlistView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}