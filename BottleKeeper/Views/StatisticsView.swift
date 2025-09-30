import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bottle.createdAt, ascending: false)],
        animation: .default)
    private var bottles: FetchedResults<Bottle>

    var totalBottles: Int {
        bottles.count
    }

    var totalInvestment: Decimal {
        bottles.reduce(Decimal(0)) { sum, bottle in
            if let price = bottle.purchasePrice {
                return sum + price.decimalValue
            }
            return sum
        }
    }

    var averageABV: Double {
        guard !bottles.isEmpty else { return 0 }
        let total = bottles.reduce(0.0) { $0 + $1.abv }
        return total / Double(bottles.count)
    }

    var openedBottles: Int {
        bottles.filter { $0.isOpened }.count
    }

    var unopenedBottles: Int {
        bottles.filter { !$0.isOpened }.count
    }

    var openedPercentage: Double {
        guard totalBottles > 0 else { return 0 }
        return Double(openedBottles) / Double(totalBottles) * 100
    }

    var typeDistribution: [(String, Int)] {
        let types = Dictionary(grouping: bottles) { $0.wrappedType }
        return types.map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }

    var averageRemainingPercentage: Double {
        let openedBottlesArray = bottles.filter { $0.isOpened }
        guard !openedBottlesArray.isEmpty else { return 0 }
        let total = openedBottlesArray.reduce(0.0) { $0 + $1.remainingPercentage }
        return total / Double(openedBottlesArray.count)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                if bottles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                            .padding(.top, 60)

                        Text("統計情報がありません")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Text("ボトルを追加すると統計が表示されます")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 20) {
                        // 基本統計
                        VStack(spacing: 16) {
                            Text("コレクション概要")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                StatCardView(
                                    title: "総ボトル数",
                                    value: "\(totalBottles)",
                                    icon: "wineglass.fill",
                                    color: .blue
                                )

                                StatCardView(
                                    title: "総投資額",
                                    value: "¥\(Int(truncating: totalInvestment as NSNumber))",
                                    icon: "yensign.circle.fill",
                                    color: .green
                                )

                                StatCardView(
                                    title: "平均ABV",
                                    value: "\(averageABV, specifier: "%.1f")%",
                                    icon: "percent",
                                    color: .orange
                                )

                                StatCardView(
                                    title: "開栓率",
                                    value: "\(openedPercentage, specifier: "%.0f")%",
                                    icon: "seal.fill",
                                    color: .purple
                                )
                            }
                        }
                        .padding()

                        // 開栓状況
                        VStack(spacing: 16) {
                            Text("開栓状況")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 20) {
                                VStack {
                                    Text("\(openedBottles)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                    Text("開栓済み")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)

                                VStack {
                                    Text("\(unopenedBottles)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                    Text("未開栓")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }

                            if openedBottles > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("平均残量")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    ProgressView(value: averageRemainingPercentage, total: 100)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))

                                    Text("\(averageRemainingPercentage, specifier: "%.1f")%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding()

                        // タイプ別分布
                        if !typeDistribution.isEmpty {
                            VStack(spacing: 16) {
                                Text("タイプ別分布")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(typeDistribution, id: \.0) { type, count in
                                    HStack {
                                        Text(type)
                                            .font(.subheadline)

                                        Spacer()

                                        Text("\(count)本")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)

                                        Text("(\(Double(count) / Double(totalBottles) * 100, specifier: "%.0f")%)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding()
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("統計")
        }
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    StatisticsView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}