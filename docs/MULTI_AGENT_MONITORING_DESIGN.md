# Multi-Agent Monitoring Feature - Design Spec

## 🎯 Vision
Eine **Agent Control Center** Übersicht in ClawChat wo Marvin alle seine Agents sieht, deren Status, und was sie gerade machen. Übersichtlich, modern, auf einen Blick.

---

## 📱 Screen: Agent Control Center

### Layout (Bottom Tab Integration)
```
┌─────────────────────────────────┐
│  🔮 Agent Control Center    ⚙️  │
├─────────────────────────────────┤
│  ┌─────────────────────────────┐│
│  │ 🤖 Marvis (Main)     🟢 LIVE││
│  │ "Heartbeat + Chat"          ││
│  │ ████████████░░░ 80%        ││
│  └─────────────────────────────┘│
│  ┌─────────────────────────────┐│
│  │ 👾 Cody (Coding)    🟡 BUSY││
│  │ "ClawChat Development"      ││
│  │ ████████████████░ 95%       ││
│  └─────────────────────────────┘│
│  ┌─────────────────────────────┐│
│  │ 🔍 Deep Search       ⚪ IDLE ││
│  │ "Ready to work"             ││
│  └─────────────────────────────┘│
│  ┌─────────────────────────────┐│
│  │ ⚡ AutoTask          🟢 ACTIVE││
│  │ "Daily research + updates"  ││
│  │ Last: 5 min ago             ││
│  └─────────────────────────────┘│
├─────────────────────────────────┤
│  [🕐 Activity Log] [➕ New Task]│
└─────────────────────────────────┘
```

---

## 🎨 Agent Card Design

### States
| State | Color | Icon | Meaning |
|-------|-------|------|---------|
| **LIVE** | Green 🟢 | Pulsing dot | Currently responding |
| **BUSY** | Yellow 🟡 | Spinning | Working on task |
| **IDLE** | Gray ⚪ | Circle | Waiting |
| **ERROR** | Red 🔴 | X | Problem |

### Card Content
```
┌────────────────────────────────────────┐
│ [Avatar] Agent Name           [Status] │
│         Agent ID / Role                │
│                                        │
│ Current Task: "description..."        │
│                                        │
│ [Progress Bar ████████░░░░ 75%]        │
│                                        │
│ [3 steps] [Started 5m ago] [Cancel]    │
└────────────────────────────────────────┘
```

### Avatar Icons per Agent Type
- Main Agent: 🤖
- Coding (Cody): 👾
- Research: 🔍
- AutoTask: ⚡
- Custom: 🎭

---

## 📊 Dashboard Features

### 1. Agent Grid/List Toggle
- **Grid View**: 2 Cards pro Reihe, kompakt
- **List View**: 1 Card pro Reihe, detailliert

### 2. Filter Options
- Show: All | Active | Idle | Error
- Sort: Name | Status | Last Active

### 3. Quick Stats Bar
```
┌─────────────────────────────────────────┐
│ 4 Agents │ 2 Active │ 1 Busy │ 0 Errors │
└─────────────────────────────────────────┘
```

### 4. Activity Timeline
- Scrollbare Liste der letzten Agent-Aktivitäten
- "Cody completed task: Fix login bug"
- "Deep Search finished research"
- Timestamps + Agent Icons

### 5. New Task Modal
```
┌─────────────────────────────────────────┐
│ ➕ New Task                        [X] │
├─────────────────────────────────────────┤
│ Agent:  [Dropdown: Cody ▼]              │
│ Task:   [TextField]                    │
│ Priority: [Low] [Medium] [High]         │
│                                         │
│              [Cancel] [Start Task]       │
└─────────────────────────────────────────┘
```

---

## 🔔 Notification Badges

### Tab Bar
- Agent Tab shows badge with number of active agents
- Red badge if any agent has ERROR state

### Card-Level
- Pulsing animation when agent is working
- Shake animation when ERROR

---

## 🎨 Color Palette

### Dark Mode
| Element | Color |
|---------|-------|
| Card BG | #1E1E2E |
| Card Border | #2D2D3D |
| LIVE | #22C55E (green) |
| BUSY | #EAB308 (yellow) |
| IDLE | #6B7280 (gray) |
| ERROR | #EF4444 (red) |
| Text Primary | #F9FAFB |
| Text Secondary | #9CA3AF |

### Light Mode
| Element | Color |
|---------|-------|
| Card BG | #FFFFFF |
| Card Border | #E5E7EB |
| LIVE | #16A34A |
| BUSY | #CA8A04 |
| IDLE | #9CA3AF |
| ERROR | #DC2626 |
| Text Primary | #111827 |
| Text Secondary | #6B7280 |

---

## 🔄 Interactions

### Tap on Agent Card
→ Opens **Agent Detail Sheet** (bottom sheet):
- Full task description
- Step-by-step progress
- Activity log for this agent
- [View Chat] [Cancel Task] [Send Message]

### Long Press on Agent Card
→ Quick actions menu:
- Send message
- Cancel current task
- View history
- Reset agent

### Swipe Card Left
→ Quick cancel (with confirmation)

### Pull to Refresh
→ Refreshes all agent statuses

---

## 📐 Animations

### Status Indicator
- **LIVE**: Slow pulse (2s interval)
- **BUSY**: Spinning ring (1s interval)
- **ERROR**: Shake (3x, 200ms)

### Card Transitions
- New card: Slide in from bottom + fade
- Status change: Color crossfade 300ms
- Progress bar: Animated fill 400ms ease-out

### List Animations
- Staggered entrance (50ms delay between cards)
- Smooth reorder when status changes

---

## 📋 TODO List für Cody (Reihenfolge)

### Phase 1: Core Infrastructure
- [ ] `AgentStatus` enum und Model
- [ ] `AgentSession` model (name, id, status, task, progress, lastActive)
- [ ] `AgentMonitorService` (WebSocket endpoint für agent status)
- [ ] Mock data für Development

### Phase 2: UI Components
- [ ] `AgentCard` Widget (basic card layout)
- [ ] `StatusIndicator` Widget (pulsing dot/spinner)
- [ ] `ProgressBar` Widget (animated)
- [ ] `AgentAvatar` Widget (icon + color)

### Phase 3: Screen
- [ ] `AgentMonitorScreen` (main screen)
- [ ] Grid/List toggle
- [ ] Filter bar
- [ ] Stats summary bar

### Phase 4: Detail View
- [ ] `AgentDetailSheet` (bottom sheet)
- [ ] Activity timeline for agent
- [ ] Quick actions

### Phase 5: Polish
- [ ] Animations (pulse, shake, transitions)
- [ ] Notification badges
- [ ] Pull to refresh
- [ ] Empty states

### Phase 6: Integration
- [ ] Connect to real WebSocket API
- [ ] Real agent data
- [ ] Error handling
- [ ] Connection status

---

## 🎯 Success Criteria

1. Marvin kann alle Agents auf einen Blick sehen
2. Status (LIVE/BUSY/IDLE/ERROR) sofort erkennbar
3. Aktuelle Aufgabe + Fortschritt sichtbar
4. Schnelle Actions (Nachricht senden, Task canceln)
5. Detaillierte Ansicht auf Tap
6. Smooth animations die nicht nerven
7. Funktioniert in Dark + Light mode

---

*Design Spec erstellt: 2026-05-11*