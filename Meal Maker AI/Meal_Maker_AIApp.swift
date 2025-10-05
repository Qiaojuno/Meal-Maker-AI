//
//  Meal_Maker_AIApp.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import SwiftUI

@main
struct Meal_Maker_AIApp: App {
    init() {
        // Clean up old auto-saved recipes from previous schema
        StorageService.shared.cleanupOldRecipes()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
}
