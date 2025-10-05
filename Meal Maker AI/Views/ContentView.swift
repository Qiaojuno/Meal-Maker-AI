//
//  ContentView.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import SwiftUI

// MARK: - Theme Colors
private extension Color {
    static let brandGreen = Color(red: 65/255, green: 72/255, blue: 41/255)
}

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showAddSheet = false
    @State private var isMenuExpanded = false
    @State private var homeNavigationPath = NavigationPath() // Manage home navigation
    @StateObject private var homeViewModel = HomeViewModel() // Shared home view model

    var body: some View {
        ZStack(alignment: .bottom) {
            // Layer 1: Main content (blurred when expanded)
            Group {
                TabView(selection: $selectedTab) {
                    HomeTabView(viewModel: homeViewModel, navigationPath: $homeNavigationPath).tag(0)
                    SavedRecipesView().tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                CustomNavBar(
                    selectedTab: $selectedTab,
                    showAddSheet: $showAddSheet,
                    isExpanded: $isMenuExpanded,
                    homeNavigationPath: $homeNavigationPath,
                    showToggleButton: false  // Don't show toggle button in blurred layer
                )
            }
            .blur(radius: isMenuExpanded ? 5 : 0)
            .animation(.easeOut(duration: 0.25), value: isMenuExpanded)

            // Layer 2: Dimming overlay (appears above blurred content)
            if isMenuExpanded {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            isMenuExpanded = false
                        }
                    }
                    .animation(.easeOut(duration: 0.25), value: isMenuExpanded)
            }

            // Layer 3: Radial menu buttons (always sharp, on top)
            if isMenuExpanded {
                radialMenuButtons
            }

            // Layer 4: Toggle button (always on top, never blurred)
            toggleButton
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationView {
                Text("Add Recipe Manually")
                    .navigationTitle("New Recipe")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showAddSheet = false }
                        }
                    }
            }
        }
    }

    private var radialMenuButtons: some View {
        ZStack(alignment: .bottomTrailing) {
            // Generate Recipes button
            RadialMenuButton(
                icon: "wand.and.stars",
                label: "Generate Recipes",
                color: .brandGreen
            ) {
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()

                withAnimation {
                    isMenuExpanded = false
                    selectedTab = 0 // Switch to home tab
                    homeNavigationPath = NavigationPath() // Reset navigation to home
                }

                // Set loading immediately for instant feedback
                homeViewModel.isLoading = true

                // Trigger recipe generation on HomeViewModel
                Task {
                    await homeViewModel.generateNewRecipes()
                }
            }
            .offset(x: -59, y: -180)

            // Update Fridge button (navigate to camera)
            RadialMenuButton(
                icon: "camera.fill",
                label: "Update Fridge",
                color: .brandGreen
            ) {
                isMenuExpanded = false

                // Disable all animations to prevent jitter
                var transaction = Transaction()
                transaction.disablesAnimations = true

                withTransaction(transaction) {
                    // If not on home tab, switch instantly
                    if selectedTab != 0 {
                        selectedTab = 0
                    }

                    // Create and set path with camera destination
                    var newPath = NavigationPath()
                    newPath.append(NavigationDestination.camera)
                    homeNavigationPath = newPath
                }
            }
            .offset(x: -59, y: -100)
        }
    }

    private var toggleButton: some View {
        HStack(spacing: 0) {
            Spacer()
            Spacer()
            Spacer()

            Button {
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()

                withAnimation(.easeInOut(duration: 0.4)) {
                    isMenuExpanded.toggle()
                }
            } label: {
                Circle()
                    .fill(isMenuExpanded ? Color.white : Color.brandGreen)
                    .frame(width: 90, height: 90)
                    .overlay(
                        Image(systemName: isMenuExpanded ? "xmark" : "plus")
                            .font(.custom("Archivo-SemiBold", size: 22))
                            .foregroundColor(isMenuExpanded ? .black : .white)
                            .rotationEffect(.degrees(isMenuExpanded ? 90 : 0))
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }
            .offset(y: -30)
        }
        .padding(.horizontal, 40)
        .padding(.top, 12)
        .padding(.bottom, -40)
    }
}

// MARK: - Custom Navigation Bar

struct CustomNavBar: View {
    @Binding var selectedTab: Int
    @Binding var showAddSheet: Bool
    @Binding var isExpanded: Bool
    @Binding var homeNavigationPath: NavigationPath
    var showToggleButton: Bool = true  // Default to true for compatibility

    var body: some View {
        ZStack {
            navigationButtons
        }
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
    }

    private var navigationButtons: some View {
        HStack(spacing: 0) {
            NavButton(icon: "house.fill", isSelected: selectedTab == 0) {
                selectedTab = 0
                // Clear navigation to return to camera root
                homeNavigationPath = NavigationPath()
            }
            .offset(x: 25, y: -15)

            Spacer()

            NavButton(icon: "fork.knife", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            .offset(x: 15, y: -15)

            Spacer()

            // Placeholder spacer when toggle button is hidden
            if !showToggleButton {
                Color.clear
                    .frame(width: 90, height: 90)
                    .offset(y: -30)
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 12)
        .padding(.bottom, -40)
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
            HStack(alignment: .center, spacing: 12) {
                Text(label)
                    .font(.custom("Archivo-Medium", size: 12))
                    .foregroundColor(.white)

                Circle()
                    .fill(color)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: icon)
                            .font(.custom("Archivo-Regular", size: 20))
                            .foregroundColor(.white)
                    )
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
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
                .font(.custom("Archivo-Regular", size: 24))
                .foregroundColor(isSelected ? .brandGreen : .gray)
        }
    }
}

// MARK: - Home Tab View

struct HomeTabView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var navigationPath: NavigationPath
    @State private var identifiedIngredients: [Ingredient] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            // HomeScreen is the root view
            HomeScreen(viewModel: viewModel, navigationPath: $navigationPath)
                .navigationBarHidden(true)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .camera:
                        CameraView { ingredients in
                            identifiedIngredients = ingredients
                            navigationPath.append(NavigationDestination.ingredientList(ingredients))
                        }
                    case .ingredientList(let ingredients):
                        IngredientListView(
                            ingredients: ingredients,
                            onConfirm: { confirmedIngredients in
                                identifiedIngredients = confirmedIngredients
                                // Save ingredients
                                StorageService.shared.saveIngredients(confirmedIngredients)

                                // Haptic feedback
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()

                                // Go back to home
                                navigationPath.removeLast()

                                // Set loading immediately for instant visual feedback
                                viewModel.isLoading = true

                                // Auto-generate recipes from scanned ingredients
                                Task {
                                    await viewModel.generateNewRecipes()
                                }
                            },
                            onRescan: {
                                navigationPath.removeLast()
                            }
                        )
                    case .recipeDetail(let recipe):
                        RecipeDetailView(recipe: recipe)
                    }
                }
        }
    }
}

// MARK: - Navigation Destination

enum NavigationDestination: Hashable {
    case camera
    case ingredientList([Ingredient])
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
        HomeTabView(viewModel: HomeViewModel(), navigationPath: .constant(NavigationPath()))
    }
}
#endif
