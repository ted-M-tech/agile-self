# Agile Self v2 - Product Specification

> **Version**: 2.0 (Full Rebuild)
> **Date**: 2026-02-22
> **Status**: Design First - UI/UX Prototype Phase

---

## 1. Product Vision

### Tagline
**"Your AI Growth Partner"**

### Motto
**"Turn Reflection Into Action"**

### Elevator Pitch
Agile Self は、毎日15秒のスコアリングと Apple Health/Screen Time のデータを組み合わせ、AI が週次・月次で「定量×定性」のハイブリッド分析を行うセルフ振り返りアプリ。意識の高いビジネスパーソンの自己成長を、データドリブンにサポートする。

### Target User
- **20-30代の意識が高い社会人**
- キャリアアップ・自己成長に貪欲
- Apple Watch / iPhone ヘビーユーザー
- ランニングやワークアウトの習慣がある or 始めたい
- 振り返り習慣を定着させたいが、時間がない

### Differentiation (vs Apple Journal)
1. **構造化された振り返り** - 自由記述ではなく4軸スコアリングで成長を可視化
2. **AI分析力** - 定量データ(健康・スクリーンタイム)×定性データ(振り返り)の相関分析
3. **アクション指向** - 振り返りで終わらず、具体的なアクションアイテムに落とし込む

---

## 2. Core Framework: Daily / Weekly / Monthly Hybrid

KPTAフレームワークを進化させ、3層のリズムで振り返りを構造化する。

| Layer | Frequency | Time | Method | AI Role |
|-------|-----------|------|--------|---------|
| **Daily** | 毎日 | 15秒 | 4軸スコアカード + 任意メモ | オンデバイスで感情分析・ミニインサイト生成 |
| **Weekly** | 週1回 | 3-5分 | AIとの会話形式レビュー | Gemini APIで深い質問・パターン発見・アクション提案 |
| **Monthly** | 月1回 | 自動生成 | AIレポート | Gemini APIでトレンド分析・相関発見・成長レポート |

### Daily Check-in (4 Dimensions)
| Dimension | Color | Question | Scale |
|-----------|-------|----------|-------|
| **Energy** | Gold (#FDCB6E) | "How's your energy today?" | 1-10 |
| **Focus** | Sky Blue (#74B9FF) | "How focused were you?" | 1-10 |
| **Stress** | Coral (#FF6B6B) | "Stress level?" | 1-10 (low=good) |
| **Growth** | Mint (#55EFC4) | "Did you grow today?" | 1-10 |

+ Optional free-text note (max 280 chars)

### Weekly Review (AI Conversation)
- AI が1週間のデータを分析し、4-6個の質問をチャット形式で投げかける
- Quick Response チップで簡単に回答可能
- 完了後にサマリー生成: Wins / Challenges / Next Actions
- アクションアイテムを自動抽出

### Monthly Report (Auto-generated)
- 全自動でAIがレポートを生成
- 総合スコア推移、各軸トレンド、相関分析
- ヒートマップカレンダー、成長メトリクス
- エグゼクティブサマリー（2-3段落の叙述）

---

## 3. Design System

### Theme: Premium Dark

```
PALETTE
────────────────────────────────────────
Background Primary:   #0A0A0F  (near-black, blue undertone)
Background Secondary: #13131A  (card surfaces)
Background Tertiary:  #1C1C26  (elevated cards, sheets)
Accent Gradient:      #6C5CE7 → #A29BFE  (primary purple)

Dimension Colors:
  Energy:   #FDCB6E  (warm gold)
  Focus:    #74B9FF  (sky blue)
  Stress:   #FF6B6B  (coral red)
  Growth:   #55EFC4  (mint green)

Text Primary:    #F0F0F5  (95% white)
Text Secondary:  #8888A0  (muted lavender-gray)
Text Tertiary:   #55556A  (subtle labels)
Divider:         #FFFFFF0A

Semantic:
  Success:  #00B894  (emerald)
  Warning:  #E17055  (burnt orange)

TYPOGRAPHY (SF Pro Rounded + SF Pro Text)
────────────────────────────────────────
Display:   SF Pro Rounded Bold 34pt     (hero numbers)
Title 1:   SF Pro Rounded Semibold 28pt
Title 2:   SF Pro Rounded Semibold 22pt
Title 3:   SF Pro Rounded Medium 20pt
Headline:  SF Pro Text Semibold 17pt
Body:      SF Pro Text Regular 17pt
Callout:   SF Pro Text Regular 16pt
Subhead:   SF Pro Text Regular 15pt
Footnote:  SF Pro Text Regular 13pt
Caption:   SF Pro Text Regular 12pt

SPACING SCALE
────────────────────────────────────────
xs: 4  sm: 8  md: 16  lg: 24  xl: 32  xxl: 48

CORNER RADII
────────────────────────────────────────
small: 8  medium: 12  large: 16  xl: 20  pill: 999
```

### Design References
- **Athlytic** - ヘルスデータの表示方法、プレミアム感
- **Gentler Streak** - ミニマルで美しいヘルスカード
- **Oura Ring** - ダークテーマのリング/チャート表現
- **Linear** - クリーンなUI、ミニマルなインタラクション

---

## 4. Screen Designs

### Navigation (3 Tabs)
| Tab | Label | Icon | Content |
|-----|-------|------|---------|
| 1 | Home | house.fill | Dashboard + Check-in CTA |
| 2 | Insights | chart.line.uptrend.xyaxis | トレンド/チャート/相関分析 |
| 3 | Profile | person.fill | 設定/ストリーク/サブスク管理 |

### 4.1 Onboarding (4 Screens)

**Screen 1: Welcome**
- ロゴアニメーション（4色のパーティクルが集合）
- "AGILE SELF" + "Turn Reflection Into Action"
- Get Started ボタン（アクセントグラデーション）

**Screen 2: How It Works**
- Daily (15sec) / Weekly (3-5min) / Monthly (auto) の3カード
- 上から下への接続線アニメーション
- 各カードにゴールド/ブルー/ミントのアクセントボーダー

**Screen 3: Permissions**
- Apple Health / Screen Time / Nike Run Club / Notifications のトグル
- 各トグルがシステム権限ダイアログをトリガー
- 「You can change these later in Settings」
- Continueは常に有効（権限はオプション）

**Screen 4: First Check-in Prompt**
- スパークルアニメーション
- "Start First Check-in" → Daily Check-in フローへ
- "Skip for now" → Home Dashboard へ

### 4.2 Home Dashboard

```
┌─────────────────────────────────┐
│ Good evening, Tetsuya       ⚙️  │
│ Sunday, Feb 22                  │
│                                 │
│ ┌─ 7-DAY SCORE TREND ─────────┐│
│ │  ▁▂▄▃▅▇█  Today: 7.4 ▲0.3  ││
│ │  M T W T F S S              ││
│ └─────────────────────────────┘│
│                                 │
│ ┌──────────┐ ┌──────────┐      │
│ │☀ ENERGY  │ │🎯 FOCUS   │      │
│ │  [ring]  │ │  [ring]  │      │
│ │  7/10    │ │  6/10    │      │
│ └──────────┘ └──────────┘      │
│ ┌──────────┐ ┌──────────┐      │
│ │😤 STRESS │ │🌱 GROWTH  │      │
│ │  [ring]  │ │  [ring]  │      │
│ │  3/10    │ │  9/10    │      │
│ └──────────┘ └──────────┘      │
│                                 │
│ ┌─ 💡 AI INSIGHT ─────────────┐│
│ │ "Your focus tends to dip on  ││
│ │  Wednesdays. Consider a      ││
│ │  midweek reset ritual."      ││
│ └─────────────────────────────┘│
│                                 │
│ TODAY'S HEALTH (horizontal scroll)│
│ ┌──────┐┌──────┐┌──────┐┌──────┐│
│ │🛏7h23m││🚶8,421││❤️62bpm││📱3h12m│
│ └──────┘└──────┘└──────┘└──────┘│
│                                 │
│ ┌─ ✏️ Log Today's Score ──────┐│
│ └─────────────────────────────┘│
│                                 │
├──────────┬──────────┬───────────┤
│ 🏠 Home  │📈Insights│ 👤Profile │
└──────────┴──────────┴───────────┘
```

**Interactions:**
- Pull-to-refresh でヘルスデータ更新 + ハプティック
- 7日トレンドチャートは Swift Charts でグラデーション塗り（左→右描画アニメ）
- 各ディメンションカードタップ → 30日トレンドシート
- Check-in CTAは20時以降で未入力なら脈動アニメーション
- ヘルスカードは水平スクロール (.scrollTargetBehavior(.viewAligned))

### 4.3 Daily Check-in

**Screen 3A: Scorecard Entry** (Full screen sheet)
- 4つのディメンションカード、各1-10の水平ナンバーピッカー
- タップまたは水平ドラッグで選択、選択時ライトハプティック
- タイマーバッジ（右上、経過秒数表示）
- "+Add a note" タップで TextEditor 展開
- "Save Check-in" で確認画面へ

**Screen 3B: Confirmation**
- アニメーションチェックマーク + パーティクルバースト
- "Logged in 12s" 表示
- スコアサマリー行 + 前日比デルタ
- AIミクロインサイト（オンデバイス生成）
- 5秒後に自動dismiss

### 4.4 Weekly Review

**Screen 4A: Intro**
- 週間データサマリー（スパークライン + 各軸バーチャート）
- "Start AI Review ~3-5min" ボタン
- "Skip & view summary →" リンク

**Screen 4B: AI Conversation**
- チャットUI (ScrollViewReader)
- AI messages: 左寄せ、ダークカード、タイプライターエフェクト
- User messages: 右寄せ、アクセントパープル半透明
- Quick Response チップ（横スクロール）
- テキスト入力 + 送信ボタン（アクセントグラデーション円形）
- AI が4-6問質問後にサマリー生成

**Screen 4C: Weekly Summary**
- Wins（ミント左ボーダー）/ Challenges（コーラル左ボーダー）/ Actions（ブルー左ボーダー）
- AI Takeaway（アクセントグラデーションボーダー）
- アクションアイテムはチェックボックス付き
- "Share Summary" → UIActivityViewController

### 4.5 Monthly Report

- 総合スコアゲージ（大きなリング）
- 4軸トレンドチャート（30日折れ線、各ディメンションカラー）
- ヒートマップカレンダー（GitHub contribution graph風）
- 相関カード（"Sleep↑ = Focus↑"）
- エグゼクティブサマリー
- "Share Report" ボタン

### 4.6 Insights Tab

- 期間セレクター: Week / Month / Quarter / Year
- スコアトレンドチャート（メイン）
- ヘルスデータ相関マトリクス
- AI発見のパターンカード
- ストリーク情報

### 4.7 Profile Tab

- ストリークカウント + カレンダービュー
- アクションアイテムリスト（Active / Completed）
- サブスクリプション管理
- データ設定（HealthKit / Screen Time / Notifications）
- テーマ設定
- エクスポート（JSON / PDF）
- About

### 4.8 Widget Designs

**Small Widget:**
```
┌─────────────┐
│ Today  7.4  │
│ ☀7 🎯6 😤3 🌱9│
│ 🔥 12-day   │
└─────────────┘
```

**Medium Widget:**
```
┌─────────────────────────┐
│ Agile Self    7.4 ▲0.3  │
│ ▁▂▄▃▅▇█               │
│ M T W T F S S          │
│ ☀7  🎯6  😤3  🌱9      │
│ 🔥 12-day streak       │
└─────────────────────────┘
```

**Large Widget:**
```
┌─────────────────────────┐
│ Agile Self    7.4 ▲0.3  │
│ ▁▂▄▃▅▇█               │
│ ☀7  🎯6  😤3  🌱9      │
│ Sleep 7h23m │ Steps 8.4k│
│ Screen 3h12m│ Run 5.2km │
│ 💡 "Focus dips midweek" │
│ 🔥 12-day  [Check-in ▶] │
└─────────────────────────┘
```

### 4.9 Smart Notifications

| Type | Trigger | Example |
|------|---------|---------|
| Daily Reminder | ユーザー設定時刻 + 未入力 | "Ready for your 15-second check-in?" |
| Data-driven | 睡眠データ取得後 | "Last night's sleep: 7h23m. How's your energy today?" |
| Weekly Nudge | 設定した曜日(デフォルト金曜) | "Your week's data is ready. Let's review together." |
| Streak Alert | 連続記録が途切れそうな時 | "Don't break your 12-day streak! Quick check-in?" |
| Insight | AI が面白い相関を発見 | "Interesting: your focus scores are 23% higher on run days." |

---

## 5. Technical Architecture

### 5.1 Tech Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Language | Swift | 5.0 (Approachable Concurrency) |
| UI | SwiftUI | iOS 26.1+ |
| Data | SwiftData | iOS 26+ |
| Cloud Sync | CloudKit (via SwiftData) | Deferred to M6 (`cloudKitDatabase = .none`) |
| Health | HealthKit | Free-account ✅ |
| Screen Time | DeviceActivity / FamilyControls | Deferred (paid/uncertain) |
| Charts | Swift Charts | - |
| AI (on-device) | Foundation Models + NaturalLanguage | iOS 26.1+ |
| AI (cloud) | Gemini API | Deferred (behind `allowCloudAI`) |
| Subscription | StoreKit 2 | local `.storekit` config |
| Widget | WidgetKit | App Group `group.tetsuya.agile-self` |
| Notifications | UserNotifications | local-only |
| Min iOS | **26.1** | - |

### 5.2 Architecture Pattern

**Unidirectional Data Flow:**
```
Views → ViewModels → Services → SwiftData Models
  ↑                                    │
  └────────── @Observable ─────────────┘
```

**Dependency Injection via AppContainer:**
```swift
@Observable  // nonisolated by default — no SWIFT_DEFAULT_ACTOR_ISOLATION
final class AppContainer {
    let modelContainer: ModelContainer
    lazy var healthKitService = HealthKitService()
    lazy var screenTimeService = ScreenTimeService()
    lazy var aiService: AIServiceProtocol = AIServiceRouter(...)
    lazy var notificationService = NotificationService()
    lazy var analyticsService = AnalyticsService()
    lazy var subscriptionService = SubscriptionService()
    lazy var streakService = StreakService()
}
```

### 5.3 Data Models

```
UserProfile (singleton)
    │
    ├── DailyCheckIn (1 per day)
    │       ├── ScoreDimension[4] (embedded Codable)
    │       └── HealthSnapshot (1:1)
    │
    ├── WeeklyReview (1 per week)
    │       ├── ConversationMessage[] (embedded Codable)
    │       ├── WeeklyInsight[] (embedded Codable)
    │       └── ActionItem[] (1:N relationship)
    │
    ├── MonthlyReport (1 per month)
    │       ├── GrowthMetric[] (embedded Codable)
    │       └── Correlation[] (embedded Codable)
    │
    └── Streak (singleton)
```

**Key Models:**

| Model | Key Fields |
|-------|------------|
| DailyCheckIn | date, scores[4], note?, sentimentScore?, dailyInsight?, healthSnapshot |
| HealthSnapshot | sleepMinutes, steps, activeCalories, exerciseMinutes, restingHeartRate, runningDistanceMeters, screenTimeMinutes |
| WeeklyReview | weekStart/End, conversationMessages[], insights[], summary?, actionItems[], isCompleted |
| MonthlyReport | month, year, executiveSummary?, growthMetrics[], correlations[], topInsight? |
| ActionItem | text, isCompleted, deadline?, priority, source (weeklyReview/manual/aiSuggested) |
| UserProfile | displayName?, checkInReminderTime?, weeklyReviewDay, subscriptionTier, allowCloudAI |
| Streak | currentStreak, longestStreak, lastCheckInDate?, totalCheckIns |

### 5.4 Service Layer

| Service | Responsibility |
|---------|---------------|
| HealthKitService | HealthKit authorization, fetch today's data, build HealthSnapshot |
| ScreenTimeService | FamilyControls authorization, App Group経由でスクリーンタイム取得 |
| AIServiceProtocol | 統一AI interface (OnDevice + Cloud implementations) |
| OnDeviceAIService | NaturalLanguage感情分析 + Foundation Models日次インサイト |
| GeminiAIService | Gemini 2.0 Flash API - 週次会話/月次レポート生成 |
| NotificationService | スマート通知スケジューリング |
| AnalyticsService | トレンド計算、相関検出、集計 |
| SubscriptionService | StoreKit 2 - 購入/復元/エンタイトルメント確認 |
| StreakService | 連続記録トラッキング |

### 5.5 AI Pipeline

```
Daily Check-in Save
    │
    ├─→ NaturalLanguage: 感情分析 (note → sentimentScore)
    ├─→ Foundation Models: 日次インサイト生成 (on-device, free)
    │
Weekly Review (Friday default)
    │
    ├─→ AnalyticsService: 1週間分のデータ集計
    ├─→ GeminiAIService: 会話コンテキスト構築 → チャット形式レビュー
    ├─→ GeminiAIService: アクションアイテム抽出
    │
Monthly Report (月末に自動)
    │
    ├─→ AnalyticsService: 月間データ集計
    └─→ GeminiAIService: レポート生成 (JSON structured output)
```

**Data Anonymization (Cloud AI送信前):**
- ユーザー名は送信しない
- 日付はオフセット化 (Day 1, Day 2...)
- テキストノートのみGeminiに送信、ヘルスデータは数値のみ

### 5.6 Project Structure

```
agile-self/
├── App/
│   ├── agile_selfApp.swift
│   └── AppContainer.swift
│
├── Models/
│   ├── DailyCheckIn.swift
│   ├── HealthSnapshot.swift
│   ├── WeeklyReview.swift
│   ├── MonthlyReport.swift
│   ├── ActionItem.swift
│   ├── ActionPriority.swift
│   ├── UserProfile.swift
│   └── Streak.swift
│
├── Views/
│   ├── Root/
│   │   ├── RootView.swift
│   │   └── MainTabView.swift
│   ├── Onboarding/
│   │   ├── OnboardingContainerView.swift
│   │   ├── WelcomeView.swift
│   │   ├── HowItWorksView.swift
│   │   ├── PermissionsView.swift
│   │   └── FirstCheckInPromptView.swift
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── ScoreTrendChart.swift
│   │   ├── DimensionCard.swift
│   │   ├── AIInsightCard.swift
│   │   └── HealthMetricCard.swift
│   ├── CheckIn/
│   │   ├── DailyCheckInView.swift
│   │   ├── ScoreDimensionPicker.swift
│   │   └── CheckInConfirmationView.swift
│   ├── WeeklyReview/
│   │   ├── WeeklyReviewIntroView.swift
│   │   ├── WeeklyConversationView.swift
│   │   ├── WeeklySummaryView.swift
│   │   └── QuickResponseChip.swift
│   ├── MonthlyReport/
│   │   ├── MonthlyReportView.swift
│   │   ├── HeatmapCalendarView.swift
│   │   └── CorrelationCard.swift
│   ├── Insights/
│   │   ├── InsightsView.swift
│   │   ├── TrendChartView.swift
│   │   └── PatternCard.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   ├── StreakView.swift
│   │   ├── ActionsListView.swift
│   │   └── SubscriptionView.swift
│   └── Settings/
│       └── SettingsView.swift
│
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── CheckInViewModel.swift
│   ├── WeeklyReviewViewModel.swift
│   ├── InsightsViewModel.swift
│   └── ProfileViewModel.swift
│
├── Services/
│   ├── HealthKit/
│   │   └── HealthKitService.swift
│   ├── ScreenTime/
│   │   └── ScreenTimeService.swift
│   ├── AI/
│   │   ├── AIServiceProtocol.swift
│   │   ├── AIServiceRouter.swift
│   │   ├── OnDeviceAIService.swift
│   │   └── GeminiAIService.swift
│   ├── Notifications/
│   │   └── NotificationService.swift
│   ├── Analytics/
│   │   └── AnalyticsService.swift
│   ├── Subscription/
│   │   └── SubscriptionService.swift
│   └── Streak/
│       └── StreakService.swift
│
├── Utilities/
│   ├── Theme.swift
│   ├── KeychainHelper.swift
│   └── Extensions/
│       ├── Date+Extensions.swift
│       └── Color+Extensions.swift
│
├── Localization/
│   ├── en.lproj/Localizable.strings
│   └── ja.lproj/Localizable.strings
│
└── Resources/
    └── Assets.xcassets

ScreenTimeReport/                   (App Extension)
├── ScreenTimeReport.swift
├── TotalActivityReport.swift
└── TotalActivityView.swift

AgileWidget/                        (Widget Extension)
├── AgileWidget.swift
├── SmallWidgetView.swift
├── MediumWidgetView.swift
└── LargeWidgetView.swift
```

### 5.7 Xcode Capabilities Required

| Target | Capabilities |
|--------|-------------|
| agile-self (iOS) | HealthKit, iCloud (CloudKit), Family Controls, Push Notifications, App Groups |
| ScreenTimeReport | Family Controls |
| AgileWidget | App Groups |

---

## 6. Subscription Model

### Tiers

| Feature | Free | Premium |
|---------|------|---------|
| Daily Check-in | Unlimited | Unlimited |
| Basic Dashboard | Full | Full |
| Health Data Display | Full | Full |
| AI Daily Insight (on-device) | Full | Full |
| Weekly AI Review | 2回/月 | Unlimited |
| Monthly Report | Summary only | Full report |
| Trend Charts (30日+) | 7日のみ | Unlimited |
| Correlation Analysis | - | Full |
| Action Items | 3個まで | Unlimited |
| Widget | Basic (small) | All sizes |
| Export (PDF/JSON) | - | Full |

### Pricing (予定)
- Monthly: ¥480 / $3.99
- Yearly: ¥3,800 / $29.99 (34% off)
- Free trial: 14日間全機能開放

### 設計方針
- 最初のユーザーは自分 → まず全機能を実装
- 課金壁はリリース直前に設置
- AI は一定量まで無料で使わせる（体験を損なわない）
- 赤字にならないよう Gemini API 無料枠の範囲でFreeプラン設計

---

## 7. Privacy & Data Policy

### ローカルファースト
- 全データは SwiftData でデバイス内に保存
- iCloud/CloudKit での端末間同期はオプション（Apple管理の暗号化）
- ユーザーアカウント不要（Apple ID経由のiCloudのみ）

### AI データ送信
- オンデバイスAI処理が優先（NaturalLanguage + Foundation Models）
- Cloud AI (Gemini) 送信時は匿名化:
  - ユーザー名なし
  - 日付はオフセット化
  - テキスト + 数値データのみ
- ユーザーの明示的同意が必要 (`allowCloudAI` フラグ)
- 送信データはリクエスト単位で消去（学習に使われない）

### 明示表示
- "Your data stays on your device. We never sell your data."
- AIデータ送信時に都度確認 or 設定で一括許可

---

## 8. Localization

| 言語 | Status |
|------|--------|
| 英語 (en) | v1.0 |
| 日本語 (ja) | v1.0 |

- UIテキストは全て Localizable.strings で管理
- AI の応答言語はデバイスのロケールに合わせる
- 日付/数値フォーマットはロケール自動対応

---

## 9. Branding Proposals

現在名「Agile Self」に加え、以下の候補も検討:

| Name | Concept | Domain/App Store |
|------|---------|-----------------|
| **Agile Self** (現行) | アジャイル開発×自己成長 | エンジニア層に刺さる |
| **Stride** | 前進、一歩ずつの成長 | 幅広い層にアピール |
| **Cadence** | リズム、周期的な振り返り | プレミアム感 |
| **Pulse** | 脈拍、毎日のチェックイン | ヘルスデータとの親和性 |

→ 最終決定はデザインプロトタイプ後

---

## 10. Development Phases

### Phase 0: Design Prototype (Current)
- [ ] 全画面のSwiftUIプロトタイプ（モックデータ）
- [ ] デザインシステム (Theme.swift) 確定
- [ ] カラーパレット、タイポグラフィ、アニメーション
- [ ] Xcode Preview で全画面確認

### Phase 1: Core Experience (MVP)
- [ ] DailyCheckIn モデル + Check-in フロー
- [ ] Home Dashboard（トレンドチャート + 4軸カード）
- [ ] HealthKit 連携（睡眠、歩数、心拍、カロリー、ランニング）
- [ ] Screen Time 連携
- [ ] Streak トラッキング
- [ ] オンデバイスAI (感情分析 + Foundation Models インサイト)
- [ ] WidgetKit (Small + Medium)

### Phase 2: AI & Depth
- [ ] Weekly Review (Gemini API 会話)
- [ ] Monthly Report 自動生成
- [ ] 相関分析 (AnalyticsService)
- [ ] Smart Notifications
- [ ] Large Widget
- [ ] ローカライゼーション (日英)

### Phase 3: Monetization & Polish
- [ ] StoreKit 2 サブスクリプション
- [ ] 課金壁の実装
- [ ] エクスポート機能 (PDF/JSON)
- [ ] Share Summary / Report
- [ ] onboarding フロー完成
- [ ] App Store 準備

### Phase 4: Expansion (v1.x)
- [ ] watchOS コンパニオンアプリ
- [ ] iPad 対応
- [ ] Siri Shortcuts / App Intents
- [ ] Live Activities / Dynamic Island

---

## 11. Critical Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| FamilyControls entitlement がAppleに却下される | Screen Time 機能なし | HealthKit の screenTime カテゴリで代替検討 |
| Gemini API 無料枠の制限変更 | AI機能のコスト増 | Claude/OpenAI への切り替え容易な AIServiceProtocol 設計 |
| Foundation Models の成熟度 | 低品質なインサイト | ルールベースフォールバック実装済み |
| iOS 26.1+ の普及率 | ユーザーベース縮小 | ターゲット層は最新OS率が高い |
| Apple Journal との競合 | 差別化の弱さ | 構造化×AI分析で明確な差別化 |
| Subscription fatigue | 低い課金率 | 無料でも十分使える + AI体験で課金動機 |

---

## Appendix: Animation Specification

| Element | Animation | Duration | Easing |
|---------|-----------|----------|--------|
| Trend line draw | Left to right | 1.2s | easeOut |
| Dimension rings | 0 to value | 0.8s (stagger) | spring |
| Health cards | Fade in + translate up | 0.5s (stagger) | easeOut |
| Check-in cards | Stagger from right | 0.1s apart | spring |
| Score selection | Scale 1.2x + fill color | 0.15s | spring |
| AI typing dots | Bounce | 0.15s phase offset | easeInOut |
| Chat messages | Slide up from bottom | 0.3s | spring |
| Checkmark | Path draw + particle burst | 0.6s | easeOut |
| CTA pulse | Scale 0.98-1.02 | 2s loop | easeInOut |
