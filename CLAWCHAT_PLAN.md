# ClawChat Plan - Offene Tasks

_Letztes Update: 2026-04-30 20:43 UTC_

---

## 📋 Offene Tasks

### P0 - Must Have (Critical)
| Task | Beschreibung | Status |
|------|--------------|--------|
| `streaming_integration` | WebSocket streaming end event + UI integration | ⏳ Offen |
| `fcm_notifications` | Firebase Cloud Messaging Backend | ⏳ Offen |

### P1 - Should Have (Wichtig)
| Task | Beschreibung | Status |
|------|--------------|--------|
| `code_copy_button` | Copy Button für Code Blocks | ✅ **Fertig!** (74666f2) |
| `message_search` | Chat durchsuchen | 🚧 In Progress (d4bfc9a) |
| `message_edit` | Nachrichten nachträglich editieren | ⏳ Offen |
| `agent_presets` | Preset Agents speichern/laden | ⏳ Offen |
| `chat_export` | Chat als JSON/Text exportieren | ⏳ Offen |

### P2 - Nice to Have
| Task | Beschreibung | Status |
|------|--------------|--------|
| `message_search` | Chat durchsuchen | ⏳ Offen |
| `keyboard_shortcuts` | Tastaturkürzel ( Ctrl+Enter to send) | ⏳ Offen |
| `dark_mode_toggle` | Manueller Dark/Light Mode Toggle | ✅ Existiert (Auto) |
| `image_fullscreen` | Bilder im Fullscreen anschauen | ⏳ Offen |
| `voice_settings` | Voice Input Sensitivity einstellen | ⏳ Offen |

### P3 - Future
| Task | Beschreibung | Status |
|------|--------------|--------|
| `multi_language` | Mehrsprachigkeit (i18n) | ⏳ Offen |
| `offline_mode` | Offline Chat History | ⏳ Offen |
| `widget_extensions` | iOS Widgets | ⏳ Offen |

---

## 🎯 Priorisierte Reihenfolge

### 1. StreamingText Integration (P0)
**Warum:** Hoher Wow-Faktor, ChatGPT-like Experience

**Steps:**
1. WebSocket `message_stream_start` + `message_stream_end` events
2. `ChatMessage.isStreaming` field
3. `StreamingText` Widget in `MessageBubble` für assistant messages
4. Blinking cursor während streaming

### 2. Message Search (P2)
**Warum:** Oft gebraucht, относительно einfach

**Steps:**
1. Search bar im AppBar
2. Filter messages by content
3. Highlight search term
4. Jump to message

### 3. Code Block Copy Button (P1)
**Warum:** Schneller Gewinn, bereits Long-press implementiert

**Steps:**
1. Already have long-press to copy
2. Add visible copy button in corner of code blocks
3. Show "Copied!" feedback

### 4. FCM Notifications (P0)
**Warum:** Wichtig für User Engagement

**Steps:**
1. Firebase Projekt setup
2. iOS APNs konfigurieren
3. NotificationService implementieren
4. Token management
5. Handle foreground/background notifications

---

## 📊 Quick Wins (Schnell umsetzbar)

| Task | Geschätzte Zeit | Aufwand |
|------|----------------|---------|
| Copy Button zu Code Blocks | 30 min | Niedrig |
| Message Search | 2-3h | Mittel |
| Voice Settings | 1h | Niedrig |

---

## ✅ Abgeschlossene Tasks (zuletzt)

- `32ef62a` - Final status - 71 commits, pausing
- `6d53921` - ToolExecutionCard integriert
- `8ee5d73` - Message Status Icons
- `06ba27a` - Scroll-to-bottom FAB
- `ddd2a73` - Syntax Highlighting
- `f97f043` - Skeleton Loaders
- `90f5660` - AgentActivityCard
- `5a059c2` - HapticService
- `2aa6d50` - AppPageTransitions

---

## 📁 Files im Projekt

```
lib/
├── core/
│   ├── constants/
│   └── services/
│       ├── websocket_service.dart    # Braucht streaming events
│       ├── notification_service.dart  # FCM fehlt
│       └── haptic_service.dart        # ✅ Fertig
├── features/
│   └── chat/
│       ├── chat_screen.dart          # Main screen
│       └── widgets/
│           ├── tool_execution_card.dart
│           ├── thinking_indicator.dart
│           ├── streaming_text.dart    # Widget existiert
│           └── chat_widgets.dart      # MessageBubble
└── models/
    └── message.dart                   # ChatMessage model
```

---

## 🚀 Nächste Schritte

1. **StreamingText Integration** starten
2. Oder Message Search
3. Oder Copy Button

**Was zuerst?**