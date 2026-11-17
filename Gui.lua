-- Lex Hub | Frame Preview V3 (white + sea blue)
-- Standalone UI preview; no farm, ESP, remote calls, or background loops.
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local parent = player:WaitForChild("PlayerGui")

-- Clean up only our earlier preview GUIs. Never remove game menus.
local oldNames = {
    "LexHubPreviewV1", "LexHubFramePreviewV2", "LexHubFrameWhiteBlueV3"
}
local roots = {parent}
pcall(function() table.insert(roots, game:GetService("CoreGui")) end)
pcall(function()
    if type(gethui) == "function" then
        local root = gethui()
        if root then table.insert(roots, root) end
    end
end)
for _, root in ipairs(roots) do
    for _, name in ipairs(oldNames) do
        local old = root:FindFirstChild(name)
        if old then pcall(function() old:Destroy() end) end
    end
end

local WHITE = Color3.fromRGB(250, 253, 255)
local SEA = Color3.fromRGB(30, 166, 234)
local DEEP = Color3.fromRGB(6, 20, 38)

local function create(className, properties, container)
    local instance = Instance.new(className)
    for key, value in pairs(properties) do
        instance[key] = value
    end
    instance.Parent = container
    return instance
end

-- Static alternating white/sea-blue colors; no render-step updates.
local alternating = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, WHITE),
    ColorSequenceKeypoint.new(0.24, WHITE),
    ColorSequenceKeypoint.new(0.25, SEA),
    ColorSequenceKeypoint.new(0.49, SEA),
    ColorSequenceKeypoint.new(0.50, WHITE),
    ColorSequenceKeypoint.new(0.74, WHITE),
    ColorSequenceKeypoint.new(0.75, SEA),
    ColorSequenceKeypoint.new(1.00, SEA),
})

local gui = create("ScreenGui", {
    Name = "LexHubFrameWhiteBlueV3",
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    DisplayOrder = 900,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, parent)

local frame = create("Frame", {
    Name = "LexHubWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    BorderSizePixel = 0,
    BackgroundColor3 = DEEP,
    BackgroundTransparency = 0.87,
    Active = false,
    ZIndex = 2,
}, gui)
create("UICorner", {CornerRadius = UDim.new(0, 7)}, frame)
local border = create("UIStroke", {
    Thickness = 1.65,
    Transparency = 0.18,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Color = WHITE,
}, frame)
create("UIGradient", {Color = alternating, Rotation = 0}, border)

-- Exact minimalist header concept: a thin title bar and one divider.
local headerBg = create("Frame", {
    Name = "TitleBar",
    Size = UDim2.new(1, 0, 0, 47),
    BackgroundColor3 = Color3.fromRGB(5, 18, 35),
    BackgroundTransparency = 0.64,
    BorderSizePixel = 0,
    ZIndex = 3,
}, frame)
create("UICorner", {CornerRadius = UDim.new(0, 7)}, headerBg)

local divider = create("Frame", {
    Name = "HeaderDivider",
    Size = UDim2.new(1, -2, 0, 2),
    Position = UDim2.new(0, 1, 0, 46),
    BorderSizePixel = 0,
    BackgroundColor3 = WHITE,
    BackgroundTransparency = 0.20,
    ZIndex = 5,
}, frame)
create("UIGradient", {Color = alternating}, divider)

local title = create("TextLabel", {
    Name = "PerfectlyCenteredLexHub",
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    RichText = true,
    Text = '<font color="#FFFFFF">Lex</font> <font color="#1EA6EA">Hub</font>',
    Font = Enum.Font.GothamBold,
    TextSize = 22,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center,
    TextStrokeColor3 = DEEP,
    TextStrokeTransparency = 0.60,
    Active = true,
    ZIndex = 6,
}, frame)

-- Empty workspace like Banana Hub's blank window screenshot.
local content = create("Frame", {
    Name = "EmptyContent",
    Position = UDim2.new(0, 6, 0, 50),
    Size = UDim2.new(1, -12, 1, -57),
    BorderSizePixel = 0,
    BackgroundTransparency = 1,
    Active = false,
    ZIndex = 3,
}, frame)

-- A SINGLE Lex badge, inside header when open; it floats only when hidden.
local logo = create("TextButton", {
    Name = "LexHubToggle",
    Text = "L",
    Font = Enum.Font.GothamBlack,
    TextSize = 25,
    TextColor3 = WHITE,
    TextStrokeColor3 = SEA,
    TextStrokeTransparency = 0.38,
    BackgroundColor3 = DEEP,
    BackgroundTransparency = 0.16,
    BorderSizePixel = 0,
    AutoButtonColor = true,
    ZIndex = 12,
}, gui)
create("UICorner", {CornerRadius = UDim.new(0, 8)}, logo)
local logoStroke = create("UIStroke", {
    Thickness = 2,
    Color = SEA,
    Transparency = 0.02,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, logo)
create("UIGradient", {Color = alternating, Rotation = 90}, logoStroke)

local opened = true
local viewport = Vector2.new(1280, 720)
local dimensions = Vector2.new(900, 550)
local center = Vector2.new(650, 380)
local initialized = false
local dragActive = false
local dragInput, startInput, startCenter

local function currentViewport()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or viewport
end

local function clampCenter(xy)
    local minX = dimensions.X * 0.5 + 3
    local minY = dimensions.Y * 0.5 + 3
    return Vector2.new(
        math.clamp(xy.X, minX, math.max(minX, viewport.X - minX)),
        math.clamp(xy.Y, minY, math.max(minY, viewport.Y - minY))
    )
end

local function layout()
    viewport = currentViewport()
    dimensions = Vector2.new(
        math.max(240, math.min(1100, viewport.X * 0.64)),
        math.max(160, math.min(650, viewport.Y * 0.82))
    )
    dimensions = Vector2.new(
        math.min(dimensions.X, viewport.X - 8),
        math.min(dimensions.Y, viewport.Y - 8)
    )
    if not initialized then
        center = Vector2.new(viewport.X * 0.52, viewport.Y * 0.547)
        initialized = true
    end
    center = clampCenter(center)
    frame.Size = UDim2.fromOffset(dimensions.X, dimensions.Y)
    frame.Position = UDim2.fromOffset(center.X, center.Y)

    local left = center.X - dimensions.X * 0.5
    local top = center.Y - dimensions.Y * 0.5
    local badge = math.clamp(math.floor(dimensions.Y * 0.057), 27, 37)
    logo.Size = UDim2.fromOffset(badge, badge)
    if opened then
        logo.Position = UDim2.fromOffset(left + 13, top + 7)
    else
        logo.Position = UDim2.fromOffset(15, 104)
    end
    title.TextSize = math.clamp(math.floor(dimensions.Y * 0.037), 16, 22)
    logo.TextSize = math.clamp(math.floor(badge * 0.72), 19, 26)
end

layout()
logo.Activated:Connect(function()
    opened = not opened
    frame.Visible = opened
    layout()
end)

-- Drag using touch or mouse; one connection only (no while loops).
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragActive = true
        dragInput = input
        startInput = input.Position
        startCenter = center
    end
end)

local moveConnection = UIS.InputChanged:Connect(function(input)
    if not dragActive or not startInput then return end
    if dragInput.UserInputType == Enum.UserInputType.Touch then
        if input ~= dragInput then return end
    elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
        return
    end
    local delta = input.Position - startInput
    center = clampCenter(startCenter + Vector2.new(delta.X, delta.Y))
    layout()
end)
local releaseConnection = UIS.InputEnded:Connect(function(input)
    if input == dragInput or (dragInput and dragInput.UserInputType == Enum.UserInputType.MouseButton1
        and input.UserInputType == Enum.UserInputType.MouseButton1) then
        dragActive = false
        dragInput = nil
    end
end)

local resizeConnection
local cam = workspace.CurrentCamera
if cam then
    resizeConnection = cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if gui.Parent then layout() end
    end)
end

gui.Destroying:Connect(function()
    moveConnection:Disconnect()
    releaseConnection:Disconnect()
    if resizeConnection then resizeConnection:Disconnect() end
end)

getgenv().LexHubFramePreview = {
    Gui = gui,
    Frame = frame,
    Content = content,
    Show = function()
        opened = true
        frame.Visible = true
        layout()
    end,
    Hide = function()
        opened = false
        frame.Visible = false
        layout()
    end,
    Destroy = function() gui:Destroy() end,
}
