//
//  Config.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import Foundation

enum Config {
    /// Gemini API Key from .env file
    static var geminiAPIKey: String {
        // First try to read from .env file in bundle
        if let path = Bundle.main.path(forResource: ".env", ofType: nil),
           let content = try? String(contentsOfFile: path),
           let key = parseEnvFile(content)["GEMINI_API_KEY"], !key.isEmpty {
            return key
        }

        // Fallback: Check Info.plist (for production builds)
        if let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String, !key.isEmpty {
            return key
        }

        // Development fallback: Return placeholder
        // This allows app to compile but will fail at runtime if key not set
        return "YOUR_GEMINI_API_KEY_HERE"
    }

    /// Check if Gemini API key is configured
    static var isGeminiConfigured: Bool {
        let key = geminiAPIKey
        return !key.isEmpty && key != "YOUR_GEMINI_API_KEY_HERE"
    }

    /// Parse .env file contents into dictionary
    private static func parseEnvFile(_ content: String) -> [String: String] {
        var result: [String: String] = [:]
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            // Skip comments and empty lines
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            // Parse KEY=VALUE format
            let parts = trimmed.components(separatedBy: "=")
            guard parts.count >= 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1...].joined(separator: "=")  // Handle values with = in them
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))  // Remove quotes

            result[key] = value
        }

        return result
    }
}
