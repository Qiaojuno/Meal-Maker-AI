//
//  IngredientListView.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import SwiftUI

struct IngredientListView: View {
    @State private var ingredients: [Ingredient]
    @State private var showingAddIngredient = false
    @State private var newIngredientName = ""
    @State private var newIngredientQuantity = ""

    // Callback when user confirms ingredients
    var onConfirm: (([Ingredient]) -> Void)?
    var onRescan: (() -> Void)?

    // CRITICAL FIX: Proper initializer for @State with external parameter
    init(
        ingredients: [Ingredient],
        onConfirm: (([Ingredient]) -> Void)? = nil,
        onRescan: (() -> Void)? = nil
    ) {
        print("🔍 DEBUG: IngredientListView.init() called with \(ingredients.count) ingredients")
        ingredients.forEach { ingredient in
            print("  📦 init: \(ingredient.name)")
        }
        // Use _ingredients to set the @State wrapper's initial value
        self._ingredients = State(initialValue: ingredients)
        print("🔍 DEBUG: _ingredients State wrapper initialized")
        self.onConfirm = onConfirm
        self.onRescan = onRescan
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                // Header
                headerView

                // Ingredients list
                ingredientsListView

                // Add ingredient button
                addIngredientButton

                // Action buttons
                actionButtons
            }
            .background(Color(.systemGroupedBackground))

            // Custom back button overlay
            backButton
                .padding(.top, 8)
                .padding(.leading, 16)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddIngredient) {
            addIngredientSheet
        }
        .onAppear {
            print("🔍 DEBUG: IngredientListView appeared with \(ingredients.count) ingredients")
            ingredients.forEach { ingredient in
                print("  - \(ingredient.name)")
            }
        }
    }

    // MARK: - Subviews

    private var backButton: some View {
        Button(action: rescan) {
            Circle()
                .fill(Color.white)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "chevron.left")
                        .font(.custom("Archivo-SemiBold", size: 18))
                        .foregroundColor(Color(red: 44/255, green: 62/255, blue: 45/255))
                )
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
    }

    private var headerView: some View {
        let _ = print("🔍 DEBUG: headerView rendering with \(ingredients.count) ingredients")
        return VStack(spacing: 8) {
            ZStack {
                Text("Review Ingredients")
                    .font(.custom("Archivo-SemiBold", size: 22))
                    .opacity(0.5)
                Text("Review Ingredients")
                    .font(.custom("Archivo-SemiBold", size: 22))
            }

            Text("\(ingredients.count) ingredients detected")
                .font(.custom("Archivo-Regular", size: 15))
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    private var ingredientsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(ingredients) { ingredient in
                    IngredientRow(ingredient: ingredient) {
                        deleteIngredient(ingredient)
                    }
                }
            }
            .padding()
        }
    }

    private var addIngredientButton: some View {
        Button(action: { showingAddIngredient = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Ingredient")
                    .fontWeight(.medium)
            }
            .foregroundColor(.blue)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: confirmIngredients) {
                Text("Save to Fridge")
                    .font(.custom("Archivo-SemiBold", size: 17))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 74/255, green: 93/255, blue: 74/255))
                    .cornerRadius(12)
            }
            .disabled(ingredients.isEmpty)
            .opacity(ingredients.isEmpty ? 0.5 : 1.0)

            Button(action: rescan) {
                Text("Rescan Fridge")
                    .font(.custom("Archivo-Regular", size: 15))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var addIngredientSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Ingredient Details")) {
                    TextField("Name (e.g., chicken breast)", text: $newIngredientName)
                        .autocapitalization(.none)

                    TextField("Quantity (optional)", text: $newIngredientQuantity)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddIngredient = false
                        resetAddIngredientForm()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addIngredient()
                    }
                    .disabled(newIngredientName.trimmed.isEmpty)
                }
            }
        }
    }

    // MARK: - Actions

    private func deleteIngredient(_ ingredient: Ingredient) {
        ingredients.removeAll { $0.id == ingredient.id }
    }

    private func addIngredient() {
        let ingredient = Ingredient(
            name: newIngredientName.trimmed,
            quantity: newIngredientQuantity.trimmed.isEmpty ? nil : newIngredientQuantity.trimmed
        )
        ingredients.append(ingredient)
        showingAddIngredient = false
        resetAddIngredientForm()
    }

    private func resetAddIngredientForm() {
        newIngredientName = ""
        newIngredientQuantity = ""
    }

    private func confirmIngredients() {
        onConfirm?(ingredients)
    }

    private func rescan() {
        onRescan?()
    }
}

// MARK: - Ingredient Row

struct IngredientRow: View {
    let ingredient: Ingredient
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.custom("Archivo-SemiBold", size: 17))

                if let quantity = ingredient.quantity {
                    Text(quantity)
                        .font(.custom("Archivo-Regular", size: 15))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    IngredientListView(ingredients: [
        Ingredient(name: "Chicken Breast", quantity: "2 pieces"),
        Ingredient(name: "Spinach", quantity: "1 bag"),
        Ingredient(name: "Cheddar Cheese")
    ])
}
