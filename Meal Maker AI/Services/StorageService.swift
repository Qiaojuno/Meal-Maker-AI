//
//  StorageService.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import Foundation

/// Service for persisting recipes locally using UserDefaults
class StorageService {
    // Singleton instance
    static let shared = StorageService()

    private let userDefaults = UserDefaults.standard
    private let savedRecipesKey = "savedRecipes"

    private init() {}  // Private init for singleton

    // MARK: - Public Methods

    /// Save a recipe to local storage
    /// - Parameter recipe: Recipe to save
    func saveRecipe(_ recipe: Recipe) {
        var savedRecipes = getSavedRecipes()

        // Create a mutable copy with isSaved = true
        var recipeToSave = recipe
        recipeToSave.isSaved = true

        // Check if recipe already exists (by id)
        if let existingIndex = savedRecipes.firstIndex(where: { $0.id == recipeToSave.id }) {
            // Update existing recipe
            savedRecipes[existingIndex] = recipeToSave
        } else {
            // Add new recipe
            savedRecipes.append(recipeToSave)
        }

        // Persist to UserDefaults
        persist(recipes: savedRecipes)
    }

    /// Get all saved recipes
    /// - Returns: Array of saved recipes, sorted by creation date (newest first)
    func getSavedRecipes() -> [Recipe] {
        guard let data = userDefaults.data(forKey: savedRecipesKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let recipes = try decoder.decode([Recipe].self, from: data)
            return recipes.sorted { $0.createdAt > $1.createdAt }  // Newest first
        } catch {
            print("❌ Error decoding saved recipes: \(error)")
            return []
        }
    }

    /// Delete a recipe from local storage
    /// - Parameter recipe: Recipe to delete
    func deleteRecipe(_ recipe: Recipe) {
        var savedRecipes = getSavedRecipes()
        savedRecipes.removeAll { $0.id == recipe.id }
        persist(recipes: savedRecipes)
    }

    /// Check if a recipe is saved
    /// - Parameter recipeId: ID of the recipe to check
    /// - Returns: True if recipe is saved, false otherwise
    func isRecipeSaved(recipeId: UUID) -> Bool {
        return getSavedRecipes().contains { $0.id == recipeId }
    }

    /// Delete all saved recipes (useful for testing/reset)
    func deleteAllRecipes() {
        userDefaults.removeObject(forKey: savedRecipesKey)
    }

    // MARK: - Private Methods

    /// Persist recipes array to UserDefaults
    private func persist(recipes: [Recipe]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(recipes)
            userDefaults.set(data, forKey: savedRecipesKey)
        } catch {
            print("❌ Error encoding recipes: \(error)")
        }
    }
}
