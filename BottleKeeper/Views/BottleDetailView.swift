import SwiftUI

struct BottleDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let bottle: Bottle
    @State private var showingEditForm = false
    @State private var showingRemainingVolumeSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 写真セクション
                if !bottle.photosArray.isEmpty {
                    TabView {
                        ForEach(bottle.photosArray, id: \.id) { photo in
                            AsyncImage(url: nil) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        ProgressView()
                                    )
                            }
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(PageTabViewStyle())
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("写真が追加されていません")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                        .cornerRadius(12)
                }

                // 基本情報セクション
                VStack(alignment: .leading, spacing: 12) {
                    Text("基本情報")
                        .font(.headline)

                    DetailRowView(title: "銘柄", value: bottle.wrappedName)
                    DetailRowView(title: "蒸留所", value: bottle.wrappedDistillery)
                    DetailRowView(title: "地域", value: bottle.wrappedRegion)
                    DetailRowView(title: "タイプ", value: bottle.wrappedType)
                    DetailRowView(title: "アルコール度数", value: "\(bottle.abv, specifier: "%.1f")%")
                    DetailRowView(title: "容量", value: "\(bottle.volume)ml")

                    if bottle.vintage > 0 {
                        DetailRowView(title: "年代", value: "\(bottle.vintage)年")
                    }
                }

                // 残量情報セクション
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("残量情報")
                            .font(.headline)
                        Spacer()
                        Button("更新") {
                            showingRemainingVolumeSheet = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("残り: \(bottle.remainingVolume)ml / \(bottle.volume)ml")
                            .font(.subheadline)

                        ProgressView(value: bottle.remainingPercentage, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: bottle.remainingPercentage)))

                        Text("\(bottle.remainingPercentage, specifier: "%.1f")%")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if bottle.isOpened {
                            if let openedDate = bottle.openedDate {
                                Text("開栓日: \(openedDate, formatter: dateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("未開栓")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }

                // 購入情報セクション
                if bottle.purchaseDate != nil || bottle.purchasePrice != nil || !bottle.wrappedShop.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("購入情報")
                            .font(.headline)

                        if let purchaseDate = bottle.purchaseDate {
                            DetailRowView(title: "購入日", value: dateFormatter.string(from: purchaseDate))
                        }

                        if let purchasePrice = bottle.purchasePrice {
                            DetailRowView(title: "購入価格", value: "¥\(purchasePrice)")
                        }

                        if !bottle.wrappedShop.isEmpty && bottle.wrappedShop != "不明" {
                            DetailRowView(title: "購入店舗", value: bottle.wrappedShop)
                        }
                    }
                }

                // 評価・ノートセクション
                VStack(alignment: .leading, spacing: 12) {
                    Text("評価・ノート")
                        .font(.headline)

                    if bottle.rating > 0 {
                        HStack {
                            Text("評価:")
                                .foregroundColor(.secondary)
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= bottle.rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }

                    if !bottle.wrappedNotes.isEmpty {
                        Text(bottle.wrappedNotes)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle(bottle.wrappedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") {
                    showingEditForm = true
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            BottleFormView(bottle: bottle)
        }
        .sheet(isPresented: $showingRemainingVolumeSheet) {
            RemainingVolumeUpdateView(bottle: bottle)
        }
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

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
}

struct DetailRowView: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        BottleDetailView(bottle: {
            let context = CoreDataManager.preview.container.viewContext
            let bottle = Bottle(context: context)
            bottle.id = UUID()
            bottle.name = "山崎 12年"
            bottle.distillery = "サントリー"
            bottle.region = "日本"
            bottle.type = "シングルモルト"
            bottle.abv = 43.0
            bottle.volume = 700
            bottle.remainingVolume = 500
            bottle.rating = 5
            bottle.notes = "華やかな香りと深い味わい。バランスが素晴らしい。"
            bottle.purchaseDate = Date()
            bottle.openedDate = Date()
            return bottle
        }())
    }
    .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}