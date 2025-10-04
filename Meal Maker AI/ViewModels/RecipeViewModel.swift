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

    // MARK: - Public Methods

    /// Generate recipes from ingredients
    func generateRecipes(from ingredients: [Ingredient]) async {
        generatedRecipes = []
        errorMessage = nil
        isGenerating = true

        do {
            let recipes = try await geminiService.generateRecipes(from: ingredients)
            generatedRecipes = recipes
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

    /// Check if a recipe is saved
    func isRecipeSaved(_ recipeId: UUID) -> Bool {
        return storageService.isRecipeSaved(recipeId: recipeId)
    }

    /// Reset state
    func reset() {
        generatedRecipes = []
        errorMessage = nil
        isGenerating = false
    }
}
