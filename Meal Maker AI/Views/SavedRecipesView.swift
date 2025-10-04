//
//  SavedRecipesView.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import SwiftUI

struct SavedRecipesView: View {
    @StateObject private var viewModel = SavedRecipesViewModel()
    @StateObject private var recipeViewModel = RecipeViewModel()  // For detail view

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if viewModel.savedRecipes.isEmpty {
                    emptyStateView
                } else {
                    recipesList
                }
            }
            .navigationTitle("Saved Recipes")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadSavedRecipes()
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Saved Recipes")
                .font(.title2)
                .fontWeight(.bold)

            Text("Recipes you save will appear here")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var recipesList: some View {
        List {
            ForEach(viewModel.savedRecipes) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe, viewModel: recipeViewModel)) {
                    SavedRecipeRow(recipe: recipe)
                }
            }
            .onDelete(perform: viewModel.deleteRecipe)
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Saved Recipe Row

struct SavedRecipeRow: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.title)
                .font(.headline)

            HStack(spacing: 12) {
                if let cookingTime = recipe.cookingTime {
                    Label(cookingTime, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                if let difficulty = recipe.difficulty {
                    Label(difficulty.capitalized, systemImage: "chart.bar")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Text("Saved \(recipe.createdAt, formatter: relativeDateFormatter)")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }

    private var relativeDateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }
}

#Preview {
    SavedRecipesView()
}
