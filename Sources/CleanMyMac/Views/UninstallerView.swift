import SwiftUI
import AppKit

struct UninstallerView: View {
    @State private var model = UninstallerModel()
    @State private var pendingApp: InstalledApp?

    var body: some View {
        VStack(spacing: 0) {
            ModuleHeader(
                title: "卸载器",
                subtitle: "扫描 /Applications 与 ~/Applications 中的应用及其残留文件",
                isScanning: model.isScanning,
                scanAction: { Task { await model.scan() } }
            )
            .padding()

            Divider()

            if model.apps.isEmpty && !model.isScanning {
                EmptyState(symbol: "trash.slash", message: "点击“扫描”列出已安装的应用")
            } else if !model.apps.isEmpty {
                List {
                    ForEach(model.apps) { app in
                        UninstallerRow(app: app, uninstall: { pendingApp = app })
                    }
                }
                .listStyle(.inset)
            } else {
                Spacer()
            }

            if !model.apps.isEmpty {
                Divider()
                HStack {
                    Text("共 \(model.apps.count) 个应用 · \(FileUtils.formatBytes(model.totalSize))")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("卸载器")
        .alert(
            Text("卸载 \(pendingApp?.name ?? "")？"),
            isPresented: Binding(get: { pendingApp != nil }, set: { if !$0 { pendingApp = nil } }),
            presenting: pendingApp
        ) { app in
            Button("卸载", role: .destructive) {
                Task { await model.uninstall(app) }
            }
            Button("取消", role: .cancel) {}
        } message: { app in
            Text("将把应用移入废纸篓，并删除 \(app.relatedFiles.count) 个关联文件（共 \(FileUtils.formatBytes(app.totalSize))）。")
        }
    }
}

private struct UninstallerRow: View {
    let app: InstalledApp
    let uninstall: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.appURL.path))
                .resizable().frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name).lineLimit(1)
                HStack(spacing: 6) {
                    Text(FileUtils.formatBytes(app.size))
                    if !app.relatedFiles.isEmpty {
                        Text("+ \(app.relatedFiles.count) 关联文件 \(FileUtils.formatBytes(app.relatedSize))")
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("卸载", action: uninstall)
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 2)
    }
}
