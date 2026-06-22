import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum ImageFormat: String, CaseIterable, Identifiable, Sendable {
    case jpeg
    case png
    case avif

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .jpeg: "JPEG"
        case .png: "PNG"
        case .avif: "AVIF"
        }
    }

    public var fileExtension: String {
        switch self {
        case .jpeg: "jpg"
        case .png: "png"
        case .avif: "avif"
        }
    }

    /// PNG is lossless, so it ignores the quality setting.
    public var isLossy: Bool { self != .png }

    public var utType: UTType {
        switch self {
        case .jpeg: .jpeg
        case .png: .png
        // String init dodges the macOS 13 SDK symbol; "public.avif" is stable.
        case .avif: UTType("public.avif") ?? .jpeg
        }
    }
}

public struct ExportSettings: Sendable {
    public var format: ImageFormat
    /// 0...1, applied only to lossy formats.
    public var quality: Double
    /// Scales the image down to this width (aspect preserved) when it's wider.
    /// `nil` keeps the original width.
    public var maxWidth: Int?

    public init(format: ImageFormat = .jpeg, quality: Double = 0.8, maxWidth: Int? = nil) {
        self.format = format
        self.quality = quality
        self.maxWidth = maxWidth
    }
}

public enum ExportError: LocalizedError {
    case renderFailed
    case unsupportedFormat
    case writeFailed

    public var errorDescription: String? {
        switch self {
        case .renderFailed: "Couldn't render the image."
        case .unsupportedFormat: "This format isn't supported on this Mac."
        case .writeFailed: "Couldn't write the file."
        }
    }
}

/// Writes a rendered image to disk, preserving sRGB.
public enum Exporter {
    public static func write(
        _ image: CIImage,
        to url: URL,
        settings: ExportSettings,
        context: CIContext
    ) throws {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB) else { return }
        let out = downscaled(image, maxWidth: settings.maxWidth)

        switch settings.format {
        case .png:
            try context.writePNGRepresentation(of: out, to: url, format: .RGBA8, colorSpace: space)
        case .jpeg:
            let key = CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String)
            try context.writeJPEGRepresentation(
                of: out, to: url, colorSpace: space, options: [key: settings.quality])
        case .avif:
            // No Core Image convenience writer exists for AVIF; go through ImageIO.
            try writeWithImageIO(
                out, to: url, type: settings.format.utType,
                quality: settings.quality, colorSpace: space, context: context)
        }
    }

    private static func downscaled(_ image: CIImage, maxWidth: Int?) -> CIImage {
        guard let maxWidth, maxWidth > 0, image.extent.width > CGFloat(maxWidth) else { return image }
        let scale = CGFloat(maxWidth) / image.extent.width
        return image.applyingFilter("CILanczosScaleTransform", parameters: [
            kCIInputScaleKey: scale,
            kCIInputAspectRatioKey: 1.0,
        ])
    }

    private static func writeWithImageIO(
        _ image: CIImage,
        to url: URL,
        type: UTType,
        quality: Double,
        colorSpace: CGColorSpace,
        context: CIContext
    ) throws {
        guard let cg = context.createCGImage(
            image, from: image.extent, format: .RGBA8, colorSpace: colorSpace)
        else { throw ExportError.renderFailed }
        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL, type.identifier as CFString, 1, nil)
        else { throw ExportError.unsupportedFormat }
        CGImageDestinationAddImage(dest, cg, [
            kCGImageDestinationLossyCompressionQuality: quality,
        ] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { throw ExportError.writeFailed }
    }
}
