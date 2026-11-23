import SwiftUI

struct LargeFilesView: View {
    @State private var model = LargeFilesModel()
    @State private var tab: Tab = .large

    enum Tab: String, CaseIterable {
        case large = "大文件"
        case old = "旧文件"
    }

    private var currentList: [ScannedFile] { tab == .large ? model.large : model.old }
    private var currentSelectedCount: Int { currentList.filter { model.selected.contains($0.id) }.count }
    private var currentSelectedSize: Int64 { currentList.filter { model.selected.contains($0.id) }.reduce(0) { $0 + $1.size } }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                ModuleHeader(
                    title: "大文件与旧文件",
                    subtitle: "范围：\(model.rootDescription.isEmpty ? "尚未扫描" : model.rootDescription)",
                    isScanning: model.isScanning,
                    scanAction: { Task { await model.scan() } }
                )
                HStack(spacing: 16) {
                    Picker("最小文件大小", selection: $model.minSizeMB) {
                        ForEach([50, 100, 200, 500, 1024], id: \.self) { mb in
                            Text("\(mb) MB").tag(mb)
                        }
                    }
                    .frame(width: 160)

                    Stepper("超过 \(model.olderThanDays) 天未修改", value: $model.olderThanDays, in: 30...730, step: 30)

                    Picker("", selection: $tab) {
                        ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
            }
            .padding()

            Divider()

            if model.large.isEmpty && model.old.isEmpty && !model.isScanning {
                EmptyState(symbol: "doc.text", message: "点击“扫描”查找大文件与很久未使用的文件")
            } else if !currentList.isEmpty {
                List {
                    ForEach(currentList) { file in
                        SelectableFileRow(file: file, selected: $model.selected)
                    }
                }
                .listStyle(.inset)
            } else {
                Spacer()
            }

            if !currentList.isEmpty {
                Divider()
                CleanBar(
                    selectedCount: currentSelectedCount,
                    selectedSize: currentSelectedSize,
                    cleanTitle: "删除",
                    action: { Task { await model.clean() } }
                )
            }
        }
        .navigationTitle("大文件与旧文件")
    }
}
