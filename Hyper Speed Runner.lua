

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local TS = TweenService
local Q  = TweenInfo.new

-- ═══════════════════════════════════════════════════
-- KEY SYSTEM
-- ═══════════════════════════════════════════════════

local CORRECT_KEY  = "k1~!oo021"
local DISCORD_LINK = "https://discord.gg/ezscript"

local function getHWID()
    local ok, r = pcall(function()
        if identifyexecutor then
            return identifyexecutor().."_"..game:GetService("RbxAnalyticsService"):GetClientId()
        end
        return "PC_"..player.UserId.."_"..os.time()
    end)
    return (ok and r) or ("PC_"..player.UserId.."_"..os.time())
end

local function loadData()
    local ok, d = pcall(function()
        if readfile and isfile and isfile("EzScript_KEY.txt") then
            local c = readfile("EzScript_KEY.txt")
            if c and c ~= "" then return HttpService:JSONDecode(c) end
        end
    end)
    return (ok and d) or {}
end

local function saveData(d)
    pcall(function()
        if writefile then writefile("EzScript_KEY.txt", HttpService:JSONEncode(d)) end
    end)
end

local savedData   = loadData()
local currentHWID = getHWID()
local keyVerified = false

if type(savedData) == "table" then
    for k, v in pairs(savedData) do
        if v == currentHWID and k == CORRECT_KEY then keyVerified = true; break end
    end
end

-- ═══════════════════════════════════════════════════
-- STATE (оригинальная логика)
-- ═══════════════════════════════════════════════════

local toggles = {
    AutoCash    = false,
    AutoRebirth = false,
}

-- ═══════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════

for _, n in ipairs({"EzScriptUI","EzLoad","BlackWhiteHub"}) do
    pcall(function() if CoreGui:FindFirstChild(n) then CoreGui[n]:Destroy() end end)
    pcall(function() if player.PlayerGui:FindFirstChild(n) then player.PlayerGui[n]:Destroy() end end)
end

-- ═══════════════════════════════════════════════════
-- COLORS
-- ═══════════════════════════════════════════════════

local C = {
    BG    = Color3.fromRGB(8,8,10),
    BG2   = Color3.fromRGB(14,14,18),
    BG3   = Color3.fromRGB(22,22,28),
    LINE  = Color3.fromRGB(255,255,255),
    LINE2 = Color3.fromRGB(50,50,62),
    TEXT  = Color3.fromRGB(225,225,232),
    DIM   = Color3.fromRGB(80,80,96),
    WHITE = Color3.fromRGB(255,255,255),
    GREEN = Color3.fromRGB(90,255,140),
    RED   = Color3.fromRGB(255,75,75),
}

-- ═══════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════

local function rnd(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6); c.Parent = p; return c
end

local function mkStroke(p, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or C.LINE2; s.Thickness = th or 1
    s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p; return s
end

local function tw(obj, t, props)
    TS:Create(obj, Q(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function pulse(obj, prop, a, b, t)
    t = t or 0.7
    task.spawn(function()
        while obj and obj.Parent do
            TS:Create(obj,Q(t,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{[prop]=a}):Play()
            task.wait(t)
            TS:Create(obj,Q(t,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{[prop]=b}):Play()
            task.wait(t)
        end
    end)
end

local GCHARS = {"#","@","!","%","&","$","*","?","<",">","\\","|","_","~"}
local function glitch(obj, orig, reps, spd)
    reps=reps or 4; spd=spd or 0.035
    task.spawn(function()
        for _=1,reps do
            local g=""
            for i=1,#orig do
                g=g..(math.random(1,4)==1 and GCHARS[math.random(1,#GCHARS)] or orig:sub(i,i))
            end
            obj.Text=g; task.wait(spd)
        end
        obj.Text=orig
    end)
end

local function typeWrite(obj, txt, spd)
    spd=spd or 0.025; obj.Text=""
    for i=1,#txt do obj.Text=txt:sub(1,i); task.wait(spd) end
end

-- ═══════════════════════════════════════════════════
-- LOADING SCREEN
-- ═══════════════════════════════════════════════════

local LoadGui = Instance.new("ScreenGui")
LoadGui.Name="EzLoad"; LoadGui.ResetOnSpawn=false
LoadGui.IgnoreGuiInset=true
LoadGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
pcall(function() LoadGui.Parent=CoreGui end)
if not LoadGui.Parent then LoadGui.Parent=player:WaitForChild("PlayerGui") end

local LBG=Instance.new("Frame",LoadGui)
LBG.Size=UDim2.new(1,0,1,0); LBG.BackgroundColor3=C.BG
LBG.BorderSizePixel=0; LBG.ZIndex=1

-- Grid
local GRID=Instance.new("Frame",LBG)
GRID.Size=UDim2.new(1,0,1,0); GRID.BackgroundTransparency=1; GRID.ZIndex=2
for i=0,20 do
    local v=Instance.new("Frame",GRID); v.Size=UDim2.new(0,1,1,0)
    v.Position=UDim2.new(i/20,0,0,0); v.BackgroundColor3=C.LINE
    v.BackgroundTransparency=0.97; v.BorderSizePixel=0; v.ZIndex=2
    local h=Instance.new("Frame",GRID); h.Size=UDim2.new(1,0,0,1)
    h.Position=UDim2.new(0,0,i/20,0); h.BackgroundColor3=C.LINE
    h.BackgroundTransparency=0.97; h.BorderSizePixel=0; h.ZIndex=2
end

-- Scanlines
local SL=Instance.new("Frame",LBG); SL.Size=UDim2.new(1,0,1,0)
SL.BackgroundTransparency=1; SL.ZIndex=12
for i=0,100 do
    local ln=Instance.new("Frame",SL); ln.Size=UDim2.new(1,0,0,1)
    ln.Position=UDim2.new(0,0,0,i*10); ln.BackgroundColor3=C.WHITE
    ln.BackgroundTransparency=0.965; ln.BorderSizePixel=0; ln.ZIndex=12
end

-- Particles
local PARTS=Instance.new("Frame",LBG); PARTS.Size=UDim2.new(1,0,1,0)
PARTS.BackgroundTransparency=1; PARTS.ZIndex=3
local function spawnP()
    local p=Instance.new("Frame",PARTS); local sz=math.random(2,4)
    p.Size=UDim2.new(0,sz,0,sz); p.BorderSizePixel=0
    p.Position=UDim2.new(math.random(5,95)/100,0,math.random(10,90)/100,0)
    p.BackgroundColor3=C.WHITE; p.BackgroundTransparency=math.random(55,80)/100; p.ZIndex=3
    Instance.new("UICorner",p).CornerRadius=UDim.new(1,0)
    local life=math.random(30,60)/10
    local tw2=TS:Create(p,Q(life,Enum.EasingStyle.Linear),{
        Position=UDim2.new(p.Position.X.Scale+math.random(-20,20)/1000,0,p.Position.Y.Scale-math.random(10,30)/100,0),
        BackgroundTransparency=1
    }); tw2:Play()
    tw2.Completed:Connect(function() pcall(function() p:Destroy() end) end)
end
task.spawn(function()
    while LoadGui and LoadGui.Parent do spawnP(); task.wait(math.random(5,12)/100) end
end)

-- Corner brackets
local function bracket(parent,ax,ay,px,py)
    local f=Instance.new("Frame",parent); f.Size=UDim2.new(0,28,0,28); f.BackgroundTransparency=1
    f.AnchorPoint=Vector2.new(ax,ay); f.Position=UDim2.new(px,0,py,0); f.ZIndex=15
    local h2=Instance.new("Frame",f); h2.Size=UDim2.new(0,18,0,1.5)
    h2.BackgroundColor3=C.WHITE; h2.BackgroundTransparency=0.2; h2.BorderSizePixel=0; h2.ZIndex=15
    local v2=Instance.new("Frame",f); v2.Size=UDim2.new(0,1.5,0,18)
    v2.BackgroundColor3=C.WHITE; v2.BackgroundTransparency=0.2; v2.BorderSizePixel=0; v2.ZIndex=15
    if ax==1 then h2.Position=UDim2.new(1,-18,0,0); v2.Position=UDim2.new(1,-1.5,0,0) end
    if ay==1 then
        h2.Position=UDim2.new(ax==1 and 1 or 0,ax==1 and -18 or 0,1,-1.5)
        v2.Position=UDim2.new(ax==1 and 1 or 0,ax==1 and -1.5 or 0,1,-18)
    end
end
bracket(LBG,0,0,0.04,0.05); bracket(LBG,1,0,0.96,0.05)
bracket(LBG,0,1,0.04,0.95); bracket(LBG,1,1,0.96,0.95)

-- Center panel
local CEN=Instance.new("Frame",LBG)
CEN.Size=UDim2.new(0,420,0,210); CEN.AnchorPoint=Vector2.new(0.5,0.5)
CEN.Position=UDim2.new(0.5,0,0.5,0); CEN.BackgroundTransparency=1; CEN.ZIndex=5

local Tag=Instance.new("TextLabel",CEN); Tag.Size=UDim2.new(1,0,0,18)
Tag.Text="[ SYSTEM BOOT ]"; Tag.Font=Enum.Font.Code; Tag.TextSize=9; Tag.TextColor3=C.DIM
Tag.BackgroundTransparency=1; Tag.TextXAlignment=Enum.TextXAlignment.Center; Tag.ZIndex=5

local TitleShadow=Instance.new("TextLabel",CEN)
TitleShadow.Size=UDim2.new(1,0,0,50); TitleShadow.Position=UDim2.new(0,2,0,20)
TitleShadow.Text="EzScript"; TitleShadow.Font=Enum.Font.GothamBlack; TitleShadow.TextSize=36
TitleShadow.TextColor3=C.WHITE; TitleShadow.TextTransparency=0.9
TitleShadow.BackgroundTransparency=1; TitleShadow.TextXAlignment=Enum.TextXAlignment.Center; TitleShadow.ZIndex=5

local LoadTitle=Instance.new("TextLabel",CEN)
LoadTitle.Size=UDim2.new(1,0,0,50); LoadTitle.Position=UDim2.new(0,0,0,18)
LoadTitle.Text="EzScript"; LoadTitle.Font=Enum.Font.GothamBlack; LoadTitle.TextSize=36
LoadTitle.TextColor3=C.WHITE; LoadTitle.BackgroundTransparency=1
LoadTitle.TextXAlignment=Enum.TextXAlignment.Center; LoadTitle.ZIndex=6

local SubRow=Instance.new("Frame",CEN)
SubRow.Size=UDim2.new(1,0,0,18); SubRow.Position=UDim2.new(0,0,0,68)
SubRow.BackgroundTransparency=1; SubRow.ZIndex=5

local SubLeft=Instance.new("TextLabel",SubRow); SubLeft.Size=UDim2.new(0.5,0,1,0)
SubLeft.Text="--- LOADER v3.0 ---"; SubLeft.Font=Enum.Font.Code; SubLeft.TextSize=9
SubLeft.TextColor3=C.DIM; SubLeft.BackgroundTransparency=1; SubLeft.TextXAlignment=Enum.TextXAlignment.Left; SubLeft.ZIndex=5

local SubRight=Instance.new("TextLabel",SubRow); SubRight.Size=UDim2.new(0.5,0,1,0); SubRight.Position=UDim2.new(0.5,0,0,0)
SubRight.Text="HWID VERIFIED"; SubRight.Font=Enum.Font.Code; SubRight.TextSize=9
SubRight.TextColor3=C.DIM; SubRight.BackgroundTransparency=1; SubRight.TextXAlignment=Enum.TextXAlignment.Right; SubRight.ZIndex=5

local Div1=Instance.new("Frame",CEN); Div1.Size=UDim2.new(1,0,0,1); Div1.Position=UDim2.new(0,0,0,90)
Div1.BackgroundColor3=C.LINE; Div1.BackgroundTransparency=0.82; Div1.BorderSizePixel=0; Div1.ZIndex=5

local StatusLbl=Instance.new("TextLabel",CEN); StatusLbl.Size=UDim2.new(1,0,0,22); StatusLbl.Position=UDim2.new(0,0,0,100)
StatusLbl.Text="> initializing..."; StatusLbl.Font=Enum.Font.Code; StatusLbl.TextSize=11; StatusLbl.TextColor3=C.DIM
StatusLbl.BackgroundTransparency=1; StatusLbl.TextXAlignment=Enum.TextXAlignment.Left; StatusLbl.ZIndex=6

local BarTrack=Instance.new("Frame",CEN); BarTrack.Size=UDim2.new(1,0,0,3); BarTrack.Position=UDim2.new(0,0,0,130)
BarTrack.BackgroundColor3=C.BG3; BarTrack.BorderSizePixel=0; BarTrack.ZIndex=5; rnd(BarTrack,2)

local BarFill=Instance.new("Frame",BarTrack); BarFill.Size=UDim2.new(0,0,1,0); BarFill.BackgroundColor3=C.WHITE
BarFill.BorderSizePixel=0; BarFill.ZIndex=6; rnd(BarFill,2)

local BarGlow=Instance.new("Frame",BarFill); BarGlow.Size=UDim2.new(1,0,0,7); BarGlow.Position=UDim2.new(0,0,0.5,-3.5)
BarGlow.BackgroundColor3=C.WHITE; BarGlow.BackgroundTransparency=0.7; BarGlow.BorderSizePixel=0; BarGlow.ZIndex=7; rnd(BarGlow,4)

local Shimmer=Instance.new("Frame",BarFill); Shimmer.Size=UDim2.new(0,40,1,0)
Shimmer.BackgroundColor3=C.WHITE; Shimmer.BackgroundTransparency=0.6; Shimmer.BorderSizePixel=0; Shimmer.ZIndex=8; rnd(Shimmer,2)
local SG=Instance.new("UIGradient",Shimmer)
SG.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(0,0,0)),ColorSequenceKeypoint.new(0.5,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.new(0,0,0))}
SG.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0.25),NumberSequenceKeypoint.new(1,1)}
SG.Rotation=90
task.spawn(function()
    while LoadGui and LoadGui.Parent do
        Shimmer.Position=UDim2.new(-0.2,0,0,0)
        TS:Create(Shimmer,Q(0.9,Enum.EasingStyle.Linear),{Position=UDim2.new(1.1,0,0,0)}):Play(); task.wait(1.8)
    end
end)

local PctLbl=Instance.new("TextLabel",CEN); PctLbl.Size=UDim2.new(1,0,0,18); PctLbl.Position=UDim2.new(0,0,0,140)
PctLbl.Text="0%"; PctLbl.Font=Enum.Font.Code; PctLbl.TextSize=9; PctLbl.TextColor3=C.DIM
PctLbl.BackgroundTransparency=1; PctLbl.TextXAlignment=Enum.TextXAlignment.Right; PctLbl.ZIndex=6

local StepLbl=Instance.new("TextLabel",CEN); StepLbl.Size=UDim2.new(1,0,0,18); StepLbl.Position=UDim2.new(0,0,0,140)
StepLbl.Text="[0/5]"; StepLbl.Font=Enum.Font.Code; StepLbl.TextSize=9; StepLbl.TextColor3=C.DIM
StepLbl.BackgroundTransparency=1; StepLbl.TextXAlignment=Enum.TextXAlignment.Left; StepLbl.ZIndex=6

local SysRow=Instance.new("TextLabel",CEN); SysRow.Size=UDim2.new(1,0,0,18); SysRow.Position=UDim2.new(0,0,0,168)
SysRow.Text="PLACE: "..game.PlaceId.."   |   PLAYER: "..player.Name
SysRow.Font=Enum.Font.Code; SysRow.TextSize=8; SysRow.TextColor3=C.DIM
SysRow.BackgroundTransparency=1; SysRow.TextXAlignment=Enum.TextXAlignment.Center; SysRow.ZIndex=5

local loadSteps={
    {pct=15,label="Bypassing anti-cheat...",wait=0.4},
    {pct=35,label="Fetching remote index...",wait=0.45},
    {pct=60,label="Verifying HWID signature...",wait=0.5},
    {pct=85,label="Finalizing UI renderer...",wait=0.35},
    {pct=100,label="Access granted.",wait=0.5},
}

local function setProgress(pct,label,step)
    StepLbl.Text="["..step.."/5]"
    task.spawn(function() typeWrite(StatusLbl,"> "..label,0.018) end)
    task.spawn(function()
        for v=tonumber(PctLbl.Text:gsub("%%","")) or 0,pct do PctLbl.Text=v.."%"; task.wait(0.007) end
        PctLbl.Text=pct.."%"
    end)
    TS:Create(BarFill,Q(0.4,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=UDim2.new(pct/100,0,1,0)}):Play()
    if pct==100 then SubRight.TextColor3=C.GREEN end
    task.delay(0.1,function() glitch(LoadTitle,"EzScript",3,0.04) end)
end

pulse(BarGlow,"BackgroundTransparency",0.5,0.85,0.5)

-- ═══════════════════════════════════════════════════
-- MAIN GUI
-- ═══════════════════════════════════════════════════

local MainGui=Instance.new("ScreenGui")
MainGui.Name="EzScriptUI"; MainGui.ResetOnSpawn=false
MainGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
pcall(function() MainGui.Parent=CoreGui end)
if not MainGui.Parent then MainGui.Parent=player:WaitForChild("PlayerGui") end

-- ═══════════════════════════════════════════════════
-- KEY PANEL
-- ═══════════════════════════════════════════════════

local KeyPanel=Instance.new("Frame",MainGui)
KeyPanel.Size=UDim2.new(0,400,0,340); KeyPanel.AnchorPoint=Vector2.new(0.5,0.5)
KeyPanel.Position=UDim2.new(0.5,0,0.5,0); KeyPanel.BackgroundColor3=C.BG2
KeyPanel.BorderSizePixel=0; KeyPanel.Visible=false; KeyPanel.ZIndex=20
rnd(KeyPanel,4); mkStroke(KeyPanel,C.LINE,1.5,0.25)

local KSL=Instance.new("Frame",KeyPanel); KSL.Size=UDim2.new(1,0,1,0); KSL.BackgroundTransparency=1; KSL.ZIndex=20
for i=0,40 do
    local ln=Instance.new("Frame",KSL); ln.Size=UDim2.new(1,0,0,1)
    ln.Position=UDim2.new(0,0,0,i*9); ln.BackgroundColor3=C.WHITE
    ln.BackgroundTransparency=0.972; ln.BorderSizePixel=0; ln.ZIndex=20
end

local KTopBar=Instance.new("Frame",KeyPanel); KTopBar.Size=UDim2.new(1,0,0,3); KTopBar.BackgroundColor3=C.WHITE
KTopBar.BorderSizePixel=0; KTopBar.ZIndex=21; rnd(KTopBar,4)
pulse(KTopBar,"BackgroundTransparency",0,0.5,0.6)

local KHdr=Instance.new("Frame",KeyPanel); KHdr.Size=UDim2.new(1,0,0,52); KHdr.BackgroundColor3=C.BG3
KHdr.BorderSizePixel=0; KHdr.ZIndex=21

local KHdrDiv=Instance.new("Frame",KHdr); KHdrDiv.Size=UDim2.new(1,0,0,1); KHdrDiv.Position=UDim2.new(0,0,1,0)
KHdrDiv.BackgroundColor3=C.LINE; KHdrDiv.BackgroundTransparency=0.75; KHdrDiv.BorderSizePixel=0; KHdrDiv.ZIndex=22

local function kDot(x,col)
    local d=Instance.new("Frame",KHdr); d.Size=UDim2.new(0,8,0,8)
    d.Position=UDim2.new(0,x,0.5,-4); d.BackgroundColor3=col; d.BorderSizePixel=0; d.ZIndex=22; rnd(d,99)
end
kDot(14,C.RED); kDot(28,C.DIM); kDot(42,C.DIM)

local KHdrTitle=Instance.new("TextLabel",KHdr); KHdrTitle.Size=UDim2.new(1,0,1,0)
KHdrTitle.Text="EzScript -- authentication required"; KHdrTitle.Font=Enum.Font.Code
KHdrTitle.TextSize=11; KHdrTitle.TextColor3=C.DIM; KHdrTitle.BackgroundTransparency=1
KHdrTitle.TextXAlignment=Enum.TextXAlignment.Center; KHdrTitle.ZIndex=22

local KBody=Instance.new("Frame",KeyPanel); KBody.Size=UDim2.new(1,-40,0,270); KBody.Position=UDim2.new(0,20,0,68)
KBody.BackgroundTransparency=1; KBody.ZIndex=21

local KEzTitle=Instance.new("TextLabel",KBody); KEzTitle.Size=UDim2.new(1,0,0,44)
KEzTitle.Text="EzScript"; KEzTitle.Font=Enum.Font.GothamBlack; KEzTitle.TextSize=34
KEzTitle.TextColor3=C.WHITE; KEzTitle.BackgroundTransparency=1; KEzTitle.ZIndex=22

local KEzSub=Instance.new("TextLabel",KBody); KEzSub.Size=UDim2.new(1,0,0,18); KEzSub.Position=UDim2.new(0,0,0,44)
KEzSub.Text="Enter your access key to continue"; KEzSub.Font=Enum.Font.Code
KEzSub.TextSize=11; KEzSub.TextColor3=C.DIM; KEzSub.BackgroundTransparency=1; KEzSub.ZIndex=22

local KInputBG=Instance.new("Frame",KBody); KInputBG.Size=UDim2.new(1,0,0,42); KInputBG.Position=UDim2.new(0,0,0,78)
KInputBG.BackgroundColor3=C.BG; KInputBG.BorderSizePixel=0; KInputBG.ZIndex=22; rnd(KInputBG,4)
local KInputStroke=mkStroke(KInputBG,C.LINE2,1,0)

local KPrompt=Instance.new("TextLabel",KInputBG); KPrompt.Size=UDim2.new(0,28,1,0); KPrompt.Position=UDim2.new(0,8,0,0)
KPrompt.Text=">"; KPrompt.Font=Enum.Font.Code; KPrompt.TextSize=18
KPrompt.TextColor3=C.WHITE; KPrompt.BackgroundTransparency=1; KPrompt.ZIndex=23

local KeyInput=Instance.new("TextBox",KInputBG); KeyInput.Size=UDim2.new(1,-40,1,0); KeyInput.Position=UDim2.new(0,32,0,0)
KeyInput.PlaceholderText="paste key here..."; KeyInput.PlaceholderColor3=C.DIM; KeyInput.Text=""
KeyInput.TextColor3=C.TEXT; KeyInput.Font=Enum.Font.Code; KeyInput.TextSize=13
KeyInput.BackgroundTransparency=1; KeyInput.ClearTextOnFocus=false; KeyInput.ZIndex=23

KeyInput.Focused:Connect(function() tw(KInputStroke,0.2,{Color=C.WHITE,Transparency=0.4}) end)
KeyInput.FocusLost:Connect(function() tw(KInputStroke,0.2,{Color=C.LINE2,Transparency=0}) end)

local KStatus=Instance.new("TextLabel",KBody); KStatus.Size=UDim2.new(1,0,0,16); KStatus.Position=UDim2.new(0,0,0,126)
KStatus.Text=""; KStatus.Font=Enum.Font.Code; KStatus.TextSize=10
KStatus.TextColor3=C.RED; KStatus.BackgroundTransparency=1; KStatus.ZIndex=22

local KUnlockBtn=Instance.new("TextButton",KBody); KUnlockBtn.Size=UDim2.new(1,0,0,42); KUnlockBtn.Position=UDim2.new(0,0,0,148)
KUnlockBtn.Text="[ UNLOCK ]"; KUnlockBtn.Font=Enum.Font.GothamBlack; KUnlockBtn.TextSize=14
KUnlockBtn.BackgroundColor3=C.WHITE; KUnlockBtn.TextColor3=C.BG
KUnlockBtn.BorderSizePixel=0; KUnlockBtn.ZIndex=22; rnd(KUnlockBtn,4); KUnlockBtn.AutoButtonColor=false
KUnlockBtn.MouseEnter:Connect(function() tw(KUnlockBtn,0.15,{BackgroundColor3=Color3.fromRGB(200,200,200)}) end)
KUnlockBtn.MouseLeave:Connect(function() tw(KUnlockBtn,0.15,{BackgroundColor3=C.WHITE}) end)
KUnlockBtn.MouseButton1Click:Connect(function()
    tw(KUnlockBtn,0.05,{BackgroundColor3=Color3.fromRGB(140,140,140)}); task.wait(0.08); tw(KUnlockBtn,0.15,{BackgroundColor3=C.WHITE})
end)

local KDiscordBtn=Instance.new("TextButton",KBody); KDiscordBtn.Size=UDim2.new(1,0,0,36); KDiscordBtn.Position=UDim2.new(0,0,0,200)
KDiscordBtn.Text="[ GET KEY -- JOIN DISCORD ]"; KDiscordBtn.Font=Enum.Font.Code; KDiscordBtn.TextSize=11
KDiscordBtn.BackgroundColor3=C.BG3; KDiscordBtn.TextColor3=C.DIM
KDiscordBtn.BorderSizePixel=0; KDiscordBtn.ZIndex=22
rnd(KDiscordBtn,4); mkStroke(KDiscordBtn,C.LINE2,1,0.3); KDiscordBtn.AutoButtonColor=false
KDiscordBtn.MouseEnter:Connect(function() tw(KDiscordBtn,0.15,{TextColor3=C.TEXT}) end)
KDiscordBtn.MouseLeave:Connect(function() tw(KDiscordBtn,0.15,{TextColor3=C.DIM}) end)
KDiscordBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then
            setclipboard(DISCORD_LINK)
            KDiscordBtn.Text="[ LINK COPIED TO CLIPBOARD ]"; KDiscordBtn.TextColor3=C.GREEN
            task.wait(2); KDiscordBtn.Text="[ GET KEY -- JOIN DISCORD ]"; KDiscordBtn.TextColor3=C.DIM
        end
    end)
end)

-- ═══════════════════════════════════════════════════
-- MAIN MENU
-- ═══════════════════════════════════════════════════

local isMinimized=false
local ezT=Q(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

local MenuPanel=Instance.new("Frame",MainGui)
MenuPanel.Size=UDim2.new(0,280,0,230)
MenuPanel.Position=UDim2.new(0.5,-140,0.5,-115)
MenuPanel.BackgroundColor3=C.BG2; MenuPanel.BorderSizePixel=0
MenuPanel.Visible=false; MenuPanel.Active=true; MenuPanel.ZIndex=30
rnd(MenuPanel,6); mkStroke(MenuPanel,C.LINE,1.5,0.3)

-- Top accent stripe
local MTopStripe=Instance.new("Frame",MenuPanel); MTopStripe.Size=UDim2.new(1,0,0,2); MTopStripe.BackgroundColor3=C.WHITE
MTopStripe.BorderSizePixel=0; MTopStripe.ZIndex=31; rnd(MTopStripe,4)
pulse(MTopStripe,"BackgroundTransparency",0,0.55,0.7)

-- Scanlines
local MSL=Instance.new("Frame",MenuPanel); MSL.Size=UDim2.new(1,0,1,0); MSL.BackgroundTransparency=1; MSL.ZIndex=31
for i=0,28 do
    local ln=Instance.new("Frame",MSL); ln.Size=UDim2.new(1,0,0,1)
    ln.Position=UDim2.new(0,0,0,i*9); ln.BackgroundColor3=C.WHITE
    ln.BackgroundTransparency=0.972; ln.BorderSizePixel=0; ln.ZIndex=31
end

-- Dot grid
local DG=Instance.new("Frame",MenuPanel); DG.Size=UDim2.new(1,0,1,0); DG.BackgroundTransparency=1; DG.ZIndex=31
for row=0,12 do for col=0,9 do
    local d=Instance.new("Frame",DG); d.Size=UDim2.new(0,2,0,2)
    d.Position=UDim2.new(0,col*30+8,0,row*20+5)
    d.BackgroundColor3=C.WHITE; d.BackgroundTransparency=0.93; d.BorderSizePixel=0; d.ZIndex=31; rnd(d,99)
end end

-- Header
local MHdr=Instance.new("Frame",MenuPanel); MHdr.Size=UDim2.new(1,0,0,44); MHdr.BackgroundColor3=C.BG3
MHdr.BorderSizePixel=0; MHdr.ZIndex=32; rnd(MHdr,6)
local MHdrFill=Instance.new("Frame",MHdr); MHdrFill.Size=UDim2.new(1,0,0.5,0); MHdrFill.Position=UDim2.new(0,0,0.5,0)
MHdrFill.BackgroundColor3=C.BG3; MHdrFill.BorderSizePixel=0; MHdrFill.ZIndex=32

local MHdrDiv=Instance.new("Frame",MHdr); MHdrDiv.Size=UDim2.new(1,0,0,1); MHdrDiv.Position=UDim2.new(0,0,1,-1)
MHdrDiv.BackgroundColor3=C.LINE; MHdrDiv.BackgroundTransparency=0.8; MHdrDiv.BorderSizePixel=0; MHdrDiv.ZIndex=33

local function mDot(x,col)
    local d=Instance.new("Frame",MHdr); d.Size=UDim2.new(0,8,0,8)
    d.Position=UDim2.new(0,x,0.5,-4); d.BackgroundColor3=col; d.BorderSizePixel=0; d.ZIndex=34; rnd(d,99)
end
mDot(12,C.RED); mDot(26,C.DIM); mDot(40,C.DIM)

local MHdrTitle=Instance.new("TextLabel",MHdr); MHdrTitle.Size=UDim2.new(1,-30,1,0)
MHdrTitle.Text="EzScript"; MHdrTitle.Font=Enum.Font.GothamBlack; MHdrTitle.TextSize=15
MHdrTitle.TextColor3=C.TEXT; MHdrTitle.BackgroundTransparency=1
MHdrTitle.TextXAlignment=Enum.TextXAlignment.Center; MHdrTitle.ZIndex=34

local MStatusDot=Instance.new("Frame",MHdr); MStatusDot.Size=UDim2.new(0,6,0,6)
MStatusDot.AnchorPoint=Vector2.new(1,0.5); MStatusDot.Position=UDim2.new(1,-50,0.5,0)
MStatusDot.BackgroundColor3=C.DIM; MStatusDot.BorderSizePixel=0; MStatusDot.ZIndex=34; rnd(MStatusDot,99)

-- Minimize button
local MMinBG=Instance.new("Frame",MHdr); MMinBG.Size=UDim2.new(0,30,0,30); MMinBG.Position=UDim2.new(1,-40,0.5,-15)
MMinBG.BackgroundColor3=Color3.fromRGB(20,20,30); MMinBG.BorderSizePixel=0; MMinBG.ZIndex=35
rnd(MMinBG,6); mkStroke(MMinBG,C.LINE2,1,0.3)

local MMinBtn=Instance.new("TextButton",MMinBG); MMinBtn.Size=UDim2.new(1,0,1,0); MMinBtn.Text="-"
MMinBtn.Font=Enum.Font.GothamBlack; MMinBtn.TextSize=16; MMinBtn.TextColor3=C.DIM
MMinBtn.BackgroundTransparency=1; MMinBtn.ZIndex=36; MMinBtn.AutoButtonColor=false
MMinBtn.MouseEnter:Connect(function() tw(MMinBG,0.15,{BackgroundColor3=Color3.fromRGB(30,30,45)}); tw(MMinBtn,0.15,{TextColor3=C.TEXT}) end)
MMinBtn.MouseLeave:Connect(function() tw(MMinBG,0.15,{BackgroundColor3=Color3.fromRGB(20,20,30)}); tw(MMinBtn,0.15,{TextColor3=C.DIM}) end)

-- Divider
local MenuDiv=Instance.new("Frame",MenuPanel); MenuDiv.Size=UDim2.new(1,-40,0,1); MenuDiv.Position=UDim2.new(0,20,0,55)
MenuDiv.BackgroundColor3=C.LINE2; MenuDiv.BorderSizePixel=0; MenuDiv.ZIndex=32

-- Button container
local BtnContainer=Instance.new("Frame",MenuPanel)
BtnContainer.Size=UDim2.new(1,0,1,-90); BtnContainer.Position=UDim2.new(0,0,0,66)
BtnContainer.BackgroundTransparency=1; BtnContainer.ZIndex=32; BtnContainer.ClipsDescendants=true

-- ── Feature button factory ────────────────────────

local function CreateToggleBtn(labelText, yPos)
    local BtnFrame=Instance.new("Frame",BtnContainer)
    BtnFrame.Size=UDim2.new(1,-40,0,56); BtnFrame.Position=UDim2.new(0,20,0,yPos)
    BtnFrame.BackgroundColor3=C.BG3; BtnFrame.BorderSizePixel=0; BtnFrame.ZIndex=33
    rnd(BtnFrame,5)
    local RStroke=mkStroke(BtnFrame,C.LINE2,1,0.15)

    local AccentBar=Instance.new("Frame",BtnFrame); AccentBar.Size=UDim2.new(0,2,0.55,0); AccentBar.Position=UDim2.new(0,0,0.225,0)
    AccentBar.BackgroundColor3=C.DIM; AccentBar.BorderSizePixel=0; AccentBar.ZIndex=34; rnd(AccentBar,99)

    local IconBox=Instance.new("Frame",BtnFrame); IconBox.Size=UDim2.new(0,32,0,32); IconBox.Position=UDim2.new(0,10,0.5,-16)
    IconBox.BackgroundColor3=C.BG2; IconBox.BorderSizePixel=0; IconBox.ZIndex=34; rnd(IconBox,7)

    local NameLabel=Instance.new("TextLabel",BtnFrame); NameLabel.Size=UDim2.new(0,148,0,18); NameLabel.Position=UDim2.new(0,52,0,8)
    NameLabel.BackgroundTransparency=1; NameLabel.Text=labelText
    NameLabel.TextColor3=C.TEXT; NameLabel.TextSize=11
    NameLabel.Font=Enum.Font.GothamBold; NameLabel.TextXAlignment=Enum.TextXAlignment.Left; NameLabel.ZIndex=34

    local StatusLabel=Instance.new("TextLabel",BtnFrame); StatusLabel.Size=UDim2.new(0,148,0,12); StatusLabel.Position=UDim2.new(0,52,0,28)
    StatusLabel.BackgroundTransparency=1; StatusLabel.Text="status: disabled"
    StatusLabel.TextColor3=C.DIM; StatusLabel.TextSize=9
    StatusLabel.Font=Enum.Font.Code; StatusLabel.TextXAlignment=Enum.TextXAlignment.Left; StatusLabel.ZIndex=34

    local ToggleBg=Instance.new("Frame",BtnFrame); ToggleBg.Size=UDim2.new(0,42,0,20)
    ToggleBg.AnchorPoint=Vector2.new(1,0.5); ToggleBg.Position=UDim2.new(1,-10,0.5,0)
    ToggleBg.BackgroundColor3=C.BG; ToggleBg.BorderSizePixel=0; ToggleBg.ZIndex=35
    rnd(ToggleBg,10); mkStroke(ToggleBg,C.LINE2,1,0.2)

    local ToggleKnob=Instance.new("Frame",ToggleBg); ToggleKnob.Size=UDim2.new(0,14,0,14); ToggleKnob.Position=UDim2.new(0,3,0.5,-7)
    ToggleKnob.BackgroundColor3=C.DIM; ToggleKnob.BorderSizePixel=0; ToggleKnob.ZIndex=36; rnd(ToggleKnob,99)

    local HitBtn=Instance.new("TextButton",BtnFrame); HitBtn.Size=UDim2.new(1,0,1,0)
    HitBtn.BackgroundTransparency=1; HitBtn.Text=""; HitBtn.ZIndex=37; HitBtn.AutoButtonColor=false

    HitBtn.MouseEnter:Connect(function() tw(BtnFrame,0.15,{BackgroundColor3=Color3.fromRGB(20,20,28)}) end)
    HitBtn.MouseLeave:Connect(function() tw(BtnFrame,0.15,{BackgroundColor3=C.BG3}) end)
    HitBtn.MouseButton1Down:Connect(function()
        TS:Create(BtnFrame,Q(0.07,Enum.EasingStyle.Quad),{Size=UDim2.new(1,-44,0,54)}):Play()
    end)
    HitBtn.MouseButton1Up:Connect(function()
        TS:Create(BtnFrame,Q(0.12,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(1,-40,0,56)}):Play()
    end)

    return {Frame=BtnFrame,AccentBar=AccentBar,IconBox=IconBox,StatusLabel=StatusLabel,
            ToggleBg=ToggleBg,ToggleKnob=ToggleKnob,HitBtn=HitBtn,RStroke=RStroke}
end

-- Animate toggle
local function AnimateToggle(btn, on)
    TS:Create(btn.ToggleKnob,Q(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
        Position = on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
        BackgroundColor3 = on and C.WHITE or C.DIM
    }):Play()
    tw(btn.ToggleBg,  0.18,{BackgroundColor3 = on and C.BG3 or C.BG})
    tw(btn.AccentBar, 0.18,{BackgroundColor3 = on and C.WHITE or C.DIM})
    tw(btn.IconBox,   0.18,{BackgroundColor3 = on and Color3.fromRGB(26,26,34) or C.BG2})
    tw(btn.RStroke,   0.18,{Color = on and C.LINE or C.LINE2, Transparency = on and 0.45 or 0.15})
    tw(btn.StatusLabel,0.18,{TextColor3 = on and C.GREEN or C.DIM})
    btn.StatusLabel.Text = on and "status: active" or "status: disabled"
end

-- Build buttons
local BtnCash    = CreateToggleBtn("AUTO CASH & LEVEL", 8)
local BtnRebirth = CreateToggleBtn("AUTO REBIRTH",      76)

-- Footer
local MFooter=Instance.new("Frame",MenuPanel); MFooter.Size=UDim2.new(1,0,0,22); MFooter.Position=UDim2.new(0,0,1,-22)
MFooter.BackgroundColor3=C.BG3; MFooter.BorderSizePixel=0; MFooter.ZIndex=32; rnd(MFooter,6)
local MFootFill=Instance.new("Frame",MFooter); MFootFill.Size=UDim2.new(1,0,0.5,0); MFootFill.BackgroundColor3=C.BG3
MFootFill.BorderSizePixel=0; MFootFill.ZIndex=32
local MFootDiv=Instance.new("Frame",MFooter); MFootDiv.Size=UDim2.new(1,0,0,1); MFootDiv.BackgroundColor3=C.LINE
MFootDiv.BackgroundTransparency=0.82; MFootDiv.BorderSizePixel=0; MFootDiv.ZIndex=33
local MFootTxt=Instance.new("TextLabel",MFooter); MFootTxt.Size=UDim2.new(1,0,1,0)
MFootTxt.Text="EzScript  |  "..player.Name; MFootTxt.Font=Enum.Font.Code; MFootTxt.TextSize=9
MFootTxt.TextColor3=C.DIM; MFootTxt.BackgroundTransparency=1; MFootTxt.TextXAlignment=Enum.TextXAlignment.Center; MFootTxt.ZIndex=34

-- Status dot pulse
local statusPulseConn=nil
local function UpdateStatusDot()
    if statusPulseConn then statusPulseConn:Disconnect(); statusPulseConn=nil end
    local anyOn = toggles.AutoCash or toggles.AutoRebirth
    MStatusDot.BackgroundTransparency=0
    if anyOn then
        MStatusDot.BackgroundColor3=C.WHITE
        statusPulseConn=RunService.Heartbeat:Connect(function()
            MStatusDot.BackgroundTransparency=1-((math.sin(tick()*math.pi*2)*0.4)+0.6)
        end)
    else
        MStatusDot.BackgroundColor3=C.DIM
    end
end

-- ── Minimize ──────────────────────────────────────

MMinBtn.MouseButton1Click:Connect(function()
    isMinimized=not isMinimized
    if isMinimized then
        TS:Create(MenuPanel,Q(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.InOut),{Size=UDim2.new(0,280,0,44)}):Play()
        BtnContainer.Visible=false; MenuDiv.Visible=false; MFooter.Visible=false; MMinBtn.Text="+"
    else
        TS:Create(MenuPanel,Q(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,280,0,230)}):Play()
        BtnContainer.Visible=true; MenuDiv.Visible=true; MFooter.Visible=true; MMinBtn.Text="-"
    end
end)

-- ── Drag ──────────────────────────────────────────

local dragging,dragStart,startPos
MHdr.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=inp.Position; startPos=MenuPanel.Position
        inp.Changed:Connect(function()
            if inp.UserInputState==Enum.UserInputState.End then dragging=false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then
        local d=inp.Position-dragStart
        MenuPanel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)

-- ═══════════════════════════════════════════════════
-- SHOW / HIDE PANELS
-- ═══════════════════════════════════════════════════

local function showMenu()
    MenuPanel.Position=UDim2.new(0.5,-140,1.5,0)
    MenuPanel.BackgroundTransparency=1; MenuPanel.Visible=true
    TS:Create(MenuPanel,Q(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
        Position=UDim2.new(0.5,-140,0.5,-115), BackgroundTransparency=0
    }):Play()
end

local function showKeyPanel()
    KeyPanel.Position=UDim2.new(0.5,-200,1.2,0); KeyPanel.Visible=true
    TS:Create(KeyPanel,Q(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
        Position=UDim2.new(0.5,-200,0.5,-170)
    }):Play()
end

-- ═══════════════════════════════════════════════════
-- KEY VERIFY
-- ═══════════════════════════════════════════════════

KUnlockBtn.MouseButton1Click:Connect(function()
    local entered=KeyInput.Text:gsub("%s+","")
    if entered==CORRECT_KEY then
        local used,usedBy=false,""
        if type(savedData)=="table" then
            for k,v in pairs(savedData) do if k==CORRECT_KEY then used=true;usedBy=v;break end end
        end
        if used and usedBy~=currentHWID then
            KStatus.Text="x  key already used on another machine"; KStatus.TextColor3=C.RED; KeyInput.Text=""; return
        end
        savedData=savedData or {}; savedData[CORRECT_KEY]=currentHWID; saveData(savedData)
        KStatus.Text="v  access granted"; KStatus.TextColor3=C.GREEN
        task.spawn(function()
            TS:Create(KeyPanel,Q(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{
                Position=UDim2.new(0.5,-200,1.1,0), BackgroundTransparency=1
            }):Play()
            task.wait(0.35); KeyPanel.Visible=false; showMenu()
        end)
    else
        KStatus.Text="x  invalid key"; KStatus.TextColor3=C.RED
        local orig=KeyPanel.Position
        for _=1,4 do
            TS:Create(KeyPanel,Q(0.04),{Position=UDim2.new(orig.X.Scale,orig.X.Offset+8,orig.Y.Scale,orig.Y.Offset)}):Play(); task.wait(0.05)
            TS:Create(KeyPanel,Q(0.04),{Position=UDim2.new(orig.X.Scale,orig.X.Offset-8,orig.Y.Scale,orig.Y.Offset)}):Play(); task.wait(0.05)
        end
        TS:Create(KeyPanel,Q(0.04),{Position=orig}):Play(); KeyInput.Text=""
    end
end)

-- ═══════════════════════════════════════════════════
-- BOOT SEQUENCE
-- ═══════════════════════════════════════════════════

local function runLoader(onDone)
    LBG.BackgroundTransparency=1
    LoadTitle.TextTransparency=1; TitleShadow.TextTransparency=1; Tag.TextTransparency=1
    SubLeft.TextTransparency=1; SubRight.TextTransparency=1; Div1.BackgroundTransparency=1
    StatusLbl.TextTransparency=1; BarTrack.BackgroundTransparency=1
    PctLbl.TextTransparency=1; StepLbl.TextTransparency=1; SysRow.TextTransparency=1

    TS:Create(LBG,Q(0.5,Enum.EasingStyle.Quad),{BackgroundTransparency=0}):Play(); task.wait(0.4)
    TS:Create(Tag,Q(0.3),{TextTransparency=0}):Play(); task.wait(0.2)
    LoadTitle.Position=UDim2.new(0,0,0,40); TitleShadow.Position=UDim2.new(0,2,0,42)
    TS:Create(LoadTitle,Q(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{TextTransparency=0,Position=UDim2.new(0,0,0,18)}):Play()
    TS:Create(TitleShadow,Q(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{TextTransparency=0.9,Position=UDim2.new(0,2,0,20)}):Play()
    task.wait(0.35)
    TS:Create(SubLeft,Q(0.3),{TextTransparency=0}):Play(); TS:Create(SubRight,Q(0.3),{TextTransparency=0}):Play(); task.wait(0.15)
    Div1.Size=UDim2.new(0,0,0,1)
    TS:Create(Div1,Q(0.4,Enum.EasingStyle.Quart),{Size=UDim2.new(1,0,0,1),BackgroundTransparency=0.82}):Play(); task.wait(0.3)
    TS:Create(BarTrack,Q(0.3),{BackgroundTransparency=0}):Play()
    TS:Create(PctLbl,Q(0.3),{TextTransparency=0}):Play(); TS:Create(StepLbl,Q(0.3),{TextTransparency=0}):Play()
    TS:Create(StatusLbl,Q(0.3),{TextTransparency=0}):Play(); TS:Create(SysRow,Q(0.3),{TextTransparency=0}):Play(); task.wait(0.35)

    for i,step in ipairs(loadSteps) do setProgress(step.pct,step.label,i); task.wait(step.wait) end
    task.wait(0.3)

    local flash=Instance.new("Frame",LBG); flash.Size=UDim2.new(1,0,1,0)
    flash.BackgroundColor3=C.WHITE; flash.BackgroundTransparency=0.8; flash.BorderSizePixel=0; flash.ZIndex=100
    TS:Create(flash,Q(0.4,Enum.EasingStyle.Quart),{BackgroundTransparency=1}):Play(); task.wait(0.4); pcall(function() flash:Destroy() end)

    local fadeT=Q(0.5,Enum.EasingStyle.Quart,Enum.EasingDirection.In)
    for _,obj in ipairs({LoadTitle,TitleShadow,Tag,SubLeft,SubRight,Div1,StatusLbl,BarTrack,BarFill,BarGlow,PctLbl,StepLbl,SysRow}) do
        local prop=obj:IsA("Frame") and "BackgroundTransparency" or "TextTransparency"
        TS:Create(obj,fadeT,{[prop]=1}):Play()
    end
    TS:Create(LBG,Q(0.55,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{BackgroundTransparency=1}):Play()
    task.wait(0.6); pcall(function() LoadGui:Destroy() end)
    onDone()
end

task.spawn(function()
    runLoader(function()
        if keyVerified then showMenu() else showKeyPanel() end
    end)
end)

-- ═══════════════════════════════════════════════════
-- ОРИГИНАЛЬНАЯ ЛОГИКА (не тронута)
-- ═══════════════════════════════════════════════════

-- Auto Cash & Level
local function toggleAutoCash()
    toggles.AutoCash = not toggles.AutoCash
    AnimateToggle(BtnCash, toggles.AutoCash)
    UpdateStatusDot()

    if toggles.AutoCash then
        task.spawn(function()
            while toggles.AutoCash do
                local character = player.Character
                if character then
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    local hum = character:FindFirstChild("Humanoid")
                    if hrp and hum then
                        local animator = hum:FindFirstChildOfClass("Animator")
                        if animator then
                            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end
                        end

                        local ReturnButtons = workspace:FindFirstChild("ReturnButtons")
                        if ReturnButtons then
                            local passButtons = {5, 7, 9, 11, 13}
                            for _, num in ipairs(passButtons) do
                                if not toggles.AutoCash then break end
                                local btn = ReturnButtons:FindFirstChild("Button" .. num)
                                if btn then
                                    hrp.CFrame = CFrame.new(btn.Position + Vector3.new(8, 0, 0))
                                    task.wait(0.2)
                                end
                            end

                            if toggles.AutoCash then
                                local btn15 = ReturnButtons:FindFirstChild("Button15")
                                if btn15 then
                                    local target = btn15:FindFirstChild("Collider") or btn15
                                    hrp.CFrame = CFrame.new(target.Position)
                                    pcall(function()
                                        firetouchinterest(hrp, target, 0)
                                        firetouchinterest(hrp, target, 1)
                                    end)
                                end
                            end
                        end
                    end
                end
                task.wait(0.3)
            end
        end)
    end
end

-- Auto Rebirth
local function toggleAutoRebirth()
    toggles.AutoRebirth = not toggles.AutoRebirth
    AnimateToggle(BtnRebirth, toggles.AutoRebirth)
    UpdateStatusDot()

    if toggles.AutoRebirth then
        task.spawn(function()
            local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
            local RequestRebirth = Remotes and Remotes:WaitForChild("RequestRebirth", 5)

            while toggles.AutoRebirth do
                if RequestRebirth then
                    pcall(function() RequestRebirth:FireServer() end)
                end
                task.wait(1)
            end
        end)
    end
end

-- Подключаем клики
BtnCash.HitBtn.MouseButton1Click:Connect(toggleAutoCash)
BtnRebirth.HitBtn.MouseButton1Click:Connect(toggleAutoRebirth)
