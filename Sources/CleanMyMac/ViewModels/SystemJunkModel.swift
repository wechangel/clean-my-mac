import Foundation
import Observation

@Observable
final class SystemJunkModel {
    var results: [ScannedFile] = []
    var selected: Set<UUID> = []
    var isScanning = false
    var lastMessage = ""

    var totalSize: Int64 { results.reduce(0) { $0 + $1.size } }
    var selectedSize: Int64 { results.filter { selected.contains($0.id) }.reduce(0) { $0 + $1.size } }

    func scan() async {
        isScanning = true
        defer { isScanning = false }
        let found = await Task.detached(priority: .userInitiated) { SystemJunkScanner.scan() }.value
        results = found
        selected = Set(found.map(\.id))
        lastMessage = "发现 \(found.count) 项，共 \(FileUtils.formatBytes(found.reduce(0) { $0 + $1.size }))"
    }

    func clean() async {
        let urls = results.filter { selected.contains($0.id) }.map(\.url)
        let outcome = await Task.detached(priority: .userInitiated) { FileUtils.delete(urls) }.value
        results.removeAll { selected.contains($0.id) }
        selected.removeAll()
        lastMessage = "已清理 \(outcome.deleted) 项" + (outcome.failed.isEmpty ? "" : "，\(outcome.failed.count) 项失败")
    }
}
