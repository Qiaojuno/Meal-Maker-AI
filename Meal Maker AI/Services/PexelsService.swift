//
//  PexelsService.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import Foundation

class PexelsService {
    private let apiKey = "ee1AgRWUaXqDy94EDQ0MIFvwCq0xPxhp1MFpj24DQZ3ZZsRObQwLzRgs"
    private let baseURL = "https://api.pexels.com/v1"

    enum PexelsError: Error {
        case invalidURL
        case networkError(Error)
        case noResults
        case invalidResponse
    }

    // Search for a food photo based on recipe title
    func searchFoodPhoto(for recipeTitle: String) async throws -> String {
        // Extract primary food keywords from recipe title
        let extractedKeywords = extractFoodKeywords(from: recipeTitle)

        // If extraction returned nil, no food words found - show placeholder
        guard let searchQuery = extractedKeywords, !searchQuery.isEmpty else {
            throw PexelsError.noResults
        }

        // Try search with extracted food keywords only (don't add "food dish")
        if let imageURL = try? await performSearch(query: searchQuery) {
            return imageURL
        }

        // If no match found, show placeholder icon
        throw PexelsError.noResults
    }

    // Extract food-related keywords from recipe title
    // Returns nil if no food words are detected
    private func extractFoodKeywords(from title: String) -> String? {
        // Common food-related words to identify main ingredient
        let foodWords = ["pasta", "chicken", "beef", "pork", "fish", "salmon", "tuna", "shrimp",
                        "rice", "noodles", "soup", "salad", "pizza", "burger", "sandwich",
                        "steak", "tacos", "burrito", "curry", "stir fry", "roast", "grilled",
                        "baked", "fried", "spaghetti", "lasagna", "risotto", "paella",
                        "sushi", "ramen", "pho", "pie", "cake", "bread", "cookies",
                        "vegetables", "potatoes", "beans", "lentils", "quinoa", "tofu",
                        "eggs", "omelette", "pancakes", "waffles", "meatballs", "chili",
                        "carbonara", "alfredo", "marinara", "pesto", "bolognese",
                        "teriyaki", "pad thai", "penne", "fettuccine", "ravioli",
                        "kebab", "fajitas", "enchiladas", "quesadilla", "nachos", "wings",
                        "ribs", "bacon", "sausage", "ham", "turkey", "duck", "lamb",
                        "shrimp", "crab", "lobster", "scallops", "oysters", "mussels",
                        "broccoli", "spinach", "kale", "carrots", "mushrooms", "peppers",
                        "tomato", "onion", "garlic", "ginger", "avocado", "asparagus"]

        var cleanTitle = title.lowercased()

        // Remove possessives
        cleanTitle = cleanTitle.replacingOccurrences(of: "'s", with: "")

        // Remove non-food descriptive words
        let wordsToRemove = ["recipe", "easy", "quick", "delicious", "homemade", "simple",
                            "best", "perfect", "classic", "traditional", "gordon", "ramsay",
                            "chef", "mom", "grandma", "authentic", "amazing", "incredible",
                            "ultimate", "favorite", "world", "famous", "style", "the", "a", "an"]

        for word in wordsToRemove {
            cleanTitle = cleanTitle.replacingOccurrences(of: " \(word) ", with: " ")
            cleanTitle = cleanTitle.replacingOccurrences(of: "^\(word) ", with: "", options: .regularExpression)
            cleanTitle = cleanTitle.replacingOccurrences(of: " \(word)$", with: "", options: .regularExpression)
        }

        // Clean up extra spaces
        cleanTitle = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanTitle = cleanTitle.replacingOccurrences(of: "  ", with: " ")

        // ONLY return results if we find a known food word
        for foodWord in foodWords {
            if cleanTitle.contains(foodWord) {
                // Extract the food word and surrounding context (max 3 words)
                let words = cleanTitle.split(separator: " ")
                if let index = words.firstIndex(where: { $0.contains(foodWord) }) {
                    let start = max(0, index - 1)
                    let end = min(words.count, index + 2)
                    return words[start..<end].joined(separator: " ")
                }
            }
        }

        // No food word found - return nil to show placeholder
        return nil
    }

    // Perform the actual Pexels API search
    private func performSearch(query: String) async throws -> String {
        // Encode query for URL
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?query=\(encodedQuery)&per_page=1") else {
            throw PexelsError.invalidURL
        }

        // Create request with authorization header
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw PexelsError.invalidResponse
            }

            // Parse JSON response
            let searchResponse = try JSONDecoder().decode(PexelsSearchResponse.self, from: data)

            guard let firstPhoto = searchResponse.photos.first else {
                throw PexelsError.noResults
            }

            // Return medium-sized image URL
            return firstPhoto.src.medium

        } catch let error as PexelsError {
            throw error
        } catch {
            throw PexelsError.networkError(error)
        }
    }
}

// MARK: - Pexels API Response Models

struct PexelsSearchResponse: Codable {
    let photos: [PexelsPhoto]
}

struct PexelsPhoto: Codable {
    let id: Int
    let src: PexelsSrc
}

struct PexelsSrc: Codable {
    let original: String
    let large2x: String
    let large: String
    let medium: String
    let small: String
    let portrait: String
    let landscape: String
    let tiny: String
}
