import SwiftUI

/// The main (and only) screen — dark canvas with text overlays and controls.
struct CanvasView: View {
    @Environment(CanvasViewModel.self) private var canvas
    @Environment(FontLibraryViewModel.self) private var fontLibrary

    @State private var showStyleControls = false
    @State private var showFontPicker = false
    @State private var showExportSheet = false
    @State private var editingText = ""

    var body: some View {
        ZStack {
            // Background — tap to deselect
            GlyphTheme.background
                .ignoresSafeArea()
                .onTapGesture {
                    canvas.deselectAll()
                    showStyleControls = false
                }

            // Overlays
            ForEach(canvas.overlays) { overlay in
                TextOverlayView(
                    overlay: overlay,
                    isSelected: canvas.selectedOverlayID == overlay.id
                )
            }

            // Top toolbar
            VStack {
                HStack {
                    Button {
                        let font = fontLibrary.fonts.first?.familyName ?? "Playfair Display"
                        canvas.addOverlay(fontFamily: font)
                        editingText = "Hello"
                        showStyleControls = true
                    } label: {
                        Label("Add Text", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(GlyphTheme.accent)
                    }

                    Spacer()

                    if !canvas.overlays.isEmpty {
                        Button {
                            showExportSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(GlyphTheme.accent)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                // Bottom controls for selected overlay
                if canvas.selectedOverlay != nil {
                    HStack(spacing: 16) {
                        Button {
                            showFontPicker = true
                        } label: {
                            Image(systemName: "textformat")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(GlyphTheme.surface, in: Circle())
                        }

                        Button {
                            showStyleControls = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(GlyphTheme.surface, in: Circle())
                        }

                        Button {
                            canvas.removeSelected()
                            showStyleControls = false
                        } label: {
                            Image(systemName: "trash")
                                .font(.title3)
                                .foregroundStyle(GlyphTheme.error)
                                .frame(width: 44, height: 44)
                                .background(GlyphTheme.surface, in: Circle())
                        }
                    }
                    .padding(.bottom, 20)
                }
            }

            // Inline text editor when editing
            if canvas.isEditing, let overlay = canvas.selectedOverlay {
                VStack {
                    Spacer()
                    TextField("Type something", text: Binding(
                        get: { overlay.text },
                        set: { canvas.updateText($0) }
                    ))
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding()
                    .background(GlyphTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
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
                    .presentationBackground(GlyphTheme.surface)
            }
        }
        .sheet(isPresented: $showFontPicker) {
            FontPickerSheet()
                .environment(canvas)
                .environment(fontLibrary)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(GlyphTheme.surface)
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet()
                .environment(canvas)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
                .presentationBackground(GlyphTheme.surface)
        }
    }
}
