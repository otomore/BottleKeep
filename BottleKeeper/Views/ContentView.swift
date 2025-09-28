import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BottleListView()
                .tabItem {
                    Label("ボトル", systemImage: "wineglass")
                }

            WishlistView()
                .tabItem {
                    Label("ウィッシュリスト", systemImage: "heart")
                }

            StatisticsView()
                .tabItem {
                    Label("統計", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
}