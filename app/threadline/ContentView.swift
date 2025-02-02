//
//  ContentView.swift
//  threadline
//
//  Created by sheline on 1/27/25.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI
import Vision
import VisionKit

extension View {
// This function changes our View to UIView, then calls another function
// to convert the newly-made UIView to a UIImage.
    public func asUIImage() -> UIImage {
        let controller = UIHostingController(rootView: self)
        
        // Set the background to be transparent incase the image is a PNG, WebP or (Static) GIF
        controller.view.backgroundColor = .clear
        
        controller.view.frame = CGRect(x: 0, y: CGFloat(Int.max), width: 1, height: 1)
        UIApplication.shared.windows.first!.rootViewController?.view.addSubview(controller.view)
        
        let size = controller.sizeThatFits(in: UIScreen.main.bounds.size)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.sizeToFit()
        
        // here is the call to the function that converts UIView to UIImage: `.asUIImage()`
        let image = controller.view.asUIImage()
        controller.view.removeFromSuperview()
        return image
    }
}

extension UIView {
    // This is the function to convert UIView to UIImage
    public func asUIImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

struct ContentView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var isShowingPhotoPicker = false

    var body: some View {
        VStack(spacing: 20) {
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            } else {
                Text("Select an image of a clothing item")
                    .foregroundColor(.gray)
            }

            Button(action: {
                isShowingPhotoPicker = true
            }) {
                Text("Choose Image")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .sheet(isPresented: $isShowingPhotoPicker) {
            PhotoPicker(selectedImage: $selectedImage)
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
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

            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                return
            }

            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let self = self, let uiImage = image as? UIImage, error == nil else {
                    return
                }

                DispatchQueue.main.async {
                    self.parent.selectedImage = uiImage
                    
                    // have the image here
                    self.parent.removeBackground()
                }
            }
        }

    }

    private func createMask(from inputImage: CIImage) -> CIImage? {
    
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: inputImage)

        do {
            try handler.perform([request])
            
            if let result = request.results?.first {
                let mask = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
                return CIImage(cvPixelBuffer: mask)
            }
        } catch {
            print("Vision error: \(error)")
        }
        
        return nil
    }

    private func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        
        return filter.outputImage!
    }

    private func convertToUIImage(ciImage: CIImage) -> UIImage {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            fatalError("Failed to render CGImage")
        }
        
        return UIImage(cgImage: cgImage)
    }

    private func removeBackground() {
        guard let inputImage = CIImage(image: selectedImage!) else {
            print("Failed to create CIImage")
            return
        }
        
        Task {
            guard let maskImage = createMask(from: inputImage) else {
                print("Failed to create mask")
                return
            }
            
            let outputImage = applyMask(mask: maskImage, to: inputImage)
            let finalImage = convertToUIImage(ciImage: outputImage)
            
            selectedImage = finalImage
        }
    }
}

//#Preview {
//    ContentView()
//}
