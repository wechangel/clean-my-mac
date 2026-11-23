import Foundation

struct RelatedFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let size: Int64
}

struct InstalledApp: Identifiable, Hashable {
    let id = UUID()
    let appURL: URL
    let name: String
    let bundleID: String?
    let size: Int64
    let relatedFiles: [RelatedFile]

    var relatedSize: Int64 { relatedFiles.reduce(0) { $0 + $1.size } }
    var totalSize: Int64 { size + relatedSize }
}

enum UninstallerScanner {
    static func appDirectories() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/Applications/Utilities"),
            home.appendingPathComponent("Applications"),
        ]
    }

    static func scan() -> [InstalledApp] {
        var apps: [InstalledApp] = []
        var seen = Set<String>()
        for directory in appDirectories() {
            guard FileUtils.exists(directory) else { continue }
            let contents = (try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )) ?? []
            for appURL in contents where appURL.pathExtension == "app" {
                guard seen.insert(appURL.standardizedFileURL.path).inserted else { continue }
                if let app = makeApp(appURL) { apps.append(app) }
            }
        }
        return apps.sorted { $0.totalSize > $1.totalSize }
    }

    private static func makeApp(_ appURL: URL) -> InstalledApp? {
        let bundle = Bundle(url: appURL)
        let bundleID = bundle?.bundleIdentifier
        let name = (bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? appURL.deletingPathExtension().lastPathComponent
        let size = FileUtils.directorySize(appURL, skipPackages: false)
        let related = relatedFiles(for: name, bundleID: bundleID)
        return InstalledApp(appURL: appURL, name: name, bundleID: bundleID, size: size, relatedFiles: related)
    }

    private static func relatedFiles(for name: String, bundleID: String?) -> [RelatedFile] {
        let lib = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library")
        var candidates: [URL] = []
        if let bid = bundleID, !bid.isEmpty {
            candidates += [
                lib.appendingPathComponent("Caches/\(bid)"),
                lib.appendingPathComponent("Preferences/\(bid).plist"),
                lib.appendingPathComponent("Containers/\(bid)"),
                lib.appendingPathComponent("Logs/\(bid)"),
                lib.appendingPathComponent("WebKit/\(bid)"),
                lib.appendingPathComponent("HTTPStorages/\(bid)"),
                lib.appendingPathComponent("Saved Application State/\(bid).savedState"),
            ]
        }
        candidates += [
            lib.appendingPathComponent("Application Support/\(name)"),
            lib.appendingPathComponent("Preferences/\(name).plist"),
            lib.appendingPathComponent("Saved Application State/\(name).savedState"),
        ]

        var result: [RelatedFile] = []
        for candidate in candidates {
            guard FileUtils.exists(candidate) else { continue }
            let size = FileUtils.isDirectory(candidate) ? FileUtils.directorySize(candidate) : FileUtils.fileSize(candidate)
            result.append(RelatedFile(url: candidate, size: size))
        }
        return result
    }
}
