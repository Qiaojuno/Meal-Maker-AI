//
//  IngredientListView.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import SwiftUI

struct IngredientListView: View {
    @State var ingredients: [Ingredient]
    @State private var showingAddIngredient = false
    @State private var newIngredientName = ""
    @State private var newIngredientQuantity = ""

    // Callback when user confirms ingredients
    var onConfirm: (([Ingredient]) -> Void)?
    var onRescan: (() -> Void)?

    var body: some View {
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
        .sheet(isPresented: $showingAddIngredient) {
            addIngredientSheet
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Review Ingredients")
                .font(.title2)
                .fontWeight(.bold)

            Text("\(ingredients.count) ingredients detected")
                .font(.subheadline)
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
                Text("Generate Recipes")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(ingredients.isEmpty)
            .opacity(ingredients.isEmpty ? 0.5 : 1.0)

            Button(action: rescan) {
                Text("Rescan Fridge")
                    .font(.subheadline)
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
                    .font(.headline)

                if let quantity = ingredient.quantity {
                    Text(quantity)
                        .font(.subheadline)
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
