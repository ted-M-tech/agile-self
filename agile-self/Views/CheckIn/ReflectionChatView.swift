//
//  ReflectionChatView.swift
//  agile-self
//
//  Lightweight, chatbot-style reflection shown right after a check-in is saved. The on-device
//  AI asks a warm opener and ONE context-aware follow-up, then distills the answers into a
//  single "moment worth keeping" line stored on the check-in's note. Fully skippable.
//

import SwiftUI

// MARK: - Chat message model

private struct ReflectionMessage: Identifiable, Equatable {
    enum Role { case bot, user }
    let id = UUID()
    let role: Role
    let text: String
}

// MARK: - ReflectionChatView

struct ReflectionChatView: View {
    let checkIn: DailyCheckIn
    let reflectionService: ReflectionService
    /// Called with the distilled note (or nil when the user skips with nothing to keep).
    let onFinish: (String?) -> Void

    @State private var messages: [ReflectionMessage] = []
    @State private var answers: [String] = []
    @State private var input = ""
    /// 0 = awaiting first answer, 1 = awaiting follow-up answer, 2 = finishing.
    @State private var step = 0
    @State private var isThinking = false
    @State private var isFinishing = false
    @FocusState private var inputFocused: Bool

    private let opener = "How was your day? Anything worth holding onto?"

    var body: some View {
        ZStack {
            Theme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                transcript
            }
        }
        .safeAreaInset(edge: .bottom) { inputBar }
        .task {
            if messages.isEmpty {
                messages = [ReflectionMessage(role: .bot, text: opener)]
                inputFocused = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.Colors.accentStart)
                    Text("Reflect")
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                Text("Your scores are saved. Capture a moment if you like.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            Button("Skip") { finish(skipped: true) }
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .disabled(isFinishing)
                .accessibilityHint("Save the check-in without a reflection note")
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Transcript

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    ForEach(messages) { message in
                        bubble(message)
                            .id(message.id)
                    }
                    if isThinking {
                        typingIndicator.id("typing")
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
            }
            .onChange(of: messages) { _, _ in
                if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
            }
            .onChange(of: isThinking) { _, thinking in
                if thinking { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
            }
        }
    }

    private func bubble(_ message: ReflectionMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: Theme.Spacing.xl) }
            Text(message.text)
                .font(Theme.Typography.body)
                .foregroundStyle(message.role == .user ? .white : Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    message.role == .user
                        ? AnyShapeStyle(Theme.Colors.accentGradient)
                        : AnyShapeStyle(Theme.Colors.backgroundSecondary)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            if message.role == .bot { Spacer(minLength: Theme.Spacing.xl) }
        }
    }

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Theme.Colors.textTertiary)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            Spacer(minLength: Theme.Spacing.xl)
        }
        .accessibilityLabel("Thinking")
    }

    // MARK: - Input bar

    private var inputBar: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if isFinishing {
                ProgressView().tint(Theme.Colors.accentStart)
            } else {
                HStack(spacing: Theme.Spacing.sm) {
                    TextField("Type a few words…", text: $input, axis: .vertical)
                        .lineLimit(1...4)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .focused($inputFocused)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
                        .submitLabel(.send)
                        .onSubmit(send)

                    Button(action: send) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundStyle(canSend ? Theme.Colors.accentStart : Theme.Colors.textTertiary)
                    }
                    .disabled(!canSend)
                    .accessibilityLabel("Send")
                }

                if !answers.isEmpty {
                    Button { finish(skipped: false) } label: {
                        Text("Done — save this reflection")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Colors.accentStart)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm)
        .background(.ultraThinMaterial)
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking && !isFinishing
    }

    // MARK: - Actions

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking, !isFinishing else { return }
        messages.append(ReflectionMessage(role: .user, text: text))
        answers.append(text)
        input = ""

        if step == 0 {
            step = 1
            isThinking = true
            Task {
                let question = await reflectionService.followUp(checkIn: checkIn, firstAnswer: text)
                isThinking = false
                messages.append(ReflectionMessage(role: .bot, text: question))
                inputFocused = true
            }
        } else {
            // Second answer captured — distill and finish.
            finish(skipped: false)
        }
    }

    private func finish(skipped: Bool) {
        guard !isFinishing else { return }
        inputFocused = false
        if answers.isEmpty {
            onFinish(nil)
            return
        }
        isFinishing = true
        Task {
            let summary = await reflectionService.summarize(checkIn: checkIn, answers: answers)
            let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
            onFinish(trimmed.isEmpty ? nil : trimmed)
        }
    }
}

// MARK: - Preview

#Preview {
    ReflectionChatView(
        checkIn: DailyCheckIn(energyScore: 4, focusScore: 4, stressScore: 3, growthScore: 5),
        reflectionService: ReflectionService(),
        onFinish: { _ in }
    )
    .preferredColorScheme(.dark)
}
