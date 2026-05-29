//
//  FaceGlyph.swift
//  agile-self
//
//  Monochrome, single-color line-art face whose expression maps a 1…5 level
//  (1 = down … 3 = neutral … 5 = bright). Drawn with shapes instead of emoji so it
//  tints to ONE color (the dimension color when selected), scales crisply at any size,
//  and reads consistently in dark mode — unlike the multicolor emoji it replaces.
//

import SwiftUI

struct FaceGlyph: View {
    /// Expression level, 1 (sad) … 5 (happy). Clamped.
    let level: Int
    /// Stroke weight for eyes/mouth, relative to the glyph; scaled with size.
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
            // Mouth bend: level 3 = flat; >3 curves the centre DOWN (smile, larger y);
            // <3 curves it UP (frown, smaller y). SwiftUI's y grows downward.
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

// MARK: - Preview

#Preview("Face ramp") {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()
        HStack(spacing: 16) {
            ForEach(1...5, id: \.self) { level in
                FaceGlyph(level: level)
                    .foregroundStyle(Theme.Colors.accentStart)
                    .frame(width: 40, height: 40)
            }
        }
    }
    .preferredColorScheme(.dark)
}
