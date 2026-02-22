// FineTune/Views/DesignSystem/VisualEffectBackground.swift
import SwiftUI
import AppKit

/// A frosted glass background using NSVisualEffectView.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .menu
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Colors

extension Color {
    /// Popup background overlay - uses theme-aware color from DesignTokens
    /// Darker than before for more contrast with floating glass rows
    static var popupBackgroundOverlay: Color { DesignTokens.Colors.popupOverlay }
}

// MARK: - View Extensions

extension View {
    /// Applies a liquid glass popup background with native material depth.
    func darkGlassBackground() -> some View {
        modifier(LiquidGlassBackgroundModifier())
    }

    /// Applies EQ panel glass background (recessed style)
    func eqPanelBackground() -> some View {
        modifier(EQPanelBackgroundModifier())
    }
}

// MARK: - Liquid Glass Background Modifier

struct LiquidGlassBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: DesignTokens.Dimensions.cornerRadius,
            style: .continuous
        )

        content
            .background {
                ZStack {
                    // Native vibrancy base.
                    VisualEffectBackground(material: .menu, blendingMode: .behindWindow)

                    // Very light tint to keep contrast without muddying translucency.
                    Color.black.opacity(0.08)

                    // Soft liquid highlight near the top edge.
                    RadialGradient(
                        colors: [.white.opacity(0.20), .clear],
                        center: .top,
                        startRadius: 4,
                        endRadius: 320
                    )

                    // Gentle vertical gleam for a curved glass look.
                    LinearGradient(
                        colors: [.white.opacity(0.10), .clear, .black.opacity(0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .clipShape(shape)
            .overlay {
                shape
                    .strokeBorder(.white.opacity(0.24), lineWidth: 0.6)
            }
            .overlay {
                shape
                    .strokeBorder(.black.opacity(0.10), lineWidth: 0.45)
            }
            .shadow(color: .black.opacity(0.14), radius: 10, y: 6)
    }
}

// MARK: - EQ Panel Background Modifier

/// Modifier that applies glass background to EQ panel
/// Locked to recessed style: dark overlay with subtle border
struct EQPanelBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Dimensions.buttonRadius)
                    .fill(DesignTokens.Colors.recessedBackground)
            }
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Dimensions.buttonRadius)
                    .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 0.5)
            }
    }
}

// MARK: - Previews

#Preview("Dark Glass Popup Background") {
    VStack(spacing: 16) {
        Text("OUTPUT DEVICES")
            .sectionHeaderStyle()
        Text("Dark frosted glass background")
            .foregroundStyle(.primary)
    }
    .padding(DesignTokens.Spacing.lg)
    .frame(width: 300)
    .darkGlassBackground()
    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Dimensions.cornerRadius))
    .environment(\.colorScheme, .dark)
}

#Preview("EQ Panel - Recessed") {
    VStack(spacing: 8) {
        Text("EQ Panel - Recessed")
            .foregroundStyle(.secondary)
        HStack {
            ForEach(0..<5) { _ in
                Rectangle()
                    .fill(.secondary.opacity(0.3))
                    .frame(width: 20, height: 60)
            }
        }
    }
    .padding()
    .eqPanelBackground()
    .padding()
    .darkGlassBackground()
    .environment(\.colorScheme, .dark)
}
