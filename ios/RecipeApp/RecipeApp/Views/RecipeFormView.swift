
import SwiftUI

struct RecipeFormView: View {
    var recipe: Recipe? = nil
    var onSave: (CreateRecipeRequest) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var cuisineID = 1
    @State private var cookTime = 30
    @State private var servings = 4
    @State private var difficulty = 2

    let cuisines = [
        (1, "Итальянская"), (2, "Японская"),  (3, "Мексиканская"),
        (4, "Французская"), (5, "Индийская"), (6, "Китайская"),
        (7, "Русская"),     (8, "Греческая"), (9, "Американская"),
        (10, "Тайская")
    ]

    var isEditing: Bool { recipe != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название рецепта", text: $title)
                    TextField("Описание", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Кухня") {
                    Picker("Кухня", selection: $cuisineID) {
                        ForEach(cuisines, id: \.0) { id, name in
                            Text(name).tag(id)
                        }
                    }
                }

                Section("Детали") {
                    Stepper("Время готовки: \(cookTime) мин", value: $cookTime, in: 5...300, step: 5)
                    Stepper("Порций: \(servings)", value: $servings, in: 1...20)
                    Picker("Сложность", selection: $difficulty) {
                        Text("Легко").tag(1)
                        Text("Несложно").tag(2)
                        Text("Средне").tag(3)
                        Text("Сложно").tag(4)
                        Text("Шеф").tag(5)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(isEditing ? "Редактировать" : "Новый рецепт")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") {
                        let request = CreateRecipeRequest(
                            title: title,
                            description: description,
                            cuisineId: cuisineID,
                            cookTime: cookTime,
                            servings: servings,
                            difficulty: difficulty
                        )
                        onSave(request)
                        dismiss()
                    }
                    .bold()
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let recipe {
                    title       = recipe.title
                    description = recipe.description
                    cuisineID   = recipe.cuisineId
                    cookTime    = recipe.cookTime
                    servings    = recipe.servings
                    difficulty  = recipe.difficulty
                }
            }
        }
    }
}
