import SwiftUI

struct LargeFilesView: View {
    @State private var model = LargeFilesModel()
    @State private var tab: Tab = .large
    @State private var sortOrder: SortOrder = .oldestFirst

    enum Tab: String, CaseIterable {
        case large = "大文件"
        case old = "旧文件"
    }

    enum SortOrder: String, CaseIterable {
        case oldestFirst = "时间：从旧到新"
        case newestFirst = "时间：从新到旧"
    }

    private var currentList: [ScannedFile] {
        switch tab {
        case .large:
            return model.large
        case .old:
            let ascending = model.old.sorted {
                ($0.modifiedAt ?? .distantPast) < ($1.modifiedAt ?? .distantPast)
            }
            return sortOrder == .oldestFirst ? ascending : Array(ascending.reversed())
        }
    }

    private var currentSelectedCount: Int {
        currentList.filter { model.selected.contains($0.id) }.count
    }

    private var currentSelectedSize: Int64 {
        currentList.filter { model.selected.contains($0.id) }.reduce(0) { $0 + $1.size }
    }

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

                    Picker("未修改超过", selection: $model.olderThanDays) {
                        ForEach([30, 60, 90, 180, 365, 730], id: \.self) { days in
                            Text("\(days) 天").tag(days)
                        }
                    }
                    .pickerStyle(.menu)

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
                selectionBar
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

    /// 当前列表上方的批量操作栏：全选 / 反选，旧文件页额外提供时间排序。
    private var selectionBar: some View {
        HStack(spacing: 12) {
            Button("全选") {
                model.selected = model.selected.union(currentList.map(\.id))
            }
            Button("反选") {
                var next = model.selected
                for id in currentList.map(\.id) {
                    if next.contains(id) {
                        next.remove(id)
                    } else {
                        next.insert(id)
                    }
                }
                model.selected = next
            }
            Spacer()
            if tab == .old {
                Picker("排序", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 190)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
