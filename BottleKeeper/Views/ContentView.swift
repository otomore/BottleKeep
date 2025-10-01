import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab = 0
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        // iPadではNavigationSplitView、iPhoneではTabViewを使用
        if horizontalSizeClass == .regular {
            // iPad用レイアウト
            NavigationSplitView(columnVisibility: $columnVisibility) {
                // サイドバー
                List {
                    Button {
                        selectedTab = 0
                    } label: {
                        Label("コレクション", systemImage: "list.bullet")
                    }
                    .listRowBackground(selectedTab == 0 ? Color.blue.opacity(0.2) : Color.clear)

                    Button {
                        selectedTab = 1
                    } label: {
                        Label("ウィッシュリスト", systemImage: "star")
                    }
                    .listRowBackground(selectedTab == 1 ? Color.blue.opacity(0.2) : Color.clear)

                    Button {
                        selectedTab = 2
                    } label: {
                        Label("統計", systemImage: "chart.bar")
                    }
                    .listRowBackground(selectedTab == 2 ? Color.blue.opacity(0.2) : Color.clear)

                    Button {
                        selectedTab = 3
                    } label: {
                        Label("設定", systemImage: "gear")
                    }
                    .listRowBackground(selectedTab == 3 ? Color.blue.opacity(0.2) : Color.clear)
                }
                .navigationTitle("BottleKeeper")
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
            } detail: {
                // メインコンテンツ
                selectedView
                    .navigationBarTitleDisplayMode(.inline)
            }
            .navigationSplitViewStyle(.balanced)
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