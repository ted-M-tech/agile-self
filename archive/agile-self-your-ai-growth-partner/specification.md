# Agile Self: Product Specification

## 1. Core Concept & Vision

**Agile Self** is a web application designed for personal self-retrospective. It adapts the agile KPTA framework into a simple, powerful tool for individuals to foster continuous self-improvement with AI-powered insights.

- **Name**: Agile Self
- **Tagline**: Your AI Growth Partner
- **Vision**: To create a private, intuitive space where users can reflect on their life weekly or monthly, identify patterns with AI assistance, and create concrete action plans for growth.
- **Motto**: Turn Reflection Into Action.

---

## 2. Product Features: The KPTA Framework + AI Insights

The product integrates the KPTA (Keep, Problem, Try, Action) framework with AI-powered insights for enhanced personal growth.

### Framework Components

- **Keep**: What went well? What positive habits or events should I continue?
- **Problem**: What obstacles or challenges did I face? What's holding me back?
- **Try**: Based on the 'Problems' and 'Keeps', what is a new approach I can experiment with?
- **Action**: Convert each 'Try' into a specific, concrete to-do item. This is the critical step that distinguishes our app from passive journaling. For example, a 'Try' to "be more organized" becomes an 'Action' to "spend 15 minutes every Sunday planning the week."

### AI-Powered Features

- **Wellbeing Score**: Intelligent scoring (0-100) based on sentiment analysis of your retrospectives
- **Pattern Detection**: Identify recurring themes in problems and keeps across multiple retrospectives
- **Personalized Insights**: AI-generated suggestions and observations about your growth journey
- **Trend Visualization**: Charts showing wellbeing score progression over time
- **Achievement Recognition**: Celebrate consistency and improvement milestones

---

## 3. Core Features

The application includes these core features:

1. **User Accounts**: Secure user registration and login via Supabase Auth with social providers
2. **KPTA Entry Interface**: A modern, responsive interface with separate sections for Keep, Problem, and Try entries
3. **Inline Action Creation**: Create action items directly from Try entries with optional deadlines
4. **Action Items Management**: Track and manage all action items with completion status
5. **AI Dashboard**: Wellbeing score tracking, trend charts, and personalized insights
6. **Retrospective History**: Chronological view of all past sessions with search and filtering
7. **Customizable Reminders**: Browser notifications or email reminders for weekly/monthly retrospectives
8. **Data Export**: Export all data in JSON format at any time

---

## 4. UI/UX Principles

The UI features a modern gradient design with smooth animations and glass-morphism effects.

- **Modern & Vibrant**: Gradient backgrounds (`blue-600` via `indigo-600` to `purple-700`) with backdrop blur effects
- **Responsive & Accessible**: Optimized for desktop and mobile browsers with smooth transitions
- **Intuitive Flow**: The user journey from reflection ('Keep'/'Problem') to action ('Try'/'Action') is visually guided and seamless
- **Engaging Landing Page**: Interactive hero section with feature showcases and "how it works" flow
- **Dashboard-First**: AI insights and wellbeing trends prominently displayed on home screen
- **Smooth Animations**: framer-motion for delightful micro-interactions and page transitions

---

## 5. AI Integration with Gemini API

The AI features are integrated from the start as a core differentiator and the primary driver for the premium tier.

### Technology
Gemini API powers the intelligent analysis and suggestion engine, called via Supabase Edge Functions for security.

### Functionality
The AI acts as a "Personal Growth Co-Pilot" by analyzing retrospective data:

- **Wellbeing Score Calculation**: Combines sentiment analysis with retrospective patterns to generate a 0-100 score
- **Recurring Theme Identification**: Uses NLP to find patterns (e.g., "Sleep issues appear frequently in your retrospectives")
- **Actionable Suggestions**: Based on detected patterns, suggests specific approaches (e.g., "Try the '2-Minute Rule' for procrastination")
- **Sentiment Analysis**: Analyzes emotional tone to track well-being trends over time
- **Achievement Detection**: Recognizes improvements and consistency to celebrate progress
- **Pattern Warnings**: Alerts users to concerning trends that need attention

### Free vs Premium

- **Free Tier**: Basic wellbeing score, limited AI insights (3 per month)
- **Premium Tier**: Full AI analysis, unlimited insights, advanced pattern detection, historical trend analysis

---

## 6. Tech Stack

- **Frontend Framework**: Next.js 14 with React 18+ and TypeScript for type safety, better DX, and SSR capabilities
- **Build Tool**: Next.js built-in compiler for fast development and optimized production builds
- **UI Library**: Tailwind CSS for utility-first styling + shadcn/ui for pre-built components
- **Animation**: framer-motion for smooth, declarative animations
- **Charts**: Recharts for wellbeing trend visualization
- **Backend**: Supabase (PostgreSQL + auto-generated REST APIs + Edge Functions)
- **Database**: PostgreSQL (via Supabase) for relational KPTA data with AI analytics support
- **Authentication**: Supabase Auth with email/password, social providers (Google), and magic links
- **AI Integration**: Gemini API called via Supabase Edge Functions for secure server-side processing
- **Deployment**: Vercel (optimized for Next.js) for automatic deployments from Git

---

## 7. Monetization Strategy

We will adopt a Freemium model to maximize user acquisition and create a clear upgrade path.

- **Free Tier (MVP)**: All core KPTA functionality will be free. This includes unlimited retrospectives, action tracking, and history. The goal is to get users to build the habit.
- **Premium Tier (Phase 2)**: The AI Co-Pilot features (thematic analysis, sentiment tracking, and personalized 'Try' suggestions) will be the core of the paid subscription plan.

---

## 8. Detailed Screen Flows & User Journeys

### 8.1 First-Time User Experience

1. **Landing Page** → Hero section with tagline "Your AI Growth Partner" and feature showcases
2. **How It Works** → 3-step explanation of KPTA framework with visuals
3. **CTA** → "Get Started Free" button → Sign Up modal/page
4. **Sign Up** → Email/password or social OAuth (Google)
5. **Dashboard (Empty State)** → Welcome message with "Create Your First Retrospective" button
6. **First Retrospective** → Guided creation with helpful placeholders and examples

### 8.2 Core User Flow: Creating a KPTA Retrospective

1. **Dashboard/Home Tab** → Click "New Retrospective" button or navigate to "New" tab
2. **New Retrospective Page** (vertical scroll layout):
   - **Card 1: Setup**
     - Select type: Weekly or Monthly (radio buttons)
     - Date pickers for start/end dates (auto-populated)
     - Editable title field (auto-generated but customizable)
   - **Card 2: Keep & Problem** (two-column grid on desktop, stacked on mobile)
     - Keep column (green theme): Textarea inputs with "+ Add Keep" button
     - Problem column (red theme): Textarea inputs with "+ Add Problem" button
   - **Card 3: Try & Actions** (purple theme)
     - Try items with textarea
     - Checkbox to "Create action item" for each Try
     - Date picker for action deadline (optional)
     - "+ Add Try Item" button
   - **Save Button** → Large blue button at bottom
3. **Success Feedback**:
   - Toast notification: "Retrospective saved successfully!"
   - Automatically navigate back to Home/Dashboard tab
   - Dashboard now shows updated wellbeing score and new retrospective in history

### 8.3 Action Items Management Flow

1. **Actions Tab** → Click "Actions" in main navigation
2. **Action List** → All actions displayed with checkboxes
   - Badge showing pending action count in tab
   - Each item shows: checkbox, text, deadline (if set), retrospective link
3. **Filter Tabs**: All / Pending / Completed
4. **Check off action** → Click checkbox to toggle completion (instant update with toast)
5. **Delete** → Click trash icon → Confirmation dialog → Delete
6. **View Source** → Click retrospective ID/title → Navigate to history detail view

### 8.4 History & Review Flow

1. **History Tab** → Click "History" in main navigation
2. **Retrospective Cards** → List view sorted by date (newest first)
   - Each card shows: title, date, KPTA counts, wellbeing score, progress bar
3. **Search Bar** → Type to search across all retrospective text (full-text search)
4. **Card Actions**:
   - Click card → Expand to show full details (keeps, problems, tries, actions)
   - Trash icon → Delete with confirmation dialog
5. **Empty State** → "No retrospectives found" with "Create First Retrospective" button

### 8.5 Settings Flow

1. **Settings Tab** → Click "Settings" in main navigation
2. **Settings Page** organized in cards:
   - **Account**: Display name, email (read-only), avatar upload
   - **Reminders**: Toggle on/off, frequency (weekly/monthly), day of week, time
   - **Notifications**: Browser notifications permission, email reminders toggle
   - **Premium**: Current tier, upgrade button (if free tier)
   - **Data & Privacy**:
     - Export data button → Downloads JSON file
     - Delete account button → Confirmation dialog with warning
   - **About**: App version, links to terms, privacy policy, feedback

---

## 9. Data Models

### 9.1 User Model

**PostgreSQL Schema (Supabase)**:
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_premium BOOLEAN DEFAULT FALSE
);

CREATE TABLE user_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  reminder_enabled BOOLEAN DEFAULT TRUE,
  reminder_frequency TEXT CHECK (reminder_frequency IN ('weekly', 'monthly')),
  reminder_day TEXT,
  reminder_time TIME,
  fcm_token TEXT, -- For push notifications
  timezone TEXT DEFAULT 'UTC',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**JSON Representation**:
```json
{
  "id": "uuid",
  "email": "string",
  "displayName": "string",
  "avatarUrl": "string",
  "createdAt": "timestamp",
  "preferences": {
    "reminderEnabled": "boolean",
    "reminderFrequency": "weekly | monthly",
    "reminderDay": "string",
    "reminderTime": "string"
  },
  "isPremium": "boolean"
}
```

### 9.2 Retrospective Model

**PostgreSQL Schema (Supabase)**:
```sql
CREATE TABLE retrospectives (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  period_type TEXT CHECK (period_type IN ('weekly', 'monthly')),
  period_start_date DATE,
  period_end_date DATE,
  status TEXT CHECK (status IN ('draft', 'completed')) DEFAULT 'draft',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE keeps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  retrospective_id UUID NOT NULL REFERENCES retrospectives(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE problems (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  retrospective_id UUID NOT NULL REFERENCES retrospectives(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE tries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  retrospective_id UUID NOT NULL REFERENCES retrospectives(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Optional: Link tries to specific problems/keeps
CREATE TABLE try_links (
  try_id UUID REFERENCES tries(id) ON DELETE CASCADE,
  linked_problem_id UUID REFERENCES problems(id) ON DELETE CASCADE,
  linked_keep_id UUID REFERENCES keeps(id) ON DELETE CASCADE,
  PRIMARY KEY (try_id, linked_problem_id, linked_keep_id)
);
```

**JSON Representation**:
```json
{
  "id": "uuid",
  "userId": "uuid",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "period": {
    "type": "weekly | monthly",
    "startDate": "date",
    "endDate": "date"
  },
  "keep": [
    {
      "id": "uuid",
      "text": "string",
      "order": "number"
    }
  ],
  "problems": [
    {
      "id": "uuid",
      "text": "string",
      "order": "number"
    }
  ],
  "tries": [
    {
      "id": "uuid",
      "text": "string",
      "order": "number"
    }
  ],
  "status": "draft | completed"
}
```

### 9.3 Action Item Model

**PostgreSQL Schema (Supabase)**:
```sql
CREATE TABLE actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  retrospective_id UUID NOT NULL REFERENCES retrospectives(id) ON DELETE CASCADE,
  try_id UUID REFERENCES tries(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  due_date DATE,
  order_index INTEGER NOT NULL
);

-- Index for fast queries on user actions
CREATE INDEX idx_actions_user_id ON actions(user_id);
CREATE INDEX idx_actions_completed ON actions(is_completed, user_id);
```

**JSON Representation**:
```json
{
  "id": "uuid",
  "userId": "uuid",
  "retrospectiveId": "uuid",
  "tryId": "uuid",
  "text": "string",
  "isCompleted": "boolean",
  "createdAt": "timestamp",
  "completedAt": "timestamp | null",
  "dueDate": "date | null",
  "order": "number"
}
```

**Key Benefits of PostgreSQL Schema**:
- Foreign key constraints ensure data integrity
- Cascade deletes clean up related data automatically
- Indexes optimize queries for user actions
- Native date/time support for temporal queries (Phase 2 AI)
- Full-text search on retrospective text

---

## 10. User Stories (MVP)

### Epic 1: User Authentication

- As a new user, I want to sign up with email/password so I can create my account
- As a returning user, I want to log in quickly so I can access my retrospectives
- As a user, I want to reset my password if I forget it

### Epic 2: KPTA Entry

- As a user, I want to create a new retrospective so I can reflect on my week/month
- As a user, I want to write multiple Keep items so I can note everything positive
- As a user, I want to write multiple Problem items so I can identify challenges
- As a user, I want to write Try items so I can plan experiments
- As a user, I want my entries auto-saved so I don't lose my work
- As a user, I want to save drafts so I can return to incomplete retrospectives

### Epic 3: Action Management

- As a user, I want to create specific action items from each Try so I have concrete tasks
- As a user, I want to see all my action items in one place so I can track my commitments
- As a user, I want to check off completed actions so I can track my progress
- As a user, I want to see which retrospective an action came from so I have context

### Epic 4: History & Review

- As a user, I want to view all my past retrospectives so I can review my journey
- As a user, I want to search my retrospectives by keyword so I can find specific entries
- As a user, I want to see completion rates of my actions so I can measure my follow-through

### Epic 5: Reminders

- As a user, I want to set weekly or monthly reminders so I build a consistent habit
- As a user, I want to customize reminder time/day so it fits my schedule
- As a user, I want to turn off reminders if needed so I control notifications

### Epic 6: Data Control

- As a user, I want to export my data so I own my retrospective history
- As a user, I want to delete my account so I can remove my data if needed

---

## 11. Technical Requirements

### 11.1 Frontend Framework

**Next.js 14 with React 18+ and TypeScript**

- **Rationale**: Industry-leading React framework with built-in SSR, API routes, file-based routing, and excellent TypeScript support
- **App Router**: Uses Next.js 14 App Router for modern React Server Components
- **TypeScript**: Full TypeScript support for type safety and better developer experience
- **Target Browsers**: Modern browsers (Chrome, Firefox, Safari, Edge) with ES2020+ support
- **Mobile Responsive**: Fully responsive design works on mobile browsers (iOS Safari, Chrome Mobile)
- **SEO Benefits**: Server-side rendering for better SEO and initial page load performance

### 11.2 Frontend Architecture

- **State Management**: React useState/useContext (simple) or Zustand for global state
- **Routing**: Next.js App Router with file-based routing and middleware for protected routes
- **UI Components**: shadcn/ui (Radix UI primitives + Tailwind CSS) for accessible, customizable components
- **Styling**: Tailwind CSS for utility-first styling with custom design system
- **Forms**: React Hook Form with Zod validation
- **Backend Client**: @supabase/supabase-js for database, auth, and real-time
- **Local Storage**: localStorage for session persistence and offline draft saving
- **Date Handling**: date-fns for date manipulation and formatting
- **Charts**: Recharts for data visualization (wellbeing trends)
- **Animations**: framer-motion for smooth, declarative animations
- **Notifications**: sonner for toast notifications
- **Real-time**: Supabase Realtime for live updates (optional)

### 11.3 Backend Architecture

**Recommended: Supabase (BaaS - Backend as a Service)**

```
Supabase Stack:
├── PostgreSQL Database (relational data)
├── Auto-generated REST API
├── Realtime subscriptions (WebSocket)
├── Authentication (built-in)
├── Row-Level Security (RLS)
└── Edge Functions (serverless)
```

**Alternative: Custom Backend (Node.js + Express or Python + FastAPI)**

```
Custom Backend Services:
├── API Gateway (Express/FastAPI)
├── Authentication Service (JWT)
├── Retrospective Service
├── Action Service
├── Notification Service (for reminders)
└── User Service
```

- Advantage for custom: Full control, better for complex business logic
- Trade-off: More infrastructure management, slower development

### 11.4 Database

**Recommended: Supabase PostgreSQL**

- **Relational structure**: Perfect for KPTA → Action relationships
- **Real-time subscriptions**: Live updates like Firebase
- **Powerful queries**: Complex joins, aggregations for AI analytics
- **Full-text search**: Built-in search for retrospective history
- **Row-Level Security**: Secure user data isolation
- **Free tier**: 500MB database, 50,000 monthly active users
- **Open source**: No vendor lock-in, can self-host if needed

**Alternative: Firebase Firestore**

- Better mobile SDK maturity
- Excellent offline support
- Simpler for basic CRUD operations
- Trade-off: Harder to query for AI pattern analysis

### 11.5 Cloud Infrastructure

**Recommended: Supabase Cloud**

- **Database**: PostgreSQL (500MB free tier)
- **Authentication**: Built-in auth with social providers
- **Storage**: File storage for user avatars
- **Edge Functions**: Serverless functions for custom logic
- **Realtime**: WebSocket connections for live updates
- **API**: Auto-generated REST and GraphQL APIs

**Cost Estimate**:
- Free tier: Up to 500MB database, 50K MAU, 2GB file storage
- Pro tier: $25/month for 8GB database, 100K MAU (scales with usage)
- Estimated cost for 1000+ users: $25-50/month

**Additional Services Needed:**
- Push Notifications: Firebase Cloud Messaging (FCM) - free
- Analytics: PostHog, Mixpanel, or Google Analytics
- Error Tracking: Sentry (free tier available)

**Alternative: Firebase Suite (Google Cloud)**

- All-in-one solution with mature mobile SDKs
- Better offline support out of the box
- Trade-off: Higher costs at scale, harder to migrate

### 11.6 Authentication

**Recommended: Supabase Auth**

- **Providers**: Email/Password, Google, Apple, GitHub, Magic Links
- **JWT tokens**: Automatic token generation and refresh
- **Row-Level Security**: Database-level user isolation
- **Session management**: Built-in session handling
- **Password recovery**: Email-based reset flow
- **Social auth**: Easy OAuth integration

**Implementation**:
```javascript
// Sign up
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'password'
})

// Sign in
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password'
})
```

### 11.7 Reminders & Notifications

**Web Notifications** - Browser-based reminders for web platform

- **Browser Notifications API**: Native browser notifications for desktop/mobile browsers
- **Email Reminders**: Backup option via Supabase Edge Functions + email service (SendGrid/Resend)
- **Permission-based**: Request notification permission on first visit
- **Customizable**: User can configure frequency, time, and delivery method

**Implementation with Supabase**:
1. Use Browser Notifications API for in-app reminders
2. Store notification preferences in Supabase user preferences table
3. Use Supabase Edge Functions with cron jobs to trigger reminders
4. Schedule based on user timezone (stored in Supabase)
5. Fall back to email if browser notifications are disabled

**Reminder Flow**:
```
Supabase Cron Job (daily check)
  → Query users with reminders due today
  → Check notification preferences (browser vs email)
  → Send browser notification or email
  → Log delivery status
```

### 11.8 Data Export

**Export Formats**:

1. **JSON Export**:
   - Query all user data from Supabase using SQL
   - Include retrospectives, actions, and metadata
   - Generate downloadable JSON file

2. **CSV Export**:
   - Flatten relational data (retrospectives + actions)
   - Excel-compatible format
   - Include timestamps, completion status

3. **PDF Export**:
   - Use react-native-pdf or backend PDF generation
   - Formatted retrospective history with styling
   - Optional: Include completion statistics

**Implementation**:
```javascript
// Supabase query for all user data
const { data, error } = await supabase
  .from('retrospectives')
  .select(`
    *,
    keeps(*),
    problems(*),
    tries(*),
    actions(*)
  `)
  .eq('user_id', userId)
  .order('created_at', { ascending: false })
```

**Advantages with PostgreSQL**:
- Complex joins for complete data export
- SQL dumps available for power users
- Easy data portability

---

## 12. Success Metrics (MVP)

### 12.1 User Acquisition

- **Target**: 100 active users in first month
- **Measurement**: Sign-ups, DAU/MAU ratio
- **Goal**: 30% weekly retention after 4 weeks

### 12.2 Engagement Metrics

- **Primary**: Retrospectives created per user per month
- **Target**: Average 2+ retrospectives per user in first month
- **Secondary**: Action completion rate (target: 40%+)
- **Time in app**: Average session 8-12 minutes (healthy reflection time)

### 12.3 Quality Metrics

- **Crash-free sessions**: 99%+
- **App load time**: <2 seconds
- **KPTA save success**: 99.9%+

### 12.4 Retention Metrics

- **Week 1 retention**: 50%+
- **Week 4 retention**: 30%+
- **Churn triggers**: Track when users stop creating retrospectives

### 12.5 Qualitative Metrics

- User interviews (5-10 users per sprint)
- NPS score (target: 40+)
- App store ratings (target: 4.2+)
- Feature request themes

---

## 13. Development Timeline

### Phase 1: Foundation & Setup (Week 1)

- Project setup (Next.js 14 + TypeScript + App Router)
- Tailwind CSS + shadcn/ui configuration
- Supabase project creation and configuration
- Database schema implementation (PostgreSQL tables)
- Row-Level Security (RLS) policies
- Basic routing structure (React Router)
- **Deliverable**: Development environment ready with basic structure

### Phase 2: Authentication & Landing (Week 2)

- Landing page with hero, features, and CTA sections
- Authentication flow (Supabase Auth: email, Google, GitHub)
- Protected routes setup
- User session management
- **Deliverable**: Users can sign up, log in, and see landing page

### Phase 3: KPTA Entry Interface (Week 3)

- New retrospective page with type/date selection
- Keep and Problem sections (two-column grid)
- Try & Actions section with inline action creation
- Form validation and error handling
- **Deliverable**: Users can create complete KPTA retrospectives

### Phase 4: Dashboard & AI Integration (Week 4)

- Dashboard with stats cards (wellbeing, action rate, etc.)
- Wellbeing score calculation (basic algorithm)
- Supabase Edge Function for Gemini API integration
- AI insights generation (pattern detection, suggestions)
- Wellbeing trend chart with time range filters
- **Deliverable**: AI-powered dashboard with insights

### Phase 5: Action Management & History (Week 5)

- Action items list with filtering (all/pending/completed)
- Retrospective history with search
- Delete functionality with confirmations
- Action completion tracking
- **Deliverable**: Full action and history management

### Phase 6: Polish & Premium Features (Week 6)

- Settings page with preferences and data export
- Premium tier UI with upgrade prompts
- Browser notifications setup
- Responsive design refinements
- Accessibility improvements
- **Deliverable**: Complete feature set with premium tier

### Phase 7: Testing & Optimization (Week 7)

- Comprehensive testing (unit, integration, E2E with Playwright)
- Performance optimization (lazy loading, code splitting)
- SEO optimization (meta tags, sitemap, robots.txt)
- Error tracking setup (Sentry)
- Analytics integration
- **Deliverable**: Production-ready application

### Phase 8: Beta & Launch (Week 8)

- Beta testing with 20+ users
- Bug fixes and polish based on feedback
- Deploy to production (Vercel)
- Custom domain setup
- Product Hunt launch
- **Deliverable**: Public launch

**Total Timeline**: 8 weeks from start to public launch

**Post-Launch Roadmap**:
- Week 9-10: Monitor, iterate, and optimize based on user feedback
- Month 2-3: Advanced AI features (embeddings, deeper analysis)
- Month 4+: Mobile app consideration (PWA or React Native)

---

## 14. UI/UX Design Specifications

### 14.1 Color Palette (Modern Gradients)

#### Primary Gradients
- **Hero**: `from-blue-600 via-indigo-600 to-purple-700` (landing page hero section)
- **Background**: `from-slate-50 via-blue-50 to-slate-50` (main app background)
- **Cards**: White with backdrop blur - `bg-white/60 backdrop-blur-sm`

#### Primary Colors (Tailwind)
- **Blue**: `blue-600` (#2563eb) - Primary actions, dashboard elements
- **Indigo**: `indigo-600` (#4f46e5) - Secondary actions, accents
- **Purple**: `purple-600` (#9333ea) - Premium features, highlights

#### Text Colors
- **Primary**: `slate-900` (headings)
- **Secondary**: `slate-600` (body text)
- **Tertiary**: `slate-500` (metadata, timestamps)
- **Muted**: `slate-400` (placeholders, hints)

#### KPTA Section Colors
- **Keep**: Green palette (`green-50/60` bg, `green-200` border, `green-900` text)
- **Problem**: Red palette (`red-50/60` bg, `red-200` border, `red-900` text)
- **Try**: Purple palette (`purple-50/60` bg, `purple-200` border, `purple-900` text)
- **Action**: Blue palette (`blue-600` primary, `blue-700` hover)

### 14.2 Typography

**Font Family**: Inter (web) with system font fallbacks

Typography is handled via Tailwind's text utilities and CSS variables in globals.css:

#### Headings
- **H1**: `text-2xl` with `font-weight-medium` (screen titles)
- **H2**: `text-xl` with `font-weight-medium` (section headers)
- **H3**: `text-lg` with `font-weight-medium` (card titles)
- **H4**: `text-base` with `font-weight-medium` (subsections)

#### Body Text
- **Regular**: `text-base` with `font-weight-normal` (main content)
- **Small**: `text-sm` (metadata, timestamps)
- **Tiny**: `text-xs` (badges, pills)

#### Spacing
- **Line Height**: 1.5 (default)
- Uses Tailwind's spacing scale (4px base unit)

### 14.3 Component Specifications

#### KPTA Entry Screen

- **Layout**: Three card sections with responsive grid
  - Card 1: Retrospective type and date selection
  - Card 2: Two-column grid (Keep left, Problem right)
  - Card 3: Try & Actions with inline action creation
- **Input areas**: Textarea components with colored borders matching section theme
- **Add buttons**: `+ Add Keep/Problem/Try` buttons at bottom of each section
- **Action creation**: Checkboxes next to Try items with optional deadline picker
- **Save button**: Large blue button at bottom ("Save Retrospective")

#### Dashboard Components

- **Stats Grid**: 4 colored cards showing Current Wellbeing, Avg Score, Action Rate, Total Sessions
- **Wellbeing Chart**: Line chart with time range toggles (30D/90D/All)
- **AI Insights Card**: List of insights with icons and type badges
- **Recent Retrospectives**: Cards with wellbeing score and progress bars

#### Action Items List

- **Each action**: Checkbox + text + deadline badge + retrospective link
- **Filters**: All / Pending / Completed tabs
- **Delete**: Trash icon button
- **Completed items**: Reduced opacity with strike-through

#### Retrospective History

- **Cards**: Show title, date, KPTA counts, wellbeing score with progress bar
- **Search**: Full-text search box at top
- **Delete**: Trash icon with confirmation dialog

### 14.4 Interaction Patterns

- **Loading states**: Skeleton loaders with shimmer effects (shadcn/ui skeleton)
- **Empty states**: Friendly illustrations + helpful text prompting first action
- **Success feedback**: Toast notifications (sonner library) with success checkmarks
- **Animations**: framer-motion for page transitions and element reveals
  - `initial={{ opacity: 0, y: 20 }}`
  - `animate={{ opacity: 1, y: 0 }}`
  - Duration: 0.3-0.6s with staggered delays for lists
- **Hover states**: Subtle color transitions and shadow increases
- **Focus states**: Ring utility from Tailwind for keyboard navigation

---

## 15. AI Integration Architecture

### 15.1 Data Collection Strategy

- Store full text of all KPTA entries (not just summaries) in PostgreSQL
- Tag entries with timestamps for temporal analysis
- Track retrospective frequency and consistency
- Monitor action completion rates per user
- Store AI-generated insights with cache timestamps

### 15.2 API Architecture

```
AI Integration via Supabase Edge Functions:
├── Gemini API Client (secure server-side calls)
├── Wellbeing Score Calculator
│   ├── Sentiment Analysis
│   ├── Keep/Problem Ratio Analysis
│   └── Action Engagement Scoring
├── Pattern Analysis Module
│   ├── Recurring Theme Detection
│   ├── Keyword Extraction
│   └── Consistency Tracking
├── Insight Generator
│   ├── Achievement Recognition
│   ├── Warning Detection
│   └── Actionable Suggestions
└── Rate Limiter & Cost Control
    ├── Usage Tracking per User
    ├── Cache Layer (Redis or Supabase)
    └── Premium Tier Limits
```

### 15.3 Premium Tier Implementation

- **Free Tier**:
  - Basic wellbeing score calculation
  - 3 AI insights per month
  - Limited historical analysis (last 4 retrospectives)
- **Premium Tier** ($9.99/month):
  - Unlimited AI insights
  - Full historical pattern analysis
  - Advanced trend predictions
  - Priority AI processing
  - Email summaries

### 15.4 Cost Management & Performance

- **Rate Limiting**:
  - Free: 3 AI calls/month
  - Premium: 50 AI calls/month
- **Caching Strategy**: Cache AI insights for 7 days to reduce API costs
- **Batch Processing**: Analyze multiple retrospectives in a single Gemini API call
- **Cost Monitoring**: Track Gemini API usage with alerts at $50, $100 thresholds
- **Optimization**: Use Gemini Flash for most analyses, Pro only for complex patterns

---

## 16. Risk Mitigation

### Technical Risks

- **Firebase costs scaling** → Monitor usage, set budget alerts
- **Offline sync conflicts** → Implement last-write-wins with timestamp
- **Push notification delivery** → Track delivery rate, fallback to in-app

### Product Risks

- **Low engagement** → Weekly user interviews to refine UX
- **Poor retention** → A/B test reminder timing and copy
- **Complex UI** → User testing sessions before each release

### Business Risks

- **Slow growth** → Referral program, social sharing of milestones
- **Monetization** → Validate premium willingness-to-pay early (surveys)

---

## 17. Launch Checklist

### Pre-Launch

- [ ] Privacy policy and terms of service published on website
- [ ] Landing page designed and deployed with email signup
- [ ] Error tracking configured (Sentry recommended)
- [ ] Analytics tracking (PostHog, Plausible, or Google Analytics)
- [ ] Beta testing with 20+ users for 2 weeks
- [ ] Performance testing (load testing, Core Web Vitals optimization)
- [ ] Accessibility audit (WCAG 2.1 AA compliance)
- [ ] SEO optimization (meta tags, Open Graph, sitemap)
- [ ] Favicon and web app manifest configured
- [ ] SSL certificate and custom domain configured

### Launch

- [ ] Deploy to production (Vercel/Netlify)
- [ ] DNS and domain configuration
- [ ] Set up monitoring and uptime alerts
- [ ] Social media accounts created (Twitter/X, LinkedIn, Product Hunt)
- [ ] Product Hunt launch scheduled
- [ ] Launch announcement blog post
- [ ] Email drip campaign for waitlist/beta users
- [ ] Press kit prepared (screenshots, logo assets, copy)

### Post-Launch

- [ ] Monitor error rates and performance daily (first week)
- [ ] Respond to user feedback within 24 hours
- [ ] Weekly metrics review (users, retention, engagement, AI usage)
- [ ] User interview schedule (2 per week)
- [ ] Iterate based on feedback (weekly releases with CI/CD)
- [ ] A/B testing for key conversion points
- [ ] Monitor AI API costs and optimize if needed

---

## 18. Why Supabase for KPTA?

### Perfect Fit for KPTA Framework

**1. Relational Data Model**
- KPTA is inherently relational (Keeps → Tries → Actions)
- PostgreSQL enforces data integrity with foreign keys
- Easy to query relationships for analytics

**2. Powerful Querying for AI (Phase 2)**
```sql
-- Example: Find recurring problems across retrospectives
SELECT text, COUNT(*) as frequency
FROM problems
WHERE user_id = $1
GROUP BY text
HAVING COUNT(*) > 1
ORDER BY frequency DESC;
```

**3. Full-Text Search**
- Built-in search across all retrospectives
- No additional service needed
- Fast and accurate

**4. Real-time Subscriptions (Optional)**
```javascript
// Listen for new action completions
supabase
  .from('actions')
  .on('UPDATE', payload => {
    console.log('Action completed!', payload)
  })
  .subscribe()
```

**5. Row-Level Security (RLS)**
- Database-level user isolation
- No user can access another user's data
- Enforced at PostgreSQL level, not just app level

**6. Developer Experience**
- Auto-generated TypeScript types from schema
- Instant REST API from table definitions
- Built-in auth with social providers
- Local development with Docker

**7. Cost & Scalability**
- Free tier: 500MB database, 50K MAU
- Predictable pricing as you scale
- No surprises like Firebase's document read costs

### Migration Path from Firebase (if needed)
If you later need Firebase features:
- Use both: Supabase for data, FCM for notifications
- Easy to add Firebase SDK alongside Supabase
- Not locked into either platform

---

**Document Version**: 2.0
**Last Updated**: 2025-10-25
**Status**: Product Specification - Web App with AI Integration

**Major Changes from v1.3**:
- Platform changed from mobile (React Native) to web (Next.js 14 with React 18+)
- AI features (Gemini API) integrated from MVP instead of Phase 2
- UI updated to modern gradient design based on Figma prototype
- Tech stack updated: Next.js App Router, Tailwind CSS, shadcn/ui, framer-motion, Recharts
- Development timeline reduced from 10 weeks to 8 weeks
- Deployment changed from App Stores to Vercel (optimized for Next.js)
- Notifications changed from FCM push to browser notifications + email
