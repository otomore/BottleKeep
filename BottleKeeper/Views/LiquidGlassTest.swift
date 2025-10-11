import SwiftUI

/// Liquid Glass APIのテスト用ビュー
/// このファイルはテスト目的で作成されています
struct LiquidGlassTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Liquid Glass Test")
                .font(.title)
                .padding()
                .background(.clear)
                .glassEffect() // ← このAPIが存在するか確認

            Button("Test Button") {
                print("Button tapped")
            }
            .padding()
            .glassEffect(.regular.tint(.blue.opacity(0.5)))
        }
        .padding()
    }
}

#Preview {
    LiquidGlassTestView()
        .background(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}
