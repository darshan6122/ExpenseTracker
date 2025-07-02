import UIKit
import Vision
import VisionKit

class ImageProcessingService {
    static let shared = ImageProcessingService()
    
    private init() {}
    
    // MARK: - Image Processing
    
    func processReceiptImage(_ image: UIImage) async throws -> (processedImage: UIImage, text: String) {
        // Resize image if needed
        let resizedImage = resizeImageIfNeeded(image)
        
        // Convert to grayscale for better text recognition
        let grayscaleImage = convertToGrayscale(resizedImage)
        
        // Perform text recognition
        let text = try await performTextRecognition(on: grayscaleImage)
        
        return (grayscaleImage, text)
    }
    
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 2048
        let size = image.size
        
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func convertToGrayscale(_ image: UIImage) -> UIImage {
        let context = CIContext(options: nil)
        let currentFilter = CIFilter(name: "CIColorControls")
        currentFilter?.setValue(CIImage(image: image), forKey: kCIInputImageKey)
        currentFilter?.setValue(0.0, forKey: kCIInputSaturationKey)
        
        guard let output = currentFilter?.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func performTextRecognition(on image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw ImageProcessingError.invalidImage
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        
        try await requestHandler.perform([request])
        
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return ""
        }
        
        return observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: "\n")
    }
    
    // MARK: - Image Storage
    
    func saveImage(_ image: UIImage, for expenseId: UUID) throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(expenseId.uuidString).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ImageProcessingError.compressionFailed
        }
        
        try imageData.write(to: fileURL)
        return fileURL
    }
    
    func loadImage(from url: URL) throws -> UIImage {
        guard let imageData = try? Data(contentsOf: url),
              let image = UIImage(data: imageData) else {
            throw ImageProcessingError.loadFailed
        }
        return image
    }
    
    func deleteImage(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}

enum ImageProcessingError: Error {
    case invalidImage
    case compressionFailed
    case loadFailed
    case saveFailed
} 