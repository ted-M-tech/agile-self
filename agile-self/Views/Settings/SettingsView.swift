//
//  SettingsView.swift
//  agile-self
//
//  Full settings screen with dark premium theme.
//

import SwiftUI
import SwiftData

// MARK: - SettingsView

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    // MARK: - Local State

    @State private var displayName: String = ""
    @State private var reminderEnabled: Bool = true
    @State private var reminderTime: Date = SettingsView.defaultReminderTime
    @State private var weeklyReviewDay: Int = 6
    @State private var allowCloudAI: Bool = false
    @State private var notificationsEnabled: Bool = true
    @State private var showPaywall: Bool = false
    @State private var showPrivacySheet: Bool = false
    @State private var selectedLanguage: String = {
        let current = UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first ?? Locale.current.language.languageCode?.identifier ?? "en"
        return current.hasPrefix("ja") ? "ja" : "en"
    }()
    @State private var showLanguageRestartAlert = false

    // MARK: - Constants

    private static let weekdays = [
        "Sunday", "Monday", "Tuesday", "Wednesday",
        "Thursday", "Friday", "Saturday",
    ]

    private static var defaultReminderTime: Date {
        var components = DateComponents()
        components.hour = 21
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private static let appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    accountSection
                    languageSection
                    reminderSection
                    weeklyReviewSection
                    aiPrivacySection
                    healthDataSection
                    subscriptionSection
                    dataSection
                    aboutSection

                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.accentStart)
                }
            }
            .task { loadProfile() }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showPrivacySheet) {
                privacyInfoSheet
            }
            .alert("Restart to Apply Language", isPresented: $showLanguageRestartAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The new language takes effect the next time you open Agile Self.")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "ACCOUNT")

            VStack(spacing: 0) {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "person.fill")
                        .font(.callout)
                        .foregroundStyle(Theme.Colors.accentStart)
                        .frame(width: 24, height: 24)

                    TextField("Display Name", text: $displayName)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .onChange(of: displayName) { _, newValue in
                            saveDisplayName(newValue)
                        }
                        .accessibilityLabel("Display name")
                        .accessibilityHint("Enter your display name")
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
            }
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        }
    }

    // MARK: - Language Section

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "LANGUAGE")

            VStack(spacing: 0) {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "globe")
                        .font(.callout)
                        .foregroundStyle(Theme.Dimension.focus)
                        .frame(width: 24, height: 24)

                    Text("Language")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Spacer()

                    Picker("", selection: $selectedLanguage) {
                        Text("English").tag("en")
                        Text("Japanese").tag("ja")
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.Colors.accentEnd)
                    .onChange(of: selectedLanguage) { _, newValue in
                        // Persist the preferred language; iOS applies it on next launch.
                        // Never call exit(0) — force-terminating is an App Store rejection
                        // risk and reads as a crash. Prompt the user to restart instead.
                        UserDefaults.standard.set([newValue], forKey: "AppleLanguages")
                        showLanguageRestartAlert = true
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("App language")
                .accessibilityValue(selectedLanguage == "ja" ? "Japanese" : "English")
            }
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        }
    }

    // MARK: - Reminder Section

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "CHECK-IN REMINDER")

            VStack(spacing: 0) {
                // Toggle row
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "bell.fill")
                        .font(.callout)
                        .foregroundStyle(Theme.Colors.warning)
                        .frame(width: 24, height: 24)

                    Text("Daily Reminder")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Spacer()

                    Toggle("", isOn: $reminderEnabled)
                        .labelsHidden()
                        .tint(Theme.Colors.accentStart)
                        .onChange(of: reminderEnabled) { _, _ in
                            saveReminderSettings()
                        }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Daily check-in reminder")
                .accessibilityValue(reminderEnabled ? "On" : "Off")

                if reminderEnabled {
                    settingsDivider

                    // Time picker row
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "clock.fill")
                            .font(.callout)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .frame(width: 24, height: 24)

                        Text("Time")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Spacer()

                        DatePicker(
                            "",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .tint(Theme.Colors.accentStart)
                        .colorScheme(.dark)
                        .onChange(of: reminderTime) { _, _ in
                            saveReminderSettings()
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .accessibilityLabel("Reminder time")
                }
            }
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            .animation(Theme.Animation.standard, value: reminderEnabled)
        }
    }

    // MARK: - Weekly Review Section

    private var weeklyReviewSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "WEEKLY REVIEW")

            VStack(spacing: 0) {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.callout)
                        .foregroundStyle(Theme.Dimension.focus)
                        .frame(width: 24, height: 24)

                    Text("Review Day")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Spacer()

                    Picker("", selection: $weeklyReviewDay) {
                        ForEach(1...7, id: \.self) { day in
                            Text(Self.weekdays[day - 1])
                                .tag(day)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.Colors.accentEnd)
                    .onChange(of: weeklyReviewDay) { _, newValue in
                        saveWeeklyReviewDay(newValue)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Weekly review day")
                .accessibilityValue(Self.weekdays[weeklyReviewDay - 1])
            }
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        }
    }

    // MARK: - AI & Privacy Section

    private var aiPrivacySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "AI & PRIVACY")

            VStack(spacing: 0) {
                // Cloud AI toggle
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "cloud.fill")
                            .font(.callout)
                            .foregroundStyle(Theme.Colors.accentEnd)
                            .frame(width: 24, height: 24)

                        Text("Cloud AI")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Spacer()

                        Toggle("", isOn: $allowCloudAI)
                            .labelsHidden()
                            .tint(Theme.Colors.accentStart)
                            .onChange(of: allowCloudAI) { _, newValue in
                                saveCloudAI(newValue)
                            }
                    }

                    Text("Allow AI analysis via cloud. Your data is anonymized before sending.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .padding(.leading, 24 + Theme.Spacing.md)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Cloud AI analysis")
                .accessibilityValue(allowCloudAI ? "On" : "Off")
                .accessibilityHint("Your data is anonymized before sending")

                settingsDivider

                // Privacy info row
                Button {
                    showPrivacySheet = true
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "hand.raised.fill")
                            .font(.callout)
                            .foregroundStyle(Theme.Colors.success)
                            .frame(width: 24, height: 24)

                        Text("Privacy Information")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Privacy information")
                .accessibilityHint("Opens privacy details")
            }
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        }
    }

    // MARK: - Health & Data Section

    private var healthDataSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "HEALTH & DATA")

            VStack(spacing: 0) {
                // HealthKit row
                statusRow(
                    icon: "heart.fill",
                    iconColor: .red,
                    label: "Health Data",
                    statusText: "Connected",
                    statusColor: Theme.Colors.success
                )

                settingsDivider

                // Screen Time row
                statusRow(
                    icon: "hourglass",
                    iconColor: .cyan,
                    label: "Screen Time",
                    statusText: "Connected",
                    statusColor: Theme.Colors.success
                )

                settingsDivider

                // Notifications row
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "bell.badge.fill")
                        .font(.callout)
                        .foregroundStyle(Theme.Colors.warning)
                        .frame(width: 24, height: 24)

                    Text("Notifications")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Spacer()

                    Toggle("", isOn: $notificationsEnabled)
                        .labelsHidden()
                        .tint(Theme.Colors.accentStart)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            saveNotifications(newValue)
                        }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Notifications")
                .accessibilityValue(notificationsEnabled ? "Enabled" : "Disabled")
            }
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "SUBSCRIPTION")

            VStack(spacing: 0) {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "crown.fill")
                        .font(.callout)
                        .foregroundStyle(Theme.Dimension.energy)
                        .frame(width: 24, height: 24)

                    Text("Current Plan")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Spacer()

                    let tier = profile?.subscriptionTier ?? .free
                    Text(tier == .premium ? "Premium" : "Free")
                        .pillStyle(
                            color: tier == .premium
                                ? Theme.Colors.accentStart
                                : Theme.Colors.textSecondary
                        )
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current plan: \(profile?.subscriptionTier == .premium ? "Premium" : "Free")")

                if profile?.subscriptionTier != .premium {
                    settingsDivider

                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "sparkles")
                                .font(.callout)
                                .foregroundStyle(Theme.Colors.accentStart)
                                .frame(width: 24, height: 24)

                            Text("Upgrade to Premium")
                                .font(Theme.Typography.headline)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Theme.Colors.accentStart, Theme.Colors.accentEnd],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.accentEnd)
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Upgrade to Premium")
                    .accessibilityHint("Opens subscription options")
                }
            }
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "DATA")

            VStack(spacing: 0) {
                Button {
                    // Export placeholder
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.callout)
                            .foregroundStyle(Theme.Colors.success)
                            .frame(width: 24, height: 24)

                        Text("Export Data")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Spacer()

                        Text("JSON / PDF")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Export data")
                .accessibilityHint("Export your data as JSON or PDF")
            }
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "ABOUT")

            VStack(spacing: 0) {
                // Version row
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "info.circle")
                        .font(.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 24, height: 24)

                    Text("Version")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Spacer()

                    Text(Self.appVersion)
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Version \(Self.appVersion)")

                settingsDivider

                // Privacy Policy
                linkRow(
                    icon: "lock.shield.fill",
                    iconColor: Theme.Colors.accentEnd,
                    label: "Privacy Policy",
                    url: URL(string: "https://agileself.app/privacy")!
                )

                settingsDivider

                // Terms of Service
                linkRow(
                    icon: "doc.text.fill",
                    iconColor: Theme.Colors.textSecondary,
                    label: "Terms of Service",
                    url: URL(string: "https://agileself.app/terms")!
                )
            }
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))

            // Footer
            Text("Made with \u{2764}\u{FE0F} for personal growth")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.Spacing.sm)
                .accessibilityLabel("Made with love for personal growth")
        }
    }

    // MARK: - Privacy Info Sheet

    private var privacyInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Label("Local-First Storage", systemImage: "iphone")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("All your check-in data, health metrics, and action items are stored locally on your device using SwiftData. Your data never leaves your device unless you explicitly enable Cloud AI.")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Label("Cloud AI Processing", systemImage: "cloud.fill")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("When Cloud AI is enabled, your data is anonymized and stripped of personally identifiable information before being sent for analysis. We use Gemini 2.0 Flash for AI insights. You can disable this at any time.")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Label("Health Data", systemImage: "heart.fill")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("Health data is read from Apple HealthKit with your permission. This data is only used locally for correlations and insights. It is never shared with third parties.")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Label("iCloud Sync", systemImage: "arrow.triangle.2.circlepath.icloud.fill")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("If iCloud is enabled, your data is synced across your Apple devices using CloudKit. Apple encrypts this data in transit and at rest.")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
            }
            .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Privacy")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showPrivacySheet = false }
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.accentStart)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Reusable Components

    private func sectionHeader(title: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Colors.textTertiary)
                .tracking(1.2)

            Spacer()
        }
    }

    private func statusRow(
        icon: String,
        iconColor: Color,
        label: String,
        statusText: String,
        statusColor: Color
    ) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)

            Text(label)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()

            HStack(spacing: Theme.Spacing.xs) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)

                Text(statusText)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(statusColor)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(statusText)")
    }

    private func linkRow(
        icon: String,
        iconColor: Color,
        label: String,
        url: URL
    ) -> some View {
        Link(destination: url) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(iconColor)
                    .frame(width: 24, height: 24)

                Text(label)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
        .accessibilityHint("Opens in Safari")
    }

    private var settingsDivider: some View {
        Divider()
            .overlay(Theme.Colors.divider)
            .padding(.leading, Theme.Spacing.md + 24 + Theme.Spacing.md)
    }

    // MARK: - Data Operations

    private func loadProfile() {
        guard let profile else { return }
        displayName = profile.displayName ?? ""
        weeklyReviewDay = profile.weeklyReviewDay
        allowCloudAI = profile.allowCloudAI
        notificationsEnabled = profile.notificationsEnabled

        var components = DateComponents()
        components.hour = profile.checkInReminderHour
        components.minute = profile.checkInReminderMinute
        if let time = Calendar.current.date(from: components) {
            reminderTime = time
        }
    }

    private func saveDisplayName(_ name: String) {
        guard let profile else { return }
        profile.displayName = name.isEmpty ? nil : name
    }

    private func saveReminderSettings() {
        guard let profile else { return }
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        profile.checkInReminderHour = components.hour ?? 21
        profile.checkInReminderMinute = components.minute ?? 0
    }

    private func saveWeeklyReviewDay(_ day: Int) {
        guard let profile else { return }
        profile.weeklyReviewDay = day
    }

    private func saveCloudAI(_ enabled: Bool) {
        guard let profile else { return }
        profile.allowCloudAI = enabled
    }

    private func saveNotifications(_ enabled: Bool) {
        guard let profile else { return }
        profile.notificationsEnabled = enabled
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
        .preferredColorScheme(.dark)
}
