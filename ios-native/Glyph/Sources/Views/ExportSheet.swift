import SwiftUI
import UIKit

private typealias DS = GlyphDesignSystem

/// Bottom sheet with export actions: Instagram, Photos, Clipboard.
struct ExportSheet: View {
    @Environment(CanvasViewModel.self) private var canvas
    @Environment(HapticsService.self) private var haptics
    @Environment(SettingsViewModel.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isExporting = false
    @State private var toastMessage: String?
    @State private var showInstagramAlert = false
    @State private var cachedImage: UIImage?
    @State private var previewImage: UIImage?

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            Text("EXPORT")
                .font(DS.Typography.label)
                .tracking(1.5)
                .foregroundStyle(DS.Color.textTertiary)
                .padding(.top, DS.Spacing.xs)

            // MARK: - Preview
            if let preview = previewImage {
                Image(uiImage: preview)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                    .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .stroke(DS.Color.border, lineWidth: 0.5)
                    )
            } else {
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .fill(DS.Color.surfaceAlt)
                    .frame(maxHeight: 200)
                    .overlay { ProgressView() }
            }

            Button {
                Task { await exportToInstagram() }
            } label: {
                Label("Share to Instagram Stories", systemImage: "paperplane.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(DS.Color.accent, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            }
            .disabled(isExporting)
            .accessibilityLabel("Share to Instagram Stories")

            Button {
                Task { await saveToPhotos() }
            } label: {
                Label("Save to Photos", systemImage: "photo.on.rectangle")
                    .font(.body.weight(.medium))
                    .foregroundStyle(DS.Color.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(DS.Color.canvas, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .stroke(DS.Color.border, lineWidth: 1)
                    )
            }
            .disabled(isExporting)
            .accessibilityLabel("Save to photo library")

            Button {
                copyToClipboard()
            } label: {
                Label("Copy Image", systemImage: "doc.on.doc")
                    .font(.body.weight(.medium))
                    .foregroundStyle(DS.Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(DS.Color.canvas, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .stroke(DS.Color.border, lineWidth: 1)
                    )
            }
            .disabled(isExporting)
            .accessibilityLabel("Copy image to clipboard")
        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.bottom, DS.Spacing.xl)
        .overlay {
            if let message = toastMessage {
                VStack {
                    Text(message)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Color.textPrimary)
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.vertical, DS.Spacing.md)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                }
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { toastMessage = nil }
                    }
                }
            }
        }
        .task { renderPreview() }
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

    private func renderImage() -> UIImage? {
        if let cached = cachedImage { return cached }
        let canvasSize = CGSize(width: 1080, height: 1920)
        let image = ExportEngine.renderLayers(canvas.layers, background: canvas.background, canvasSize: canvasSize)
        cachedImage = image
        return image
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
            haptics.exportSuccess()
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
        haptics.exportSuccess()
        showToast("Saved to Photos!")
    }

    private func copyToClipboard() {
        let canvasSize = CGSize(width: 1080, height: 1920)

        if settings.exportFormat == "jpeg" {
            guard let data = ExportEngine.renderToData(
                canvas.layers,
                background: canvas.background,
                canvasSize: canvasSize,
                format: "jpeg",
                quality: settings.exportQuality
            ) else {
                showToast("Export failed")
                return
            }
            UIPasteboard.general.setData(data, forPasteboardType: "public.jpeg")
        } else {
            guard let image = renderImage() else {
                showToast("Export failed")
                return
            }
            UIPasteboard.general.image = image
        }

        haptics.exportSuccess()
        showToast("Copied!")
    }

    private func renderPreview() {
        let size = CGSize(width: 360, height: 640)
        previewImage = ExportEngine.renderLayers(canvas.layers, background: canvas.background, canvasSize: size)
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
