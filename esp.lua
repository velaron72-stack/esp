local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    HueSpeed = 0.4,
    BoxWidthRatio = 0.45,
    BoxPadding = 8,
    BoxThickness = 2,
    UniqueColorPerPlayer = true,
    ShowName = true,
    ShowDistance = true,
    NameTextSize = 14,
    DistanceTextSize = 12,
    MaxDistance = 10000,
    MinScale = 0.15,
    ToggleButtonSize = 56,
    ToggleButtonPosition = UDim2.new(0, 20, 0, 20),
}

local espEnabled = true
local entries = {}
local hue = 0

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function buildBox()
    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false

    local stroke = Instance.new("UIStroke")
    stroke.Name = "BoxStroke"
    stroke.Thickness = CONFIG.BoxThickness
    stroke.Parent = box

    return box, stroke
end

local function buildTextLabel(name, textSize)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = ""
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = textSize
    label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
    label.TextStrokeTransparency = 0.6
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.XY
    label.Visible = false
    return label
end

local function buildToggleButton(parent)
    local btn = Instance.new("TextButton")
    btn.Name = "ESPToggle"
    btn.Size = UDim2.new(0, CONFIG.ToggleButtonSize, 0, CONFIG.ToggleButtonSize)
    btn.Position = CONFIG.ToggleButtonPosition
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.Text = "ESP"
    btn.TextColor3 = Color3.fromRGB(80, 255, 80)
    btn.TextSize = 16
    btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    btn.AutoButtonColor = true
    btn.Active = true
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Name = "ToggleStroke"
    stroke.Color = Color3.fromRGB(80, 255, 80)
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = btn

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.Parent = btn

    local pulseTime = os.clock()

    btn.Activated:Connect(function()
        espEnabled = not espEnabled
        pulseTime = os.clock()

        if espEnabled then
            btn.TextColor3 = Color3.fromRGB(80, 255, 80)
            stroke.Color = Color3.fromRGB(80, 255, 80)
        else
            btn.TextColor3 = Color3.fromRGB(255, 80, 80)
            stroke.Color = Color3.fromRGB(255, 80, 80)
            for _, entry in pairs(entries) do
                entry.Container.Visible = false
            end
        end

        TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, CONFIG.ToggleButtonSize * 1.25, 0, CONFIG.ToggleButtonSize * 1.25)
        }):Play()

        task.delay(0.12, function()
            TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, CONFIG.ToggleButtonSize, 0, CONFIG.ToggleButtonSize)
            }):Play()
        end)
    end)

    RunService.RenderStepped:Connect(function()
        local elapsed = os.clock() - pulseTime
        if elapsed < 1.5 then
            local pulse = (1 - elapsed / 1.5) * 0.3
            stroke.Transparency = 0.5 - pulse
        else
            stroke.Transparency = 0.5
        end
    end)

    return btn
end

local function createEntry(player)
    if player == LocalPlayer then return nil end

    local container = Instance.new("Frame")
    container.Name = "ESP_" .. player.Name
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Visible = false

    local box, boxStroke = buildBox()
    box.Parent = container

    local nameLabel = buildTextLabel("NameLabel", CONFIG.NameTextSize)
    nameLabel.Parent = container

    local distanceLabel = buildTextLabel("DistanceLabel", CONFIG.DistanceTextSize)
    distanceLabel.Parent = container

    return {
        Player = player,
        Container = container,
        Box = box,
        BoxStroke = boxStroke,
        NameLabel = nameLabel,
        DistanceLabel = distanceLabel,
    }
end

local gui = Instance.new("ScreenGui")
gui.Name = "CheatsGameESP"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local toggleBtn = buildToggleButton(gui)

local function trackPlayer(player)
    if entries[player] then return end
    local entry = createEntry(player)
    if entry then
        entry.Container.Parent = gui
        entries[player] = entry
    end
end

local function untrackPlayer(player)
    local entry = entries[player]
    if not entry then return end
    entry.Container:Destroy()
    entries[player] = nil
end

local function getDistanceScale(distance)
    local t = math.min(distance / CONFIG.MaxDistance, 1)
    return math.clamp((1 - t) ^ 1.5, CONFIG.MinScale, 1)
end

local function getCharacterWorldHeight(root, head, humanoid)
    local topY = head.Position.Y + head.Size.Y * 0.5
    local bottomY = root.Position.Y - root.Size.Y * 0.5 - humanoid.HipHeight
    return topY - bottomY
end

for _, player in ipairs(Players:GetPlayers()) do
    trackPlayer(player)
end

Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(untrackPlayer)

RunService.RenderStepped:Connect(function(dt)
    if not espEnabled then
        for _, entry in pairs(entries) do
            entry.Container.Visible = false
        end
        return
    end

    local camera = Workspace.CurrentCamera
    if not camera then return end

    local viewportSize = camera.ViewportSize
    local fovRad = math.rad(camera.FieldOfView)
    local focalLength = (viewportSize.Y * 0.5) / math.tan(fovRad * 0.5)

    hue = (hue + dt * CONFIG.HueSpeed) % 1

    for player, entry in pairs(entries) do
        local character = player.Character
        if not character then
            entry.Container.Visible = false
            continue
        end

        local root = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local head = character:FindFirstChild("Head")

        if not root or not humanoid or humanoid.Health <= 0 or not head then
            entry.Container.Visible = false
            continue
        end

        local rootPos = root.Position
        local localChar = LocalPlayer.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

        if not localRoot then
            entry.Container.Visible = false
            continue
        end

        local distance = (rootPos - localRoot.Position).Magnitude

        local scale = getDistanceScale(distance)

        local colorHue = hue
        if CONFIG.UniqueColorPerPlayer then
            colorHue = (hue + (player.UserId % 100) / 100) % 1
        end
        local color = Color3.fromHSV(colorHue, 1, 1)

        local rootScreen, onScreen = camera:WorldToViewportPoint(rootPos)
        if not onScreen then
            entry.Container.Visible = false
            continue
        end

        local worldHeight = getCharacterWorldHeight(root, head, humanoid)
        local depth = math.max(rootScreen.Z, 1)
        local screenHeightPx = (worldHeight * focalLength) / depth
        screenHeightPx = math.clamp(screenHeightPx * scale, 4, viewportSize.Y)

        local boxH = screenHeightPx + CONFIG.BoxPadding * 2
        local boxW = boxH * CONFIG.BoxWidthRatio

        entry.Container.Position = UDim2.new(0, rootScreen.X - boxW / 2, 0, rootScreen.Y - boxH / 2)
        entry.Container.Size = UDim2.new(0, boxW, 0, boxH)
        entry.Container.Visible = true

        entry.Box.Size = UDim2.new(1, 0, 1, 0)
        entry.Box.Visible = true
        entry.BoxStroke.Color = color
        entry.BoxStroke.Thickness = math.max(CONFIG.BoxThickness * scale, 1)

        if CONFIG.ShowName then
            entry.NameLabel.Text = player.DisplayName
            entry.NameLabel.Position = UDim2.new(0.5, 0, 0, -18 * scale)
            entry.NameLabel.AnchorPoint = Vector2.new(0.5, 1)
            entry.NameLabel.TextSize = CONFIG.NameTextSize * scale
            entry.NameLabel.Visible = true
        else
            entry.NameLabel.Visible = false
        end

        if CONFIG.ShowDistance then
            local dist = math.floor(distance)
            entry.DistanceLabel.Text = tostring(dist) .. "m"
            entry.DistanceLabel.Position = UDim2.new(0.5, 0, 1, 4 * scale)
            entry.DistanceLabel.AnchorPoint = Vector2.new(0.5, 0)
            entry.DistanceLabel.TextSize = CONFIG.DistanceTextSize * scale
            entry.DistanceLabel.Visible = true
        else
            entry.DistanceLabel.Visible = false
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    for _, entry in pairs(entries) do
        entry.Container.Visible = false
    end
end)
