import SwiftUI
import AppKit

struct DuplicatesView: View {
    @State private var model = DuplicateModel()
    @State private var root: URL?

    var body: some View {
        VStack(spacing: 0) {
            ModuleHeader(
                title: "重复文件",
                subtitle: root.map { "扫描范围：\($0.path)" } ?? "尚未选择文件夹",
                isScanning: model.isScanning,
                scanAction: scan,
                scanTitle: "选择文件夹并扫描"
            )
            .padding()

            Divider()

            if model.groups.isEmpty && !model.isScanning {
                EmptyState(symbol: "doc.on.doc", message: "选择一个文件夹，扫描内容完全相同的重复文件")
            } else if !model.groups.isEmpty {
                List {
                    ForEach(model.groups) { group in
                        DuplicateGroupRow(group: group, selected: $model.selected)
                    }
                }
                .listStyle(.inset)
            } else {
                Spacer()
            }

            if !model.groups.isEmpty {
                Divider()
                CleanBar(
                    selectedCount: model.selectedCount,
                    selectedSize: model.selectedSize,
                    cleanTitle: "删除重复项",
                    action: { Task { await model.clean() } }
                )
            }
        }
        .navigationTitle("重复文件")
    }

    private func scan() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "扫描此文件夹"
        if panel.runModal() == .OK, let url = panel.url {
            root = url
            Task { await model.scan(root: url) }
        }
    }
}

private struct DuplicateGroupRow: View {
    let group: DuplicateGroup
    @Binding var selected: Set<UUID>

    var body: some View {
        DisclosureGroup {
            ForEach(group.files) { file in
                SelectableFileRow(file: file, selected: $selected)
            }
        } label: {
            HStack {
                Text("\(group.files.count) 个重复文件")
                Text("· 每份 \(FileUtils.formatBytes(group.size))")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("可释放 \(FileUtils.formatBytes(group.size * Int64(group.files.count - 1)))")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
