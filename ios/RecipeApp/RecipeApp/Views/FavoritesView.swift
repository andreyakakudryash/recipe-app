
import SwiftUI

// Хранилище избранных рецептов
class FavoritesStore: ObservableObject {
    @Published var favorites: [Recipe] = []

    func add(_ recipe: Recipe) {
        guard !favorites.contains(where: { $0.id == recipe.id }) else { return }
        favorites.insert(recipe, at: 0)
    }

    func remove(_ recipe: Recipe) {
        favorites.removeAll { $0.id == recipe.id }
    }

    func isFavorite(_ recipe: Recipe) -> Bool {
        favorites.contains(where: { $0.id == recipe.id })
    }
}

struct FavoritesView: View {
    @EnvironmentObject var store: FavoritesStore
    @State private var showCreateForm = false

    var body: some View {
        NavigationStack {
            Group {
                if store.favorites.isEmpty {
                    ContentUnavailableView(
                        "Нет сохранённых рецептов",
                        systemImage: "heart.slash",
                        description: Text("Нажмите ♥ на рецепте чтобы сохранить его")
                    )
                } else {
                    List {
                        ForEach(store.favorites) { recipe in
                            NavigationLink(destination: RecipeDetailView(
                                recipe: recipe,
                                onDelete: {
                                    store.remove(recipe)
                                    Task { try? await APIClient.shared.deleteRecipe(id: recipe.id) }
                                },
                                onEdit: { updated in
                                    if let idx = store.favorites.firstIndex(where: { $0.id == updated.id }) {
                                        store.favorites[idx] = updated
                                    }
                                }
                            )) {
                                RecipeCardView(recipe: recipe, compact: false)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                store.remove(store.favorites[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Мои рецепты")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .sheet(isPresented: $showCreateForm) {
                RecipeFormView { request in
                    // Создаём рецепт и добавляем в избранное
                    Task {
                        if let recipe = try? await APIClient.shared.createRecipe(request) {
                            await MainActor.run { store.add(recipe) }
                        }
                    }
                }
            }
        }
    }
}

