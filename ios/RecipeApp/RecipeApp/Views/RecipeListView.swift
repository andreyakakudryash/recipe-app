import SwiftUI

class AppSettings: ObservableObject {
    @Published var colorScheme: ColorScheme? = nil
    @Published var gridColumns: Int = 1
}

struct RecipeListView: View {
    @StateObject private var viewModel = RecipeViewModel()
    @StateObject private var settings = AppSettings()
    @State private var showCreateForm = false
    @State private var showFilters = false

    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: settings.gridColumns)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Поиск
                SearchBar(text: $viewModel.searchText, onSearch: {
                    Task { await viewModel.search() }
                })
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Список
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Загрузка...")
                    Spacer()
                } else if viewModel.recipes.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "Рецепты не найдены",
                        systemImage: "fork.knife",
                        description: Text("Попробуйте изменить фильтры")
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.recipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    RecipeCardView(recipe: recipe, compact: settings.gridColumns > 1)
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    Task { await viewModel.loadMoreIfNeeded(currentItem: recipe) }
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        Task { await viewModel.deleteRecipe(id: recipe.id) }
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                        // Индикатор подгрузки
                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView("Загружаем ещё...")
                                    .padding(.vertical, 16)
                                Spacer()
                            }
                        }

                        // Конец списка
                        if !viewModel.hasMore && !viewModel.recipes.isEmpty {
                            Text("Все рецепты загружены")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .refreshable {
                        await viewModel.loadRecipes()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Рецепты")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showFilters = true } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        // Сетка 1 или 2
                        Button {
                            withAnimation {
                                settings.gridColumns = settings.gridColumns == 1 ? 2 : 1
                            }
                        } label: {
                            Image(systemName: settings.gridColumns == 1 ? "rectangle" : "rectangle.split.2x1")
                        }

                        // Тема
                        Button {
                            withAnimation {
                                if settings.colorScheme == nil {
                                    settings.colorScheme = .dark
                                } else if settings.colorScheme == .dark {
                                    settings.colorScheme = .light
                                } else {
                                    settings.colorScheme = nil
                                }
                            }
                        } label: {
                            Image(systemName: themeIcon)
                        }

                        // Добавить
                        Button { showCreateForm = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateForm) {
                RecipeFormView { request in
                    Task { await viewModel.createRecipe(request) }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterView(viewModel: viewModel)
            }
            .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                if viewModel.recipes.isEmpty {
                    await viewModel.loadRecipes()
                }
            }
        }
        .preferredColorScheme(settings.colorScheme)
    }

    var themeIcon: String {
        switch settings.colorScheme {
        case .dark:  return "moon.fill"
        case .light: return "sun.max.fill"
        default:     return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Карточка рецепта

struct RecipeCardView: View {
    let recipe: Recipe
    var compact: Bool = false

    let categories = ["burger", "butter-chicken", "dessert", "idly",
                      "pasta", "pizza", "rice", "samosa"]

    var imageURL: URL? {
        let category = categories[recipe.id % categories.count]
        let number = (recipe.id % 10) + 1
        return URL(string: "https://foodish-api.com/images/\(category)/\(category)\(number).jpg")
    }

    var cardHeight: CGFloat { compact ? 110 : 190 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Картинка с фиксированными размерами
            GeometryReader { geo in
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
                            .frame(width: geo.size.width, height: cardHeight)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "fork.knife")
                                    .foregroundStyle(.secondary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: geo.size.width, height: cardHeight)
                .clipped()
            }
            .frame(height: cardHeight)

            // Текст
            VStack(alignment: .leading, spacing: compact ? 4 : 8) {
                Text(recipe.cuisineName.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
                    .tracking(1)

                Text(recipe.title)
                    .font(compact ? .caption : .headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !compact {
                    Text(recipe.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()
                }

                HStack(spacing: compact ? 6 : 12) {
                    MetaTag(icon: "clock.fill", text: "\(recipe.cookTime)м", color: .blue)
                    if !compact {
                        MetaTag(icon: "person.2.fill", text: "\(recipe.servings)", color: .green)
                        MetaTag(icon: "flame.fill", text: difficultyText, color: difficultyColor)
                    }
                    Spacer()
                }
                .font(.caption)
            }
            .padding(compact ? 8 : 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 3)
    }

    var difficultyText: String {
        switch recipe.difficulty {
        case 1: return "Легко"
        case 2: return "Несложно"
        case 3: return "Средне"
        case 4: return "Сложно"
        default: return "Шеф"
        }
    }

    var difficultyColor: Color {
        switch recipe.difficulty {
        case 1, 2: return .green
        case 3:    return .orange
        default:   return .red
        }
    }
}

// MARK: - Поиск

struct SearchBar: View {
    @Binding var text: String
    let onSearch: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Поиск рецептов...", text: $text)
                .onSubmit { onSearch() }
                .submitLabel(.search)
            if !text.isEmpty {
                Button {
                    text = ""
                    onSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Фильтры

struct FilterView: View {
    @ObservedObject var viewModel: RecipeViewModel
    @Environment(\.dismiss) var dismiss
    @State private var cuisineID = 0
    @State private var cookTime = 0

    let cuisines = [
        (0, "Все кухни"),    (1, "Итальянская"), (2, "Японская"),
        (3, "Мексиканская"), (4, "Французская"), (5, "Индийская"),
        (6, "Китайская"),    (7, "Русская"),      (8, "Греческая"),
        (9, "Американская"), (10, "Тайская")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Кухня") {
                    Picker("Кухня", selection: $cuisineID) {
                        ForEach(cuisines, id: \.0) { id, name in
                            Text(name).tag(id)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                Section("Максимальное время готовки") {
                    Picker("Время", selection: $cookTime) {
                        Text("Любое").tag(0)
                        Text("до 15 мин").tag(15)
                        Text("до 30 мин").tag(30)
                        Text("до 60 мин").tag(60)
                        Text("до 90 мин").tag(90)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Фильтры")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Сбросить") {
                        Task { await viewModel.resetFilters(); dismiss() }
                    }
                    .foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Применить") {
                        Task {
                            await viewModel.applyFilters(cuisineID: cuisineID, cookTime: cookTime)
                            dismiss()
                        }
                    }
                    .bold()
                    .foregroundStyle(.orange)
                }
            }
        }
    }
}

// MARK: - Мета тег

struct MetaTag: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(text).foregroundStyle(.secondary)
        }
    }
}
