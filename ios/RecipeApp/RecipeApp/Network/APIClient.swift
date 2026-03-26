
import Foundation

class APIClient {
    static let shared = APIClient()

    private let baseURL = "http://localhost:8080/api/v1"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        session = URLSession(configuration: config)
}

    // Получить список рецептов
    func getRecipes(
        cursor: Int = 0,
        limit: Int = 20,
        cuisineID: Int = 0,
        maxCookTime: Int = 0
    ) async throws -> RecipeListResponse {
        var urlString = "\(baseURL)/recipes?limit=\(limit)"
        if cursor > 0      { urlString += "&cursor=\(cursor)" }
        if cuisineID > 0   { urlString += "&cuisine_id=\(cuisineID)" }
        if maxCookTime > 0 { urlString += "&max_cook_time=\(maxCookTime)" }

        return try await fetch(urlString)
    }

    // Поиск рецептов
    func searchRecipes(query: String, cursor: Int = 0) async throws -> RecipeListResponse {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/recipes/search?q=\(encoded)&cursor=\(cursor)"
        return try await fetch(urlString)
    }

    // Получить один рецепт
    func getRecipe(id: Int) async throws -> Recipe {
        return try await fetch("\(baseURL)/recipes/\(id)")
    }

    // Создать рецепт
    func createRecipe(_ request: CreateRecipeRequest) async throws -> Recipe {
        return try await send(urlString: "\(baseURL)/recipes", method: "POST", body: request)
    }

    // Обновить рецепт
    func updateRecipe(id: Int, _ request: CreateRecipeRequest) async throws -> Recipe {
        return try await send(urlString: "\(baseURL)/recipes/\(id)", method: "PUT", body: request)
    }

    // Удалить рецепт
    func deleteRecipe(id: Int) async throws {
        guard let url = URL(string: "\(baseURL)/recipes/\(id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError.serverError
        }
    }

    // Получить ингредиенты рецепта
    func getIngredients(recipeID: Int) async throws -> [Ingredient] {
        let response: IngredientsResponse = try await fetch("\(baseURL)/recipes/\(recipeID)/ingredients")
        return response.data
}
    func getCount() async throws -> Int {
        struct CountResponse: Decodable { let count: Int }
        let response: CountResponse = try await fetch("\(baseURL)/recipes/count")
        return response.count
    }

    // MARK: - Private helpers

    private func fetch<T: Decodable>(_ urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        let (data, response) = try await session.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError.serverError
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func send<T: Decodable, B: Encodable>(
        urlString: String,
        method: String,
        body: B
    ) async throws -> T {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 ||
              (response as? HTTPURLResponse)?.statusCode == 201 else {
            throw APIError.serverError
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case serverError

    var errorDescription: String? {
        switch self {
        case .invalidURL:   return "Неверный URL"
        case .serverError:  return "Ошибка сервера"
        }
    }
}
