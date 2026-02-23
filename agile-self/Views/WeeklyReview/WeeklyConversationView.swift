//
//  WeeklyConversationView.swift
//  agile-self
//
//  Chat-style AI coaching conversation for the weekly review.
//

import SwiftUI

// MARK: - WeeklyConversationView

struct WeeklyConversationView: View {
    let onComplete: () -> Void

    @State private var messages: [ConversationMessage] = []
    @State private var inputText = ""
    @State private var isAITyping = false
    @FocusState private var isInputFocused: Bool

    private let mockConversation: [ConversationMessage] = {
        [
            ConversationMessage(role: .assistant, content: "Great week, Tetsuya! Your overall score averaged 7.4 - that's up from 6.8 last week. What do you think drove the improvement?"),
            ConversationMessage(role: .user, content: "I think running regularly helped my energy a lot"),
            ConversationMessage(role: .assistant, content: "The data supports that. On days you ran, your energy was 1.8 points higher on average. Your focus also improved by 1.2 points on run days. Want to set a running target for next week?"),
            ConversationMessage(role: .user, content: "Yes, I'd like to run at least 3 times"),
            ConversationMessage(role: .assistant, content: "Perfect. I noticed your stress peaked on Wednesday (7/10). What happened?"),
            ConversationMessage(role: .user, content: "Back-to-back meetings all day, no breaks"),
        ]
    }()

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
        .onAppear {
            loadMockMessages()
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

    private func loadMockMessages() {
        // Stagger the initial messages for a natural feel
        for (index, message) in mockConversation.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                withAnimation(Theme.Animation.chatMessage) {
                    messages.append(message)
                }
            }
        }
    }

    private func sendMessage(_ text: String) {
        let userMessage = ConversationMessage(role: .user, content: text)
        withAnimation(Theme.Animation.chatMessage) {
            messages.append(userMessage)
        }

        // Simulate AI typing
        withAnimation(Theme.Animation.standard) {
            isAITyping = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(Theme.Animation.standard) {
                isAITyping = false
            }

            let aiResponse = ConversationMessage(
                role: .assistant,
                content: "That's a great observation. Let me note that as an action item for next week. Is there anything else you'd like to focus on?"
            )
            withAnimation(Theme.Animation.chatMessage) {
                messages.append(aiResponse)
            }
        }
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
    WeeklyConversationView(onComplete: {})
}
