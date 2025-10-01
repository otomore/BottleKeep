import SwiftUI
import CoreData
import Charts

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bottle.createdAt, ascending: false)],
        animation: .default)
    private var bottles: FetchedResults<Bottle>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DrinkingLog.date, ascending: false)],
        animation: .default)
    private var drinkingLogs: FetchedResults<DrinkingLog>

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

    var monthlyConsumption: [(String, Int)] {
        let calendar = Calendar.current
        let now = Date()

        // 過去6ヶ月のデータを取得
        let months = (0..<6).compactMap { offset -> (String, Int)? in
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: now) else {
                return nil
            }

            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!

            let formatter = DateFormatter()
            formatter.dateFormat = "M月"
            formatter.locale = Locale(identifier: "ja_JP")
            let monthLabel = formatter.string(from: monthDate)

            let consumption = drinkingLogs.filter { log in
                guard let logDate = log.date else { return false }
                return logDate >= monthStart && logDate <= monthEnd
            }.reduce(0) { $0 + Int($1.volume) }

            return (monthLabel, consumption)
        }

        return months.reversed()
    }

    var averageRemainingPercentage: Double {
        let openedBottlesArray = bottles.filter { $0.isOpened }
        guard !openedBottlesArray.isEmpty else { return 0 }
        let total = openedBottlesArray.reduce(0.0) { $0 + $1.remainingPercentage }
        return total / Double(openedBottlesArray.count)
    }

    var body: some View {
        NavigationStack {
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
                                    value: String(format: "%.1f%%", averageABV),
                                    icon: "percent",
                                    color: .orange
                                )

                                StatCardView(
                                    title: "開栓率",
                                    value: String(format: "%.0f%%", openedPercentage),
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

                        // タイプ別分布（円グラフ）
                        if !typeDistribution.isEmpty {
                            VStack(spacing: 16) {
                                Text("タイプ別分布")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Chart(typeDistribution, id: \.0) { type, count in
                                    SectorMark(
                                        angle: .value("本数", count),
                                        innerRadius: .ratio(0.5),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(by: .value("タイプ", type))
                                    .annotation(position: .overlay) {
                                        Text("\(count)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(height: 250)
                                .chartLegend(position: .bottom, alignment: .center, spacing: 10)

                                // 詳細リスト
                                VStack(spacing: 8) {
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
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                            }
                            .padding()
                        }

                        // 月別消費量（棒グラフ）
                        if !monthlyConsumption.isEmpty && monthlyConsumption.contains(where: { $0.1 > 0 }) {
                            VStack(spacing: 16) {
                                Text("月別消費量")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Chart(monthlyConsumption, id: \.0) { month, volume in
                                    BarMark(
                                        x: .value("月", month),
                                        y: .value("消費量", volume)
                                    )
                                    .foregroundStyle(Color.blue.gradient)
                                    .annotation(position: .top) {
                                        if volume > 0 {
                                            Text("\(volume)ml")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .frame(height: 200)
                                .chartYAxis {
                                    AxisMarks(position: .leading) { value in
                                        AxisValueLabel {
                                            if let intValue = value.as(Int.self) {
                                                Text("\(intValue)ml")
                                                    .font(.caption2)
                                            }
                                        }
                                        AxisGridLine()
                                    }
                                }

                                // 統計情報
                                let totalConsumption = monthlyConsumption.reduce(0) { $0 + $1.1 }
                                let avgConsumption = monthlyConsumption.isEmpty ? 0 : totalConsumption / monthlyConsumption.count

                                HStack(spacing: 20) {
                                    VStack {
                                        Text("\(totalConsumption)ml")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                        Text("合計消費量")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)

                                    VStack {
                                        Text("\(avgConsumption)ml")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                        Text("月平均")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green.opacity(0.1))
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