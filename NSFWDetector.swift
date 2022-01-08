//
// https://github.com/OurBigAdventure/Swift_NSFW_Detector
//

import UIKit
import CoreML
import Vision
import ImageIO

enum NSFW {
  case sfw
  case nsfw
  case unknown
}

extension CGImagePropertyOrientation {
  init(_ orientation: UIImage.Orientation) {
    switch orientation {
      case .up: self = .up
      case .upMirrored: self = .upMirrored
      case .down: self = .down
      case .downMirrored: self = .downMirrored
      case .left: self = .left
      case .leftMirrored: self = .leftMirrored
      case .right: self = .right
      case .rightMirrored: self = .rightMirrored
      @unknown default:
        self = .up
        print("🧨 Unknown UIImage Orientation. Set as .up by default.")
    }
  }
}

extension UIImage {

  /// Check if an image is NSFW.  This call processes an image using the
  /// OpenNSFW MLModel and returns an NSFW flag along with a
  /// confidence score (0-1).
  ///
  /// Sample usage:
  /// let image = UIImage(...)
  /// image.checkNSFW() { result, confidence in
  ///   switch result {
  ///     case .sfw:
  ///       self.allowImage()
  ///     case .nsfw:
  ///       if conficence > 0.5 {
  ///         self.blockImage()
  ///       } else {
  ///         self.allowImage()
  ///       }
  ///     case .unknown:
  ///       self.flagImage()
  ///   }
  /// }
  ///
  /// - Parameter completion: (NSFW, Float)->()
  func checkNSFW(completion: @escaping (NSFW, Float)->()) {
    guard let ciImage = CIImage(image: self) else {
      print("🧨 Could not create CIImage")
      completion(.unknown, 0.0)
      return
    }
    let orientation = CGImagePropertyOrientation(self.imageOrientation)
    let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation, options: [:])
    do {
      let modelConfig = MLModelConfiguration()
      let model = try OpenNSFW(configuration: modelConfig)
      let NSFWmodel = try VNCoreMLModel(for: model.model)
      let vnRequest = VNCoreMLRequest(model: NSFWmodel, completionHandler: { request, error in
        if let error = error {
          print("🧨 VNCoreMLRequest Error: \(error.localizedDescription)")
          completion(.unknown, 0.0)
          return
        }
        guard let observations = request.results as? [VNClassificationObservation] else {
          print("🧨 Unexpected result type from VNCoreMLRequest")
          completion(.unknown, 0.0)
          return
        }
        guard let best = observations.first else {
          print("🧨 Unable to retrieve NSFW observation")
          completion(.unknown, 0.0)
          return
        }
        switch best.identifier {
          case "NSFW": completion(.nsfw, best.confidence)
          case "SFW": completion(.sfw, best.confidence)
          default: completion(.unknown, best.confidence)
        }
      })
      try handler.perform([vnRequest])
    } catch let error {
      completion(.unknown, 0.0)
      print("🧨 Cannot load ML model: \(error.localizedDescription)")
    }
  }

}
