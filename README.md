# Swift_NSFW_Detector
An NSFW image detector for Swift built as an extension on UIImage.

If you've ever allowed users to share images you are probably wishing you had implemented a 'hotdog' filter. Now you can easily filter images when they are selected or before they are shared.

The MLModel used in this implementation is the OpenNSFW.mlmodel

Based on https://github.com/kashif/NsfwDetector this extension makes implementation much simpler.

## Installation

Copy `NSFWDetector.swift` and `OpenNSFW.mlmodel` into your project and you're done.

## Sample usage:

    let image = UIImage(...)
    image.checkNSFW() { result, confidence in
      switch result {
        case .sfw:
          self.allowImage()
        case .nsfw:
          if conficence > 0.5 {
            self.blockImage()
          } else {
            self.allowImage()
          }
        case .unknown:
          self.flagImage()
      }
    }

