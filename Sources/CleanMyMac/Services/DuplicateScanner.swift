import Foundation
import CryptoKit

struct DuplicateGroup: Identifiable, Hashable {
    let id = UUID()
    let size: Int64
    var files: [ScannedFile]
}

enum DuplicateScanner {
    /// Scans a directory, grouping files with identical content (same size + same SHA-256).
    static func scan(root: URL) -> [DuplicateGroup] {
        var filesBySize: [Int64: [URL]] = [:]
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return [] }

        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  values.isRegularFile == true else { continue }
            let size = Int64(values.fileSize ?? 0)
            guard size > 0 else { continue }
            filesBySize[size, default: []].append(url)
        }

        var groups: [DuplicateGroup] = []
        for (size, urls) in filesBySize where urls.count > 1 {
            var byHash: [String: [URL]] = [:]
            for url in urls {
                guard let hash = try? sha256(of: url) else { continue }
                byHash[hash, default: []].append(url)
            }
            for (_, dups) in byHash where dups.count > 1 {
                groups.append(DuplicateGroup(
                    size: size,
                    files: dups.map { ScannedFile(url: $0, size: size) }
                ))
            }
        }
        return groups.sorted { $0.size > $1.size }
    }

    private static func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while true {
            guard let data = try handle.read(upToCount: 1 << 20), !data.isEmpty else { break }
            hasher.update(data: data)
        }
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
