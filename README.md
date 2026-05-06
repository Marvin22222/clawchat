# ClawChat 🦞

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue" alt="Flutter">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
  <img src="https://img.shields.io/badge/Version-1.0.0-orange" alt="Version">
</p>

A **native iOS app** for OpenClaw that connects directly to your OpenClaw gateway. 

> **Why ClawChat?** Because Telegram/WhatsApp don't show you what the AI is thinking or what tools it's using. ClawChat gives you **full transparency** - see the thinking process, tool calls, and agent switches in real-time.

---

## ✨ Features

### Core Features

| Feature | Description |
|---------|-------------|
| 🔐 **Secure Login** | Gateway Token authentication with secure iOS Keychain storage |
| 💬 **Real-time Chat** | Live message streaming via WebSocket - messages appear as they're typed |
| 🤖 **Agent Management** | Switch between Main, Coding, Research, and custom agents seamlessly |
| 🌙 **Dark/Light Mode** | Beautiful themes - follows system preference or manual toggle |

### Advanced Features

| Feature | Description |
|---------|-------------|
| 🔧 **Tool Call Display** | See exactly what tools the AI is using (web_search, file operations, etc.) |
| 🧠 **Thinking Indicator** | Watch the AI "think" - animated indicator shows reasoning process |
| 🎤 **Voice Input** | Tap the microphone to dictate your message |
| 📸 **Image Upload** | Share images from gallery or camera |
| 📋 **Tasks & Cron Jobs** | Monitor your scheduled OpenClaw tasks |
| 📂 **Session History** | View past conversations with swipe-to-delete |
| 🤖 **Multi-Agent Monitoring** | Real-time Agent Control Center - see all agents, their status, current tasks, and progress |

### Security Features

| Feature | Description |
|---------|-------------|
| 🔒 **Secure Storage** | Token stored in iOS Keychain via flutter_secure_storage |
| 👆 **Face ID / Touch ID** | Biometric authentication ready (native implementation pending) |
| ⏰ **Auto-Logout** | Configurable auto-logout after inactivity |
| 🔑 **Token Masking** | Tokens are masked in the UI for security |

---

## 🏗️ Architecture

### Tech Stack

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter 3.x |
| **Language** | Dart 3.x |
| **State Management** | Provider (ChangeNotifier) |
| **Architecture** | Clean Architecture |
| **HTTP** | web_socket_channel |
| **Storage** | flutter_secure_storage, shared_preferences |

### Project Structure

```
clawchat/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app.dart                 # MaterialApp configuration
│   ├── clawchat.dart           # Main export file
│   │
│   ├── core/                   # Core utilities and services
│   │   ├── constants/          # Colors, AppConfig, Constants
│   │   │   ├── colors.dart     # Color palette (Primary, Secondary, Status)
│   │   │   ├── app_config.dart # App-wide configuration
│   │   │   ├── app_constants.dart # Strings, Dimensions, Durations
│   │   │   └── constants.dart  # API endpoints, Storage keys
│   │   │
│   │   ├── services/            # External services
│   │   │   ├── websocket_service.dart    # WebSocket connection to Gateway
│   │   │   ├── voice_input_service.dart # Speech-to-text (placeholder)
│   │   │   ├── image_upload_service.dart # Image picker
│   │   │   ├── notification_service.dart  # Push notifications
│   │   │   ├── biometric_service.dart   # Face ID/Touch ID
│   │   │   ├── connectivity_service.dart # Network status
│   │   │   └── local_storage.dart       # SharedPreferences wrapper
│   │   │
│   │   ├── theme/              # Theme definitions
│   │   │   ├── app_theme.dart  # Basic theme
│   │   │   └── theme_config.dart # Full Material 3 theme config
│   │   │
│   │   └── utils/              # Utility functions
│   │       ├── error_handler.dart  # Error dialogs & snackbars
│   │       ├── logger.dart         # Debug logging
│   │       ├── helpers.dart        # DateTime, String, Validators
│   │       ├── crypto_utils.dart  # Hash, Token masking
│   │       ├── platform_utils.dart # Clipboard, Share, Launch
│   │       └── url_utils.dart      # URL parsing
│   │
│   ├── features/               # Feature modules (screens + widgets)
│   │   ├── auth/
│   │   │   └── login_screen.dart  # Gateway Token login
│   │   │
│   │   ├── home/
│   │   │   └── home_screen.dart   # Dashboard with quick actions
│   │   │
│   │   ├── chat/
│   │   │   ├── chat_screen.dart   # Main chat interface
│   │   │   └── widgets/
│   │   │       ├── chat_widgets.dart    # MessageBubble, ChatInput, ThinkingIndicator
│   │   │       └── tool_call_card.dart  # Tool call display
│   │   │
│   │   ├── agents/
│   │   │   └── agents_screen.dart # Agent list & picker
│   │   │
│   │   ├── tasks/
│   │   │   └── tasks_screen.dart  # Cron jobs & tasks
│   │   │
│   │   ├── settings/
│   │   │   └── settings_screen.dart # App settings
│   │   │
│   │   ├── history/
│   │   │   └── session_history_screen.dart # Past conversations
│   │   │
│   │   ├── splash/
│   │   │   └── splash_screen.dart  # Animated splash
│   │   │
│   │   ├── onboarding/
│   │   │   └── onboarding_screen.dart # First-time user flow
│   │   │
│   │   └── main/
│   │       └── main_navigation.dart # Bottom navigation
│   │
│   ├── models/                # Data models
│   │   ├── message.dart       # ChatMessage, MessageType, ToolCall
│   │   ├── session.dart       # Session, SessionManager
│   │   └── agent.dart        # Agent model
│   │
│   ├── providers/             # State management
│   │   └── auth_provider.dart  # AuthProvider, ThemeProvider
│   │
│   └── widgets/               # Reusable widgets
│       ├── animations/
│       │   └── animations.dart # Pulse, Typing, SlideIn, GlowButton
│       └── common/
│           ├── markdown_renderer.dart # Markdown support
│           ├── ui_components.dart    # LoadingOverlay, EmptyState
│           ├── settings_widgets.dart # SettingsTile, SettingsSection
│           └── dashboard_widgets.dart # QuickActions, AgentChip
│
├── test/                       # Unit tests
│   ├── helpers_test.dart       # Utils tests
│   └── widget_test.dart       # Widget tests
│
├── .github/
│   └── workflows/
│       └── ci.yml             # GitHub Actions CI/CD
│
├── ios/                        # iOS native code
│   └── Runner/
│       ├── AppDelegate.swift
│       └── Info.plist
│
├── pubspec.yaml               # Dependencies
├── README.md                   # This file
├── CHANGELOG.md              # Version history
└── CLAWCHAT.md              # Quick description
```

---

## 🔌 WebSocket Integration

### Connection

The app connects to your OpenClaw Gateway via WebSocket:

```
wss://<gateway-url>/ws?token=<token>&type=app
```

### Message Types (Gateway → App)

| Type | Description |
|------|-------------|
| `auth_success` | Authentication successful, returns available agents |
| `message_chunk` | Partial message response (streaming) |
| `thinking` | AI is thinking/reasoning |
| `tool_call_start` | A tool is being called |
| `tool_call_progress` | Tool execution progress |
| `tool_call_end` | Tool execution completed |
| `error` | Error message |

### Message Types (App → Gateway)

| Type | Description |
|------|-------------|
| `auth` | Initial authentication with token |
| `message` | Send a chat message |
| `agent_switch` | Switch to a different agent |

### Example Flow

```dart
// Connect
ws.connect('localhost:18789', 'gw_xxx');

// Send message
ws.sendMessage('Hello!', agent: 'main');

// Receive streaming response
ws.onMessage = (chunk) => print(chunk);
ws.onThinking = (thought) => print('Thinking: $thought');
ws.onToolCall = (tool) => print('Using tool: ${tool['tool']}');
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter** 3.x or higher
- **Xcode** 15+ (for iOS builds)
- **iOS Simulator** or physical iOS device
- **OpenClaw Gateway** running and accessible

### Installation

```bash
# Clone the repository
git clone https://github.com/Marvin22222/clawchat.git

# Navigate to project
cd clawchat

# Get dependencies
flutter pub get

# Run on iOS Simulator
flutter run -d "iPhone 15 Pro"
```

### Building for iOS

```bash
# Debug build (simulator only, no codesign)
flutter build ios --simulator --no-codesign

# Release build (requires Apple Developer account)
flutter build ios --release --export-options-plist=ExportOptions.plist
```

### Gateway Configuration

1. **Get your Gateway Token:**
   - Open OpenClaw settings
   - Go to Gateway section
   - Copy your token

2. **Enter Gateway URL:**
   - Local: `localhost:18789`
   - Remote: `your-domain.com:18789`
   - Cloudflare Tunnel: `subdomain.duckdns.org`

3. **Connect!**

---

## 🎨 Design System

### Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Primary | `#6366F1` | Main brand color (Indigo) |
| Primary Light | `#818CF8` | Hover states |
| Primary Dark | `#4F46E5` | Pressed states |
| Secondary | `#8B5CF6` | Accents (Purple) |
| Success | `#10B981` | Positive states |
| Warning | `#F59E0B` | Warnings |
| Error | `#EF4444` | Errors |
| Info | `#3B82F6` | Information |

### Dark Mode Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Background | `#0F0F23` | Main background |
| Surface | `#1A1A2E` | Cards, dialogs |
| Tertiary | `#252542` | Input fields |

### Light Mode Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Background | `#FFFFFF` | Main background |
| Surface | `#F9FAFB` | Cards, dialogs |
| Tertiary | `#F3F4F6` | Input fields |

---

## 🤝 Contributing

### Development Workflow

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/my-feature`
3. **Make** your changes
4. **Test** with `flutter test`
5. **Analyze** with `flutter analyze`
6. **Commit** with clear messages: `git commit -m "Add feature: ..."`
7. **Push** to your fork: `git push origin feature/my-feature`
8. **Create** a Pull Request

### Code Style

- Follow Flutter's [style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable names
- Add comments for complex logic
- Keep functions small and focused

---

## 📋 Known Issues

| Issue | Status | Workaround |
|-------|--------|------------|
| Face ID native | 🔄 Pending | Uses placeholder UI |
| Push Notifications | 🔄 Pending | Uses local notifications placeholder |
| Android build | 🔄 Not started | N/A - iOS only for now |

---

## 🗺️ Roadmap

### Phase 1 - MVP ✅
- [x] Login with Token
- [x] Real-time Chat
- [x] Agent Management
- [x] Dark/Light Mode

### Phase 2 - Enhanced Features
- [x] Tool Call Display
- [x] Thinking Indicator
- [x] Session History
- [x] Tasks/Cron Jobs

### Phase 3 - Polish ✅
- [x] Animations (pulse, shake, transitions)
- [x] Notification badges
- [x] Pull to refresh
- [x] Empty states

### Phase 4 - Multi-Agent Control Center ✅
- [x] Agent cards with real-time status (LIVE/BUSY/IDLE/ERROR)
- [x] Progress bars for active tasks
- [x] Agent avatars with type icons
- [x] Stats summary bar (agents count, active, busy, errors)
- [x] Filter and sort options (All/Active/Idle/Error)
- [x] Grid/List view toggle
- [x] Agent detail bottom sheet
- [x] Quick actions (message, cancel, view history, reset)
- [x] Connection indicators
- [x] Activity timeline per agent
- [x] Staggered animations

### Phase 5 - Future
- [ ] Android support (Flutter web?)
- [ ] macOS support
- [ ] Widgets
- [ ] App Clip

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

---

## 🦞 About OpenClaw

ClawChat is designed to work with **OpenClaw** - your personal AI assistant that lives on your own infrastructure.

- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [OpenClaw Documentation](https://docs.openclaw.ai)
- [OpenClaw Discord](https://discord.com/invite/clawd)

---

<p align="center">
  Made with ❤️ by Marvin
</p>
