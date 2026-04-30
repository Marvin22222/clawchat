# ClawChat UI Plan - Marvins Vision

_Letztes Update: 2026-04-30_

---

## 🎯 Vision

ClawChat wird eine **ChatGPT-ähnliche AI Chat App** mit:
- Schöne Tool Execution Animationen
- Apple-like, moderne UI
- Smooth transitions & flüssige Animationen
- Klare sequentiale Anzeige (Tool → Response)
- Sichtbarer Thinking Mode
- Autonomes Agent Monitoring

---

## 🧠 Brainstorm: UI Ideen

### 1. Tool Execution UI (ChatGPT-like)
- **Expandable Cards**: Tool Calls starten collapsed, expandieren bei tap
- **Streaming Animation**: Text erscheint Buchstabe für Buchstabe
- **Progress Indicator**: Zeigt Fortschritt während Tool läuft
- **Inline Display**: Tool + Result zusammen, nicht separiert
- **Tool Badge**: Kleines Icon/Tag für Tool-Typ (Calculator, Search, etc.)
- **Collapsible Results**: Lange Results einklappbar mit "Show more"

### 2. Thinking Mode
- **Drei-Dots Animation**: Pulsierendes "..." während Denken
- **Separate Section**: Thinking wird visuell abgetrennt
- **Subtile Farbe**: Leicht andere Hintergrundfarbe
- **Thinking Badge**: "Thinking..." Label sichtbar
- **Cancel Option**: X um Thinking zu canceln

### 3. Message Bubble Improvements
- **Apple-like Rundungen**: Mehr like iMessage
- **Timestamp Position**: Unten rechts, dezent
- **Status Indicators**: Kleine Icons (sent, delivered, read)
- **Reaction Animation**: Emoji pop-out wenn hinzugefügt

### 4. Autonomes Agent Monitoring
- **Agent Activity Card**: Zeigt aktive Agents in Echtzeit
- **Step Log**: Liste der ausgeführten Steps
- **Status Badge**: Running, Completed, Error states
- **Progress Bar**: Für mehrstufige Tasks
- **Live Updates**: WebSocket für Echtzeit-Feedback

### 5. Modern UI Elements
- **Blur Effects**: Glassmorphism für Overlays
- **Haptic Feedback**: Bei Interaktionen
- **Pull-to-Refresh**: Für Chat reloaden
- **Smooth Scrolling**: Rubber-band effect
- **Dark/Light Transition**: Sanfter Wechsel
- **Skeleton Loaders**: Während Content lädt

### 6. Connection & Status
- **Minimaler Status Bar**: Nur bei Bedarf
- **Animated Reconnect**: Smooth transition
- **Background Sync**: Zeigt sync Status dezent

---

## 📋 Feature List

### Phase 1: Tool Execution UI
| Feature | Beschreibung |
|---------|--------------|
| `tool_execution_card` | Expandable Card für Tool Calls |
| `streaming_text` | Text erscheint Buchstabe für Buchstabe |
| `tool_badge` | Icon/Tag für Tool-Typ |
| `progress_indicator` | Animierter Fortschrittsbalken |

### Phase 2: Thinking Mode
| Feature | Beschreibung |
|---------|--------------|
| `thinking_indicator` | Drei-Dots Animation |
| `thinking_section` | Visuell abgetrennte Section |
| `thinking_cancel` | X Button zum Canceln |

### Phase 3: Agent Monitoring
| Feature | Beschreibung |
|---------|--------------|
| `agent_activity_card` | Echtzeit-Agent-Status |
| `step_log_list` | Liste der Steps mit Status |
| `live_progress` | WebSocket-basierte Updates |

### Phase 4: UI Polish
| Feature | Beschreibung |
|---------|--------------|
| `smooth_transitions` | Flüssige Page/Element Transitions |
| `haptic_feedback` | Haptic bei Button presses |
| `skeleton_loaders` | Lade-Platzhalter |
| `message_polish` | Apple-like bubble design |

---

## 🎨 Design Konzepte

### Farben
```
Primary:        #6366F1 (Indigo)
Secondary:      #8B5CF6 (Purple)
Success:        #10B981 (Green)
Warning:        #F59E0B (Amber)
Error:          #EF4444 (Red)
Background:     
  Light:        #FFFFFF / #F5F5F7
  Dark:         #1C1C1E / #2C2C2E
```

### Typography
```
Font:           SF Pro (iOS), Roboto (Android)
Title:          20px, SemiBold
Body:           16px, Regular
Caption:        12px, Regular
Code:           14px, Monospace
```

### Spacing (8pt Grid)
```
xs:  4px
sm:  8px
md:  16px
lg:  24px
xl:  32px
xxl: 48px
```

### Border Radius
```
small:    8px
medium:   16px
large:    24px
full:     9999px (pills)
```

### Shadows
```
light:  0 2px 8px rgba(0,0,0,0.08)
medium: 0 4px 16px rgba(0,0,0,0.12)
heavy:  0 8px 32px rgba(0,0,0,0.16)
```

---

## 🔥 Priority Order

### P0 (Must Have - Jetzt)
1. **Tool Execution Card** - Expandable, mit Badge
2. **Streaming Text Animation** - Buchstabe für Buchstabe
3. **Thinking Indicator** - Drei-Dots Animation

### P1 (Should Have - Diese Woche)
4. **Progress Indicator** - Für laufende Tools
5. **Smooth Transitions** - Page transitions
6. **Haptic Feedback** - Bei Interaktionen

### P2 (Nice to Have - Später)
7. **Agent Activity Card** - Monitoring Dashboard
8. **Skeleton Loaders** - Lade-States
9. **Message Polish** - Details

---

## 🚀 Implementierung

### Step 1: Tool Execution Card
```
lib/features/chat/widgets/
├── tool_execution_card.dart   (NEW)
└── chat_widgets.dart         (MODIFY)
```

### Step 2: Streaming Animation
```
lib/features/chat/services/
├── streaming_service.dart    (NEW)
```

### Step 3: Thinking Indicator
```
lib/features/chat/widgets/
├── thinking_indicator.dart    (NEW)
```

---

## 📁 Neue Files zu erstellen

1. `lib/features/chat/widgets/tool_execution_card.dart`
2. `lib/features/chat/widgets/thinking_indicator.dart`
3. `lib/features/chat/widgets/streaming_text.dart`
4. `lib/features/chat/widgets/agent_activity_card.dart`
5. `lib/core/constants/animation_constants.dart`

---

## ✅ Acceptance Criteria

- [ ] Tool Calls werden als expandable Cards angezeigt
- [ ] Text streamed Buchstabe für Buchstabe
- [ ] Thinking Indicator ist sichtbar und animiert
- [ ] Smooth transitions zwischen States
- [ ] Keine CI/CD - nur commit + push

---

_Cody shipped. Cody documentiert. Cody planed._