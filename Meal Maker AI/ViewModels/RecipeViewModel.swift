//
//  RecipeViewModel.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import Foundation

@MainActor
class RecipeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var generatedRecipes: [Recipe] = []
    @Published var isGenerating = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let geminiService = GeminiService()
    private let storageService = StorageService.shared
    private let pexelsService = PexelsService()

    // MARK: - Public Methods

    /// Generate recipes from ingredients
    func generateRecipes(from ingredients: [Ingredient]) async {
        generatedRecipes = []
        errorMessage = nil
        isGenerating = true

        do {
            let recipes = try await geminiService.generateRecipes(from: ingredients)

            // Images will be loaded lazily when displayed (no Pexels call here)
            generatedRecipes = recipes

            // Add to recent recipes list (for home screen display)
            storageService.addToRecentRecipes(recipes)
        } catch let error as GeminiError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }

        isGenerating = false
    }

    /// Save a recipe to local storage
    func saveRecipe(_ recipe: Recipe) {
        storageService.saveRecipe(recipe)

        // Update local state to reflect saved status
        if let index = generatedRecipes.firstIndex(where: { $0.id == recipe.id }) {
            generatedRecipes[index].isSaved = true
        }
    }

    /// Unsave (delete) a recipe from local storage
    func unsaveRecipe(_ recipe: Recipe) {
        storageService.deleteRecipe(recipe)

        // Update local state to reflect unsaved status
        if let index = generatedRecipes.firstIndex(where: { $0.id == recipe.id }) {
            generatedRecipes[index].isSaved = false
        }
    }

    /// Check if a recipe is saved
    func isRecipeSaved(_ recipeId: UUID) -> Bool {
        return storageService.isRecipeSaved(recipeId: recipeId)
    }

    /// Fetch image for a recipe (lazy loading)
    func fetchImageIfNeeded(for recipe: Recipe) async -> String? {
        // If recipe already has an image URL, return it
        if let imageURL = recipe.imageURL {
            return imageURL
        }

        // Otherwise, fetch from Pexels
        if let imageURL = try? await pexelsService.searchFoodPhoto(for: recipe.title) {
            // Update the recipe in storage with the new image URL
            var updatedRecipe = recipe
            updatedRecipe.imageURL = imageURL
            storageService.updateRecipe(updatedRecipe)
            return imageURL
        }

        return nil
    }

    /// Reset state
    func reset() {
        generatedRecipes = []
        errorMessage = nil
        isGenerating = false
    }
}
