import SwiftUI

struct CanvasView: View {
    private typealias DS = GlyphDesignSystem

    @Environment(CanvasViewModel.self) private var vm
    @Environment(FontLibraryViewModel.self) private var fontLibrary

    @State private var showStyleControls = false
    @State private var showFontPicker = false
    @State private var showExportSheet = false
    @State private var showLayerPanel = false
    @State private var showBackgroundPicker = false
    @State private var showImageOverlayPicker = false

    var body: some View {
        VStack(spacing: 0) {
            topToolbar
            canvas
            bottomControls
        }
        .background(DS.Color.surface.ignoresSafeArea())
        .sheet(isPresented: $showBackgroundPicker) {
            ImagePickerView { image in
                vm.setBackground(image)
                showBackgroundPicker = false
            }
        }
        .sheet(isPresented: $showImageOverlayPicker) {
            ImagePickerView { image in
                vm.addImageLayer(image)
                showImageOverlayPicker = false
            }
        }
        .sheet(isPresented: $showLayerPanel) {
            LayerPanelView()
                .environment(vm)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(DS.Color.surface)
        }
        .sheet(isPresented: $showStyleControls) {
            if vm.selectedTextLayer != nil {
                StyleControlsView()
                    .environment(vm)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(DS.Color.surface)
            }
        }
        .sheet(isPresented: $showFontPicker) {
            FontPickerSheet()
                .environment(vm)
                .environment(fontLibrary)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(DS.Color.surface)
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet()
                .environment(vm)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
                .presentationBackground(DS.Color.surface)
        }
    }

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        HStack(spacing: DS.Spacing.md) {
            Button { showBackgroundPicker = true } label: {
                Text("BG")
                    .font(DS.Typography.label)
                    .tracking(1.5)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Button { showImageOverlayPicker = true } label: {
                Image(systemName: "photo.on.rectangle")
                    .font(.body)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Spacer()

            Button {
                let font = fontLibrary.fonts.first?.familyName ?? "Playfair Display"
                vm.addTextLayer(fontFamily: font)
                showStyleControls = true
            } label: {
                Text("ADD TEXT")
                    .font(DS.Typography.label)
                    .tracking(1.5)
                    .foregroundStyle(DS.Color.accent)
            }

            Button { showLayerPanel = true } label: {
                Image(systemName: "square.3.layers.3d")
                    .font(.body)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            if !vm.layers.isEmpty {
                Button { showExportSheet = true } label: {
                    Text("EXPORT")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.accent)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.vertical, DS.Spacing.sm)
    }

    // MARK: - Canvas

    private var canvas: some View {
        ZStack {
            // Background
            if let background = vm.background {
                BackgroundImageView(
                    background: background,
                    onScaleChange: { vm.updateBackgroundScale($0) },
                    onOffsetChange: { vm.updateBackgroundOffset($0) }
                )
            } else {
                DS.Color.canvas
            }

            // Layers in z-order
            ForEach(vm.sortedLayers, id: \.id) { layer in
                if let imageLayer = layer as? ImageLayer {
                    ImageOverlayView(
                        layer: imageLayer,
                        isSelected: vm.selectedLayerID == layer.id,
                        onSelect: { vm.selectLayer(id: layer.id) },
                        onLongPress: { vm.enterMultiSelect(startingWith: layer.id) },
                        onPositionChange: { vm.updatePosition(id: layer.id, position: $0) },
                        onScaleChange: { vm.updateScale(id: layer.id, scale: $0) },
                        onRotationChange: { vm.updateRotation(id: layer.id, rotation: $0) }
                    )
                } else if let textLayer = layer as? TextLayer {
                    TextOverlayView(
                        layer: textLayer,
                        isSelected: vm.selectedLayerID == layer.id,
                        onSelect: { vm.selectLayer(id: layer.id) },
                        onEdit: {
                            vm.selectLayer(id: layer.id)
                            vm.isEditing = true
                        },
                        onPositionChange: { vm.updatePosition(id: layer.id, position: $0) },
                        onScaleChange: { vm.updateScale(id: layer.id, scale: $0) },
                        onRotationChange: { vm.updateRotation(id: layer.id, rotation: $0) }
                    )
                }
            }

            // Inline text editor
            if vm.isEditing, let textLayer = vm.selectedTextLayer {
                VStack {
                    Spacer()
                    TextField("Type something", text: Binding(
                        get: { textLayer.text },
                        set: { vm.updateText(id: textLayer.id, text: $0) }
                    ))
                    .font(DS.Typography.title)
                    .foregroundStyle(DS.Color.textPrimary)
                    .padding(DS.Spacing.lg)
                    .background(DS.Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.bottom, 80)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onTapGesture {
            vm.deselectAll()
            showStyleControls = false
        }
        .animation(.easeInOut(duration: 0.2), value: vm.selectedLayerID)
        .animation(.easeInOut(duration: 0.2), value: vm.isEditing)
    }

    // MARK: - Bottom Controls

    @ViewBuilder
    private var bottomControls: some View {
        if vm.selectedLayerID != nil {
            HStack(spacing: DS.Spacing.lg) {
                if vm.selectedTextLayer != nil {
                    controlButton(icon: "textformat") { showFontPicker = true }
                    controlButton(icon: "slider.horizontal.3") { showStyleControls = true }
                }
                controlButton(icon: "trash", tint: DS.Color.error) {
                    vm.removeSelectedLayers()
                    showStyleControls = false
                }
            }
            .padding(.vertical, DS.Spacing.lg)
        }
    }

    private func controlButton(
        icon: String,
        tint: SwiftUI.Color = DS.Color.textPrimary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(DS.Color.canvas, in: Circle())
                .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
        }
    }
}
