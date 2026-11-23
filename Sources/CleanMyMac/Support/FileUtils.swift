import Foundation

enum FileUtils {
    static let fm = FileManager.default

    /// Human-readable byte count, e.g. "1.2 GB".
    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
    }

    static func fileSize(_ url: URL) -> Int64 {
        Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
    }

    /// Recursive size. `skipPackages` avoids descending into bundles (`.app`, `.framework`, …).
    static func directorySize(_ url: URL, skipPackages: Bool = true) -> Int64 {
        guard isDirectory(url) else { return fileSize(url) }
        var options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
        if skipPackages { options.insert(.skipsPackageDescendants) }
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: options,
            errorHandler: { _, _ in true }
        ) else { return 0 }
        var total: Int64 = 0
        for case let child as URL in enumerator {
            if let values = try? child.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
               values.isRegularFile == true {
                total += Int64(values.fileSize ?? 0)
            }
        }
        return total
    }

    static func modificationDate(_ url: URL) -> Date? {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }

    static func exists(_ url: URL) -> Bool {
        fm.fileExists(atPath: url.path)
    }

    /// Move items to the Trash, or permanently delete items that are already inside the Trash (e.g. "empty trash").
    static func delete(_ urls: [URL]) -> (deleted: Int, failed: [URL]) {
        let trashPath = fm.homeDirectoryForCurrentUser.appendingPathComponent(".Trash").standardizedFileURL.path
        var deleted = 0
        var failed: [URL] = []
        for url in urls {
            let standardized = url.standardizedFileURL
            do {
                if standardized.path == trashPath || standardized.path.hasPrefix(trashPath + "/") {
                    try fm.removeItem(at: standardized)
                } else {
                    _ = try fm.trashItem(at: standardized, resultingItemURL: nil)
                }
                deleted += 1
            } catch {
                failed.append(url)
            }
        }
        return (deleted, failed)
    }

    /// Total / available capacity for the startup volume.
    static func volumeInfo() -> (total: Int64, available: Int64)? {
        let url = URL(fileURLWithPath: "/")
        guard let values = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]),
              let total = values.volumeTotalCapacity,
              let available = values.volumeAvailableCapacityForImportantUsage else { return nil }
        return (Int64(total), Int64(available))
    }
}
