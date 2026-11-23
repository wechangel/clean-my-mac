import Foundation

enum LargeFilesScanner {
    static func defaultRoots() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return ["Desktop", "Documents", "Downloads", "Movies", "Music", "Pictures"]
            .map { home.appendingPathComponent($0) }
            .filter { FileUtils.exists($0) }
    }

    struct ScanResult {
        var large: [ScannedFile] = []
        var old: [ScannedFile] = []
        var scannedCount = 0
        var totalSize: Int64 = 0
    }

    static func scan(root: URL, minSize: Int64, olderThan: Date) -> ScanResult {
        var result = ScanResult()
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return result }

        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]),
                  values.isRegularFile == true else { continue }
            let size = Int64(values.fileSize ?? 0)
            let modified = values.contentModificationDate
            result.scannedCount += 1
            result.totalSize += size
            if size >= minSize {
                result.large.append(ScannedFile(url: url, size: size, modifiedAt: modified, category: "大文件"))
            }
            if let modified, modified <= olderThan {
                result.old.append(ScannedFile(url: url, size: size, modifiedAt: modified, category: "旧文件"))
            }
        }
        result.large.sort { $0.size > $1.size }
        result.old.sort { ($0.modifiedAt ?? .distantPast) < ($1.modifiedAt ?? .distantPast) }
        return result
    }
}
