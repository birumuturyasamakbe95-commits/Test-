-- ============================================================
-- Sakura.vs — ANTI BAT v3 (+ HOLD Inf Jump entegre)
-- ============================================================
repeat task.wait() until game:IsLoaded()

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TS         = game:GetService("TweenService")
local HS         = game:GetService("HttpService")

local LP = Players.LocalPlayer

-- STATE
antiBatEnabled        = false
antiBatConn           = nil
antiBatPanelVisible   = false
antiBatPanelGui       = nil
antiBatPanelPos       = nil
antiBatPanelCollapsed = false
setAntiBatVisual      = nil
mobSetAntiBat         = nil
_isResetting          = false

local CONFIG_FILE = "Sakura_vs_AntiBat.json"
local BG_ASSET    = "126567400601699"
local PANEL_NAME  = "SakuraAntiBat"
local MINI_NAME   = "AntiBatMiniBtn"

-- ============================================================
-- YARDIMCILAR
-- ============================================================
local function safeWrite(tbl)
    if type(writefile) ~= "function" then return end
    pcall(function() writefile(CONFIG_FILE, HS:JSONEncode(tbl)) end)
end

local function safeRead()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return nil end
    if not isfile(CONFIG_FILE) then return nil end
    local ok, data = pcall(function() return HS:JSONDecode(readfile(CONFIG_FILE)) end)
    if ok then return data end
    return nil
end

local function saveAntiBatState()
    if _isResetting then return end
    safeWrite({
        antiBatEnabled        = antiBatEnabled,
        antiBatPanelPos       = antiBatPanelPos,
        antiBatPanelCollapsed = antiBatPanelCollapsed,
        infJumpEnabled        = infJumpEnabled,
    })
end

local function getGuiParent()
    return LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui", 10)
end

-- ============================================================
-- ANTI BAT (spiral velocity)
-- ============================================================
local _antiBatSpeed     = 10000
local _antiBatAngle     = 0
local _antiBatDirection = 1

function stopAntiBat()
    antiBatEnabled = false
    if antiBatConn then
        pcall(function() antiBatConn:Disconnect() end)
        antiBatConn = nil
    end
    _antiBatSpeed     = 10000
    _antiBatAngle     = 0
    _antiBatDirection = 1
    if setAntiBatVisual then pcall(setAntiBatVisual, false) end
    if mobSetAntiBat then pcall(mobSetAntiBat, false) end
    saveAntiBatState()
end

function startAntiBat()
    local char = LP.Character
    if not char then warn("[AntiBat] karakter yok") return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then warn("[AntiBat] HRP yok") return end

    antiBatEnabled = true
    if antiBatConn then
        pcall(function() antiBatConn:Disconnect() end)
        antiBatConn = nil
    end

    antiBatConn = RunService.Heartbeat:Connect(function()
        if not antiBatEnabled then return end
        if _isResetting then return end
        local c = LP.Character
        if not c then return end
        root = c:FindFirstChild("HumanoidRootPart")
        if not root or not root.Parent then return end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then return end

        local origXZ = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)

        _antiBatSpeed = _antiBatSpeed + (50 * _antiBatDirection)
        if _antiBatSpeed >= 20000 then
            _antiBatSpeed = 20000
            _antiBatDirection = -1
        elseif _antiBatSpeed <= 10000 then
            _antiBatSpeed = 10000
            _antiBatDirection = 1
        end

        _antiBatAngle = _antiBatAngle + (math.random() * 0.5)

        local radius = _antiBatSpeed + math.random(-5000, 5000)
        local newX = math.cos(_antiBatAngle) * radius
        local newZ = math.sin(_antiBatAngle) * radius

        root.Velocity = Vector3.new(newX, root.Velocity.Y, newZ)

        RunService.RenderStepped:Wait()

        if root and root.Parent then
            root.Velocity = Vector3.new(origXZ.X, root.Velocity.Y, origXZ.Z)
        end
    end)

    if setAntiBatVisual then pcall(setAntiBatVisual, true) end
    if mobSetAntiBat then pcall(mobSetAntiBat, true) end
    saveAntiBatState()
end

function setAntiBat(on)
    if on then startAntiBat() else stopAntiBat() end
end

function toggleAntiBat()
    if antiBatEnabled then stopAntiBat() else startAntiBat() end
    return antiBatEnabled
end

-- ============================================================
-- INFINITE JUMP (HOLD) — orijinal dosyadan
-- ============================================================
infJumpEnabled = infJumpEnabled or false
infJumpMode    = infJumpMode or "HOLD"

_G.AmbitiousNormalInfJump = _G.AmbitiousNormalInfJump or {
    holdPressed = false, holdActive = false,
    controllerActive = false, mobilePressed = false,
    mobileActive = false, hooked = {}
}

function _G._jumpEnsureProxy()
    local char = LP.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

function _G.AmbitiousApplyNormalInfJumpBoost(boost)
    if not infJumpEnabled then return end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local proxy = _G._jumpEnsureProxy()
    if not proxy then return end
    local curVel = proxy.AssemblyLinearVelocity
    local y = boost or 50
    proxy.AssemblyLinearVelocity = Vector3.new(curVel.X, y, curVel.Z)
    pcall(function()
        proxy.Velocity = Vector3.new(proxy.Velocity.X, y, proxy.Velocity.Z)
    end)
end

function _G.AmbitiousStopNormalInfJumpHoldState()
    local S = _G.AmbitiousNormalInfJump
    S.holdPressed = false
    S.holdActive = false
    S.controllerActive = false
    S.mobilePressed = false
    S.mobileActive = false
end

UIS.JumpRequest:Connect(function()
    if not infJumpEnabled then return end
    if UIS:GetFocusedTextBox() then return end
    _G.AmbitiousApplyNormalInfJumpBoost(50)
end)

UIS.InputBegan:Connect(function(input)
    if UIS:GetFocusedTextBox() then return end
    local S = _G.AmbitiousNormalInfJump

    if input.UserInputType == Enum.UserInputType.Keyboard
       and input.KeyCode == Enum.KeyCode.Space then
        if infJumpMode == "MANUAL" then return end
        S.holdPressed = true
        task.delay(0.12, function()
            if _G.AmbitiousNormalInfJump.holdPressed and infJumpEnabled then
                _G.AmbitiousNormalInfJump.holdActive = true
                _G.AmbitiousApplyNormalInfJumpBoost(50)
            end
        end)
    elseif input.KeyCode == Enum.KeyCode.ButtonA
       and input.UserInputType and tostring(input.UserInputType):find("Gamepad") then
        if infJumpMode ~= "MANUAL" then S.controllerActive = true end
    end
end)

UIS.InputEnded:Connect(function(input)
    local S = _G.AmbitiousNormalInfJump
    if input.UserInputType == Enum.UserInputType.Keyboard
       and input.KeyCode == Enum.KeyCode.Space then
        S.holdPressed = false
        S.holdActive  = false
    end
    if input.KeyCode == Enum.KeyCode.ButtonA
       and input.UserInputType and tostring(input.UserInputType):find("Gamepad") then
        S.controllerActive = false
    end
end)

function _G.AmbitiousHookNormalInfMobileJumpButton(obj)
    local S = _G.AmbitiousNormalInfJump
    if not obj or obj.Name ~= "JumpButton"
       or not obj:IsA("GuiButton") or S.hooked[obj] then return end
    S.hooked[obj] = true
    obj.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch
           or not infJumpEnabled then return end
        if infJumpMode == "MANUAL" then return end
        S.mobilePressed = true
        task.delay(0.12, function()
            if S.mobilePressed and infJumpEnabled then
                S.mobileActive = true
                _G.AmbitiousApplyNormalInfJumpBoost(50)
            end
        end)
    end)
    obj.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            S.mobilePressed = false
            S.mobileActive  = false
        end
    end)
end

do
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if pg then
        for _, obj in ipairs(pg:GetDescendants()) do
            _G.AmbitiousHookNormalInfMobileJumpButton(obj)
        end
        pg.DescendantAdded:Connect(function(obj)
            task.defer(_G.AmbitiousHookNormalInfMobileJumpButton, obj)
        end)
    end
end

RunService.Heartbeat:Connect(function()
    local S = _G.AmbitiousNormalInfJump
    if infJumpEnabled and infJumpMode == "HOLD"
       and (S.holdActive or S.mobileActive or S.controllerActive) then
        _G.AmbitiousApplyNormalInfJumpBoost(50)
    end
end)

function _G.setInfJumpInternal(on)
    infJumpEnabled = on and true or false
    if not infJumpEnabled then
        _G.AmbitiousStopNormalInfJumpHoldState()
        local ch = LP.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function()
                local v = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(v.X, math.min(v.Y, 0), v.Z)
            end)
        end
    end
    saveAntiBatState()
end

InfiniteJump = {
    start = function() _G.setInfJumpInternal(true)  end,
    stop  = function() _G.setInfJumpInternal(false) end,
    isRunning = function() return infJumpEnabled == true end,
    setJumpPower = function() end,
    setMode = function(mode)
        if mode == "manual" or mode == "MANUAL" then
            infJumpMode = "MANUAL"
            _G.AmbitiousStopNormalInfJumpHoldState()
        else
            infJumpMode = "HOLD"
        end
    end,
}

-- ============================================================
-- PANEL
-- ============================================================
function destroyAntiBatPanel()
    if antiBatPanelGui then
        pcall(function() antiBatPanelGui:Destroy() end)
        antiBatPanelGui = nil
    end
    antiBatPanelVisible = false
end

function createAntiBatPanel()
    pcall(destroyAntiBatPanel)

    local parent = getGuiParent()
    if not parent then warn("[AntiBat] PlayerGui yok") return end

    local BLUE  = Color3.fromRGB(255, 255, 255)
    local WHITE = Color3.fromRGB(255, 255, 255)
    local FULL_H = 168
    local MINI_H = 44
    local collapsed = antiBatPanelCollapsed == true

    local gui = Instance.new("ScreenGui")
    gui.Name = PANEL_NAME
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999
    gui.Parent = parent

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.ClipsDescendants = true
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    if antiBatPanelPos and type(antiBatPanelPos.XOffset) == "number" then
        Main.Position = UDim2.new(
            antiBatPanelPos.XScale or 0.5,
            antiBatPanelPos.XOffset or 0,
            antiBatPanelPos.YScale or 0.5,
            antiBatPanelPos.YOffset or 0
        )
    else
        Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    end
    Main.Size = UDim2.new(0, 260, 0, collapsed and MINI_H or FULL_H)
    Main.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Parent = gui
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke", Main)
    stroke.Color = BLUE
    stroke.Thickness = 1.4
    stroke.Transparency = 0.25

    local bg = Instance.new("ImageLabel", Main)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundTransparency = 1
    bg.Image = "rbxthumb://type=Asset&id=" .. BG_ASSET .. "&w=768&h=432"
    bg.ImageTransparency = 0.12
    bg.ScaleType = Enum.ScaleType.Crop
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 14)

    local dim = Instance.new("Frame", Main)
    dim.Size = UDim2.new(1, 0, 1, 0)
    dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dim.BackgroundTransparency = 0.45
    dim.BorderSizePixel = 0
    dim.ZIndex = 2
    Instance.new("UICorner", dim).CornerRadius = UDim.new(0, 14)

    -- Title
    local titleBar = Instance.new("Frame", Main)
    titleBar.Name = "TitleBar"
    titleBar.ZIndex = 5
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.Size = UDim2.new(1, 0, 0, 44)
    titleBar.BackgroundTransparency = 1
    titleBar.Active = true

    local title = Instance.new("TextLabel", titleBar)
    title.ZIndex = 5
    title.Position = UDim2.new(0, 14, 0, 4)
    title.Size = UDim2.new(1, -90, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "Sakura.vs Anti Bat"      -- ← Sakura.vs
    title.TextColor3 = BLUE
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left

    local minBtn = Instance.new("TextButton", titleBar)
    minBtn.Name = "Minimize"
    minBtn.ZIndex = 7
    minBtn.Position = UDim2.new(1, -64, 0, 9)
    minBtn.Size = UDim2.new(0, 26, 0, 26)
    minBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    minBtn.Text = collapsed and "□" or "_"
    minBtn.TextColor3 = WHITE
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 14
    minBtn.AutoButtonColor = false
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.ZIndex = 7
    closeBtn.Position = UDim2.new(1, -34, 0, 9)
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = WHITE
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.AutoButtonColor = false
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

    -- Content
    local content = Instance.new("Frame", Main)
    content.Name = "Content"
    content.ZIndex = 5
    content.Position = UDim2.new(0, 0, 0, 44)
    content.Size = UDim2.new(1, 0, 1, -44)
    content.BackgroundTransparency = 1
    content.Visible = not collapsed

    local line = Instance.new("Frame", content)
    line.ZIndex = 5
    line.Position = UDim2.new(0, 14, 0, 0)
    line.Size = UDim2.new(1, -28, 0, 1)
    line.BackgroundColor3 = BLUE
    line.BackgroundTransparency = 0.5
    line.BorderSizePixel = 0

    -- Inf Jump toggle row (tek satır)
    local row = Instance.new("Frame", content)
    row.ZIndex = 5
    row.Position = UDim2.new(0, 14, 0, 12)
    row.Size = UDim2.new(1, -28, 0, 44)
    row.BackgroundColor3 = Color3.fromRGB(6, 6, 12)
    row.BackgroundTransparency = 0.25
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    local rowStroke = Instance.new("UIStroke", row)
    rowStroke.Color = Color3.fromRGB(80, 80, 80)
    rowStroke.Transparency = 0.4

    local lbl = Instance.new("TextLabel", row)
    lbl.ZIndex = 6
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.Size = UDim2.new(1, -90, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Inf Jump"
    lbl.TextColor3 = WHITE
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("Frame", row)
    track.Name = "Track"
    track.ZIndex = 7
    track.Position = UDim2.new(1, -58, 0.5, -12)
    track.Size = UDim2.new(0, 46, 0, 24)
    track.BackgroundColor3 = infJumpEnabled and BLUE or Color3.fromRGB(55, 55, 68)
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", track)
    knob.Name = "Knob"
    knob.ZIndex = 8
    knob.Position = infJumpEnabled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.BackgroundColor3 = WHITE
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local toggleBtn = Instance.new("TextButton", track)
    toggleBtn.ZIndex = 9
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""

    local function setInfJumpVisual(on)
        TS:Create(track, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            BackgroundColor3 = on and BLUE or Color3.fromRGB(55, 55, 68)
        }):Play()
        TS:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        }):Play()
    end
    _G._antiBatPanelSetInfJumpVisual = setInfJumpVisual

    toggleBtn.MouseButton1Click:Connect(function()
        local newState = not infJumpEnabled
        _G.setInfJumpInternal(newState)
        setInfJumpVisual(newState)
    end)

    local footer = Instance.new("TextLabel", content)
    footer.ZIndex = 6
    footer.Position = UDim2.new(0, 0, 0, 74)
    footer.Size = UDim2.new(1, 0, 0, 18)
    footer.BackgroundTransparency = 1
    footer.Text = "discord.gg/SakuraDuels"
    footer.TextColor3 = Color3.fromRGB(180, 180, 180)
    footer.Font = Enum.Font.Gotham
    footer.TextSize = 11

    local function setCollapsed(on)
        collapsed = on and true or false
        antiBatPanelCollapsed = collapsed
        content.Visible = not collapsed
        Main.Size = UDim2.new(0, 260, 0, collapsed and MINI_H or FULL_H)
        minBtn.Text = collapsed and "□" or "_"
        saveAntiBatState()
    end

    minBtn.MouseButton1Click:Connect(function()
        setCollapsed(not collapsed)
    end)

    closeBtn.MouseButton1Click:Connect(function()
        destroyAntiBatPanel()
    end)

    -- Drag
    local dragging, dragStart, startPos, activeInput = false, nil, nil, nil
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            activeInput = input
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input == activeInput then
            if dragging then
                antiBatPanelPos = {
                    XScale = Main.Position.X.Scale, XOffset = Main.Position.X.Offset,
                    YScale = Main.Position.Y.Scale, YOffset = Main.Position.Y.Offset,
                }
                saveAntiBatState()
            end
            dragging = false
            activeInput = nil
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if dragging and (input == activeInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
            antiBatPanelPos = {
                XScale = Main.Position.X.Scale, XOffset = Main.Position.X.Offset,
                YScale = Main.Position.Y.Scale, YOffset = Main.Position.Y.Offset,
            }
            saveAntiBatState()
            dragging = false
            activeInput = nil
        end
    end)

    antiBatPanelGui = gui
    antiBatPanelVisible = true
    print("[Sakura AntiBat] Panel açıldı")
end

-- ============================================================
-- MINI TOGGLE BUTONU
-- ============================================================
local function createMiniToggle()
    local parent = getGuiParent()
    if not parent then return end

    local existing = parent:FindFirstChild(MINI_NAME)
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = MINI_NAME
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Parent = parent

    local btn = Instance.new("TextButton", gui)
    btn.Size = UDim2.new(0, 140, 0, 38)
    btn.Position = UDim2.new(1, -160, 0, 90)
    btn.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    btn.BorderSizePixel = 0
    btn.Text = "Anti Bat"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.Active = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local s = Instance.new("UIStroke", btn)
    s.Color = Color3.fromRGB(220, 220, 225)
    s.Thickness = 1.2
    s.Transparency = 0.3

    btn.MouseButton1Click:Connect(function()
        if antiBatPanelVisible then
            destroyAntiBatPanel()
        else
            createAntiBatPanel()
        end
    end)

    -- Drag
    local dragging, dragStart, startPos
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = btn.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                     startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ============================================================
-- BAŞLAT
-- ============================================================
task.spawn(function()
    local ok, err = pcall(function()
        local data = safeRead()
        if data then
            if data.antiBatPanelPos then antiBatPanelPos = data.antiBatPanelPos end
            antiBatPanelCollapsed = data.antiBatPanelCollapsed == true
        end

        createMiniToggle()
        createAntiBatPanel()

        if data and data.infJumpEnabled then
            task.defer(function()
                _G.setInfJumpInternal(true)
                if _G._antiBatPanelSetInfJumpVisual then
                    pcall(_G._antiBatPanelSetInfJumpVisual, true)
                end
            end)
        end

        -- RightShift: panel aç/kapat
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if UIS:GetFocusedTextBox() then return end
            if input.KeyCode == Enum.KeyCode.RightShift then
                if antiBatPanelVisible then
                    destroyAntiBatPanel()
                else
                    createAntiBatPanel()
                end
            end
        end)

        print("[Sakura.vs Anti Bat] yüklendi")
    end)
    if not ok then
        warn("[Sakura.vs Anti Bat] HATA:", err)
    end
end)