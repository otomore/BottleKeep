import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab = 0

    var body: some View {
        // iPadではNavigationSplitView、iPhoneではTabViewを使用
        if horizontalSizeClass == .regular {
            // iPad用レイアウト
            NavigationSplitView {
                // サイドバー
                List(selection: $selectedTab) {
                    NavigationLink(value: 0) {
                        Label("コレクション", systemImage: "list.bullet")
                    }
                    NavigationLink(value: 1) {
                        Label("ウィッシュリスト", systemImage: "star")
                    }
                    NavigationLink(value: 2) {
                        Label("統計", systemImage: "chart.bar")
                    }
                    NavigationLink(value: 3) {
                        Label("設定", systemImage: "gear")
                    }
                }
                .navigationTitle("BottleKeeper")
            } detail: {
                // メインコンテンツ
                selectedView
            }
        } else {
            // iPhone用レイアウト（従来通り）
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

    @ViewBuilder
    private var selectedView: some View {
        switch selectedTab {
        case 0:
            BottleListView()
        case 1:
            WishlistView()
        case 2:
            StatisticsView()
        case 3:
            SettingsView()
        default:
            BottleListView()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, CoreDataManager.preview.container.viewContext)
}