
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
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(store.favorites) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    RecipeCardView(recipe: recipe, compact: false)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        store.remove(recipe)
                                    } label: {
                                        Label("Удалить", systemImage: "heart.slash")
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
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
