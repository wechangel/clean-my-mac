import SwiftUI

struct SystemJunkView: View {
    @State private var model = SystemJunkModel()

    var body: some View {
        VStack(spacing: 0) {
            ModuleHeader(
                title: "系统垃圾",
                subtitle: "扫描用户与系统缓存、日志、临时文件和废纸篓",
                isScanning: model.isScanning,
                scanAction: { Task { await model.scan() } }
            )
            .padding()

            Divider()

            if model.results.isEmpty && !model.isScanning {
                EmptyState(symbol: "trash", message: "点击右上角“扫描”开始分析系统垃圾")
            } else if !model.results.isEmpty {
                List {
                    ForEach(model.results) { file in
                        SelectableFileRow(file: file, selected: $model.selected)
                    }
                }
                .listStyle(.inset)
            } else {
                Spacer()
            }

            if !model.results.isEmpty {
                Divider()
                CleanBar(
                    selectedCount: model.selected.count,
                    selectedSize: model.selectedSize,
                    cleanTitle: "清理",
                    action: { Task { await model.clean() } }
                )
            }
        }
        .navigationTitle("系统垃圾")
    }
}
