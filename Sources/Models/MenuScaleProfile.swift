import SwiftUI

/// Predefined layout configuration profile for each discrete menu zoom level (75% to 210%, 11 steps total).
public struct MenuScaleProfile {
    public let fontTitle: CGFloat
    public let fontSubtitle: CGFloat
    public let fontSectionHeader: CGFloat
    public let fontBody: CGFloat
    public let fontCaption: CGFloat
    public let fontBadge: CGFloat
    public let buttonHeight: CGFloat
    public let menuSizeButtonWidth: CGFloat
    public let menuSizeButtonHeight: CGFloat
    public let containerWidth: CGFloat
    public let outerPaddingHorizontal: CGFloat
    public let outerPaddingVertical: CGFloat
    public let innerSpacing: CGFloat

    public static func profile(for factor: Double) -> MenuScaleProfile {
        if factor <= 0.78 {
            // Step 1: 75% Ultra-Compact Mode
            return MenuScaleProfile(
                fontTitle: 12, fontSubtitle: 8.5, fontSectionHeader: 9,
                fontBody: 9.5, fontCaption: 8.5, fontBadge: 7.5,
                buttonHeight: 17, menuSizeButtonWidth: 11, menuSizeButtonHeight: 13,
                containerWidth: 250, outerPaddingHorizontal: 9, outerPaddingVertical: 9, innerSpacing: 7
            )
        } else if factor <= 0.88 {
            // Step 2: 85% Compact Mode
            return MenuScaleProfile(
                fontTitle: 13, fontSubtitle: 9, fontSectionHeader: 9.5,
                fontBody: 10, fontCaption: 9, fontBadge: 8,
                buttonHeight: 18, menuSizeButtonWidth: 12, menuSizeButtonHeight: 14,
                containerWidth: 260, outerPaddingHorizontal: 10, outerPaddingVertical: 10, innerSpacing: 8
            )
        } else if factor <= 0.97 {
            // Step 3: 95% Slightly Compact Mode
            return MenuScaleProfile(
                fontTitle: 13.5, fontSubtitle: 9.2, fontSectionHeader: 9.8,
                fontBody: 10.5, fontCaption: 9.2, fontBadge: 8.2,
                buttonHeight: 19, menuSizeButtonWidth: 12.5, menuSizeButtonHeight: 14.5,
                containerWidth: 270, outerPaddingHorizontal: 11, outerPaddingVertical: 11, innerSpacing: 8.5
            )
        } else if factor <= 1.05 {
            // Step 4: 100% Standard Baseline
            return MenuScaleProfile(
                fontTitle: 14, fontSubtitle: 9.5, fontSectionHeader: 10,
                fontBody: 11, fontCaption: 9.5, fontBadge: 8.5,
                buttonHeight: 20, menuSizeButtonWidth: 13, menuSizeButtonHeight: 15,
                containerWidth: 280, outerPaddingHorizontal: 12, outerPaddingVertical: 12, innerSpacing: 9
            )
        } else if factor <= 1.18 {
            // Step 5: 112% Comfort Reading Mode
            return MenuScaleProfile(
                fontTitle: 14.5, fontSubtitle: 9.8, fontSectionHeader: 10.2,
                fontBody: 11.2, fontCaption: 9.8, fontBadge: 8.8,
                buttonHeight: 21, menuSizeButtonWidth: 13.5, menuSizeButtonHeight: 15.5,
                containerWidth: 290, outerPaddingHorizontal: 12, outerPaddingVertical: 12, innerSpacing: 9.5
            )
        } else if factor <= 1.31 {
            // Step 6: 125% Large Text Mode
            return MenuScaleProfile(
                fontTitle: 15.5, fontSubtitle: 10.2, fontSectionHeader: 10.5,
                fontBody: 11.8, fontCaption: 10.2, fontBadge: 9,
                buttonHeight: 22, menuSizeButtonWidth: 14, menuSizeButtonHeight: 16,
                containerWidth: 300, outerPaddingHorizontal: 12.5, outerPaddingVertical: 12.5, innerSpacing: 10
            )
        } else if factor <= 1.44 {
            // Step 7: 138% Extra Large ADA Mode
            return MenuScaleProfile(
                fontTitle: 16.5, fontSubtitle: 10.8, fontSectionHeader: 11,
                fontBody: 12.2, fontCaption: 10.8, fontBadge: 9.5,
                buttonHeight: 23, menuSizeButtonWidth: 15, menuSizeButtonHeight: 17,
                containerWidth: 310, outerPaddingHorizontal: 13, outerPaddingVertical: 13, innerSpacing: 10
            )
        } else if factor <= 1.58 {
            // Step 8: 150% High Visibility Mode
            return MenuScaleProfile(
                fontTitle: 17.5, fontSubtitle: 11.2, fontSectionHeader: 11.5,
                fontBody: 12.8, fontCaption: 11.2, fontBadge: 10,
                buttonHeight: 24, menuSizeButtonWidth: 16, menuSizeButtonHeight: 18,
                containerWidth: 320, outerPaddingHorizontal: 13.5, outerPaddingVertical: 13.5, innerSpacing: 11
            )
        } else if factor <= 1.75 {
            // Step 9: 165% Extended Accessibility Mode
            return MenuScaleProfile(
                fontTitle: 18.5, fontSubtitle: 11.8, fontSectionHeader: 12,
                fontBody: 13.2, fontCaption: 11.8, fontBadge: 10.5,
                buttonHeight: 25, menuSizeButtonWidth: 16.5, menuSizeButtonHeight: 18.5,
                containerWidth: 330, outerPaddingHorizontal: 14, outerPaddingVertical: 14, innerSpacing: 11.5
            )
        } else if factor <= 1.95 {
            // Step 10: 185% Super Zoom Mode
            return MenuScaleProfile(
                fontTitle: 19.5, fontSubtitle: 12.4, fontSectionHeader: 12.5,
                fontBody: 13.8, fontCaption: 12.4, fontBadge: 11,
                buttonHeight: 26, menuSizeButtonWidth: 17, menuSizeButtonHeight: 19,
                containerWidth: 340, outerPaddingHorizontal: 14.5, outerPaddingVertical: 14.5, innerSpacing: 12
            )
        } else {
            // Step 11: 210% Maximum Ultra Zoom Mode
            return MenuScaleProfile(
                fontTitle: 21, fontSubtitle: 13, fontSectionHeader: 13,
                fontBody: 14.5, fontCaption: 13, fontBadge: 11.5,
                buttonHeight: 27, menuSizeButtonWidth: 18, menuSizeButtonHeight: 20,
                containerWidth: 350, outerPaddingHorizontal: 15, outerPaddingVertical: 15, innerSpacing: 12.5
            )
        }
    }
}
