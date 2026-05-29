//
//  WeeklyConversationView.swift
//  agile-self
//
//  Chat-style AI coaching conversation for the weekly review.
//

import SwiftUI
import SwiftData

// MARK: - WeeklyConversationView

struct WeeklyConversationView: View {
    let checkIns: [DailyCheckIn]
    let review: WeeklyReview?
    let onComplete: () -> Void

    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    @State private var messages: [ConversationMessage] = []
    @State private var questions: [String] = []
    @State private var inputText = ""
    @State private var isAITyping = false
    @FocusState private var isInputFocused: Bool

    private let quickResponses: [String] = [
        "I felt more energized",
        "Work was stressful",
        "I exercised regularly",
        "Better sleep helped",
        "I need to improve",
    ]

    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                messageList
                quickResponseSection
                inputBar
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await seedOpeningQuestion()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("AI Review")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Week in Review")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            Button(action: onComplete) {
                Text("Done")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.accentStart)
            }
            .accessibilityLabel("Finish conversation")
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.md) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    if isAITyping {
                        typingIndicator
                            .id("typing")
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in
                withAnimation(Theme.Animation.chatMessage) {
                    if let lastMessage = messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Quick Responses

    private var quickResponseSection: some View {
        Group {
            if !isInputFocused {
                QuickResponseChipRow(
                    suggestions: quickResponses,
                    onSelect: { response in
                        sendMessage(response)
                    }
                )
                .padding(.vertical, Theme.Spacing.sm)
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            TextField("Type your response...", text: $inputText, axis: .vertical)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1...4)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xl))
                .focused($isInputFocused)

            Button {
                guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                sendMessage(inputText)
                inputText = ""
            } label: {
                Image(systemName: "arrow.up")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Theme.Colors.accentGradient)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.backgroundPrimary)
    }

    // MARK: - Typing Indicator

    @State private var typingDot1 = false
    @State private var typingDot2 = false
    @State private var typingDot3 = false

    private var typingIndicator: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundStyle(Theme.Colors.accentStart)

            HStack(spacing: 4) {
                Circle()
                    .fill(Theme.Colors.textTertiary)
                    .frame(width: 6, height: 6)
                    .offset(y: typingDot1 ? -4 : 0)
                Circle()
                    .fill(Theme.Colors.textTertiary)
                    .frame(width: 6, height: 6)
                    .offset(y: typingDot2 ? -4 : 0)
                Circle()
                    .fill(Theme.Colors.textTertiary)
                    .frame(width: 6, height: 6)
                    .offset(y: typingDot3 ? -4 : 0)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            withAnimation(Theme.Animation.typewriterDot) {
                typingDot1 = true
            }
            withAnimation(Theme.Animation.typewriterDot.delay(0.15)) {
                typingDot2 = true
            }
            withAnimation(Theme.Animation.typewriterDot.delay(0.30)) {
                typingDot3 = true
            }
        }
        .accessibilityLabel("AI is typing")
    }

    // MARK: - Actions

    /// Restores a persisted transcript, or seeds the opening question from the
    /// on-device question bank. The questions are a fixed opening-question bank — they
    /// are NOT per-turn AI reasoning.
    private func seedOpeningQuestion() async {
        // Always (re)load the question bank so reply-indexed follow-ups work after restore.
        questions = (try? await appContainer.aiService.generateWeeklyQuestions(checkIns: checkIns, health: [])) ?? []

        // Restore an existing transcript if one was saved.
        if let existing = review?.conversations, !existing.isEmpty {
            messages = existing
            return
        }

        // Fresh conversation: open with the first banked question.
        guard let opening = questions.first else { return }
        withAnimation(Theme.Animation.chatMessage) {
            messages = [ConversationMessage(role: .assistant, content: opening)]
        }
        persist()
    }

    private func sendMessage(_ text: String) {
        let userMessage = ConversationMessage(role: .user, content: text)
        withAnimation(Theme.Animation.chatMessage) {
            messages.append(userMessage)
        }
        persist()

        withAnimation(Theme.Animation.standard) {
            isAITyping = true
        }

        Task {
            // Brief, natural pacing delay — the next line is the next banked question,
            // indexed by the user's reply count (not assistant count).
            try? await Task.sleep(for: .milliseconds(700))
            withAnimation(Theme.Animation.standard) {
                isAITyping = false
            }

            let userReplies = messages.filter { $0.role == .user }.count
            let nextContent = userReplies < questions.count
                ? questions[userReplies]
                : "Anything else you'd like to add before we wrap up?"

            withAnimation(Theme.Animation.chatMessage) {
                messages.append(ConversationMessage(role: .assistant, content: nextContent))
            }
            persist()
        }
    }

    /// Persists the current transcript onto the shared WeeklyReview model.
    private func persist() {
        review?.setConversations(messages)
        try? modelContext.save()
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ConversationMessage

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: Theme.Spacing.xxl) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: Theme.Spacing.xs) {
                if !isUser {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.accentStart)

                        Text("AI Coach")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                Text(message.content)
                    .font(Theme.Typography.body)
                    .foregroundStyle(isUser ? .white : Theme.Colors.textPrimary)
                    .multilineTextAlignment(isUser ? .trailing : .leading)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        isUser
                            ? AnyShapeStyle(Theme.Colors.accentStart.opacity(0.6))
                            : AnyShapeStyle(Theme.Colors.backgroundSecondary)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            }

            if !isUser { Spacer(minLength: Theme.Spacing.xxl) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isUser ? "You" : "AI Coach"): \(message.content)")
    }
}

// MARK: - Preview

#Preview {
    WeeklyConversationView(
        checkIns: MockData.weeklyCheckIns,
        review: MockData.weeklyReview,
        onComplete: {}
    )
    .modelContainer(MockData.previewContainer)
    .environment(AppContainer(modelContainer: MockData.previewContainer))
}
