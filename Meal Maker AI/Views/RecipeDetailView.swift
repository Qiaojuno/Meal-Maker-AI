//
//  RecipeDetailView.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.dismiss) var dismiss
    let recipe: Recipe
    @StateObject private var viewModel: RecipeViewModel
    @State private var isSaved: Bool = false

    init(recipe: Recipe, viewModel: RecipeViewModel? = nil) {
        self.recipe = recipe
        self._viewModel = StateObject(wrappedValue: viewModel ?? RecipeViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image (full width, edge-to-edge) with action buttons
                ZStack(alignment: .top) {
                    heroImage

                    // Top overlay buttons
                    HStack {
                        // Back button (left)
                        backButton
                            .padding(.leading, 16)

                        Spacer()

                        // Action buttons (right)
                        HStack(spacing: 12) {
                            // Share button
                            shareButton

                            // Save button
                            saveButton
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 16)
                }

                VStack(alignment: .leading, spacing: 24) {
                    // Recipe Header (Title)
                    recipeHeader

                    // Meta Info Row (Time, Servings, Difficulty)
                    metaInfoRow

                    // Ingredients Section
                    ingredientsSection

                    // Instructions Section
                    instructionsSection

                    Spacer(minLength: 100)
                }
                .padding()
            }
        }
        .background(Color(red: 248/255, green: 248/255, blue: 248/255)) // #F8F8F8
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            isSaved = viewModel.isRecipeSaved(recipe.id)
        }
    }

    // MARK: - Subviews

    private var heroImage: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 90/255, green: 122/255, blue: 90/255),
                            Color(red: 74/255, green: 93/255, blue: 74/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.custom("Archivo-Regular", size: 80))
                        .foregroundColor(.white.opacity(0.5))
                )
                .frame(width: geometry.size.width)
        }
        .frame(height: 350)
        .edgesIgnoringSafeArea(.horizontal)
    }

    private var backButton: some View {
        Button(action: {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()

            dismiss()
        }) {
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "chevron.left")
                        .font(.custom("Archivo-SemiBold", size: 18))
                        .foregroundColor(Color(red: 44/255, green: 62/255, blue: 45/255))
                )
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
    }

    private var shareButton: some View {
        Button(action: shareRecipe) {
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "square.and.arrow.up")
                        .font(.custom("Archivo-SemiBold", size: 16))
                        .foregroundColor(Color(red: 44/255, green: 62/255, blue: 45/255))
                )
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
    }

    private var saveButton: some View {
        Button(action: toggleSave) {
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.custom("Archivo-SemiBold", size: 16))
                        .foregroundColor(isSaved ? Color(red: 74/255, green: 93/255, blue: 74/255) : Color(red: 44/255, green: 62/255, blue: 45/255))
                )
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
    }

    private var recipeHeader: some View {
        ZStack(alignment: .leading) {
            Text(recipe.title)
                .font(.custom("Archivo-Bold", size: 28))
                .foregroundColor(Color(red: 44/255, green: 62/255, blue: 45/255)) // #2C3E2D
                .opacity(0.5)
            Text(recipe.title)
                .font(.custom("Archivo-Bold", size: 28))
                .foregroundColor(Color(red: 44/255, green: 62/255, blue: 45/255)) // #2C3E2D
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(3)
    }

    private var metaInfoRow: some View {
        HStack(spacing: 12) {
            // Cook Time
            if let cookingTime = recipe.cookingTime {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.custom("Archivo-Regular", size: 14))
                    Text(cookingTime)
                        .font(.custom("Archivo-Medium", size: 14))
                }
                .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255)) // #666666
            }

            // Bullet separator
            if recipe.cookingTime != nil && recipe.servings != nil {
                Text("•")
                    .foregroundColor(.gray)
            }

            // Servings
            if let servings = recipe.servings {
                HStack(spacing: 6) {
                    Image(systemName: "person.2")
                        .font(.custom("Archivo-Regular", size: 14))
                    Text("\(servings) servings")
                        .font(.custom("Archivo-Medium", size: 14))
                }
                .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
            }

            // Bullet separator
            if recipe.servings != nil && recipe.difficulty != nil {
                Text("•")
                    .foregroundColor(.gray)
            }

            // Difficulty Badge (reusing existing component)
            if let difficulty = recipe.difficulty {
                DifficultyBadge(difficulty: difficulty)
            }
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .leading) {
                Text("Ingredients")
                    .font(.custom("Archivo-SemiBold", size: 20))
                    .foregroundColor(Color(red: 44/255, green: 62/255, blue: 45/255))
                    .opacity(0.5)
                Text("Ingredients")
                    .font(.custom("Archivo-SemiBold", size: 20))
                    .foregroundColor(Color(red: 44/255, green: 62/255, blue: 45/255))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Text("•")
                                .font(.custom("Archivo-Bold", size: 16))
                                .foregroundColor(categoryColor(for: ingredient))
                                .opacity(0.5)
                            Text("•")
                                .font(.custom("Archivo-Bold", size: 16))
                                .foregroundColor(categoryColor(for: ingredient))
                        }

                        Text(ingredient)
                            .font(.custom("Archivo-Regular", size: 16))
                            .foregroundColor(categoryColor(for: ingredient))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 4)
                            .background(categoryBackground(for: ingredient))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(categoryStroke(for: ingredient), lineWidth: 1)
                            )
                            .cornerRadius(6)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .leading) {
                Text("Instructions")
                    .font(.custom("Archivo-SemiBold", size: 20))
                    .foregroundColor(Color(red: 44/255, green: 62/255, blue: 45/255))
                    .opacity(0.5)
                Text("Instructions")
                    .font(.custom("Archivo-SemiBold", size: 20))
                    .foregroundColor(Color(red: 44/255, green: 62/255, blue: 45/255))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 74/255, green: 93/255, blue: 74/255))
                                .frame(width: 28, height: 28)

                            ZStack {
                                Text("\(index + 1)")
                                    .font(.custom("Archivo-Bold", size: 12))
                                    .foregroundColor(.white)
                                    .opacity(0.5)
                                Text("\(index + 1)")
                                    .font(.custom("Archivo-Bold", size: 12))
                                    .foregroundColor(.white)
                            }
                        }

                        Text(instruction)
                            .font(.custom("Archivo-Regular", size: 16))
                            .foregroundColor(Color(red: 44/255, green: 62/255, blue: 45/255))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)

                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    // MARK: - Helper Functions for Ingredient Color Coding

    private func detectCategory(for ingredient: String) -> String {
        let lowerIngredient = ingredient.lowercased()

        // Protein keywords (red)
        let proteinKeywords = ["chicken", "beef", "pork", "fish", "salmon", "tuna", "turkey", "lamb", "shrimp", "meat", "steak", "bacon", "sausage", "egg", "tofu"]
        if proteinKeywords.contains(where: { lowerIngredient.contains($0) }) {
            return "Protein"
        }

        // Dairy keywords (grey/white with stroke)
        let dairyKeywords = ["milk", "cheese", "yogurt", "cream", "butter", "parmesan", "mozzarella", "cheddar", "feta", "ricotta"]
        if dairyKeywords.contains(where: { lowerIngredient.contains($0) }) {
            return "Dairy"
        }

        // Carbohydrates keywords (yellow/orange)
        let carbKeywords = ["pasta", "rice", "bread", "flour", "penne", "spaghetti", "noodle", "grain", "oats", "cereal", "quinoa", "wheat", "tortilla"]
        if carbKeywords.contains(where: { lowerIngredient.contains($0) }) {
            return "Carbohydrates"
        }

        // Vegetables (green) - default
        return "Vegetables"
    }

    private func categoryColor(for ingredient: String) -> Color {
        let category = detectCategory(for: ingredient)
        switch category {
        case "Protein":
            return Color(red: 215/255, green: 108/255, blue: 108/255) // #D76C6C - Red
        case "Carbohydrates":
            return Color(red: 232/255, green: 168/255, blue: 124/255) // #E8A87C - Orange/Yellow
        case "Dairy":
            return Color(red: 102/255, green: 102/255, blue: 102/255) // #666666 - Grey
        default: // Vegetables
            return Color(red: 90/255, green: 122/255, blue: 90/255) // #5A7A5A - Green
        }
    }

    private func categoryBackground(for ingredient: String) -> Color {
        let category = detectCategory(for: ingredient)
        if category == "Dairy" {
            return Color.white
        }
        return Color.clear
    }

    private func categoryStroke(for ingredient: String) -> Color {
        let category = detectCategory(for: ingredient)
        if category == "Dairy" {
            return Color(red: 102/255, green: 102/255, blue: 102/255) // Grey stroke
        }
        return Color.clear
    }

    // MARK: - Actions

    private func toggleSave() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        if isSaved {
            viewModel.unsaveRecipe(recipe)
            isSaved = false
        } else {
            viewModel.saveRecipe(recipe)
            isSaved = true
        }
    }

    private func shareRecipe() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Format recipe as text
        var recipeText = "🍳 \(recipe.title)\n\n"

        if let time = recipe.cookingTime, let servings = recipe.servings {
            recipeText += "⏱️ \(time) | 👥 \(servings) servings\n\n"
        }

        recipeText += "📝 Ingredients:\n"
        for ingredient in recipe.ingredients {
            recipeText += "• \(ingredient)\n"
        }

        recipeText += "\n👨‍🍳 Instructions:\n"
        for (index, instruction) in recipe.instructions.enumerated() {
            recipeText += "\(index + 1). \(instruction)\n"
        }

        recipeText += "\n🤖 Generated with Meal4Me"

        // Present share sheet
        let activityVC = UIActivityViewController(
            activityItems: [recipeText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

}

#Preview {
    NavigationView {
        RecipeDetailView(
            recipe: Recipe(
                title: "Gordon Ramsay's Penne Pasta",
                ingredients: [
                    "1 lb penne pasta",
                    "2 cups marinara sauce",
                    "1 lb ground beef",
                    "1/2 cup parmesan cheese, grated",
                    "Fresh basil leaves",
                    "Salt and pepper to taste"
                ],
                instructions: [
                    "Boil pasta according to package directions until al dente",
                    "Brown ground beef in large skillet over medium-high heat",
                    "Add marinara sauce to beef and simmer for 10 minutes",
                    "Drain pasta and add to sauce mixture",
                    "Toss with parmesan cheese and garnish with basil",
                    "Season with salt and pepper, serve immediately"
                ],
                cookingTime: "20 minutes",
                difficulty: "Hard",
                servings: 2
            ),
            viewModel: RecipeViewModel()
        )
    }
}
