import Foundation

/// Headless self-check run with `swift run CleanMyMac --smoke-test`.
enum SmokeTest {
    static func run() {
        print("=== CleanMyMac smoke test ===")

        let junk = SystemJunkScanner.scan()
        print("System junk: \(junk.count) items, \(FileUtils.formatBytes(junk.reduce(0) { $0 + $1.size }))")
        for item in junk.prefix(5) {
            print("  [\(item.category ?? "?")] \(item.name)  \(FileUtils.formatBytes(item.size))")
        }

        let apps = UninstallerScanner.scan()
        print("Installed apps: \(apps.count)")
        for app in apps.prefix(5) {
            print("  \(app.name)  bundle=\(app.bundleID ?? "nil")  total=\(FileUtils.formatBytes(app.totalSize))  related=\(app.relatedFiles.count)")
        }

        // Deterministic duplicate check in a scratch directory.
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("CleanMyMacSmoke")
        try? FileManager.default.removeItem(at: tmp)
        try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let payload = Data(repeating: 0x41, count: 4096)
        try? payload.write(to: tmp.appendingPathComponent("dup-a.bin"))
        try? payload.write(to: tmp.appendingPathComponent("dup-b.bin"))
        try? Data(repeating: 0x42, count: 1024).write(to: tmp.appendingPathComponent("unique.bin"))
        let dups = DuplicateScanner.scan(root: tmp)
        print("Duplicate groups (scratch dir): \(dups.count)  (expect 1)")
        for group in dups {
            print("  group size=\(FileUtils.formatBytes(group.size)) files=\(group.files.count)")
        }
        try? FileManager.default.removeItem(at: tmp)

        let roots = LargeFilesScanner.defaultRoots()
        print("Large/old file roots: \(roots.map(\.lastPathComponent).joined(separator: ", "))")

        if let volume = FileUtils.volumeInfo() {
            print("Volume: total=\(FileUtils.formatBytes(volume.total)) available=\(FileUtils.formatBytes(volume.available))")
        }

        print("=== smoke test done ===")
    }
}
