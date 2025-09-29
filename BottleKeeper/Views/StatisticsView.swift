import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            VStack {
                Text("統計")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                Text("ここにコレクションの統計が表示されます")
                    .font(.body)
                    .foregroundColor(.gray)

                Spacer()
            }
            .navigationTitle("統計")
        }
    }
}

#Preview {
    StatisticsView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}