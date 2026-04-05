import SwiftUI

private typealias DS = GlyphDesignSystem

// MARK: - Color Tokens Preview

#Preview("Colors") {
    ScrollView {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            Text("COLOR TOKENS")
                .font(DS.Typography.label)
                .tracking(1.5)
                .foregroundStyle(DS.Color.textTertiary)
                .padding(.top, DS.Spacing.lg)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: DS.Spacing.md) {
                colorSwatch("canvas", DS.Color.canvas, bordered: true)
                colorSwatch("surface", DS.Color.surface)
                colorSwatch("surfaceAlt", DS.Color.surfaceAlt)
                colorSwatch("accent", DS.Color.accent)
                colorSwatch("textPrimary", DS.Color.textPrimary)
                colorSwatch("textSecondary", DS.Color.textSecondary)
                colorSwatch("textTertiary", DS.Color.textTertiary)
                colorSwatch("border", DS.Color.border)
                colorSwatch("error", DS.Color.error)
                colorSwatch("success", DS.Color.success)
            }
        }
        .padding(DS.Spacing.xl)
    }
    .background(DS.Color.canvas)
}

// MARK: - Typography Preview

#Preview("Typography") {
    ScrollView {
        VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            Text("TYPOGRAPHY SCALE")
                .font(DS.Typography.label)
                .tracking(1.5)
                .foregroundStyle(DS.Color.textTertiary)
                .padding(.top, DS.Spacing.lg)

            Group {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("DISPLAY")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("Glyph — 28pt Bold")
                        .font(DS.Typography.display)
                        .foregroundStyle(DS.Color.textPrimary)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("TITLE")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("Font Library — 20pt Semibold")
                        .font(DS.Typography.title)
                        .foregroundStyle(DS.Color.textPrimary)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("BODY")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("Type your text, pick a font, share to Stories — 16pt Regular")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Color.textPrimary)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("CAPTION")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("Playfair Display · Bold · 24pt — 13pt Regular")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("LABEL")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("EXPORT · STYLE · FONT")
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }
        }
        .padding(DS.Spacing.xl)
    }
    .background(DS.Color.canvas)
}

// MARK: - Spacing & Radius Preview

#Preview("Spacing & Radius") {
    ScrollView {
        VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            Text("SPACING SCALE")
                .font(DS.Typography.label)
                .tracking(1.5)
                .foregroundStyle(DS.Color.textTertiary)
                .padding(.top, DS.Spacing.lg)

            ForEach([
                ("xs", DS.Spacing.xs),
                ("sm", DS.Spacing.sm),
                ("md", DS.Spacing.md),
                ("lg", DS.Spacing.lg),
                ("xl", DS.Spacing.xl),
                ("xxl", DS.Spacing.xxl),
            ], id: \.0) { name, value in
                HStack {
                    Text(name.uppercased())
                        .font(DS.Typography.label)
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.textTertiary)
                        .frame(width: 40, alignment: .leading)
                    Rectangle()
                        .fill(DS.Color.accent)
                        .frame(width: value * 4, height: DS.Spacing.sm)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                    Text("\(Int(value))pt")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Text("CORNER RADIUS")
                .font(DS.Typography.label)
                .tracking(1.5)
                .foregroundStyle(DS.Color.textTertiary)
                .padding(.top, DS.Spacing.lg)

            HStack(spacing: DS.Spacing.md) {
                ForEach([
                    ("sm", DS.Radius.sm),
                    ("md", DS.Radius.md),
                    ("lg", DS.Radius.lg),
                    ("xl", DS.Radius.xl),
                ], id: \.0) { name, radius in
                    VStack(spacing: DS.Spacing.xs) {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(DS.Color.surface)
                            .frame(width: 48, height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: radius)
                                    .stroke(DS.Color.border, lineWidth: 1)
                            )
                        Text(name.uppercased())
                            .font(DS.Typography.label)
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                }
            }
        }
        .padding(DS.Spacing.xl)
    }
    .background(DS.Color.canvas)
}

// MARK: - Buttons Preview

#Preview("Buttons") {
    VStack(spacing: DS.Spacing.lg) {
        Text("BUTTON STYLES")
            .font(DS.Typography.label)
            .tracking(1.5)
            .foregroundStyle(DS.Color.textTertiary)

        Text("Share to Instagram Stories")
            .font(.body.weight(.semibold))
            .foregroundStyle(DS.Color.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(DS.Color.accent, in: RoundedRectangle(cornerRadius: DS.Radius.md))

        Text("Save to Photos")
            .font(.body.weight(.medium))
            .foregroundStyle(DS.Color.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(DS.Color.canvas, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .stroke(DS.Color.border, lineWidth: 1)
            )

        Text("Copy Image")
            .font(.body.weight(.medium))
            .foregroundStyle(DS.Color.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
    }
    .padding(DS.Spacing.xl)
    .background(DS.Color.surface)
}

// MARK: - Helpers

private func colorSwatch(_ name: String, _ color: Color, bordered: Bool = false) -> some View {
    VStack(spacing: DS.Spacing.xs) {
        RoundedRectangle(cornerRadius: DS.Radius.sm)
            .fill(color)
            .frame(height: 48)
            .overlay {
                if bordered {
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .stroke(DS.Color.border, lineWidth: 1)
                }
            }
        Text(name)
            .font(DS.Typography.label)
            .foregroundStyle(DS.Color.textSecondary)
    }
}
