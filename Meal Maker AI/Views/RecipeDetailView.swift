//
//  RecipeDetailView.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @ObservedObject var viewModel: RecipeViewModel
    @State private var isSaved: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section
                headerSection

                // Ingredients section
                ingredientsSection

                // Instructions section
                instructionsSection

                Spacer(minLength: 100)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                saveButton
            }
        }
        .onAppear {
            isSaved = viewModel.isRecipeSaved(recipe.id)
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Meta info
            HStack(spacing: 20) {
                if let cookingTime = recipe.cookingTime {
                    MetaLabel(icon: "clock", text: cookingTime)
                }

                if let difficulty = recipe.difficulty {
                    MetaLabel(icon: "chart.bar", text: difficulty.capitalized)
                }

                if let servings = recipe.servings {
                    MetaLabel(icon: "person.2", text: "\(servings) servings")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)

                        Text(ingredient)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 28, height: 28)

                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }

                        Text(instruction)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }

    private var saveButton: some View {
        Button(action: toggleSave) {
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .foregroundColor(isSaved ? .blue : .gray)
        }
    }

    // MARK: - Actions

    private func toggleSave() {
        if !isSaved {
            viewModel.saveRecipe(recipe)
            isSaved = true
        }
    }
}

// MARK: - Meta Label

struct MetaLabel: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)

            Text(text)
                .font(.caption)
        }
        .foregroundColor(.gray)
    }
}

#Preview {
    NavigationView {
        RecipeDetailView(
            recipe: Recipe(
                title: "Chicken Stir Fry",
                ingredients: [
                    "2 chicken breasts, diced",
                    "1 cup rice",
                    "2 cups vegetables",
                    "2 tbsp soy sauce"
                ],
                instructions: [
                    "Cook rice according to package instructions",
                    "Heat oil in large pan over medium-high heat",
                    "Add chicken and cook until browned",
                    "Add vegetables and stir fry for 5 minutes",
                    "Add soy sauce and serve over rice"
                ],
                cookingTime: "25 minutes",
                difficulty: "easy",
                servings: 2
            ),
            viewModel: RecipeViewModel()
        )
    }
}
