import SwiftUI
import CoreData

struct WishlistView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            VStack {
                Text("ウィッシュリスト")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                Text("ここに欲しいウイスキーのリストが表示されます")
                    .font(.body)
                    .foregroundColor(.gray)

                Spacer()
            }
            .navigationTitle("ウィッシュリスト")
        }
    }
}

#Preview {
    WishlistView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}