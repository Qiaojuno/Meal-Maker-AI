//
//  HomeScreen.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import SwiftUI

struct HomeScreen: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var expandedCategories: Set<String> = []
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 0) {
            // Title bar (matching other views)
            VStack(spacing: 0) {
                HStack {
                    Text("Meal4Me")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 12)
            }
            .background(Color.white)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            .ignoresSafeArea(edges: .top)

            // Content
            ZStack {
                // Background
                Color(red: 248/255, green: 248/255, blue: 248/255) // #F8F8F8
                    .ignoresSafeArea()

                ScrollView {
                VStack(spacing: 20) {
                    // Last Updated Card
                    LastUpdatedCard(text: viewModel.lastUpdatedText) {
                        // Navigate to CameraView to scan fridge
                        navigationPath.append(NavigationDestination.camera)
                    }

                    // Ingredient Categories
                    VStack(spacing: 12) {
                        ForEach(viewModel.categoryData, id: \.name) { category in
                            IngredientCategoryCard(
                                name: category.name,
                                icon: category.icon,
                                color: category.color,
                                count: category.count,
                                ingredients: viewModel.ingredientsByCategory[category.name] ?? [],
                                isExpanded: Binding(
                                    get: { expandedCategories.contains(category.name) },
                                    set: { isExpanded in
                                        if isExpanded {
                                            expandedCategories.insert(category.name)
                                        } else {
                                            expandedCategories.remove(category.name)
                                        }
                                    }
                                )
                            )
                        }
                    }

                    // Recent Recipes Section (if any)
                    if !viewModel.recentRecipes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Recipes")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)

                            ForEach(viewModel.recentRecipes.prefix(5)) { recipe in
                                RecipeCard(recipe: recipe) {
                                    navigationPath.append(NavigationDestination.recipeDetail(recipe))
                                }
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 100) // Space for bottom nav
                }
                .refreshable {
                    viewModel.loadData()
                }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

#Preview {
    HomeScreen(navigationPath: .constant(NavigationPath()))
}
