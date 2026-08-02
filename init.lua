--- === WhisprByTheo ===
---
--- Push-to-talk voice transcription for macOS using Whisper AI.
--- Hold a key to record, release to transcribe and paste.
---
--- Features a beautiful native-looking UI with animated feedback.
--- Powered by MLX Whisper for fast on-device transcription on Apple Silicon.
---
--- Download: https://github.com/wehomemove/WhisprByTheo.spoon

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "WhisprByTheo"
obj.version = "1.0.0"
obj.author = "Theo @ Homemove"
obj.homepage = "https://github.com/wehomemove/WhisprByTheo.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Configuration with defaults
obj.whisperPath = os.getenv("HOME") .. "/.local/bin/mlx_whisper"
obj.ffmpegPath = "/opt/homebrew/bin/ffmpeg"
obj.whisperModel = "mlx-community/whisper-tiny"
obj.language = nil  -- nil = let Whisper auto-detect the language per utterance
obj.conditionOnPreviousText = false  -- True invites repetition loops on pauses and language-lock on code-switching; keep False for dictation
obj.audioDevice = ":0"  -- Default audio input (avfoundation index)
obj.audioDevicePreference = nil  -- e.g. {"Jabra", "Insta360"}: first connected match wins (name substring, case-insensitive); overrides audioDevice
obj.initialPrompt = nil  -- optional vocabulary bias, e.g. domain terms Whisper should favor; also biases language, so leave nil for bilingual use
obj.restoreClipboard = true  -- put the previous clipboard contents back after pasting (plain text only)
obj.keyCode = nil  -- Set during setup or manually

-- Internal state
local recording = false
local micLive = false
local recordingTask = nil
local audioFile = "/tmp/whispr_audio.wav"
local voiceUI = nil
local keyDownTap = nil
local keyUpTap = nil
local spoonPath = nil

--- WhisprByTheo:init()
--- Method
--- Initialize the spoon
function obj:init()
    spoonPath = hs.spoons.scriptPath()
    return self
end

-- Get screen center for UI positioning
local function getScreenCenter()
    local screen = hs.screen.mainScreen():frame()
    return {
        x = screen.x + (screen.w / 2) - 100,
        y = screen.y + (screen.h / 2) - 200
    }
end

-- Show the voice UI
local function showUI(state, label)
    if voiceUI then
        voiceUI:evaluateJavaScript(string.format("setState('%s', '%s')", state, label or state))
        return
    end

    local center = getScreenCenter()
    voiceUI = hs.webview.new({x = center.x, y = center.y, w = 200, h = 120})
    voiceUI:windowStyle({"borderless", "utility", "HUD"})
    voiceUI:level(hs.drawing.windowLevels.overlay)
    voiceUI:alpha(1)
    voiceUI:allowTextEntry(false)
    voiceUI:transparent(true)
    voiceUI:url("file://" .. spoonPath .. "/voice-ui.html")
    voiceUI:bringToFront(true)
    voiceUI:show()

    hs.timer.doAfter(0.1, function()
        if voiceUI then
            voiceUI:evaluateJavaScript(string.format("setState('%s', '%s')", state, label or state))
        end
    end)
end

-- Hide the UI with animation
local function hideUI(success)
    if not voiceUI then return end

    if success then
        voiceUI:evaluateJavaScript("setState('success', 'Done')")
        hs.timer.doAfter(0.6, function()
            if voiceUI then
                voiceUI:evaluateJavaScript("fadeOut()")
                hs.timer.doAfter(0.3, function()
                    if voiceUI then
                        voiceUI:delete()
                        voiceUI = nil
                    end
                end)
            end
        end)
    else
        voiceUI:evaluateJavaScript("fadeOut()")
        hs.timer.doAfter(0.3, function()
            if voiceUI then
                voiceUI:delete()
                voiceUI = nil
            end
        end)
    end
end

-- Map audioDevicePreference names to the current avfoundation index.
-- Indices shift as devices come and go, so resolve by name — at start()
-- and again on every device add/remove, never on the recording hot path.
local function resolveAudioDevice()
    if not obj.audioDevicePreference then return end
    obj._resolvedAudioDevice = nil
    local p = io.popen(obj.ffmpegPath .. ' -list_devices true -f avfoundation -i "" 2>&1')
    if not p then return end
    local out = p:read("*a")
    p:close()
    local audioSection = out:match("audio devices:(.*)$") or ""
    local devices = {}
    for idx, name in audioSection:gmatch("%[(%d+)%]([^\r\n]+)") do
        devices[#devices + 1] = { index = idx, name = name:match("^%s*(.-)%s*$") }
    end
    for _, want in ipairs(obj.audioDevicePreference) do
        for _, d in ipairs(devices) do
            if d.name:lower():find(want:lower(), 1, true) then
                obj._resolvedAudioDevice = ":" .. d.index
                return
            end
        end
    end
end

-- Start recording audio
local function startRecording()
    if recording then return end
    recording = true

    -- ffmpeg needs up to ~1s to open the capture device; words spoken before
    -- that are lost. Show "Starting" until ffmpeg's progress stream confirms
    -- samples are flowing, so the user knows when the mic is actually hot.
    micLive = false
    showUI("recording", "Starting")

    recordingTask = hs.task.new(obj.ffmpegPath, nil, function(_, stdOut, _)
        if recording and not micLive and stdOut and #stdOut > 0 then
            micLive = true
            showUI("recording", "Listening")
        end
        return true
    end, {
        "-y", "-nostats", "-progress", "pipe:1",
        "-f", "avfoundation", "-i", obj._resolvedAudioDevice or obj.audioDevice, "-ar", "16000", "-ac", "1", audioFile
    })
    recordingTask:start()
end

-- Stop recording and transcribe
local function stopRecordingAndTranscribe()
    if not recording then return end
    recording = false

    if recordingTask then
        recordingTask:terminate()
        recordingTask = nil
    end

    showUI("transcribing", "Transcribing")

    hs.timer.doAfter(0.3, function()
        hs.task.new(obj.whisperPath,
            function(exitCode)
                if exitCode == 0 then
                    local f = io.open("/tmp/whispr_out/whispr_audio.txt", "r")
                    if f then
                        local text = f:read("*all"):gsub("^%s+", ""):gsub("%s+$", ""):gsub("\n", " ")
                        f:close()
                        if text ~= "" then
                            local previousClipboard = obj.restoreClipboard and hs.pasteboard.getContents() or nil
                            hs.pasteboard.setContents(text)
                            hideUI(true)
                            hs.timer.doAfter(0.5, function()
                                hs.eventtap.keyStroke({"cmd"}, "v")
                                if previousClipboard then
                                    hs.timer.doAfter(0.4, function()
                                        hs.pasteboard.setContents(previousClipboard)
                                    end)
                                end
                            end)
                        else
                            showUI("error", "No speech")
                            hs.timer.doAfter(1.5, function() hideUI(false) end)
                        end
                    else
                        showUI("error", "Read error")
                        hs.timer.doAfter(1.5, function() hideUI(false) end)
                    end
                else
                    showUI("error", "Error")
                    hs.timer.doAfter(1.5, function() hideUI(false) end)
                end
                os.remove(audioFile)
                os.execute("rm -rf /tmp/whispr_out")
            end,
            (function()
                local args = {audioFile, "--model", obj.whisperModel, "--output-dir", "/tmp/whispr_out",
                              "--condition-on-previous-text", obj.conditionOnPreviousText and "True" or "False"}
                if obj.language and obj.language ~= "auto" then
                    table.insert(args, "--language")
                    table.insert(args, obj.language)
                end
                if obj.initialPrompt then
                    table.insert(args, "--initial-prompt")
                    table.insert(args, obj.initialPrompt)
                end
                return args
            end)()
        ):start()
    end)
end

--- WhisprByTheo:bindKey(keyCode)
--- Method
--- Bind the push-to-talk key by keycode
---
--- Parameters:
---  * keyCode - The keycode to use (number)
---
--- Returns:
---  * The WhisprByTheo object
function obj:bindKey(keyCode)
    self.keyCode = keyCode

    -- Clean up existing taps
    if keyDownTap then keyDownTap:stop() end
    if keyUpTap then keyUpTap:stop() end

    keyDownTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
        if e:getKeyCode() == self.keyCode then
            startRecording()
            return true
        end
        return false
    end)
    keyDownTap:start()

    keyUpTap = hs.eventtap.new({hs.eventtap.event.types.keyUp}, function(e)
        if e:getKeyCode() == self.keyCode then
            stopRecordingAndTranscribe()
            return true
        end
        return false
    end)
    keyUpTap:start()

    return self
end

--- WhisprByTheo:setup()
--- Method
--- Interactive setup - detects the key you press and binds it
---
--- Returns:
---  * The WhisprByTheo object
function obj:setup()
    hs.alert.show("🎙️ Press the key you want to use for voice input...", 10)

    local setupTap
    setupTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
        local keyCode = e:getKeyCode()
        setupTap:stop()

        -- Save to config file
        local configPath = os.getenv("HOME") .. "/.config/whispr"
        os.execute("mkdir -p " .. configPath)
        local f = io.open(configPath .. "/config.lua", "w")
        if f then
            f:write("return { keyCode = " .. keyCode .. " }\n")
            f:close()
        end

        hs.alert.closeAll()
        hs.alert.show("✓ Key bound! (keycode " .. keyCode .. ")", 2)

        self:bindKey(keyCode)
        return true
    end)
    setupTap:start()

    return self
end

--- WhisprByTheo:start()
--- Method
--- Start WhisprByTheo with saved config or run setup if no config exists
---
--- Returns:
---  * The WhisprByTheo object
function obj:start()
    -- Check dependencies at the paths actually used later; `which` via io.popen
    -- runs with the GUI launchd PATH, which lacks ~/.local/bin and /opt/homebrew/bin
    if not hs.fs.attributes(self.whisperPath) then
        hs.alert.show("⚠️ mlx_whisper not found at " .. self.whisperPath .. ". Run install script first.", 5)
        return self
    end

    if not hs.fs.attributes(self.ffmpegPath) then
        hs.alert.show("⚠️ ffmpeg not found at " .. self.ffmpegPath .. ". Run: brew install ffmpeg, or set ffmpegPath.", 5)
        return self
    end

    -- Pick the recording device up front and track plug/unplug events
    if self.audioDevicePreference then
        resolveAudioDevice()
        hs.audiodevice.watcher.setCallback(function(event)
            if event == "dev#" then resolveAudioDevice() end
        end)
        hs.audiodevice.watcher.start()
    end

    -- Try to load saved config
    local configPath = os.getenv("HOME") .. "/.config/whispr/config.lua"
    local f = io.open(configPath, "r")
    if f then
        f:close()
        local config = dofile(configPath)
        if config and config.keyCode then
            self:bindKey(config.keyCode)
            hs.alert.show("🎙️ Voice ready!", 2)
            return self
        end
    end

    -- No config found, run setup
    self:setup()
    return self
end

--- WhisprByTheo:stop()
--- Method
--- Stop WhisprByTheo and clean up
---
--- Returns:
---  * The WhisprByTheo object
function obj:stop()
    if self.audioDevicePreference and hs.audiodevice.watcher.isRunning() then
        hs.audiodevice.watcher.stop()
    end
    if keyDownTap then keyDownTap:stop(); keyDownTap = nil end
    if keyUpTap then keyUpTap:stop(); keyUpTap = nil end
    if voiceUI then voiceUI:delete(); voiceUI = nil end
    return self
end

--- WhisprByTheo:setModel(model)
--- Method
--- Set the Whisper model to use
---
--- Parameters:
---  * model - Model name (e.g., "mlx-community/whisper-tiny", "mlx-community/whisper-base", "mlx-community/whisper-small")
---
--- Returns:
---  * The WhisprByTheo object
function obj:setModel(model)
    self.whisperModel = model
    return self
end

--- WhisprByTheo:setLanguage(lang)
--- Method
--- Set the language for transcription
---
--- Parameters:
---  * lang - Language code (e.g., "en", "es", "fr", "de")
---
--- Returns:
---  * The WhisprByTheo object
function obj:setLanguage(lang)
    self.language = lang
    return self
end

return obj
