//
//  KPTASetupStepView.swift
//  agile-self
//
//  Created by Claude on 2025/12/01.
//

import SwiftUI

/// A minimal setup step for selecting retrospective period
struct KPTASetupStepView: View {
    @Binding var retroType: RetrospectiveType
    @Binding var startDate: Date
    @Binding var endDate: Date

    let onSelectPreviousPeriod: () -> Void
    let onSelectNextPeriod: () -> Void
    let onSelectCurrentPeriod: () -> Void

    private var canGoToFuture: Bool {
        endDate < Date()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            stepHeader
                .padding(.top, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xxl)

            // Type selector (3 options: Daily, Weekly, Monthly)
            typeSelector
                .padding(.bottom, Theme.Spacing.xl)

            // Period selector
            periodSelector
                .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            // Quick actions
            quickActions
                .padding(.bottom, Theme.Spacing.xl)
        }
    }

    // MARK: - Header

    private var stepHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: retroType.iconName)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Theme.KPTA.action.opacity(0.2))

            Text("When")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("What period are you reflecting on?")
                .font(Theme.Typography.body)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Type Selector

    private var typeSelector: some View {
        Picker("Type", selection: $retroType) {
            Text("Daily").tag(RetrospectiveType.daily)
            Text("Weekly").tag(RetrospectiveType.weekly)
            Text("Monthly").tag(RetrospectiveType.monthly)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.Spacing.lg)
        .onChange(of: retroType) { _, newValue in
            updateDateRange(for: newValue)
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Previous button
            Button(action: onSelectPreviousPeriod) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous \(periodUnitLabel)")

            // Date display
            VStack(spacing: Theme.Spacing.xxs) {
                Text(periodTitle)
                    .font(Theme.Typography.title2)

                if retroType != .daily {
                    Text(dateRangeText)
                        .font(Theme.Typography.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            // Next button
            Button(action: onSelectNextPeriod) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(canGoToFuture ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(!canGoToFuture)
            .accessibilityLabel("Next \(periodUnitLabel)")
        }
        .padding(.vertical, Theme.Spacing.lg)
        .padding(.horizontal, Theme.Spacing.md)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: Theme.Spacing.md) {
            QuickPeriodButton(
                title: currentPeriodLabel,
                isSelected: isCurrentPeriod,
                action: onSelectCurrentPeriod
            )

            QuickPeriodButton(
                title: previousPeriodLabel,
                isSelected: isPreviousPeriod,
                action: {
                    onSelectCurrentPeriod()
                    onSelectPreviousPeriod()
                }
            )
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Computed Properties

    private var periodUnitLabel: String {
        switch retroType {
        case .daily: return "day"
        case .weekly: return "week"
        case .monthly: return "month"
        }
    }

    private var currentPeriodLabel: String {
        switch retroType {
        case .daily: return "Today"
        case .weekly: return "This Week"
        case .monthly: return "This Month"
        }
    }

    private var previousPeriodLabel: String {
        switch retroType {
        case .daily: return "Yesterday"
        case .weekly: return "Last Week"
        case .monthly: return "Last Month"
        }
    }

    private var periodTitle: String {
        let calendar = Calendar.current

        switch retroType {
        case .daily:
            if calendar.isDateInToday(startDate) {
                return "Today"
            } else if calendar.isDateInYesterday(startDate) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE, MMM d"
                return formatter.string(from: startDate)
            }
        case .weekly:
            let weekNumber = calendar.component(.weekOfYear, from: startDate)
            return "Week \(weekNumber)"
        case .monthly:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: startDate)
        }
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)

        return "\(start) - \(end)"
    }

    private var isCurrentPeriod: Bool {
        let calendar = Calendar.current
        let now = Date()

        switch retroType {
        case .daily:
            return calendar.isDateInToday(startDate)
        case .weekly:
            return calendar.isDate(startDate, equalTo: calendar.startOfWeek(for: now), toGranularity: .day)
        case .monthly:
            return calendar.isDate(startDate, equalTo: calendar.startOfMonth(for: now), toGranularity: .day)
        }
    }

    private var isPreviousPeriod: Bool {
        let calendar = Calendar.current
        let now = Date()

        switch retroType {
        case .daily:
            return calendar.isDateInYesterday(startDate)
        case .weekly:
            let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: calendar.startOfWeek(for: now))!
            return calendar.isDate(startDate, equalTo: lastWeekStart, toGranularity: .day)
        case .monthly:
            let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: calendar.startOfMonth(for: now))!
            return calendar.isDate(startDate, equalTo: lastMonthStart, toGranularity: .day)
        }
    }

    private func updateDateRange(for type: RetrospectiveType) {
        let calendar = Calendar.current
        let now = Date()

        switch type {
        case .daily:
            startDate = calendar.startOfDay(for: now)
            endDate = calendar.startOfDay(for: now)
        case .weekly:
            startDate = calendar.startOfWeek(for: now)
            endDate = calendar.endOfWeek(for: now)
        case .monthly:
            startDate = calendar.startOfMonth(for: now)
            endDate = calendar.endOfMonth(for: now)
        }
    }
}

// MARK: - Quick Period Button

private struct QuickPeriodButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.callout)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Theme.KPTA.action : Color(.systemGray6))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    KPTASetupStepView(
        retroType: .constant(.daily),
        startDate: .constant(Date()),
        endDate: .constant(Date()),
        onSelectPreviousPeriod: {},
        onSelectNextPeriod: {},
        onSelectCurrentPeriod: {}
    )
}
