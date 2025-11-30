//
//  DateRangePickerView.swift
//  agile-self
//
//  Created by Claude on 2025/11/30.
//

import SwiftUI

/// A view for selecting retrospective type and date range
struct DateRangePickerView: View {
    @Bindable var viewModel: KPTAEntryViewModel

    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Type Selector
            typeSelector

            // Date Range Display with Navigation
            dateRangeSelector

            // Quick Selection Buttons
            quickSelectionButtons
        }
        .padding(Theme.Spacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }

    // MARK: - Type Selector

    private var typeSelector: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Retrospective Type")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Picker("Retrospective Type", selection: $viewModel.retroType) {
                ForEach(RetrospectiveType.allCases, id: \.self) { type in
                    Text(type.displayName)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Retrospective type selector")
            .accessibilityHint("Choose between weekly or monthly retrospective")
            .onChange(of: viewModel.retroType) { _, newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.updateDateRange(for: newValue)
                }
            }
        }
    }

    // MARK: - Date Range Selector

    private var dateRangeSelector: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Previous Period Button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.selectPreviousPeriod()
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous \(viewModel.retroType.displayName.lowercased())")

            Spacer()

            // Date Range Display
            VStack(spacing: Theme.Spacing.xxs) {
                Text(viewModel.generatedTitle)
                    .font(Theme.Typography.headline)
                    .accessibilityAddTraits(.isHeader)

                HStack(spacing: Theme.Spacing.xs) {
                    dateButton(
                        date: viewModel.startDate,
                        label: "Start Date",
                        isExpanded: showStartDatePicker
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showStartDatePicker.toggle()
                            showEndDatePicker = false
                        }
                    }

                    Text("-")
                        .foregroundStyle(.secondary)

                    dateButton(
                        date: viewModel.endDate,
                        label: "End Date",
                        isExpanded: showEndDatePicker
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showEndDatePicker.toggle()
                            showStartDatePicker = false
                        }
                    }
                }
            }

            Spacer()

            // Next Period Button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.selectNextPeriod()
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next \(viewModel.retroType.displayName.lowercased())")
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - Date Button

    private func dateButton(
        date: Date,
        label: String,
        isExpanded: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(formattedDate(date))
                .font(Theme.Typography.callout)
                .foregroundStyle(isExpanded ? Theme.KPTA.action : .primary)
                .padding(.horizontal, Theme.Spacing.xs)
                .padding(.vertical, Theme.Spacing.xxs)
                .background(
                    isExpanded ? Theme.KPTA.actionBackground : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label): \(formattedDate(date))")
        .accessibilityHint("Double tap to change \(label.lowercased())")
    }

    // MARK: - Quick Selection Buttons

    private var quickSelectionButtons: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Date Pickers (shown when expanded)
            if showStartDatePicker {
                DatePicker(
                    "Start Date",
                    selection: $viewModel.startDate,
                    in: ...viewModel.endDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .opacity
                ))
            }

            if showEndDatePicker {
                DatePicker(
                    "End Date",
                    selection: $viewModel.endDate,
                    in: viewModel.startDate...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .opacity
                ))
            }

            // Quick Selection Chips
            HStack(spacing: Theme.Spacing.sm) {
                quickSelectButton(
                    title: "This \(viewModel.retroType == .weekly ? "Week" : "Month")",
                    systemImage: "calendar"
                ) {
                    closeDatePickers()
                    viewModel.selectCurrentPeriod()
                }

                quickSelectButton(
                    title: "Last \(viewModel.retroType == .weekly ? "Week" : "Month")",
                    systemImage: "clock.arrow.circlepath"
                ) {
                    closeDatePickers()
                    viewModel.selectPreviousPeriod()
                }
            }
        }
    }

    private func quickSelectButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(Theme.Typography.callout)
                .foregroundStyle(.primary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func closeDatePickers() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showStartDatePicker = false
            showEndDatePicker = false
        }
    }
}

// MARK: - Preview

#Preview {
    DateRangePickerView(viewModel: KPTAEntryViewModel())
        .padding()
}
