import SwiftUI

struct LayerPanelView: View {
    private typealias DS = GlyphDesignSystem

    @Environment(CanvasViewModel.self) private var vm

    var body: some View {
        NavigationStack {
            Group {
                if vm.layers.isEmpty {
                    emptyState
                } else {
                    layerList
                }
            }
            .navigationTitle("Layers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .background(DS.Color.surface.ignoresSafeArea())
        }
    }

    private var layerList: some View {
        List {
            ForEach(vm.sortedLayers.reversed(), id: \.id) { layer in
                LayerRowView(
                    layer: layer,
                    isSelected: vm.selectedLayerID == layer.id || vm.multiSelectedIDs.contains(layer.id)
                ) {
                    vm.selectLayer(id: layer.id)
                }
                .listRowBackground(
                    (vm.selectedLayerID == layer.id || vm.multiSelectedIDs.contains(layer.id))
                        ? DS.Color.accent.opacity(0.12) : DS.Color.surface
                )
                .listRowInsets(EdgeInsets(top: DS.Spacing.xs, leading: DS.Spacing.md, bottom: DS.Spacing.xs, trailing: DS.Spacing.md))
            }
            .onMove { source, destination in
                let totalCount = vm.layers.count
                let mirroredSource = IndexSet(source.map { totalCount - 1 - $0 })
                let mirroredDest = totalCount - destination
                vm.moveLayer(from: mirroredSource, to: mirroredDest)
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
    }

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 40))
                .foregroundStyle(DS.Color.textTertiary)
            Text("No layers yet")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if vm.isMultiSelectActive {
                Button("Delete Selected", role: .destructive) {
                    vm.removeSelectedLayers()
                }
                .foregroundStyle(DS.Color.error)
            }
        }
    }
}

// MARK: - LayerRowView

private struct LayerRowView: View {
    private typealias DS = GlyphDesignSystem

    var layer: any Layer
    var isSelected: Bool
    var onTap: () -> Void

    @Environment(CanvasViewModel.self) private var vm
    @Environment(HapticsService.self) private var haptics

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            // Thumbnail
            RoundedRectangle(cornerRadius: DS.Radius.sm)
                .fill(DS.Color.surfaceAlt)
                .frame(width: 36, height: 36)
                .overlay {
                    if let imageLayer = layer as? ImageLayer {
                        Image(uiImage: imageLayer.image)
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
                    } else if let textLayer = layer as? TextLayer {
                        Text(String(textLayer.text.prefix(2)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)
                    }
                }

            Text(layer.name)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Color.textPrimary)
                .lineLimit(1)

            Spacer()

            Button { vm.toggleLock(id: layer.id); haptics.lockToggle() } label: {
                Image(systemName: layer.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 16))
                    .foregroundStyle(layer.isLocked ? DS.Color.accent : DS.Color.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(layer.isLocked ? "Unlock layer" : "Lock layer")

            Button { vm.toggleVisibility(id: layer.id) } label: {
                Image(systemName: layer.isVisible ? "eye" : "eye.slash")
                    .font(.system(size: 16))
                    .foregroundStyle(layer.isVisible ? DS.Color.textSecondary : DS.Color.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(layer.isVisible ? "Hide layer" : "Show layer")
        }
        .padding(.vertical, DS.Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}
