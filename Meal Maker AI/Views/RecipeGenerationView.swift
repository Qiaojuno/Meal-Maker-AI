//
//  RecipeGenerationView.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import SwiftUI

struct RecipeGenerationView: View {
    @StateObject private var viewModel = RecipeViewModel()
    let ingredients: [Ingredient]

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if viewModel.isGenerating {
                generatingView
            } else if !viewModel.generatedRecipes.isEmpty {
                recipesListView
            } else {
                // Initial state - trigger generation
                Color.clear
                    .onAppear {
                        Task {
                            await viewModel.generateRecipes(from: ingredients)
                        }
                    }
            }
        }
        .navigationTitle("Recipes")
        .navigationBarTitleDisplayMode(.large)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Try Again") {
                viewModel.errorMessage = nil
                Task {
                    await viewModel.generateRecipes(from: ingredients)
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Subviews

    private var generatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Creating recipes for you...")
                .font(.custom("Archivo-SemiBold", size: 17))

            Text("This may take a few seconds")
                .font(.custom("Archivo-Regular", size: 15))
                .foregroundColor(.gray)
        }
    }

    private var recipesListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("\(viewModel.generatedRecipes.count) Recipes Found")
                    .font(.custom("Archivo-Regular", size: 15))
                    .foregroundColor(.gray)
                    .padding(.top)

                ForEach(viewModel.generatedRecipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe, viewModel: viewModel)) {
                        RecipePreviewCard(recipe: recipe)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

// MARK: - Recipe Preview Card

struct RecipePreviewCard: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            ZStack {
                Text(recipe.title)
                    .font(.custom("Archivo-Bold", size: 20))
                    .foregroundColor(.primary)
                    .opacity(0.5)
                Text(recipe.title)
                    .font(.custom("Archivo-Bold", size: 20))
                    .foregroundColor(.primary)
            }

            // Meta info
            HStack(spacing: 16) {
                if let cookingTime = recipe.cookingTime {
                    Label(cookingTime, systemImage: "clock")
                        .font(.custom("Archivo-Regular", size: 15))
                        .foregroundColor(.gray)
                }

                if let difficulty = recipe.difficulty {
                    Label(difficulty.capitalized, systemImage: "chart.bar")
                        .font(.custom("Archivo-Regular", size: 15))
                        .foregroundColor(.gray)
                }

                if let servings = recipe.servings {
                    Label("\(servings) servings", systemImage: "person.2")
                        .font(.custom("Archivo-Regular", size: 15))
                        .foregroundColor(.gray)
                }
            }

            // Ingredients preview
            Text("\(recipe.ingredients.count) ingredients")
                .font(.custom("Archivo-Regular", size: 12))
                .foregroundColor(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

#Preview {
    NavigationView {
        RecipeGenerationView(ingredients: [
            Ingredient(name: "Chicken", quantity: "2 pieces"),
            Ingredient(name: "Rice", quantity: "1 cup")
        ])
    }
}
