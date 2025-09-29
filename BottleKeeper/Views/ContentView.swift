import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BottleListView()
                .tabItem {
                    Label("コレクション", systemImage: "list.bullet")
                }
                .tag(0)

            WishlistView()
                .tabItem {
                    Label("ウィッシュリスト", systemImage: "star")
                }
                .tag(1)

            StatisticsView()
                .tabItem {
                    Label("統計", systemImage: "chart.bar")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}