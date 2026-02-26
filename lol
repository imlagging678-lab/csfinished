local username = "imlagging678-lab"
local repo = "cs5.6" 
local baseUrl = "https://raw.githubusercontent.com/" .. username .. "/" .. repo .. "/main/"
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Camera = workspace.CurrentCamera

local function sendNotification(msg)
    warn(msg)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "csgo moveset",
            Text = msg,
            Duration = 5
        })
    end)
end

local oldGui = game:GetService("CoreGui"):FindFirstChild("CENTERED_PIXEL_SYSTEM")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
screenGui.Name = "CENTERED_PIXEL_SYSTEM"
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = -9999999 

local pixelPool = {}
for i = 1, 8000 do 
    local p = Instance.new("Frame", screenGui)
    p.BorderSizePixel = 0
    p.Visible = false
    pixelPool[i] = p
end

-- preload
local animationFrames = {}
local idleData = nil

local function preload()
    local s, b = pcall(function() return game:HttpGet(baseUrl .. "idle.json", true) end)
    if s then idleData = HttpService:JSONDecode(b) end
    for i = 1, 24 do
        local success, body = pcall(function() return game:HttpGet(baseUrl .. "a" .. i .. ".json", true) end)
        if success then animationFrames[i] = HttpService:JSONDecode(body) end
    end
end

local function ultraSmoothRender(startData, endData, duration, sw, sh, zoom, oW, oH, isIdle)
    if not endData or not startData then return end
    
    local startX = (sw / 2.05) - ((oW / 2) * zoom)
    local startY = (sh / 1.81) - ((oH / 2) * zoom)
    
    local taskMap = {}
    for i = 1, 8000 do
        local target = endData[i]
        local start = startData[i] or target
        if target and type(target) == "table" and target[1] ~= 0 then 
            local p1X, p1Y = startX + (start[1] * zoom), startY + (start[2] * zoom)
            local p2X, p2Y = startX + (target[1] * zoom), startY + (target[2] * zoom)
            local dist = math.sqrt((p2X - p1X)^2 + (p2Y - p1Y)^2)
            if dist > (40 * zoom) then
                taskMap[i] = {p2X, p2Y, p2X, p2Y, target, target}
            else
                taskMap[i] = {p1X, p1Y, p2X, p2Y, start, target}
            end
        else
            taskMap[i] = false
        end
    end

    local elapsed = 0
    while elapsed < duration do
        local dt = RunService.RenderStepped:Wait()
        elapsed = elapsed + dt
        local alpha = math.clamp(elapsed / duration, 0, 1)
        local curve = math.sin(alpha * (math.pi / 2)) 

        local offsetX = 0
        local offsetY = 0
        if isIdle then
            offsetX = math.cos(tick() * 1.0) * 0.8 
            offsetY = math.sin(tick() * 1.2) * 1.5 
        end

        for i = 1, 8000 do 
            local p = pixelPool[i]
            local t = taskMap[i]
            if t then
                local targetPosX = t[1] + (t[3] - t[1]) * curve + offsetX
                local targetPosY = t[2] + (t[4] - t[2]) * curve + offsetY
                
                p.Position = UDim2.new(0, math.round(targetPosX), 0, math.round(targetPosY))
                local c1 = Color3.new(t[5][3], t[5][4], t[5][5])
                local c2 = Color3.new(t[6][3], t[6][4], t[6][5])
                p.BackgroundColor3 = c1:Lerp(c2, curve)
                
                local stretch = (alpha > 0 and alpha < 1) and 0.8 or 0.45
                p.Size = UDim2.new(0, math.ceil(zoom + stretch), 0, math.ceil(zoom + stretch))
                p.Visible = true
            else
                if p.Visible then p.Visible = false end
            end
        end
    end
end

local function play()
    sendNotification("frames are loading behind screen...")
    preload()
    
    local loadedCount = 0
    repeat
        loadedCount = 0
        for i = 1, 24 do 
            if animationFrames[i] then 
                loadedCount = loadedCount + 1 
            end 
        end
        task.wait(0.7)
    until idleData and loadedCount >= 23
    
    -- BURASI: Notification çıkıyor ve sinyal gönderiliyor
    sendNotification("Loaded")
    _G.CS5_6_Loaded = true 

    local oW, oH = 373, 165 
    local zoom = 3.9
    local lastData = idleData

    while true do
        local sw, sh = Camera.ViewportSize.X, Camera.ViewportSize.Y
        
        ultraSmoothRender(lastData, idleData, 0.7, sw, sh, zoom, oW, oH, false)

        local idleStart = tick()
        while tick() - idleStart < 10 do
            ultraSmoothRender(idleData, idleData, 0.1, sw, sh, zoom, oW, oH, true) 
            if (tick() - idleStart >= 10) then break end
        end
        
        lastData = idleData

        for i = 1, 24 do
            local nextData = animationFrames[i]
            if nextData then
                ultraSmoothRender(lastData, nextData, 0.08, sw, sh, zoom, oW, oH, false)
                lastData = nextData
            end
        end
    end
end

task.spawn(play)
