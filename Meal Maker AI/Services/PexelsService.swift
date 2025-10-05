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
        let searchQuery = extractFoodKeywords(from: recipeTitle)

        // Try full query first
        if let imageURL = try? await performSearch(query: searchQuery) {
            return imageURL
        }

        // Fallback to generic "food" if no results
        if let imageURL = try? await performSearch(query: "food") {
            return imageURL
        }

        throw PexelsError.noResults
    }

    // Extract food-related keywords from recipe title
    private func extractFoodKeywords(from title: String) -> String {
        // Remove common words/phrases that aren't food-related
        let wordsToRemove = ["recipe", "easy", "quick", "delicious", "homemade", "simple",
                            "best", "perfect", "classic", "traditional", "gordon", "ramsay",
                            "ramsay's", "chef", "mom's", "grandma's", "authentic"]

        var cleanTitle = title.lowercased()

        // Remove possessives
        cleanTitle = cleanTitle.replacingOccurrences(of: "'s", with: "")

        // Remove words to remove
        for word in wordsToRemove {
            cleanTitle = cleanTitle.replacingOccurrences(of: word, with: "")
        }

        // Clean up extra spaces
        cleanTitle = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanTitle = cleanTitle.replacingOccurrences(of: "  ", with: " ")

        // If we removed everything, use the original title
        if cleanTitle.isEmpty {
            return title
        }

        return cleanTitle
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
