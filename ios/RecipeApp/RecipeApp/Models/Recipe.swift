
import Foundation

struct Recipe: Identifiable, Codable {
    let id: Int
    let title: String
    let description: String
    let cuisineId: Int
    let cuisineName: String
    let cookTime: Int
    let servings: Int
    let difficulty: Int
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case cuisineId    = "cuisine_id"
        case cuisineName  = "cuisine_name"
        case cookTime     = "cook_time"
        case servings
        case difficulty
        case createdAt    = "created_at"
    }
}

struct RecipeListResponse: Codable {
    let data: [Recipe]
    let nextCursor: Int

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}

struct CreateRecipeRequest: Codable {
    let title: String
    let description: String
    let cuisineId: Int
    let cookTime: Int
    let servings: Int
    let difficulty: Int

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case cuisineId  = "cuisine_id"
        case cookTime   = "cook_time"
        case servings
        case difficulty
    }
}

struct Ingredient: Codable, Identifiable {
    var id: String { name }
    let name: String
    let amount: Double
    let unit: String
}

struct IngredientsResponse: Codable {
    let data: [Ingredient]
}