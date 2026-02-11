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
obj.whisperModel = "mlx-community/whisper-tiny"
obj.language = "en"
obj.audioDevice = ":0"  -- Default audio input
obj.keyCode = nil  -- Set during setup or manually

-- Internal state
local recording = false
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

-- Start recording audio
local function startRecording()
    if recording then return end
    recording = true

    showUI("recording", "Listening")

    recordingTask = hs.task.new("/opt/homebrew/bin/ffmpeg", nil, {
        "-y", "-f", "avfoundation", "-i", obj.audioDevice, "-ar", "16000", "-ac", "1", audioFile
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
                            hs.pasteboard.setContents(text)
                            hideUI(true)
                            hs.timer.doAfter(0.5, function()
                                hs.eventtap.keyStroke({"cmd"}, "v")
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
            {audioFile, "--model", obj.whisperModel, "--output-dir", "/tmp/whispr_out", "--language", obj.language}
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
    -- Check dependencies
    local whisperCheck = io.popen("which mlx_whisper 2>/dev/null || echo ''"):read("*a"):gsub("%s+", "")
    if whisperCheck == "" then
        hs.alert.show("⚠️ mlx_whisper not found. Run install script first.", 5)
        return self
    end

    local ffmpegCheck = io.popen("which ffmpeg 2>/dev/null || echo ''"):read("*a"):gsub("%s+", "")
    if ffmpegCheck == "" then
        hs.alert.show("⚠️ ffmpeg not found. Run: brew install ffmpeg", 5)
        return self
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
