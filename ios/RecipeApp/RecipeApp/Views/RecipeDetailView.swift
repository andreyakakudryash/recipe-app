
import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    let categories = ["burger", "butter-chicken", "dessert", "idly",
                      "pasta", "pizza", "rice", "samosa"]

    var imageURL: URL? {
        let category = categories[recipe.id % categories.count]
        let number = (recipe.id % 10) + 1
        return URL(string: "https://foodish-api.com/images/\(category)/\(category)\(number).jpg")
    }
    @State private var showEditForm = false
    @State private var ingredients: [Ingredient] = []
    @State private var isLoadingIngredients = false
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var favoritesStore: FavoritesStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Шапка с картинкой

                
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width, height: 320)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay(Image(systemName: "fork.knife").font(.system(size: 60)).foregroundStyle(.secondary))
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width, height: 320)
                    .clipped()

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .frame(width: UIScreen.main.bounds.width, height: 320)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(recipe.cuisineName.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                            .tracking(1.5)
                        Text(recipe.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                    .padding(20)
                }

                .frame(height: 320)

                // Контент
                VStack(alignment: .leading, spacing: 20) {

                    // Быстрая инфо
                    HStack(spacing: 0) {
                        QuickInfoItem(icon: "clock.fill", value: "\(recipe.cookTime)", unit: "минут", color: .blue)
                        Divider().frame(height: 50)
                        QuickInfoItem(icon: "person.2.fill", value: "\(recipe.servings)", unit: "порций", color: .green)
                        Divider().frame(height: 50)
                        QuickInfoItem(icon: "flame.fill", value: difficultyText, unit: "сложность", color: difficultyColor)
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)

                    // Описание
                    SectionCard(title: "Описание") {
                        Text(recipe.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(5)
                    }

                    // Ингредиенты
                    SectionCard(title: "Ингредиенты") {
                        if isLoadingIngredients {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else if ingredients.isEmpty {
                            Text("Ингредиенты не найдены")
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(ingredients) { ingredient in
                                    HStack {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundStyle(.orange)
                                        Text(ingredient.name)
                                            .font(.body)
                                        Spacer()
                                        Text("\(String(format: "%.0f", ingredient.amount)) \(ingredient.unit)")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 8)

                                    if ingredient.id != ingredients.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                    // Детали
                    SectionCard(title: "Детали") {
                        VStack(spacing: 8) {
                            DetailRow(label: "Кухня", value: recipe.cuisineName, icon: "globe")
                            DetailRow(label: "Время", value: "\(recipe.cookTime) минут", icon: "clock.fill")
                            DetailRow(label: "Порций", value: "\(recipe.servings)", icon: "person.2.fill")
                            DetailRow(label: "Сложность", value: difficultyText, icon: "flame.fill")
                        }
                    }
                }
                .padding(16)
                .background(Color(.systemGroupedBackground))
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        if favoritesStore.isFavorite(recipe) {
                            favoritesStore.remove(recipe)
                        } else {
                            favoritesStore.add(recipe)
                        }
                    } label: {
                        Image(systemName: favoritesStore.isFavorite(recipe) ? "heart.fill" : "heart")
                            .foregroundStyle(.red)
                    }

                    Button("Изменить") { showEditForm = true }
                        .foregroundStyle(.orange)
                }
            }
        }
        .sheet(isPresented: $showEditForm) {
            RecipeFormView(recipe: recipe) { _ in }
        }
        .task {
            isLoadingIngredients = true
            ingredients = (try? await APIClient.shared.getIngredients(recipeID: recipe.id)) ?? []
            isLoadingIngredients = false
        }
    }

    var difficultyText: String {
        switch recipe.difficulty {
        case 1: return "Легко"
        case 2: return "Несложно"
        case 3: return "Средне"
        case 4: return "Сложно"
        case 5: return "Шеф"
        default: return "—"
        }
    }

    var difficultyColor: Color {
        switch recipe.difficulty {
        case 1, 2: return .green
        case 3:    return .orange
        case 4, 5: return .red
        default:   return .gray
        }
    }
}

// MARK: - Вспомогательные компоненты

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            content
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

struct QuickInfoItem: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.orange)
                .frame(width: 20)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}
