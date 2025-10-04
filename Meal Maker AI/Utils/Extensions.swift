//
//  Extensions.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import UIKit
import SwiftUI

// MARK: - UIImage Extensions

extension UIImage {
    /// Convert UIImage to base64 encoded string (JPEG format)
    /// - Parameter compressionQuality: JPEG compression quality (0.0 to 1.0). Default is 0.8
    /// - Returns: Base64 encoded string, or nil if conversion fails
    func toBase64String(compressionQuality: CGFloat = 0.8) -> String? {
        guard let imageData = self.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        return imageData.base64EncodedString()
    }

    /// Resize image to fit within max dimensions while maintaining aspect ratio
    /// - Parameters:
    ///   - maxWidth: Maximum width in pixels
    ///   - maxHeight: Maximum height in pixels
    /// - Returns: Resized UIImage
    func resized(maxWidth: CGFloat = 1024, maxHeight: CGFloat = 1024) -> UIImage {
        let size = self.size

        // Calculate scaling factor
        let widthRatio = maxWidth / size.width
        let heightRatio = maxHeight / size.height
        let scaleFactor = min(widthRatio, heightRatio, 1.0)  // Don't upscale

        // If no resizing needed, return original
        guard scaleFactor < 1.0 else { return self }

        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

        // Perform resize
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Prepare image for API upload (resize + compress)
    /// Returns base64 encoded string optimized for Gemini API
    /// - Returns: Base64 encoded string, or nil if preparation fails
    func preparedForAPI() -> String? {
        // Resize to max 1024x1024 (Gemini API recommendation)
        let resized = self.resized(maxWidth: 1024, maxHeight: 1024)

        // Compress to JPEG with 80% quality
        return resized.toBase64String(compressionQuality: 0.8)
    }
}

// MARK: - String Extensions

extension String {
    /// Check if string is a valid (non-empty, trimmed)
    var isValidInput: Bool {
        return !self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Trim whitespace and newlines
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - View Extensions

extension View {
    /// Hide keyboard when tapping outside
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
