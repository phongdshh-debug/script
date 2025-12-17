
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- =========================
-- SERVICES
-- =========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- =========================
-- SETTINGS
-- =========================
local ESPSettings = {
    Enabled = true,
    TeamCheck = true,

    CenterDot = true,

    EnemyColor = Color3.fromRGB(255, 120, 120),
    TeamColor = Color3.fromRGB(120, 255, 180),

    NameSize = 30,
    DotRadius = 5
}

-- =========================
-- TOGGLE KEY
-- =========================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightAlt then
        ESPSettings.Enabled = not ESPSettings.Enabled
        warn("[ESP]", ESPSettings.Enabled and "ENABLED" or "DISABLED")
    end
end)

-- =========================
-- STORAGE
-- =========================
local ESPObjects = {}

-- =========================
-- CREATE ESP
-- =========================
local function CreateESP(Player)
    if Player == LocalPlayer or ESPObjects[Player] then return end

    local Name = Drawing.new("Text")
    Name.Center = true
    Name.Outline = true
    Name.OutlineColor = Color3.new(0,0,0)
    Name.Size = ESPSettings.NameSize
    Name.Font = 3
    Name.Visible = false

    local Dot = Drawing.new("Circle")
    Dot.Filled = true
    Dot.Radius = ESPSettings.DotRadius
    Dot.Visible = false

    ESPObjects[Player] = {
        Name = Name,
        Dot = Dot
    }

    Player.CharacterAdded:Connect(function()
        task.wait(0.15)
    end)
end

-- =========================
-- REMOVE ESP
-- =========================
local function RemoveESP(Player)
    if ESPObjects[Player] then
        for _, obj in pairs(ESPObjects[Player]) do
            obj:Remove()
        end
        ESPObjects[Player] = nil
    end
end

-- =========================
-- PLAYER CONNECTIONS
-- =========================
for _, Player in ipairs(Players:GetPlayers()) do
    CreateESP(Player)
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- =========================
-- RENDER LOOP
-- =========================
RunService.RenderStepped:Connect(function()
    for Player, ESP in pairs(ESPObjects) do
        if not ESPSettings.Enabled then
            for _, obj in pairs(ESP) do obj.Visible = false end
            continue
        end

        local Character = Player.Character
        local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character and Character:FindFirstChild("Humanoid")

        if not Character or not HRP or not Humanoid or Humanoid.Health <= 0 then
            for _, obj in pairs(ESP) do obj.Visible = false end
            continue
        end

        if ESPSettings.TeamCheck and Player.Team == LocalPlayer.Team then
            for _, obj in pairs(ESP) do obj.Visible = false end
            continue
        end

        local Pos, OnScreen = Camera:WorldToViewportPoint(HRP.Position)
        if not OnScreen then
            for _, obj in pairs(ESP) do obj.Visible = false end
            continue
        end

        local DistanceStuds = (Camera.CFrame.Position - HRP.Position).Magnitude
        local DistanceMeters = math.floor(DistanceStuds)

        local DrawColor =
            (Player.Team == LocalPlayer.Team)
            and ESPSettings.TeamColor
            or ESPSettings.EnemyColor

        -- NAME + DISTANCE FORMAT
        ESP.Name.Text = string.format("%s (%dm)", Player.Name, DistanceMeters)
        ESP.Name.Position = Vector2.new(Pos.X, Pos.Y - 18)
        ESP.Name.Color = DrawColor
        ESP.Name.Visible = true

        -- CENTER DOT
        ESP.Dot.Position = Vector2.new(Pos.X, Pos.Y - 2)
        ESP.Dot.Color = DrawColor
        ESP.Dot.Visible = ESPSettings.CenterDot
    end
end)
