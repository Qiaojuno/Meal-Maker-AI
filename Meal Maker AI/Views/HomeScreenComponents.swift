//
//  HomeScreenComponents.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import SwiftUI

// MARK: - Last Updated Card

struct LastUpdatedCard: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .font(.title3)
                    .foregroundColor(.white)

                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color(red: 39/255, green: 45/255, blue: 28/255)) // #272D1C
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Ingredient Category Card

struct IngredientCategoryCard: View {
    let name: String
    let icon: String
    let color: Color
    let count: Int
    let ingredients: [Ingredient]
    @Binding var isExpanded: Bool

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }) {
            VStack(spacing: 0) {
                // Header (always visible)
                HStack(spacing: 16) {
                    // Icon
                    Text(icon)
                        .font(.system(size: 32))

                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.headline)
                            .foregroundColor(.white)

                        if !isExpanded {
                            Text("\(count) item\(count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()

                    // Chevron
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(0)) // Smooth rotation handled by icon change
                }
                .padding()

                // Expanded content (2-column grid)
                if isExpanded && !ingredients.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(ingredients) { ingredient in
                            Text(ingredient.name.capitalized)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
            .background(count == 0 ? color.opacity(0.5) : color)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(count == 0)
    }
}

// MARK: - Recipe Card

struct RecipeCard: View {
    let recipe: Recipe
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Recipe image placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.title2)
                            .foregroundColor(.white)
                    )

                // Recipe details
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.title)
                        .font(.headline)
                        .foregroundColor(.black)
                        .lineLimit(2)

                    HStack(spacing: 12) {
                        // Time
                        if let time = recipe.cookingTime {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text(time)
                                    .font(.caption)
                            }
                            .foregroundColor(.gray)
                        }

                        // Difficulty badge
                        if let difficulty = recipe.difficulty {
                            DifficultyBadge(difficulty: difficulty)
                        }
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Difficulty Badge

struct DifficultyBadge: View {
    let difficulty: String

    private var badgeColor: Color {
        switch difficulty.lowercased() {
        case "easy":
            return Color(red: 90/255, green: 122/255, blue: 90/255) // Green
        case "medium":
            return Color(red: 232/255, green: 168/255, blue: 124/255) // Orange
        case "hard":
            return Color(red: 215/255, green: 108/255, blue: 108/255) // Red
        default:
            return Color.gray
        }
    }

    var body: some View {
        Text(difficulty.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor)
            .cornerRadius(6)
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    @Binding var showMenu: Bool
    let onScanFridge: () -> Void
    let onGenerateRecipes: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Dimmed background when menu is open
            if showMenu {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showMenu = false
                        }
                    }
            }

            VStack(alignment: .trailing, spacing: 16) {
                // Menu items (shown when expanded)
                if showMenu {
                    FABMenuItem(
                        icon: "camera.fill",
                        label: "Scan New Fridge",
                        action: {
                            withAnimation {
                                showMenu = false
                            }
                            onScanFridge()
                        }
                    )
                    .transition(.scale.combined(with: .opacity))

                    FABMenuItem(
                        icon: "wand.and.stars",
                        label: "New Recipes from Last Scan",
                        action: {
                            withAnimation {
                                showMenu = false
                            }
                            onGenerateRecipes()
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                // Main FAB button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showMenu.toggle()
                    }
                }) {
                    Circle()
                        .fill(Color(red: 74/255, green: 93/255, blue: 74/255)) // #4A5D4A
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: showMenu ? "xmark" : "plus")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(showMenu ? 90 : 0))
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 100) // Above tab bar
        }
    }
}

// MARK: - FAB Menu Item

struct FABMenuItem: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)

                Circle()
                    .fill(Color(red: 74/255, green: 93/255, blue: 74/255))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(.white)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct HomeScreenComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            LastUpdatedCard(text: "Last updated: 10/04/25") {}

            IngredientCategoryCard(
                name: "Vegetables",
                icon: "🥦",
                color: Color(red: 90/255, green: 122/255, blue: 90/255),
                count: 5,
                ingredients: [
                    Ingredient(name: "Spinach", quantity: "1 bag", category: "Vegetables"),
                    Ingredient(name: "Carrots", quantity: "5 pieces", category: "Vegetables"),
                    Ingredient(name: "Broccoli", quantity: "1 head", category: "Vegetables")
                ],
                isExpanded: .constant(false)
            )

            RecipeCard(
                recipe: Recipe(
                    title: "Chicken Stir Fry",
                    ingredients: [],
                    instructions: [],
                    cookingTime: "25 min",
                    difficulty: "easy"
                ),
                action: {}
            )
        }
        .padding()
        .background(Color(red: 248/255, green: 248/255, blue: 248/255))
    }
}
#endif
