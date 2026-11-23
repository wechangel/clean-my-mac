import Foundation

enum SystemJunkScanner {
    struct Location {
        let name: String
        let url: URL
    }

    static func locations() -> [Location] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            Location(name: "用户缓存", url: home.appendingPathComponent("Library/Caches")),
            Location(name: "系统缓存", url: URL(fileURLWithPath: "/Library/Caches")),
            Location(name: "系统日志", url: URL(fileURLWithPath: "/Library/Logs")),
            Location(name: "用户日志", url: home.appendingPathComponent("Library/Logs")),
            Location(name: "Xcode 派生数据", url: home.appendingPathComponent("Library/Developer/Xcode/DerivedData")),
            Location(name: "废纸篓", url: home.appendingPathComponent(".Trash")),
            Location(name: "临时文件", url: URL(fileURLWithPath: NSTemporaryDirectory())),
        ]
    }

    /// Enumerates the top-level contents of each junk location so the user can pick and choose.
    static func scan() -> [ScannedFile] {
        var results: [ScannedFile] = []
        for location in locations() {
            guard FileUtils.exists(location.url) else { continue }
            let children = (try? FileManager.default.contentsOfDirectory(
                at: location.url,
                includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )) ?? []
            for child in children {
                let size = FileUtils.isDirectory(child) ? FileUtils.directorySize(child) : FileUtils.fileSize(child)
                guard size > 0 else { continue }
                results.append(ScannedFile(
                    url: child,
                    size: size,
                    modifiedAt: FileUtils.modificationDate(child),
                    category: location.name
                ))
            }
        }
        return results.sorted { $0.size > $1.size }
    }
}
