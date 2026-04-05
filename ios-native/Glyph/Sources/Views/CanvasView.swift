import SwiftUI

private typealias DS = GlyphDesignSystem

/// The main (and only) screen — light canvas with text overlays and controls.
struct CanvasView: View {
    @Environment(CanvasViewModel.self) private var canvas
    @Environment(FontLibraryViewModel.self) private var fontLibrary

    @State private var showStyleControls = false
    @State private var showFontPicker = false
    @State private var showExportSheet = false

    var body: some View {
        ZStack {
            DS.Color.canvas
                .ignoresSafeArea()
                .onTapGesture {
                    canvas.deselectAll()
                    showStyleControls = false
                }

            ForEach(canvas.overlays) { overlay in
                TextOverlayView(
                    overlay: overlay,
                    isSelected: canvas.selectedOverlayID == overlay.id
                )
            }

            VStack {
                HStack {
                    Button {
                        let font = fontLibrary.fonts.first?.familyName ?? "Playfair Display"
                        canvas.addOverlay(fontFamily: font)
                        showStyleControls = true
                    } label: {
                        Text("ADD TEXT")
                            .font(DS.Typography.label)
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.accent)
                    }

                    Spacer()

                    if !canvas.overlays.isEmpty {
                        Button {
                            showExportSheet = true
                        } label: {
                            Text("EXPORT")
                                .font(DS.Typography.label)
                                .tracking(1.5)
                                .foregroundStyle(DS.Color.accent)
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.sm)

                Spacer()

                if canvas.selectedOverlay != nil {
                    HStack(spacing: DS.Spacing.lg) {
                        controlButton(icon: "textformat") {
                            showFontPicker = true
                        }

                        controlButton(icon: "slider.horizontal.3") {
                            showStyleControls = true
                        }

                        controlButton(icon: "trash", tint: DS.Color.error) {
                            canvas.removeSelected()
                            showStyleControls = false
                        }
                    }
                    .padding(.bottom, DS.Spacing.xl)
                }
            }

            if canvas.isEditing, let overlay = canvas.selectedOverlay {
                VStack {
                    Spacer()
                    TextField("Type something", text: Binding(
                        get: { overlay.text },
                        set: { canvas.updateText($0) }
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
        .animation(.easeInOut(duration: 0.2), value: canvas.selectedOverlayID)
        .animation(.easeInOut(duration: 0.2), value: canvas.isEditing)
        .sheet(isPresented: $showStyleControls) {
            if canvas.selectedOverlay != nil {
                StyleControlsView()
                    .environment(canvas)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(DS.Color.surface)
            }
        }
        .sheet(isPresented: $showFontPicker) {
            FontPickerSheet()
                .environment(canvas)
                .environment(fontLibrary)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(DS.Color.surface)
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet()
                .environment(canvas)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
                .presentationBackground(DS.Color.surface)
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
