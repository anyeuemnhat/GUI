-- Lex Hub / Purple UI. All controls are interface previews only.
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local Tweens = game:GetService("TweenService")

repeat task.wait() until Players.LocalPlayer
local player = Players.LocalPlayer

local ASSETS = {
    Logo = "92599590358566",
    Background = "102363221886944",
    Home = "132438576251581",
    Farm = "88690276794955",
    Combat = "71150385866756",
    Player = "134885357707164",
    Teleport = "125206121526268",
    Race = "81864304157736",
    Fruit = "120866804192405",
    Raid = "80890989765473",
    Sea = "132052609598784",
    Quests = "102414489086009",
    Misc = "72730351582941",
    Config = "102726470936133",
}

local DISCORD = "https://discord.gg/vuWaN9cPN"
local W, H, SIDE = 1280, 720, 226

local C = {
    base = Color3.fromRGB(22, 12, 39),
    panel = Color3.fromRGB(39, 22, 61),
    row = Color3.fromRGB(63, 35, 86),
    text = Color3.fromRGB(248, 239, 255),
    muted = Color3.fromRGB(210, 188, 229),
    accent = Color3.fromRGB(220, 139, 255),
    edge = Color3.fromRGB(166, 90, 206),
}

local parent = player:WaitForChild("PlayerGui")

if type(gethui) == "function" then
    local ok, hidden = pcall(gethui)
    if ok and typeof(hidden) == "Instance" then
        parent = hidden
    end
end

local old = parent:FindFirstChild("LexHubUI")
if old then old:Destroy() end

local function new(class, props, owner)
    local object = Instance.new(class)
    for key, value in pairs(props) do
        object[key] = value
    end
    object.Parent = owner
    return object
end

local function rounded(object, radius)
    new("UICorner", {
        CornerRadius = UDim.new(0, radius or 12),
    }, object)
end

local function stroke(object, color, thickness, transparency)
    return new("UIStroke", {
        Color = color or C.edge,
        Thickness = thickness or 1,
        Transparency = transparency or 0.25,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, object)
end

local function glow(object, radius)
    for _, layer in ipairs({
        {5, 0.94},
        {2.5, 0.82},
        {1, 0.12},
    }) do
        local outline = new("Frame", {
            Name = "GlowOutline",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            BorderSizePixel = 0,
        }, object)

        rounded(outline, radius or 16)
        stroke(outline, C.accent, layer[1], layer[2])
    end
end

local function text(owner, value, size, x, y, width, height, color, font)
    return new("TextLabel", {
        BackgroundTransparency = 1,
        Text = value,
        TextSize = size,
        Font = font or Enum.Font.Gotham,
        TextColor3 = color or C.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(width, height),
    }, owner)
end

local connections, glassTargets = {}, {}
local cameraConnection
local glassValue = 45

local function on(signal, callback)
    local connection = signal:Connect(callback)
    connections[#connections + 1] = connection
    return connection
end

local function glass(object, base, gain)
    glassTargets[#glassTargets + 1] = {object, base, gain}
    object.BackgroundTransparency = base + glassValue / 100 * gain
end

local function tween(object, props)
    Tweens:Create(
        object,
        TweenInfo.new(0.16, Enum.EasingStyle.Quad),
        props
    ):Play()
end

local gui = new("ScreenGui", {
    Name = "LexHubUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 1000,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, parent)

gui.Destroying:Connect(function()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    if cameraConnection then
        cameraConnection:Disconnect()
    end
end)

local window = new("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(W, H),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, gui)

local scale = new("UIScale", {Scale = 1}, window)

local backdrop = new("ImageLabel", {
    Name = "Background",
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Image = "rbxassetid://" .. ASSETS.Background,
    ImageTransparency = 0.60,
    ScaleType = Enum.ScaleType.Crop,
    ZIndex = 1,
}, window)
rounded(backdrop, 18)

local shade = new("Frame", {
    BackgroundColor3 = C.base,
    Size = UDim2.fromScale(1, 1),
    BorderSizePixel = 0,
    ZIndex = 2,
}, window)
rounded(shade, 18)
glass(shade, 0.08, 0.5)

local sidebar = new("Frame", {
    Size = UDim2.new(0, SIDE, 1, 0),
    BackgroundColor3 = C.base,
    BorderSizePixel = 0,
    ZIndex = 3,
}, window)
rounded(sidebar, 18)
glass(sidebar, 0.05, 0.4)
stroke(sidebar, C.accent, 1, 0.35)

new("ImageLabel", {
    Position = UDim2.fromOffset(15, 16),
    Size = UDim2.fromOffset(57, 57),
    BackgroundTransparency = 1,
    Image = "rbxassetid://" .. ASSETS.Logo,
    ScaleType = Enum.ScaleType.Fit,
}, sidebar)

text(
    sidebar, "Lex Hub", 34,
    82, 14, 134, 42,
    C.text, Enum.Font.Garamond
)
text(
    sidebar, "Blox Fruits Script", 12,
    83, 59, 135, 20, C.muted
)

new("Frame", {
    Position = UDim2.fromOffset(22, 91),
    Size = UDim2.fromOffset(182, 1),
    BackgroundColor3 = C.accent,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
}, sidebar)

local nav = new("ScrollingFrame", {
    Position = UDim2.fromOffset(17, 105),
    Size = UDim2.fromOffset(195, 510),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = C.accent,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, sidebar)

new("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, nav)

new("UIPadding", {
    PaddingTop = UDim.new(0, 3),
    PaddingBottom = UDim.new(0, 4),
    PaddingLeft = UDim.new(0, 3),
    PaddingRight = UDim.new(0, 4),
}, nav)

local username = text(
    sidebar, "@" .. player.Name, 13,
    20, 626, 185, 22, C.muted
)

on(player:GetPropertyChangedSignal("Name"), function()
    username.Text = "@" .. player.Name
end)

local discordButton = new("TextButton", {
    Position = UDim2.fromOffset(20, 665),
    Size = UDim2.fromOffset(186, 32),
    BackgroundColor3 = Color3.fromRGB(83, 39, 118),
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Text = "Discord  /  Copy invite",
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextColor3 = C.text,
    AutoButtonColor = true,
}, sidebar)
rounded(discordButton, 10)
stroke(discordButton, C.accent, 1, 0.2)

local banner = new("ImageLabel", {
    Position = UDim2.fromOffset(SIDE + 2, 0),
    Size = UDim2.new(1, -SIDE - 2, 0, 205),
    BackgroundTransparency = 1,
    Image = "rbxassetid://" .. ASSETS.Background,
    ScaleType = Enum.ScaleType.Crop,
    ZIndex = 3,
}, window)
rounded(banner, 16)

local fade = new("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.base,
    BorderSizePixel = 0,
}, banner)

new("UIGradient", {
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.65, 0.85),
        NumberSequenceKeypoint.new(1, 0),
    }),
}, fade)

local dragHandle = new("TextButton", {
    BackgroundTransparency = 1,
    Text = "",
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(1, -118, 1, 0),
    AutoButtonColor = false,
}, banner)

local controls = new("Frame", {
    Position = UDim2.new(1, -120, 0, 12),
    Size = UDim2.fromOffset(102, 34),
    BackgroundColor3 = C.base,
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    ZIndex = 5,
}, window)
rounded(controls, 17)
glow(controls, 17)

local function control(value, x)
    return new("TextButton", {
        Position = UDim2.fromOffset(x, 0),
        Size = UDim2.fromOffset(48, 34),
        BackgroundTransparency = 1,
        Text = value,
        TextSize = 24,
        Font = Enum.Font.Gotham,
        TextColor3 = C.text,
    }, controls)
end

local minimize = control("-", 2)
local close = control("x", 52)

local main = new("Frame", {
    Position = UDim2.fromOffset(SIDE + 12, 210),
    Size = UDim2.new(1, -SIDE - 24, 1, -242),
    BackgroundColor3 = C.base,
    BorderSizePixel = 0,
    ZIndex = 4,
}, window)
rounded(main, 22)
glass(main, 0.05, 0.45)
glow(main, 22)

local function icon(owner, id, fallback, x, y, size)
    local holder = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(size, size),
    }, owner)

    local glyph = text(
        holder, fallback, math.floor(size * 0.8),
        0, 0, size, size, C.text
    )
    glyph.TextXAlignment = Enum.TextXAlignment.Center

    local image = new("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Image = "rbxassetid://" .. id,
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
    }, holder)

    local function refresh()
        image.ImageTransparency = image.IsLoaded and 0 or 1
        glyph.Visible = not image.IsLoaded
    end

    on(image:GetPropertyChangedSignal("IsLoaded"), refresh)
    refresh()

    return holder, image, glyph
end

local titleIcon, titleImage, titleGlyph =
    icon(main, ASSETS.Quests, "≡", 34, 18, 56)

local title = text(
    main, "Quests", 47,
    112, 10, 650, 59,
    C.text, Enum.Font.Garamond
)
title.TextStrokeColor3 = C.accent
title.TextStrokeTransparency = 0.65

local subtitle = text(
    main, "Quản lý nhiệm vụ trong Blox Fruits", 15,
    114, 66, 850, 24, C.muted
)

text(main, "✿", 56, W - SIDE - 135, 13, 68, 70, C.accent)
text(main, "✦", 27, 18, -17, 34, 34, C.accent)
text(main, "✦", 25, W - SIDE - 87, H - 257, 34, 34, C.accent)

new("Frame", {
    Position = UDim2.fromOffset(112, 57),
    Size = UDim2.new(1, -180, 0, 1),
    BackgroundColor3 = C.accent,
    BackgroundTransparency = 0.45,
    BorderSizePixel = 0,
}, main)

local body = new("Frame", {
    Position = UDim2.fromOffset(18, 112),
    Size = UDim2.new(1, -36, 1, -132),
    BackgroundTransparency = 1,
}, main)

local tabs = {
    {"Home", "Home", "⌂", "Thông tin tài khoản và giao diện"},
    {"Farm", "Farm", "⚔", "Thiết lập giao diện farming"},
    {"Combat", "Combat", "⊕", "Thiết lập giao diện chiến đấu"},
    {"Player", "Player", "♟", "Thông tin người chơi Roblox hiện tại"},
    {"Teleport", "Teleport", "◎", "Danh sách Sea và địa điểm"},
    {"Race / V4", "Race", "Ψ", "Giao diện Race và V4"},
    {"Fruit", "Fruit", "●", "Giao diện quản lý trái"},
    {"Raid / Boss", "Raid", "☠", "Giao diện Raid và Boss"},
    {"Sea Event", "Sea", "♜", "Giao diện sự kiện trên biển"},
    {
        "Quests", "Quests", "≡",
        "Quản lý và tự động làm nhiệm vụ trong Blox Fruits",
    },
    {"Misc", "Misc", "◇", "Các thiết lập bổ sung"},
    {"Config", "Config", "⚙", "Tùy chỉnh giao diện Lex Hub"},
}

local pages, entries, state = {}, {}, {}
local selectTab

local function panel(owner, position, size)
    local frame = new("Frame", {
        Position = position,
        Size = size,
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
    }, owner)
    rounded(frame, 18)
    glass(frame, 0.12, 0.45)
    glow(frame, 18)
    return frame
end

local function list(owner)
    local frame = new("ScrollingFrame", {
        Position = UDim2.fromOffset(16, 58),
        Size = UDim2.new(1, -32, 1, -72),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = C.accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, owner)

    new("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, frame)

    new("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 3),
    }, frame)

    return frame
end

local function row(owner, height, clickable)
    local object = new(clickable and "TextButton" or "Frame", {
        Size = UDim2.new(1, -2, 0, height),
        LayoutOrder = #owner:GetChildren(),
        BackgroundColor3 = C.row,
        BorderSizePixel = 0,
    }, owner)

    if clickable then
        object.Text = ""
        object.AutoButtonColor = false
    end

    rounded(object, 13)
    stroke(object, C.edge, 1, 0.35)
    glass(object, 0.18, 0.4)

    return object
end

local function toggle(owner, page, name, description, assetKey, fallback)
    local button = row(owner, 68, true)

    icon(button, ASSETS[assetKey], fallback, 15, 18, 32)

    text(
        button, name, 18,
        63, 10, 350, 25,
        C.text, Enum.Font.GothamBold
    )
    text(button, description, 12, 64, 37, 350, 18, C.muted)

    local track = new("Frame", {
        Position = UDim2.new(1, -70, 0.5, -13),
        Size = UDim2.fromOffset(52, 26),
        BackgroundColor3 = Color3.fromRGB(103, 64, 133),
        BorderSizePixel = 0,
    }, button)
    rounded(track, 13)

    local knob = new("Frame", {
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(20, 20),
        BackgroundColor3 = Color3.fromRGB(237, 207, 255),
        BorderSizePixel = 0,
    }, track)
    rounded(knob, 10)

    local key = page .. "/" .. name
    state[key] = false

    on(button.Activated, function()
        state[key] = not state[key]

        tween(track, {
            BackgroundColor3 = state[key]
                and C.accent
                or Color3.fromRGB(103, 64, 133),
        })
        tween(knob, {
            Position = UDim2.fromOffset(state[key] and 29 or 3, 3),
        })
    end)
end

local function stat(owner, name, value)
    local card = row(owner, 45)
    text(card, name, 14, 14, 10, 230, 25, C.muted)

    return new("TextLabel", {
        Position = UDim2.new(0.58, 0, 0, 10),
        Size = UDim2.new(0.42, -14, 0, 25),
        BackgroundTransparency = 1,
        Text = tostring(value),
        TextSize = 14,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)
end

for index, tab in ipairs(tabs) do
    local name, key, glyph = tab[1], tab[2], tab[3]

    local button = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        LayoutOrder = index,
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromRGB(127, 44, 176),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, nav)
    rounded(button, 12)

    local outline = stroke(button, C.accent, 1, 0.8)
    icon(button, ASSETS[key], glyph, 14, 6, 25)

    local caption = text(
        button, name, 15,
        61, 7, 121, 23,
        C.text, Enum.Font.GothamBold
    )

    entries[name] = {
        button = button,
        outline = outline,
        caption = caption,
        key = key,
        glyph = glyph,
        description = tab[4],
    }

    on(button.Activated, function()
        selectTab(name)
    end)

    local page = new("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
    }, body)

    local left = panel(
        page, UDim2.new(),
        UDim2.new(0.59, -7, 1, 0)
    )
    local right = panel(
        page, UDim2.new(0.59, 7, 0, 0),
        UDim2.new(0.41, -7, 1, 0)
    )

    text(
        left,
        name == "Quests" and "♛  Quest Manager" or ("◇  " .. name),
        21, 21, 15, 520, 28,
        C.text, Enum.Font.GothamBold
    )
    text(
        right,
        name == "Quests" and "▥  Thông Tin Nhiệm Vụ" or "▥  Thông tin",
        19, 21, 15, 350, 28,
        C.text, Enum.Font.GothamBold
    )

    pages[name] = {
        frame = page,
        left = list(left),
        right = list(right),
    }
end

toggle(
    pages.Quests.left, "Quests", "Quest Tracker",
    "Theo dõi và hiển thị nhiệm vụ hiện tại", "Farm", "⚔"
)
toggle(
    pages.Quests.left, "Quests", "Boss Quest",
    "Tự động nhận và làm nhiệm vụ Boss", "Raid", "☠"
)
toggle(
    pages.Quests.left, "Quests", "Daily Quest",
    "Tự động hoàn thành nhiệm vụ hằng ngày", "Quests", "≡"
)

stat(pages.Quests.right, "Nhiệm vụ hiện tại", "--")
stat(pages.Quests.right, "Tiến độ", "0%")
stat(pages.Quests.right, "Loại nhiệm vụ", "--")
stat(pages.Quests.right, "Thời gian", "--")

stat(pages.Home.left, "Username", "@" .. player.Name)
stat(pages.Home.left, "User ID", player.UserId)
stat(pages.Home.left, "Place ID", game.PlaceId)
stat(pages.Home.right, "Phiên bản", "Lex Hub UI")
stat(pages.Home.right, "Trạng thái", "Preview")

stat(pages.Player.left, "Username", "@" .. player.Name)
stat(pages.Player.left, "User ID", player.UserId)
stat(pages.Player.right, "Tài khoản", "Roblox")

local samples = {
    Farm = {
        {"Auto Farm", "Tùy chọn giao diện farming"},
        {"Auto Quest", "Tùy chọn nhận nhiệm vụ"},
        {"Bring Mobs", "Tùy chọn gom mục tiêu"},
    },
    Combat = {
        {"Fast Attack", "Tùy chọn giao diện chiến đấu"},
        {"Auto Equip", "Tùy chọn chọn vũ khí"},
    },
    Teleport = {
        {"Sea 1", "Xem địa điểm tại Sea 1"},
        {"Sea 2", "Xem địa điểm tại Sea 2"},
        {"Sea 3", "Xem địa điểm tại Sea 3"},
    },
    ["Race / V4"] = {
        {"Race", "Giao diện Race"},
        {"V4", "Giao diện V4"},
    },
    Fruit = {
        {"Auto Store Fruit", "Tùy chọn lưu trái"},
        {"Fruit Tracker", "Tùy chọn hiển thị trái"},
    },
    ["Raid / Boss"] = {
        {"Raid", "Giao diện Raid"},
        {"Boss", "Giao diện Boss"},
    },
    ["Sea Event"] = {
        {"Sea Event", "Giao diện sự kiện biển"},
        {"Sea Beast", "Giao diện mục tiêu biển"},
    },
    Misc = {
        {"Misc Preview", "Các tùy chọn giao diện bổ sung"},
    },
}

for name, options in pairs(samples) do
    for _, item in ipairs(options) do
        toggle(
            pages[name].left, name, item[1], item[2],
            entries[name].key, entries[name].glyph
        )
    end

    stat(pages[name].right, "Trạng thái", "Preview")
    stat(pages[name].right, "Đã chọn", "--")
end

local function applyGlass(value)
    glassValue = math.clamp(value, 0, 90)

    for _, target in ipairs(glassTargets) do
        target[1].BackgroundTransparency =
            target[2] + glassValue / 100 * target[3]
    end

    backdrop.ImageTransparency = 0.35 + glassValue / 100 * 0.45

    for _, entry in pairs(entries) do
        if entry.outline.Transparency < 0.5 then
            entry.button.BackgroundTransparency =
                0.1 + glassValue / 100 * 0.35
        end
    end
end

local sliderRow = row(pages.Config.left, 90)

text(
    sliderRow, "Độ trong suốt", 17,
    17, 12, 350, 25,
    C.text, Enum.Font.GothamBold
)

local sliderValue = text(
    sliderRow, tostring(glassValue), 14,
    440, 12, 70, 25, C.muted
)

local hit = new("TextButton", {
    Position = UDim2.fromOffset(20, 46),
    Size = UDim2.new(1, -40, 0, 28),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
}, sliderRow)

local track = new("Frame", {
    Position = UDim2.new(0, 0, 0.5, -2),
    Size = UDim2.new(1, 0, 0, 4),
    BackgroundColor3 = Color3.fromRGB(99, 58, 128),
    BorderSizePixel = 0,
}, hit)
rounded(track, 2)

local fill = new("Frame", {
    Size = UDim2.new(glassValue / 90, 0, 1, 0),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
}, track)

local thumb = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(13, 13),
    Position = UDim2.fromScale(glassValue / 90, 0.5),
    BackgroundColor3 = C.text,
    BorderSizePixel = 0,
}, track)
rounded(thumb, 7)

local sliderInput

local function pointer(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function moved(input, held)
    return input == held
        or (
            held.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement
        )
end

local function released(input, held)
    return input == held
        or (
            held.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseButton1
        )
end

local function updateSlider(input)
    if track.AbsoluteSize.X <= 0 then return end

    local ratio = math.clamp(
        (input.Position.X - track.AbsolutePosition.X)
            / track.AbsoluteSize.X,
        0, 1
    )
    local value = math.floor(ratio * 90 + 0.5)

    fill.Size = UDim2.new(value / 90, 0, 1, 0)
    thumb.Position = UDim2.fromScale(value / 90, 0.5)
    sliderValue.Text = tostring(value)
    applyGlass(value)
end

on(hit.InputBegan, function(input)
    if pointer(input) then
        sliderInput = input
        updateSlider(input)
    end
end)

on(Input.InputChanged, function(input)
    if sliderInput and moved(input, sliderInput) then
        updateSlider(input)
    end
end)

on(Input.InputEnded, function(input)
    if sliderInput and released(input, sliderInput) then
        sliderInput = nil
    end
end)

on(Input.WindowFocusReleased, function()
    sliderInput = nil
end)

local inviteRow = row(pages.Config.left, 85)

text(
    inviteRow, "Discord Invite", 17,
    17, 10, 350, 25, C.text, Enum.Font.GothamBold
)

local inviteBox = new("TextBox", {
    Position = UDim2.fromOffset(17, 43),
    Size = UDim2.new(1, -34, 0, 28),
    BackgroundTransparency = 1,
    Text = DISCORD,
    ClearTextOnFocus = false,
    TextColor3 = C.accent,
    Font = Enum.Font.Gotham,
    TextSize = 14,
}, inviteRow)

on(inviteBox.FocusLost, function()
    inviteBox.Text = DISCORD
end)

stat(pages.Config.right, "Logo / nền", "Custom")
stat(pages.Config.right, "Giao diện", "Purple")

selectTab = function(name)
    for pageName, page in pairs(pages) do
        page.frame.Visible = pageName == name
    end

    for pageName, entry in pairs(entries) do
        local active = pageName == name

        entry.button.BackgroundTransparency =
            active and (0.1 + glassValue / 100 * 0.35) or 1

        entry.outline.Transparency = active and 0.05 or 0.8
        entry.outline.Thickness = active and 2 or 1
        entry.caption.TextColor3 = active and C.text or C.muted
    end

    title.Text = name
    subtitle.Text = entries[name].description
    titleGlyph.Text = entries[name].glyph
    titleImage.Image = "rbxassetid://" .. ASSETS[entries[name].key]
    titleImage.ImageTransparency = titleImage.IsLoaded and 0 or 1
    titleGlyph.Visible = not titleImage.IsLoaded
end

on(discordButton.Activated, function()
    local copy =
        type(setclipboard) == "function" and setclipboard
        or type(toclipboard) == "function" and toclipboard

    if copy then
        local ok, result = pcall(copy, DISCORD)

        if ok and result ~= false then
            discordButton.Text = "Invite copied!"

            task.delay(2, function()
                if discordButton.Parent then
                    discordButton.Text = "Discord  /  Copy invite"
                end
            end)
            return
        end
    end

    selectTab("Config")
    inviteBox:CaptureFocus()
    inviteBox.SelectionStart = 1
    inviteBox.CursorPosition = #DISCORD + 1
end)

local footer = text(
    window, "LEX HUB  •  GIAO DIỆN XEM TRƯỚC", 10,
    SIDE + 18, H - 23, 600, 17, C.muted
)
footer.ZIndex = 4

local dock = new("ImageButton", {
    Name = "OpenLexHub",
    Size = UDim2.fromOffset(50, 50),
    Image = "rbxassetid://" .. ASSETS.Logo,
    ScaleType = Enum.ScaleType.Fit,
    BackgroundColor3 = C.base,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    ZIndex = 30,
}, gui)

rounded(dock, 14)
glow(dock, 14)

local function viewport()
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function clampPosition(object, x, y)
    local view = viewport()
    local width = object == window and W * scale.Scale or 50
    local height = object == window and H * scale.Scale or 50
    local ax, ay = object.AnchorPoint.X, object.AnchorPoint.Y

    x = math.clamp(
        x,
        width * ax + 6,
        math.max(width * ax + 6, view.X - width * (1 - ax) - 6)
    )
    y = math.clamp(
        y,
        height * ay + 6,
        math.max(height * ay + 6, view.Y - height * (1 - ay) - 6)
    )

    object.Position = UDim2.fromOffset(x, y)
end

local placed = false

local function fit()
    local view = viewport()

    scale.Scale = math.max(
        0.1,
        math.min(1, (view.X - 20) / W, (view.Y - 20) / H)
    )

    if not placed then
        window.Position = UDim2.fromOffset(view.X / 2, view.Y / 2)
        dock.Position = UDim2.fromOffset(
            12, math.max(8, view.Y / 2 - 25)
        )
        placed = true
    end

    clampPosition(
        window, window.Position.X.Offset, window.Position.Y.Offset
    )
    clampPosition(
        dock, dock.Position.X.Offset, dock.Position.Y.Offset
    )
end

local function watchCamera()
    if cameraConnection then
        cameraConnection:Disconnect()
    end

    if workspace.CurrentCamera then
        cameraConnection = workspace.CurrentCamera
            :GetPropertyChangedSignal("ViewportSize")
            :Connect(fit)
    end

    fit()
end

on(workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)
watchCamera()

local function toggleWindow()
    window.Visible = not window.Visible
end

on(minimize.Activated, toggleWindow)
on(close.Activated, function() gui:Destroy() end)

on(Input.InputBegan, function(input, processed)
    if not processed
        and not Input:GetFocusedTextBox()
        and input.KeyCode == Enum.KeyCode.RightShift then
        toggleWindow()
    end
end)

local function draggable(object, handle, tap)
    local held, start, origin, dragged

    on(handle.InputBegan, function(input)
        if pointer(input) then
            held = input
            start = input.Position
            origin = object.Position
            dragged = false
        end
    end)

    on(Input.InputChanged, function(input)
        if not held or not moved(input, held) then return end

        local delta = input.Position - start
        if delta.Magnitude > 5 then dragged = true end

        if dragged then
            clampPosition(
                object,
                origin.X.Offset + delta.X,
                origin.Y.Offset + delta.Y
            )
        end
    end)

    on(Input.InputEnded, function(input)
        if held and released(input, held) then
            held = nil
            if tap and not dragged then tap() end
        end
    end)

    on(Input.WindowFocusReleased, function()
        held = nil
    end)
end

draggable(window, dragHandle)
draggable(dock, dock, toggleWindow)

applyGlass(glassValue)
selectTab("Quests")

print("[Lex Hub] Purple UI ready.")