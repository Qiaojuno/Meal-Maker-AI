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
    
    var body: some View {
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
            
            // Plus button
            Button(action: { showAddSheet = true }) {
                Circle()
                    .fill(Color(red: 65/255, green: 72/255, blue: 41/255))
                    .frame(width: 90, height: 90)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
            }
            .offset(y: -30) // Makes it pop up a bit
        }
        .padding(.horizontal, 40)
        .padding(.top, 12)
        .padding(.bottom, -20)
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
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
                identifiedIngredients = ingredients
                navigationPath.append(NavigationDestination.ingredientList)
            }
            .navigationTitle("FridgeScanner")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .ingredientList:
                    IngredientListView(
                        ingredients: identifiedIngredients,
                        onConfirm: { confirmedIngredients in
                            identifiedIngredients = confirmedIngredients
                            navigationPath.append(NavigationDestination.recipeGeneration)
                        },
                        onRescan: {
                            navigationPath.removeLast()
                        }
                    )

                case .recipeGeneration:
                    RecipeGenerationView(ingredients: identifiedIngredients)
                }
            }
        }
    }
}

// MARK: - Navigation Destination

enum NavigationDestination: Hashable {
    case ingredientList
    case recipeGeneration
}

#Preview {
    ContentView()
}
