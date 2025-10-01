import SwiftUI

/// 星評価の表示・編集コンポーネント
struct StarRatingView: View {
    @Binding var rating: Int16
    let isEditable: Bool
    let onRatingChange: ((Int16) -> Void)?

    init(rating: Binding<Int16>, isEditable: Bool = true, onRatingChange: ((Int16) -> Void)? = nil) {
        self._rating = rating
        self.isEditable = isEditable
        self.onRatingChange = onRatingChange
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    if isEditable {
                        let newRating = Int16(star)
                        // 同じ星をタップした場合は0に戻す
                        rating = (rating == newRating) ? 0 : newRating
                        onRatingChange?(rating)
                    }
                } label: {
                    Image(systemName: Int16(star) <= rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(isEditable ? .title2 : .caption)
                }
                .buttonStyle(.plain)
                .disabled(!isEditable)
            }
        }
    }
}

#Preview("編集可能") {
    StarRatingView(rating: .constant(3))
        .padding()
}

#Preview("読み取り専用") {
    StarRatingView(rating: .constant(4), isEditable: false)
        .padding()
}
