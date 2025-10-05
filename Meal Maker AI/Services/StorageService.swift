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
    private let savedRecipesKey = "savedRecipes"  // Only bookmarked recipes
    private let recentRecipesKey = "recentRecipes"  // Last generated recipes
    private let savedIngredientsKey = "savedIngredients"
    private let lastScanDateKey = "lastScanDate"

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
    /// - Returns: Array of saved recipes (only bookmarked), sorted by creation date (newest first)
    func getSavedRecipes() -> [Recipe] {
        guard let data = userDefaults.data(forKey: savedRecipesKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let recipes = try decoder.decode([Recipe].self, from: data)
            // Filter to only return recipes that are actually saved (bookmarked)
            return recipes
                .filter { $0.isSaved }
                .sorted { $0.createdAt > $1.createdAt }  // Newest first
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

    /// Clean up old unsaved recipes from storage
    /// This removes recipes that were auto-saved in the old schema
    func cleanupOldRecipes() {
        guard let data = userDefaults.data(forKey: savedRecipesKey) else {
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let allRecipes = try decoder.decode([Recipe].self, from: data)

            // Keep only recipes that are actually saved
            let savedOnly = allRecipes.filter { $0.isSaved }

            // Persist cleaned list
            persist(recipes: savedOnly)

            print("✅ Cleaned up saved recipes: removed \(allRecipes.count - savedOnly.count) unsaved recipes")
        } catch {
            print("❌ Error cleaning up recipes: \(error)")
        }
    }

    // MARK: - Ingredients Storage

    /// Save ingredients from fridge scan
    /// - Parameter ingredients: Array of ingredients to save
    func saveIngredients(_ ingredients: [Ingredient]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(ingredients)
            userDefaults.set(data, forKey: savedIngredientsKey)

            // Update last scan date
            userDefaults.set(Date(), forKey: lastScanDateKey)
        } catch {
            print("❌ Error encoding ingredients: \(error)")
        }
    }

    /// Get saved ingredients from last fridge scan
    /// - Returns: Array of saved ingredients
    func getSavedIngredients() -> [Ingredient] {
        guard let data = userDefaults.data(forKey: savedIngredientsKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let ingredients = try decoder.decode([Ingredient].self, from: data)
            return ingredients
        } catch {
            print("❌ Error decoding saved ingredients: \(error)")
            return []
        }
    }

    /// Get the date of last fridge scan
    /// - Returns: Date of last scan, or nil if never scanned
    func getLastScanDate() -> Date? {
        return userDefaults.object(forKey: lastScanDateKey) as? Date
    }

    /// Delete all saved ingredients
    func deleteAllIngredients() {
        userDefaults.removeObject(forKey: savedIngredientsKey)
        userDefaults.removeObject(forKey: lastScanDateKey)
    }

    // MARK: - Recent Recipes Storage

    /// Save recently generated recipes (last 10)
    /// - Parameter recipes: Array of recipes to save as recent
    func saveRecentRecipes(_ recipes: [Recipe]) {
        // Only keep last 10
        let recentRecipes = Array(recipes.prefix(10))

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(recentRecipes)
            userDefaults.set(data, forKey: recentRecipesKey)
        } catch {
            print("❌ Error encoding recent recipes: \(error)")
        }
    }

    /// Get recently generated recipes
    /// - Returns: Array of recent recipes (last 10 generated)
    func getRecentRecipes() -> [Recipe] {
        guard let data = userDefaults.data(forKey: recentRecipesKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let recipes = try decoder.decode([Recipe].self, from: data)
            return recipes.sorted { $0.createdAt > $1.createdAt }  // Newest first
        } catch {
            print("❌ Error decoding recent recipes: \(error)")
            return []
        }
    }

    /// Add new recipes to recent list
    /// - Parameter newRecipes: New recipes to add
    func addToRecentRecipes(_ newRecipes: [Recipe]) {
        var allRecent = getRecentRecipes()
        // Prepend new recipes
        allRecent.insert(contentsOf: newRecipes, at: 0)
        // Keep only last 10
        saveRecentRecipes(Array(allRecent.prefix(10)))
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
