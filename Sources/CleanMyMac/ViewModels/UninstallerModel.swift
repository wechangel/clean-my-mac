import Foundation
import Observation

@Observable
final class UninstallerModel {
    var apps: [InstalledApp] = []
    var isScanning = false
    var lastMessage = ""

    var totalSize: Int64 { apps.reduce(0) { $0 + $1.totalSize } }

    func scan() async {
        isScanning = true
        defer { isScanning = false }
        let found = await Task.detached(priority: .userInitiated) { UninstallerScanner.scan() }.value
        apps = found
        lastMessage = "发现 \(found.count) 个应用，共 \(FileUtils.formatBytes(found.reduce(0) { $0 + $1.totalSize }))"
    }

    func uninstall(_ app: InstalledApp) async {
        var urls = app.relatedFiles.map(\.url)
        urls.append(app.appURL)
        let outcome = await Task.detached(priority: .userInitiated) { FileUtils.delete(urls) }.value
        apps.removeAll { $0.id == app.id }
        lastMessage = "已卸载 \(app.name)" + (outcome.failed.isEmpty ? "" : "，\(outcome.failed.count) 项失败")
    }
}
