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
        NavigationStack {
            List {
                ForEach(filteredBottles, id: \.id) { bottle in
                    NavigationLink(destination: BottleDetailView(bottle: bottle)) {
                        BottleRowView(bottle: bottle)
                    }
                }
                .onDelete(perform: deleteBottles)
            }
            .searchable(text: $searchText, prompt: "ボトルを検索")
            .navigationTitle("コレクション")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddBottle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBottle) {
                BottleFormView()
            }
        }
    }

    private func deleteBottles(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredBottles[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // エラーハンドリング
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct BottleRowView: View {
    let bottle: Bottle

    var body: some View {
        HStack {
            AsyncImage(url: nil) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 60, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(bottle.wrappedName)
                    .font(.headline)
                    .lineLimit(1)

                Text(bottle.wrappedDistillery)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack {
                    Text("\(bottle.abv, specifier: "%.1f")%")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)

                    Text("\(bottle.volume)ml")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }

                ProgressView(value: bottle.remainingPercentage, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: bottle.remainingPercentage)))
                    .scaleEffect(x: 1, y: 0.8)

                Text("残り: \(bottle.remainingVolume)ml (\(bottle.remainingPercentage, specifier: "%.0f")%)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func progressColor(for percentage: Double) -> Color {
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