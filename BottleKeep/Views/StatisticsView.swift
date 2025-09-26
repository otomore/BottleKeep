import SwiftUI
import Charts

struct StatisticsView: View {
    @StateObject private var viewModel: StatisticsViewModel

    init(diContainer: DIContainer = DIContainer()) {
        _viewModel = StateObject(wrappedValue: diContainer.makeStatisticsViewModel())
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("統計データを読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("エラーが発生しました")
                            .font(.headline)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                        Button("再試行") {
                            Task { await viewModel.refreshData() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    statisticsContent
                }
            }
            .navigationTitle("統計")
            .refreshable {
                await viewModel.refreshData()
            }
            .task {
                await viewModel.loadStatistics()
            }
        }
    }

    @ViewBuilder
    private var statisticsContent: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // 概要統計
                overviewSection

                // チャートセクション
                if viewModel.totalCount > 0 {
                    chartsSection
                    distributionSection
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("概要")
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticCard(
                    title: "総ボトル数",
                    value: "\(viewModel.totalCount)本",
                    icon: "bottle.fill",
                    color: .blue
                )

                StatisticCard(
                    title: "開栓済み",
                    value: "\(viewModel.openedCount)本",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                StatisticCard(
                    title: "未開栓",
                    value: "\(viewModel.unopenedCount)本",
                    icon: "circle",
                    color: .orange
                )

                StatisticCard(
                    title: "開栓率",
                    value: String(format: "%.1f%%", viewModel.openedPercentage),
                    icon: "percent",
                    color: .purple
                )

                StatisticCard(
                    title: "総価値",
                    value: viewModel.totalValueText,
                    icon: "yensign.circle.fill",
                    color: .green
                )

                StatisticCard(
                    title: "平均評価",
                    value: viewModel.averageRatingText,
                    icon: "star.fill",
                    color: .yellow
                )
            }
        }
    }

    @ViewBuilder
    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("開栓状況")
                .font(.title2)
                .fontWeight(.bold)

            Chart {
                SectorMark(
                    angle: .value("数", viewModel.openedCount),
                    innerRadius: .ratio(0.4),
                    outerRadius: .inset(20)
                )
                .foregroundStyle(.green)
                .opacity(0.8)

                SectorMark(
                    angle: .value("数", viewModel.unopenedCount),
                    innerRadius: .ratio(0.4),
                    outerRadius: .inset(20)
                )
                .foregroundStyle(.orange)
                .opacity(0.8)
            }
            .frame(height: 200)
        }
    }

    @ViewBuilder
    private var distributionSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 地域分布
            if !viewModel.sortedRegions.isEmpty {
                distributionChart(
                    title: "地域別分布",
                    data: viewModel.sortedRegions.prefix(5).map { ($0.0, $0.1) },
                    color: .blue
                )
            }

            // タイプ分布
            if !viewModel.sortedTypes.isEmpty {
                distributionChart(
                    title: "タイプ別分布",
                    data: viewModel.sortedTypes.prefix(5).map { ($0.0, $0.1) },
                    color: .purple
                )
            }

            // ヴィンテージ分布
            if !viewModel.sortedVintages.isEmpty {
                vintageChart
            }
        }
    }

    @ViewBuilder
    private func distributionChart(title: String, data: [(String, Int)], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Chart(data, id: \.0) { item in
                BarMark(
                    x: .value("数", item.1),
                    y: .value("項目", item.0)
                )
                .foregroundStyle(color.gradient)
            }
            .frame(height: max(120, CGFloat(data.count * 30)))
        }
    }

    @ViewBuilder
    private var vintageChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ヴィンテージ分布")
                .font(.title2)
                .fontWeight(.bold)

            Chart(viewModel.sortedVintages, id: \.0) { vintage in
                BarMark(
                    x: .value("年", vintage.0),
                    y: .value("数", vintage.1)
                )
                .foregroundStyle(.red.gradient)
            }
            .frame(height: 200)
        }
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    StatisticsView()
}