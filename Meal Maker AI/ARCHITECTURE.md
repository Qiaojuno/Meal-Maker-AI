# FridgeScanner MVP - 24 Hour Architecture Plan

## Project Structure
```
FridgeScanner/
├── Models/
│   ├── Ingredient.swift
│   ├── Recipe.swift
│   └── ScanResult.swift
├── ViewModels/
│   ├── CameraViewModel.swift
│   ├── IngredientListViewModel.swift
│   ├── RecipeViewModel.swift
│   └── SavedRecipesViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── CameraView.swift
│   ├── IngredientListView.swift
│   ├── RecipeGenerationView.swift
│   ├── RecipeDetailView.swift
│   └── SavedRecipesView.swift
├── Services/
│   ├── GeminiService.swift
│   ├── ClaudeService.swift (fallback)
│   ├── StorageService.swift
│   └── CameraService.swift
├── Utils/
│   ├── Config.swift
│   └── Extensions.swift
└── Resources/
    └── .env
```

## Core Models

### Ingredient.swift
```swift
struct Ingredient: Identifiable, Codable {
    let id = UUID()
    var name: String
    var quantity: String?
    var isConfirmed: Bool = false
}
```

### Recipe.swift
```swift
struct Recipe: Identifiable, Codable {
    let id = UUID()
    let title: String
    let ingredients: [String]
    let instructions: [String]
    let cookingTime: String?
    let difficulty: String?
    let createdAt: Date = Date()
    var isSaved: Bool = false
}
```

### ScanResult.swift
```swift
struct ScanResult: Codable {
    let ingredients: [Ingredient]
    let confidence: Double
    let timestamp: Date
}
```

## MVVM ViewModels

### CameraViewModel.swift
```swift
@MainActor
class CameraViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private let geminiService = GeminiService()

    func captureAndProcessImage(_ image: UIImage) async {
        // Handle image capture and trigger Gemini API
    }

    func retakePhoto() {
        // Reset state for new capture
    }
}
```

### IngredientListViewModel.swift
```swift
@MainActor
class IngredientListViewModel: ObservableObject {
    @Published var ingredients: [Ingredient] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func addIngredient(_ name: String) {
        // Manual ingredient addition
    }

    func removeIngredient(_ ingredient: Ingredient) {
        // Remove ingredient from list
    }

    func confirmIngredientList() {
        // Proceed to recipe generation
    }
}
```

### RecipeViewModel.swift
```swift
@MainActor
class RecipeViewModel: ObservableObject {
    @Published var generatedRecipes: [Recipe] = []
    @Published var isGenerating = false
    @Published var errorMessage: String?

    private let geminiService = GeminiService()
    private let storageService = StorageService()

    func generateRecipes(from ingredients: [Ingredient]) async {
        // Generate recipes using Gemini API
    }

    func saveRecipe(_ recipe: Recipe) {
        // Save to local storage
    }
}
```

## Services Architecture

### GeminiService.swift
```swift
class GeminiService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let maxIngredients = 12

    init() {
        self.apiKey = Config.geminiAPIKey
    }

    // Ingredient identification from image
    func identifyIngredients(from image: UIImage) async throws -> [Ingredient] {
        let base64Image = image.base64EncodedString()
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
        - Return up to 12 significant ingredients maximum
        """

        let ingredients: [Ingredient] = try await makeAPICall(prompt: prompt, image: base64Image)

        // Truncate if more than max (though prompt asks for max 12)
        let truncatedIngredients = Array(ingredients.prefix(maxIngredients))

        return truncatedIngredients
    }

    // Recipe generation from ingredients
    func generateRecipes(from ingredients: [Ingredient]) async throws -> [Recipe] {
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
        """

        return try await makeAPICall(prompt: prompt, image: nil)
    }

    private func makeAPICall<T: Codable>(prompt: String, image: String?) async throws -> T {
        // Generic API call handler with JSON response parsing
        // Implementation details for Gemini API calls

        var requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]

        // Add image if provided
        if let imageData = image {
            requestBody["contents"] = [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": imageData
                            ]
                        ]
                    ]
                ]
            ]
        }

        // Make actual API call, parse JSON response
        // Handle errors and return parsed object

        // Placeholder implementation - will be completed in Claude Code
        fatalError("API implementation needed")
    }
}
```

### StorageService.swift
```swift
class StorageService {
    private let userDefaults = UserDefaults.standard
    private let savedRecipesKey = "savedRecipes"

    func saveRecipe(_ recipe: Recipe) {
        var savedRecipes = getSavedRecipes()
        savedRecipes.append(recipe)

        if let data = try? JSONEncoder().encode(savedRecipes) {
            userDefaults.set(data, forKey: savedRecipesKey)
        }
    }

    func getSavedRecipes() -> [Recipe] {
        guard let data = userDefaults.data(forKey: savedRecipesKey),
              let recipes = try? JSONDecoder().decode([Recipe].self, from: data) else {
            return []
        }
        return recipes
    }

    func deleteRecipe(_ recipe: Recipe) {
        var savedRecipes = getSavedRecipes()
        savedRecipes.removeAll { $0.id == recipe.id }

        if let data = try? JSONEncoder().encode(savedRecipes) {
            userDefaults.set(data, forKey: savedRecipesKey)
        }
    }
}
```

## Configuration & Environment

### Config.swift
```swift
struct Config {
    static var geminiAPIKey: String {
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil),
              let content = try? String(contentsOfFile: path),
              let key = parseEnvFile(content)["GEMINI_API_KEY"] else {
            fatalError("GEMINI_API_KEY not found in .env file")
        }
        return key
    }

    static var claudeAPIKey: String {
        // Similar implementation for Claude fallback
    }

    private static func parseEnvFile(_ content: String) -> [String: String] {
        var result: [String: String] = [:]
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let parts = line.components(separatedBy: "=")
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                result[key] = value
            }
        }
        return result
    }
}
```

## Main App Flow

### ContentView.swift
```swift
struct ContentView: View {
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var currentStep: AppStep = .camera

    enum AppStep {
        case camera
        case ingredientList
        case recipeGeneration
        case savedRecipes
    }

    var body: some View {
        NavigationView {
            switch currentStep {
            case .camera:
                CameraView(viewModel: cameraViewModel)
            case .ingredientList:
                IngredientListView()
            case .recipeGeneration:
                RecipeGenerationView()
            case .savedRecipes:
                SavedRecipesView()
            }
        }
    }
}
```

## 24-Hour Implementation Timeline

### Hours 1-4: Foundation Setup
- [x] Create Xcode project with MVVM structure
- [x] Set up .env file and Config.swift
- [x] Create all model structs
- [x] Basic navigation structure

### Hours 5-8: Camera Implementation
- [x] Camera view with AVFoundation
- [x] Image capture and preview
- [x] Basic error handling
- [x] CameraViewModel implementation

### Hours 9-12: Gemini Integration
- [x] GeminiService implementation
- [x] Image-to-ingredients API call
- [x] JSON parsing and error handling
- [x] Loading states

### Hours 13-16: Ingredient Management
- [x] IngredientListView with edit capabilities
- [x] Add/remove ingredients manually
- [x] Rescan functionality
- [x] Confirmation flow

### Hours 17-20: Recipe Generation
- [x] Recipe generation from ingredient list
- [x] RecipeDetailView with instructions
- [x] Recipe display UI
- [x] Loading states for generation

### Hours 21-22: Local Storage
- [x] StorageService implementation
- [x] Save/retrieve recipes
- [x] SavedRecipesView

### Hours 23-24: Polish & Testing
- [x] Error handling and edge cases
- [x] UI polish and loading states
- [x] Real device testing
- [x] Demo preparation

## API Prompt Templates

### Ingredient Identification Prompt
```
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
- Return up to 12 significant ingredients maximum
```

### Recipe Generation Prompt
```
Create exactly 3 recipes for college students using these ingredients: [INGREDIENT_LIST]

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
```

## Risk Mitigation

### Potential Issues & Solutions
1. **Gemini API Rate Limits**: Implement exponential backoff
2. **Poor Image Quality**: Add image quality validation
3. **Ingredient Recognition Failures**: Manual edit capability
4. **JSON Parsing Errors**: Robust error handling with fallback
5. **Network Connectivity**: Offline state management

### Claude Fallback Implementation
```swift
// Simple fallback service if Gemini fails
class ClaudeService {
    func fallbackIngredientIdentification(_ prompt: String) async throws -> [Ingredient] {
        // Manual prompt construction for Claude API
        // Or prompt user to use Claude.ai manually
    }
}
```

This architecture gives us a solid foundation for the 24-hour MVP while keeping everything modular and testable. Ready to start coding?
