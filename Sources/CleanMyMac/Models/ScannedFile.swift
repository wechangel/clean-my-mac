import Foundation

/// A single file or directory surfaced by a scanner, ready to be shown and (optionally) cleaned.
struct ScannedFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int64
    let modifiedAt: Date?
    let category: String?
    let detail: String?

    init(url: URL, name: String? = nil, size: Int64, modifiedAt: Date? = nil, category: String? = nil, detail: String? = nil) {
        self.url = url
        self.name = name ?? url.lastPathComponent
        self.size = size
        self.modifiedAt = modifiedAt
        self.category = category
        self.detail = detail
    }
}
