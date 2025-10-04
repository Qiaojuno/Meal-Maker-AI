//
//  ContentView.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Camera/Scan Flow
            HomeTabView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // History Tab - Saved Recipes
            SavedRecipesView()
                .tabItem {
                    Label("History", systemImage: "bookmark.fill")
                }
                .tag(1)
        }
        .accentColor(.blue)
    }
}

// MARK: - Home Tab View

struct HomeTabView: View {
    @State private var navigationPath = NavigationPath()
    @State private var identifiedIngredients: [Ingredient] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            CameraView { ingredients in
                identifiedIngredients = ingredients
                navigationPath.append(NavigationDestination.ingredientList)
            }
            .navigationTitle("FridgeScanner")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .ingredientList:
                    IngredientListView(
                        ingredients: identifiedIngredients,
                        onConfirm: { confirmedIngredients in
                            identifiedIngredients = confirmedIngredients
                            navigationPath.append(NavigationDestination.recipeGeneration)
                        },
                        onRescan: {
                            navigationPath.removeLast()  // Go back to camera
                        }
                    )

                case .recipeGeneration:
                    RecipeGenerationView(ingredients: identifiedIngredients)
                }
            }
        }
    }
}

// MARK: - Navigation Destination

enum NavigationDestination: Hashable {
    case ingredientList
    case recipeGeneration
}

#Preview {
    ContentView()
}
