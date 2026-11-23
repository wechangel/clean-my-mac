import Foundation
import Observation

@Observable
final class DuplicateModel {
    var groups: [DuplicateGroup] = []
    var selected: Set<UUID> = []
    var isScanning = false
    var lastMessage = ""

    var selectedSize: Int64 {
        groups.reduce(0) { groupTotal, group in
            groupTotal + group.files.filter { selected.contains($0.id) }.reduce(0) { $0 + $1.size }
        }
    }

    var selectedCount: Int {
        groups.reduce(0) { $0 + $1.files.filter { selected.contains($0.id) }.count }
    }

    func scan(root: URL) async {
        isScanning = true
        defer { isScanning = false }
        let found = await Task.detached(priority: .userInitiated) { DuplicateScanner.scan(root: root) }.value
        groups = found
        var selection = Set<UUID>()
        for group in found {
            for file in group.files.dropFirst() { selection.insert(file.id) }
        }
        selected = selection
        lastMessage = "发现 \(found.count) 组重复文件"
    }

    func clean() async {
        let urls = groups.flatMap { $0.files }.filter { selected.contains($0.id) }.map(\.url)
        let outcome = await Task.detached(priority: .userInitiated) { FileUtils.delete(urls) }.value
        for index in groups.indices {
            groups[index].files.removeAll { selected.contains($0.id) }
        }
        groups.removeAll { $0.files.count < 2 }
        selected.removeAll()
        lastMessage = "已删除 \(outcome.deleted) 项" + (outcome.failed.isEmpty ? "" : "，\(outcome.failed.count) 项失败")
    }
}
