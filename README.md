# WhisprByTheo 🎙️

**Push-to-talk voice transcription for macOS.** Hold a key to record, release to transcribe and paste. Works everywhere - Slack, email, documents, anywhere you can type.

<p align="center">
  <img src="https://img.shields.io/badge/No_API_Keys-100%25_Local-brightgreen?style=for-the-badge" alt="No API Keys">
  <img src="https://img.shields.io/badge/Apple_Silicon-M1%2FM2%2FM3%2FM4-blue?style=for-the-badge" alt="Apple Silicon">
  <img src="https://img.shields.io/badge/100%25_Free-Open_Source-orange?style=for-the-badge" alt="Free">
</p>

---

## ✨ Why Whispr?

| | |
|---|---|
| 🔒 **No API keys needed** | Runs 100% on your Mac. No OpenAI account, no subscriptions, no cloud. |
| 🚀 **Fast** | Transcribes in ~1 second using Apple Silicon's ML engine |
| 🎨 **Beautiful** | Native macOS look with animated feedback while recording |
| 🔐 **Private** | Audio never leaves your computer |
| 💰 **Free forever** | Open source, no limits, no usage caps |

---

## 🖥️ What You'll Get

Hold your chosen key → speak → release → text appears:

```
┌─────────────────────────────────┐
│  ████████████████████████████   │  ← Recording animation (red bars)
│         Listening               │
└─────────────────────────────────┘
                ↓
┌─────────────────────────────────┐
│  ░░░░████░░░░████░░░░████░░░░   │  ← Transcribing animation (blue wave)
│       Transcribing              │
└─────────────────────────────────┘
                ↓
        Text pasted at cursor! ✓
```

---

## 📋 Requirements

- **Mac with Apple Silicon** (M1, M2, M3, or M4 chip)
- **macOS Ventura or later** (13.0+)
- **Microphone** (built-in works fine)

> ⚠️ **Intel Macs not supported** - MLX only runs on Apple Silicon

---

## 🚀 Installation (5 minutes)

### Step 1: Install Hammerspoon

Hammerspoon is a free macOS automation tool. It runs in your menu bar and lets you create keyboard shortcuts and automations.

**Option A - Using Homebrew (recommended):**
```bash
brew install --cask hammerspoon
```

**Option B - Manual download:**
1. Go to [hammerspoon.org](https://www.hammerspoon.org/)
2. Click "Download"
3. Drag to Applications
4. Open Hammerspoon

**First launch:** Click "Open System Settings" when prompted and enable Hammerspoon under **Privacy & Security → Accessibility**.

---

### Step 2: Download WhisprByTheo

**Option A - One command:**
```bash
git clone https://github.com/wehomemove/WhisprByTheo.spoon.git ~/.hammerspoon/Spoons/WhisprByTheo.spoon
```

**Option B - Manual download:**
1. [Download ZIP](https://github.com/wehomemove/WhisprByTheo.spoon/archive/refs/heads/main.zip)
2. Unzip it
3. Rename folder to `WhisprByTheo.spoon`
4. Move to `~/.hammerspoon/Spoons/` (press Cmd+Shift+G in Finder and paste the path)

---

### Step 3: Install AI Engine

This installs the speech recognition (runs locally, no cloud):

```bash
~/.hammerspoon/Spoons/WhisprByTheo.spoon/install-deps.sh
```

<details>
<summary>What does this install?</summary>

- **ffmpeg** - Records audio from your microphone
- **mlx-whisper** - OpenAI's Whisper AI, optimized for Apple Silicon by Apple

Both are open source. Total install size: ~500MB.
</details>

---

### Step 4: Configure Hammerspoon

Open (or create) the file `~/.hammerspoon/init.lua` and add:

```lua
hs.loadSpoon("WhisprByTheo")
spoon.WhisprByTheo:start()
```

**Not sure how to edit this file?** Run this in Terminal:
```bash
echo 'hs.loadSpoon("WhisprByTheo")
spoon.WhisprByTheo:start()' >> ~/.hammerspoon/init.lua
```

---

### Step 5: Choose Your Key

1. Click the Hammerspoon icon (🔨) in your menu bar
2. Click **Reload Config**
3. You'll see: *"Press the key you want to use for voice input..."*
4. **Press any key** - this becomes your push-to-talk key

**Good choices:**
- A key you don't use (like `Caps Lock`, `Right Option`, or a function key)
- A numpad key if you have one

---

## 🎤 How to Use

1. **Hold** your chosen key
2. **Speak** (you'll see the red "Listening" animation)
3. **Release** the key
4. Wait ~1 second for transcription
5. ✨ Text appears at your cursor

Works in any app - Slack, Gmail, VS Code, Notes, anywhere!

---

## ⚙️ Settings (Optional)

### Change Language

Default is English. To change, edit your `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("WhisprByTheo")
spoon.WhisprByTheo:setLanguage("es")  -- Spanish
spoon.WhisprByTheo:start()
```

**Supported languages:** en, es, fr, de, it, pt, nl, ru, zh, ja, ko, ar, hi, and [90+ more](https://github.com/openai/whisper#available-models-and-languages)

### Better Accuracy (Slower)

Default uses the tiny model (fast). For better accuracy:

```lua
spoon.WhisprByTheo:setModel("mlx-community/whisper-base")  -- or whisper-small
```

| Model | Speed | Accuracy | Best for |
|-------|-------|----------|----------|
| `whisper-tiny` | ⚡ ~1s | Good | Quick notes, casual use |
| `whisper-base` | ~2s | Better | General use |
| `whisper-small` | ~4s | Great | Important transcription |
| `whisper-medium` | ~10s | Excellent | Maximum accuracy |

### Change Key Binding

To pick a different key:
```lua
spoon.WhisprByTheo:setup()  -- Will prompt you to press a new key
```

---

## ❓ Troubleshooting

<details>
<summary><b>"mlx_whisper not found"</b></summary>

Run the install script again:
```bash
~/.hammerspoon/Spoons/WhisprByTheo.spoon/install-deps.sh
```
</details>

<details>
<summary><b>No audio / wrong microphone</b></summary>

1. Check your mic is set as default in System Settings → Sound → Input
2. Or specify it manually:
```lua
spoon.WhisprByTheo.audioDevice = ":1"  -- Try :0, :1, :2 etc
spoon.WhisprByTheo:start()
```
</details>

<details>
<summary><b>Key binding not working</b></summary>

Hammerspoon needs Accessibility permission:
1. Open System Settings → Privacy & Security → Accessibility
2. Find Hammerspoon and enable it (or remove and re-add it)
3. Reload Hammerspoon config
</details>

<details>
<summary><b>First transcription is slow</b></summary>

The first time you use it, the AI model downloads (~50-150MB). After that, it's instant.
</details>

---

## 🔒 Privacy

**Whispr is 100% local.** Your audio is:
- ✅ Recorded to a temp file on your Mac
- ✅ Processed by AI running on your Mac
- ✅ Deleted immediately after transcription
- ❌ Never sent to any server
- ❌ Never stored permanently

No accounts, no API keys, no tracking, no cloud.

---

## 🙏 Credits

- [MLX Whisper](https://github.com/ml-explore/mlx-examples/tree/main/whisper) - Apple's optimized port of OpenAI Whisper
- [Hammerspoon](https://www.hammerspoon.org/) - macOS automation
- [OpenAI Whisper](https://github.com/openai/whisper) - The underlying AI model

Built by Theo @ [Homemove](https://homemove.com)

---

## 📄 License

MIT - Use it however you want, free forever.
