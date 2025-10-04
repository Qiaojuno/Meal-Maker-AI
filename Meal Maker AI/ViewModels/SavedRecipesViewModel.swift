//
//  SavedRecipesViewModel.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import Foundation

@MainActor
class SavedRecipesViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var savedRecipes: [Recipe] = []

    // MARK: - Private Properties

    private let storageService = StorageService.shared

    // MARK: - Initialization

    init() {
        loadSavedRecipes()
    }

    // MARK: - Public Methods

    /// Load saved recipes from storage
    func loadSavedRecipes() {
        savedRecipes = storageService.getSavedRecipes()
    }

    /// Delete a recipe
    func deleteRecipe(_ recipe: Recipe) {
        storageService.deleteRecipe(recipe)
        loadSavedRecipes()  // Refresh list
    }

    /// Delete recipe at index (for SwiftUI list)
    func deleteRecipe(at indexSet: IndexSet) {
        for index in indexSet {
            let recipe = savedRecipes[index]
            deleteRecipe(recipe)
        }
    }
}
