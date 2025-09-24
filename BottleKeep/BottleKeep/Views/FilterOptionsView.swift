import SwiftUI

struct FilterOptionsView: View {
    @Binding var selectedFilter: BottleListViewModel.FilterOption
    @Binding var selectedSort: BottleListViewModel.SortOption

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("フィルタ") {
                    ForEach(BottleListViewModel.FilterOption.allCases, id: \.title) { filter in
                        HStack {
                            Text(filter.title)
                            Spacer()
                            if selectedFilter.title == filter.title {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedFilter = filter
                        }
                    }
                }

                Section("並び順") {
                    ForEach(BottleListViewModel.SortOption.allCases, id: \.title) { sort in
                        HStack {
                            Text(sort.title)
                            Spacer()
                            if selectedSort == sort {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSort = sort
                        }
                    }
                }
            }
            .navigationTitle("フィルタ・並び順")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FilterOptionsView(
        selectedFilter: .constant(.all),
        selectedSort: .constant(.updatedDate)
    )
}