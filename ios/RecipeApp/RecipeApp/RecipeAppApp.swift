

import SwiftUI

@main
struct RecipeAppApp: App {
    @StateObject private var favoritesStore = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                RecipeListView()
                    .tabItem {
                        Label("Рецепты", systemImage: "fork.knife")
                    }

                FavoritesView()
                    .tabItem {
                        Label("Мои рецепты", systemImage: "heart.fill")
                    }
            }
            .environmentObject(favoritesStore)
        }
    }
}
