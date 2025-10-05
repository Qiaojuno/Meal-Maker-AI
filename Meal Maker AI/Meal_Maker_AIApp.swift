//
//  Meal_Maker_AIApp.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import SwiftUI

@main
struct Meal_Maker_AIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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

// App Delegate to lock orientation to portrait only
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait  // Lock to portrait mode only
    }
}
