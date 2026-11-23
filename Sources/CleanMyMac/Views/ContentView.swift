import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard, junk, large, uninstaller, duplicates

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "概览"
        case .junk: "系统垃圾"
        case .large: "大文件与旧文件"
        case .uninstaller: "卸载器"
        case .duplicates: "重复文件"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "gauge"
        case .junk: "trash"
        case .large: "doc.text"
        case .uninstaller: "trash.slash"
        case .duplicates: "doc.on.doc"
        }
    }
}

struct ContentView: View {
    @State private var selection: SidebarItem? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.title, systemImage: item.icon)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 230)
        } detail: {
            switch selection ?? .dashboard {
            case .dashboard: DashboardView()
            case .junk: SystemJunkView()
            case .large: LargeFilesView()
            case .uninstaller: UninstallerView()
            case .duplicates: DuplicatesView()
            }
        }
        .frame(minWidth: 900, minHeight: 560)
    }
}
