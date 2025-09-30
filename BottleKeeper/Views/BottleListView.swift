import SwiftUI
import CoreData

struct BottleListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bottle.createdAt, ascending: false)],
        animation: .default)
    private var bottles: FetchedResults<Bottle>

    @State private var showingAddBottle = false
    @State private var searchText = ""

    var filteredBottles: [Bottle] {
        if searchText.isEmpty {
            return Array(bottles)
        } else {
            return bottles.filter { bottle in
                bottle.wrappedName.localizedCaseInsensitiveContains(searchText) ||
                bottle.wrappedDistillery.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if bottles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "wineglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("ボトルが登録されていません")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Text("右上の+ボタンから新しいボトルを登録しましょう")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {
                            showingAddBottle = true
                        } label: {
                            Label("ボトルを追加", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                } else {
                    List {
                        ForEach(filteredBottles, id: \.id) { bottle in
                            NavigationLink(destination: BottleDetailView(bottle: bottle)) {
                                BottleRowView(bottle: bottle)
                            }
                        }
                        .onDelete(perform: deleteBottles)
                    }
                    .searchable(text: $searchText, prompt: "銘柄名や蒸留所で検索")
                }
            }
            .navigationTitle("コレクション")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddBottle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                if !bottles.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingAddBottle) {
                BottleFormView(bottle: nil)
            }
        }
    }

    private func deleteBottles(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredBottles[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct BottleRowView: View {
    let bottle: Bottle

    var body: some View {
        HStack(spacing: 12) {
            // ボトル画像のプレースホルダー
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "wineglass.fill")
                        .foregroundColor(.gray)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(bottle.wrappedName)
                    .font(.headline)

                Text(bottle.wrappedDistillery)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    // 開栓ステータス
                    if bottle.isOpened {
                        Label("\(bottle.remainingPercentage, specifier: "%.0f")%", systemImage: "drop.fill")
                            .font(.caption)
                            .foregroundColor(remainingColor(for: bottle.remainingPercentage))
                    } else {
                        Label("未開栓", systemImage: "seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    // レーティング
                    if bottle.rating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                            Text("\(bottle.rating)")
                                .font(.caption)
                        }
                        .foregroundColor(.yellow)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func remainingColor(for percentage: Double) -> Color {
        switch percentage {
        case 50...100:
            return .green
        case 20..<50:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    BottleListView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}