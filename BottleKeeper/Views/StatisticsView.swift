import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bottle.createdAt, ascending: false)],
        animation: .default)
    private var bottles: FetchedResults<Bottle>

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 基本統計
                    BasicStatsSection(bottles: Array(bottles))

                    // 地域別統計
                    RegionStatsSection(bottles: Array(bottles))

                    // 残量統計
                    RemainingVolumeStatsSection(bottles: Array(bottles))

                    // 評価統計
                    RatingStatsSection(bottles: Array(bottles))
                }
                .padding()
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct BasicStatsSection: View {
    let bottles: [Bottle]

    var totalBottles: Int { bottles.count }
    var totalValue: Decimal {
        bottles.compactMap { $0.purchasePrice?.decimalValue }.reduce(0, +)
    }
    var averageValue: Decimal {
        guard totalBottles > 0 else { return 0 }
        return totalValue / Decimal(totalBottles)
    }
    var openedBottles: Int {
        bottles.filter { $0.isOpened }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("基本統計")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCardView(
                    title: "総ボトル数",
                    value: "\(totalBottles)本",
                    icon: "list.bullet",
                    color: .blue
                )

                StatCardView(
                    title: "開栓済み",
                    value: "\(openedBottles)本",
                    icon: "drop.fill",
                    color: .orange
                )

                StatCardView(
                    title: "コレクション価値",
                    value: "¥\(totalValue)",
                    icon: "yensign.circle.fill",
                    color: .green
                )

                StatCardView(
                    title: "平均価格",
                    value: "¥\(averageValue)",
                    icon: "chart.bar.fill",
                    color: .purple
                )
            }
        }
    }
}

struct RegionStatsSection: View {
    let bottles: [Bottle]

    var regionCounts: [(String, Int)] {
        let regionDict = Dictionary(grouping: bottles) { $0.wrappedRegion }
        return regionDict.map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("地域別分布")
                .font(.headline)

            if regionCounts.isEmpty {
                Text("データがありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(regionCounts, id: \.0) { region, count in
                        HStack {
                            Text(region == "不明" ? "地域未設定" : region)
                                .font(.subheadline)
                            Spacer()
                            Text("\(count)本")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Rectangle()
                                .fill(regionColor(for: region))
                                .frame(width: CGFloat(count) / CGFloat(bottles.count) * 100, height: 8)
                                .cornerRadius(4)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    private func regionColor(for region: String) -> Color {
        switch region {
        case "スコットランド":
            return .blue
        case "日本":
            return .red
        case "アイルランド":
            return .green
        case "アメリカ":
            return .orange
        case "カナダ":
            return .purple
        default:
            return .gray
        }
    }
}

struct RemainingVolumeStatsSection: View {
    let bottles: [Bottle]

    var totalVolume: Int32 {
        bottles.map { $0.volume }.reduce(0, +)
    }

    var remainingVolume: Int32 {
        bottles.map { $0.remainingVolume }.reduce(0, +)
    }

    var consumedVolume: Int32 {
        totalVolume - remainingVolume
    }

    var remainingPercentage: Double {
        guard totalVolume > 0 else { return 0 }
        return Double(remainingVolume) / Double(totalVolume) * 100
    }

    var almostEmptyBottles: Int {
        bottles.filter { $0.remainingPercentage < 20 }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("残量統計")
                .font(.headline)

            VStack(spacing: 12) {
                HStack {
                    Text("総容量: \(totalVolume)ml")
                    Spacer()
                    Text("残量: \(remainingVolume)ml")
                }
                .font(.subheadline)

                ProgressView(value: Double(remainingVolume), total: Double(totalVolume))
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: remainingPercentage)))

                HStack {
                    Text("消費量: \(consumedVolume)ml")
                    Spacer()
                    Text("\(remainingPercentage, specifier: "%.1f")% 残存")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                if almostEmptyBottles > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("残り少ないボトル: \(almostEmptyBottles)本")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
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
}

struct RatingStatsSection: View {
    let bottles: [Bottle]

    var ratedBottles: [Bottle] {
        bottles.filter { $0.rating > 0 }
    }

    var averageRating: Double {
        guard !ratedBottles.isEmpty else { return 0 }
        return Double(ratedBottles.map { $0.rating }.reduce(0, +)) / Double(ratedBottles.count)
    }

    var ratingDistribution: [(Int, Int)] {
        let ratings = Dictionary(grouping: ratedBottles) { Int($0.rating) }
        return (1...5).map { rating in
            (rating, ratings[rating]?.count ?? 0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("評価統計")
                .font(.headline)

            if ratedBottles.isEmpty {
                Text("評価されたボトルがありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Text("平均評価")
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: Double(star) <= averageRating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                            Text("(\(averageRating, specifier: "%.1f"))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    VStack(spacing: 4) {
                        ForEach(ratingDistribution.reversed(), id: \.0) { rating, count in
                            HStack {
                                HStack(spacing: 2) {
                                    ForEach(1...rating, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption2)
                                    }
                                }
                                .frame(width: 60, alignment: .leading)

                                Spacer()

                                Text("\(count)本")
                                    .font(.caption)
                                    .fontWeight(.medium)

                                Rectangle()
                                    .fill(Color.yellow)
                                    .frame(width: max(4, CGFloat(count) / CGFloat(ratedBottles.count) * 80), height: 6)
                                    .cornerRadius(3)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    StatisticsView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}