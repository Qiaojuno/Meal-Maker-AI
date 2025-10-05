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

    var body: some View {
        ZStack(alignment: .bottom) {
            // Layer 1: Main content (blurred when expanded)
            Group {
                TabView(selection: $selectedTab) {
                    HomeTabView().tag(0)
                    SavedRecipesView().tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                CustomNavBar(selectedTab: $selectedTab, showAddSheet: $showAddSheet, isExpanded: $isMenuExpanded)
            }
            .blur(radius: isMenuExpanded ? 5 : 0)
            .animation(.easeOut(duration: 0.25), value: isMenuExpanded)

            // Layer 2: Dimming overlay (appears above blurred content)
            if isMenuExpanded {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeOut(duration: 0.25), value: isMenuExpanded)
            }

            // Layer 3: The 3 buttons (always sharp, on top of everything)
            if isMenuExpanded {
                radialMenuButtons
            }
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
            // Find Recipes button
            RadialMenuButton(
                icon: "magnifyingglass",
                label: "Find Recipes",
                color: .brandGreen
            ) {
                withAnimation {
                    isMenuExpanded = false
                    selectedTab = 1
                }
            }
            .offset(x: -59, y: -180)

            // Update Fridge button
            RadialMenuButton(
                icon: "camera.fill",
                label: "Update Fridge",
                color: .brandGreen
            ) {
                withAnimation {
                    isMenuExpanded = false
                    selectedTab = 0
                }
            }
            .offset(x: -59, y: -100)

            // X Button (appears on top of + button in bottom-right)
            HStack(spacing: 0) {
                Spacer()
                Spacer()
                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isMenuExpanded.toggle()
                    }
                } label: {
                    Circle()
                        .fill(.white)
                        .frame(width: 90, height: 90)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .rotationEffect(.degrees(90))
                        )
                }
                .offset(y: -30)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, -40)
        }
    }
}

// MARK: - Custom Navigation Bar

struct CustomNavBar: View {
    @Binding var selectedTab: Int
    @Binding var showAddSheet: Bool
    @Binding var isExpanded: Bool

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
            }
            .offset(x: 25, y: -15)

            Spacer()

            NavButton(icon: "fork.knife", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            .offset(x: 15, y: -15)

            Spacer()

            toggleButton
        }
        .padding(.horizontal, 40)
        .padding(.top, 12)
        .padding(.bottom, -40)
    }

    private var toggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        } label: {
            Circle()
                .fill(Color.brandGreen)
                .frame(width: 90, height: 90)
                .overlay(
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
        }
        .offset(y: -30)
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
                .font(.system(size: 24))
                .foregroundColor(isSelected ? .brandGreen : .gray)
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
                navigationPath.append(NavigationDestination.ingredientList(ingredients))
            }
            .navigationTitle("FridgeScanner")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .ingredientList(let ingredients):
                    IngredientListView(
                        ingredients: ingredients,
                        onConfirm: { confirmedIngredients in
                            identifiedIngredients = confirmedIngredients
                            navigationPath.append(NavigationDestination.recipeGeneration(confirmedIngredients))
                        },
                        onRescan: {
                            navigationPath.removeLast()
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
    case ingredientList([Ingredient])
    case recipeGeneration([Ingredient])
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
