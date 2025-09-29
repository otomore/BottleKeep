import SwiftUI
import CoreData

struct BottleListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            VStack {
                Text("ボトルコレクション")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                Text("ここにウイスキーボトルのリストが表示されます")
                    .font(.body)
                    .foregroundColor(.gray)

                Spacer()
            }
            .navigationTitle("コレクション")
        }
    }
}

#Preview {
    BottleListView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}