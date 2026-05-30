//
//  WatchFaceGlyph.swift
//  agile-self Watch App
//
//  Monochrome line-art face, ported from the iOS FaceGlyph so the watch matches the phone.
//  The face is the hero of every check-in card: eyes (two dots) + a mouth whose curvature
//  expresses the 1..5 level (1 = sad, 5 = happy). Pure SwiftUI — no UIKit.
//

import SwiftUI

// MARK: - WatchFaceGlyph

/// A 1..5 mood face rendered as line art. Inherits its stroke/fill color from the
/// surrounding `.foregroundStyle(...)`, so callers tint it with a dimension color.
struct WatchFaceGlyph: View {
    /// 1 (sad) .. 5 (happy). Clamped internally.
    let level: Int
    var lineWidth: CGFloat = 2.2

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let lvl = CGFloat(min(max(level, 1), 5))
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            let eyeY = cy - s * 0.10
            let eyeDX = s * 0.18
            let eyeR = max(1.0, s * 0.05)
            let mouthY = cy + s * 0.16
            let mouthHalf = s * 0.20
            // Negative bend (sad) for low levels, positive (happy) for high levels.
            let bend = (lvl - 3) * 0.10 * s

            ZStack {
                Circle()
                    .frame(width: eyeR * 2, height: eyeR * 2)
                    .position(x: cx - eyeDX, y: eyeY)
                Circle()
                    .frame(width: eyeR * 2, height: eyeR * 2)
                    .position(x: cx + eyeDX, y: eyeY)
                Path { p in
                    p.move(to: CGPoint(x: cx - mouthHalf, y: mouthY))
                    p.addQuadCurve(
                        to: CGPoint(x: cx + mouthHalf, y: mouthY),
                        control: CGPoint(x: cx, y: mouthY + bend * 2)
                    )
                }
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Composite word headline

/// Maps a 1.0–5.0 composite score to a short, encouraging word headline. Mirrors the iOS
/// `CheckInConfirmationView` bands so the watch and phone speak the same language.
func watchCompositeWord(for composite: Double) -> String {
    switch composite {
    case 4.5...: return "Great day"
    case 3.5...: return "Good day"
    case 2.5...: return "Steady day"
    case 1.5...: return "Tough day"
    default: return "Hard day"
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        WatchTheme.Colors.backgroundPrimary.ignoresSafeArea()
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { level in
                    WatchFaceGlyph(level: level)
                        .foregroundStyle(WatchTheme.Dimension.energy)
                        .frame(width: 28, height: 28)
                }
            }
            Text(watchCompositeWord(for: 3.8))
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(WatchTheme.Colors.textPrimary)
        }
    }
    .preferredColorScheme(.dark)
}
