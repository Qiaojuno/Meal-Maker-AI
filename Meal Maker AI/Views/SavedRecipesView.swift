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
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Static title bar (matching home screen)
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

                // Scrollable content
                ZStack {
                    Color(red: 248/255, green: 248/255, blue: 248/255) // #F8F8F8 background
                        .ignoresSafeArea()

                    if viewModel.savedRecipes.isEmpty {
                        emptyStateView
                    } else {
                        VStack(spacing: 0) {
                            // Section header with count
                            HStack {
                                ZStack {
                                    Text("Saved Recipes")
                                        .font(.custom("Archivo-SemiBold", size: 22))
                                        .foregroundColor(.black)
                                        .opacity(0.5)
                                    Text("Saved Recipes")
                                        .font(.custom("Archivo-SemiBold", size: 22))
                                        .foregroundColor(.black)
                                }

                                Text("(\(viewModel.savedRecipes.count))")
                                    .font(.custom("Archivo-Medium", size: 22))
                                    .foregroundColor(Color(red: 74/255, green: 93/255, blue: 74/255)) // #4A5D4A green

                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 12)

                            // Recipes scroll view
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.savedRecipes) { recipe in
                                        RecipeCard(recipe: recipe) {
                                            navigationPath.append(recipe)
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    viewModel.deleteRecipe(recipe)
                                                }
                                            } label: {
                                                Label("Unsave Recipe", systemImage: "bookmark.slash.fill")
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 80) // Space for nav bar
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe, viewModel: recipeViewModel)
            }
            .onAppear {
                viewModel.loadSavedRecipes()
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark.slash")
                .font(.custom("Archivo-Regular", size: 60))
                .foregroundColor(Color(red: 74/255, green: 93/255, blue: 74/255)) // #4A5D4A green

            ZStack {
                Text("No Saved Recipes")
                    .font(.custom("Archivo-SemiBold", size: 22))
                    .foregroundColor(.black)
                    .opacity(0.5)
                Text("No Saved Recipes")
                    .font(.custom("Archivo-SemiBold", size: 22))
                    .foregroundColor(.black)
            }

            Text("Recipes you save will appear here")
                .font(.custom("Archivo-Regular", size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    SavedRecipesView()
}
