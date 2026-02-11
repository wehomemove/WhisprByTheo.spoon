# VoiceToText.spoon 🎙️

Beautiful push-to-talk voice transcription for macOS. Hold a key to record, release to transcribe and paste.

![Demo](demo.gif)

## Features

- **Push-to-talk** - Hold any key to record, release to transcribe
- **Fast on-device AI** - Powered by MLX Whisper, runs entirely on your Mac
- **Beautiful UI** - Native-looking glassmorphic overlay with animated feedback
- **Privacy first** - No audio leaves your computer
- **Apple Silicon optimized** - Blazing fast on M1/M2/M3/M4 Macs

## Requirements

- **macOS** on Apple Silicon (M1/M2/M3/M4)
- **[Hammerspoon](https://www.hammerspoon.org/)** - macOS automation tool
- **Microphone** - Built-in or external

## Quick Install

### 1. Install Hammerspoon

```bash
brew install --cask hammerspoon
```

Open Hammerspoon and grant Accessibility permissions when prompted.

### 2. Download the Spoon

```bash
# Clone directly into Hammerspoon Spoons directory
git clone https://github.com/wehomemove/VoiceToText.spoon.git ~/.hammerspoon/Spoons/VoiceToText.spoon
```

Or download the latest release and unzip to `~/.hammerspoon/Spoons/`

### 3. Install Dependencies

```bash
~/.hammerspoon/Spoons/VoiceToText.spoon/install-deps.sh
```

This installs:
- `ffmpeg` - Audio recording
- `mlx-whisper` - AI transcription

### 4. Configure Hammerspoon

Add to your `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("VoiceToText")
spoon.VoiceToText:start()
```

### 5. Reload & Setup

Reload Hammerspoon config (click menubar icon → Reload Config).

**You'll be prompted to press the key you want to use.** Press any key - it will be saved and used for push-to-talk.

## Usage

1. **Hold** your configured key
2. **Speak** while the UI shows "Listening"
3. **Release** the key
4. Watch it transcribe (blue "Transcribing" animation)
5. Text is automatically pasted at your cursor

## Configuration

### Change Whisper Model

Larger models are more accurate but slower:

```lua
hs.loadSpoon("VoiceToText")
spoon.VoiceToText:setModel("mlx-community/whisper-base")  -- Options: tiny, base, small, medium
spoon.VoiceToText:start()
```

| Model | Speed | Accuracy | VRAM |
|-------|-------|----------|------|
| `whisper-tiny` | Fastest | Good | ~1GB |
| `whisper-base` | Fast | Better | ~1GB |
| `whisper-small` | Medium | Great | ~2GB |
| `whisper-medium` | Slower | Excellent | ~5GB |

### Change Language

```lua
spoon.VoiceToText:setLanguage("es")  -- Spanish
spoon.VoiceToText:start()
```

Supported: en, es, fr, de, it, pt, nl, pl, ru, zh, ja, ko, and [many more](https://github.com/openai/whisper#available-models-and-languages).

### Manual Key Binding

If you know the keycode:

```lua
spoon.VoiceToText:bindKey(76)  -- Numpad Enter
spoon.VoiceToText:start()
```

### Re-run Setup

To change your key binding:

```lua
spoon.VoiceToText:setup()
```

## API Reference

| Method | Description |
|--------|-------------|
| `:start()` | Load config and start (runs setup if no config) |
| `:stop()` | Stop and clean up |
| `:setup()` | Interactive key binding setup |
| `:bindKey(keyCode)` | Bind specific keycode |
| `:setModel(model)` | Set Whisper model |
| `:setLanguage(lang)` | Set transcription language |

## Troubleshooting

### "mlx_whisper not found"

Run the install script:
```bash
~/.hammerspoon/Spoons/VoiceToText.spoon/install-deps.sh
```

### No audio / wrong microphone

List available devices:
```bash
ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep -A 20 "audio devices"
```

Set the correct device in your config:
```lua
spoon.VoiceToText.audioDevice = ":1"  -- Change number to match your mic
spoon.VoiceToText:start()
```

### Key binding not working

Make sure Hammerspoon has Accessibility permissions:
System Settings → Privacy & Security → Accessibility → Hammerspoon ✓

### Transcription is slow

Use a smaller model:
```lua
spoon.VoiceToText:setModel("mlx-community/whisper-tiny")
```

## How It Works

1. **Recording**: ffmpeg captures audio from your microphone
2. **Transcription**: MLX Whisper processes audio entirely on-device using Apple's ML framework
3. **Output**: Text is copied to clipboard and pasted at cursor position

All processing happens locally. No data is sent anywhere.

## Credits

- [MLX Whisper](https://github.com/ml-explore/mlx-examples/tree/main/whisper) - Apple's MLX port of OpenAI Whisper
- [Hammerspoon](https://www.hammerspoon.org/) - Powerful macOS automation
- Built with ❤️ by [Homemove](https://homemove.com)

## License

MIT License - see [LICENSE](LICENSE)
