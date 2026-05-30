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
    @Environment(AppContainer.self) private var appContainer
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    // MARK: - Local State

    @State private var displayName: String = ""
    /// The single daily check-in reminder control, backed by `profile.notificationsEnabled`
    /// (the daily reminder is the app's only notification now that weekly review is cut).
    @State private var reminderEnabled: Bool = true
    /// Set while we mutate `reminderEnabled` programmatically (revert / OS reconciliation) so the
    /// bound Toggle's `.onChange` doesn't re-enter the scheduling side-effects.
    @State private var isSyncingReminder = false
    @State private var reminderTime: Date = SettingsView.defaultReminderTime
    @State private var showPaywall: Bool = false
    @State private var showPrivacySheet: Bool = false
    @State private var selectedLanguage: String = {
        let current = UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first ?? Locale.current.language.languageCode?.identifier ?? "en"
        return current.hasPrefix("ja") ? "ja" : "en"
    }()
    @State private var showLanguageRestartAlert = false
    @State private var showNotificationsDeniedAlert = false
    @State private var exportFile: ExportedDataFile?
    @State private var showExportShare = false
    @State private var showDeleteConfirmation = false
    @State private var isImportingHealth = false
    @State private var healthImportMessage: String?

    // MARK: - Constants

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
            .task {
                loadProfile()
                await reconcileReminderWithSystem()
            }
            .confirmationDialog(
                "Delete All Data?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    // Content-only wipe: clears logged data + resets the streak, but PRESERVES
                    // the profile (name, reminder time, preferences) and keeps you signed in.
                    // The scheduled daily reminder intentionally stays (you're still set up).
                    appContainer.dataManagementService.deleteAllData(context: modelContext)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your check-ins, health data, reports, actions, and streak on this device. Your name and settings are kept. This cannot be undone.")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showPrivacySheet) {
                privacyInfoSheet
            }
            .sheet(isPresented: $showExportShare) {
                exportShareSheet
            }
            .alert("Restart to Apply Language", isPresented: $showLanguageRestartAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The new language takes effect the next time you open Agile Self.")
            }
            .alert("Notifications Are Off", isPresented: $showNotificationsDeniedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Turn on notifications for Agile Self in iOS Settings to get your daily check-in reminder.")
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
                        .onChange(of: reminderEnabled) { _, newValue in
                            // Ignore programmatic reverts/reconciliation; only act on real taps.
                            if isSyncingReminder {
                                isSyncingReminder = false
                                return
                            }
                            setReminder(enabled: newValue)
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
                            rescheduleReminderTime()
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

    // MARK: - AI & Privacy Section

    private var aiPrivacySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(title: "AI & PRIVACY")

            VStack(spacing: 0) {
                // On-device AI status (honest: insights run locally; cloud AI is not used yet,
                // so we don't show an editable toggle for a deferred feature).
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "cpu")
                            .font(.callout)
                            .foregroundStyle(Theme.Colors.accentEnd)
                            .frame(width: 24, height: 24)

                        Text("On-Device AI")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Spacer()

                        Text("Active")
                            .pillStyle(color: Theme.Colors.success)
                    }

                    Text("Your insights are generated privately on this device. Nothing is sent to the cloud.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .padding(.leading, 24 + Theme.Spacing.md)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("On-device AI is active. Your insights are generated privately on this device.")

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
                // HealthKit row — reflect the REAL authorization state. HealthKit never
                // reports read access directly, so isAuthorized is true only after a fetch
                // returned at least one metric (see HealthKitService.fetchTodaySnapshot).
                let healthConnected = appContainer.healthKitService.isAuthorized
                statusRow(
                    icon: "heart.fill",
                    iconColor: .red,
                    label: "Health Data",
                    statusText: healthConnected ? "Connected" : "Not connected",
                    statusColor: healthConnected ? Theme.Colors.success : Theme.Colors.textTertiary
                )

                settingsDivider

                // Screen Time row — Family Controls / DeviceActivity requires a paid Apple
                // Developer Program membership and is not enabled on this build, so report
                // the truth rather than a fake "Connected".
                statusRow(
                    icon: "hourglass",
                    iconColor: .cyan,
                    label: "Screen Time",
                    statusText: "Not available",
                    statusColor: Theme.Colors.textTertiary
                )
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
                // Build the JSON lazily on tap (not on every Settings open) — serializing the
                // whole store eagerly each appearance was wasteful.
                Button {
                    exportFile = appContainer.dataManagementService.exportFile(context: modelContext)
                    showExportShare = true
                } label: {
                    dataRowLabel(icon: "square.and.arrow.up", title: "Export Data", trailing: "JSON", iconColor: Theme.Colors.success)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Export data")
                .accessibilityHint("Prepares your data as a JSON file to share")

                Divider()
                    .overlay(Theme.Colors.divider)
                    .padding(.leading, Theme.Spacing.md + 24 + Theme.Spacing.md)

                // Backfills real Apple Health history (sleep, steps, activity) for the last 30
                // days so past check-ins have real metrics to correlate against — not just today.
                Button {
                    Task { await importAppleHealthHistory() }
                } label: {
                    dataRowLabel(
                        icon: "heart.text.square.fill",
                        title: "Import Apple Health",
                        trailing: isImportingHealth ? "…" : nil,
                        iconColor: Theme.Colors.heartRate
                    )
                }
                .buttonStyle(.plain)
                .disabled(isImportingHealth)
                .accessibilityLabel("Import Apple Health history")
                .accessibilityHint("Backfills your past sleep, steps, and activity for correlations")

                Divider()
                    .overlay(Theme.Colors.divider)
                    .padding(.leading, Theme.Spacing.md + 24 + Theme.Spacing.md)

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    dataRowLabel(icon: "trash.fill", title: "Delete All Data", trailing: nil, iconColor: Theme.Colors.error)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete all data")
                .accessibilityHint("Permanently deletes all your data on this device")
            }
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        }
        .alert(
            "Apple Health",
            isPresented: Binding(
                get: { healthImportMessage != nil },
                set: { if !$0 { healthImportMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { healthImportMessage = nil }
        } message: {
            Text(healthImportMessage ?? "")
        }
    }

    /// Imports the last 30 days of real Apple Health data and reports how many days landed.
    private func importAppleHealthHistory() async {
        guard !isImportingHealth else { return }
        isImportingHealth = true
        let imported = await appContainer.healthKitService.importRecentHistory(days: 30, context: modelContext)
        isImportingHealth = false
        healthImportMessage = imported > 0
            ? "Imported \(imported) day\(imported == 1 ? "" : "s") of Apple Health data."
            : "No Apple Health data was available to import. Make sure Health access is allowed for Agile Self."
    }

    private func dataRowLabel(icon: String, title: String, trailing: String?, iconColor: Color) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)

            Text(title)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .contentShape(Rectangle())
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

                        Text("All your check-in data, health metrics, and action items are stored locally on your device using SwiftData. Your data stays on your device.")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Label("On-Device AI", systemImage: "cpu")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("Your insights, patterns, and connections are generated on this device using Apple's on-device intelligence. Your reflections and health data are never sent to a server for AI analysis.")
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
                        Label("No Cloud Sync", systemImage: "iphone.and.arrow.forward")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("Your data is stored locally on this device. Nothing is synced to the cloud, so it stays with you. If you remove the app, its data is removed too.")
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

    // MARK: - Export Share Sheet

    @ViewBuilder
    private var exportShareSheet: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Spacer()
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.Colors.success)

                Text("Your data is ready")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("A JSON file with all your check-ins, health data, reports, and actions.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)

                if let exportFile {
                    ShareLink(item: exportFile, preview: SharePreview("Agile Self Data Export")) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share JSON")
                        }
                        .primaryButtonStyle()
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                } else {
                    Text("Couldn't prepare the export. Please try again.")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.warning)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showExportShare = false }
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
                .accessibilityAddTraits(.isHeader)

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
        // Guard the programmatic flip so loading the profile never re-fires setReminder via
        // the Toggle's onChange (only set the flag when the value will actually change, so it
        // isn't left stuck true on a no-op load).
        isSyncingReminder = (reminderEnabled != profile.notificationsEnabled)
        reminderEnabled = profile.notificationsEnabled

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

    /// Persists the chosen reminder time onto the profile (without touching scheduling).
    private func persistReminderTime() {
        guard let profile else { return }
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        profile.checkInReminderHour = components.hour ?? 21
        profile.checkInReminderMinute = components.minute ?? 0
    }

    /// Turning the daily reminder on/off ACTUALLY schedules or cancels the notification (and
    /// requests authorization when enabling). If permission is denied, the toggle reverts so
    /// it reflects reality.
    private func setReminder(enabled: Bool) {
        guard let profile else { return }
        persistReminderTime()

        if enabled {
            Task {
                let granted = await appContainer.notificationService.requestAuthorization()
                if granted {
                    profile.notificationsEnabled = true
                    appContainer.notificationService.scheduleDailyReminder(
                        hour: profile.checkInReminderHour,
                        minute: profile.checkInReminderMinute
                    )
                } else {
                    profile.notificationsEnabled = false
                    isSyncingReminder = true
                    reminderEnabled = false
                    appContainer.notificationService.cancelAll()
                    showNotificationsDeniedAlert = true
                }
            }
        } else {
            profile.notificationsEnabled = false
            appContainer.notificationService.cancelAll()
        }
    }

    /// Brings the in-app reminder state in line with the OS: if the user revoked notifications
    /// in iOS Settings while the app thought the reminder was on, turn it off (and clear any
    /// stale pending request) so the toggle never falsely claims an active reminder.
    private func reconcileReminderWithSystem() async {
        guard let profile, profile.notificationsEnabled else { return }
        let authorized = await appContainer.notificationService.isAuthorized()
        guard !authorized else { return }
        profile.notificationsEnabled = false
        isSyncingReminder = true
        reminderEnabled = false
        appContainer.notificationService.cancelAll()
    }

    /// Reschedules the reminder at the new time when it is enabled; otherwise just persists it.
    private func rescheduleReminderTime() {
        guard let profile else { return }
        persistReminderTime()
        guard reminderEnabled else { return }
        appContainer.notificationService.scheduleDailyReminder(
            hour: profile.checkInReminderHour,
            minute: profile.checkInReminderMinute
        )
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(MockData.previewContainer)
        .environment(AppContainer(modelContainer: MockData.previewContainer))
        .preferredColorScheme(.dark)
}
