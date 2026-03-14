import Foundation

@MainActor
class RecipeViewModel: ObservableObject {

    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCuisineID = 0
    @Published var maxCookTime = 0

    // Cursor-based пагинация
    private var nextCursor: Int = 0
    @Published var hasMore = true
    let pageSize = 20

    private var isSearching: Bool { !searchText.isEmpty }

    // MARK: - Загрузка (первая страница)

    func loadRecipes() async {
        isLoading = true
        errorMessage = nil
        nextCursor = 0
        hasMore = true

        do {
            let response = try await APIClient.shared.getRecipes(
                cursor: 0,
                limit: pageSize,
                cuisineID: selectedCuisineID,
                maxCookTime: maxCookTime
            )
            recipes = response.data
            nextCursor = response.nextCursor
            hasMore = response.nextCursor > 0
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Подгрузка следующей порции

    func loadMore() async {
        guard hasMore, !isLoading, !isLoadingMore else { return }

        isLoadingMore = true

        do {
            let response: RecipeListResponse
            if isSearching {
                response = try await APIClient.shared.searchRecipes(
                    query: searchText,
                    cursor: nextCursor
                )
            } else {
                response = try await APIClient.shared.getRecipes(
                    cursor: nextCursor,
                    limit: pageSize,
                    cuisineID: selectedCuisineID,
                    maxCookTime: maxCookTime
                )
            }

            // Защита от дубликатов
            let existingIDs = Set(recipes.map { $0.id })
            let newRecipes = response.data.filter { !existingIDs.contains($0.id) }

            recipes.append(contentsOf: newRecipes)
            nextCursor = response.nextCursor
            hasMore = response.nextCursor > 0
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingMore = false
    }

    // Вызывается когда пользователь доскроллил до конкретного рецепта
    func loadMoreIfNeeded(currentItem: Recipe) async {
        // Начинаем подгружать за 5 элементов до конца списка
        guard let index = recipes.firstIndex(where: { $0.id == currentItem.id }) else { return }
        if index >= recipes.count - 5 {
            await loadMore()
        }
    }

    // MARK: - Поиск

    func search() async {
        guard !searchText.isEmpty else {
            await loadRecipes()
            return
        }

        isLoading = true
        errorMessage = nil
        nextCursor = 0
        hasMore = true

        do {
            let response = try await APIClient.shared.searchRecipes(
                query: searchText,
                cursor: 0
            )
            recipes = response.data
            nextCursor = response.nextCursor
            hasMore = response.nextCursor > 0
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - CRUD

    func createRecipe(_ request: CreateRecipeRequest) async {
        isLoading = true
        do {
            let newRecipe = try await APIClient.shared.createRecipe(request)
            recipes.insert(newRecipe, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteRecipe(id: Int) async {
        do {
            try await APIClient.shared.deleteRecipe(id: id)
            recipes.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Фильтры

    func applyFilters(cuisineID: Int, cookTime: Int) async {
        selectedCuisineID = cuisineID
        maxCookTime = cookTime
        await loadRecipes()
    }

    func resetFilters() async {
        selectedCuisineID = 0
        maxCookTime = 0
        searchText = ""
        await loadRecipes()
    }
}
