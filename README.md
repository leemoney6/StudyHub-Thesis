# 📚 StudyHub – Smart Study Companion (iOS, SwiftUI)

StudyHub is an iOS app built with **SwiftUI + Firebase** that helps university students organize their study life in one place:

- Plan and track tasks and deadlines
- Focus using a Pomodoro-style timer
- See real-time study stats and session history
- Join and manage study groups
- View a personalized dashboard with progress and recent activity

> This project was created as part of my university work in community organizing / education technology.

---

## ✨ Features

### 🔐 Authentication & Onboarding
- Email/password login & sign up (Firebase Authentication)
- Google Sign-In integration
- Password reset with reset email flow
- Profile completion screen after first login:
  - University name  
  - Major / field of study  
  - Year of study  

User profiles are stored in Firestore (`UserProfile`).

---

### ✅ Task Management

- Create, edit, and delete **study tasks**
- Fields: title, description, subject, due date, priority, completion status
- Filter / browse tasks in a dedicated **Tasks** tab
- Tasks are synced with **Cloud Firestore**

Main components:
- `StudyTask` model
- `TaskViewModel` (MVVM controller for all task operations)
- `TasksView`, `AddTaskView`, `TaskDetailView`, `TaskFiltersView`, `TaskRowView`

---

### ⏱ Focus Timer (Pomodoro) + Session Tracking

A Pomodoro-style focus timer that is fully connected to Firebase.

- Phases: **focus**, **short break**, **long break**
- Automatic phase switching (every 4 focus sessions → long break)
- Session progress ring and modern glassmorphism UI
- Link a session to a specific task (or “Free Focus”)
- Skip, pause, reset controls

#### Session analytics (Firestore)

Every session is saved as a `StudySession` document under the current user:

- Type: `.focus`, `.shortBreak`, `.longBreak`
- Duration (seconds)
- Start & end time
- Completed vs skipped
- Optional linked `taskId` + `taskTitle`
- Derived fields used for stats (e.g. day string)

The timer view model (`PomodoroTimerViewModel`) also computes:

- Today’s number of focus sessions
- Total focus time today
- Completion rate
- Longest day streak with focus sessions
- Recent session history list

The **Focus** tab includes:
- A main timer (`PomodoroView`)
- Quick task selection chips
- Current task section
- Today’s statistics cards
- Recent sessions list
- A full-screen `SessionHistoryView`

---

### 🧠 Dashboard

The Dashboard gives a quick overview of the student’s day.

Sections:

- **Greeting header**  
  - Dynamic greeting (Good morning / afternoon / evening / night)
  - Live time and date
  - Animated StudyHub brain GIF

- **Today’s Progress**  
  Uses **real data** from `PomodoroTimerViewModel` and `TaskViewModel`:
  - Total focus time today
  - Completed / total tasks
  - Number of sessions

- **Quick Start**  
  Four quick actions that switch the app’s main tab:
  - Start Focus Session → Focus tab  
  - Add New Task → Tasks tab  
  - Join Study Group → Groups tab  
  - View Statistics → Focus (session stats)

- **Recent Activity**  
  Shows recent focus sessions with:
  - Session type and status (completed / skipped)
  - Linked task title (if any)
  - Duration
  - “time ago” label

---

### 👥 Study Groups (basic)

A placeholder **Groups** tab (backed by `StudyGroupsViewModel`) for:

- Viewing existing study groups
- Basic structure to later add:
  - Join/leave groups
  - Group description / subjects
  - Member list

(Current implementation is intentionally light since the main focus is on tasks + timer.)

---

### 👤 Profile

- Shows basic user information from `UserProfile`
- Entry point for future settings:
  - Notification preferences
  - Timer defaults
  - Account management

---

## 🏛 Architecture & Project Structure

The app follows a **SwiftUI + MVVM** architecture with a modular folder structure.

```text
StudyHub
└── StudyHub
    ├── App
    │   ├── StudyHubApp.swift       # App entry point, tab navigation
    │   └── ContentView.swift
    ├── Core
    │   └── Models
    │       ├── FirebaseManager.swift
    │       ├── Task.swift          # StudyTask model
    │       ├── StudySession.swift  # Session + statistics models
    │       └── UserStatsViewModel.swift
    ├── Features
    │   ├── Authentication
    │   │   ├── ViewModels/AuthViewModel.swift
    │   │   └── Views/AuthenticationView.swift,
    │   │             ProfileCompletionView.swift,
    │   │             ForgotPasswordView.swift
    │   ├── Tasks
    │   │   ├── ViewModels/TaskViewModel.swift
    │   │   ├── TasksView.swift
    │   │   └── Views/AddTaskView.swift,
    │   │             TaskDetailView.swift,
    │   │             TaskFiltersView.swift,
    │   │             TaskRowView.swift
    │   ├── Timer
    │   │   ├── ViewModels/PomodoroTimerViewModel.swift
    │   │   └── Views/PomodoroView.swift,
    │   │             TaskSelectorView.swift,
    │   │             SessionHistoryView.swift
    │   ├── Dashboard/DashboardView.swift
    │   ├── Groups/GroupsView.swift
    │   └── Main/MainAppView.swift
    ├── Shared
    │   ├── GlassBlurView.swift
    │   └── GlassBlurViewHelper.swift
    ├── Resources
    │   └── studyhub-brain-icon.gif
    └── GoogleService-Info.plist (Firebase config)
