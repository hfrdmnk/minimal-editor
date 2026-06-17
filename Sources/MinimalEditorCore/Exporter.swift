import CoreImage
import Foundation
import ImageIO

public enum ExportFormat {
    case png
    case jpeg(quality: Double)

    public var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        }
    }
}

/// Writes a rendered image to disk, preserving sRGB.
public enum Exporter {
    public static func write(
        _ image: CIImage,
        to url: URL,
        format: ExportFormat,
        context: CIContext
    ) throws {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB) else { return }
        switch format {
        case .png:
            try context.writePNGRepresentation(of: image, to: url, format: .RGBA8, colorSpace: space)
        case let .jpeg(quality):
            let key = CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String)
            try context.writeJPEGRepresentation(
                of: image, to: url, colorSpace: space, options: [key: quality])
        }
    }
}
