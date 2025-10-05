//
//  Ingredient.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import Foundation

struct Ingredient: Identifiable, Codable, Hashable {
    var id: UUID = UUID()  // Mutable to allow decoding
    var name: String
    var quantity: String?
    var category: String?  // "Vegetables", "Carbohydrates", "Protein", "Dairy"
    var isConfirmed: Bool = false

    // Custom coding keys to ensure proper JSON mapping
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case quantity
        case category
        case isConfirmed
    }

    // Custom initializer for manual creation
    init(id: UUID = UUID(), name: String, quantity: String? = nil, category: String? = nil, isConfirmed: Bool = false) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.category = category
        self.isConfirmed = isConfirmed
    }

    // Custom decoder to handle missing id from API responses
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode id, or generate new one if missing (for API responses)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.quantity = try? container.decode(String.self, forKey: .quantity)
        self.category = try? container.decode(String.self, forKey: .category)
        self.isConfirmed = (try? container.decode(Bool.self, forKey: .isConfirmed)) ?? false
    }
}
