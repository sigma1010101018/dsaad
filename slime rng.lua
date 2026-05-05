-- SoloScripts | Slime RNG
-- Tabbed UI • Persistent settings • Auto-resume on teleport

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- =========================================================
-- LOADER URL

local LOADER_URL = "https://raw.githubusercontent.com/sigma1010101018/dsaad/refs/heads/main/slime%20rng.lua"

-- =========================================================
-- PERSISTENT STATE

local CONFIG_PATH = "SoloScripts_config.json"

local State = {
    AutoRoll = false,
    AutoEquipBest = false,
    AutoLoot = false,
    AutoKill = false,
    AutoRebirth = false,
    AutoUpgrade = false,
    AutoBuyZone = false,
    SpeedEnabled = false,
    SpeedValue = 32,
}

-- временный флаг что Auto Recipe сейчас работает (чтобы Auto Kill / Loot стояли)
local AutoRecipeRunning = false

local function saveState()
    if not (writefile and isfile) then return end
    pcall(function()
        writefile(CONFIG_PATH, HttpService:JSONEncode(State))
    end)
end

local function loadState()
    if not (isfile and readfile) then return end
    if not isfile(CONFIG_PATH) then return end
    pcall(function()
        local data = HttpService:JSONDecode(readfile(CONFIG_PATH))
        for k, v in pairs(data) do
            if State[k] ~= nil then
                State[k] = v
            end
        end
    end)
end

loadState()

if queue_on_teleport and LOADER_URL ~= "" then
    pcall(function()
        queue_on_teleport(string.format(
            'loadstring(game:HttpGet("%s"))()',
            LOADER_URL
        ))
    end)
end

if LOADER_URL ~= "" then
    LocalPlayer.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.Started then
            if queue_on_teleport then
                queue_on_teleport(string.format(
                    'loadstring(game:HttpGet("%s"))()',
                    LOADER_URL
                ))
            end
        end
    end)
end

-- =========================================================
-- REMOTES

local function getRemote(serviceName)
    local pkg = game:GetService("ReplicatedStorage")
        :WaitForChild("Packages")
        :WaitForChild("_Index")
        :WaitForChild("leifstout_networker@0.3.1")
        :WaitForChild("networker")
        :WaitForChild("_remotes")
    local svc = pkg:WaitForChild(serviceName)
    return svc:WaitForChild("RemoteFunction")
end

local Remotes = {
    Roll      = getRemote("RollService"),
    Inventory = getRemote("InventoryService"),
    Rebirth   = getRemote("RebirthService"),
    Upgrade   = getRemote("UpgradeService"),
    Zones     = getRemote("ZonesService"),
}

local function safeInvoke(remote, ...)
    local args = {...}
    pcall(function() remote:InvokeServer(unpack(args)) end)
end

local function getHRP()
    local char = LocalPlayer.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
end

-- =========================================================
-- ZONE NAMES

local ZONE_NAMES = {
    [1]="grasslands",[2]="desert",[3]="polar",[4]="volcano",[5]="islands",
    [6]="cave",[7]="heaven",[8]="jungle",[9]="canyon",[10]="mushroomForest",
    [11]="moon",[12]="redwoodForest",[13]="meteor",[14]="candyland",
    [15]="cherryGrove",[16]="crystalCavern",[17]="pumpkinPatch",[18]="atlantis",
    [19]="river",[20]="pyramid",[21]="graveyard",[22]="hotSprings",
    [23]="tribe",[24]="toxicWasteland",[25]="steampunk",
}

-- =========================================================
-- UPGRADES

local UPGRADES = {
    "voidRolls","enemySpawnSpeed3","luck2","bigEnemies","diamondRolls4",
    "rollSpeed6","friendLuck4","diamondRolls2","friendLuckBoost2","rollSpeed4",
    "voidRolls4","slimeTargetRange3","voidRolls2","rollSpeed2","invertedEnemyChance1",
    "shinySlimes","friendLuck1","playerTree","voidRolls3","enemyCount5",
    "hugeEnemyChance1","luck1","hugeSlimes","rollSpeed3","friendLuck3",
    "slots2","goopDropRate4","enemyCount4","slots4","cloverRolls3",
    "cloverRolls2","goopDropRate3","rollSpeed1","shinyEnemyChance1","diamondRolls3",
    "lootTree","slimeTargetRange1","luck9","shinyEnemies","extraRollChance2",
    "bonusRolls2","friendLuckBoost3","luck15","luck14","luck13","backpack",
    "luck12","luck11","friendLuckBoost1","cloverRolls4","luck8","autoRoll",
    "luck7","luck6","slots5","goldenRolls4","luck5","friendLuckBoost4","goop",
    "bonusRolls3","extraRollChance3","extraRollChance1","luck10","luck3",
    "cloverRolls1","goldenRolls3","enemyCount6","friendLuck5","friendLuck2",
    "goldenRolls","bigEnemyChance1","friendLuck6","diamondRolls","slots3",
    "enemySpawnSpeed1","goldenRolls2","rollSpeed5","enemyCount2","bonusRolls1",
    "enemyCount7","slots6","enemySpawnSpeed2","invertedEnemies","hugeEnemies",
    "luck4","goopDropRate6","goopDropRate5","goopDropRate2","enemyCount3",
    "goopDropRate1","invertedSlimes","bigSlimes","slimeTargetRange2","cloverRolls5",
    "offlineLootAmount2","coinIncome8","lootLuck","coinIncome12","overkill5",
    "lootCurrency","offlineLootAmount1","overkill1","coinIncome7","coinIncome5",
    "lootWatermelon","lootDrumstick","coinIncome10","overkill6","lootChicken",
    "lootPizza","overkill2","lootApple","coinIncome2","offlineLootAmount3",
    "coinIncome4","coinIncome3","offlineLootAmount5","coinIncome13","coinIncome1",
    "lootUltraLuck","coinIncome9","lootBanana","lootGrapes","overkill3",
    "lootCarrot","overkill4","offlineLootAmount4","lootCherries","coinIncome11",
    "lootRollSpeed","coinIncome6","walkSpeed1","magnet1","walkSpeed2","magnet3",
    "walkSpeed3","teleporter","magnet2"
}

-- =========================================================
-- ZONE HELPERS

local function getLatestUnlockedZoneNum()
    local zonesFolder = workspace:FindFirstChild("Zones")
    if not zonesFolder then return nil end

    for i = 1, 100 do
        local zone = zonesFolder:FindFirstChild(tostring(i))
        if not zone then break end

        local gate = zone:FindFirstChild("Gate")
        local back = gate and gate:FindFirstChild("Back")

        if back and back:IsA("BasePart") and back.CanCollide then
            return i
        end
    end
    return nil
end

local function getLatestUnlockedZone()
    local num = getLatestUnlockedZoneNum()
    if not num then return nil end
    return workspace.Zones:FindFirstChild(tostring(num))
end

local function isInsideZone(hrp, zone)
    local poi = zone:FindFirstChild("POI")
    local hitbox = poi and poi:FindFirstChild("Hitbox")
    if not (hitbox and hitbox:IsA("BasePart")) then return false end

    local rel = hitbox.CFrame:PointToObjectSpace(hrp.Position)
    return math.abs(rel.X) <= hitbox.Size.X / 2
       and math.abs(rel.Z) <= hitbox.Size.Z / 2
end

local function ensureInZone()
    local hrp = getHRP()
    if not hrp then return end

    local zone = getLatestUnlockedZone()
    if not zone then return end

    if not isInsideZone(hrp, zone) then
        local poi = zone:FindFirstChild("POI")
        if not poi then return end
        local target = poi:FindFirstChild("PlayerSpawn") or poi:FindFirstChild("Hitbox")
        if target then
            pcall(function()
                hrp.CFrame = target.CFrame + Vector3.new(0, 5, 0)
            end)
        end
    end
end

-- =========================================================
-- ENEMY HELPERS

local function getAllEnemies()
    local enemies = {}
    for _, zone in ipairs(workspace:GetChildren()) do
        if zone.Name:match("^Gameplay%d+$") then
            local folder = zone:FindFirstChild("Enemies")
            if folder then
                for _, enemy in ipairs(folder:GetChildren()) do
                    if enemy:IsA("Model") then
                        table.insert(enemies, enemy)
                    end
                end
            end
        end
    end
    return enemies
end

local function getClosestEnemy(hrp)
    local closest, closestDist
    for _, enemy in ipairs(getAllEnemies()) do
        local ok, pivot = pcall(function() return enemy:GetPivot() end)
        if ok then
            local dist = (pivot.Position - hrp.Position).Magnitude
            if not closestDist or dist < closestDist then
                closestDist = dist
                closest = enemy
            end
        end
    end
    return closest
end

-- =========================================================
-- RECIPE HELPERS

local function findProximityPrompt(part)
    for _, d in ipairs(part:GetDescendants()) do
        if d:IsA("ProximityPrompt") then return d end
    end
    if part.Parent then
        for _, d in ipairs(part.Parent:GetDescendants()) do
            if d:IsA("ProximityPrompt") then return d end
        end
    end
    return nil
end

local function findAllActiveRecipes()
    local recipes = {}
    local zones = workspace:FindFirstChild("Zones")
    if not zones then return recipes end

    for _, d in ipairs(zones:GetDescendants()) do
        if d:IsA("MeshPart") and d.Name:lower() == "recipe" then
            local prompt = findProximityPrompt(d)
            if prompt and prompt.Enabled then
                table.insert(recipes, { part = d, prompt = prompt })
            end
        end
    end
    return recipes
end

-- объявим заранее, реализация будет после того как UI создаст showInfoNotif
local showInfoNotif

local function collectAllRecipes()
    local recipes = findAllActiveRecipes()
    if #recipes == 0 then
        if showInfoNotif then
            showInfoNotif("No available recipes right now.")
        end
        return
    end

    AutoRecipeRunning = true
    local hrp = getHRP()
    if not hrp then AutoRecipeRunning = false; return end

    for _, r in ipairs(recipes) do
        if r.part.Parent and r.prompt.Enabled then
            pcall(function()
                hrp.CFrame = r.part.CFrame + Vector3.new(0, 3, 0)
            end)
            task.wait(0.2)
            pcall(function() fireproximityprompt(r.prompt) end)
            task.wait(0.5)
        end
    end

    AutoRecipeRunning = false
end

-- =========================================================
-- SPEED

local function applySpeed()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = State.SpeedEnabled and State.SpeedValue or 16
    end
end

RunService.Stepped:Connect(function()
    if State.SpeedEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= State.SpeedValue then
            hum.WalkSpeed = State.SpeedValue
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applySpeed()
end)

-- =========================================================
-- LOOPS

task.spawn(function()
    while task.wait() do
        if State.AutoRoll then safeInvoke(Remotes.Roll, "requestRoll") end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if State.AutoEquipBest then safeInvoke(Remotes.Inventory, "requestEquipBest") end
    end
end)

task.spawn(function()
    while task.wait(3) do
        if State.AutoRebirth then safeInvoke(Remotes.Rebirth, "requestRebirth") end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if State.AutoUpgrade then
            for _, name in ipairs(UPGRADES) do
                task.spawn(function()
                    safeInvoke(Remotes.Upgrade, "requestUnlock", name)
                end)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if State.AutoBuyZone then
            local currentNum = getLatestUnlockedZoneNum() or 1
            local nextNum = currentNum + 1
            local nextName = ZONE_NAMES[nextNum]
            if nextName then
                safeInvoke(Remotes.Zones, "requestPurchaseZone", nextName)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if State.AutoLoot and not AutoRecipeRunning then
            local hrp = getHRP()
            local lootFolder = workspace:FindFirstChild("Loot")
            if hrp and lootFolder then
                for _, item in ipairs(lootFolder:GetChildren()) do
                    if item:IsA("Model") then
                        pcall(function() hrp.CFrame = item:GetPivot() end)
                        task.wait(0.05)
                    end
                end
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    if State.AutoKill then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end
    end
end)

local prevAutoKill = false
task.spawn(function()
    while task.wait(0.2) do
        if prevAutoKill and not State.AutoKill then
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        pcall(function() p.CanCollide = true end)
                    end
                end
            end
        end
        prevAutoKill = State.AutoKill
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if State.AutoKill and not AutoRecipeRunning then
            local hrp = getHRP()
            if hrp then
                ensureInZone()

                local target = getClosestEnemy(hrp)
                if target then
                    local pivot = target:GetPivot()
                    local distance = (pivot.Position - hrp.Position).Magnitude
                    local tween = TweenService:Create(
                        hrp,
                        TweenInfo.new(math.max(distance / 80, 0.1), Enum.EasingStyle.Linear),
                        { CFrame = pivot * CFrame.new(0, 3, 0) }
                    )
                    tween:Play()
                    while target.Parent and State.AutoKill and not AutoRecipeRunning do
                        task.wait(0.1)
                    end
                    tween:Cancel()
                end
            end
        end
    end
end)

-- =========================================================
-- UI

local ACCENT = Color3.fromRGB(140, 110, 255)
local ACCENT_DARK = Color3.fromRGB(90, 70, 200)

local FULL_HEIGHT = 380
local COLLAPSED_HEIGHT = 36

local gui = Instance.new("ScreenGui")
gui.Name = "SoloScripts"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, FULL_HEIGHT)
main.Position = UDim2.new(0, 30, 0.5, -FULL_HEIGHT/2)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(45, 45, 55)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.3

local bgGrad = Instance.new("UIGradient", main)
bgGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 28)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 16)),
}
bgGrad.Rotation = 135

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleClip = Instance.new("Frame")
titleClip.Size = UDim2.new(1, 0, 0.5, 0)
titleClip.Position = UDim2.new(0, 0, 0.5, 0)
titleClip.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
titleClip.BorderSizePixel = 0
titleClip.Parent = titleBar

local titleLine = Instance.new("Frame")
titleLine.Size = UDim2.new(1, 0, 0, 1)
titleLine.Position = UDim2.new(0, 0, 1, -1)
titleLine.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
titleLine.BorderSizePixel = 0
titleLine.BackgroundTransparency = 0.4
titleLine.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -80, 1, 0)
titleText.Position = UDim2.new(0, 14, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "SoloScripts"
titleText.TextColor3 = Color3.fromRGB(235, 235, 240)
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 14
titleText.Parent = titleBar

local titleGradient = Instance.new("UIGradient", titleText)
titleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 170, 220)),
}

local collapseBtn = Instance.new("TextButton")
collapseBtn.Size = UDim2.new(0, 22, 0, 22)
collapseBtn.Position = UDim2.new(1, -58, 0, 7)
collapseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
collapseBtn.BorderSizePixel = 0
collapseBtn.Text = "−"
collapseBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.TextSize = 16
collapseBtn.AutoButtonColor = false
collapseBtn.Parent = titleBar
Instance.new("UICorner", collapseBtn).CornerRadius = UDim.new(1, 0)

collapseBtn.MouseEnter:Connect(function()
    TweenService:Create(collapseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 65)}):Play()
end)
collapseBtn.MouseLeave:Connect(function()
    TweenService:Create(collapseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}):Play()
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -30, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 35)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- =========================================================
-- TABS

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -16, 0, 30)
tabBar.Position = UDim2.new(0, 8, 0, 42)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main

local tabPages = {} -- name -> Frame
local tabButtons = {} -- name -> TextButton
local activeTab = nil

local function selectTab(name)
    activeTab = name
    for tabName, page in pairs(tabPages) do
        page.Visible = (tabName == name)
    end
    for tabName, btn in pairs(tabButtons) do
        local on = (tabName == name)
        local tweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad)
        if on then
            TweenService:Create(btn, tweenInfo, {BackgroundColor3 = ACCENT_DARK}):Play()
            TweenService:Create(btn.TextLabel, tweenInfo, {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
        else
            TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(28, 28, 36)}):Play()
            TweenService:Create(btn.TextLabel, tweenInfo, {TextColor3 = Color3.fromRGB(170, 170, 185)}):Play()
        end
    end
end

local function makeTab(name)
    local idx = 0
    for _ in pairs(tabButtons) do idx = idx + 1 end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, -3, 1, 0)
    btn.Position = UDim2.new(0.5 * idx, idx == 0 and 0 or 3, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = tabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local tabStroke = Instance.new("UIStroke", btn)
    tabStroke.Color = Color3.fromRGB(45, 45, 55)
    tabStroke.Thickness = 1
    tabStroke.Transparency = 0.4

    local lbl = Instance.new("TextLabel")
    lbl.Name = "TextLabel"
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(170, 170, 185)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.Parent = btn

    -- Page
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -16, 1, -82)
    page.Position = UDim2.new(0, 8, 0, 76)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = main

    local pageLayout = Instance.new("UIListLayout", page)
    pageLayout.Padding = UDim.new(0, 6)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder

    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 4)
    end)

    btn.MouseButton1Click:Connect(function() selectTab(name) end)

    tabPages[name] = page
    tabButtons[name] = btn

    return page
end

local mainPage = makeTab("Main")
local otherPage = makeTab("Other")
selectTab("Main")

-- =========================================================
-- COMPONENT FACTORIES

local function makeToggle(parent, label, key, onChange)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ClipsDescendants = true
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    local btnGrad = Instance.new("UIGradient", btn)
    btnGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 38)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 26)),
    }
    btnGrad.Rotation = 90

    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(40, 40, 52)
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.4

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 3, 0.6, 0)
    accentBar.Position = UDim2.new(0, 0, 0.2, 0)
    accentBar.BackgroundColor3 = ACCENT
    accentBar.BorderSizePixel = 0
    accentBar.BackgroundTransparency = 1
    accentBar.Parent = btn
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.Parent = btn

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 32, 0, 16)
    track.Position = UDim2.new(1, -42, 0.5, -8)
    track.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    track.BorderSizePixel = 0
    track.Parent = btn
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local trackStroke = Instance.new("UIStroke", track)
    trackStroke.Color = Color3.fromRGB(60, 60, 75)
    trackStroke.Thickness = 1
    trackStroke.Transparency = 0.3

    local knobShadow = Instance.new("Frame")
    knobShadow.Size = UDim2.new(0, 14, 0, 14)
    knobShadow.Position = UDim2.new(0, 1, 0.5, -6)
    knobShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    knobShadow.BackgroundTransparency = 0.5
    knobShadow.BorderSizePixel = 0
    knobShadow.Parent = track
    Instance.new("UICorner", knobShadow).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(0, 2, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(190, 190, 200)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local knobGrad = Instance.new("UIGradient", knob)
    knobGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 215)),
    }
    knobGrad.Rotation = 90

    local function refresh()
        local on = State[key]
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        if on then
            TweenService:Create(track, tweenInfo, {BackgroundColor3 = ACCENT_DARK}):Play()
            TweenService:Create(trackStroke, tweenInfo, {Color = ACCENT, Transparency = 0.2}):Play()
            TweenService:Create(knob, tweenInfo, {Position = UDim2.new(1, -14, 0.5, -6)}):Play()
            TweenService:Create(knobShadow, tweenInfo, {Position = UDim2.new(1, -13, 0.5, -6)}):Play()
            TweenService:Create(accentBar, tweenInfo, {BackgroundTransparency = 0}):Play()
            TweenService:Create(btnStroke, tweenInfo, {Color = ACCENT, Transparency = 0.5}):Play()
            TweenService:Create(lbl, tweenInfo, {TextColor3 = Color3.fromRGB(240, 240, 250)}):Play()
        else
            TweenService:Create(track, tweenInfo, {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play()
            TweenService:Create(trackStroke, tweenInfo, {Color = Color3.fromRGB(60, 60, 75), Transparency = 0.3}):Play()
            TweenService:Create(knob, tweenInfo, {Position = UDim2.new(0, 2, 0.5, -6)}):Play()
            TweenService:Create(knobShadow, tweenInfo, {Position = UDim2.new(0, 1, 0.5, -6)}):Play()
            TweenService:Create(accentBar, tweenInfo, {BackgroundTransparency = 1}):Play()
            TweenService:Create(btnStroke, tweenInfo, {Color = Color3.fromRGB(40, 40, 52), Transparency = 0.4}):Play()
            TweenService:Create(lbl, tweenInfo, {TextColor3 = Color3.fromRGB(200, 200, 210)}):Play()
        end
    end

    btn.MouseButton1Click:Connect(function()
        State[key] = not State[key]
        refresh()
        saveState()
        if onChange then onChange(State[key]) end
    end)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 30, 38)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(24, 24, 30)}):Play()
    end)

    refresh()
end

local function makeButton(parent, label, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ClipsDescendants = true
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    local btnGrad = Instance.new("UIGradient", btn)
    btnGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 38)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 26)),
    }
    btnGrad.Rotation = 90

    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(40, 40, 52)
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.4

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -28, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.Parent = btn

    -- Стрелка справа
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 16, 1, 0)
    arrow.Position = UDim2.new(1, -22, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▶"
    arrow.TextColor3 = ACCENT
    arrow.Font = Enum.Font.Gotham
    arrow.TextSize = 10
    arrow.Parent = btn

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = ACCENT_DARK}):Play()
        task.wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 30, 38)}):Play()
        task.spawn(callback)
    end)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(34, 34, 42)}):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = ACCENT, Transparency = 0.5}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(24, 24, 30)}):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(40, 40, 52), Transparency = 0.4}):Play()
    end)
end

local function makeSlider(parent, label, key, min, max, onChange)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    container.BorderSizePixel = 0
    container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 7)

    local cGrad = Instance.new("UIGradient", container)
    cGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 38)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 26)),
    }
    cGrad.Rotation = 90

    local cStroke = Instance.new("UIStroke", container)
    cStroke.Color = Color3.fromRGB(40, 40, 52)
    cStroke.Thickness = 1
    cStroke.Transparency = 0.4

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 0, 18)
    lbl.Position = UDim2.new(0, 14, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.Parent = container

    local valueLbl = Instance.new("TextLabel")
    valueLbl.Size = UDim2.new(0, 40, 0, 18)
    valueLbl.Position = UDim2.new(1, -50, 0, 6)
    valueLbl.BackgroundTransparency = 1
    valueLbl.Text = tostring(State[key])
    valueLbl.TextColor3 = ACCENT
    valueLbl.TextXAlignment = Enum.TextXAlignment.Right
    valueLbl.Font = Enum.Font.GothamBold
    valueLbl.TextSize = 12
    valueLbl.Parent = container

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -28, 0, 6)
    barBg.Position = UDim2.new(0, 14, 1, -16)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
    barBg.BorderSizePixel = 0
    barBg.Parent = container
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((State[key] - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = barBg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local fillGrad = Instance.new("UIGradient", fill)
    fillGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, ACCENT),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 140, 255)),
    }

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((State[key] - min) / (max - min), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = barBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local knobStroke = Instance.new("UIStroke", knob)
    knobStroke.Color = ACCENT
    knobStroke.Thickness = 2

    local dragging = false
    local function update(input)
        local pos = input.Position.X
        local barAbs = barBg.AbsolutePosition.X
        local barW = barBg.AbsoluteSize.X
        local rel = math.clamp((pos - barAbs) / barW, 0, 1)
        local val = math.floor(min + (max - min) * rel + 0.5)
        State[key] = val
        valueLbl.Text = tostring(val)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        if onChange then onChange(val) end
    end

    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            main.Draggable = false
            main.Active = false
            update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                main.Draggable = true
                main.Active = true
                saveState()
            end
        end
    end)
end

-- =========================================================
-- COLLAPSE

local collapsed = false
collapseBtn.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    if collapsed then
        TweenService:Create(main, tweenInfo, {Size = UDim2.new(0, 260, 0, COLLAPSED_HEIGHT)}):Play()
        collapseBtn.Text = "+"
        for _, page in pairs(tabPages) do
            TweenService:Create(page, TweenInfo.new(0.15), {GroupTransparency = 1}):Play()
        end
        TweenService:Create(tabBar, TweenInfo.new(0.15), {GroupTransparency = 1}):Play()
    else
        TweenService:Create(main, tweenInfo, {Size = UDim2.new(0, 260, 0, FULL_HEIGHT)}):Play()
        collapseBtn.Text = "−"
        for _, page in pairs(tabPages) do
            TweenService:Create(page, TweenInfo.new(0.25), {GroupTransparency = 0}):Play()
        end
        TweenService:Create(tabBar, TweenInfo.new(0.25), {GroupTransparency = 0}):Play()
    end
end)

-- =========================================================
-- MAIN TAB CONTENT

makeToggle(mainPage, "Auto Roll", "AutoRoll")
makeToggle(mainPage, "Auto Equip Best", "AutoEquipBest")
makeToggle(mainPage, "Auto Loot", "AutoLoot")
makeToggle(mainPage, "Auto Kill", "AutoKill")
makeToggle(mainPage, "Auto Rebirth", "AutoRebirth")
makeToggle(mainPage, "Auto Upgrade", "AutoUpgrade")
makeToggle(mainPage, "Auto Buy Zone", "AutoBuyZone")

-- =========================================================
-- OTHER TAB CONTENT

makeButton(otherPage, "Auto Recipe (collect now)", function()
    collectAllRecipes()
end)

makeToggle(otherPage, "Speed", "SpeedEnabled", function() applySpeed() end)
makeSlider(otherPage, "Speed Value", "SpeedValue", 16, 200, function() applySpeed() end)

-- =========================================================
-- KEYBIND

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
    end
end)

main.BackgroundTransparency = 1
TweenService:Create(main, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()

-- =========================================================
-- INFO NOTIFICATION (универсальная функция для попапов)

local notifSlot = 0

local function makeNotif(text, options)
    options = options or {}
    local autoCloseAfter = options.autoCloseAfter or 5
    local hasLink = options.link ~= nil

    local height = hasLink and 130 or 80
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 320, 0, height)
    notif.Position = UDim2.new(1, 20, 1, -(height + 20 + notifSlot * (height + 10)))
    notif.AnchorPoint = Vector2.new(0, 0)
    notif.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    notif.BorderSizePixel = 0
    notif.Parent = gui
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 10)

    local notifStroke = Instance.new("UIStroke", notif)
    notifStroke.Color = Color3.fromRGB(45, 45, 55)
    notifStroke.Thickness = 1
    notifStroke.Transparency = 0.3

    local notifGrad = Instance.new("UIGradient", notif)
    notifGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 28)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 16)),
    }
    notifGrad.Rotation = 135

    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(0, 3, 1, -16)
    accentLine.Position = UDim2.new(0, 0, 0, 8)
    accentLine.BackgroundColor3 = ACCENT
    accentLine.BorderSizePixel = 0
    accentLine.Parent = notif
    Instance.new("UICorner", accentLine).CornerRadius = UDim.new(1, 0)

    local notifTitle = Instance.new("TextLabel")
    notifTitle.Size = UDim2.new(1, -50, 0, 20)
    notifTitle.Position = UDim2.new(0, 14, 0, 10)
    notifTitle.BackgroundTransparency = 1
    notifTitle.Text = options.title or "SoloScripts"
    notifTitle.TextColor3 = Color3.fromRGB(240, 240, 248)
    notifTitle.TextXAlignment = Enum.TextXAlignment.Left
    notifTitle.Font = Enum.Font.GothamBold
    notifTitle.TextSize = 14
    notifTitle.Parent = notif

    local notifTitleGrad = Instance.new("UIGradient", notifTitle)
    notifTitleGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 170, 220)),
    }

    local notifClose = Instance.new("TextButton")
    notifClose.Size = UDim2.new(0, 20, 0, 20)
    notifClose.Position = UDim2.new(1, -28, 0, 10)
    notifClose.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
    notifClose.BorderSizePixel = 0
    notifClose.Text = "×"
    notifClose.TextColor3 = Color3.fromRGB(200, 200, 210)
    notifClose.Font = Enum.Font.GothamBold
    notifClose.TextSize = 14
    notifClose.Parent = notif
    Instance.new("UICorner", notifClose).CornerRadius = UDim.new(1, 0)

    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -28, 0, 28)
    body.Position = UDim2.new(0, 14, 0, 32)
    body.BackgroundTransparency = 1
    body.Text = text
    body.TextColor3 = Color3.fromRGB(170, 170, 185)
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextWrapped = true
    body.Font = Enum.Font.Gotham
    body.TextSize = 11
    body.Parent = notif

    if hasLink then
        local linkBox = Instance.new("Frame")
        linkBox.Size = UDim2.new(1, -28, 0, 28)
        linkBox.Position = UDim2.new(0, 14, 1, -38)
        linkBox.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
        linkBox.BorderSizePixel = 0
        linkBox.Parent = notif
        Instance.new("UICorner", linkBox).CornerRadius = UDim.new(0, 6)

        local linkBoxStroke = Instance.new("UIStroke", linkBox)
        linkBoxStroke.Color = Color3.fromRGB(45, 45, 55)
        linkBoxStroke.Thickness = 1
        linkBoxStroke.Transparency = 0.4

        local linkText = Instance.new("TextLabel")
        linkText.Size = UDim2.new(1, -54, 1, 0)
        linkText.Position = UDim2.new(0, 8, 0, 0)
        linkText.BackgroundTransparency = 1
        linkText.Text = options.link
        linkText.TextColor3 = Color3.fromRGB(180, 160, 240)
        linkText.TextXAlignment = Enum.TextXAlignment.Left
        linkText.Font = Enum.Font.Code
        linkText.TextSize = 10
        linkText.TextTruncate = Enum.TextTruncate.AtEnd
        linkText.Parent = linkBox

        local copyBtn = Instance.new("TextButton")
        copyBtn.Size = UDim2.new(0, 42, 1, -6)
        copyBtn.Position = UDim2.new(1, -45, 0, 3)
        copyBtn.BackgroundColor3 = ACCENT_DARK
        copyBtn.BorderSizePixel = 0
        copyBtn.Text = "Copy"
        copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.TextSize = 10
        copyBtn.AutoButtonColor = false
        copyBtn.Parent = linkBox
        Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 4)

        copyBtn.MouseEnter:Connect(function()
            TweenService:Create(copyBtn, TweenInfo.new(0.15), {BackgroundColor3 = ACCENT}):Play()
        end)
        copyBtn.MouseLeave:Connect(function()
            TweenService:Create(copyBtn, TweenInfo.new(0.15), {BackgroundColor3 = ACCENT_DARK}):Play()
        end)

        copyBtn.MouseButton1Click:Connect(function()
            if setclipboard then pcall(setclipboard, options.link) end
            local origText = copyBtn.Text
            copyBtn.Text = "✓"
            TweenService:Create(copyBtn, TweenInfo.new(0.15),
                {BackgroundColor3 = Color3.fromRGB(80, 200, 120)}):Play()
            task.wait(1.2)
            copyBtn.Text = origText
            TweenService:Create(copyBtn, TweenInfo.new(0.15),
                {BackgroundColor3 = ACCENT_DARK}):Play()
        end)
    end

    local mySlot = notifSlot
    notifSlot = notifSlot + 1

    local targetPos = UDim2.new(1, -340, 1, -(height + 20 + mySlot * (height + 10)))
    TweenService:Create(notif,
        TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = targetPos}
    ):Play()

    local closing = false
    local function close()
        if closing then return end
        closing = true
        TweenService:Create(notif,
            TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 20, targetPos.Y.Scale, targetPos.Y.Offset)}
        ):Play()
        task.wait(0.4)
        notif:Destroy()
        notifSlot = math.max(0, notifSlot - 1)
    end

    notifClose.MouseButton1Click:Connect(close)

    if autoCloseAfter > 0 then
        task.spawn(function()
            task.wait(autoCloseAfter)
            if notif.Parent then close() end
        end)
    end
end

-- объявленный выше showInfoNotif теперь реализован
showInfoNotif = function(text)
    makeNotif(text, { title = "SoloScripts", autoCloseAfter = 4 })
end

-- =========================================================
-- WELCOME

task.spawn(function()
    makeNotif(
        "This is the only official source of scripts. If you see a script that is not from me — it is stolen.",
        {
            title = "SoloScripts",
            link = "https://scriptblox.com/script/Slime-RNG-Full-autofarm-212541",
            autoCloseAfter = 12
        }
    )
end)
