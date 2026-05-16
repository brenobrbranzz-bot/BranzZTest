-- ╔══════════════════════════════════════════╗
-- ║    BRANZZ SPAWN VISUAL — v3.0            ║
-- ║       🧑‍💻 By BranZZ MetoDos 🚀            ║
-- ╚══════════════════════════════════════════╝

local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")
local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local WIKI_API    = "https://stealabrainrot.fandom.com/api.php"
local FANDOM_BASE = "https://stealabrainrot.fandom.com/wiki/"

-- ══════════════════════════════════════
-- SAVE/LOAD NO EXECUTOR
-- ══════════════════════════════════════
local SAVE_KEY = "BRANZZ_SPAWN_V3"

local function saveData(data)
    pcall(function()
        writefile(SAVE_KEY .. ".json", HttpService:JSONEncode(data))
    end)
end

local function loadData()
    local ok, content = pcall(function() return readfile(SAVE_KEY .. ".json") end)
    if ok and content and content ~= "" then
        local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
        if ok2 and data then return data end
    end
    return {}
end

-- ══════════════════════════════════════
-- MÓDULOS
-- ══════════════════════════════════════
local AnimalsData   = nil
local AnimalsShared = nil
pcall(function()
    AnimalsData   = require(ReplicatedStorage.Packages.Synchronizer) and require(ReplicatedStorage.Datas.Animals)
    AnimalsShared = require(ReplicatedStorage.Shared.Animals)
end)

-- ══════════════════════════════════════
-- UTILS
-- ══════════════════════════════════════
local function formatGen(val)
    val = tonumber(val) or 0
    if val >= 1e9 then
        local n = val / 1e9
        return (n == math.floor(n)) and n .. "B/s" or string.format("%.1fB/s", n)
    elseif val >= 1e6 then
        local n = val / 1e6
        return (n == math.floor(n)) and n .. "M/s" or string.format("%.1fM/s", n)
    elseif val >= 1e3 then
        local n = val / 1e3
        return (n == math.floor(n)) and n .. "K/s" or string.format("%.1fK/s", n)
    end
    return tostring(val) .. "/s"
end

-- ══════════════════════════════════════
-- SCANNER — MEU PLOT
-- ══════════════════════════════════════
local function getMyPlotName()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local found = false
        pcall(function()
            local ch = require(ReplicatedStorage.Packages.Synchronizer):Get(plot.Name)
            if not ch then return end
            local owner = ch:Get("Owner")
            if (typeof(owner) == "Instance" and owner == localPlayer)
            or (type(owner) == "table" and owner.UserId == localPlayer.UserId) then
                found = true
            end
        end)
        if found then return plot.Name end
    end
    return nil
end

local function scanMyBrainrots()
    local results = {}
    local myPlotName = getMyPlotName()
    if not myPlotName then return results end

    pcall(function()
        local ch = require(ReplicatedStorage.Packages.Synchronizer):Get(myPlotName)
        if not ch then return end
        local animalList = ch:Get("AnimalList")
        if not animalList then return end

        for slot, animalData in pairs(animalList) do
            if type(animalData) ~= "table" or not animalData.Index then continue end
            local info = AnimalsData and AnimalsData[animalData.Index]
            if not info then continue end

            local displayName = info.DisplayName or animalData.Index
            local mutation    = animalData.Mutation or "None"
            local genVal      = 0
            pcall(function()
                genVal = AnimalsShared:GetGeneration(animalData.Index, animalData.Mutation, animalData.Traits, nil)
            end)

            local traitsText = "None"
            if animalData.Traits and type(animalData.Traits) == "table" and #animalData.Traits > 0 then
                local tList = {}
                for _, t in pairs(animalData.Traits) do
                    if type(t) == "string" and t ~= "" then
                        table.insert(tList, t)
                    elseif type(t) == "table" and t.Name then
                        table.insert(tList, t.Name)
                    end
                end
                if #tList > 0 then traitsText = table.concat(tList, ", ") end
            end

            table.insert(results, {
                displayName = displayName,
                index       = animalData.Index,
                mutation    = mutation,
                traits      = traitsText,
                genVal      = genVal,
                slot        = tostring(slot),
                plotName    = myPlotName,
            })
        end
    end)

    table.sort(results, function(a, b) return a.genVal > b.genVal end)
    return results
end

-- ══════════════════════════════════════
-- ACHAR PODIUM REAL NO WORKSPACE
-- ══════════════════════════════════════
local function getPodiumPart(plotName, slot)
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local plot = plots:FindFirstChild(plotName)
    if not plot then return nil end
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return nil end
    local podium = podiums:FindFirstChild(slot)
    if not podium then return nil end
    local base  = podium:FindFirstChild("Base")
    local spawn = base and base:FindFirstChild("Spawn")
    return spawn or base or podium
end

local function getPodiumCFrame(plotName, slot)
    local part = getPodiumPart(plotName, slot)
    if not part then return nil end
    if part:IsA("Model") and part.PrimaryPart then
        return part.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
    elseif part:IsA("BasePart") then
        return part.CFrame + Vector3.new(0, 3, 0)
    end
    for _, c in ipairs(part:GetDescendants()) do
        if c:IsA("BasePart") then return c.CFrame + Vector3.new(0, 3, 0) end
    end
    return nil
end

local function findRealModelByIndex(index)
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then continue end
        for _, podium in ipairs(podiums:GetChildren()) do
            local base      = podium:FindFirstChild("Base")
            local spawn     = base and base:FindFirstChild("Spawn")
            local container = spawn or base
            if not container then continue end
            for _, child in ipairs(container:GetChildren()) do
                if (child:IsA("Model") or child:IsA("BasePart")) and child.Name == index then
                    return child
                end
            end
            -- Fallback pelo DisplayName
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Model") or child:IsA("BasePart") then
                    return child
                end
            end
        end
    end
    return nil
end

-- ══════════════════════════════════════
-- IMAGEM DA WIKI
-- ══════════════════════════════════════
local BAD = {
    "background", "banner", "logo", "wiki_", "button", "badge", "placeholder",
    "cursor", "arrow", "wordmark", "favicon", "navicon", "header", "footer",
    "spotlight", "transparent", "question", "default", "noimage", "blank", "star",
}

local function isBad(url)
    if not url or url == "" then return true end
    local low = url:lower()
    for _, kw in ipairs(BAD) do if low:find(kw, 1, true) then return true end end
    local px = low:match("/(%d+)px%-")
    return px and tonumber(px) < 150
end

local function httpGet(url)
    local res
    if not res then pcall(function() res = request({ Url = url, Method = "GET" }) end) end
    if not res then pcall(function() res = http.request({ Url = url, Method = "GET" }) end) end
    if not res then pcall(function() res = syn.request({ Url = url, Method = "GET" }) end) end
    return res
end

local imageCache = {}
local function fetchFandomImage(name)
    if imageCache[name] then return imageCache[name] end
    local url, done = nil, false
    local v1 = name:gsub("(%a)([%w]*)", function(a, b) return a:upper() .. b:lower() end):gsub(" ", "_")
    local v2 = name:gsub(" ", "_")

    task.spawn(function()
        if done then return end
        for _, v in ipairs({ v1, v2 }) do
            if done then break end
            pcall(function()
                local res = httpGet(WIKI_API .. "?action=query&titles=" .. v .. "&prop=pageimages&format=json&pithumbsize=400&piprop=original|thumbnail")
                if done or not res or not res.Body then return end
                if res.Body:find('"missing"') then return end
                local orig = res.Body:match('"original":%s*{.-"source":%s*"([^"]+)"')
                if orig and not isBad(orig) then done = true; url = orig:gsub("\\", ""); return end
                local thumb = res.Body:match('"thumbnail":%s*{.-"source":%s*"([^"]+)"')
                if thumb and not isBad(thumb) then done = true; url = thumb:gsub("\\", "") end
            end)
        end
    end)

    task.spawn(function()
        if done then return end
        pcall(function()
            local res = httpGet(FANDOM_BASE .. v1)
            if done or not res or not res.Body then return end
            local og = res.Body:match('property="og:image"%s+content="([^"]+)"')
                    or res.Body:match('content="([^"]+)"%s+property="og:image"')
            if og and not isBad(og) then done = true; url = og:gsub("&amp;", "&"); return end
            for img in res.Body:gmatch('data%-src="(https://static%.wikia%.nocookie%.net/stealabrainrot/images/[^"]+)"') do
                local c = img:gsub("&amp;", "&"):match("^([^?]+)")
                if c and not isBad(c) then done = true; url = c; return end
            end
        end)
    end)

    local w = 0
    while not done and w < 4 do task.wait(0.05); w = w + 0.05 end
    if url then imageCache[name] = url end
    return url
end

-- ══════════════════════════════════════
-- SISTEMA DE TROCA VISUAL
-- ══════════════════════════════════════
local activeSwaps = {} -- { [plotName_slot] = { overlay=Model, billboard=BillboardGui } }

local function removeBillboard(plotName, slot)
    local key  = plotName .. "_" .. slot
    local swap = activeSwaps[key]
    if swap then
        pcall(function() swap.overlay:Destroy() end)
        pcall(function() swap.billboard:Destroy() end)
        activeSwaps[key] = nil
    end
end

local function applyVisualSwap(brainrot, newName, newMut, newTraits, newGenVal)
    local key = brainrot.plotName .. "_" .. brainrot.slot
    removeBillboard(brainrot.plotName, brainrot.slot)

    local cf = getPodiumCFrame(brainrot.plotName, brainrot.slot)
    if not cf then
        warn("[BranzZ] Podium não encontrado: " .. brainrot.plotName .. " slot " .. brainrot.slot)
        return false
    end

    local realModel = findRealModelByIndex(newName:gsub(" ", "_"))
    local overlay   = nil

    if realModel then
        overlay      = realModel:Clone()
        overlay.Name = "BRANZZ_OVERLAY_" .. key
        for _, s in ipairs(overlay:GetDescendants()) do
            if s:IsA("Script") or s:IsA("LocalScript") then s.Enabled = false end
            if s:IsA("BasePart") then s.Anchored = true; s.CanCollide = false end
        end
        overlay.Parent = Workspace
        pcall(function()
            if overlay:IsA("Model") and overlay.PrimaryPart then
                overlay:SetPrimaryPartCFrame(cf)
            end
        end)
    else
        overlay              = Instance.new("Part")
        overlay.Name         = "BRANZZ_OVERLAY_" .. key
        overlay.Size         = Vector3.new(2.5, 3.5, 2.5)
        overlay.Material     = Enum.Material.Neon
        overlay.BrickColor   = BrickColor.new("Bright violet")
        overlay.Anchored     = true
        overlay.CanCollide   = false
        overlay.CFrame       = cf
        overlay.Parent       = Workspace
    end

    local running = true
    task.spawn(function()
        while running and overlay.Parent do
            local primaryPart = overlay:IsA("Model") and overlay.PrimaryPart or overlay
            if primaryPart and primaryPart:IsA("BasePart") then
                primaryPart.CFrame = primaryPart.CFrame * CFrame.Angles(0, math.rad(1), 0)
            end
            task.wait(0.03)
        end
    end)

    local primaryPart = (overlay:IsA("Model") and overlay.PrimaryPart) or overlay
    if primaryPart and primaryPart:IsA("BasePart") then
        local bb             = Instance.new("BillboardGui")
        bb.Size              = UDim2.new(0, 220, 0, 130)
        bb.StudsOffset       = Vector3.new(0, 4, 0)
        bb.AlwaysOnTop       = false
        bb.Parent            = primaryPart

        local bg                     = Instance.new("Frame")
        bg.Size                      = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3          = Color3.fromRGB(13, 11, 22)
        bg.BackgroundTransparency    = 0.1
        bg.BorderSizePixel           = 0
        bg.Parent                    = bb
        local bgc                    = Instance.new("UICorner")
        bgc.CornerRadius             = UDim.new(0, 10)
        bgc.Parent                   = bg
        local bgs                    = Instance.new("UIStroke")
        bgs.Color                    = Color3.fromRGB(150, 100, 240)
        bgs.Thickness                = 1.5
        bgs.Parent                   = bg

        local topB                   = Instance.new("Frame")
        topB.Size                    = UDim2.new(1, 0, 0, 3)
        topB.BackgroundColor3        = Color3.fromRGB(160, 100, 255)
        topB.BorderSizePixel         = 0
        topB.Parent                  = bg
        local tbc                    = Instance.new("UICorner")
        tbc.CornerRadius             = UDim.new(0, 3)
        tbc.Parent                   = topB

        local function lbl(text, color, ypos, size)
            local l                  = Instance.new("TextLabel")
            l.Size                   = UDim2.new(1, -10, 0, 22)
            l.Position               = UDim2.new(0, 5, 0, ypos)
            l.BackgroundTransparency = 1
            l.Text                   = text
            l.TextColor3             = color
            l.TextSize               = size or 12
            l.Font                   = Enum.Font.GothamBold
            l.TextWrapped            = true
            l.Parent                 = bg
        end

        lbl("👑 " .. newName,          Color3.fromRGB(220, 185, 255), 6,  14)
        lbl("💰 " .. formatGen(newGenVal), Color3.fromRGB(140, 230, 140), 28, 13)
        lbl("🧬 Mut: " .. newMut,      Color3.fromRGB(255, 205, 100), 50, 12)
        lbl("⭐ " .. newTraits,        Color3.fromRGB(170, 210, 255), 72, 10)

        task.spawn(function()
            local t = 0
            while bb.Parent do
                t = t + 0.05
                bb.StudsOffset = Vector3.new(0, 4 + math.sin(t) * 0.4, 0)
                task.wait(0.05)
            end
        end)

        activeSwaps[key] = { overlay = overlay, billboard = bb, running = running }
    end

    return true
end

local function removeAllSwaps()
    for key, swap in pairs(activeSwaps) do
        pcall(function() swap.overlay:Destroy() end)
        pcall(function() swap.billboard:Destroy() end)
        activeSwaps[key] = nil
    end
end

-- ══════════════════════════════════════
-- SALVAR E RESTAURAR SWAPS
-- ══════════════════════════════════════
local savedSwaps = loadData()

local function saveSwap(slotKey, data)
    savedSwaps[slotKey] = data
    saveData(savedSwaps)
end

local function removeSavedSwap(slotKey)
    savedSwaps[slotKey] = nil
    saveData(savedSwaps)
end

-- ══════════════════════════════════════
-- HELPERS UI
-- ══════════════════════════════════════
local function makeCorner(p, r)
    local c          = Instance.new("UICorner")
    c.CornerRadius   = UDim.new(0, r or 12)
    c.Parent         = p
end

local function makeStroke(p, color, thick)
    local s      = Instance.new("UIStroke")
    s.Color      = color or Color3.fromRGB(180, 160, 220)
    s.Thickness  = thick or 1.5
    s.Parent     = p
    return s
end

local function makeLabel(parent, props)
    local l                  = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font                   = props.font or Enum.Font.Gotham
    l.TextColor3             = props.color or Color3.fromRGB(220, 210, 240)
    l.TextSize               = props.size or 13
    l.Text                   = props.text or ""
    l.Size                   = props.sz or UDim2.new(1, 0, 0, 22)
    l.Position               = props.pos or UDim2.new(0, 0, 0, 0)
    l.ZIndex                 = props.z or 3
    l.TextXAlignment         = props.align or Enum.TextXAlignment.Left
    l.TextWrapped            = true
    l.Parent                 = parent
    return l
end

local function makeInput(parent, placeholder, ypos, z)
    local bg                = Instance.new("Frame")
    bg.Size                 = UDim2.new(1, -20, 0, 34)
    bg.Position             = UDim2.new(0, 10, 0, ypos)
    bg.BackgroundColor3     = Color3.fromRGB(22, 18, 36)
    bg.BorderSizePixel      = 0
    bg.ZIndex               = z or 3
    bg.Parent               = parent
    makeCorner(bg, 8)
    makeStroke(bg, Color3.fromRGB(90, 70, 150), 1.2)

    local input                  = Instance.new("TextBox")
    input.Size                   = UDim2.new(1, -16, 1, 0)
    input.Position               = UDim2.new(0, 8, 0, 0)
    input.BackgroundTransparency = 1
    input.Text                   = ""
    input.PlaceholderText        = placeholder
    input.TextColor3             = Color3.fromRGB(215, 205, 240)
    input.PlaceholderColor3      = Color3.fromRGB(90, 75, 130)
    input.TextSize               = 13
    input.Font                   = Enum.Font.Gotham
    input.ClearTextOnFocus       = false
    input.ZIndex                 = (z or 3) + 1
    input.Parent                 = bg
    return input
end

local function makeBtn(parent, text, color, sz, pos, z)
    local b              = Instance.new("TextButton")
    b.Size               = sz
    b.Position           = pos
    b.BackgroundColor3   = color
    b.Text               = text
    b.TextColor3         = Color3.fromRGB(240, 230, 255)
    b.TextSize           = 14
    b.Font               = Enum.Font.GothamBold
    b.BorderSizePixel    = 0
    b.AutoButtonColor    = false
    b.ZIndex             = z or 3
    b.Parent             = parent
    makeCorner(b, 10)
    return b
end

local function makeDrag(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = i.Position
            startPos  = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d      = i.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

-- ══════════════════════════════════════
-- UI
-- ══════════════════════════════════════
local sg                = Instance.new("ScreenGui")
sg.Name                 = "BRANZZ_SPAWN_V3"
sg.ResetOnSpawn         = false
sg.ZIndexBehavior       = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset       = true
sg.Parent               = CoreGui

-- Janela principal
local main              = Instance.new("Frame")
main.Size               = UDim2.new(0, 340, 0, 560)
main.Position           = UDim2.new(0.5, -170, 0.5, -280)
main.BackgroundColor3   = Color3.fromRGB(12, 10, 20)
main.BorderSizePixel    = 0
main.ZIndex             = 2
main.Parent             = sg
makeCorner(main, 20)
makeStroke(main, Color3.fromRGB(140, 100, 220), 1.5)

local grad       = Instance.new("UIGradient")
grad.Color       = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 14, 32)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 8, 18)),
})
grad.Rotation    = 135
grad.Parent      = main

local accentBar              = Instance.new("Frame")
accentBar.Size               = UDim2.new(1, 0, 0, 4)
accentBar.BackgroundColor3   = Color3.fromRGB(150, 80, 255)
accentBar.BorderSizePixel    = 0
accentBar.ZIndex             = 3
accentBar.Parent             = main
makeCorner(accentBar, 4)

-- Header
local header              = Instance.new("Frame")
header.Size               = UDim2.new(1, 0, 0, 52)
header.BackgroundColor3   = Color3.fromRGB(18, 14, 30)
header.BorderSizePixel    = 0
header.ZIndex             = 3
header.Parent             = main
makeCorner(header, 20)

local hFix              = Instance.new("Frame")
hFix.Size               = UDim2.new(1, 0, 0, 20)
hFix.Position           = UDim2.new(0, 0, 1, -20)
hFix.BackgroundColor3   = Color3.fromRGB(18, 14, 30)
hFix.BorderSizePixel    = 0
hFix.ZIndex             = 3
hFix.Parent             = header

makeDrag(main, header)

makeLabel(header, {
    text  = "🧠 BranzZ Spawn Visual",
    font  = Enum.Font.GothamBold,
    size  = 15,
    color = Color3.fromRGB(210, 180, 255),
    sz    = UDim2.new(1, -80, 0, 24),
    pos   = UDim2.new(0, 14, 0, 8),
    z     = 4,
})
makeLabel(header, {
    text  = "Visual só pra você  •  v3.0",
    size  = 11,
    color = Color3.fromRGB(100, 80, 150),
    sz    = UDim2.new(1, -80, 0, 16),
    pos   = UDim2.new(0, 14, 0, 32),
    z     = 4,
})

local closeBtn           = makeBtn(header, "✕", Color3.fromRGB(180, 50, 50), UDim2.new(0, 28, 0, 28), UDim2.new(1, -38, 0.5, -14), 5)
closeBtn.TextColor3      = Color3.fromRGB(255, 210, 210)
closeBtn.TextSize        = 14
closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
    task.wait(0.35)
    sg:Destroy()
end)

-- Tabs
local TAB_H              = 36
local tabFrame           = Instance.new("Frame")
tabFrame.Size            = UDim2.new(1, -20, 0, TAB_H)
tabFrame.Position        = UDim2.new(0, 10, 0, 58)
tabFrame.BackgroundColor3 = Color3.fromRGB(18, 14, 30)
tabFrame.BorderSizePixel = 0
tabFrame.ZIndex          = 3
tabFrame.Parent          = main
makeCorner(tabFrame, 10)
makeStroke(tabFrame, Color3.fromRGB(60, 45, 100), 1)

local tabSpawn          = makeBtn(tabFrame, "✨ Spawn", Color3.fromRGB(90, 55, 185), UDim2.new(0.5, 0, 1, 0), UDim2.new(0, 0, 0, 0), 4)
tabSpawn.TextSize       = 13
local tabSwap           = makeBtn(tabFrame, "🔄 Trocar", Color3.fromRGB(22, 18, 36), UDim2.new(0.5, 0, 1, 0), UDim2.new(0.5, 0, 0, 0), 4)
tabSwap.TextSize        = 13
tabSwap.TextColor3      = Color3.fromRGB(170, 150, 220)

-- Páginas
local pageSpawn               = Instance.new("Frame")
pageSpawn.Size                = UDim2.new(1, 0, 1, -100)
pageSpawn.Position            = UDim2.new(0, 0, 0, 100)
pageSpawn.BackgroundTransparency = 1
pageSpawn.ZIndex              = 3
pageSpawn.Parent              = main

local pageSwap                = Instance.new("Frame")
pageSwap.Size                 = UDim2.new(1, 0, 1, -100)
pageSwap.Position             = UDim2.new(0, 0, 0, 100)
pageSwap.BackgroundTransparency = 1
pageSwap.ZIndex               = 3
pageSwap.Visible              = false
pageSwap.Parent               = main

local function setTab(isSpawn)
    pageSpawn.Visible        = isSpawn
    pageSwap.Visible         = not isSpawn
    tabSpawn.BackgroundColor3 = isSpawn and Color3.fromRGB(90, 55, 185) or Color3.fromRGB(22, 18, 36)
    tabSpawn.TextColor3      = isSpawn and Color3.fromRGB(240, 230, 255) or Color3.fromRGB(170, 150, 220)
    tabSwap.BackgroundColor3 = not isSpawn and Color3.fromRGB(90, 55, 185) or Color3.fromRGB(22, 18, 36)
    tabSwap.TextColor3       = not isSpawn and Color3.fromRGB(240, 230, 255) or Color3.fromRGB(170, 150, 220)
end

tabSpawn.MouseButton1Click:Connect(function() setTab(true) end)
tabSwap.MouseButton1Click:Connect(function() setTab(false) end)

-- ══════════════════════════════════════
-- PAGE SPAWN
-- ══════════════════════════════════════

-- Preview
local previewFrame              = Instance.new("Frame")
previewFrame.Size               = UDim2.new(1, -20, 0, 96)
previewFrame.Position           = UDim2.new(0, 10, 0, 4)
previewFrame.BackgroundColor3   = Color3.fromRGB(18, 14, 30)
previewFrame.BorderSizePixel    = 0
previewFrame.ZIndex             = 4
previewFrame.Parent             = pageSpawn
makeCorner(previewFrame, 12)
makeStroke(previewFrame, Color3.fromRGB(80, 55, 140), 1.2)

local previewImg             = Instance.new("ImageLabel")
previewImg.Size              = UDim2.new(0, 86, 0, 86)
previewImg.Position          = UDim2.new(0, 5, 0.5, -43)
previewImg.BackgroundColor3  = Color3.fromRGB(28, 18, 48)
previewImg.Image             = ""
previewImg.ScaleType         = Enum.ScaleType.Fit
previewImg.ZIndex            = 5
previewImg.Parent            = previewFrame
makeCorner(previewImg, 10)

local pName   = makeLabel(previewFrame, { text = "Nome do Brainrot", font = Enum.Font.GothamBold, size = 13, color = Color3.fromRGB(200, 175, 245), sz = UDim2.new(1, -102, 0, 20), pos = UDim2.new(0, 97, 0, 6),  z = 5 })
local pGen    = makeLabel(previewFrame, { text = "Gen: —",           size = 12,                   color = Color3.fromRGB(140, 225, 140),             sz = UDim2.new(1, -102, 0, 18), pos = UDim2.new(0, 97, 0, 28), z = 5 })
local pMut    = makeLabel(previewFrame, { text = "Mut: —",           size = 11,                   color = Color3.fromRGB(255, 205, 100),             sz = UDim2.new(1, -102, 0, 18), pos = UDim2.new(0, 97, 0, 48), z = 5 })
local pTraits = makeLabel(previewFrame, { text = "Traits: —",        size = 10,                   color = Color3.fromRGB(160, 205, 255),             sz = UDim2.new(1, -102, 0, 18), pos = UDim2.new(0, 97, 0, 68), z = 5 })

local div1                  = Instance.new("Frame")
div1.Size                   = UDim2.new(0.9, 0, 0, 1)
div1.Position               = UDim2.new(0.05, 0, 0, 106)
div1.BackgroundColor3       = Color3.fromRGB(50, 38, 80)
div1.BorderSizePixel        = 0
div1.ZIndex                 = 4
div1.Parent                 = pageSpawn

makeLabel(pageSpawn, { text = "Nome",       size = 12, color = Color3.fromRGB(160, 135, 210), sz = UDim2.new(1, -20, 0, 16), pos = UDim2.new(0, 10, 0, 114), z = 4 })
local inputName   = makeInput(pageSpawn, "Ex: Capitano Moby",       130, 4)

makeLabel(pageSpawn, { text = "Geração /s", size = 12, color = Color3.fromRGB(160, 135, 210), sz = UDim2.new(1, -20, 0, 16), pos = UDim2.new(0, 10, 0, 170), z = 4 })
local inputGen    = makeInput(pageSpawn, "Ex: 4000000000",           186, 4)

makeLabel(pageSpawn, { text = "Mutação",    size = 12, color = Color3.fromRGB(160, 135, 210), sz = UDim2.new(1, -20, 0, 16), pos = UDim2.new(0, 10, 0, 226), z = 4 })
local inputMut    = makeInput(pageSpawn, "Ex: Gold, Rainbow...",     242, 4)

makeLabel(pageSpawn, { text = "Traits",     size = 12, color = Color3.fromRGB(160, 135, 210), sz = UDim2.new(1, -20, 0, 16), pos = UDim2.new(0, 10, 0, 282), z = 4 })
local inputTraits = makeInput(pageSpawn, "Ex: Taco, Fire, Nyan Cat", 298, 4)

local statusSpawn = makeLabel(pageSpawn, {
    text  = "",
    size  = 12,
    color = Color3.fromRGB(140, 220, 140),
    sz    = UDim2.new(1, -20, 0, 16),
    pos   = UDim2.new(0, 10, 0, 340),
    z     = 4,
    align = Enum.TextXAlignment.Center,
})

local spawnBtn = makeBtn(pageSpawn, "✨  Spawn",   Color3.fromRGB(90, 55, 185),  UDim2.new(0.56, 0, 0, 40), UDim2.new(0.05, 0, 0, 360), 4)
makeStroke(spawnBtn, Color3.fromRGB(150, 90, 255), 1.5)

local clearBtn = makeBtn(pageSpawn, "🗑 Limpar",   Color3.fromRGB(160, 50, 50),  UDim2.new(0.33, 0, 0, 40), UDim2.new(0.63, 0, 0, 360), 4)
makeStroke(clearBtn, Color3.fromRGB(220, 70, 70), 1.5)

makeLabel(pageSpawn, {
    text  = "「🇧🇷」branzZ🧠  •  v3.0",
    size  = 10,
    color = Color3.fromRGB(55, 42, 85),
    sz    = UDim2.new(1, 0, 0, 16),
    pos   = UDim2.new(0, 0, 0, 406),
    z     = 4,
    align = Enum.TextXAlignment.Center,
})

-- Hover
spawnBtn.MouseEnter:Connect(function() TweenService:Create(spawnBtn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(115, 75, 220) }):Play() end)
spawnBtn.MouseLeave:Connect(function() TweenService:Create(spawnBtn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(90, 55, 185)  }):Play() end)
clearBtn.MouseEnter:Connect(function() TweenService:Create(clearBtn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(200, 65, 65)  }):Play() end)
clearBtn.MouseLeave:Connect(function() TweenService:Create(clearBtn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(160, 50, 50)  }):Play() end)

-- ══════════════════════════════════════
-- PAGE SWAP
-- ══════════════════════════════════════

makeLabel(pageSwap, {
    text  = "Meus Brainrots",
    font  = Enum.Font.GothamBold,
    size  = 13,
    color = Color3.fromRGB(200, 175, 245),
    sz    = UDim2.new(1, -20, 0, 20),
    pos   = UDim2.new(0, 10, 0, 6),
    z     = 4,
})

-- Lista de brainrots
local listFrame                     = Instance.new("ScrollingFrame")
listFrame.Size                      = UDim2.new(1, -20, 0, 180)
listFrame.Position                  = UDim2.new(0, 10, 0, 28)
listFrame.BackgroundColor3          = Color3.fromRGB(16, 12, 28)
listFrame.BorderSizePixel           = 0
listFrame.ScrollBarThickness        = 4
listFrame.ScrollBarImageColor3      = Color3.fromRGB(120, 80, 200)
listFrame.ZIndex                    = 4
listFrame.Parent                    = pageSwap
listFrame.CanvasSize                = UDim2.new(0, 0, 0, 0)
makeCorner(listFrame, 10)
makeStroke(listFrame, Color3.fromRGB(60, 45, 100), 1)

local listLayout         = Instance.new("UIListLayout")
listLayout.Padding       = UDim.new(0, 4)
listLayout.Parent        = listFrame
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
end)

local selectedBrainrot = nil
local brainrotItems    = {}

local function refreshList()
    for _, c in ipairs(listFrame:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    brainrotItems  = {}
    selectedBrainrot = nil

    local myBrainrots = scanMyBrainrots()

    if #myBrainrots == 0 then
        makeLabel(listFrame, {
            text  = "Nenhum brainrot detectado na sua base",
            size  = 12,
            color = Color3.fromRGB(130, 100, 180),
            sz    = UDim2.new(1, -10, 0, 30),
            pos   = UDim2.new(0, 5, 0, 0),
            z     = 5,
            align = Enum.TextXAlignment.Center,
        })
        return
    end

    for _, br in ipairs(myBrainrots) do
        local item                = Instance.new("TextButton")
        item.Size                 = UDim2.new(1, -8, 0, 48)
        item.BackgroundColor3     = Color3.fromRGB(22, 17, 38)
        item.Text                 = ""
        item.BorderSizePixel      = 0
        item.AutoButtonColor      = false
        item.ZIndex               = 5
        item.Parent               = listFrame
        makeCorner(item, 8)
        makeStroke(item, Color3.fromRGB(60, 45, 100), 1)

        makeLabel(item, { text = "👑 " .. br.displayName, font = Enum.Font.GothamBold, size = 12, color = Color3.fromRGB(200, 175, 245), sz = UDim2.new(1, -10, 0, 20), pos = UDim2.new(0, 8, 0, 4),  z = 6 })
        makeLabel(item, { text = "💰 " .. formatGen(br.genVal) .. "  🧬 " .. br.mutation,          size = 11, color = Color3.fromRGB(140, 220, 140), sz = UDim2.new(1, -10, 0, 18), pos = UDim2.new(0, 8, 0, 24), z = 6 })

        local brCopy = br
        item.MouseButton1Click:Connect(function()
            selectedBrainrot = brCopy
            for _, itm in ipairs(brainrotItems) do
                TweenService:Create(itm, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(22, 17, 38) }):Play()
            end
            TweenService:Create(item, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(60, 40, 120) }):Play()
            statusSwap.Text      = "✅ Selecionado: " .. brCopy.displayName
            statusSwap.TextColor3 = Color3.fromRGB(140, 220, 140)
        end)

        table.insert(brainrotItems, item)
    end
end

local div2                  = Instance.new("Frame")
div2.Size                   = UDim2.new(0.9, 0, 0, 1)
div2.Position               = UDim2.new(0.05, 0, 0, 214)
div2.BackgroundColor3       = Color3.fromRGB(50, 38, 80)
div2.BorderSizePixel        = 0
div2.ZIndex                 = 4
div2.Parent                 = pageSwap

makeLabel(pageSwap, {
    text  = "Trocar visual por:",
    font  = Enum.Font.GothamBold,
    size  = 13,
    color = Color3.fromRGB(200, 175, 245),
    sz    = UDim2.new(1, -20, 0, 18),
    pos   = UDim2.new(0, 10, 0, 220),
    z     = 4,
})

makeLabel(pageSwap, { text = "Novo Nome",       size = 12, color = Color3.fromRGB(160, 135, 210), sz = UDim2.new(1, -20, 0, 16), pos = UDim2.new(0, 10, 0, 242), z = 4 })
local swapInputName   = makeInput(pageSwap, "Ex: Dragon Cannelloni",   258, 4)

makeLabel(pageSwap, { text = "Nova Geração /s", size = 12, color = Color3.fromRGB(160, 135, 210), sz = UDim2.new(1, -20, 0, 16), pos = UDim2.new(0, 10, 0, 298), z = 4 })
local swapInputGen    = makeInput(pageSwap, "Ex: 18800000000",          314, 4)

makeLabel(pageSwap, { text = "Nova Mutação",    size = 12, color = Color3.fromRGB(160, 135, 210), sz = UDim2.new(1, -20, 0, 16), pos = UDim2.new(0, 10, 0, 354), z = 4 })
local swapInputMut    = makeInput(pageSwap, "Ex: Cyber",                370, 4)

makeLabel(pageSwap, { text = "Novos Traits",    size = 12, color = Color3.fromRGB(160, 135, 210), sz = UDim2.new(1, -20, 0, 16), pos = UDim2.new(0, 10, 0, 410), z = 4 })
local swapInputTraits = makeInput(pageSwap, "Ex: Fire, Crab, Tung Tung", 426, 4)

local statusSwap = makeLabel(pageSwap, {
    text  = "",
    size  = 12,
    color = Color3.fromRGB(140, 220, 140),
    sz    = UDim2.new(1, -20, 0, 14),
    pos   = UDim2.new(0, 10, 0, 466),
    z     = 4,
    align = Enum.TextXAlignment.Center,
})

local swapBtn       = makeBtn(pageSwap, "🔄  Aplicar Troca", Color3.fromRGB(60, 120, 80),  UDim2.new(0.56, 0, 0, 36), UDim2.new(0.05, 0, 0, 484), 4)
makeStroke(swapBtn, Color3.fromRGB(80, 180, 110), 1.5)

local refreshBtn    = makeBtn(pageSwap, "🔃",                Color3.fromRGB(40, 35, 70),   UDim2.new(0.1, 0, 0, 36),  UDim2.new(0.63, 0, 0, 484), 4)
makeStroke(refreshBtn, Color3.fromRGB(100, 80, 160), 1.2)

local removeSwapBtn = makeBtn(pageSwap, "✖ Remover",         Color3.fromRGB(160, 50, 50),  UDim2.new(0.22, 0, 0, 36), UDim2.new(0.75, 0, 0, 484), 4)
makeStroke(removeSwapBtn, Color3.fromRGB(220, 70, 70), 1.2)
removeSwapBtn.TextSize = 11

swapBtn.MouseEnter:Connect(function() TweenService:Create(swapBtn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(75, 150, 100)  }):Play() end)
swapBtn.MouseLeave:Connect(function() TweenService:Create(swapBtn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(60, 120, 80)   }):Play() end)

-- ══════════════════════════════════════
-- LÓGICA SPAWN
-- ══════════════════════════════════════
local spawnedVisuals = {}

local function spawnVisualFree(name, mutation, traits, genVal)
    local myPlotName = getMyPlotName()
    if not myPlotName then
        warn("[BranzZ] Plot não encontrado!")
        return nil
    end

    local plots    = Workspace:FindFirstChild("Plots")
    local myPlot   = plots and plots:FindFirstChild(myPlotName)
    local spawnCF  = CFrame.new(0, 10, 0)

    if myPlot then
        local podiums = myPlot:FindFirstChild("AnimalPodiums")
        if podiums then
            for _, pod in ipairs(podiums:GetChildren()) do
                local base      = pod:FindFirstChild("Base")
                local spawn     = base and base:FindFirstChild("Spawn")
                local container = spawn or base
                if container then
                    for _, part in ipairs((container:IsA("Model") and container:GetDescendants() or container:GetChildren())) do
                        if part:IsA("BasePart") then
                            spawnCF = part.CFrame + Vector3.new(0, 3, 0)
                            break
                        end
                    end
                    break
                end
            end
        end
    end

    local realModel  = findRealModelByIndex(name:gsub(" ", "_"))
    local container  = Instance.new("Model")
    container.Name   = "BRANZZ_SPAWN_" .. name:gsub(" ", "_")
    container.Parent = myPlot or Workspace

    if realModel then
        local clone = realModel:Clone()
        for _, s in ipairs(clone:GetDescendants()) do
            if s:IsA("Script") or s:IsA("LocalScript") then s.Enabled = false end
            if s:IsA("BasePart") then s.Anchored = true; s.CanCollide = false end
        end
        clone.Parent = container
        pcall(function()
            if clone:IsA("Model") and clone.PrimaryPart then
                clone:SetPrimaryPartCFrame(spawnCF)
            end
        end)
        container.PrimaryPart = clone:IsA("Model") and clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart", true)
    else
        local part           = Instance.new("Part")
        part.Size            = Vector3.new(2.5, 3.5, 2.5)
        part.Material        = Enum.Material.Neon
        part.BrickColor      = BrickColor.new("Bright violet")
        part.Anchored        = true
        part.CanCollide      = false
        part.CFrame          = spawnCF
        part.Name            = name
        part.Parent          = container
        container.PrimaryPart = part
    end

    local primaryPart = container.PrimaryPart or container:FindFirstChildWhichIsA("BasePart", true)
    if primaryPart then
        local bb             = Instance.new("BillboardGui")
        bb.Size              = UDim2.new(0, 220, 0, 130)
        bb.StudsOffset       = Vector3.new(0, 4, 0)
        bb.AlwaysOnTop       = false
        bb.Parent            = primaryPart

        local bg                  = Instance.new("Frame")
        bg.Size                   = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3       = Color3.fromRGB(13, 11, 22)
        bg.BackgroundTransparency = 0.1
        bg.BorderSizePixel        = 0
        bg.Parent                 = bb
        makeCorner(bg, 10)
        makeStroke(bg, Color3.fromRGB(150, 100, 240), 1.5)

        local topB              = Instance.new("Frame")
        topB.Size               = UDim2.new(1, 0, 0, 3)
        topB.BackgroundColor3   = Color3.fromRGB(160, 100, 255)
        topB.BorderSizePixel    = 0
        topB.Parent             = bg
        makeCorner(topB, 3)

        local function lbl(text, color, ypos, size)
            local l                  = Instance.new("TextLabel")
            l.Size                   = UDim2.new(1, -10, 0, 22)
            l.Position               = UDim2.new(0, 5, 0, ypos)
            l.BackgroundTransparency = 1
            l.Text                   = text
            l.TextColor3             = color
            l.TextSize               = size or 12
            l.Font                   = Enum.Font.GothamBold
            l.TextWrapped            = true
            l.Parent                 = bg
        end

        lbl("👑 " .. name,           Color3.fromRGB(220, 185, 255), 6,  14)
        lbl("💰 " .. formatGen(genVal), Color3.fromRGB(140, 230, 140), 28, 13)
        lbl("🧬 Mut: " .. mutation,  Color3.fromRGB(255, 205, 100), 50, 12)
        lbl("⭐ " .. traits,         Color3.fromRGB(170, 210, 255), 72, 10)

        task.spawn(function()
            local t = 0
            while bb.Parent do
                t = t + 0.05
                bb.StudsOffset = Vector3.new(0, 4 + math.sin(t) * 0.4, 0)
                task.wait(0.05)
            end
        end)

        task.spawn(function()
            while container.Parent do
                if primaryPart and primaryPart:IsA("BasePart") then
                    primaryPart.CFrame = primaryPart.CFrame * CFrame.Angles(0, math.rad(1), 0)
                end
                task.wait(0.03)
            end
        end)
    end

    table.insert(spawnedVisuals, container)
    return container
end

-- ══════════════════════════════════════
-- LÓGICA BOTÕES
-- ══════════════════════════════════════

-- Preview ao sair do campo nome (spawn)
inputName.FocusLost:Connect(function()
    local name = inputName.Text
    if name == "" then return end
    pName.Text        = "⏳ Buscando..."
    statusSpawn.Text  = "🔍 Buscando..."
    statusSpawn.TextColor3 = Color3.fromRGB(200, 200, 100)
    task.spawn(function()
        local img      = fetchFandomImage(name)
        previewImg.Image = img or ""
        pName.Text     = name
        pGen.Text      = "Gen: " .. formatGen(tonumber(inputGen.Text) or 0)
        pMut.Text      = "Mut: " .. (inputMut.Text ~= "" and inputMut.Text or "None")
        pTraits.Text   = "Traits: " .. (inputTraits.Text ~= "" and inputTraits.Text or "None")
        statusSpawn.Text      = img and "✅ Imagem encontrada!" or "⚠️ Sem imagem"
        statusSpawn.TextColor3 = img and Color3.fromRGB(140, 220, 140) or Color3.fromRGB(255, 180, 80)
    end)
end)

-- Spawn
spawnBtn.MouseButton1Click:Connect(function()
    local name   = inputName.Text
    local genVal = tonumber(inputGen.Text) or 0
    local mut    = inputMut.Text ~= "" and inputMut.Text or "None"
    local traits = inputTraits.Text ~= "" and inputTraits.Text or "None"

    if name == "" then
        statusSpawn.Text       = "⚠️ Coloca o nome!"
        statusSpawn.TextColor3 = Color3.fromRGB(255, 120, 120)
        return
    end

    spawnBtn.Text              = "⏳ Spawning..."
    spawnBtn.BackgroundColor3  = Color3.fromRGB(55, 35, 110)
    statusSpawn.Text           = "⏳ Spawning..."
    statusSpawn.TextColor3     = Color3.fromRGB(200, 200, 100)

    task.spawn(function()
        local model = spawnVisualFree(name, mut, traits, genVal)
        if model then
            statusSpawn.Text       = "✅ " .. name .. " spawned!"
            statusSpawn.TextColor3 = Color3.fromRGB(140, 220, 140)
        else
            statusSpawn.Text       = "❌ Erro ao spawnar"
            statusSpawn.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        task.wait(0.4)
        spawnBtn.Text             = "✨  Spawn"
        spawnBtn.BackgroundColor3 = Color3.fromRGB(90, 55, 185)
    end)
end)

-- Limpar spawns
clearBtn.MouseButton1Click:Connect(function()
    for _, v in ipairs(spawnedVisuals) do pcall(function() v:Destroy() end) end
    spawnedVisuals         = {}
    statusSpawn.Text       = "🗑 Removidos!"
    statusSpawn.TextColor3 = Color3.fromRGB(255, 180, 80)
    task.delay(2, function() statusSpawn.Text = "" end)
end)

-- Refresh lista swap
refreshBtn.MouseButton1Click:Connect(function()
    statusSwap.Text       = "🔄 Atualizando..."
    statusSwap.TextColor3 = Color3.fromRGB(200, 200, 100)
    refreshList()
    statusSwap.Text       = "✅ Lista atualizada!"
    statusSwap.TextColor3 = Color3.fromRGB(140, 220, 140)
    task.delay(2, function() statusSwap.Text = "" end)
end)

-- Aplicar troca
swapBtn.MouseButton1Click:Connect(function()
    if not selectedBrainrot then
        statusSwap.Text       = "⚠️ Seleciona um Brainrot!"
        statusSwap.TextColor3 = Color3.fromRGB(255, 120, 120)
        return
    end

    local newName   = swapInputName.Text
    local newGenVal = tonumber(swapInputGen.Text) or selectedBrainrot.genVal
    local newMut    = swapInputMut.Text ~= "" and swapInputMut.Text or selectedBrainrot.mutation
    local newTraits = swapInputTraits.Text ~= "" and swapInputTraits.Text or selectedBrainrot.traits

    if newName == "" then
        statusSwap.Text       = "⚠️ Coloca o novo nome!"
        statusSwap.TextColor3 = Color3.fromRGB(255, 120, 120)
        return
    end

    swapBtn.Text              = "⏳ Aplicando..."
    swapBtn.BackgroundColor3  = Color3.fromRGB(35, 70, 50)
    statusSwap.Text           = "⏳ Aplicando troca..."
    statusSwap.TextColor3     = Color3.fromRGB(200, 200, 100)

    task.spawn(function()
        local myBrainrots = scanMyBrainrots()
        local count       = 0
        for _, br in ipairs(myBrainrots) do
            if br.displayName == selectedBrainrot.displayName and br.mutation == selectedBrainrot.mutation then
                local ok = applyVisualSwap(br, newName, newMut, newTraits, newGenVal)
                if ok then
                    count = count + 1
                    local slotKey = br.plotName .. "_" .. br.slot
                    saveSwap(slotKey, {
                        plotName  = br.plotName,
                        slot      = br.slot,
                        newName   = newName,
                        newMut    = newMut,
                        newTraits = newTraits,
                        newGenVal = newGenVal,
                    })
                end
            end
        end

        if count > 0 then
            statusSwap.Text       = "✅ Trocado em " .. count .. " slot(s)!"
            statusSwap.TextColor3 = Color3.fromRGB(140, 220, 140)
        else
            statusSwap.Text       = "❌ Não foi possível aplicar"
            statusSwap.TextColor3 = Color3.fromRGB(255, 100, 100)
        end

        task.wait(0.4)
        swapBtn.Text             = "🔄  Aplicar Troca"
        swapBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 80)
    end)
end)

-- Remover troca
removeSwapBtn.MouseButton1Click:Connect(function()
    if not selectedBrainrot then
        statusSwap.Text       = "⚠️ Seleciona um Brainrot!"
        statusSwap.TextColor3 = Color3.fromRGB(255, 120, 120)
        return
    end
    local myBrainrots = scanMyBrainrots()
    local count       = 0
    for _, br in ipairs(myBrainrots) do
        if br.displayName == selectedBrainrot.displayName and br.mutation == selectedBrainrot.mutation then
            local slotKey = br.plotName .. "_" .. br.slot
            removeBillboard(br.plotName, br.slot)
            removeSavedSwap(slotKey)
            count = count + 1
        end
    end
    statusSwap.Text       = "🗑 Removido de " .. count .. " slot(s)!"
    statusSwap.TextColor3 = Color3.fromRGB(255, 180, 80)
    task.delay(2, function() statusSwap.Text = "" end)
end)

-- ══════════════════════════════════════
-- RESTAURAR SWAPS SALVOS
-- ══════════════════════════════════════
task.spawn(function()
    task.wait(3)
    local count = 0
    for slotKey, data in pairs(savedSwaps) do
        if data and data.plotName and data.slot then
            local fakeBr = {
                plotName    = data.plotName,
                slot        = data.slot,
                displayName = data.newName,
                mutation    = data.newMut,
            }
            local ok = applyVisualSwap(fakeBr, data.newName, data.newMut, data.newTraits, data.newGenVal)
            if ok then count = count + 1 end
        end
    end
    if count > 0 then
        print("[BranzZ] ✅ " .. count .. " swap(s) restaurado(s) do executor!")
    end
end)

-- ══════════════════════════════════════
-- INIT
-- ══════════════════════════════════════
refreshList()
print("[BranzZ] ✅ Spawn Visual v3.0 carregado!")
