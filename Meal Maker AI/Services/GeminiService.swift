//
//  GeminiService.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import UIKit
import Foundation

/// Service for interacting with Google Gemini API
class GeminiService {
    // API Configuration
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private let visionModel = "gemini-2.5-flash"  // Supports images (multimodal)
    private let textModel = "gemini-2.5-flash"    // Text only, faster
    private let maxIngredients = 12

    private var apiKey: String {
        return Config.geminiAPIKey
    }

    // MARK: - Public Methods

    /// Identify ingredients from a fridge photo
    /// - Parameter image: UIImage of the fridge contents
    /// - Returns: Array of identified ingredients
    /// - Throws: GeminiError if API call fails
    func identifyIngredients(from image: UIImage) async throws -> [Ingredient] {
        // Prepare image for API
        guard let base64Image = image.preparedForAPI() else {
            throw GeminiError.imagePreparationFailed
        }

        let prompt = """
        Analyze this fridge photo and identify the most SIGNIFICANT food items for cooking meals. Prioritize:

        HIGH PRIORITY:
        - Main proteins (chicken, beef, fish, eggs, tofu)
        - Primary vegetables (onions, peppers, spinach, broccoli)
        - Dairy essentials (milk, cheese, butter, yogurt)
        - Carb bases (bread, pasta, rice, potatoes)

        MEDIUM PRIORITY:
        - Secondary vegetables and fruits
        - Cooking ingredients (sauces, oils)

        IGNORE:
        - Small condiment packets
        - Single-use items
        - Beverages (unless cooking ingredients like milk)
        - Items too small to be meal components

        Be specific with ingredient names. Use common grocery store names.

        Return ONLY valid JSON in this exact format:
        {
          "ingredients": [
            {"name": "chicken breast", "quantity": "2 pieces"},
            {"name": "cheddar cheese", "quantity": "1 block"},
            {"name": "spinach", "quantity": "1 bag"}
          ]
        }

        Requirements:
        - Focus on ingredients that can make complete meals
        - Use specific names (e.g., "cheddar cheese" not "cheese", "chicken breast" not "meat")
        - Estimate realistic quantities
        - List most important ingredients first
        - Return up to \(maxIngredients) significant ingredients maximum
        """

        // Make API call
        let response: IngredientsResponse = try await makeVisionAPICall(prompt: prompt, image: base64Image)

        // Validate and truncate if needed
        let ingredients = Array(response.ingredients.prefix(maxIngredients))

        guard !ingredients.isEmpty else {
            throw GeminiError.noIngredientsDetected
        }

        return ingredients
    }

    /// Generate recipes from a list of ingredients
    /// - Parameter ingredients: Array of ingredients to use
    /// - Returns: Array of generated recipes (should be 3)
    /// - Throws: GeminiError if API call fails
    func generateRecipes(from ingredients: [Ingredient]) async throws -> [Recipe] {
        guard !ingredients.isEmpty else {
            throw GeminiError.noIngredientsProvided
        }

        let ingredientList = ingredients.map { $0.name }.joined(separator: ", ")

        let prompt = """
        Create exactly 3 recipes for college students using these ingredients: \(ingredientList)

        Requirements:
        - Use primarily the listed ingredients
        - Assume basic pantry staples: salt, pepper, cooking oil, butter
        - Cook time: 15-30 minutes maximum
        - Equipment: stovetop, microwave, oven, basic pans and utensils only
        - Difficulty: easy to medium
        - Budget-friendly and filling

        Return ONLY valid JSON in this exact format:
        {
          "recipes": [
            {
              "title": "Recipe Name",
              "estimated_time": 25,
              "difficulty": "easy",
              "ingredients": ["ingredient1", "ingredient2", "ingredient3"],
              "instructions": [
                "Step 1 description",
                "Step 2 description",
                "Step 3 description"
              ],
              "servings": 2
            }
          ]
        }

        Make recipes practical for dorm/apartment cooking with minimal cleanup.
        Generate exactly 3 different recipes.
        """

        // Make API call (text only, no image)
        let response: RecipesResponse = try await makeTextAPICall(prompt: prompt)

        guard !response.recipes.isEmpty else {
            throw GeminiError.noRecipesGenerated
        }

        return response.recipes
    }

    // MARK: - Private API Methods

    /// Make API call with image (vision model)
    private func makeVisionAPICall<T: Decodable>(prompt: String, image: String) async throws -> T {
        let endpoint = "\(baseURL)/\(visionModel):generateContent?key=\(apiKey)"

        guard let url = URL(string: endpoint) else {
            throw GeminiError.invalidURL
        }

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": image
                            ]
                        ]
                    ]
                ]
            ]
        ]

        return try await performRequest(url: url, body: requestBody)
    }

    /// Make API call with text only (faster, cheaper)
    private func makeTextAPICall<T: Decodable>(prompt: String) async throws -> T {
        let endpoint = "\(baseURL)/\(textModel):generateContent?key=\(apiKey)"

        guard let url = URL(string: endpoint) else {
            throw GeminiError.invalidURL
        }

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]

        return try await performRequest(url: url, body: requestBody)
    }

    /// Perform HTTP request and parse response
    private func performRequest<T: Decodable>(url: URL, body: [String: Any]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw GeminiError.requestEncodingFailed
        }

        // Perform request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message from response
            if let errorMessage = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
                throw GeminiError.apiError(errorMessage.error.message)
            }
            throw GeminiError.httpError(httpResponse.statusCode)
        }

        // Parse Gemini response format
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        // Extract text from response
        guard let text = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw GeminiError.emptyResponse
        }

        // Extract JSON from response (Gemini often wraps in markdown)
        let jsonString = extractJSON(from: text)

        // Parse into expected type
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw GeminiError.jsonParsingFailed
        }

        do {
            return try JSONDecoder().decode(T.self, from: jsonData)
        } catch {
            print("❌ JSON Parsing Error: \(error)")
            print("📄 Received JSON: \(jsonString)")
            throw GeminiError.jsonParsingFailed
        }
    }

    /// Extract JSON string from Gemini response (removes markdown code blocks)
    private func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code blocks if present
        if trimmed.hasPrefix("```json") {
            let withoutPrefix = trimmed.replacingOccurrences(of: "```json", with: "")
            let withoutSuffix = withoutPrefix.replacingOccurrences(of: "```", with: "")
            return withoutSuffix.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if trimmed.hasPrefix("```") {
            let withoutBackticks = trimmed.replacingOccurrences(of: "```", with: "")
            return withoutBackticks.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return trimmed
    }
}

// MARK: - Response Models

/// Gemini API response structure
private struct GeminiResponse: Decodable {
    let candidates: [Candidate]

    struct Candidate: Decodable {
        let content: Content
    }

    struct Content: Decodable {
        let parts: [Part]
    }

    struct Part: Decodable {
        let text: String?
    }
}

/// Gemini API error response
private struct GeminiErrorResponse: Decodable {
    let error: ErrorDetail

    struct ErrorDetail: Decodable {
        let message: String
    }
}

/// Ingredients response from API
private struct IngredientsResponse: Decodable {
    let ingredients: [Ingredient]
}

/// Recipes response from API
private struct RecipesResponse: Decodable {
    let recipes: [Recipe]
}

// MARK: - Error Types

enum GeminiError: LocalizedError {
    case imagePreparationFailed
    case invalidURL
    case requestEncodingFailed
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case emptyResponse
    case jsonParsingFailed
    case noIngredientsDetected
    case noIngredientsProvided
    case noRecipesGenerated

    var errorDescription: String? {
        switch self {
        case .imagePreparationFailed:
            return "Failed to prepare image for upload. Please try another photo."
        case .invalidURL:
            return "Invalid API endpoint URL."
        case .requestEncodingFailed:
            return "Failed to encode request data."
        case .invalidResponse:
            return "Invalid response from server."
        case .httpError(let code):
            return "Server error (HTTP \(code)). Please try again."
        case .apiError(let message):
            return "API Error: \(message)"
        case .emptyResponse:
            return "No response from AI. Please try again."
        case .jsonParsingFailed:
            return "Failed to parse AI response. Please try again."
        case .noIngredientsDetected:
            return "No ingredients detected in photo. Please try a clearer photo."
        case .noIngredientsProvided:
            return "No ingredients provided for recipe generation."
        case .noRecipesGenerated:
            return "Failed to generate recipes. Please try again."
        }
    }
}
