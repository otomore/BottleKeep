import SwiftUI

struct WishlistView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "heart")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)

                Text("ウィッシュリスト")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("欲しいボトルを管理する機能は今後追加予定です")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(.horizontal, 40)
            .navigationTitle("ウィッシュリスト")
        }
    }
}

#Preview {
    WishlistView()
}