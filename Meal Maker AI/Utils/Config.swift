//
//  Config.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import Foundation

// ⚠️ SECURITY WARNING - HACKATHON MVP ONLY ⚠️
//
// This file contains a hardcoded API key for demonstration purposes ONLY.
//
// ❌ DO NOT USE IN PRODUCTION
// ❌ DO NOT PUBLISH TO APP STORE
// ❌ DO NOT SHARE THIS CODE PUBLICLY WITH THE KEY
//
// TODO: Before production deployment:
// 1. Remove hardcoded API key from this file
// 2. Implement backend proxy server (Node.js/Python/Go)
// 3. Move API key to backend environment variables
// 4. Update GeminiService to call YOUR backend, not Gemini directly
// 5. Backend should validate requests and rate-limit per user
//
// Example backend architecture:
// iOS App → https://your-backend.com/api/identify-ingredients → Gemini API
//          (no API key)                                      (key secure on server)

enum Config {
    /// Gemini API Key - HACKATHON DEMO ONLY
    ///
    /// ⚠️ THIS IS INSECURE - Anyone can decompile the app and extract this key
    /// ⚠️ TODO: Move to secure backend before production deployment
    static var geminiAPIKey: String {
        // HACKATHON ONLY: Hardcoded API key
        // TODO: Replace with backend API call before production
        return "AIzaSyD3K3llXHluUU0UEeHuRoDsBvVbNuCJKrM"
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
