import SwiftUI

struct CanvasView: View {
    private typealias DS = GlyphDesignSystem

    @Environment(CanvasViewModel.self) private var vm
    @Environment(FontLibraryViewModel.self) private var fontLibrary
    @Environment(SettingsViewModel.self) private var settings
    @Environment(HapticsService.self) private var haptics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Sheet State Machine

    enum ActiveSheet: Identifiable {
        case backgroundPicker
        case imageOverlayPicker
        case layerPanel
        case styleControls
        case fontPicker
        case exportSheet
        case settings

        var id: Int { hashValue }
    }

    @State private var activeSheet: ActiveSheet?

    // MARK: - Toolbar Auto-Hide

    @State private var toolbarVisible = true
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            if toolbarVisible { topToolbar.transition(.move(edge: .top).combined(with: .opacity)) }
            canvas
            if toolbarVisible { bottomControls.transition(.move(edge: .bottom).combined(with: .opacity)) }
        }
        .background(DS.Color.surface.ignoresSafeArea())
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .backgroundPicker:
                ImagePickerView { image in
                    vm.setBackground(image)
                    activeSheet = nil
                }
            case .imageOverlayPicker:
                ImagePickerView { image in
                    vm.addImageLayer(image)
                    activeSheet = nil
                }
            case .layerPanel:
                LayerPanelView()
                    .environment(vm)
                    .environment(haptics)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(DS.Color.surface)
            case .styleControls:
                if vm.selectedTextLayer != nil {
                    StyleControlsView()
                        .environment(vm)
                        .environment(haptics)
                        .environment(settings)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                        .presentationBackground(DS.Color.surface)
                }
            case .fontPicker:
                FontPickerSheet()
                    .environment(vm)
                    .environment(fontLibrary)
                    .environment(haptics)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(DS.Color.surface)
            case .exportSheet:
                ExportSheet()
                    .environment(vm)
                    .environment(haptics)
                    .environment(settings)
                    .presentationDetents([.height(480)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(DS.Color.surface)
            case .settings:
                SettingsView()
                    .environment(settings)
            }
        }
        .focusable()
        .onKeyPress(.leftArrow)  { vm.nudgeSelected(dx: -1, dy:  0); return .handled }
        .onKeyPress(.rightArrow) { vm.nudgeSelected(dx:  1, dy:  0); return .handled }
        .onKeyPress(.upArrow)    { vm.nudgeSelected(dx:  0, dy: -1); return .handled }
        .onKeyPress(.downArrow)  { vm.nudgeSelected(dx:  0, dy:  1); return .handled }
        .onShake { vm.undo() }
    }

    // MARK: - Toolbar Auto-Hide

    private func resetHideTimer() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { toolbarVisible = false }
        }
    }

    private func showToolbar() {
        hideTask?.cancel()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { toolbarVisible = true }
    }

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        HStack(spacing: DS.Spacing.md) {
            Button { activeSheet = .backgroundPicker } label: {
                Text("BG")
                    .font(DS.Typography.label)
                    .tracking(1.5)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .accessibilityLabel("Set background image")

            Button { activeSheet = .imageOverlayPicker } label: {
                Image(systemName: "photo.on.rectangle")
                    .font(.body)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .accessibilityLabel("Add image layer")

            Spacer()

            // Undo / Redo
            Button { vm.undo(); haptics.selectionChanged() } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.body)
                    .foregroundStyle(vm.canUndo ? DS.Color.textPrimary : DS.Color.textTertiary)
            }
            .disabled(!vm.canUndo)
            .accessibilityLabel("Undo")

            Button { vm.redo(); haptics.selectionChanged() } label: {
                Image(systemName: "arrow.uturn.forward")
                    .font(.body)
                    .foregroundStyle(vm.canRedo ? DS.Color.textPrimary : DS.Color.textTertiary)
            }
            .disabled(!vm.canRedo)
            .accessibilityLabel("Redo")

            Button {
                let font = fontLibrary.fonts.first?.familyName ?? "Playfair Display"
                vm.addTextLayer(fontFamily: font)
                activeSheet = .styleControls
            } label: {
                Text("ADD TEXT")
                    .font(DS.Typography.label)
                    .tracking(1.5)
                    .foregroundStyle(DS.Color.accent)
            }
            .accessibilityLabel("Add text layer")

            Button { vm.showGuides.toggle() } label: {
                Image(systemName: vm.showGuides ? "grid.circle.fill" : "grid.circle")
                    .font(.body)
                    .foregroundStyle(vm.showGuides ? DS.Color.accent : DS.Color.textSecondary)
            }
            .accessibilityLabel(vm.showGuides ? "Hide alignment grid" : "Show alignment grid")

            Button { activeSheet = .layerPanel } label: {
                Image(systemName: "square.3.layers.3d")
                    .font(.body)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .accessibilityLabel("Open layer panel")

            Button { activeSheet = .settings } label: {
                Image(systemName: "gearshape")
                    .font(.body)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .accessibilityLabel("Open settings")

            if !vm.layers.isEmpty {
                Button { activeSheet = .exportSheet } label: {
                    Text("EXPORT")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.accent)
                }
                .accessibilityLabel("Export canvas")
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
                    canvasSize: vm.canvasSize,
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
                        onSelect: { vm.selectLayer(id: layer.id); haptics.selectionChanged(); resetHideTimer() },
                        onLongPress: { vm.enterMultiSelect(startingWith: layer.id); haptics.selectionChanged() },
                        onPositionChange: { vm.updatePosition(id: layer.id, position: $0) },
                        onScaleChange: { vm.updateScale(id: layer.id, scale: $0) },
                        onRotationChange: { vm.updateRotation(id: layer.id, rotation: $0) }
                    )
                } else if let textLayer = layer as? TextLayer {
                    TextOverlayView(
                        layer: textLayer,
                        isSelected: vm.selectedLayerID == layer.id,
                        onSelect: { vm.selectLayer(id: layer.id); haptics.selectionChanged(); resetHideTimer() },
                        onEdit: {
                            vm.selectLayer(id: layer.id)
                            vm.isEditing = true
                            haptics.selectionChanged()
                        },
                        onPositionChange: { vm.updatePosition(id: layer.id, position: $0) },
                        onScaleChange: { vm.updateScale(id: layer.id, scale: $0) },
                        onRotationChange: { vm.updateRotation(id: layer.id, rotation: $0) }
                    )
                }
            }

            // Guides overlay (grid + snap lines + custom guides)
            GeometryReader { geo in
                if vm.showGuides || !vm.activeGuides.isEmpty {
                    GuidesOverlayView(
                        canvasSize: geo.size,
                        showGrid: vm.showGuides,
                        gridType: settings.gridType,
                        gridColumns: settings.gridColumns,
                        showCenterGuides: settings.showCenterGuides,
                        activeGuides: vm.activeGuides,
                        customGuides: vm.customGuides,
                        snapThreshold: CGFloat(vm.snapThreshold),
                        onAddCustomGuide: { axis, pos in vm.addCustomGuide(axis: axis, position: pos) },
                        onMoveCustomGuide: { id, pos in vm.moveCustomGuide(id: id, to: pos) },
                        onRemoveCustomGuide: { id in vm.removeCustomGuide(id: id) }
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
                .transition(reduceMotion ? .opacity : .move(edge: .bottom))
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onTapGesture {
            vm.deselectAll()
            activeSheet = nil
            showToolbar()
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: vm.selectedLayerID)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: vm.isEditing)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: toolbarVisible)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { vm.canvasSize = geo.size }
                    .onChange(of: geo.size) { _, new in vm.canvasSize = new }
            }
        )
        .background(
            MultiTapDetector(
                onTwoFingerTap: { vm.undo(); haptics.selectionChanged() },
                onThreeFingerTap: { vm.redo(); haptics.selectionChanged() }
            )
        )
        .onChange(of: vm.activeGuides.count) { old, new in
            if new > old { haptics.snapToGuide() }
        }
        .onAppear {
            vm.showGuides = settings.showGridByDefault
            vm.snapThreshold = settings.snapThreshold
        }
    }

    // MARK: - Bottom Controls

    @ViewBuilder
    private var bottomControls: some View {
        if vm.selectedLayerID != nil {
            HStack(spacing: DS.Spacing.lg) {
                if vm.selectedTextLayer != nil {
                    controlButton(icon: "textformat", label: "Choose font") { activeSheet = .fontPicker }
                    controlButton(icon: "slider.horizontal.3", label: "Style controls") { activeSheet = .styleControls }
                }
                controlButton(icon: "arrow.counterclockwise", label: "Reset position") {
                    if let id = vm.selectedLayerID { vm.resetLayerTransform(id: id); haptics.selectionChanged() }
                }
                controlButton(icon: "lock", label: "Lock layer") {
                    if let id = vm.selectedLayerID { vm.toggleLock(id: id); haptics.selectionChanged() }
                }
                controlButton(icon: "trash", label: "Delete selected layer", tint: DS.Color.error) {
                    vm.removeSelectedLayers()
                    activeSheet = nil
                    haptics.delete()
                }
            }
            .padding(.vertical, DS.Spacing.lg)
        }
    }

    private func controlButton(
        icon: String,
        label: String,
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
        .accessibilityLabel(label)
    }
}

// MARK: - Shake-to-Undo

extension View {
    func onShake(_ action: @escaping () -> Void) -> some View {
        background(ShakeDetector(onShake: action))
    }
}

private struct ShakeDetector: UIViewRepresentable {
    let onShake: () -> Void

    func makeUIView(context: Context) -> DetectorView {
        let v = DetectorView(); v.onShake = onShake; return v
    }

    func updateUIView(_ uiView: DetectorView, context: Context) { uiView.onShake = onShake }

    final class DetectorView: UIView {
        var onShake: (() -> Void)?
        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            if motion == .motionShake { onShake?() }
        }
    }
}

// MARK: - Multi-Finger Tap Gestures (Undo / Redo)

private struct MultiTapDetector: UIViewRepresentable {
    let onTwoFingerTap: () -> Void
    let onThreeFingerTap: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let twoFinger = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTwoFinger)
        )
        twoFinger.numberOfTouchesRequired = 2
        twoFinger.cancelsTouchesInView = false
        twoFinger.delaysTouchesBegan = false

        let threeFinger = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleThreeFinger)
        )
        threeFinger.numberOfTouchesRequired = 3
        threeFinger.cancelsTouchesInView = false
        threeFinger.delaysTouchesBegan = false

        twoFinger.require(toFail: threeFinger)

        view.addGestureRecognizer(twoFinger)
        view.addGestureRecognizer(threeFinger)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onTwoFingerTap = onTwoFingerTap
        context.coordinator.onThreeFingerTap = onThreeFingerTap
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTwoFingerTap: onTwoFingerTap, onThreeFingerTap: onThreeFingerTap)
    }

    final class Coordinator {
        var onTwoFingerTap: () -> Void
        var onThreeFingerTap: () -> Void

        init(onTwoFingerTap: @escaping () -> Void, onThreeFingerTap: @escaping () -> Void) {
            self.onTwoFingerTap = onTwoFingerTap
            self.onThreeFingerTap = onThreeFingerTap
        }

        @objc func handleTwoFinger() { onTwoFingerTap() }
        @objc func handleThreeFinger() { onThreeFingerTap() }
    }
}
