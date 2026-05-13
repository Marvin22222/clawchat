# CHANGELOG.md

# Changelog

All notable changes to ClawChat will be documented in this file.

## [1.1.0] - 2026-05-13

### Internationalization (i18n)
- 🌐 **Multi-language support** (German + English)
  - Complete German (`de.dart`) and English (`en.dart`) translations
  - `LocalizationService` for runtime language switching
  - Language picker in settings
  - System locale detection with fallback to German
  - `l10n()` extension for easy translation access

### User Experience & Onboarding
- 🎪 **Onboarding screens** for first-time users
  - Tips & Tricks screen with feature highlights
  - "What's New" sheet for version updates
  - Animated feature discovery
- ✨ **Haptic feedback improvements**
  - `HapticService` with intensity levels (light/medium/heavy)
  - Custom haptic patterns for actions
  - Toggle in settings

### Chat Improvements
- 📝 **Message templates** and canned responses
- 🔍 **Command palette** (Ctrl+K) for quick actions
- 🔗 **URL preview** and link detection
- 💬 **Reply/quote message** feature
- ✅ **Read receipts** with blue checkmarks
- 🎤 **Voice message recording** and playback
- 🖼️ **Image compression** before upload
- 🎬 **Inline video player** for attachments
- 📜 **Virtualized list** for performance
- ♾️ **Infinite scroll** for chat history
- 🗂️ **Chat list sorting** (unread first) + swipe actions

### Settings & Customization
- 🎨 **Theme customization**
  - OLED black mode
  - Accent color picker
  - System theme option
- 🔔 **Notification settings panel**
  - Push notifications toggle
  - Sound & vibration options
  - Quiet hours
- 🔐 **Biometric authentication** UI improvements
  - Face ID / Touch ID toggle
  - Auto-lock timer
- 💾 **Data and storage management**
  - Chat export (JSON, PDF, TXT)
  - Backup restore
  - Cache clear
  - Storage info display

### Performance
- ⚡ **Cold start optimization** with lazy loading
- 🚀 **Virtualized scrolling** for large chat histories
- 📦 **Image lazy loading** with Intersection Observer
- 🔄 **Typing indicators optimization**

### Accessibility
- ♿ **Accessibility improvements**
  - Better semantic labels
  - Screen reader support
  - Keyboard navigation

### Desktop & PWA
- 🖥️ **Responsive desktop mode**
- 📱 **PWA improvements** for desktop PC

### Code Quality
- 📐 **Consistent typography** using `AppTypography`
- 🎯 **Better error handling** UI
- ✨ **Better empty states** with animations
- 🧩 **Offline mode indicator** + loading skeletons

## [1.0.0] - 2026-03-12

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
