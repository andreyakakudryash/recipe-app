import SwiftUI

struct RecipeSearchView: View {
    @ObservedObject var viewModel: RecipeViewModel

    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $viewModel.searchText, onSearch: {
                Task { await viewModel.search() }
            })
            .padding(.horizontal)
            .padding(.vertical, 8)

            if viewModel.isLoading && viewModel.recipes.isEmpty {
                Spacer()
                ProgressView("Поиск...")
                Spacer()
            } else if viewModel.recipes.isEmpty && !viewModel.searchText.isEmpty {
                Spacer()
                ContentUnavailableView.search(text: viewModel.searchText)
                Spacer()
            } else {
                List {
                    ForEach(viewModel.recipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            RecipeCardView(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            Task { await viewModel.loadMoreIfNeeded(currentItem: recipe) }
                        }
                    }

                    if viewModel.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView("Загружаем ещё...")
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Поиск")
    }
}