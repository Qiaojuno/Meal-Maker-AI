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
        capturedImage = image
        identifiedIngredients = []
        errorMessage = nil
        isProcessing = true

        do {
            let ingredients = try await geminiService.identifyIngredients(from: image)
            identifiedIngredients = ingredients
        } catch let error as GeminiError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }

        isProcessing = false
    }

    /// Reset state for new capture
    func reset() {
        capturedImage = nil
        identifiedIngredients = []
        errorMessage = nil
        isProcessing = false
    }
}
