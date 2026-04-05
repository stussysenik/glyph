import SwiftUI

/// Bottom sheet with export actions: Instagram, Photos, Clipboard.
struct ExportSheet: View {
    @Environment(CanvasViewModel.self) private var canvas
    @Environment(\.dismiss) private var dismiss

    @State private var isExporting = false
    @State private var toastMessage: String?
    @State private var showInstagramAlert = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Export")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.top, 4)

            // Instagram Stories — primary action
            Button {
                Task { await exportToInstagram() }
            } label: {
                Label("Share to Instagram Stories", systemImage: "paperplane.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(GlyphTheme.accent, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isExporting)

            // Save to Photos
            Button {
                Task { await saveToPhotos() }
            } label: {
                Label("Save to Photos", systemImage: "photo.on.rectangle")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(GlyphTheme.surfaceLight, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isExporting)

            // Copy to Clipboard
            Button {
                copyToClipboard()
            } label: {
                Label("Copy Image", systemImage: "doc.on.doc")
                    .font(.body.weight(.medium))
                    .foregroundStyle(GlyphTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(GlyphTheme.surfaceLight, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isExporting)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .overlay {
            if let message = toastMessage {
                VStack {
                    Text(message)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { toastMessage = nil }
                    }
                }
            }
        }
        .animation(.easeInOut, value: toastMessage)
        .alert("Instagram Not Installed", isPresented: $showInstagramAlert) {
            Button("Save to Photos Instead") {
                Task { await saveToPhotos() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Install Instagram to share stickers directly to Stories.")
        }
    }

    // MARK: - Export Actions

    private func renderImage() -> UIImage? {
        // Use a 1080x1920 canvas (Stories resolution)
        let canvasSize = CGSize(width: 1080, height: 1920)
        return ExportEngine.renderOverlays(canvas.overlays, canvasSize: canvasSize)
    }

    private func exportToInstagram() async {
        isExporting = true
        defer { isExporting = false }

        guard InstagramSharer.isAvailable else {
            showInstagramAlert = true
            return
        }

        guard let image = renderImage() else {
            showToast("Export failed")
            return
        }

        let success = await InstagramSharer.shareSticker(image)
        if success {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } else {
            showToast("Sharing failed")
        }
    }

    private func saveToPhotos() async {
        isExporting = true
        defer { isExporting = false }

        guard let image = renderImage() else {
            showToast("Export failed")
            return
        }

        _ = await InstagramSharer.saveToPhotos(image)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast("Saved to Photos!")
    }

    private func copyToClipboard() {
        guard let image = renderImage() else {
            showToast("Export failed")
            return
        }

        InstagramSharer.copyToClipboard(image)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast("Copied!")
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
    }
}
