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
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content (your existing tab views)
            TabView(selection: $selectedTab) {
                HomeTabView()
                    .tag(0)
                
                SavedRecipesView()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never)) // Hides default tab bar
            
            // Custom navigation bar overlay
            CustomNavBar(selectedTab: $selectedTab, showAddSheet: $showAddSheet)
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
    @State private var isExpanded = false // 👈 New state for radial menu
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // Home button
                NavButton(icon: "house.fill", isSelected: selectedTab == 0) {
                    selectedTab = 0
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
                    // 👈 LOGIC: Navigate to recipe search
                    withAnimation {
                        isExpanded = false
                        selectedTab = 1 // Or trigger recipe search
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
                    // 👈 LOGIC: Go to camera view
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
    @State private var navigationPath = NavigationPath()
    @State private var identifiedIngredients: [Ingredient] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            CameraView { ingredients in
                print("🔍 DEBUG: HomeTabView received \(ingredients.count) ingredients")
                identifiedIngredients = ingredients
                print("🔍 DEBUG: Navigating with ingredients passed through enum")
                // CRITICAL FIX: Pass ingredients THROUGH the navigation destination
                // Don't rely on captured state from closure
                navigationPath.append(NavigationDestination.ingredientList(ingredients))
            }
            .navigationTitle("FridgeScanner")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .ingredientList(let ingredients):
                    let _ = print("🔍 DEBUG: Creating IngredientListView with \(ingredients.count) ingredients from enum")
                    IngredientListView(
                        ingredients: ingredients,
                        onConfirm: { confirmedIngredients in
                            print("🔍 DEBUG: User confirmed \(confirmedIngredients.count) ingredients")
                            identifiedIngredients = confirmedIngredients
                            navigationPath.append(NavigationDestination.recipeGeneration(confirmedIngredients))
                        },
                        onRescan: {
                            print("🔍 DEBUG: User requested rescan")
                            navigationPath.removeLast()  // Go back to camera
                        }
                    )

                case .recipeGeneration(let ingredients):
                    RecipeGenerationView(ingredients: ingredients)
                }
            }
        }
    }
}

// MARK: - Navigation Destination

enum NavigationDestination: Hashable {
    case ingredientList([Ingredient])  // Pass ingredients directly!
    case recipeGeneration([Ingredient])  // Pass ingredients directly!
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
