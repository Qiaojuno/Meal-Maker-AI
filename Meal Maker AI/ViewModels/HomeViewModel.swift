//
//  HomeViewModel.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var lastScanDate: Date?
    @Published var ingredientsByCategory: [String: [Ingredient]] = [:]
    @Published var recentRecipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let storageService = StorageService.shared
    private let geminiService = GeminiService()

    // MARK: - Computed Properties

    var categoryData: [(name: String, icon: String, color: Color, count: Int)] {
        [
            (
                name: "Vegetables",
                icon: "🥦",
                color: Color(red: 90/255, green: 122/255, blue: 90/255), // #5A7A5A
                count: ingredientsByCategory["Vegetables"]?.count ?? 0
            ),
            (
                name: "Carbohydrates",
                icon: "🍞",
                color: Color(red: 232/255, green: 168/255, blue: 124/255), // #E8A87C
                count: ingredientsByCategory["Carbohydrates"]?.count ?? 0
            ),
            (
                name: "Protein",
                icon: "🍗",
                color: Color(red: 215/255, green: 108/255, blue: 108/255), // #D76C6C
                count: ingredientsByCategory["Protein"]?.count ?? 0
            ),
            (
                name: "Dairy",
                icon: "🥛",
                color: Color(red: 229/255, green: 229/255, blue: 229/255), // #E5E5E5
                count: ingredientsByCategory["Dairy"]?.count ?? 0
            )
        ]
    }

    var lastUpdatedText: String {
        guard let date = lastScanDate else {
            return "Take your first scan"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return "Last updated: \(formatter.string(from: date))"
    }

    var hasScannedBefore: Bool {
        lastScanDate != nil
    }

    // MARK: - Initialization

    init() {
        loadData()
    }

    // MARK: - Public Methods

    /// Load all data from storage
    func loadData() {
        isLoading = true
        errorMessage = nil

        // Load last scan date
        lastScanDate = storageService.getLastScanDate()

        // Load ingredients and categorize
        let ingredients = storageService.getSavedIngredients()
        categorizeIngredients(ingredients)

        // Load recent recipes (last 10 generated, not just saved)
        recentRecipes = storageService.getRecentRecipes()

        isLoading = false
    }

    /// Generate new recipes from saved ingredients
    func generateNewRecipes() async {
        let ingredients = storageService.getSavedIngredients()

        guard !ingredients.isEmpty else {
            errorMessage = "No ingredients found. Please scan your fridge first."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let recipes = try await geminiService.generateRecipes(from: ingredients)

            // Add to recent recipes (NOT auto-save to bookmarks)
            storageService.addToRecentRecipes(recipes)

            // Reload recent recipes
            recentRecipes = storageService.getRecentRecipes()
        } catch let error as GeminiError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }

        isLoading = false
    }

    // MARK: - Private Methods

    /// Categorize ingredients by category field
    private func categorizeIngredients(_ ingredients: [Ingredient]) {
        var categorized: [String: [Ingredient]] = [
            "Vegetables": [],
            "Carbohydrates": [],
            "Protein": [],
            "Dairy": []
        ]

        for ingredient in ingredients {
            let category = ingredient.category ?? "Vegetables" // Default to Vegetables if no category
            if categorized[category] != nil {
                categorized[category]?.append(ingredient)
            }
        }

        ingredientsByCategory = categorized
    }
}
