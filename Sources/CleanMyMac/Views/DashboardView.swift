import SwiftUI

struct DashboardView: View {
    @State private var total: Int64 = 0
    @State private var available: Int64 = 0

    private var used: Int64 { max(0, total - available) }
    private var usedFraction: Double {
        total > 0 ? min(1.0, Double(used) / Double(total)) : 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("CleanMyMac").font(.largeTitle.bold())
                    Text("一款 macOS 系统清理工具原型，帮助你释放磁盘空间、卸载应用、查找大文件与重复文件。")
                        .foregroundStyle(.secondary)
                }

                storageCard
                featureCard
            }
            .padding(32)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .task {
            if let info = FileUtils.volumeInfo() {
                total = info.total
                available = info.available
            }
        }
    }

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("磁盘空间").font(.headline)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(.quaternary)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(usedFraction > 0.85 ? Color.red : Color.accentColor)
                        .frame(width: max(0, geo.size.width * usedFraction))
                }
            }
            .frame(height: 14)
            HStack {
                Text("已用 \(FileUtils.formatBytes(used))").foregroundStyle(.secondary)
                Spacer()
                Text("可用 \(FileUtils.formatBytes(available))").foregroundStyle(.secondary)
            }
            Text("总容量 \(FileUtils.formatBytes(total))").font(.caption).foregroundStyle(.tertiary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(.quaternary.opacity(0.5)))
    }

    private var featureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("功能模块").font(.headline)
            ForEach(FeatureRow.all, id: \.title) { feature in
                HStack(spacing: 10) {
                    Image(systemName: feature.icon).frame(width: 24).foregroundStyle(Color.accentColor)
                    Text(feature.title)
                    Spacer()
                    Text(feature.subtitle).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(.quaternary.opacity(0.5)))
    }
}

private struct FeatureRow {
    let icon: String
    let title: String
    let subtitle: String

    static let all: [FeatureRow] = [
        FeatureRow(icon: "trash", title: "系统垃圾", subtitle: "缓存 / 日志 / 临时文件"),
        FeatureRow(icon: "doc.text", title: "大文件与旧文件", subtitle: "按大小与时间"),
        FeatureRow(icon: "trash.slash", title: "卸载器", subtitle: "应用与残留"),
        FeatureRow(icon: "doc.on.doc", title: "重复文件", subtitle: "按内容哈希"),
    ]
}
