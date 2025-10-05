//
//  CameraView.swift
//  Meal Maker AI
//
//  Created by Nicholas Ho on 2025-10-04.
//

import SwiftUI
import AVFoundation
import PhotosUI

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CameraViewModel()
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false

    // Callback when ingredients are identified
    var onIngredientsIdentified: (([Ingredient]) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Title bar (matching home screen with back button)
            VStack(spacing: 0) {
                HStack {
                    // Back button
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 74/255, green: 93/255, blue: 74/255)) // Green
                            .padding(.trailing, 8)
                    }

                    Text("Scan Fridge")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 12)
            }
            .background(Color.white)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            .ignoresSafeArea(edges: .top)

            // Content area
            ZStack {
                Color(red: 248/255, green: 248/255, blue: 248/255) // #F8F8F8
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if viewModel.isProcessing {
                            // Processing state
                            processingView
                        } else if !viewModel.identifiedIngredients.isEmpty {
                            // Success - show ingredients and proceed
                            successView
                        } else {
                            // Initial state - capture options
                            captureOptionsView
                        }
                    }
                    .padding(.top, 40)
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker(image: $viewModel.capturedImage, onImageSelected: handleImageSelected)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraCapture(image: $viewModel.capturedImage, onImageCaptured: handleImageSelected)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Try Again") {
                viewModel.errorMessage = nil
                viewModel.reset()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Subviews

    private var captureOptionsView: some View {
        VStack(spacing: 40) {
            // Header section
            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 70))
                    .foregroundColor(Color(red: 74/255, green: 93/255, blue: 74/255)) // #4A5D4A green

                Text("Scan Your Fridge")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Text("Take a photo of your fridge contents to identify ingredients")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 60)

            // Button section
            VStack(spacing: 16) {
                // Primary button - Take Photo
                Button(action: { showingCamera = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.title3)
                        Text("Take Photo")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 74/255, green: 93/255, blue: 74/255)) // #4A5D4A green
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                }

                // Secondary button - Choose from Library
                Button(action: { showingPhotoPicker = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title3)
                        Text("Choose from Library")
                            .font(.headline)
                    }
                    .foregroundColor(Color(red: 74/255, green: 93/255, blue: 74/255))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 74/255, green: 93/255, blue: 74/255), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                }
            }
            .padding(.horizontal, 30)

            Spacer()
        }
    }

    private var processingView: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(2.0)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 74/255, green: 93/255, blue: 74/255))) // Green spinner

                Text("Analyzing your fridge...")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                Text("This may take a few seconds")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(40)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

            Spacer()
        }
        .padding(.horizontal, 30)
    }

    private var successView: some View {
        VStack(spacing: 30) {
            Spacer()

            // Success card
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(Color(red: 74/255, green: 93/255, blue: 74/255)) // Green checkmark

                Text("Found \(viewModel.identifiedIngredients.count) ingredients!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                // Review button
                Button {
                    // Fix: Use DispatchQueue to ensure state is fully propagated
                    DispatchQueue.main.async {
                        proceedToIngredients()
                    }
                } label: {
                    Text("Review Ingredients")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 74/255, green: 93/255, blue: 74/255)) // #4A5D4A green
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                }

                // Scan again button
                Button(action: viewModel.reset) {
                    Text("Scan Again")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                }
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

            Spacer()
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Actions

    private func handleImageSelected(_ image: UIImage) {
        print("🔍 [CameraView] handleImageSelected() called with image: \(image.size)")
        // Process the image directly (don't rely on binding timing)
        Task {
            print("🔍 [CameraView] Starting async processImage task")
            await viewModel.processImage(image)
            print("🔍 [CameraView] processImage task completed")
            print("🔍 [CameraView] viewModel.identifiedIngredients.count = \(viewModel.identifiedIngredients.count)")
        }
    }

    private func proceedToIngredients() {
        print("🔍 [CameraView] proceedToIngredients() called")
        print("🔍 [CameraView] viewModel.identifiedIngredients.count = \(viewModel.identifiedIngredients.count)")
        viewModel.identifiedIngredients.forEach { ingredient in
            print("  📦 Sending: \(ingredient.name) - \(ingredient.quantity ?? "no quantity")")
        }
        print("🔍 [CameraView] Calling callback with \(viewModel.identifiedIngredients.count) ingredients")
        onIngredientsIdentified?(viewModel.identifiedIngredients)
        print("🔍 [CameraView] Callback completed")
    }
}

// MARK: - Photo Picker

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImageSelected: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        if let uiImage = image as? UIImage {
                            self.parent.image = uiImage
                            self.parent.onImageSelected(uiImage)  // Pass image directly
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Camera Capture

struct CameraCapture: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    @Binding var image: UIImage?
    var onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCapture

        init(_ parent: CameraCapture) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImageCaptured(image)  // Pass image directly
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
