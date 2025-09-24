import SwiftUI

struct StatisticsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "chart.bar")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)

                Text("統計情報")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("コレクションの統計を表示する機能は今後追加予定です")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(.horizontal, 40)
            .navigationTitle("統計")
        }
    }
}

#Preview {
    StatisticsView()
}