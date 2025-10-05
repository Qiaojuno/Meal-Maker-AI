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
    @StateObject private var viewModel = CameraViewModel()
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false

    // Callback when ingredients are identified
    var onIngredientsIdentified: (([Ingredient]) -> Void)?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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
            .padding()
        }
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
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)

                Text("Scan Your Fridge")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Take a photo of your fridge contents to get started")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 16) {
                Button(action: { showingCamera = true }) {
                    Label("Take Photo", systemImage: "camera")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }

                Button(action: { showingPhotoPicker = true }) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))

            Text("Analyzing your fridge...")
                .font(.headline)
                .foregroundColor(.white)

            Text("This may take a few seconds")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }

    private var successView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Found \(viewModel.identifiedIngredients.count) ingredients!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Button {
                // Fix: Use DispatchQueue to ensure state is fully propagated
                // This prevents race condition where button click happens
                // before @Published property updates the view
                DispatchQueue.main.async {
                    proceedToIngredients()
                }
            } label: {
                Text("Review Ingredients")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)

            Button(action: viewModel.reset) {
                Text("Scan Again")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
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
