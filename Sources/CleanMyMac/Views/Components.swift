import SwiftUI

/// Shared building blocks for the module screens.

struct ModuleHeader: View {
    let title: String
    let subtitle: String
    let isScanning: Bool
    let scanAction: () -> Void
    var scanTitle = "扫描"

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title2.bold())
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if isScanning {
                ProgressView().controlSize(.small)
            } else {
                Button(scanTitle, action: scanAction).buttonStyle(.borderedProminent)
            }
        }
    }
}

struct SelectableFileRow: View {
    let file: ScannedFile
    @Binding var selected: Set<UUID>

    private var isOn: Binding<Bool> {
        Binding(
            get: { selected.contains(file.id) },
            set: { on in
                if on { selected.insert(file.id) } else { selected.remove(file.id) }
            }
        )
    }

    var body: some View {
        HStack(spacing: 8) {
            Toggle("", isOn: isOn).labelsHidden().toggleStyle(.checkbox)
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name).lineLimit(1)
                Text(file.detail ?? file.url.path)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Text(FileUtils.formatBytes(file.size)).monospacedDigit().foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct CleanBar: View {
    let selectedCount: Int
    let selectedSize: Int64
    let cleanTitle: String
    let action: () -> Void

    var body: some View {
        HStack {
            Text(selectedCount > 0 ? "已选 \(selectedCount) 项 · \(FileUtils.formatBytes(selectedSize))" : "未选择任何项")
                .foregroundStyle(.secondary)
            Spacer()
            Button(cleanTitle, action: action)
                .buttonStyle(.borderedProminent)
                .disabled(selectedCount == 0)
        }
        .padding()
        .background(.bar)
    }
}

struct EmptyState: View {
    let symbol: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 40)).foregroundStyle(.tertiary)
            Text(message).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
