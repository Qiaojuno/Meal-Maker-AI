//
//  ContentView.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showAddSheet = false // For the + button
    @State private var homeNavigationPath = NavigationPath() // Shared navigation path for home tab

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            TabView(selection: $selectedTab) {
                HomeTabView(navigationPath: $homeNavigationPath)
                    .tag(0)

                SavedRecipesView()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never)) // Hides default tab bar

            // Custom navigation bar overlay
            CustomNavBar(
                selectedTab: $selectedTab,
                showAddSheet: $showAddSheet,
                homeNavigationPath: $homeNavigationPath
            )
        }
        .sheet(isPresented: $showAddSheet) {
            // What happens when + is pressed (customize this later)
            NavigationView {
                Text("Add Recipe Manually")
                    .navigationTitle("New Recipe")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showAddSheet = false
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Custom Navigation Bar

struct CustomNavBar: View {
    @Binding var selectedTab: Int
    @Binding var showAddSheet: Bool
    @Binding var homeNavigationPath: NavigationPath
    @State private var isExpanded = false // State for radial menu

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // Home button
                NavButton(icon: "house.fill", isSelected: selectedTab == 0) {
                    selectedTab = 0
                    // Clear navigation path to return to home root
                    homeNavigationPath = NavigationPath()
                }
                .offset(y: -15)
                .offset(x: 25)

                Spacer()

                // Recipes button
                NavButton(icon: "fork.knife", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                .offset(y: -15)
                .offset(x: 15)

                Spacer()

                // Plus/Close button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }) {
                    Circle()
                        .fill(Color(red: 65/255, green: 72/255, blue: 41/255))
                        .frame(width: 90, height: 90)
                        .overlay(
                            Image(systemName: isExpanded ? "xmark" : "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        )
                }
                .offset(y: -30)
            }
            .padding(.horizontal, 40)
            .padding(.top, 12)
            .padding(.bottom, -40)

            // Radial menu buttons (appear when expanded)
            if isExpanded {
                // Find Recipes button (higher up)
                RadialMenuButton(
                    icon: "magnifyingglass",
                    label: "Find Recipes",
                    color: Color(red: 65/255, green: 72/255, blue: 41/255)
                ) {
                    withAnimation {
                        isExpanded = false
                        selectedTab = 1 // Navigate to recipes
                    }
                }
                .offset(x: 65, y: -180)
                .transition(.scale.combined(with: .opacity))

                // Update Fridge button (closer to plus button)
                RadialMenuButton(
                    icon: "camera.fill",
                    label: "Update Fridge",
                    color: Color(red: 65/255, green: 72/255, blue: 41/255)
                ) {
                    withAnimation {
                        isExpanded = false
                        selectedTab = 0 // Navigate to home/camera
                    }
                }
                .offset(x: 65, y: -100)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
    }
}

// MARK: - Radial Menu Button

struct RadialMenuButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Circle()
                    .fill(color)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(.white)
                    )
            }
        }
    }
}

// MARK: - Navigation Button

struct NavButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? Color(red: 65/255, green: 72/255, blue: 41/255) : .gray)
        }
    }
}

// MARK: - Home Tab View

struct HomeTabView: View {
    @Binding var navigationPath: NavigationPath
    @StateObject private var viewModel = HomeViewModel()
    @State private var expandedCategories: Set<String> = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Static title bar with status bar background
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

                // Scrollable content
                ScrollView {
                    VStack(spacing: 20) {
                        // Last Updated Section
                        LastUpdatedCard(text: viewModel.lastUpdatedText) {
                            navigationPath.append(HomeDestination.cameraView)
                        }
                        .padding(.horizontal)

                    // Ingredients Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ingredients")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)

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
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    .padding(.horizontal)

                    // Recent Recipes Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Recipes")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal)

                        if viewModel.recentRecipes.isEmpty {
                            // Empty state
                            VStack(spacing: 12) {
                                Image(systemName: "fork.knife.circle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)

                                Text("No recipes yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)

                                Text("Scan your fridge to get started!")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(viewModel.recentRecipes) { recipe in
                                    RecipeCard(recipe: recipe) {
                                        navigationPath.append(HomeDestination.recipeDetail(recipe))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                        Spacer(minLength: 100) // Space for nav bar
                    }
                    .padding(.top, 20)
                }
                .background(Color(red: 248/255, green: 248/255, blue: 248/255))
            }
            .navigationBarHidden(true)
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .cameraView:
                    CameraView { ingredients in
                        // Navigate to ingredient review
                        navigationPath.append(HomeDestination.ingredientReview(ingredients))
                    }

                case .ingredientReview(let ingredients):
                    IngredientListView(
                        ingredients: ingredients,
                        onConfirm: { confirmedIngredients in
                            // Save ingredients to storage
                            StorageService.shared.saveIngredients(confirmedIngredients)
                            // Reload home screen data
                            viewModel.loadData()
                            // Go back to home
                            navigationPath.removeLast()
                        },
                        onRescan: {
                            navigationPath.removeLast() // Go back to camera
                        }
                    )

                case .recipeDetail(let recipe):
                    RecipeDetailView(recipe: recipe)
                }
            }
            .onAppear {
                viewModel.loadData()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
}

// MARK: - Home Navigation Destination

enum HomeDestination: Hashable {
    case cameraView
    case ingredientReview([Ingredient])
    case recipeDetail(Recipe)
}


#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct HomeTabView_Previews: PreviewProvider {
    static var previews: some View {
        HomeTabView(navigationPath: .constant(NavigationPath()))
    }
}
#endif
