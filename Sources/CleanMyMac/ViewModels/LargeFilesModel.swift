import Foundation
import Observation

@Observable
final class LargeFilesModel {
    var large: [ScannedFile] = []
    var old: [ScannedFile] = []
    var selected: Set<UUID> = []
    var isScanning = false
    var lastMessage = ""
    var minSizeMB = 100
    var olderThanDays = 180
    var rootDescription = ""

    var selectedSize: Int64 {
        (large + old).filter { selected.contains($0.id) }.reduce(0) { $0 + $1.size }
    }

    func scan() async {
        isScanning = true
        defer { isScanning = false }
        let roots = LargeFilesScanner.defaultRoots()
        let minSize = Int64(minSizeMB) * 1024 * 1024
        let cutoff = Calendar.current.date(byAdding: .day, value: -olderThanDays, to: Date()) ?? Date.distantFuture
        rootDescription = roots.map(\.lastPathComponent).joined(separator: ", ")

        let found = await Task.detached(priority: .userInitiated) { () -> ([ScannedFile], [ScannedFile]) in
            var large: [ScannedFile] = []
            var old: [ScannedFile] = []
            for root in roots {
                let r = LargeFilesScanner.scan(root: root, minSize: minSize, olderThan: cutoff)
                large += r.large
                old += r.old
            }
            large.sort { $0.size > $1.size }
            old.sort { ($0.modifiedAt ?? .distantPast) < ($1.modifiedAt ?? .distantPast) }
            return (large, old)
        }.value

        large = found.0
        old = found.1
        lastMessage = "大文件 \(large.count) 项 · 旧文件 \(old.count) 项"
    }

    func clean() async {
        let urls = (large + old).filter { selected.contains($0.id) }.map(\.url)
        let outcome = await Task.detached(priority: .userInitiated) { FileUtils.delete(urls) }.value
        large.removeAll { selected.contains($0.id) }
        old.removeAll { selected.contains($0.id) }
        selected.removeAll()
        lastMessage = "已删除 \(outcome.deleted) 项" + (outcome.failed.isEmpty ? "" : "，\(outcome.failed.count) 项失败")
    }
}
