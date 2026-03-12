# ClawChat 🦞

A native iOS app for OpenClaw - the AI assistant that connects directly to your OpenClaw gateway.

## ✨ Features

### Core
- 🔐 **Secure Login** - Gateway Token authentication
- 💬 **Real-time Chat** - Live message streaming
- 🤖 **Agent Management** - Switch between agents seamlessly
- 🌙 **Dark/Light Mode** - Beautiful themes

### Advanced
- 🔧 **Tool Call Display** - See what the AI is doing
- 🧠 **Thinking Indicator** - Watch the AI think
- 🎤 **Voice Input** - Speak your messages
- 📸 **Image Upload** - Share images
- 📋 **Tasks & Cron Jobs** - Monitor your scheduled tasks

### Security
- 👆 **Face ID / Touch ID** - Biometric login (coming soon)
- 🔒 **Secure Storage** - Token stored in iOS Keychain
- 🔑 **Auto-Logout** - Security when idle

## 🏗️ Architecture

```
lib/
├── main.dart                 # App entry point
├── app.dart                 # App configuration
├── core/
│   ├── constants/          # Colors, spacing, theme
│   ├── services/           # WebSocket, Voice, Image
│   └── theme/              # Theme definitions
├── features/
│   ├── auth/              # Login screen
│   ├── home/              # Home/Dashboard
│   ├── chat/              # Chat interface
│   ├── agents/            # Agent management
│   ├── tasks/             # Task monitoring
│   └── settings/          # App settings
├── models/                 # Data models
├── providers/              # State management
└── widgets/               # Reusable widgets
```

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x
- Xcode (for iOS)
- OpenClaw gateway running

### Installation

```bash
# Clone the repository
git clone https://github.com/Marvin22222/clawchat.git

# Navigate to project
cd clawchat

# Get dependencies
flutter pub get

# Run on iOS simulator
flutter run -d "iPhone 15 Pro"
```

### Build for iOS

```bash
# Debug build
flutter build ios --simulator --no-codesign

# Release build (requires Apple Developer account)
flutter build ios --release
```

## 🔌 Gateway Setup

1. Get your Gateway Token from OpenClaw settings
2. Enter the Gateway URL (e.g., `localhost:18789` or your domain)
3. Connect!

## 🎨 Design System

### Colors
- Primary: #6366F1 (Indigo)
- Secondary: #8B5CF6 (Purple)
- Success: #10B981
- Warning: #F59E0B
- Error: #EF4444

### Typography
- Headings: SF Pro Bold
- Body: SF Pro Regular
- Code: SF Mono

## 📱 Screenshots

[Add screenshots here]

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - see LICENSE file

## 🦞 OpenClaw

This app is designed to work with [OpenClaw](https://github.com/openclaw/openclaw) - your personal AI assistant.
