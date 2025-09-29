import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            VStack {
                Text("設定")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                Text("ここにアプリの設定が表示されます")
                    .font(.body)
                    .foregroundColor(.gray)

                Spacer()
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}