//
//  Recipe.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import Foundation

struct Recipe: Identifiable, Codable, Hashable {
    var id: UUID = UUID()  // Mutable to allow decoding
    let title: String
    let ingredients: [String]
    let instructions: [String]
    let cookingTime: String?  // e.g., "25 minutes"
    let difficulty: String?  // e.g., "easy", "medium"
    let servings: Int?  // Number of servings
    var createdAt: Date = Date()
    var isSaved: Bool = false

    // Custom coding keys for JSON mapping (API uses different names)
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case ingredients
        case instructions
        case cookingTime = "estimated_time"  // API returns "estimated_time"
        case difficulty
        case servings
        case createdAt
        case isSaved
    }

    // Custom initializer
    init(
        id: UUID = UUID(),
        title: String,
        ingredients: [String],
        instructions: [String],
        cookingTime: String? = nil,
        difficulty: String? = nil,
        servings: Int? = nil,
        createdAt: Date = Date(),
        isSaved: Bool = false
    ) {
        self.id = id
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
        self.cookingTime = cookingTime
        self.difficulty = difficulty
        self.servings = servings
        self.createdAt = createdAt
        self.isSaved = isSaved
    }

    // Custom decoder to handle API response format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.ingredients = try container.decode([String].self, forKey: .ingredients)
        self.instructions = try container.decode([String].self, forKey: .instructions)

        // Handle cookingTime as either String or Int from API
        if let timeInt = try? container.decode(Int.self, forKey: .cookingTime) {
            self.cookingTime = "\(timeInt) minutes"
        } else {
            self.cookingTime = try? container.decode(String.self, forKey: .cookingTime)
        }

        self.difficulty = try? container.decode(String.self, forKey: .difficulty)
        self.servings = try? container.decode(Int.self, forKey: .servings)
        self.createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        self.isSaved = (try? container.decode(Bool.self, forKey: .isSaved)) ?? false
    }
}
