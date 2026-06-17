import CoreImage
import Foundation

/// A parsed 3D `.cube` LUT, ready to hand to Core Image.
///
/// `.cube` files list entries with **red varying fastest** (red index increments
/// first, then green, then blue). `CIColorCube` indexes its data the same way —
/// `data[(b*N*N + g*N + r)*4]` — so we can append entries in file order with no
/// reshuffling. The identity-LUT test guards this assumption.
public struct CubeLUT: Equatable {
    public let dimension: Int
    public let data: Data
    public let sourceURL: URL?

    public init(dimension: Int, data: Data, sourceURL: URL? = nil) {
        self.dimension = dimension
        self.data = data
        self.sourceURL = sourceURL
    }

    public enum ParseError: LocalizedError, Equatable {
        case unreadable
        case missingSize
        case oneDimensionalUnsupported
        case wrongEntryCount(expected: Int, got: Int)

        public var errorDescription: String? {
            switch self {
            case .unreadable:
                return "Couldn't read the file as text."
            case .missingSize:
                return "No LUT_3D_SIZE found. Only 3D .cube files are supported."
            case .oneDimensionalUnsupported:
                return "This is a 1D LUT. Only 3D .cube files are supported."
            case let .wrongEntryCount(expected, got):
                return "Expected \(expected) entries but found \(got)."
            }
        }
    }

    public static func load(from url: URL) throws -> CubeLUT {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw ParseError.unreadable
        }
        return try parse(text, url: url)
    }

    public static func parse(_ text: String, url: URL? = nil) throws -> CubeLUT {
        var size: Int?
        var floats: [Float] = []

        for rawLine in text.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }

            let parts = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard let keyword = parts.first else { continue }

            switch keyword {
            case "LUT_3D_SIZE":
                if parts.count >= 2 { size = Int(parts[1]) }
            case "LUT_1D_SIZE":
                throw ParseError.oneDimensionalUnsupported
            case "TITLE", "DOMAIN_MIN", "DOMAIN_MAX", "LUT_3D_INPUT_RANGE", "LUT_1D_INPUT_RANGE":
                continue
            default:
                guard parts.count >= 3,
                      let r = Float(parts[0]), let g = Float(parts[1]), let b = Float(parts[2])
                else { continue }
                floats.append(r); floats.append(g); floats.append(b); floats.append(1)
            }
        }

        guard let n = size else { throw ParseError.missingSize }
        let expected = n * n * n
        guard floats.count == expected * 4 else {
            throw ParseError.wrongEntryCount(expected: expected, got: floats.count / 4)
        }

        let data = floats.withUnsafeBufferPointer { Data(buffer: $0) }
        return CubeLUT(dimension: n, data: data, sourceURL: url)
    }

    /// A fresh filter instance. Filters are stateful, so each render builds its own.
    public func makeFilter() -> CIFilter? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        return CIFilter(name: "CIColorCubeWithColorSpace", parameters: [
            "inputCubeDimension": dimension,
            "inputCubeData": data,
            "inputColorSpace": space,
        ])
    }
}
