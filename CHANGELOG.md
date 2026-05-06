# CHANGELOG.md

# Changelog

All notable changes to ClawChat will be documented in this file.

## [1.1.0] - 2026-05-11

### Added
- 🎉 **Multi-Agent Monitoring** - Agent Control Center feature
  - Real-time agent status display (LIVE/BUSY/IDLE/ERROR)
  - Agent cards with progress bars for active tasks
  - Agent avatars with type-specific icons
  - Stats summary bar (agents count, active, busy, errors)
  - Filter and sort options (All/Active/Idle/Error)
  - Grid/List view toggle
  - Agent detail bottom sheet with activity timeline
  - Quick actions (send message, cancel task, view history, reset agent)
  - Connection indicators
  - Staggered card animations
  - Status indicator animations (pulse, spin, shake)
  - Pull-to-refresh support
  - Empty state handling

### Architecture
- `AgentMonitorService` for WebSocket API integration
- `AgentStatus` enum with 4 states
- `AgentSession` model with full agent data
- `AgentBadge` widget for status badges
- `ConnectionIndicator` for connection status
- `QuickActionsSheet` for agent quick actions
- `FilterBar` for filtering agents
- `StatsSummaryBar` for aggregate stats

## [1.0.0] - 2026-03-12

### Added
- 🔐 Secure Gateway Token Login
- 💬 Real-time Chat with streaming
- 🤖 Agent Management and switching
- 🌙 Dark/Light Mode
- 🔧 Tool Call Display
- 🧠 Thinking Indicator
- 🎤 Voice Input UI
- 📸 Image Upload Service
- 📋 Task & Cron Job Monitoring
- ⚙️ Settings Screen
- 🎬 Splash Screen
- 🔔 Notification Service
- 📄 Comprehensive README
- 🎨 Beautiful Animations
- 💥 Error Handling

### Features in Progress
- 👆 Face ID / Touch ID
- 📳 Push Notifications
- 📱 iOS Build Testing

### Architecture
- Clean Architecture with Provider
- WebSocket Service for real-time communication
- Secure Storage for tokens

---

## [0.0.1] - 2026-03-12

### Initial Development
- Flutter project created
- Basic structure established
