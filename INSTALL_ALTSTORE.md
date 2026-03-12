# ClawChat mit AltStore auf iPhone installieren

## Was du brauchst:
- 💻 Mac (oder Windows PC)
- 📱 iPhone mit Kabel
- 🔗 GitHub Repo: https://github.com/Marvin22222/clawchat

---

## Schritt 1: AltServer installieren

### Auf Mac:
1. Lade AltServer herunter: https://altstore.io
2. Entpacke die .zip Datei
3. Verschiebe "AltServer" in den Applications Ordner
4. Starte AltServer

### Auf Windows:
1. Lade AltServer herunter
2. Installiere es
3. Starte AltServer

---

## Schritt 2: iPhone verbinden

1. Verbinde dein iPhone per USB-Kabel mit dem Mac/PC
2. Auf dem iPhone: Vertraue dem Computer
3. AltServer zeigt jetzt dein iPhone an

---

## Schritt 3: IPA bauen

### A) Automatisch mit CLI (empfohlen):

```bash
# 1. Repo clonen
git clone https://github.com/Marvin22222/clawchat.git
cd clawchat

# 2. Dependencies installieren
flutter pub get

# 3. IPA bauen
flutter build ipa --release
```

Die IPA Datei findest du unter:
`build/ios/ipa/ClawChat.ipa`

### B) Xcode:

1. Öffne Xcode
2. File → Open → `clawchat/ios/Runner.xcworkspace`
3. Wähle dein iPhone als Target
4. Product → Build
5. Product → Archive
6. Export → Save for Ad Hoc Deployment

---

## Schritt 4: Mit AltStore installieren

### Auf Mac/PC:
1. AltServer läuft im Hintergrund (Menu Bar Icon)
2. Klicke auf das AltServer Icon
3. Wähle "Install AltStore" → Dein iPhone
4. Melde dich mit deiner Apple ID an (kostenlos!)

### IPA installieren:
1. AltServer Menu Bar → "Install IPA"
2. Wähle die `ClawChat.ipa` Datei
3. Warte bis Installation abgeschlossen

---

## Schritt 5: App starten

1. Auf iPhone: ClawChat App Icon
2. Gateway URL eingeben (z.B. `localhost:18789` oder deine Remote URL)
3. Gateway Token eingeben
4. Verbinden!

---

## ⚠️ Wichtig zu wissen:

- **Apple ID Signieren**: Alle 7 Tage muss die App neu signiert werden
- **AltServer muss laufen**: Zum Neu-Signieren einfach AltServer öffnen
- **Funktioniert**: Voll funktionsfähig, genau wie aus dem App Store!

---

## 🔄 Workflow nach 7 Tagen:

1. AltServer öffnen
2. iPhone per Kabel
3. AltServer → "Install AltStore" (re-sign)
4. Fertig für weitere 7 Tage!

---

## ❓ Probleme?

**"AltServer can't find Xcode"**
→ Xcode öffnen und einmalig akzeptieren

**"App can't be opened"**
→ Einstellungen → Allgemein → Geräteverwaltung → Apple ID → App vertrauen

**"Connection failed"**
→ iPhone per Kabel und selbes WLAN wie Mac/PC

---

## 📦 Alternative: Direkt mit Xcode (besser!)

Falls du Xcode hast:
1. `clawchat/ios/Runner.xcworkspace` öffnen
2. iPhone auswählen
3. Play drücken
4. Fertig!

Das ist einfacher und braucht keinen Umweg! 🎉
