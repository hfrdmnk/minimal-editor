import Foundation

/// A named, self-contained look: every tweak plus the LUT it was made with.
/// The `.cube` itself is copied into the preset store, referenced here by filename.
public struct Preset: Codable, Equatable {
    public var name: String
    public var params: Params
    public var lutFileName: String?

    public init(name: String, params: Params, lutFileName: String? = nil) {
        self.name = name
        self.params = params
        self.lutFileName = lutFileName
    }
}
