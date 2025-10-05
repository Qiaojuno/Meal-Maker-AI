//
//  CameraViewModel.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import UIKit
import SwiftUI

@MainActor
class CameraViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var capturedImage: UIImage?
    @Published var identifiedIngredients: [Ingredient] = []
    @Published var isProcessing = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let geminiService = GeminiService()

    // MARK: - Public Methods

    /// Process captured image and identify ingredients
    func processImage(_ image: UIImage) async {
        print("🔍 [CameraViewModel] processImage() called")
        capturedImage = image
        identifiedIngredients = []
        errorMessage = nil
        isProcessing = true
        print("🔍 [CameraViewModel] Reset state: ingredients=[], isProcessing=true")

        do {
            print("🔍 [CameraViewModel] Calling geminiService.identifyIngredients()")
            let ingredients = try await geminiService.identifyIngredients(from: image)
            print("🔍 [CameraViewModel] API returned \(ingredients.count) ingredients")
            ingredients.forEach { print("  📦 API: \($0.name) - \($0.quantity ?? "no qty")") }

            print("🔍 [CameraViewModel] Setting identifiedIngredients = \(ingredients.count) items")
            identifiedIngredients = ingredients
            print("🔍 [CameraViewModel] After assignment: identifiedIngredients.count = \(identifiedIngredients.count)")
        } catch let error as GeminiError {
            print("❌ [CameraViewModel] Gemini error: \(error.errorDescription ?? "unknown")")
            errorMessage = error.errorDescription
        } catch {
            print("❌ [CameraViewModel] Unexpected error: \(error)")
            errorMessage = "An unexpected error occurred. Please try again."
        }

        isProcessing = false
        print("🔍 [CameraViewModel] processImage() complete: isProcessing=false, ingredients=\(identifiedIngredients.count)")
    }

    /// Reset state for new capture
    func reset() {
        capturedImage = nil
        identifiedIngredients = []
        errorMessage = nil
        isProcessing = false
    }
}
