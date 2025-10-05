//
//  HomeScreen.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import SwiftUI

struct HomeScreen: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var expandedCategories: Set<String> = []
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 0) {
            // Title bar (matching other views)
            VStack(spacing: 0) {
                HStack {
                    ZStack {
                        Text("Meal4Me")
                            .font(.custom("Archivo-Bold", size: 34))
                            .foregroundColor(.black)
                            .opacity(0.5)
                        Text("Meal4Me")
                            .font(.custom("Archivo-Bold", size: 34))
                            .foregroundColor(.black)
                    }

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
                    VStack(alignment: .leading, spacing: 12) {
                        ZStack(alignment: .leading) {
                            Text("Ingredients")
                                .font(.custom("Archivo-SemiBold", size: 22))
                                .foregroundColor(.black)
                                .opacity(0.5)
                            Text("Ingredients")
                                .font(.custom("Archivo-SemiBold", size: 22))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

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
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)

                    // Recent Recipes Section (if any or loading)
                    if viewModel.isLoading || !viewModel.recentRecipes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            ZStack {
                                Text("Recent Recipes")
                                    .font(.custom("Archivo-SemiBold", size: 22))
                                    .foregroundColor(.black)
                                    .opacity(0.5)
                                Text("Recent Recipes")
                                    .font(.custom("Archivo-SemiBold", size: 22))
                                    .foregroundColor(.black)
                            }

                            if viewModel.isLoading {
                                // Loading state
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.5)

                                    Text("Generating recipes...")
                                        .font(.custom("Archivo-Regular", size: 15))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .background(Color.white)
                                .cornerRadius(12)
                            } else {
                                // Show recipes
                                ForEach(viewModel.recentRecipes.prefix(5)) { recipe in
                                    RecipeCard(recipe: recipe) {
                                        navigationPath.append(NavigationDestination.recipeDetail(recipe))
                                    }
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
        .onChange(of: navigationPath) { oldPath, newPath in
            // Reload data when navigating back to home (empty path)
            if newPath.isEmpty {
                viewModel.loadData()
            }
        }
    }
}

#Preview {
    HomeScreen(viewModel: HomeViewModel(), navigationPath: .constant(NavigationPath()))
}
