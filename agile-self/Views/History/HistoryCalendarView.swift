//
//  HistoryCalendarView.swift
//  agile-self
//
//  A month-navigable calendar of every day. Tap a logged day to view/edit it, tap an empty
//  past/today day to back-fill it. Future days are disabled. This is the canonical place to
//  fix today's entry after the fact, fill a forgotten day, or correct a past record.
//
//  Cell colours mirror the Monthly Report heatmap (accent opacity scaled by composite score)
//  so the two surfaces read consistently.
//

import SwiftUI
import SwiftData

// MARK: - HistoryCalendarView

struct HistoryCalendarView: View {
    @Environment(\.modelContext) private var modelContext

    /// All check-ins; SwiftData keeps this live, so the grid recolours automatically the
    /// moment the editor saves/deletes (no manual refresh token needed).
    @Query(sort: \DailyCheckIn.date, order: .forward)
    private var allCheckIns: [DailyCheckIn]

    /// First day (midnight) of the month currently shown.
    @State private var visibleMonth: Date = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: Date())
    ) ?? Calendar.current.startOfDay(for: Date())

    /// The tapped day — drives the editor cover (Identifiable wrapper for `fullScreenCover(item:)`).
    @State private var selectedDay: SelectedDay?

    private let calendar = Calendar.current
    private let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    private let gridColumns = Array(
        repeating: GridItem(.flexible(), spacing: Theme.Spacing.xs),
        count: 7
    )

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                monthHeader
                calendarCard
                legend
                Spacer(minLength: Theme.Spacing.xl)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.md)
        }
        .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(item: $selectedDay) { day in
            DailyCheckInView(targetDate: day.date)
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            navButton(systemImage: "chevron.left", accessibility: "Previous month") {
                changeMonth(by: -1)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(visibleMonth.formatted(.dateTime.month(.wide).year()))
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(loggedSummary)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            navButton(systemImage: "chevron.right", accessibility: "Next month") {
                changeMonth(by: 1)
            }
            .disabled(isCurrentMonth)
            .opacity(isCurrentMonth ? 0.3 : 1)
        }
    }

    private func navButton(systemImage: String, accessibility: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 40, height: 40)
                .background(Theme.Colors.backgroundTertiary)
                .clipShape(Circle())
                // Keep the 40pt circle visually; expand the tap target to the 44pt minimum.
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .accessibilityLabel(accessibility)
    }

    // MARK: - Calendar Grid

    private var calendarCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Weekday header (Monday-first, matching the heatmap).
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(Array(weekdayLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: gridColumns, spacing: Theme.Spacing.xs) {
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date)
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .cardStyle()
    }

    private func dayCell(_ date: Date) -> some View {
        let day = calendar.startOfDay(for: date)
        let score = scoreByDay[day]
        let isFuture = day > today
        let isCurrentDay = calendar.isDate(day, inSameDayAs: today)

        return Button {
            selectedDay = SelectedDay(date: day)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(cellFill(score: score, isFuture: isFuture))

                if isCurrentDay {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .stroke(Theme.Colors.accentStart, lineWidth: 1.5)
                }

                Text("\(calendar.component(.day, from: day))")
                    .font(Theme.Typography.caption)
                    .fontWeight(score != nil ? .semibold : .regular)
                    .foregroundStyle(cellTextColor(score: score, isFuture: isFuture))
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel(cellAccessibilityLabel(day: day, score: score, isFuture: isFuture))
        .accessibilityHint(isFuture ? "" : (score == nil ? "Add a check-in" : "Edit this check-in"))
    }

    // MARK: - Legend

    private var legend: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.md) {
                legendSwatch(color: Theme.Colors.backgroundTertiary, label: "No check-in")
                legendSwatch(color: Theme.Colors.accentStart.opacity(0.7), label: "Logged")
            }
            Text("Tap a day to add, edit, or back-fill a check-in.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func legendSwatch(color: Color, label: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 14, height: 14)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }

    // MARK: - Derived Data

    private var today: Date { calendar.startOfDay(for: Date()) }

    private var currentMonthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(visibleMonth, equalTo: currentMonthStart, toGranularity: .month)
    }

    /// Composite score keyed by each check-in's start-of-day, for O(1) cell lookups.
    private var scoreByDay: [Date: Double] {
        var map: [Date: Double] = [:]
        for checkIn in allCheckIns {
            map[calendar.startOfDay(for: checkIn.date)] = checkIn.compositeScore
        }
        return map
    }

    /// The grid cells for `visibleMonth`: leading blanks to align the 1st to its weekday column,
    /// then one entry per day of the month.
    private var monthCells: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: visibleMonth) else { return [] }
        let leadingBlanks = mondayIndex(of: visibleMonth)
        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<range.count {
            if let date = calendar.date(byAdding: .day, value: offset, to: visibleMonth) {
                cells.append(date)
            }
        }
        return cells
    }

    /// "X of Y days logged" for the visible month (capped at today for the current month).
    private var loggedSummary: String {
        guard let range = calendar.range(of: .day, in: .month, for: visibleMonth) else { return "" }
        var logged = 0
        var elapsed = 0
        for offset in 0..<range.count {
            guard let date = calendar.date(byAdding: .day, value: offset, to: visibleMonth) else { continue }
            let day = calendar.startOfDay(for: date)
            if day > today { continue }
            elapsed += 1
            if scoreByDay[day] != nil { logged += 1 }
        }
        return "\(logged) of \(elapsed) days logged"
    }

    /// Column index for a date in a Monday-first grid (Mon = 0 … Sun = 6).
    private func mondayIndex(of date: Date) -> Int {
        (calendar.component(.weekday, from: date) + 5) % 7
    }

    // MARK: - Cell Styling

    private func cellFill(score: Double?, isFuture: Bool) -> Color {
        if isFuture {
            return Theme.Colors.backgroundTertiary.opacity(0.4)
        }
        guard let score else {
            return Theme.Colors.backgroundTertiary
        }
        // Map 1–5 → opacity 0.25–1.0 (same ramp as the heatmap).
        let normalized = max(0, min((score - 1.0) / 4.0, 1.0))
        return Theme.Colors.accentStart.opacity(0.25 + normalized * 0.75)
    }

    private func cellTextColor(score: Double?, isFuture: Bool) -> Color {
        if isFuture { return Theme.Colors.textTertiary }
        return score == nil ? Theme.Colors.textSecondary : Theme.Colors.textPrimary
    }

    private func cellAccessibilityLabel(day: Date, score: Double?, isFuture: Bool) -> String {
        let dateStr = day.formatted(.dateTime.weekday(.wide).month(.wide).day())
        if isFuture { return "\(dateStr), upcoming" }
        if let score { return "\(dateStr), score \(String(format: "%.1f", score)) out of 5" }
        return "\(dateStr), no check-in"
    }

    // MARK: - Actions

    private func changeMonth(by delta: Int) {
        guard let next = calendar.date(byAdding: .month, value: delta, to: visibleMonth) else { return }
        // Never navigate past the current month.
        if delta > 0, next > currentMonthStart { return }
        withAnimation(Theme.Animation.standard) {
            visibleMonth = next
        }
    }
}

// MARK: - Selected Day

/// Identifiable wrapper so a tapped day can drive `fullScreenCover(item:)`.
private struct SelectedDay: Identifiable {
    let date: Date
    var id: Date { date }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HistoryCalendarView()
    }
    .modelContainer(MockData.previewContainer)
    .environment(AppContainer(modelContainer: MockData.previewContainer))
    .preferredColorScheme(.dark)
}
