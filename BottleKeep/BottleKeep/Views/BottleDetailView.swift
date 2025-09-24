import SwiftUI

struct BottleDetailView: View {
    let bottle: Bottle

    @State private var showingEditForm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 写真セクション
                photoSection

                // 基本情報セクション
                basicInfoSection

                // 購入情報セクション
                if hasePurchaseInfo {
                    purchaseInfoSection
                }

                // テイスティング情報セクション
                if bottle.isOpened || bottle.rating > 0 {
                    tastingInfoSection
                }
            }
            .padding()
        }
        .navigationTitle(bottle.name)
        .navigationBarTitleDisplayMode(.large)
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
    }

    // MARK: - View Components

    private var photoSection: some View {
        VStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 300)
                .overlay(
                    Image(systemName: "wineglass")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基本情報")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 8) {
                InfoRow(label: "銘柄", value: bottle.name)
                InfoRow(label: "蒸留所", value: bottle.distillery)

                if let region = bottle.region {
                    InfoRow(label: "地域", value: region)
                }

                if let type = bottle.type {
                    InfoRow(label: "タイプ", value: type)
                }

                if bottle.abv > 0 {
                    InfoRow(label: "アルコール度数", value: "\(bottle.abv, specifier: "%.1f")%")
                }

                if bottle.volume > 0 {
                    InfoRow(label: "容量", value: "\(bottle.volume)ml")
                }

                if bottle.vintage > 0 {
                    InfoRow(label: "ヴィンテージ", value: "\(bottle.vintage)年")
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var purchaseInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("購入情報")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 8) {
                if let purchaseDate = bottle.purchaseDate {
                    InfoRow(label: "購入日", value: purchaseDate, formatter: .dateOnly)
                }

                if let purchasePrice = bottle.purchasePrice {
                    InfoRow(label: "購入価格", value: "¥\(purchasePrice.intValue)")
                }

                if let shop = bottle.shop {
                    InfoRow(label: "購入店舗", value: shop)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var tastingInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("テイスティング情報")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 8) {
                if let openedDate = bottle.openedDate {
                    InfoRow(label: "開栓日", value: openedDate, formatter: .dateOnly)
                }

                if bottle.volume > 0 {
                    InfoRow(label: "残量", value: "\(bottle.remainingVolume)ml / \(bottle.volume)ml")

                    // 残量バー
                    ProgressView(value: bottle.remainingPercentage / 100.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }

                if bottle.rating > 0 {
                    HStack {
                        Text("評価")
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= bottle.rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                    }
                }

                if let notes = bottle.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("テイスティングノート")
                            .foregroundColor(.secondary)
                        Text(notes)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Computed Properties

    private var hasePurchaseInfo: Bool {
        return bottle.purchaseDate != nil ||
               bottle.purchasePrice != nil ||
               bottle.shop != nil
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String

    init(label: String, value: String) {
        self.label = label
        self.value = value
    }

    init(label: String, value: Date, formatter: DateFormatter) {
        self.label = label
        self.value = formatter.string(from: value)
    }

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BottleDetailView(bottle: Bottle.createTestBottle(
            context: CoreDataManager.shared.context,
            name: "山崎 12年",
            distillery: "サントリー"
        ))
    }
}