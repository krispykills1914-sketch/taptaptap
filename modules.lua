local Modules = {
    { name = "library", source = [=[local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local TextService = cloneref(game:GetService("TextService"))
local RunService = cloneref(game:GetService("RunService"))
local GuiService = cloneref(game:GetService("GuiService"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local GuiParent = game:GetService("CoreGui")

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local Config = {
    Folder = "tapology",
    FontFolder = "tapology/fonts",
    GameFolder = "phantom forces",
    MenuKey = Enum.KeyCode.RightControl,
    Logo = "rbxassetid://101443361081291",
    SplashTime = 3,
    AutoloadTimeout = 10,
    FontName = "ProggyClean",
    FontUrl = "https://raw.githubusercontent.com/bluescan/proggyfonts/master/ProggyOriginal/ProggyClean.ttf",
    TextSize = 12,
    Bold = true,
    BoldStrength = 0.4,
    Spacing = 6,
    TabTween = 0.25,
    ToggleTween = 0.22,
    HoverLighten = 0.06,
    Indent = 12,

    Border = {
        { "Shadow", 1 },
        { "Outline", 4 },
        { "Shadow", 1 },
    },
    Theme = {
        TextOutline = rgb(0, 0, 0),
        Shadow = rgb(8, 8, 10),
        Highlight = rgb(54, 54, 60),
        Background = rgb(36, 36, 38),
        Inline = rgb(24, 24, 26),
        Outline = rgb(56, 56, 60),
        Accent = rgb(108, 147, 255),
        Text = rgb(230, 230, 232),
        SubText = rgb(130, 130, 136),
    },
}

local env = getgenv and getgenv() or _G

do
    local prev = getgenv()._TapologyServer
    if type(prev) == "table" and type(prev.Stop) == "function" then
        pcall(prev.Stop)
    end
end

getgenv()._TapologyMenuGen = (tonumber(getgenv()._TapologyMenuGen) or 0) + 1
if type(env.Tapology) == "table" and type(env.Tapology.Unload) == "function" then
    pcall(env.Tapology.Unload)
else
    env.Tapology = nil
end
if type(env.Library) == "table" and type(env.Library.Unload) == "function" then
    pcall(env.Library.Unload)
else
    env.Library = nil
end

if type(env.UI) == "table" and type(env.UI.Unload) == "function" then
    pcall(env.UI.Unload)
end

do
    local parents = { GuiParent }
    local lp = Players.LocalPlayer
    if lp then
        local pg = lp:FindFirstChildOfClass("PlayerGui")
        if pg then
            parents[#parents + 1] = pg
        end
    end
    if typeof(gethui) == "function" then
        local okHui, host = pcall(gethui)
        if okHui and typeof(host) == "Instance" then
            parents[#parents + 1] = host
        end
    end
    for _, parent in parents do
        if typeof(parent) == "Instance" then
            for _, child in parent:GetChildren() do
                if child.Name == "Tapology" and child:IsA("ScreenGui") then
                    pcall(child.Destroy, child)
                end
            end
        end
    end
end

local LocalPlayer = Players.LocalPlayer
local Connections = {}
local Themed = {}

local UI = { Config = Config, Refreshers = {}, Hotkeys = {} }

local function create(className, props)
    props = props or {}
    local instance = Instance.new(className)
    local parent = props.Parent
    for key, value in props do
        if key ~= "Parent" then
            instance[key] = value
        end
    end
    if parent ~= nil then
        local ok = pcall(function()
            instance.Parent = parent
        end)
        if not ok or instance.Parent == nil then
            pcall(function()
                instance.Parent = GuiParent
            end)
        end
    end
    return instance
end

local function theme(instance, property, slot)
    instance[property] = Config.Theme[slot]
    table.insert(Themed, { instance, property, slot })
    return instance
end

local function heartbeatUntil(step, done)
    local elapsed, connection = 0, nil
    connection = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if not step(elapsed) then
            connection:Disconnect()
            if done then
                done()
            end
        end
    end)
    table.insert(Connections, connection)
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

local function loadFont()
    for _, folder in { Config.Folder, Config.FontFolder } do
        if not isfolder(folder) then
            makefolder(folder)
        end
    end
    local fontPath = `{Config.FontFolder}/{Config.FontName}.ttf`
    local familyPath = `{Config.FontFolder}/{Config.FontName}.json`
    if not isfile(fontPath) then
        writefile(fontPath, game:HttpGet(Config.FontUrl))
    end
    writefile(familyPath, cloneref(game:GetService("HttpService")):JSONEncode({
        name = Config.FontName,
        faces = {
            { name = "Regular", weight = 400, style = "normal", assetId = getcustomasset(fontPath) },
        },
    }))
    return Font.new(getcustomasset(familyPath), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end

local ok, font = pcall(loadFont)
if not ok then
    warn(`[UI] couldn't load {Config.FontName}, falling back to Code: {font}`)
    font = Font.fromEnum(Enum.Font.Code)
end
UI.Font = font

local Mirrored = { "Text", "TextColor3", "TextTransparency", "TextXAlignment", "TextYAlignment", "TextSize", "FontFace", "TextWrapped" }

function UI.Label(parent, text, props, options)
    options = options or {}
    local slot, outline = options.Slot, options.Outline
    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = UI.Font,
        TextSize = Config.TextSize,
        Text = (type(text) == "string" and text) or "",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 0, Config.TextSize + 4),
        Parent = parent,
    })
    theme(label, "TextColor3", slot or "Text")
    for key, value in props or {} do
        label[key] = value
    end

    local layers, strokes = {}, {}
    local offsets = (options.Bold and Config.Bold) and { 1 } or {}
    if outline then
        local stroke = create("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = label })
        theme(stroke, "Color", "TextOutline")
        table.insert(strokes, stroke)
        for _, x in offsets do
            table.insert(layers, { X = x, Stroke = true })
        end
        table.insert(layers, { X = 0 })
    end
    for _, x in offsets do
        table.insert(layers, { X = x, Soft = true })
    end
    local copies = {}
    for i, layer in layers do
        local copy = create("TextLabel", {
            Name = "Layer",
            BackgroundTransparency = 1,
            Text = "",
            Position = UDim2.fromOffset(layer.X, 0),
            Size = UDim2.fromScale(1, 1),
            ZIndex = label.ZIndex + i,
            Parent = label,
        })
        if layer.Stroke then
            local stroke = create("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = copy })
            theme(stroke, "Color", "TextOutline")
            table.insert(strokes, stroke)
        end
        table.insert(copies, { Label = copy, Soft = layer.Soft })
    end
    local function fadeStrokes()
        for _, stroke in strokes do
            stroke.Transparency = label.TextTransparency
        end
    end
    fadeStrokes()
    connect(label:GetPropertyChangedSignal("TextTransparency"), fadeStrokes)
    for _, property in Mirrored do
        local function sync()
            for _, copy in copies do
                local value = label[property]
                if copy.Soft and property == "TextTransparency" then
                    value = 1 - (1 - value) * Config.BoldStrength
                end
                copy.Label[property] = value
            end
        end
        sync()
        connect(label:GetPropertyChangedSignal(property), sync)
    end
    return label
end

local dragJobs = {}
local dragBound = false
local dragCount = 0
UI.Dragging = false
local function setDragging(on)
    if on then
        dragCount += 1
    else
        dragCount = math.max(dragCount - 1, 0)
    end
    UI.Dragging = dragCount > 0
end
local function bindDrag()
    if dragBound then
        return
    end
    dragBound = true
    connect(RunService.Heartbeat, function()
        if dragCount <= 0 then
            return
        end
        for frame, job in dragJobs do
            local pending = job.pending
            if job.dragging and pending and job.startMouse and job.startPosition then
                job.pending = nil
                local delta = pending - job.startMouse
                if delta.X ~= 0 or delta.Y ~= 0 then
                    local pos = job.startPosition
                    frame.Position = UDim2.new(pos.X.Scale, pos.X.Offset + delta.X, pos.Y.Scale, pos.Y.Offset + delta.Y)
                end
            end
        end
    end)
end

function UI.Draggable(frame, handle)
    handle = handle or frame
    if handle:IsA("GuiObject") then
        handle.Active = true
    end
    local job = dragJobs[frame]
    if not job then
        job = { dragging = false, armed = false }
        dragJobs[frame] = job
        bindDrag()
    end
    local function apply()
        local pending = job.pending
        if job.dragging and pending and job.startMouse and job.startPosition then
            job.pending = nil
            local delta = pending - job.startMouse
            local pos = job.startPosition
            frame.Position = UDim2.new(pos.X.Scale, pos.X.Offset + delta.X, pos.Y.Scale, pos.Y.Offset + delta.Y)
        end
    end
    local function arm(input)
        if job.dragging or job.armed then
            return
        end
        job.armed = true
        job.dragging = false
        job.startMouse = input.Position
        job.startPosition = frame.Position
        job.pending = nil
    end
    local function release()
        if job.dragging then
            apply()
            job.dragging = false
            setDragging(false)
        end
        job.armed = false
        job.pending = nil
    end
    connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            arm(input)
        end
    end)
    if not job.globalBound then
        job.globalBound = true
        connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                release()
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if not (job.armed or job.dragging) then
                return
            end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            local delta = input.Position - job.startMouse
            if not job.dragging then
                if math.abs(delta.X) < 3 and math.abs(delta.Y) < 3 then
                    return
                end
                job.dragging = true
                setDragging(true)
            end
            job.pending = input.Position
        end)
    end
end

function UI.WindowDraggable(frame)
    if frame:IsA("GuiObject") then
        frame.Active = true
    end
    local job = dragJobs[frame]
    if not job then
        job = { dragging = false, armed = false }
        dragJobs[frame] = job
        bindDrag()
    end
    if job.windowBound then
        return
    end
    job.windowBound = true
    local function inside(pos)
        local p, s = frame.AbsolutePosition, frame.AbsoluteSize
        return pos.X >= p.X and pos.Y >= p.Y and pos.X <= p.X + s.X and pos.Y <= p.Y + s.Y
    end
    local function overGroupbox(pos)
        if not UI.Gui then
            return false
        end
        local objects = UI.Gui:GetGuiObjectsAtPosition(pos.X, pos.Y)
        for _, object in objects do
            local node = object
            while node and node ~= frame do
                if node:GetAttribute("TapologyGroupbox") then
                    return true
                end
                node = node.Parent
            end
        end
        return false
    end
    local function topIsOurs(pos)
        if not UI.Gui then
            return false
        end
        local objects = UI.Gui:GetGuiObjectsAtPosition(pos.X, pos.Y)
        for _, object in objects do
            if object:IsA("TextBox") then
                return false
            end
            if object:IsDescendantOf(frame) or object == frame then
                return true
            end
        end
        return false
    end
    connect(UserInputService.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        if UI.Gui and UI.Gui.Enabled == false then
            return
        end
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        if not inside(pos) or not topIsOurs(pos) or overGroupbox(pos) then
            return
        end
        if job.dragging or job.armed then
            return
        end
        job.armed = true
        job.dragging = false
        job.startMouse = input.Position
        job.startPosition = frame.Position
        job.pending = nil
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        if job.dragging then
            local pending = job.pending
            if pending and job.startMouse and job.startPosition then
                local delta = pending - job.startMouse
                local pos = job.startPosition
                frame.Position = UDim2.new(pos.X.Scale, pos.X.Offset + delta.X, pos.Y.Scale, pos.Y.Offset + delta.Y)
            end
            job.dragging = false
            setDragging(false)
        end
        job.armed = false
        job.pending = nil
    end)
    connect(UserInputService.InputChanged, function(input)
        if not (job.armed or job.dragging) then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local delta = input.Position - job.startMouse
        if not job.dragging then
            if math.abs(delta.X) < 3 and math.abs(delta.Y) < 3 then
                return
            end
            job.dragging = true
            setDragging(true)
        end
        job.pending = input.Position
    end)
end

local function outlined(instance, slot)
    theme(create("UIStroke", {
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = instance,
    }), "Color", slot or "Outline")
    return instance
end

local function shade(instance, top, bottom)
    create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(top, top, top), Color3.new(bottom, bottom, bottom)), Parent = instance })
    return instance
end

local SHADOW_IMAGE = "rbxassetid://6014261993"
local SHADOW_SLICE = Rect.new(49, 49, 450, 450)

local function attachExternalShadow(target, host, options)
    options = options or {}
    if not (target and host) then
        return
    end

    host = UI.Gui or host
    local pad = math.max(8, tonumber(options.ShadowPad) or 28)
    local transparency = tonumber(options.ShadowTransparency)
    if transparency == nil then
        transparency = 0.42
    end
    local shadowId = "ExternalDropShadow_" .. tostring(target):gsub("%W", "")
    local existing = host:FindFirstChild(shadowId)
    if existing then
        existing:Destroy()
    end
    local z = math.max((tonumber(target.ZIndex) or 1) - 1, 0)
    local root = create("Frame", {
        Name = shadowId,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = z,
        Parent = host,
    })
    local blur = create("ImageLabel", {
        Name = "Blur",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 0,
        Image = SHADOW_IMAGE,
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = transparency,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = SHADOW_SLICE,
        Parent = root,
    })

    local soft = create("ImageLabel", {
        Name = "Soft",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 0,
        Image = SHADOW_IMAGE,
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = math.clamp(transparency + 0.22, 0, 1),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = SHADOW_SLICE,
        Parent = root,
    })

    local cutout = create("Frame", {
        Name = "Cutout",
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0,
        ZIndex = 1,
        Parent = root,
    })
    local function sync()
        if not (target.Parent and root.Parent) then
            return
        end
        local hostPos = host.AbsolutePosition
        local pos = target.AbsolutePosition
        local size = target.AbsoluteSize
        if size.X <= 0 or size.Y <= 0 then
            root.Visible = false
            return
        end
        root.Visible = target.Visible

        root.Position = UDim2.fromOffset((pos.X - hostPos.X) - pad, (pos.Y - hostPos.Y) - pad)
        root.Size = UDim2.fromOffset(size.X + pad * 2, size.Y + pad * 2)
        soft.Position = UDim2.fromOffset(-math.floor(pad * 0.2), -math.floor(pad * 0.15))
        soft.Size = UDim2.new(1, math.floor(pad * 0.4), 1, math.floor(pad * 0.4))
        cutout.Position = UDim2.fromOffset(pad, pad)
        cutout.Size = UDim2.fromOffset(size.X, size.Y)

        cutout.BackgroundColor3 = target.BackgroundColor3
        cutout.BackgroundTransparency = target.BackgroundTransparency
        blur.ImageTransparency = transparency
        soft.ImageTransparency = math.clamp(transparency + 0.22, 0, 1)
        root.ZIndex = math.max((tonumber(target.ZIndex) or 1) - 1, 0)
    end
    connect(target:GetPropertyChangedSignal("AbsoluteSize"), sync)
    connect(target:GetPropertyChangedSignal("AbsolutePosition"), sync)
    connect(target:GetPropertyChangedSignal("Visible"), sync)
    connect(target:GetPropertyChangedSignal("BackgroundColor3"), sync)
    connect(target:GetPropertyChangedSignal("BackgroundTransparency"), sync)
    connect(target:GetPropertyChangedSignal("ZIndex"), sync)
    connect(host:GetPropertyChangedSignal("AbsolutePosition"), sync)
    connect(target.AncestryChanged, function(_, parent)
        if not parent and root.Parent then
            root:Destroy()
        end
    end)
    task.defer(sync)
    return root
end

local function polishOverlay(frame, options)
    options = options or {}
    if not frame or frame:GetAttribute("TapologyPolished") then
        return frame
    end
    frame:SetAttribute("TapologyPolished", true)
    local z = frame.ZIndex or 1
    if options.Shadow == true and UI.Gui then
        attachExternalShadow(frame, UI.Gui, {
            ShadowPad = options.ShadowPad or 28,
            ShadowTransparency = options.ShadowTransparency or 0.42,
        })
    end

    if options.Gloss == true then
        local gloss = create("Frame", {
            Name = "Gloss",
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 22),
            Position = UDim2.fromOffset(0, 0),
            ZIndex = z + 3,
            Parent = frame,
        })
        create("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 225, 235)),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.86),
                NumberSequenceKeypoint.new(0.45, 0.94),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Parent = gloss,
        })
        local sheen = create("Frame", {
            Name = "Sheen",
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.fromOffset(0, 1),
            ZIndex = z + 4,
            Parent = frame,
        })
        create("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.2, 0.78),
                NumberSequenceKeypoint.new(0.5, 0.62),
                NumberSequenceKeypoint.new(0.8, 0.78),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Parent = sheen,
        })
    end
    return frame
end
UI.PolishOverlay = polishOverlay

local function inset(instance)
    outlined(instance, "Shadow")
    outlined(create("Frame", {
        Name = "Rim",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 3,
        Parent = instance,
    }), "Highlight")
    for _, edge in { { Size = UDim2.new(1, 0, 0, 10), Rotation = 90 }, { Size = UDim2.new(0, 8, 1, 0), Rotation = 0 } } do
        local shadow = create("Frame", {
            Name = "InnerShadow",
            Size = edge.Size,
            BorderSizePixel = 0,
            ZIndex = 0,
            Parent = instance,
        })
        theme(shadow, "BackgroundColor3", "Shadow")
        create("UIGradient", {
            Rotation = edge.Rotation,
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) }),
            Parent = shadow,
        })
    end
    return shade(instance, 0.6, 1)
end

local Container = {}
Container.__index = Container

local function container(frame)
    return setmetatable({ Frame = frame }, Container)
end

function Container:Toggle(text, default, callback, options)
    return UI.Toggle(self.Frame, text, default, callback, options)
end
function Container:Slider(text, options, callback)
    return UI.Slider(self.Frame, text, options, callback)
end
function Container:ColorPicker(text, default, callback, options)
    return UI.ColorPicker(self.Frame, text, default, callback, options)
end
function Container:AlphaColorPicker(text, default, alpha, callback, options)
    return UI.AlphaColorPicker(self.Frame, text, default, alpha, callback, options)
end
function Container:Dropdown(text, options, callback)
    return UI.Dropdown(self.Frame, text, options, callback)
end
function Container:List(text, options, callback)
    return UI.List(self.Frame, text, options, callback)
end
function Container:Textbox(text, options, callback)
    return UI.Textbox(self.Frame, text, options, callback)
end
function Container:Button(text, callback)
    return UI.Button(self.Frame, text, callback)
end
function Container:Keybind(text, default, onPress)
    return UI.KeybindRow(self.Frame, text, default, onPress)
end
function Container:Label(text)
    return UI.Label(self.Frame, text, { LayoutOrder = #self.Frame:GetChildren() * 10 }, { Slot = "SubText", Outline = true })
end

UI.Flags = {}
UI.LastRegistered = os.clock()
local function register(parent, text, options, get, set)
    UI.LastRegistered = os.clock()
    if options and options.Save == false then return end
    local base = options and options.Flag or `{parent:GetAttribute("Path") or "ui"}/{text}`
    local flag, n = base, 1
    while UI.Flags[flag] do
        n += 1
        flag = `{base} #{n}`
    end
    UI.Flags[flag] = { Get = get, Set = set }
    return flag
end

local function encodeUDim2(value)
    return { value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset }
end
local function decodeUDim2(data)
    return UDim2.new(data[1], data[2], data[3], data[4])
end

local function registerPosition(flag, frame)
    UI.Flags[flag] = {
        Get = function()
            return encodeUDim2(frame.Position)
        end,
        Set = function(data)
            frame.Position = decodeUDim2(data)
        end,
    }
end

local function addBorder(frame)
    local offset = 0
    for i, ring in Config.Border do
        local holder = create("Frame", {
            Name = "Border" .. i,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(-offset, -offset),
            Size = UDim2.new(1, offset * 2, 1, offset * 2),
            Parent = frame,
        })
        theme(create("UIStroke", {
            Thickness = ring[2],
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            LineJoinMode = Enum.LineJoinMode.Miter,
            Parent = holder,
        }), "Color", ring[1])
        offset += ring[2]
    end
end

local layoutOrders = setmetatable({}, { __mode = "k" })
local function nextOrder(parent)
    local ok, count = pcall(function()
        return #parent:GetChildren()
    end)
    if ok and type(count) == "number" then
        layoutOrders[parent] = count
        return count * 10
    end
    local n = (layoutOrders[parent] or 0) + 1
    layoutOrders[parent] = n
    return n * 10
end

local function row(parent, name, height)
    local rowName = (type(name) == "string" and name ~= "") and name or "Row"
    return create("TextButton", {
        Name = rowName,
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height or Config.TextSize + 4),
        LayoutOrder = nextOrder(parent),
        Parent = parent,
    })
end

local ToggleBox = Config.TextSize - 1
local RowGap = 4

local function visualBottom(gui)
    local bottom = gui:GetAttribute("Bottom")
    return gui.AbsolutePosition.Y + (bottom or gui.AbsoluteSize.Y)
end

local function childSection(anchor)
    local frame = create("Frame", {
        Name = anchor.Name .. " children",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = anchor.LayoutOrder + 1,
        Visible = false,
        Parent = anchor.Parent,
    })
    local guide = create("Frame", {
        Name = "Guide",
        Position = UDim2.fromOffset(1 + math.floor(ToggleBox / 2), 0),
        Size = UDim2.new(0, 1, 1, 0),
        BorderSizePixel = 0,
        Parent = frame,
    })
    theme(guide, "BackgroundColor3", "Outline")
    local list = create("Frame", {
        Name = "List",
        Position = UDim2.fromOffset(Config.Indent, 0),
        Size = UDim2.new(1, -Config.Indent, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = frame,
    })
    create("UIListLayout", { Padding = UDim.new(0, RowGap), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
    list:SetAttribute("Path", anchor.Parent:GetAttribute("Path"))

    local function fit()
        local last
        for _, child in list:GetChildren() do
            if child:IsA("GuiObject") and child.Visible and (not last or child.LayoutOrder >= last.LayoutOrder) then
                last = child
            end
        end
        local length = last and math.max(visualBottom(last) - frame.AbsolutePosition.Y, 0) or 0
        guide.Size = UDim2.fromOffset(1, length)

        frame:SetAttribute("Bottom", length)
    end
    connect(list:GetPropertyChangedSignal("AbsoluteSize"), fit)
    connect(list.ChildAdded, function()
        task.defer(fit)
    end)

    local section = container(list)
    section.Section = frame
    return section
end

local function textWidth(text)
    local params = Instance.new("GetTextBoundsParams")
    params.Text, params.Font, params.Size, params.Width = text, UI.Font, Config.TextSize, 1000
    local ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
    return ok and bounds.X or #text * 7
end

local CharWidth
local function charWidth()
    CharWidth = CharWidth or textWidth("m")
    return CharWidth
end

local function fitText(text, width)
    local fits = math.floor(width / charWidth())
    if width <= 0 or #text <= fits then
        return text
    end
    return text:sub(1, math.max(fits - 3, 0)) .. "..."
end

local function lighten(color, amount)
    return color:Lerp(Color3.new(1, 1, 1), amount or Config.HoverLighten)
end

local function fillGradient(instance)
    create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.45, 0.45, 0.5)),
        Parent = instance,
    })
end

local function inside(gui, point)
    local position, size = gui.AbsolutePosition, gui.AbsoluteSize
    return point.X >= position.X and point.X <= position.X + size.X and point.Y >= position.Y and point.Y <= position.Y + size.Y
end

local function isClick(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function dragArea(surface, onMove)
    local held = false
    connect(surface.InputBegan, function(input)
        if isClick(input) then
            held = true
            onMove(input.Position)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if isClick(input) then
            held = false
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if held and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            onMove(input.Position)
        end
    end)
end

local Popup = { Open = nil }
local function popupFrame(name, opener)
    local frame = create("Frame", { Name = name, BorderSizePixel = 0, Visible = false, ZIndex = 20, Parent = UI.Gui })
    theme(frame, "BackgroundColor3", "Background")
    outlined(frame, "Shadow")
    shade(frame, 1.08, 0.88)
    polishOverlay(frame, { Shadow = true, ShadowPad = 26, ShadowTransparency = 0.4, Gloss = false })
    connect(UserInputService.InputBegan, function(input)
        if frame.Visible and isClick(input) and not inside(frame, input.Position) and not inside(opener, input.Position) then
            frame.Visible = false
        end
    end)
    return frame
end

local function openPopup(frame, opener, x, y)
    if Popup.Open and Popup.Open ~= frame then
        Popup.Open.Visible = false
    end

    local inset = GuiService:GetGuiInset()
    frame.Position = UDim2.fromOffset(opener.AbsolutePosition.X + inset.X + x, opener.AbsolutePosition.Y + inset.Y + y)
    frame.Visible = true
    Popup.Open = frame
end

function UI.Groupbox(column, title, path)
    local titleHeight = Config.TextSize + 8
    local box = create("Frame", {
        Name = title,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(column),
        Parent = column,
    })
    theme(box, "BackgroundColor3", "Background")
    box:SetAttribute("TapologyGroupbox", true)
    outlined(box, "Shadow")
    outlined(create("Frame", {
        Name = "Rim",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 3,
        Parent = box,
    }), "Highlight")
    shade(box, 1.08, 0.88)

    local titleLabel = UI.Label(box, title, {
        Position = UDim2.fromOffset(Config.Spacing + 2, 0),
        Size = UDim2.new(1, -(Config.Spacing + 2) * 2, 0, titleHeight),
    }, { Outline = true, Bold = true })
    theme(create("Frame", {
        Name = "Separator",
        Position = UDim2.fromOffset(Config.Spacing, titleHeight),
        Size = UDim2.new(1, -Config.Spacing * 2, 0, 1),
        BorderSizePixel = 0,
        Parent = box,
    }), "BackgroundColor3", "Outline")

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(0, titleHeight + 1),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = box,
    })
    create("UIPadding", {
        PaddingLeft = UDim.new(0, Config.Spacing),
        PaddingRight = UDim.new(0, Config.Spacing),
        PaddingTop = UDim.new(0, Config.Spacing),
        PaddingBottom = UDim.new(0, Config.Spacing),
        Parent = content,
    })
    create("UIListLayout", { Padding = UDim.new(0, RowGap), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
    path = path or title
    content:SetAttribute("Path", path)

    local group = container(content)
    group.Box, group.Title, group.Subtabs = box, title, {}

    local header
    local function paintSubtabs()
        for _, tab in group.Subtabs do
            local selected = tab == group.Selected
            tab.Label.TextColor3 = Config.Theme[selected and "Accent" or (tab.Hovered and "Text" or "SubText")]
            tab.Frame.Visible = selected
        end
    end
    function group:Subtab(name)
        if not header then
            titleLabel.Visible = false
            header = create("Frame", {
                Name = "Subtabs",
                Position = UDim2.fromOffset(Config.Spacing + 2, 0),
                Size = UDim2.new(1, -(Config.Spacing + 2) * 2, 0, titleHeight),
                BackgroundTransparency = 1,
                Parent = box,
            })
            create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = header })
            table.insert(UI.Refreshers, paintSubtabs)
        end
        local button = create("TextButton", {
            Name = name,
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            LayoutOrder = #group.Subtabs + 1,
            Parent = header,
        })
        local frame = create("Frame", {
            Name = name,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = #group.Subtabs + 1,
            Visible = false,
            Parent = content,
        })
        frame:SetAttribute("Path", `{path}/{name}`)
        create("UIListLayout", { Padding = UDim.new(0, RowGap), SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })
        local tab = {
            Name = name,
            Button = button,
            Frame = frame,
            Label = UI.Label(button, name, { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X }, { Slot = "SubText", Outline = true, Bold = true }),
        }
        table.insert(group.Subtabs, tab)
        group.Selected = group.Selected or tab
        connect(button.MouseButton1Click, function()
            group.Selected = tab
            paintSubtabs()
        end)
        connect(button.MouseEnter, function()
            tab.Hovered = true
            paintSubtabs()
        end)
        connect(button.MouseLeave, function()
            tab.Hovered = false
            paintSubtabs()
        end)
        paintSubtabs()
        local sub = container(frame)
        sub.Tab = tab
        return sub
    end
    return group
end

function UI.Toggle(parent, text, default, callback, options)
    local size = ToggleBox
    local rowHeight = Config.TextSize + 4
    local boxTop = math.floor((rowHeight - size) / 2)
    local line = row(parent, text, rowHeight)
    line:SetAttribute("Bottom", boxTop + size + 1)
    local box = create("Frame", {
        Name = "Box",
        Position = UDim2.fromOffset(1, boxTop),
        Size = UDim2.fromOffset(size, size),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = line,
    })
    shade(box, 0.6, 1)
    outlined(box, "Shadow")
    local fill = create("Frame", {
        Name = "Fill",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.fromScale(1, 0),
        BorderSizePixel = 0,
        Parent = box,
    })
    fillGradient(fill)
    local label = UI.Label(line, text, {
        Position = UDim2.fromOffset(size + 8, 0),
        Size = UDim2.new(1, -(size + 8), 1, 0),
    }, { Slot = "SubText", Outline = true })

    local toggle = { Value = false, Row = line, Sections = {} }
    local hovered = false
    local function paint(instant)
        local info = TweenInfo.new(instant and 0 or Config.ToggleTween, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenService:Create(fill, info, { Size = UDim2.fromScale(1, toggle.Value and 1 or 0) }):Play()
        TweenService:Create(label, info, { TextColor3 = Config.Theme[toggle.Value and "Text" or "SubText"] }):Play()
        box.BackgroundColor3 = hovered and lighten(Config.Theme.Inline) or Config.Theme.Inline
        fill.BackgroundColor3 = hovered and lighten(Config.Theme.Accent) or Config.Theme.Accent
        for _, section in toggle.Sections do
            section.Section.Visible = toggle.Value
        end
    end
    table.insert(UI.Refreshers, function()
        paint(true)
    end)

    function toggle:Set(value, instant)
        value = value and true or false
        local changed = value ~= toggle.Value
        toggle.Value = value
        paint(instant)
        if changed and callback then
            task.spawn(callback, value)
        end
    end

    function toggle:ColorPicker(color, onChange, swatchOptions)
        return UI.Swatch(line, color, onChange, swatchOptions)
    end
    function toggle:AlphaColorPicker(color, alpha, onChange, swatchOptions)
        return UI.AlphaSwatch(line, color, alpha, onChange, swatchOptions)
    end

    function toggle:Keybind(key, onPress)
        toggle.Bind = UI.Keybind(line, key, function()
            toggle:Set(not toggle.Value)
            if onPress then
                onPress(toggle.Value)
            end
        end)

        local path = parent:GetAttribute("Path") or ""
        table.insert(UI.Hotkeys, {
            Name = text == "enabled" and (path:match("([^/]+)$") or text) or text,
            Bind = toggle.Bind,
            Toggle = toggle,
        })
        return toggle.Bind
    end

    function toggle:Settings(title)
        return UI.ConfigWindow(line, title or text)
    end

    function toggle:Children()
        local section = childSection(line)
        table.insert(toggle.Sections, section)
        section.Section.Visible = toggle.Value
        return section
    end

    connect(line.MouseButton1Click, function()
        toggle:Set(not toggle.Value)
    end)
    connect(line.MouseEnter, function()
        hovered = true
        paint(true)
    end)
    connect(line.MouseLeave, function()
        hovered = false
        paint(true)
    end)
    toggle:Set(default, true)
    toggle.Flag = register(parent, text, options, function()
        return toggle.Value
    end, function(value)
        toggle:Set(value)
    end)
    return toggle
end

local function accessories(line)
    local strip = line:FindFirstChild("Accessories")
    if not strip then
        strip = create("Frame", {
            Name = "Accessories",
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, -1, 0, Config.TextSize + 4),
            BackgroundTransparency = 1,
            Parent = line,
        })
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = strip,
        })
    end
    return strip
end

local OpenConfigWindow
local function configWindow(line, title)

    local rowHeight = Config.TextSize + 4
    local dots = create("TextButton", {
        Name = "Settings",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(11, rowHeight),
        LayoutOrder = 1000,
        Parent = accessories(line),
    })
    local middle = math.floor((rowHeight - ToggleBox) / 2) + math.floor(ToggleBox / 2)
    local dotPixels = {}
    for i = 0, 2 do
        local dot = create("Frame", {
            Position = UDim2.fromOffset(1 + i * 4, middle),
            Size = UDim2.fromOffset(2, 2),
            BorderSizePixel = 0,
            Parent = dots,
        })
        outlined(dot, "TextOutline")
        table.insert(dotPixels, dot)
    end
    local dotsLabel = setmetatable({}, {
        __newindex = function(_, _, color)
            for _, dot in dotPixels do
                dot.BackgroundColor3 = color
            end
        end,
    })

    local frame = create("Frame", { Name = "ConfigWindow", BorderSizePixel = 0, Visible = false, ZIndex = 15, Parent = UI.Gui })
    theme(frame, "BackgroundColor3", "Background")
    shade(frame, 1, 0.86)
    addBorder(frame)
    polishOverlay(frame, { Shadow = true, ShadowPad = 26, ShadowTransparency = 0.4, Gloss = false })
    theme(create("Frame", { Name = "Accent", Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, ZIndex = 4, Parent = frame }), "BackgroundColor3", "Accent")
    local content = create("Frame", {
        Name = "Content",
        Size = UDim2.fromOffset(200, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = frame,
    })
    local titleHeight = Config.TextSize + 8
    UI.Label(content, title, {
        Position = UDim2.fromOffset(Config.Spacing + 2, 1),
        Size = UDim2.new(1, -(Config.Spacing + 2) * 2, 0, titleHeight),
    }, { Outline = true, Bold = true })
    theme(create("Frame", {
        Name = "Separator",
        Position = UDim2.fromOffset(Config.Spacing, titleHeight + 1),
        Size = UDim2.new(1, -Config.Spacing * 2, 0, 1),
        BorderSizePixel = 0,
        Parent = content,
    }), "BackgroundColor3", "Outline")
    local body = create("Frame", {
        Name = "Body",
        Position = UDim2.fromOffset(Config.Spacing, titleHeight + 2 + Config.Spacing),
        Size = UDim2.new(1, -Config.Spacing * 2, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = content,
    })
    create("UIPadding", { PaddingBottom = UDim.new(0, Config.Spacing), Parent = content })
    create("UIListLayout", { Padding = UDim.new(0, RowGap), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
    body:SetAttribute("Path", `{line.Parent:GetAttribute("Path") or "ui"}/{title}`)
    local function fit()
        frame.Size = UDim2.fromOffset(content.AbsoluteSize.X, content.AbsoluteSize.Y)
    end
    connect(content:GetPropertyChangedSignal("AbsoluteSize"), fit)

    local hovered = false
    local function paint()
        dotsLabel.TextColor3 = Config.Theme[frame.Visible and "Accent" or (hovered and "Text" or "SubText")]
    end
    table.insert(UI.Refreshers, paint)
    local function close()
        frame.Visible = false
        if Popup.Open then
            Popup.Open.Visible = false
        end
    end
    connect(frame:GetPropertyChangedSignal("Visible"), paint)
    connect(dots.MouseButton1Click, function()
        if frame.Visible then
            return close()
        end
        if OpenConfigWindow and OpenConfigWindow ~= frame then
            OpenConfigWindow.Visible = false
        end

        local inset = GuiService:GetGuiInset()
        frame.Position = UDim2.fromOffset(dots.AbsolutePosition.X + dots.AbsoluteSize.X + 12 + inset.X, line.AbsolutePosition.Y - 2 + inset.Y)
        fit()
        frame.Visible = true
        OpenConfigWindow = frame
    end)
    connect(dots.MouseEnter, function()
        hovered = true
        paint()
    end)
    connect(dots.MouseLeave, function()
        hovered = false
        paint()
    end)
    connect(UserInputService.InputBegan, function(input)
        if not frame.Visible or not isClick(input) then return end
        local point = input.Position
        local inChild = Popup.Open and Popup.Open.Visible and inside(Popup.Open, point)
        if not inside(frame, point) and not inside(dots, point) and not inChild then
            close()
        end
    end)
    paint()
    local section = container(body)
    section.Window = frame
    return section
end
UI.ConfigWindow = configWindow

local function makeSwatch(parent, default, alpha, callback, options)
    local hasAlpha = type(alpha) == "number"
    local strip = accessories(parent)
    local swatch = create("TextButton", {
        Name = "Swatch",
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromOffset(20, Config.TextSize - 2),
        BorderSizePixel = 0,
        LayoutOrder = #strip:GetChildren(),
        Parent = strip,
    })
    fillGradient(swatch)
    outlined(swatch, "Shadow")

    local zIndex = 20
    local popup = popupFrame("ColorPicker", swatch)
    popup.Size = UDim2.fromOffset(hasAlpha and 204 or 178, 172)
    theme(create("Frame", { Name = "Accent", Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, ZIndex = zIndex + 3, Parent = popup }), "BackgroundColor3", "Accent")

    local square = create("TextButton", {
        Name = "Square",
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.fromOffset(6, 7),
        Size = UDim2.fromOffset(140, 140),
        BorderSizePixel = 0,
        ZIndex = zIndex + 1,
        Parent = popup,
    })
    outlined(square, "Shadow")
    local whites = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = zIndex + 1, Parent = square })
    create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = whites })
    local blacks = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = zIndex + 2, Parent = square })
    create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = blacks })
    local squareCursor = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(4, 4),
        BackgroundTransparency = 1,
        ZIndex = zIndex + 3,
        Parent = square,
    })
    create("UIStroke", { Thickness = 1, Color = Color3.new(1, 1, 1), LineJoinMode = Enum.LineJoinMode.Miter, Parent = squareCursor })

    local hueBar = create("TextButton", {
        Name = "Hue",
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.fromOffset(152, 7),
        Size = UDim2.fromOffset(20, 140),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = zIndex + 1,
        Parent = popup,
    })
    outlined(hueBar, "Shadow")
    local hues = {}
    for i = 0, 6 do
        table.insert(hues, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 % 1, 1, 1)))
    end
    create("UIGradient", { Rotation = 90, Color = ColorSequence.new(hues), Parent = hueBar })
    local hueCursor = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = zIndex + 2,
        Parent = hueBar,
    })
    outlined(hueCursor, "Shadow")

    local alphaBar, alphaFill, alphaCursor
    if hasAlpha then
        alphaBar = create("TextButton", {
            Name = "Alpha",
            Text = "",
            AutoButtonColor = false,
            Position = UDim2.fromOffset(178, 7),
            Size = UDim2.fromOffset(20, 140),
            BackgroundColor3 = Color3.fromRGB(20, 20, 22),
            BorderSizePixel = 0,
            ZIndex = zIndex + 1,
            Parent = popup,
        })
        outlined(alphaBar, "Shadow")
        alphaFill = create("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = zIndex + 1, Parent = alphaBar })
        create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 1), Parent = alphaFill })
        alphaCursor = create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = zIndex + 2,
            Parent = alphaBar,
        })
        outlined(alphaCursor, "Shadow")
    end

    local readout = UI.Label(popup, "", {
        Position = UDim2.fromOffset(7, 150),
        Size = UDim2.new(1, -14, 0, Config.TextSize + 4),
        ZIndex = zIndex + 1,
    }, { Slot = "SubText", Outline = true })

    local picker = { Value = default or Config.Theme.Accent, Alpha = hasAlpha and math.clamp(alpha, 0, 1) or 1, Swatch = swatch, Popup = popup }
    local h, s, v = picker.Value:ToHSV()
    local function paint()
        local color = Color3.fromHSV(h, s, v)
        picker.Value = color
        swatch.BackgroundColor3 = color
        square.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        squareCursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.fromScale(0, h)
        local text = string.format("#%s  %d, %d, %d", color:ToHex(), color.R * 255 + 0.5, color.G * 255 + 0.5, color.B * 255 + 0.5)
        if hasAlpha then
            alphaFill.BackgroundColor3 = color
            alphaCursor.Position = UDim2.fromScale(0, 1 - picker.Alpha)
            text ..= string.format("  %d%%", picker.Alpha * 100 + 0.5)
        end
        readout.Text = text
    end
    local function changed()
        paint()
        if callback then
            if hasAlpha then
                task.spawn(callback, picker.Value, picker.Alpha)
            else
                task.spawn(callback, picker.Value)
            end
        end
    end
    function picker:Set(color, alpha)
        h, s, v = color:ToHSV()
        if hasAlpha and type(alpha) == "number" then
            picker.Alpha = math.clamp(alpha, 0, 1)
        end
        changed()
    end
    function picker:ColorPicker(color, onChange, swatchOptions)
        return UI.Swatch(parent, color, onChange, swatchOptions)
    end
    function picker:AlphaColorPicker(color, startAlpha, onChange, swatchOptions)
        return UI.AlphaSwatch(parent, color, startAlpha, onChange, swatchOptions)
    end

    function picker:Settings(title)
        local line = parent:IsA("GuiObject") and parent or swatch.Parent
        if line and line.Name == "Accessories" then
            line = line.Parent
        end
        local section = UI.ConfigWindow(line, title or "settings")
        local strip = line and line:FindFirstChild("Accessories")
        local settingsBtn = strip and strip:FindFirstChild("Settings")
        if settingsBtn then
            settingsBtn.LayoutOrder = -10
        end
        return section
    end
    picker.Line = parent

    dragArea(square, function(point)
        s = math.clamp((point.X - square.AbsolutePosition.X) / square.AbsoluteSize.X, 0, 1)
        v = 1 - math.clamp((point.Y - square.AbsolutePosition.Y) / square.AbsoluteSize.Y, 0, 1)
        changed()
    end)
    dragArea(hueBar, function(point)
        h = math.clamp((point.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 0.999)
        changed()
    end)
    if hasAlpha then
        dragArea(alphaBar, function(point)
            picker.Alpha = 1 - math.clamp((point.Y - alphaBar.AbsolutePosition.Y) / alphaBar.AbsoluteSize.Y, 0, 1)
            changed()
        end)
    end
    connect(swatch.MouseButton1Click, function()
        if popup.Visible then
            popup.Visible = false
        else
            openPopup(popup, swatch, swatch.AbsoluteSize.X - popup.Size.X.Offset, swatch.AbsoluteSize.Y + 4)
        end
    end)

    local menu = popupFrame("ColorMenu", swatch)
    menu.Size = UDim2.fromOffset(90, 0)
    menu.AutomaticSize = Enum.AutomaticSize.Y
    local menuList = create("Frame", {
        Name = "List",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = menu,
    })
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        Parent = menuList,
    })
    create("UIListLayout", { Padding = UDim.new(0, RowGap), SortOrder = Enum.SortOrder.LayoutOrder, Parent = menuList })
    UI.Button(menuList, "copy", function()
        UI.ColorClipboard = picker.Value
        UI.AlphaClipboard = hasAlpha and picker.Alpha or nil
        local hex = `#{picker.Value:ToHex()}`
        if setclipboard then
            pcall(setclipboard, hex)
        end
        menu.Visible = false
        UI:Notify(`copied color {hex}`, 2)
    end)
    UI.Button(menuList, "paste", function()
        menu.Visible = false
        if not UI.ColorClipboard then
            return UI:Notify("no color copied yet", 2)
        end
        picker:Set(UI.ColorClipboard, UI.AlphaClipboard)
        UI:Notify(`pasted color #{UI.ColorClipboard:ToHex()}`, 2)
    end)
    connect(swatch.MouseButton2Click, function()
        if menu.Visible then
            menu.Visible = false
        else
            openPopup(menu, swatch, swatch.AbsoluteSize.X - menu.Size.X.Offset, swatch.AbsoluteSize.Y + 4)
        end
    end)
    paint()

    picker.Flag = register(parent.Parent, `{parent.Name}/color`, options, function()
        local hex = picker.Value:ToHex()
        return hasAlpha and hex .. string.format("%02x", math.floor(picker.Alpha * 255 + 0.5)) or hex
    end, function(hex)
        hex = tostring(hex):gsub("^#", "")
        local alpha = #hex == 8 and tonumber(hex:sub(7, 8), 16)
        picker:Set(Color3.fromHex(hex:sub(1, 6)), alpha and alpha / 255)
    end)
    return picker
end

function UI.Swatch(parent, default, callback, options)
    return makeSwatch(parent, default, nil, callback, options)
end
function UI.AlphaSwatch(parent, default, alpha, callback, options)
    return makeSwatch(parent, default, type(alpha) == "number" and alpha or 1, callback, options)
end

local function colorRow(parent, text)
    local line = row(parent, text)
    line:SetAttribute("Bottom", math.floor((Config.TextSize + 4 + Config.TextSize - 2) / 2) + 1)
    UI.Label(line, text, { Size = UDim2.new(1, -28, 1, 0), Position = UDim2.fromOffset(1, 0) }, { Outline = true })
    return line
end
function UI.ColorPicker(parent, text, default, callback, options)
    return UI.Swatch(colorRow(parent, text), default, callback, options)
end
function UI.AlphaColorPicker(parent, text, default, alpha, callback, options)
    return UI.AlphaSwatch(colorRow(parent, text), default, alpha, callback, options)
end

function UI.Slider(parent, text, options, callback)
    options = options or {}
    local min, max = options.Min or 0, options.Max or 100
    local decimals, suffix = options.Decimals or 0, options.Suffix or ""
    local labelHeight, barHeight = Config.TextSize + 4, 10
    local line = row(parent, text, labelHeight + barHeight + math.ceil(Config.TextSize / 2) + 2)
    line:SetAttribute("Bottom", labelHeight + barHeight + 1)
    UI.Label(line, text, { Position = UDim2.fromOffset(1, 0), Size = UDim2.new(1, -2, 0, labelHeight) }, { Outline = true })

    local bar = create("TextButton", {
        Name = "Bar",
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.fromOffset(1, labelHeight),
        Size = UDim2.new(1, -2, 0, barHeight),
        BorderSizePixel = 0,
        Parent = line,
    })
    shade(bar, 0.6, 1)
    outlined(bar, "Shadow")
    local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = bar })
    fillGradient(fill)
    local value = UI.Label(bar, "", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(0, Config.TextSize),
        AutomaticSize = Enum.AutomaticSize.X,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 3,
    }, { Outline = true })

    local slider = { Value = min }
    local hovered = false
    local function place()
        if UI.Dragging then
            return
        end
        local fraction = (slider.Value - min) / math.max(max - min, 1e-9)
        local width = bar.AbsoluteSize.X
        if width <= 0 then
            return
        end
        local half = math.ceil((value.TextBounds.X + 2) / 2)
        local low = math.min(half, width)
        local high = math.max(width - half, low)
        local x = math.clamp(math.floor(fraction * width + 0.5), low, high)
        value.Position = UDim2.new(0, x, 1, 0)
    end
    local function paint()
        value.Text = string.format(`%.{decimals}f`, slider.Value) .. suffix
        fill.Size = UDim2.fromScale((slider.Value - min) / math.max(max - min, 1e-9), 1)
        bar.BackgroundColor3 = hovered and lighten(Config.Theme.Inline) or Config.Theme.Inline
        fill.BackgroundColor3 = hovered and lighten(Config.Theme.Accent) or Config.Theme.Accent
        place()
    end
    table.insert(UI.Refreshers, paint)
    connect(bar:GetPropertyChangedSignal("AbsoluteSize"), place)
    connect(value:GetPropertyChangedSignal("TextBounds"), place)

    function slider:Set(newValue)
        local step = 10 ^ -decimals
        local lo, hi = math.min(min, max), math.max(min, max)
        newValue = math.clamp(math.floor(newValue / step + 0.5) * step, lo, hi)
        local changed = newValue ~= slider.Value
        slider.Value = newValue
        paint()
        if changed and callback then
            task.spawn(callback, newValue)
        end
    end
    local function ctrlHeld()
        return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
    end
    dragArea(bar, function(point)
        if ctrlHeld() then return end
        slider:Set(min + (max - min) * math.clamp((point.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1))
    end)

    local entry
    local function openEntry()
        if not entry then
            local frame = popupFrame("SliderInput", bar)
            local list = create("Frame", { Name = "List", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = frame })
            create("UIPadding", {
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                Parent = list,
            })
            create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
            entry = { Frame = frame, Box = UI.Textbox(list, nil, { Placeholder = `{min} - {max}{suffix}`, Save = false }) }
            connect(entry.Box.Box.FocusLost, function(enterPressed)
                if enterPressed then
                    local number = tonumber((entry.Box.Value:gsub("[^%d%.%-]", "")))
                    if number then
                        slider:Set(number)
                    end
                end
                frame.Visible = false
                entry.Box:Set("")
            end)
        end
        entry.Frame.Size = UDim2.fromOffset(bar.AbsoluteSize.X + 2, Config.TextSize + 6 + 8)
        openPopup(entry.Frame, bar, -1, bar.AbsoluteSize.Y + 4)
        task.defer(function()
            entry.Box.Box:CaptureFocus()
        end)
    end
    connect(bar.InputBegan, function(input)
        if isClick(input) and ctrlHeld() then
            openEntry()
        end
    end)
    connect(bar.MouseEnter, function()
        hovered = true
        paint()
    end)
    connect(bar.MouseLeave, function()
        hovered = false
        paint()
    end)
    slider:Set(options.Default or min)
    slider.Flag = register(parent, text, options, function()
        return slider.Value
    end, function(value)
        slider:Set(value)
    end)
    return slider
end

function UI.Dropdown(parent, text, options, callback)
    options = options or {}
    local values, multi = options.Values or {}, options.Multi
    local hasLabel = type(text) == "string" and text ~= ""
    local labelHeight = hasLabel and Config.TextSize + 4 or 0
    local fieldHeight, optionHeight = Config.TextSize + 6, Config.TextSize + 6
    local line = row(parent, hasLabel and text or "Dropdown", labelHeight + fieldHeight)
    line:SetAttribute("Bottom", labelHeight + fieldHeight + 1)
    if hasLabel then
        UI.Label(line, text, { Position = UDim2.fromOffset(1, 0), Size = UDim2.new(1, -2, 0, labelHeight) }, { Outline = true })
    end

    local field = create("TextButton", {
        Name = "Field",
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.fromOffset(1, labelHeight),
        Size = UDim2.new(1, -2, 0, fieldHeight),
        BorderSizePixel = 0,
        Parent = line,
    })
    theme(field, "BackgroundColor3", "Inline")
    outlined(field, "Shadow")
    local shown = UI.Label(field, "", {
        Position = UDim2.fromOffset(6, 0),
        Size = UDim2.new(1, -22, 1, 0),
    }, { Outline = true })

    local chevron = create("Frame", {
        Name = "Chevron",
        Position = UDim2.new(1, -12, 0, math.floor((fieldHeight - 3) / 2)),
        Size = UDim2.fromOffset(5, 3),
        BackgroundTransparency = 1,
        Parent = field,
    })
    local chevronPixels = {}
    for _, p in { { 0, 0 }, { 4, 0 }, { 1, 1 }, { 3, 1 }, { 2, 2 } } do
        table.insert(chevronPixels, create("Frame", {
            Position = UDim2.fromOffset(p[1], p[2]),
            Size = UDim2.fromOffset(1, 1),
            BorderSizePixel = 0,
            Parent = chevron,
        }))
    end
    local wasOpen = false
    local maxVisible = 10

    local list = popupFrame("Dropdown", field)
    local scroller = create("ScrollingFrame", {
        Name = "List",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 2,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 21,
        Parent = list,
    })
    theme(scroller, "ScrollBarImageColor3", "Accent")
    local listLayout = create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroller })
    create("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2), Parent = scroller })

    local dropdown = { Value = multi and {} or nil, Sections = {} }
    local hovered = false
    local optionRows = {}
    local function isSelected(option)
        if multi then
            return dropdown.Value[option] == true
        end
        return dropdown.Value == option
    end
    local function fitList()
        local count = math.max(#values, 1)
        local visible = math.min(count, maxVisible)
        local height = visible * optionHeight + 4
        list.Size = UDim2.fromOffset(math.max(field.AbsoluteSize.X, 80), height)
        scroller.CanvasSize = UDim2.fromOffset(0, count * optionHeight + 4)
        scroller.ScrollBarThickness = count > maxVisible and 2 or 0
    end
    local function paint()
        if multi then
            local picked = {}
            for _, option in values do
                if dropdown.Value[option] then
                    table.insert(picked, option)
                end
            end
            shown.Text = #picked > 0 and table.concat(picked, ", ") or "none"
        else
            shown.Text = dropdown.Value ~= nil and tostring(dropdown.Value) or "none"
        end

        if not UI.Dragging then
            shown.Text = fitText(shown.Text, field.AbsoluteSize.X - 6 - 16)
        end
        if list.Visible ~= wasOpen then
            wasOpen = list.Visible
            TweenService:Create(chevron, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Rotation = wasOpen and 180 or 0 }):Play()
        end
        for _, pixel in chevronPixels do
            pixel.BackgroundColor3 = Config.Theme[(list.Visible or hovered) and "Text" or "SubText"]
        end
        field.BackgroundColor3 = (hovered or list.Visible) and lighten(Config.Theme.Inline) or Config.Theme.Inline
        for option, entry in optionRows do
            entry.Label.TextColor3 = Config.Theme[isSelected(option) and "Accent" or (entry.Hovered and "Text" or "SubText")]
            entry.Button.BackgroundTransparency = entry.Hovered and 0 or 1
            entry.Button.BackgroundColor3 = lighten(Config.Theme.Background)
        end
        for _, section in dropdown.Sections do
            section.Section.Visible = isSelected(section.Option)
        end
    end
    table.insert(UI.Refreshers, paint)
    connect(list:GetPropertyChangedSignal("Visible"), paint)
    connect(field:GetPropertyChangedSignal("AbsoluteSize"), function()
        if UI.Dragging then
            return
        end
        paint()
        if list.Visible then
            fitList()
        end
    end)

    function dropdown:SetValues(newValues)
        values = newValues
        for _, entry in optionRows do
            entry.Button:Destroy()
        end
        table.clear(optionRows)
        for i, option in values do
            local button = create("TextButton", {
                Name = tostring(option),
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, optionHeight),
                LayoutOrder = i,
                ZIndex = 22,
                Parent = scroller,
            })
            local entry = {
                Button = button,
                Label = UI.Label(button, tostring(option), {
                    Position = UDim2.fromOffset(6, 0),
                    Size = UDim2.new(1, -12, 1, 0),
                    ZIndex = 23,
                }, { Slot = "SubText", Outline = true }),
            }
            optionRows[option] = entry
            connect(button.MouseEnter, function()
                entry.Hovered = true
                paint()
            end)
            connect(button.MouseLeave, function()
                entry.Hovered = false
                paint()
            end)
            connect(button.MouseButton1Click, function()
                if multi then
                    local set = table.clone(dropdown.Value)
                    set[option] = not set[option] or nil
                    dropdown:Set(set)
                else
                    dropdown:Set(option)
                    list.Visible = false
                end
            end)
        end
        fitList()
        paint()
    end
    dropdown:SetValues(values)

    function dropdown:Set(value)
        if multi then
            local set = {}
            for key, on in typeof(value) == "table" and value or {} do
                if typeof(key) == "number" then
                    set[on] = true
                elseif on then
                    set[key] = true
                end
            end
            value = set
        end
        dropdown.Value = value
        paint()
        if callback then
            task.spawn(callback, value)
        end
    end

    function dropdown:Children(option)
        local section = childSection(line)
        section.Option = option
        section.Section.LayoutOrder = line.LayoutOrder + 1 + #dropdown.Sections
        table.insert(dropdown.Sections, section)
        paint()
        return section
    end

    connect(field.MouseButton1Click, function()
        if list.Visible then
            list.Visible = false
        else
            fitList()
            openPopup(list, field, 0, field.AbsoluteSize.Y + 2)
        end
    end)
    connect(field.MouseEnter, function()
        hovered = true
        paint()
    end)
    connect(field.MouseLeave, function()
        hovered = false
        paint()
    end)
    dropdown:Set(options.Default)
    dropdown.Flag = register(parent, text, options, function()
        return dropdown.Value
    end, function(value)
        dropdown:Set(value)
    end)
    return dropdown
end

local KeyNames = {
    LeftShift = "lshift", RightShift = "rshift", LeftControl = "lctrl", RightControl = "rctrl",
    LeftAlt = "lalt", RightAlt = "ralt", Return = "enter", Backspace = "bksp", CapsLock = "caps",
    MouseButton1 = "mb1", MouseButton2 = "mb2", MouseButton3 = "mb3",
}
local function keyName(key)
    return key and (KeyNames[key.Name] or key.Name:lower()) or "..."
end

function UI.Keybind(line, default, onPress)
    local height = Config.TextSize
    local box = create("TextButton", {
        Name = "Keybind",
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromOffset(textWidth(keyName(default)) + 10, height),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = -1,
        Parent = accessories(line),
    })
    shade(box, 0.6, 1)
    outlined(box, "Shadow")
    local label = UI.Label(box, keyName(default), {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    }, { Slot = "SubText", Outline = true })

    local bind = { Value = default, Listening = false }
    local hovered = false
    local function paint()
        box.BackgroundColor3 = (hovered or bind.Listening) and lighten(Config.Theme.Inline) or Config.Theme.Inline
        label.TextColor3 = Config.Theme[bind.Listening and "Accent" or (bind.Value and "Text" or "SubText")]
    end
    table.insert(UI.Refreshers, paint)
    local function resize()
        local text = bind.Listening and "..." or keyName(bind.Value)
        label.Text = text
        task.spawn(function()
            TweenService:Create(box, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(textWidth(text) + 10, height),
            }):Play()
        end)
    end

    function bind:Set(key)
        bind.Value = key
        resize()
        paint()
    end

    connect(box.MouseButton1Click, function()
        if bind.Listening then return end
        bind.Listening = true
        resize()
        paint()

        heartbeatUntil(function(elapsed)
            label.TextTransparency = 0.55 - 0.45 * math.cos(elapsed * 7)
            return bind.Listening
        end, function()
            label.TextTransparency = 0
        end)
        local listener
        listener = UserInputService.InputBegan:Connect(function(input)
            local key
            if input.UserInputType == Enum.UserInputType.Keyboard then
                key = (input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode ~= Enum.KeyCode.Backspace) and input.KeyCode or false
            elseif input.UserInputType.Name:match("^MouseButton%d$") then
                key = input.UserInputType
            end
            if key == nil then return end
            listener:Disconnect()
            bind.Listening = false
            bind:Set(key or nil)
        end)
        table.insert(Connections, listener)
    end)
    connect(box.MouseEnter, function()
        hovered = true
        paint()
    end)
    connect(box.MouseLeave, function()
        hovered = false
        paint()
    end)
    connect(UserInputService.InputBegan, function(input, processed)
        local key = bind.Value
        if processed or bind.Listening or not key then return end
        if input.KeyCode == key or input.UserInputType == key then
            task.spawn(onPress)
        end
    end)
    paint()

    bind.Flag = register(line.Parent, `{line.Name}/key`, nil, function()
        return bind.Value and `{bind.Value.EnumType}.{bind.Value.Name}` or false
    end, function(data)
        local enumType, name = tostring(data):match("^(%w+)%.(%w+)$")
        local ok, key = pcall(function()
            return Enum[enumType][name]
        end)
        bind:Set(enumType and ok and key or nil)
    end)
    return bind
end

function UI.KeybindRow(parent, text, default, onPress)
    local line = row(parent, text)
    UI.Label(line, text, { Position = UDim2.fromOffset(1, 0), Size = UDim2.new(1, -2, 1, 0) }, { Outline = true })
    return UI.Keybind(line, default, onPress)
end

function UI.List(parent, text, options, callback)
    options = options or {}
    local values, multi = options.Values or {}, options.Multi
    local labelHeight, optionHeight = text and Config.TextSize + 2 or 0, Config.TextSize + 4
    local line = row(parent, text or "List", labelHeight)
    if text then
        UI.Label(line, text, { Position = UDim2.fromOffset(1, -1), Size = UDim2.new(1, -2, 0, labelHeight) }, { Outline = true })
    end
    local box = create("Frame", {
        Name = "Box",
        Position = UDim2.fromOffset(1, labelHeight),
        Size = UDim2.new(1, -2, 0, 0),
        BorderSizePixel = 0,
        Parent = line,
    })
    theme(box, "BackgroundColor3", "Inline")
    shade(box, 0.6, 1)
    outlined(box, "Shadow")
    create("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2), Parent = box })
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })

    local list = { Value = multi and {} or nil }
    local entries = {}
    local slide = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local function isSelected(option)
        if multi then
            return list.Value[option] == true
        end
        return list.Value == option
    end
    local function paint()
        for option, entry in entries do
            entry.Label.TextColor3 = Config.Theme[isSelected(option) and "Accent" or (entry.Hovered and "Text" or "SubText")]
        end
    end
    table.insert(UI.Refreshers, paint)

    function list:SetValues(newValues)
        values = newValues
        for _, entry in entries do
            entry.Button:Destroy()
        end
        table.clear(entries)
        for i, option in values do
            local button = create("TextButton", {
                Name = tostring(option),
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, optionHeight),
                LayoutOrder = i,
                Parent = box,
            })
            local entry = {
                Button = button,
                Label = UI.Label(button, tostring(option), {
                    Position = UDim2.fromOffset(6, 0),
                    Size = UDim2.new(1, -12, 1, 0),
                }, { Slot = "SubText", Outline = true }),
            }
            entries[option] = entry
            connect(button.MouseEnter, function()
                entry.Hovered = true
                TweenService:Create(entry.Label, slide, { Position = UDim2.fromOffset(10, 0) }):Play()
                paint()
            end)
            connect(button.MouseLeave, function()
                entry.Hovered = false
                TweenService:Create(entry.Label, slide, { Position = UDim2.fromOffset(6, 0) }):Play()
                paint()
            end)
            connect(button.MouseButton1Click, function()
                if multi then
                    local set = table.clone(list.Value)
                    set[option] = not set[option] or nil
                    list:Set(set)
                else
                    list:Set(option)
                end
            end)
        end
        list:Resize()
        paint()
    end

    function list:Resize()
        local boxHeight = math.max(#values, 1) * optionHeight + 4
        local page = options.Fill and line:FindFirstAncestorOfClass("ScrollingFrame")
        if page and page.AbsoluteSize.Y > 0 then
            local bottom = page.AbsolutePosition.Y + page.AbsoluteSize.Y - Config.Spacing * 2 - 2
            boxHeight = math.max(boxHeight, math.floor(bottom - box.AbsolutePosition.Y))
        end
        box.Size = UDim2.new(1, -2, 0, boxHeight)
        line.Size = UDim2.new(1, 0, 0, labelHeight + boxHeight)
        line:SetAttribute("Bottom", labelHeight + boxHeight + 1)
    end
    if options.Fill then
        local function refit()
            task.defer(list.Resize, list)
        end
        connect(line.AncestryChanged, refit)
        task.defer(function()
            local page = line:FindFirstAncestorOfClass("ScrollingFrame")
            if page then
                connect(page:GetPropertyChangedSignal("AbsoluteSize"), refit)
                connect(page:GetPropertyChangedSignal("CanvasPosition"), refit)
            end
            list:Resize()
        end)
    end
    list:SetValues(values)

    function list:Set(value)
        if multi then
            local set = {}
            for key, on in typeof(value) == "table" and value or {} do
                if typeof(key) == "number" then
                    set[on] = true
                elseif on then
                    set[key] = true
                end
            end
            value = set
        end
        list.Value = value
        paint()
        if callback then
            task.spawn(callback, value)
        end
    end
    list:Set(options.Default)
    list.Flag = register(parent, text or "list", options, function()
        return list.Value
    end, function(value)
        list:Set(value)
    end)
    return list
end

function UI.Textbox(parent, text, options, callback)
    options = options or {}
    local labelHeight, fieldHeight = text and Config.TextSize + 4 or 0, Config.TextSize + 6
    local line = row(parent, text or "Textbox", labelHeight + fieldHeight)
    line:SetAttribute("Bottom", labelHeight + fieldHeight + 1)
    if text then
        UI.Label(line, text, { Position = UDim2.fromOffset(1, 0), Size = UDim2.new(1, -2, 0, labelHeight) }, { Outline = true })
    end
    local field = create("TextBox", {
        Name = "Field",
        Position = UDim2.fromOffset(1, labelHeight),
        Size = UDim2.new(1, -2, 0, fieldHeight),
        BorderSizePixel = 0,
        FontFace = UI.Font,
        TextSize = Config.TextSize,
        Text = "",

        TextTransparency = 1,
        PlaceholderText = "",
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = line,
    })
    create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = field })
    theme(field, "BackgroundColor3", "Inline")
    outlined(field, "Shadow")

    local display = create("Frame", { Name = "Display", BackgroundTransparency = 1, ClipsDescendants = true, Size = UDim2.fromScale(1, 1), Parent = field })

    local placeholder = UI.Label(display, options.Placeholder or "", { Size = UDim2.fromScale(1, 1), ZIndex = 1 }, { Slot = "SubText", Outline = true })
    local strip = create("Frame", { Name = "Strip", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = display })
    local caret = create("Frame", {
        Name = "Caret",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(1, Config.TextSize),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 2,
        Parent = strip,
    })
    theme(caret, "BackgroundColor3", "Accent")

    local charWidth = textWidth("m")
    local roll = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local glyphs, shown = {}, ""
    local function glyph(char)
        local label = create("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = UI.Font,
            TextSize = Config.TextSize,
            Text = char,
            TextTransparency = 1,
            Size = UDim2.new(0, charWidth, 1, 0),
            Parent = strip,
        })
        theme(label, "TextColor3", "Text")
        local stroke = create("UIStroke", { Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = label })
        theme(stroke, "Color", "TextOutline")
        return { Label = label, Stroke = stroke }
    end
    local function fade(g, transparency)
        TweenService:Create(g.Label, roll, { TextTransparency = transparency }):Play()
        TweenService:Create(g.Stroke, roll, { Transparency = transparency }):Play()
    end
    local function follow()
        local cursor = field.CursorPosition > 0 and field.CursorPosition - 1 or #shown
        local x = cursor * charWidth
        TweenService:Create(caret, TweenInfo.new(0.08, Enum.EasingStyle.Quad), { Position = UDim2.new(0, x, 0.5, 0) }):Play()
        local scroll = math.min(0, display.AbsoluteSize.X - x - 2)
        TweenService:Create(strip, roll, { Position = UDim2.fromOffset(scroll, 0) }):Play()
    end

    local function sync(newText)
        local old = shown
        local prefix = 0
        while prefix < #old and prefix < #newText and old:sub(prefix + 1, prefix + 1) == newText:sub(prefix + 1, prefix + 1) do
            prefix += 1
        end
        local suffix = 0
        while suffix < #old - prefix and suffix < #newText - prefix and old:sub(#old - suffix, #old - suffix) == newText:sub(#newText - suffix, #newText - suffix) do
            suffix += 1
        end
        for i = #old - suffix, prefix + 1, -1 do
            local g = table.remove(glyphs, i)
            TweenService:Create(g.Label, roll, { Position = g.Label.Position + UDim2.fromOffset(0, 6) }):Play()
            fade(g, 1)
            task.delay(roll.Time, g.Label.Destroy, g.Label)
        end
        for i = prefix + 1, #newText - suffix do
            local g = glyph(newText:sub(i, i))
            g.Label.Position = UDim2.fromOffset((i - 1) * charWidth, -6)
            table.insert(glyphs, i, g)
            fade(g, 0)
        end
        for i, g in glyphs do
            TweenService:Create(g.Label, roll, { Position = UDim2.fromOffset((i - 1) * charWidth, 0) }):Play()
        end
        shown = newText
        TweenService:Create(placeholder, roll, { TextTransparency = #newText == 0 and 0 or 1 }):Play()
        follow()
    end

    local textbox = { Value = "", Box = field }
    local hovered = false
    local function paint()
        field.BackgroundColor3 = (hovered or field:IsFocused()) and lighten(Config.Theme.Inline) or Config.Theme.Inline
        field.TextColor3 = field.BackgroundColor3
    end
    table.insert(UI.Refreshers, paint)
    function textbox:Set(value)
        field.Text = value
    end
    connect(field:GetPropertyChangedSignal("Text"), function()
        textbox.Value = field.Text
        sync(field.Text)
        if callback then
            task.spawn(callback, field.Text)
        end
    end)
    connect(field:GetPropertyChangedSignal("CursorPosition"), follow)
    connect(field.Focused, function()
        paint()
        caret.Visible = true
        heartbeatUntil(function(elapsed)
            caret.BackgroundTransparency = elapsed % 1 < 0.55 and 0 or 1
            return field:IsFocused()
        end, function()
            caret.Visible = false
        end)
    end)
    connect(field.FocusLost, paint)
    connect(field.MouseEnter, function()
        hovered = true
        paint()
    end)
    connect(field.MouseLeave, function()
        hovered = false
        paint()
    end)
    paint()
    if options.Default then
        field.Text = options.Default
    end
    textbox.Flag = register(parent, text or "textbox", options, function()
        return textbox.Value
    end, function(value)
        textbox:Set(value)
    end)
    return textbox
end

function UI.Button(parent, text, callback)
    local height = Config.TextSize + 6
    local line = row(parent, text, height)
    line:SetAttribute("Bottom", height + 1)
    local group = { Buttons = {} }
    local function layout()

        local count, gap = #group.Buttons, 4
        local shrink = (2 + gap * (count - 1)) / count
        for i, entry in group.Buttons do
            entry.Button.Position = UDim2.new((i - 1) / count, 1 + (i - 1) * (gap - shrink), 0, 0)
            entry.Button.Size = UDim2.new(1 / count, -shrink, 1, 0)
        end
    end
    function group:Add(name, onClick)
        local button = create("TextButton", {
            Name = name,
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Parent = line,
        })
        shade(button, 1.1, 0.85)
        outlined(button, "Shadow")
        local label = UI.Label(button, name, {
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
        }, { Outline = true })
        local entry = { Button = button, Label = label }
        local hovered = false
        local function paint()
            button.BackgroundColor3 = hovered and lighten(Config.Theme.Background) or Config.Theme.Background
        end
        table.insert(UI.Refreshers, paint)
        connect(button.MouseEnter, function()
            hovered = true
            paint()
        end)
        connect(button.MouseLeave, function()
            hovered = false
            paint()
        end)
        connect(button.MouseButton1Click, function()
            label.TextColor3 = Config.Theme.Accent
            TweenService:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextColor3 = Config.Theme.Text }):Play()
            if onClick then
                task.spawn(onClick)
            end
        end)
        paint()
        table.insert(group.Buttons, entry)
        layout()
        return group
    end
    group:Add(text, callback)
    return group
end

function UI.Window(size)
    size = size or UDim2.fromOffset(450, 500)
    local margin, gap, tabHeight = 6, 6, Config.TextSize + 14
    local frame = create("Frame", {
        Name = "Window",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BorderSizePixel = 0,
        Active = true,
        Parent = UI.Gui,
    })
    theme(frame, "BackgroundColor3", "Background")
    shade(frame, 1, 0.86)
    addBorder(frame)
    polishOverlay(frame, { Shadow = true, ShadowPad = 28, ShadowTransparency = 0.4, Gloss = false })
    registerPosition("__window", frame)
    local accent = 1
    local accentBar = create("Frame", { Name = "Accent", Size = UDim2.new(1, 0, 0, accent), BorderSizePixel = 0, ZIndex = 4, Parent = frame })
    theme(accentBar, "BackgroundColor3", "Accent")
    local grab = create("TextButton", {
        Name = "Grab",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, margin + accent + 4),
        ZIndex = 5,
        Parent = frame,
    })

    local pages = create("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(margin, margin + accent),
        Size = UDim2.new(1, -margin * 2, 1, -(margin * 2 + gap + tabHeight + accent)),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = frame,
    })
    theme(pages, "BackgroundColor3", "Inline")
    inset(pages)

    local tabBar = create("Frame", {
        Name = "Tabs",
        Position = UDim2.new(0, 6, 1, -(tabHeight + 6)),
        Size = UDim2.new(1, -12, 0, tabHeight),
        BorderSizePixel = 0,
        Parent = frame,
    })
    theme(tabBar, "BackgroundColor3", "Inline")
    inset(tabBar)

    local selection = create("Frame", { Name = "Selection", BorderSizePixel = 0, ZIndex = 1, Parent = tabBar })
    theme(selection, "BackgroundColor3", "Background")
    shade(selection, 1.1, 0.85)
    theme(create("Frame", { Name = "Indicator", Position = UDim2.fromOffset(0, 1), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = selection }), "BackgroundColor3", "Accent")

    local tabList = create("Frame", { Name = "List", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = tabBar })

    local window = { Frame = frame, Pages = pages, TabBar = tabBar, Selection = selection, Tabs = {}, Selected = nil }
    local slide

    local function refresh()
        for _, tab in window.Tabs do
            local selected = tab == window.Selected
            tab.Label.TextColor3 = (selected or tab.Hovered) and Config.Theme[selected and "Accent" or "Text"] or Config.Theme.SubText
            tab.Page.Visible = selected
        end
    end
    window.Refresh = refresh
    table.insert(UI.Refreshers, refresh)

    local function selectionGoal()
        local tab = window.Selected
        return UDim2.fromOffset(tab and tab.X or 0, 0), UDim2.new(0, tab and tab.Width or 0, 1, 0)
    end

    local function layoutTabs()
        local total, count = tabList.AbsoluteSize.X, #window.Tabs
        if count == 0 or total <= 0 then return end
        local textWidth = 0
        for _, tab in window.Tabs do
            textWidth += tab.Label.TextBounds.X
        end
        local gap = math.floor((total - textWidth) / count)
        local textX = math.floor((total - textWidth - gap * (count - 1)) / 2)
        local starts = {}
        for i, tab in window.Tabs do
            starts[i] = textX
            textX += tab.Label.TextBounds.X + gap
        end
        for i, tab in window.Tabs do
            local left = i == 1 and 0 or starts[i] - math.floor(gap / 2)
            local right = i == count and total or starts[i + 1] - math.floor(gap / 2)
            tab.X, tab.Width = left, right - left
            tab.Button.Position = UDim2.fromOffset(left, 0)
            tab.Button.Size = UDim2.new(0, tab.Width, 1, 0)
            tab.Label.Position = UDim2.fromOffset(starts[i] - left, 0)
            tab.Label.Size = UDim2.new(0, tab.Label.TextBounds.X, 1, 0)
        end
        if not (slide and slide.PlaybackState == Enum.PlaybackState.Playing) then
            selection.Position, selection.Size = selectionGoal()
        end
    end
    connect(tabList:GetPropertyChangedSignal("AbsoluteSize"), layoutTabs)

    function window:Select(tab, instant)
        window.Selected = tab
        refresh()
        local position, size = selectionGoal()
        if slide then
            slide:Cancel()
        end
        if instant then
            selection.Position, selection.Size = position, size
        else
            slide = TweenService:Create(selection, TweenInfo.new(Config.TabTween, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = position,
                Size = size,
            })
            slide:Play()
        end
    end

    function window:Tab(name, options)
        local button = create("TextButton", {
            Name = name,
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = tabList,
        })
        local scroller = create("ScrollingFrame", {
            Name = name,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 2,
            Visible = false,
            ZIndex = 1,
            Parent = pages,
        })
        theme(scroller, "ScrollBarImageColor3", "Accent")

        create("UIPadding", { PaddingBottom = UDim.new(0, Config.Spacing), Parent = scroller })
        local holder = create("Frame", {
            Name = "Columns",
            Position = UDim2.fromOffset(Config.Spacing, Config.Spacing),
            Size = UDim2.new(1, -Config.Spacing * 2, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = scroller,
        })
        local columns = {}
        for i, side in { "left", "right" } do
            local column = create("Frame", {
                Name = side,
                Position = UDim2.new((i - 1) * 0.5, (i - 1) * Config.Spacing / 2, 0, 0),
                Size = UDim2.new(0.5, -Config.Spacing / 2, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = holder,
            })
            create("UIListLayout", { Padding = UDim.new(0, Config.Spacing), SortOrder = Enum.SortOrder.LayoutOrder, Parent = column })
            columns[side] = column
        end

        local page = { Name = name, Frame = scroller, Columns = columns }
        function page:Groupbox(title, side)
            return UI.Groupbox(columns[side or "left"] or columns.left, title, `{name}/{title}`)
        end

        local tab = {
            Name = name,
            Button = button,
            Label = UI.Label(button, name, { Size = UDim2.fromScale(1, 1) }, { Slot = "SubText", Outline = true, Bold = true }),
            Page = scroller,
            Pinned = options and options.Pinned,
        }

        local index = #window.Tabs + 1
        if not tab.Pinned then
            for i, other in window.Tabs do
                if other.Pinned then
                    index = i
                    break
                end
            end
        end
        table.insert(window.Tabs, index, tab)
        if not tab.Pinned and window.Selected and window.Selected.Pinned then
            window.Selected = tab
        end
        connect(tab.Label:GetPropertyChangedSignal("TextBounds"), layoutTabs)
        layoutTabs()
        connect(button.MouseButton1Click, function()
            if window.Selected ~= tab then
                window:Select(tab)
            end
        end)
        connect(button.MouseEnter, function()
            tab.Hovered = true
            refresh()
        end)
        connect(button.MouseLeave, function()
            tab.Hovered = false
            refresh()
        end)
        window:Select(window.Selected or tab, true)
        return page
    end

    UI.WindowDraggable(frame)
    UI.Draggable(frame, grab)
    UI.Draggable(frame, tabBar)
    return window
end

function UI.SetColor(slot, color)
    Config.Theme[slot] = color
    for _, entry in Themed do
        if entry[3] == slot and entry[1].Parent then
            entry[1][entry[2]] = color
        end
    end
    for _, refresh in UI.Refreshers do
        refresh()
    end
end

function UI.Unload()
    for _, connection in Connections do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(Connections)
    local keepGone = UI.Gui
    if keepGone then
        pcall(function()
            keepGone:Destroy()
        end)
    end
    local parents = { GuiParent }
    local lp = LocalPlayer
    if lp then
        local pg = lp:FindFirstChildOfClass("PlayerGui")
        if pg then
            parents[#parents + 1] = pg
        end
    end
    if typeof(gethui) == "function" then
        local okHui, host = pcall(gethui)
        if okHui and typeof(host) == "Instance" then
            parents[#parents + 1] = host
        end
    end
    for _, parent in parents do
        if typeof(parent) == "Instance" then
            for _, child in parent:GetChildren() do
                if child.Name == "Tapology" and child:IsA("ScreenGui") then
                    pcall(child.Destroy, child)
                end
            end
        end
    end
    UI.Gui = nil
    if env.Tapology == UI then
        env.Tapology = nil
    end
    if env.Library == UI then
        env.Library = nil
    end
end

local hui = gethui and gethui()
do
    local parent = GuiParent
    if hui and typeof(hui) == "Instance" and not hui:IsA("LayerCollector") then
        parent = hui
    elseif gethui then

        local okHui, host = pcall(gethui)
        if okHui and typeof(host) == "Instance" and not host:IsA("LayerCollector") then
            parent = host
        end
    end
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    UI.Gui = create("ScreenGui", {
        Name = "Tapology",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        Parent = parent,
    })
    if not UI.Gui.Parent and playerGui then
        pcall(function()
            UI.Gui.Parent = playerGui
        end)
    end
    if not UI.Gui.Parent then
        pcall(function()
            UI.Gui.Parent = GuiParent
        end)
    end
end

do
    local border = 0
    for _, ring in Config.Border do
        border += ring[2]
    end
    local height = Config.TextSize + 16
    local function frameSize(width)
        return UDim2.fromOffset(width + border * 2, height + border * 2)
    end
    local function textSize(parts)
        local count = 0
        for _, part in parts do
            count += #part[1]
        end
        return count * charWidth() + 1 + 28
    end
    local started = os.clock()
    print("[Tapology] Loading UI...")
    local canvas = create("CanvasGroup", {
        Name = "Splash",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = frameSize(0),
        BackgroundTransparency = 1,
        ZIndex = 100,
        Parent = UI.Gui,
    })
    local panel = create("Frame", {
        Position = UDim2.fromOffset(border, border),
        Size = UDim2.new(1, -border * 2, 1, -border * 2),
        BorderSizePixel = 0,
        Parent = canvas,
    })
    theme(panel, "BackgroundColor3", "Background")
    shade(panel, 1, 0.86)
    addBorder(panel)

    local clip = create("Frame", { Name = "Clip", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, Parent = panel })
    theme(create("Frame", { Name = "Accent", Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = clip }), "BackgroundColor3", "Accent")

    local function phrase(parts, transparency)
        local holder = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = clip })
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = holder,
        })
        local labels = {}
        for i, part in parts do
            local label = UI.Label(holder, part[1], {
                Size = UDim2.fromOffset(0, Config.TextSize + 4),
                AutomaticSize = Enum.AutomaticSize.X,
                LayoutOrder = i,
            }, { Slot = part[2], Outline = true, Bold = true })
            label.TextTransparency = transparency
            table.insert(labels, label)
        end
        return labels
    end
    local question = { { "are you ready to", "Text" }, { " tap?", "Accent" } }
    local brand = { { "tapology", "Text" }, { ".pro", "Accent" } }
    local questionLabels, brandLabels = phrase(question, 0), phrase(brand, 1)

    local function play(target, info, goal)
        local tween = TweenService:Create(target, info, goal)
        tween:Play()
        return tween
    end
    local function quart(time, direction)
        return TweenInfo.new(time, Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
    end
    local function fade(labels, transparency, time)
        local last
        for _, label in labels do
            last = play(label, quart(time), { TextTransparency = transparency })
        end
        return last
    end

    play(canvas, quart(0.45), { Size = frameSize(textSize(question)) }).Completed:Wait()
    task.wait(math.max(Config.SplashTime * 0.5 - (os.clock() - started), 0.4))

    fade(questionLabels, 1, 0.2)
    play(canvas, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), { Size = frameSize(textSize(brand)) })
    task.wait(0.15)
    fade(brandLabels, 0, 0.3).Completed:Wait()
    task.wait(math.max(Config.SplashTime - (os.clock() - started), 0.4))

    play(canvas, quart(0.35), { GroupTransparency = 1 }).Completed:Wait()
    canvas:Destroy()
    print("[Tapology] Loaded UI")
end

local window = UI.Window(UDim2.fromOffset(505, 660))
UI.Main = window
UI.Pages = {}
UI.Groups = {}
UI.Pages.settings = window:Tab("settings", { Pinned = true })
UI.Groups.configs = UI.Pages.settings:Groupbox("configs", "left")
UI.Groups.config = UI.Pages.settings:Groupbox("config", "right")

function UI:Tab(name)
    local page = window:Tab(name)
    UI.Pages[name] = page
    return page
end

local function overlay(name, position, anchor)
    local frame = create("Frame", {
        Name = name,
        AnchorPoint = anchor,
        Position = position,
        BorderSizePixel = 0,
        Parent = UI.Gui,
    })
    theme(frame, "BackgroundColor3", "Background")
    shade(frame, 1, 0.86)
    addBorder(frame)
    polishOverlay(frame, { Shadow = true, ShadowPad = 24, ShadowTransparency = 0.44, Gloss = true })
    theme(create("Frame", { Name = "Accent", Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, ZIndex = 4, Parent = frame }), "BackgroundColor3", "Accent")

    local clip = create("Frame", { Name = "Clip", BackgroundTransparency = 1, ClipsDescendants = true, Size = UDim2.fromScale(1, 1), Parent = frame })
    local content = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.new(),
        Parent = clip,
    })
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 9),
        PaddingRight = UDim.new(0, 9),
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 4),
        Parent = content,
    })

    local resize = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local function fit(instant)
        local goal = UDim2.fromOffset(content.AbsoluteSize.X, content.AbsoluteSize.Y)
        if instant == true then
            frame.Size = goal
        else
            TweenService:Create(frame, resize, { Size = goal }):Play()
        end
    end
    connect(content:GetPropertyChangedSignal("AbsoluteSize"), fit)
    task.defer(fit, true)
    UI.Draggable(frame)
    registerPosition(`__{name:lower()}`, frame)
    return frame, content
end

local function autoLabel(parent, text, slot, order, bold, nudge)
    local label = UI.Label(parent, text, {
        Size = UDim2.fromOffset(0, Config.TextSize + 4),
        AutomaticSize = Enum.AutomaticSize.X,
        LayoutOrder = order,
    }, { Slot = slot, Outline = true, Bold = bold })
    if nudge then
        create("UIPadding", { PaddingTop = UDim.new(0, nudge * 2), Parent = label })
    end
    return label
end

local watermark, watermarkContent = overlay("Watermark", UDim2.new(1, -8, 0, 8), Vector2.new(1, 0))
create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = watermarkContent,
})
autoLabel(watermarkContent, "tapology", "Text", 1, true, 1)
autoLabel(watermarkContent, ".pro", "Accent", 2, true, 1)
UI.Watermark = watermark

local WatermarkInfo = { "fps", "time", "game", "ram", "cpu usage" }
local watermarkItems = {}
local gameName = "game"
task.spawn(function()
    local ok, info = pcall(function()
        return cloneref(game:GetService("MarketplaceService")):GetProductInfo(game.PlaceId)
    end)
    if ok and info and info.Name then
        gameName = #info.Name > 28 and info.Name:sub(1, 26) .. ".." or info.Name
    end
end)

local frames, fps = 0, 0
connect(RunService.RenderStepped, function()
    frames += 1
end)

local function cpuUsage()
    local ok, ms = pcall(function()
        return cloneref(game:GetService("Stats")).PerformanceStats.CPU:GetValue()
    end)
    if not ok then
        return "cpu n/a"
    end
    return string.format("cpu %.1fms", ms)
end
local function infoText(name)
    if name == "fps" then
        return `{fps} fps`
    elseif name == "time" then
        return os.date("%H:%M:%S")
    elseif name == "game" then
        return gameName
    elseif name == "ram" then
        local ok, mb = pcall(function()
            return cloneref(game:GetService("Stats")):GetTotalMemoryUsageMb()
        end)
        if not ok then
            return "ram n/a"
        end
        return string.format("ram %.0fmb", mb)
    elseif name == "cpu usage" then
        return cpuUsage()
    end
    return name
end

function UI.SetWatermarkInfo(selected)
    for _, item in watermarkItems do
        item.Divider:Destroy()
        item.Label:Destroy()
    end
    table.clear(watermarkItems)
    for i, name in WatermarkInfo do
        if selected[name] then
            local divider = create("Frame", {
                Name = "Divider",
                Size = UDim2.fromOffset(21, Config.TextSize + 4),
                BackgroundTransparency = 1,
                LayoutOrder = 10 + i * 2,
                Parent = watermarkContent,
            })
            theme(create("Frame", {
                Position = UDim2.fromOffset(10, 2),
                Size = UDim2.new(0, 1, 1, -4),
                BorderSizePixel = 0,
                Parent = divider,
            }), "BackgroundColor3", "Highlight")
            table.insert(watermarkItems, { Name = name, Divider = divider, Label = autoLabel(watermarkContent, infoText(name), "SubText", 11 + i * 2, false, 1) })
        end
    end
end

task.spawn(function()
    local last = os.clock()
    while true do
        local gui = UI.Gui
        if not (gui and gui.Parent) then
            break
        end
        task.wait(1)
        gui = UI.Gui
        if not (gui and gui.Parent) then
            break
        end
        local now = os.clock()
        fps = math.floor(frames / (now - last) + 0.5)
        frames, last = 0, now
        for _, item in watermarkItems do
            if item.Label and item.Label.Parent then
                item.Label.Text = infoText(item.Name)
            end
        end
    end
end)

local hotkeys, hotkeysContent = overlay("Hotkeys", UDim2.new(0, 10, 0.5, 0), Vector2.new(0, 0.5))
create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = hotkeysContent })
autoLabel(hotkeysContent, "hotkeys", "Text", 0, true)
UI.HotkeysOverlay = hotkeys
local hotkeyRows = {}

local function refreshHotkeys()
    local shown = 0
    local width = #"hotkeys" * charWidth() + 1
    for _, entry in UI.Hotkeys do
        if entry.Bind.Value ~= nil then
            width = math.max(width, (#entry.Name + #keyName(entry.Bind.Value)) * charWidth() + 16)
        end
    end
    for i, entry in UI.Hotkeys do
        local bound = entry.Bind.Value ~= nil
        local rowFrame = hotkeyRows[i]
        if not rowFrame then
            rowFrame = create("Frame", {
                Name = entry.Name,
                Size = UDim2.fromOffset(width, Config.TextSize + 4),
                BackgroundTransparency = 1,
                LayoutOrder = i,
                Parent = hotkeysContent,
            })
            rowFrame:SetAttribute("Index", i)
            UI.Label(rowFrame, entry.Name, { Size = UDim2.fromScale(1, 1), Name = "Title" }, { Slot = "SubText", Outline = true })
            UI.Label(rowFrame, "", { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Right, Name = "Key" }, { Slot = "SubText", Outline = true })
            hotkeyRows[i] = rowFrame
        end
        rowFrame.Visible = bound
        rowFrame.Size = UDim2.fromOffset(width, Config.TextSize + 4)
        if bound then
            shown += 1
            local on = entry.Toggle.Value
            rowFrame.Title.TextColor3 = Config.Theme[on and "Text" or "SubText"]
            rowFrame.Key.Text = keyName(entry.Bind.Value)
            rowFrame.Key.TextColor3 = Config.Theme[on and "Accent" or "SubText"]
        end
    end
end
table.insert(UI.Refreshers, refreshHotkeys)
task.spawn(function()
    while true do
        local gui = UI.Gui
        if not (gui and gui.Parent) then
            break
        end
        pcall(refreshHotkeys)
        task.wait(0.2)
    end
end)

local HttpService = cloneref(game:GetService("HttpService"))
local GameFolder = `{Config.Folder}/games/{Config.GameFolder}`
local ConfigFolder = `{GameFolder}/configs`

local function escape(text)
    return (tostring(text):gsub("[%%,=#%[%]\n\r]", function(char)
        return string.format("%%%02X", string.byte(char))
    end))
end
local function unescape(text)
    return (text:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end))
end

local function encodeValue(value)
    local kind = typeof(value)
    if kind == "boolean" then
        return `bool:{value}`
    elseif kind == "number" then
        return `num:{string.format("%.10g", value)}`
    elseif kind == "string" then
        return `str:{escape(value)}`
    elseif kind == "table" then
        if #value > 0 then
            local parts = {}
            for i, item in value do
                parts[i] = string.format("%.10g", item)
            end
            return `arr:{table.concat(parts, ",")}`
        end
        local keys = {}
        for key, on in value do
            if on then
                table.insert(keys, escape(key))
            end
        end
        table.sort(keys)
        return `set:{table.concat(keys, ",")}`
    end
end

local function decodeValue(text)
    local kind, body = text:match("^(%a+):(.*)$")
    if kind == "bool" then
        return body == "true"
    elseif kind == "num" then
        return tonumber(body)
    elseif kind == "str" then
        return unescape(body)
    elseif kind == "arr" then
        local list = {}
        for part in body:gmatch("[^,]+") do
            table.insert(list, tonumber(part))
        end
        return list
    elseif kind == "set" then
        local set = {}
        for part in body:gmatch("[^,]+") do
            set[unescape(part)] = true
        end
        return set
    end
end

local Base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function base64Encode(data)
    local out = {}
    for i = 1, #data, 3 do
        local a, b, c = string.byte(data, i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local chars = {}
        for k = 3, 0, -1 do
            local index = math.floor(n / 64 ^ k) % 64 + 1
            table.insert(chars, Base64:sub(index, index))
        end
        if not b then
            chars[3], chars[4] = "=", "="
        elseif not c then
            chars[4] = "="
        end
        table.insert(out, table.concat(chars))
    end
    return table.concat(out)
end
local function base64Decode(data)
    data = data:gsub("[^%w%+/=]", "")
    local out = {}
    for i = 1, #data, 4 do
        local n, pad = 0, 0
        for k = 0, 3 do
            local char = data:sub(i + k, i + k)
            local index = Base64:find(char, 1, true)
            if char == "=" or not index then
                pad += 1
                index = 1
            end
            n = n * 64 + index - 1
        end
        local bytes = string.char(math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
        table.insert(out, bytes:sub(1, 3 - pad))
    end
    return table.concat(out)
end

local function checksum(text)
    local h = 2166136261
    for i = 1, #text do
        h = bit32.bxor(h, string.byte(text, i))
        h = (h * 16777619) % 4294967296
    end
    return string.format("%08x", h)
end

local function pack(tag, entries)
    local keys = {}
    for key in entries do
        table.insert(keys, key)
    end
    table.sort(keys)
    local lines = {}
    for _, key in keys do
        table.insert(lines, `{escape(key)}={entries[key]}`)
    end
    local body = table.concat(lines, "\n")
    return `{tag}.{checksum(body)}.{base64Encode(body)}`
end

local function unpack(tag, text)
    local fileTag, sum, data = text:match("^%s*(%w+)%.(%x+)%.([%w%+/=]*)%s*$")
    if fileTag ~= tag then
        return nil
    end
    local body = base64Decode(data)
    if checksum(body) ~= sum then
        return nil
    end
    local entries = {}
    for line in (body .. "\n"):gmatch("(.-)\n") do
        local key, value = line:match("^(.-)=(.*)$")
        if key and key ~= "" then
            entries[unescape(key)] = value
        end
    end
    return entries
end

local function ensureFolder(path)
    local built = ""
    for part in path:gmatch("[^/]+") do
        built = built == "" and part or `{built}/{part}`
        if not isfolder(built) then
            makefolder(built)
        end
    end
end

local function configPath(name)
    return `{ConfigFolder}/{name}.tap`
end

local function listNames(folder, extension)
    local names = {}
    if isfolder(folder) then
        for _, file in listfiles(folder) do
            local name = file:match(`([^/\\]+)%.{extension}$`)
            if name then
                table.insert(names, name)
            end
        end
    end
    table.sort(names)
    return names
end

function UI.ListConfigs()
    return listNames(ConfigFolder, "tap")
end

function UI.SaveConfig(name)
    ensureFolder(ConfigFolder)
    local entries = {}
    for flag, entry in UI.Flags do
        local ok, value = pcall(entry.Get)
        local encoded = ok and encodeValue(value)
        if encoded then
            entries[flag] = encoded
        end
    end
    writefile(configPath(name), pack("tap2", entries))
end

function UI.LoadConfig(name)
    if not isfile(configPath(name)) then
        return false
    end
    local ok, entries = pcall(unpack, "tap2", readfile(configPath(name)))
    if not ok or not entries then
        return false
    end
    for flag, raw in entries do
        local entry = UI.Flags[flag]
        local value = decodeValue(raw)
        if entry and value ~= nil then
            pcall(entry.Set, value)
        end
    end
    return true
end

local AutoloadConfigFile = `{GameFolder}/autoload.txt`
local AutoloadThemeFile = `{Config.Folder}/themes/autoload.txt`
local function readAutoload(path)
    local name = isfile(path) and readfile(path):match("^%s*(.-)%s*$") or ""
    return name ~= "" and name or nil
end
local function writeAutoload(path, name)
    ensureFolder(path:match("^(.*)/[^/]+$"))
    if name then
        writefile(path, name)
    elseif isfile(path) then
        delfile(path)
    end
end

function UI.DeleteConfig(name)
    if isfile(configPath(name)) then
        delfile(configPath(name))
    end
end

local BorderWidth = 0
for _, ring in Config.Border do
    BorderWidth += ring[2]
end
local Notices = {}
local NoticeMargin, NoticeGap = 14, 6
local noticeHolder = create("Frame", { Name = "Notifications", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 40, Parent = UI.Gui })
local slideInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function restack()
    local offset = 0
    for _, notice in Notices do
        notice.Y = -(NoticeMargin - BorderWidth) - offset
        if not notice.Leaving then
            TweenService:Create(notice.Canvas, slideInfo, { Position = UDim2.new(1, -(NoticeMargin - BorderWidth), 1, notice.Y) }):Play()
        end
        offset += notice.Height + NoticeGap
    end
end

function UI:Notify(text, duration)
    duration = duration or 4
    text = tostring(text)
    local width = math.max(#text * charWidth() + 20, 150)
    local height = Config.TextSize + 12
    local canvas = create("CanvasGroup", {
        Name = "Notification",
        AnchorPoint = Vector2.new(1, 1),
        Size = UDim2.fromOffset(width + BorderWidth * 2, height + BorderWidth * 2),
        Position = UDim2.new(1, -(NoticeMargin - BorderWidth) + 40, 1, -(NoticeMargin - BorderWidth)),
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        Parent = noticeHolder,
    })
    local panel = create("Frame", {
        Position = UDim2.fromOffset(BorderWidth, BorderWidth),
        Size = UDim2.fromOffset(width, height),
        BorderSizePixel = 0,
        Parent = canvas,
    })
    theme(panel, "BackgroundColor3", "Background")
    shade(panel, 1, 0.86)
    addBorder(panel)
    polishOverlay(panel, { Shadow = true, ShadowPad = 24, ShadowTransparency = 0.42, Gloss = false })

    local timer = create("Frame", { Name = "Accent", Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = panel })
    theme(timer, "BackgroundColor3", "Accent")
    UI.Label(panel, text, { Position = UDim2.fromOffset(9, 1), Size = UDim2.new(1, -18, 1, -1) }, { Outline = true })

    local notice = { Canvas = canvas, Height = height + BorderWidth * 2 }
    table.insert(Notices, 1, notice)
    restack()
    canvas.Position = UDim2.new(1, -(NoticeMargin - BorderWidth) + 40, 1, notice.Y)
    TweenService:Create(canvas, slideInfo, { Position = UDim2.new(1, -(NoticeMargin - BorderWidth), 1, notice.Y), GroupTransparency = 0 }):Play()
    TweenService:Create(timer, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 1) }):Play()

    task.delay(duration, function()
        notice.Leaving = true
        TweenService:Create(canvas, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(1, -(NoticeMargin - BorderWidth) + 40, 1, notice.Y),
            GroupTransparency = 1,
        }):Play()
        task.wait(0.3)
        table.remove(Notices, table.find(Notices, notice))
        canvas:Destroy()
        restack()
    end)
end

local configList = UI.Groups.configs:List(nil, { Values = UI.ListConfigs(), Save = false, Fill = true })
local configGroup = UI.Groups.config
local manage = configGroup:Subtab("config")
local themeTab = configGroup:Subtab("theme")

local function report(text)
    UI:Notify(text)
end
local function cleanName(text)
    return (text:gsub("[^%w%s%-_]", ""):match("^%s*(.-)%s*$"))
end

local nameBox = manage:Textbox("config name", { Placeholder = "name", Save = false })
local function refreshConfigs()
    configList:SetValues(UI.ListConfigs())
    configList:Set(configList.Value)
end
local function chosenName()
    local name = cleanName(nameBox.Value)
    if name == "" then
        name = configList.Value or ""
    end
    return name
end

local configListSet = configList.Set
function configList:Set(value)
    configListSet(self, value)
    if value then
        nameBox:Set(value)
    end
end

manage:Button("create", function()
    local name = chosenName()
    if name == "" then return report("enter a config name") end
    if isfile(configPath(name)) then return report(`config '{name}' already exists`) end
    UI.SaveConfig(name)
    refreshConfigs()
    configList:Set(name)
    report(`created config '{name}'`)
end)
manage:Button("save", function()
    local name = chosenName()
    if name == "" then return report("enter a config name") end
    UI.SaveConfig(name)
    refreshConfigs()
    configList:Set(name)
    report(`saved config '{name}'`)
end):Add("load", function()
    local name = chosenName()
    report(UI.LoadConfig(name) and `loaded config '{name}'` or `couldn't load config '{name}'`)
end)
manage:Button("delete", function()
    local name = chosenName()
    if not isfile(configPath(name)) then return report(`no config named '{name}'`) end
    UI.DeleteConfig(name)
    configList:Set(nil)
    nameBox:Set("")
    refreshConfigs()
    report(`deleted config '{name}'`)
end):Add("refresh", function()
    refreshConfigs()
    report(`{#UI.ListConfigs()} configs for {Config.GameFolder}`)
end)
manage:Button("set autoload", function()
    local name = chosenName()
    if not isfile(configPath(name)) then return report(`no config named '{name}'`) end
    writeAutoload(AutoloadConfigFile, name)
    report(`config '{name}' will autoload`)
end):Add("rem autoload", function()
    local name = readAutoload(AutoloadConfigFile)
    writeAutoload(AutoloadConfigFile, nil)
    report(name and `config '{name}' won't autoload` or "no config is set to autoload")
end)

UI.MenuKey = manage:Keybind("menu key", Config.MenuKey, function()
    UI:ToggleMenu()
end)

local menuCursorConn
local function setMenuCursorFree(on)
    if menuCursorConn then
        menuCursorConn:Disconnect()
        menuCursorConn = nil
    end
    if on then
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        pcall(function()
            GuiService.SelectedObject = nil
        end)
        menuCursorConn = RunService.RenderStepped:Connect(function()
            if not window.Frame.Visible then
                return
            end
            UserInputService.MouseIconEnabled = true
            if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
        end)
        table.insert(Connections, menuCursorConn)
    end
end

function UI:ToggleMenu(visible)
    if visible == nil then
        visible = not window.Frame.Visible
    end
    window.Frame.Visible = visible
    if not visible then
        if Popup.Open then
            Popup.Open.Visible = false
        end
        if OpenConfigWindow then
            OpenConfigWindow.Visible = false
        end
        setMenuCursorFree(false)
    else
        setMenuCursorFree(true)
    end
end

UI.IsMenuOpen = function()
    return window.Frame.Visible
end

if window.Frame.Visible then
    setMenuCursorFree(true)
end

local watermarkToggle = themeTab:Toggle("watermark", true, function(on)
    watermark.Visible = on
end)
watermarkToggle:Children():Dropdown("watermark info", {
    Values = WatermarkInfo,
    Multi = true,
    Default = { "fps", "time", "game" },
}, UI.SetWatermarkInfo)

local extraInfo, extraInfoContent = overlay("ExtraInfo", UDim2.new(0, 8, 0, 8), Vector2.new(0, 0))
extraInfo.Visible = false
create("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 1),
    Parent = extraInfoContent,
})
local extraFpsLabel = autoLabel(extraInfoContent, "Average FPS: 0", "Text", 1, true, 0)
local extraPingLabel = autoLabel(extraInfoContent, "Ping (L7/L4): 0/0ms", "Text", 2, true, 0)
local extraDcLabel = autoLabel(extraInfoContent, "Datacenter: …", "Text", 3, true, 0)
UI.ExtraInfo = extraInfo

local StatsService = cloneref(game:GetService("Stats"))
local extraDc = "…"
task.spawn(function()
    pcall(function()
        local raw = game:HttpGet("https://ipinfo.io/json")
        local city = string.match(raw, '"city"%s*:%s*"([^"]+)"')
        local region = string.match(raw, '"region"%s*:%s*"([^"]+)"')
        local country = string.match(raw, '"country"%s*:%s*"([^"]+)"')
        local org = string.match(raw, '"org"%s*:%s*"([^"]+)"')
        if city and country then
            extraDc = string.upper(string.sub(city, 1, 3)) .. country
        elseif region then
            extraDc = region
        elseif country then
            extraDc = country
        elseif org then
            extraDc = org
        end
    end)
    if extraDc == "…" then
        extraDc = "LOCAL"
    end
end)

local function readDataPingMs()
    local ok, value = pcall(function()
        local item = StatsService.Network.ServerStatsItem:FindFirstChild("Data Ping")
        if not item then
            return nil
        end
        local v = item:GetValue()
        if type(v) == "number" then
            return v
        end
        if type(v) == "string" then
            return tonumber((v:gsub("[^%d%.]", "")))
        end
    end)
    return ok and value or nil
end

local function readL7PingMs()
    local ok, value = pcall(function()
        return Players.LocalPlayer:GetNetworkPing() * 1000
    end)
    return ok and value or nil
end

task.spawn(function()
    while UI.Gui and UI.Gui.Parent do
        task.wait(0.5)
        if extraInfo.Visible then
            local l7 = readL7PingMs()
            local l4 = readDataPingMs()
            extraFpsLabel.Text = string.format("Average FPS: %d", fps)
            extraPingLabel.Text = string.format(
                "Ping (L7/L4): %d/%dms",
                math.floor((l7 or 0) + 0.5),
                math.floor((l4 or 0) + 0.5)
            )
            extraDcLabel.Text = "Datacenter: " .. tostring(extraDc)
        end
    end
end)

themeTab:Toggle("extra info", false, function(on)
    extraInfo.Visible = on and true or false
end)
themeTab:Toggle("hotkeys", true, function(on)
    hotkeys.Visible = on
end)

local ThemeFolder = `{Config.Folder}/themes`
local ThemeSlots = { "Accent", "Background", "Inline", "Outline", "Shadow", "Highlight", "Text", "SubText", "TextOutline" }
local themePickers = {}
local function slotLabel(slot)
    return slot:gsub("(%l)(%u)", "%1 %2"):lower()
end
for _, slot in ThemeSlots do
    themePickers[slot] = themeTab:ColorPicker(slotLabel(slot), Config.Theme[slot], function(color)
        UI.SetColor(slot, color)
    end, { Save = false })
end

local function themePath(name)
    return `{ThemeFolder}/{name}.taptheme`
end
function UI.ListThemes()
    return listNames(ThemeFolder, "taptheme")
end
function UI.SaveTheme(name)
    ensureFolder(ThemeFolder)
    local colors = {}
    for _, slot in ThemeSlots do
        colors[slotLabel(slot)] = `#{Config.Theme[slot]:ToHex()}`
    end
    writefile(themePath(name), pack("tpt2", colors))
end
function UI.LoadTheme(name)
    if not isfile(themePath(name)) then
        return false
    end
    local ok, colors = pcall(unpack, "tpt2", readfile(themePath(name)))
    if not ok or not colors then
        return false
    end
    for _, slot in ThemeSlots do
        local hex = colors[slotLabel(slot)]
        local okColor, color = pcall(Color3.fromHex, hex and hex:gsub("^#", "") or "")
        if hex and okColor then
            themePickers[slot]:Set(color)
        end
    end
    return true
end
function UI.DeleteTheme(name)
    if isfile(themePath(name)) then
        delfile(themePath(name))
    end
end

local themeName
local themeList = themeTab:Dropdown("themes", { Values = UI.ListThemes(), Save = false })
themeName = themeTab:Textbox("theme name", { Placeholder = "name", Save = false })
local themeListSet = themeList.Set
function themeList:Set(value)
    themeListSet(self, value)
    if value then
        themeName:Set(value)
    end
end
local function chosenTheme()
    local name = cleanName(themeName.Value)
    if name == "" then
        name = themeList.Value or ""
    end
    return name
end
local function refreshThemes()
    themeList:SetValues(UI.ListThemes())
    themeList:Set(themeList.Value)
end

themeTab:Button("create", function()
    local name = chosenTheme()
    if name == "" then return report("enter a theme name") end
    if isfile(themePath(name)) then return report(`theme '{name}' already exists`) end
    UI.SaveTheme(name)
    refreshThemes()
    themeList:Set(name)
    report(`created theme '{name}'`)
end)
themeTab:Button("save", function()
    local name = chosenTheme()
    if name == "" then return report("enter a theme name") end
    UI.SaveTheme(name)
    refreshThemes()
    themeList:Set(name)
    report(`saved theme '{name}'`)
end):Add("load", function()
    local name = chosenTheme()
    report(UI.LoadTheme(name) and `loaded theme '{name}'` or `couldn't load theme '{name}'`)
end)
themeTab:Button("delete", function()
    local name = chosenTheme()
    if not isfile(themePath(name)) then return report(`no theme named '{name}'`) end
    UI.DeleteTheme(name)
    themeList:Set(nil)
    themeName:Set("")
    refreshThemes()
    report(`deleted theme '{name}'`)
end):Add("refresh", function()
    refreshThemes()
    report(`{#UI.ListThemes()} themes`)
end)
themeTab:Button("set autoload", function()
    local name = chosenTheme()
    if not isfile(themePath(name)) then return report(`no theme named '{name}'`) end
    writeAutoload(AutoloadThemeFile, name)
    report(`theme '{name}' will autoload`)
end):Add("rem autoload", function()
    local name = readAutoload(AutoloadThemeFile)
    writeAutoload(AutoloadThemeFile, nil)
    report(name and `theme '{name}' won't autoload` or "no theme is set to autoload")
end)

env.Tapology = UI
env.Library = UI
getgenv().Tapology = UI
getgenv().Library = UI
UI:Notify(`tapology.pro - {keyName(Config.MenuKey)} toggles the menu`, 5)

task.spawn(function()
    local started = os.clock()
    repeat
        task.wait(0.25)
        local built = #window.Tabs > 1 and os.clock() - UI.LastRegistered >= 1
    until not UI.Gui.Parent or built or os.clock() - started >= Config.AutoloadTimeout
    if not UI.Gui.Parent then return end
    local themeName = readAutoload(AutoloadThemeFile)
    if themeName and UI.LoadTheme(themeName) then
        themeList:Set(themeName)
        report(`autoloaded theme '{themeName}'`)
    end
    local configName = readAutoload(AutoloadConfigFile)
    if configName and UI.LoadConfig(configName) then
        configList:Set(configName)
        report(`autoloaded config '{configName}'`)
    end
end)
return UI
]=] },
    { name = "weather", source = [[do

local warn = function() end

local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService = cloneref(game:GetService("HttpService"))
local Lighting = cloneref(game:GetService("Lighting"))

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local Config = {
    Radius = 90,
    Height = 26,
    Heights = {
        Snow = 26,
        Stars = 22,
        Rain = 30,
        Ash = 26,
        Spring = 22,
        Autumn = 24,
        Fireflies = 14,
        Sandstorm = 20,
        Pestilence = 24,
        Bubbles = 18,
    },
    StarDistance = 500,
    Density = 1,
    Wind = Vector3.new(2, 0, 1),
    ChangeEnvironment = true,
    Mode = "Off",
    LastMode = "Snow",
    FadeTime = 2,
    Modifier = Enum.KeyCode.LeftControl,
    CycleKey = Enum.KeyCode.Equals,
    Keys = {
        [Enum.KeyCode.One] = "Snow",
        [Enum.KeyCode.Two] = "Stars",
        [Enum.KeyCode.Three] = "Rain",
        [Enum.KeyCode.Four] = "Ash",
        [Enum.KeyCode.Five] = "Spring",
        [Enum.KeyCode.Six] = "Autumn",
        [Enum.KeyCode.Seven] = "Fireflies",
        [Enum.KeyCode.Eight] = "Sandstorm",
        [Enum.KeyCode.Nine] = "Pestilence",
        [Enum.KeyCode.Minus] = "Bubbles",
        [Enum.KeyCode.Zero] = "Off",
    },

    Colors = {
        Snow = { Flakes = rgb(240, 246, 255), Dust = rgb(235, 242, 255), Mist = rgb(225, 235, 250) },
        Stars = {
            Star1 = rgb(255, 255, 255), Star2 = rgb(170, 210, 255), Star3 = rgb(220, 180, 255),
            Dust = rgb(200, 225, 255), DustFade = rgb(230, 190, 255),
            Comet = rgb(255, 255, 255), CometTail = rgb(170, 200, 255),
            AuroraGreen = rgb(80, 255, 170), AuroraCyan = rgb(90, 220, 255),
            AuroraViolet = rgb(170, 110, 255), AuroraPink = rgb(255, 120, 200),
        },
        Rain = {
            Drops = rgb(205, 220, 240), Veil = rgb(180, 195, 215), Splash = rgb(215, 230, 245),
            Droplets = rgb(220, 232, 245), Mist = rgb(150, 160, 175),
            Lightning = rgb(215, 225, 255), LightningGlow = rgb(200, 215, 255),
        },
        Ash = {
            Ash = rgb(115, 108, 105), EmberHot = rgb(255, 210, 120), EmberMid = rgb(255, 120, 50),
            EmberCool = rgb(200, 40, 20), Mist = rgb(120, 85, 70),
        },
        Spring = {
            Petal1 = rgb(255, 190, 215), Petal2 = rgb(255, 160, 200), Petal3 = rgb(255, 225, 235),
            Pollen = rgb(255, 235, 150),
            Butterfly1 = rgb(255, 170, 210), Butterfly2 = rgb(255, 225, 120), Butterfly3 = rgb(150, 210, 255),
        },
        Autumn = {
            Maple = rgb(235, 120, 40), Red = rgb(200, 55, 35), Oak = rgb(180, 110, 45),
            Birch = rgb(235, 185, 55), Motes = rgb(255, 210, 150),
        },
        Fireflies = {
            Firefly1 = rgb(200, 255, 110), Firefly2 = rgb(255, 235, 100), Firefly3 = rgb(170, 255, 150),
            Stars = rgb(220, 230, 255), Mist = rgb(60, 90, 95),
        },
        Sandstorm = { Sand = rgb(225, 185, 130), Dust = rgb(205, 165, 115), Drift = rgb(215, 175, 120) },
        Pestilence = {
            Flies = rgb(28, 30, 22), Spores = rgb(170, 255, 90), SporeFade = rgb(90, 140, 40),
            Blight = rgb(120, 130, 95), Miasma = rgb(120, 150, 70), Toxic = rgb(150, 210, 60),
        },
        Bubbles = {
            Bubble = rgb(255, 255, 255), Sparkle = rgb(255, 240, 255), Glow = rgb(210, 225, 255),
        },
    },
    TextureFolder = "weather_textures",
    RememberMode = false,
    Hotkeys = false,

    ModeParams = {},
}

local TextureIds

local env = getgenv and getgenv() or _G
if env.Weather then
    env.Weather.Unload()
end

if type(env.WeatherOptions) == "table" then
    for key, value in env.WeatherOptions do
        Config[key] = value
    end
end

local LocalPlayer = Players.LocalPlayer
local base64decode = (crypt and crypt.base64decode) or base64_decode or (base64 and base64.decode)
local SettingsPath = `{Config.TextureFolder}/settings.json`
local rng = Random.new()

local Textures = {}
local Connections = {}
local Modes = {}
local ModeOrder = {}
local Active
local Container, Sky, Column, Volume, Ground, NearSky, NearGround, Dome, Lens

local function create(className, props)
    local instance = Instance.new(className)
    for key, value in props do
        if key ~= "Parent" then
            instance[key] = value
        end
    end
    instance.Parent = props.Parent
    return instance
end

local function numberSequence(points)
    local keypoints = {}
    for _, point in points do
        table.insert(keypoints, NumberSequenceKeypoint.new(point[1], point[2], point[3] or 0))
    end
    return NumberSequence.new(keypoints)
end

local function colorSequence(points)
    local keypoints = {}
    for _, point in points do
        table.insert(keypoints, ColorSequenceKeypoint.new(point[1], point[2]))
    end
    return ColorSequence.new(keypoints)
end

local function newPart(name, size, parent)
    return create("Part", {
        Name = name,
        Size = size,
        Anchored = true,
        CanCollide = false,
        CanQuery = false,
        CanTouch = false,
        CastShadow = false,
        Transparency = 1,
        Parent = parent,
    })
end

local function hash(text)
    local h = 0
    for i = 1, #text do
        h = (h * 31 + string.byte(text, i)) % 4294967291
    end
    return string.format("%08x", h)
end

local function loadTextures()
    for name, id in TextureIds do
        Textures[name] = id
    end
end

local characterInterface
local characterLookupDone = false
local function resolveCharacterInterface()
    if characterInterface or characterLookupDone then
        return characterInterface
    end
    characterLookupDone = true
    if not getgc then
        return nil
    end
    for _, value in getgc(true) do
        if type(value) == "table" and rawget(value, "ScreenCull") and rawget(value, "NetworkClient") then
            local entry = rawget(value, "CharacterInterface")
            local mod = type(entry) == "table" and entry.module ~= nil and entry.module or entry
            if type(mod) == "table" and mod.getCharacterObject then
                characterInterface = mod
                return characterInterface
            end
        end
    end
    for _, value in getgc(true) do
        if type(value) == "table" and rawget(value, "getCharacterObject") and rawget(value, "isAlive") then
            characterInterface = value
            return characterInterface
        end
    end
    return nil
end

local function focusPosition()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.CFrame.Position
    end
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        return root.Position
    end
    local ci = resolveCharacterInterface()
    if ci then
        local ok, object = pcall(ci.getCharacterObject)
        if ok and object and object.getRootPart then
            local okRoot, part = pcall(function()
                return object:getRootPart()
            end)
            if okRoot and part and typeof(part.Position) == "Vector3" then
                return part.Position
            end
        end
    end
    return Vector3.zero
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function isCharacterishHit(inst)
    if not inst then
        return false
    end
    local model = inst:FindFirstAncestorOfClass("Model")
    if not model then
        return false
    end
    if model:FindFirstChildOfClass("Humanoid")
        or model:FindFirstChild("Cosmetics")
        or (model:FindFirstChild("Torso") and model:FindFirstChild("Head"))
        or model:FindFirstChild("HumanoidRootPart")
    then
        return true
    end
    return false
end

local function groundBelow(position, fallback)
    local ignore = { LocalPlayer.Character, Container, workspace.CurrentCamera }
    for _, name in ipairs({ "Ignore", "Players", "Effects", "Temporary", "Rain", "Weather", "Aura" }) do
        local folder = workspace:FindFirstChild(name)
        if folder then
            table.insert(ignore, folder)
        end
    end
    local origin = position + Vector3.new(0, 80, 0)
    local direction = Vector3.new(0, -500, 0)
    for _ = 1, 10 do
        rayParams.FilterDescendantsInstances = ignore
        local hit = workspace:Raycast(origin, direction, rayParams)
        if not hit then
            break
        end
        local inst = hit.Instance
        if isCharacterishHit(inst) then
            local model = inst:FindFirstAncestorOfClass("Model")
            table.insert(ignore, model or inst)
        else
        return hit.Position
    end
    end
    local fallbackY = typeof(fallback) == "number" and fallback or position.Y - 3
    return Vector3.new(position.X, fallbackY, position.Z)
end

local ModeParamDefaults = {
    Snow = { Radius = 90, Density = 1, Wind = 1, Size = 1, Height = 26 },
    Stars = { Radius = 70, Density = 0.7, Wind = 0.35, Size = 1, Height = 22, StarDistance = 280, CometRate = 0.55 },
    Rain = { Radius = 90, Density = 1, Wind = 1, Size = 1, Height = 30 },
    Ash = { Radius = 90, Density = 1, Wind = 1.2, Size = 1, Height = 26 },
    Spring = { Radius = 90, Density = 1, Wind = 0.8, Size = 1, Height = 22 },
    Autumn = { Radius = 90, Density = 1, Wind = 1.1, Size = 1, Height = 24 },
    Fireflies = { Radius = 70, Density = 1, Wind = 0.25, Size = 1, Height = 14 },
    Sandstorm = { Radius = 110, Density = 1.2, Wind = 2.2, Size = 1, Height = 20 },
    Pestilence = { Radius = 90, Density = 1, Wind = 0.7, Size = 1, Height = 24 },
    Bubbles = { Radius = 80, Density = 1, Wind = 0.5, Size = 1, Height = 18 },
}
for name, defaults in ModeParamDefaults do
    local copy = {}
    for key, value in defaults do
        copy[key] = value
    end
    Config.ModeParams[name] = copy
end

local function modeParams(name)
    return Config.ModeParams[name] or ModeParamDefaults[name]
end

local function paramOf(name, key, fallback)
    local params = modeParams(name)
    local value = params and params[key]
    if value == nil then
        return fallback
    end
    return value
end

local function activeRadius(name)
    return paramOf(name or (Active and Active.Name), "Radius", Config.Radius)
end

local function rateScale(name)
    local density = paramOf(name or (Active and Active.Name), "Density", Config.Density)
    local area = (activeRadius(name) / 90) ^ 2
    return math.clamp(density, 0.15, 1.25) * math.clamp(area, 0.25, 1.35) * 0.45
end

local function modeHeight(name)
    return paramOf(name, "Height", Config.Heights[name] or Config.Height)
end

local function modeStarDistance(name)
    return paramOf(name or "Stars", "StarDistance", Config.StarDistance)
end

local function modeWindScale(name)
    return paramOf(name or (Active and Active.Name), "Wind", 1)
end

local function windDirection(name)
    local flat = Config.Wind * modeWindScale(name) * Vector3.new(1, 0, 1)
    return flat.Magnitude > 1e-3 and flat.Unit or Vector3.xAxis
end

local function modeSizeScale(name)
    return paramOf(name or (Active and Active.Name), "Size", 1)
end

local function scaleSequence(sequence, mul)
    if mul == 1 or typeof(sequence) ~= "NumberSequence" then
        return sequence
    end
    local keypoints = {}
    for _, keypoint in sequence.Keypoints do
        table.insert(keypoints, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * mul, keypoint.Envelope * mul))
    end
    return NumberSequence.new(keypoints)
end

local EnvironmentProps = {
    Lighting = { "ClockTime", "Brightness", "Ambient", "OutdoorAmbient", "ExposureCompensation" },
    Atmosphere = { "Density", "Offset", "Color", "Decay", "Glare", "Haze" },
    Clouds = { "Cover", "Density", "Color" },
    Grade = { "TintColor", "Saturation", "Contrast", "Brightness" },
    Bloom = { "Intensity", "Size", "Threshold" },
    SunRays = { "Intensity", "Spread" },
}

local Environment = { Targets = {}, Original = {}, Created = {} }

local function captureEnvironment()
    local targets = Environment.Targets
    targets.Lighting = Lighting

    targets.Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not targets.Atmosphere then
        targets.Atmosphere = create("Atmosphere", { Density = 0, Haze = 0, Glare = 0, Parent = Lighting })
        table.insert(Environment.Created, targets.Atmosphere)
    end

    targets.Clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
    if not targets.Clouds then
        targets.Clouds = create("Clouds", { Cover = 0, Density = 0, Parent = workspace.Terrain })
        table.insert(Environment.Created, targets.Clouds)
    end

    targets.Grade = create("ColorCorrectionEffect", { Name = "WeatherGrade", Parent = Lighting })
    targets.Bloom = create("BloomEffect", { Name = "WeatherBloom", Intensity = 0, Size = 24, Threshold = 2, Parent = Lighting })
    targets.SunRays = create("SunRaysEffect", { Name = "WeatherSunRays", Intensity = 0, Spread = 1, Parent = Lighting })
    for _, key in { "Grade", "Bloom", "SunRays" } do
        table.insert(Environment.Created, targets[key])
    end

    for group, props in EnvironmentProps do
        Environment.Original[group] = {}
        for _, prop in props do
            Environment.Original[group][prop] = targets[group][prop]
        end
    end
end

local function worldOwnsAtmosphere()
    local world = env.World
    return type(world) == "table" and type(world.Config) == "table" and world.Config.Fog == true
end

local function applyEnvironment(preset, instant)
    for group, props in EnvironmentProps do

        if group == "Atmosphere" and worldOwnsAtmosphere() then
            continue
        end
        local values = {}
        for _, prop in props do
            local value = preset and preset[group] and preset[group][prop]
            if value == nil or not Config.ChangeEnvironment and group ~= "Grade" then
                value = Environment.Original[group][prop]
            end
            values[prop] = value
        end

        local target = Environment.Targets[group]
        if not target then
            continue
        end
        if instant then
            for prop, value in values do
                target[prop] = value
            end
        else
            TweenService:Create(target, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Sine), values):Play()
        end
    end
end

local function restoreEnvironment()
    applyEnvironment(nil, true)
    for _, instance in Environment.Created do
        instance:Destroy()
    end
end

local function mode(name, environment, build)
    Modes[name] = { Name = name, Environment = environment, Build = build }
    table.insert(ModeOrder, name)
end

local twinkle = numberSequence({ { 0, 0 }, { 0.15, 1 }, { 0.3, 0.4 }, { 0.5, 1 }, { 0.7, 0.3 }, { 0.85, 0.9 }, { 1, 0 } })
local blink = numberSequence({
    { 0, 0 }, { 0.08, 1 }, { 0.16, 0.1 }, { 0.32, 0.1 }, { 0.4, 1 }, { 0.48, 0.1 },
    { 0.64, 0.1 }, { 0.72, 1 }, { 0.8, 0.1 }, { 1, 0 },
})
local flutter = numberSequence({ { 0, 0 }, { 0.2, 0.6 }, { 0.4, -0.5 }, { 0.6, 0.6 }, { 0.8, -0.5 }, { 1, 0 } })

local function scaled(sequence, size)
    local keypoints = {}
    for _, keypoint in sequence.Keypoints do
        table.insert(keypoints, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * size))
    end
    return NumberSequence.new(keypoints)
end

local function popSize(size)
    return numberSequence({ { 0, 0 }, { 0.06, size }, { 0.9, size * 1.05 }, { 0.96, size * 1.3 }, { 1, size * 1.45 } })
end
local popTransparency = numberSequence({ { 0, 1 }, { 0.06, 0 }, { 0.9, 0 }, { 0.96, 0.45 }, { 1, 1 } })

local function nearField(m, opts)
    opts = opts or {}
    local texture = opts.Texture or Textures.soft
    local color = opts.Color or Color3.new(1, 1, 1)
    local hazeColor = opts.HazeColor or color
    local rate = opts.Rate or 55
    local size = opts.Size or 0.28
    local transparency = opts.Transparency or 0.35
    local wind = opts.Wind or 0.8

    m.Emit(NearGround, {
        Texture = texture,
        EmissionDirection = Enum.NormalId.Top,
        Rate = rate,
        Lifetime = NumberRange.new(1.1, 1.8),
        Speed = NumberRange.new(1.2, 3.2),
        SpreadAngle = Vector2.new(55, 55),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-40, 40),
        Size = NumberSequence.new(size),
        Transparency = numberSequence({ { 0, 1 }, { 0.12, transparency }, { 0.85, transparency + 0.15 }, { 1, 1 } }),
        Color = ColorSequence.new(color),
        LightEmission = opts.LightEmission or 0.15,
        LightInfluence = opts.LightInfluence or 0.55,
        Brightness = opts.Brightness or 1.2,
    }, wind)

    m.Emit(Lens, {
        Texture = texture,
        EmissionDirection = Enum.NormalId.Front,
        Rate = math.max(12, math.floor(rate * 0.45)),
        Lifetime = NumberRange.new(0.7, 1.3),
        Speed = NumberRange.new(1.5, 4),
        SpreadAngle = Vector2.new(70, 70),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-50, 50),
        Size = NumberSequence.new(size * 1.15),
        Transparency = numberSequence({ { 0, 1 }, { 0.15, transparency + 0.05 }, { 0.85, transparency + 0.2 }, { 1, 1 } }),
        Color = ColorSequence.new(color),
        LightEmission = opts.LightEmission or 0.2,
        LightInfluence = opts.LightInfluence or 0.45,
        Brightness = opts.Brightness or 1.3,
    }, wind)

    if opts.Haze ~= false then
        m.Emit(NearGround, {
            Texture = Textures.haze,
            EmissionDirection = Enum.NormalId.Top,
            Rate = opts.HazeRate or 10,
            Lifetime = NumberRange.new(2.5, 4),
            Speed = NumberRange.new(0.3, 0.9),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-8, 8),
            Size = numberSequence({ { 0, 6 }, { 1, 12 } }),
            Transparency = numberSequence({ { 0, 1 }, { 0.2, 0.78 }, { 0.8, 0.82 }, { 1, 1 } }),
            Color = ColorSequence.new(hazeColor),
            LightEmission = 0,
            LightInfluence = 0.7,
        }, wind * 0.5)
    end
end

local function groundMist(m, color, transparency, rate)
    m.Emit(Ground, {
        Texture = Textures.haze,
        EmissionDirection = Enum.NormalId.Top,
        Rate = rate or 8,
        Lifetime = NumberRange.new(7, 10),
        Speed = NumberRange.new(0.2, 0.6),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-6, 6),
        Size = numberSequence({ { 0, 10 }, { 1, 18 } }),
        Transparency = numberSequence({ { 0, 1 }, { 0.3, transparency }, { 0.7, transparency }, { 1, 1 } }),
        Color = ColorSequence.new(color),
        LightEmission = 0,
        LightInfluence = 0.8,
    }, 0.4)
end

local function starDome(m, rate, brightness, colors)
    local distance = modeStarDistance(m.Name)
    local scale = math.clamp(distance / 220, 0.45, 1.1)

    Dome.Size = Vector3.one * distance * 2
    for _, color in colors do
        local emitter = m.Emit(Dome, {
            Texture = Textures.star,
            LockedToPart = true,
            Shape = Enum.ParticleEmitterShape.Sphere,
            ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
            Rate = math.min(rate, 28),
            Lifetime = NumberRange.new(5, 9),
            Speed = NumberRange.new(0),
            Rotation = NumberRange.new(0, 90),
            Size = scaled(twinkle, rng:NextNumber(2.2, 3.0) * scale),
            Color = ColorSequence.new(color),
            LightEmission = 1,
            LightInfluence = 0,
            Brightness = math.min(brightness, 2.2),
        })
        emitter:Emit(math.min(math.floor(emitter.Rate * 1.5), 24))
    end
end

local function falling(fall, drag)
    return Vector3.new(0, -fall, 0), drag
end

mode("Snow", {
    Lighting = { ClockTime = 13.5, Brightness = 1.6, Ambient = rgb(120, 125, 135), OutdoorAmbient = rgb(150, 160, 175), ExposureCompensation = 0.15 },
    Atmosphere = { Density = 0.42, Offset = 0.15, Color = rgb(205, 215, 230), Decay = rgb(160, 175, 200), Glare = 0, Haze = 2.4 },
    Clouds = { Cover = 0.85, Density = 0.55, Color = rgb(225, 230, 240) },
    Grade = { TintColor = rgb(230, 238, 255), Saturation = -0.2, Contrast = 0.05, Brightness = 0.02 },
    Bloom = { Intensity = 0.4, Size = 30, Threshold = 1.6 },
}, function(m)
    local gravity, drag = falling(0.7, 0.2)
    for i = 1, 3 do
        m.Emit(Sky, {
            Texture = Textures[`flake{i}`],
            EmissionDirection = Enum.NormalId.Bottom,
            Rate = 70,
            Lifetime = m.Fall(2.6, 3.5),
            Speed = NumberRange.new(2.6, 3.5),
            Acceleration = gravity,
            Drag = drag,
            SpreadAngle = Vector2.new(15, 15),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-40, 40),
            Size = NumberSequence.new(0.35 + i * 0.08),
            Transparency = numberSequence({ { 0, 1 }, { 0.05, 0.1 }, { 0.9, 0.2 }, { 1, 1 } }),
            Color = ColorSequence.new(m.C("Flakes")),
            LightEmission = 0.4,
            LightInfluence = 0.15,
            Brightness = 1.6,
        }, 1)
    end
    m.Emit(Sky, {
        Texture = Textures.soft,
        EmissionDirection = Enum.NormalId.Bottom,
        Rate = 450,
        Lifetime = m.Fall(3, 4),
        Speed = NumberRange.new(3, 4),
        Acceleration = Vector3.new(0, -0.8, 0),
        Drag = 0.2,
        SpreadAngle = Vector2.new(10, 10),
        Size = NumberSequence.new(0.14),
        Transparency = numberSequence({ { 0, 1 }, { 0.05, 0.25 }, { 0.9, 0.35 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Dust")),
        LightEmission = 0.3,
        LightInfluence = 0.15,
        Brightness = 1.4,
    }, 1.2)

    m.Emit(Lens, {
        Texture = Textures.soft,
        EmissionDirection = Enum.NormalId.Bottom,
        Rate = 35,
        Lifetime = NumberRange.new(5, 7),
        Speed = NumberRange.new(1.5, 2.5),
        SpreadAngle = Vector2.new(20, 20),
        Size = NumberSequence.new(0.4),
        Transparency = numberSequence({ { 0, 1 }, { 0.15, 0.45 }, { 0.85, 0.5 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Flakes")),
        LightEmission = 0.3,
        LightInfluence = 0.2,
        Brightness = 1.2,
    }, 1)
    nearField(m, {
        Texture = Textures.flake1,
        Color = m.C("Flakes"),
        HazeColor = m.C("Mist"),
        Rate = 70,
        Size = 0.32,
        Transparency = 0.28,
        Wind = 1,
    })
    groundMist(m, m.C("Mist"), 0.85, 6)
end)

mode("Stars", {
    Lighting = { ClockTime = 0.3, Brightness = 1, Ambient = rgb(70, 72, 110), OutdoorAmbient = rgb(90, 95, 140), ExposureCompensation = 0.35 },
    Atmosphere = { Density = 0.1, Offset = 0, Color = rgb(80, 90, 140), Decay = rgb(40, 40, 80), Glare = 0, Haze = 0.3 },
    Clouds = { Cover = 0.15, Density = 0.1, Color = rgb(90, 95, 130) },
    Grade = { TintColor = rgb(225, 225, 255), Saturation = 0.15, Contrast = 0.06, Brightness = 0.03 },
    Bloom = { Intensity = 0.35, Size = 18, Threshold = 1.15 },
}, function(m)
    starDome(m, 24, 2.2, { m.C("Star1"), m.C("Star2"), m.C("Star3") })
    m.Emit(Volume, {
        Texture = Textures.star,
        EmissionDirection = Enum.NormalId.Bottom,
        Rate = 28,
        Lifetime = NumberRange.new(6, 10),
        Speed = NumberRange.new(0.4, 1.4),
        SpreadAngle = Vector2.new(30, 30),
        RotSpeed = NumberRange.new(-30, 30),
        Size = scaled(twinkle, 0.55),
        Color = colorSequence({ { 0, m.C("Dust") }, { 1, m.C("DustFade") } }),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 2,
    }, 0.4)

    local auroraAnchor = newPart("Aurora", Vector3.one, m.Folder)
    local radius = modeStarDistance(m.Name) * 0.55
    local span = math.rad(50)
    local green, cyan, violet = m.C("AuroraGreen"), m.C("AuroraCyan"), m.C("AuroraViolet")
    local palettes = {
        { green, cyan, green },
        { cyan, violet, cyan },
    }
    local curtains = {}
    for i, colors in palettes do
        local start = (i - 1) / #palettes * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
        local height = rng:NextNumber(55, 95)
        local function ringPoint(angle, y)
            return Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
        end
        local function tangent(angle)
            return Vector3.new(-math.sin(angle), 0, math.cos(angle))
        end
        local a0 = create("Attachment", { Position = ringPoint(start, height), Axis = tangent(start), Parent = auroraAnchor })
        local a1 = create("Attachment", { Position = ringPoint(start + span, height + rng:NextNumber(-12, 12)), Axis = tangent(start + span), Parent = auroraAnchor })
        local width = rng:NextNumber(48, 72)
        local beam = create("Beam", {
            Attachment0 = a0,
            Attachment1 = a1,
            Texture = Textures.aurora,
            TextureMode = Enum.TextureMode.Wrap,
            TextureLength = 140,
            TextureSpeed = rng:NextNumber(0.12, 0.28) * (rng:NextNumber() < 0.5 and -1 or 1),
            Width0 = width,
            Width1 = width * rng:NextNumber(0.75, 1.05),
            Segments = 8,
            FaceCamera = true,
            Color = colorSequence({ { 0, colors[1] }, { 0.5, colors[2] }, { 1, colors[3] } }),
            Transparency = numberSequence({ { 0, 1 }, { 0.2, 0.35 }, { 0.8, 0.35 }, { 1, 1 } }),
            LightEmission = 1,
            LightInfluence = 0,
            Brightness = 1.4,
            Parent = auroraAnchor,
        })

        local handle = radius * 4 / 3 * math.tan(span / 4)
        curtains[i] = { Beam = beam, Handle = handle, Phase = i * 1.3 }
    end

    local comets, nextAt, lastAurora = {}, 0, 0
    m.Update = function(t, dt)
        auroraAnchor.CFrame = CFrame.new(focusPosition())
        if t - lastAurora >= 0.12 then
            lastAurora = t
            for _, curtain in curtains do
                curtain.Beam.CurveSize0 = curtain.Handle * (1 + 0.25 * math.sin(t * 0.17 + curtain.Phase))
                curtain.Beam.CurveSize1 = curtain.Handle * (1 + 0.25 * math.cos(t * 0.13 + curtain.Phase))
            end
        end

        if t >= nextAt and #comets < 2 then
            local cometRate = math.max(paramOf(m.Name, "CometRate", 1), 0.1)
            nextAt = t + rng:NextNumber(2.2, 4.8) / cometRate
            local center = focusPosition()
            local area = activeRadius(m.Name)
            local angle = rng:NextNumber(0, math.pi * 2)
            local direction = Vector3.new(math.cos(angle), rng:NextNumber(-0.35, -0.15), math.sin(angle)).Unit
            local start = center + Vector3.new(rng:NextNumber(-area, area), m.Height + rng:NextNumber(30, 60), rng:NextNumber(-area, area))
                - direction * 40

            local part = newPart("ShootingStar", Vector3.new(0.2, 0.2, 0.2), m.Folder)
            part.CFrame = CFrame.new(start)
            local a0 = create("Attachment", { Position = Vector3.new(0, 0.35, 0), Parent = part })
            local a1 = create("Attachment", { Position = Vector3.new(0, -0.35, 0), Parent = part })
            create("Trail", {
                Attachment0 = a0,
                Attachment1 = a1,
                Texture = Textures.streak,
                TextureMode = Enum.TextureMode.Stretch,
                Lifetime = 0.3,
                FaceCamera = true,
                WidthScale = numberSequence({ { 0, 1 }, { 1, 0 } }),
                Transparency = numberSequence({ { 0, 0 }, { 1, 1 } }),
                Color = colorSequence({ { 0, m.C("Comet") }, { 1, m.C("CometTail") } }),
                LightEmission = 1,
                LightInfluence = 0,
                Brightness = 2.2,
                MaxLength = 60,
                Parent = part,
            })
            table.insert(comets, { Part = part, Velocity = direction * rng:NextNumber(70, 110), Born = t })
        end

        for i = #comets, 1, -1 do
            local comet = comets[i]
            if t - comet.Born > 1.2 then
                comet.Part:Destroy()
                table.remove(comets, i)
            else
                comet.Part.CFrame += comet.Velocity * dt
            end
        end
    end

    nearField(m, {
        Texture = Textures.star,
        Color = m.C("Dust"),
        HazeColor = m.C("DustFade"),
        Rate = 40,
        Size = 0.2,
        Transparency = 0.25,
        Wind = 0.25,
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 4,
        HazeRate = 4,
    })
end)

local function boltPath(from, to, segments, jitter)
    local points = { from }
    for i = 1, segments - 1 do
        local alpha = i / segments
        local offset = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.3, 0.3), rng:NextNumber(-1, 1))
        table.insert(points, from:Lerp(to, alpha) + offset * jitter * (0.4 + math.sin(alpha * math.pi)))
    end
    table.insert(points, to)
    return points
end

local function boltSegments(folder, points, width, color, parts)
    for i = 1, #points - 1 do
        local a, b = points[i], points[i + 1]
        table.insert(parts, create("Part", {
            Name = "Bolt",
            Anchored = true,
            CanCollide = false,
            CanQuery = false,
            CanTouch = false,
            CastShadow = false,
            Material = Enum.Material.Neon,
            Color = color,
            Size = Vector3.new(width, width, (b - a).Magnitude + width * 0.5),
            CFrame = CFrame.lookAt((a + b) / 2, b),
            Parent = folder,
        }))
    end
end

local function strike(m)
    local center = focusPosition()
    local angle = rng:NextNumber(0, math.pi * 2)
    local distance = rng:NextNumber(30, activeRadius(m.Name) * 0.9)
    local impact = groundBelow(center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * distance, center.Y - 3)
    local top = impact + Vector3.new(rng:NextNumber(-25, 25), 160, rng:NextNumber(-25, 25))

    local folder = create("Folder", { Name = "Strike", Parent = m.Folder })
    local parts = {}
    local color = m.C("Lightning")
    local main = boltPath(top, impact, 22, 10)
    boltSegments(folder, main, 0.55, color, parts)
    for _ = 1, rng:NextInteger(3, 6) do
        local index = rng:NextInteger(3, 14)
        local origin = main[index]
        local direction = ((main[index + 1] - origin).Unit + Vector3.new(rng:NextNumber(-1, 1), -0.4, rng:NextNumber(-1, 1))).Unit
        boltSegments(folder, boltPath(origin, origin + direction * rng:NextNumber(15, 40), 8, 4), 0.25, color, parts)
    end

    local light = create("PointLight", { Color = m.C("LightningGlow"), Range = 60, Brightness = 0, Shadows = true, Parent = parts[#main - 1] })
    local grade = Environment.Targets.Grade
    local baseBrightness = m.Environment.Grade.Brightness

    task.spawn(function()
        for _, step in { { 0, 0.05 }, { 1, 0.06 }, { 0, 0.12 } } do
            for _, part in parts do
                part.Transparency = step[1]
            end
            light.Brightness = step[1] == 0 and 10 or 0
            grade.Brightness = baseBrightness + (step[1] == 0 and 0.45 or 0.1)
            task.wait(step[2])
        end
        local start = os.clock()
        while os.clock() - start < 0.35 do
            local p = (os.clock() - start) / 0.35
            for _, part in parts do
                part.Transparency = p
            end
            light.Brightness = 10 * (1 - p)
            grade.Brightness = baseBrightness + 0.45 * (1 - p) ^ 2
            task.wait()
        end
        grade.Brightness = baseBrightness
        folder:Destroy()
    end)
end

mode("Rain", {
    Lighting = { ClockTime = 17.2, Brightness = 0.9, Ambient = rgb(70, 75, 85), OutdoorAmbient = rgb(85, 92, 105), ExposureCompensation = -0.1 },
    Atmosphere = { Density = 0.5, Offset = 0.2, Color = rgb(125, 135, 150), Decay = rgb(70, 80, 95), Glare = 0, Haze = 3 },
    Clouds = { Cover = 0.97, Density = 0.95, Color = rgb(70, 75, 85) },
    Grade = { TintColor = rgb(205, 215, 235), Saturation = -0.3, Contrast = 0.08, Brightness = -0.02 },
    Bloom = { Intensity = 0.5, Size = 30, Threshold = 1.3 },
}, function(m)
    local speed = 38

    local function rain(parent, rate, height, size, transparency)
        m.Emit(parent, {
            Texture = Textures.raindrop,
            Orientation = Enum.ParticleOrientation.VelocityParallel,
            EmissionDirection = Enum.NormalId.Bottom,
            Rate = rate,
            Lifetime = NumberRange.new(height / speed, height / speed * 1.05),
            Speed = NumberRange.new(speed * 0.95, speed),
            SpreadAngle = Vector2.zero,
            Size = NumberSequence.new(size),
            Transparency = NumberSequence.new(transparency),
            Color = ColorSequence.new(m.C("Drops")),
            LightEmission = 0.4,
            LightInfluence = 0.3,
            Brightness = 1.8,
        })
    end

    rain(Sky, 700, m.Height, 1.6, 0.4)
    rain(Sky, 350, m.Height, 2.2, 0.5)
    rain(NearSky, 650, m.Height, 1.5, 0.35)
    rain(Lens, 180, Lens.Size.Y, 0.8, 0.6)

    m.Emit(Sky, {
        Texture = Textures.rainsheet,
        Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
        EmissionDirection = Enum.NormalId.Bottom,
        Rate = 5,
        Lifetime = NumberRange.new(m.Height / 16, m.Height / 14),
        Speed = NumberRange.new(14, 16),
        Size = NumberSequence.new(m.Height * 0.9),
        Transparency = numberSequence({ { 0, 1 }, { 0.2, 0.82 }, { 0.8, 0.82 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Veil")),
        LightEmission = 0.1,
        LightInfluence = 0.6,
    })

    m.Emit(NearGround, {
        Texture = Textures.splash,
        FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2,
        FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
        Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
        EmissionDirection = Enum.NormalId.Top,
        Rate = 140,
        Lifetime = NumberRange.new(0.35, 0.45),
        Speed = NumberRange.new(0.01),
        Size = NumberSequence.new(0.7),
        Transparency = numberSequence({ { 0, 0.45 }, { 1, 0.85 } }),
        Color = ColorSequence.new(m.C("Splash")),
        LightEmission = 0.3,
        LightInfluence = 0.4,
        Brightness = 1.5,
    })
    m.Emit(NearGround, {
        Texture = Textures.soft,
        EmissionDirection = Enum.NormalId.Top,
        Rate = 220,
        Lifetime = NumberRange.new(0.2, 0.32),
        Speed = NumberRange.new(3, 6),
        SpreadAngle = Vector2.new(35, 35),
        Acceleration = Vector3.new(0, -45, 0),
        Size = numberSequence({ { 0, 0.07 }, { 1, 0.04 } }),
        Transparency = numberSequence({ { 0, 0.3 }, { 1, 0.8 } }),
        Color = ColorSequence.new(m.C("Droplets")),
        LightEmission = 0.4,
        LightInfluence = 0.4,
        Brightness = 1.6,
    })
    nearField(m, {
        Texture = Textures.raindrop,
        Color = m.C("Drops"),
        HazeColor = m.C("Mist"),
        Rate = 90,
        Size = 0.22,
        Transparency = 0.4,
        Wind = 0.2,
        LightEmission = 0.35,
    })
    groundMist(m, m.C("Mist"), 0.82, 10)

    local nextStrike = rng:NextNumber(3, 6)
    m.Update = function(t)
        if t >= nextStrike then
            nextStrike = t + rng:NextNumber(5, 12)
            strike(m)
            if rng:NextNumber() < 0.35 then
                task.delay(rng:NextNumber(0.3, 0.8), strike, m)
            end
        end
    end
end)

mode("Ash", {
    Lighting = { ClockTime = 18.1, Brightness = 1.2, Ambient = rgb(95, 65, 55), OutdoorAmbient = rgb(120, 80, 60), ExposureCompensation = 0 },
    Atmosphere = { Density = 0.55, Offset = 0.25, Color = rgb(170, 100, 65), Decay = rgb(100, 40, 25), Glare = 1.5, Haze = 2.8 },
    Clouds = { Cover = 0.85, Density = 0.8, Color = rgb(95, 60, 50) },
    Grade = { TintColor = rgb(255, 215, 190), Saturation = -0.15, Contrast = 0.12, Brightness = -0.02 },
    Bloom = { Intensity = 0.8, Size = 35, Threshold = 1.1 },
    SunRays = { Intensity = 0.12, Spread = 0.6 },
}, function(m)
    local gravity, drag = falling(0.75, 0.3)
    for i = 1, 3 do
        m.Emit(Sky, {
            Texture = Textures[`ash{i}`],
            EmissionDirection = Enum.NormalId.Bottom,
            Rate = 80,
            Lifetime = m.Fall(1.9, 2.5),
            Speed = NumberRange.new(2, 2.5),
            Acceleration = gravity,
            Drag = drag,
            SpreadAngle = Vector2.new(25, 25),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-90, 90),
            Squash = flutter,
            Size = NumberSequence.new(0.25 + i * 0.07),
            Transparency = numberSequence({ { 0, 1 }, { 0.05, 0.1 }, { 0.9, 0.2 }, { 1, 1 } }),
            Color = ColorSequence.new(m.C("Ash")),
            LightEmission = 0,
            LightInfluence = 1,
        }, 1.5)
    end
    m.Emit(Ground, {
        Texture = Textures.ember,
        EmissionDirection = Enum.NormalId.Top,
        Rate = 90,
        Lifetime = NumberRange.new(3, 6),
        Speed = NumberRange.new(2, 5),
        SpreadAngle = Vector2.new(25, 25),
        Acceleration = Vector3.new(0, 1.5, 0),
        Size = numberSequence({ { 0, 0.18 }, { 0.6, 0.12 }, { 1, 0 } }),
        Transparency = numberSequence({ { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } }),
        Color = colorSequence({ { 0, m.C("EmberHot") }, { 0.5, m.C("EmberMid") }, { 1, m.C("EmberCool") } }),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 5,
    }, 1)
    m.Emit(Lens, {
        Texture = Textures.ash1,
        EmissionDirection = Enum.NormalId.Bottom,
        Rate = 12,
        Lifetime = NumberRange.new(5, 7),
        Speed = NumberRange.new(1, 2),
        SpreadAngle = Vector2.new(30, 30),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-90, 90),
        Size = NumberSequence.new(0.5),
        Transparency = numberSequence({ { 0, 1 }, { 0.15, 0.3 }, { 0.85, 0.35 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Ash"):Lerp(Color3.new(0, 0, 0), 0.2)),
        LightEmission = 0,
        LightInfluence = 1,
    }, 1.5)
    nearField(m, {
        Texture = Textures.ash1,
        Color = m.C("Ash"),
        HazeColor = m.C("Mist"),
        Rate = 65,
        Size = 0.26,
        Transparency = 0.3,
        Wind = 1.4,
        LightEmission = 0.05,
    })
    groundMist(m, m.C("Mist"), 0.8, 8)
end)

mode("Spring", {
    Lighting = { ClockTime = 9.2, Brightness = 2.4, Ambient = rgb(130, 120, 125), OutdoorAmbient = rgb(165, 155, 160), ExposureCompensation = 0.2 },
    Atmosphere = { Density = 0.3, Offset = 0.1, Color = rgb(255, 230, 235), Decay = rgb(205, 185, 220), Glare = 0.6, Haze = 1.6 },
    Clouds = { Cover = 0.5, Density = 0.3, Color = rgb(255, 250, 250) },
    Grade = { TintColor = rgb(255, 245, 242), Saturation = 0.18, Contrast = 0.04, Brightness = 0.02 },
    Bloom = { Intensity = 0.6, Size = 40, Threshold = 1.2 },
    SunRays = { Intensity = 0.15, Spread = 0.5 },
}, function(m)
    local gravity, drag = falling(0.9, 0.3)
    for i = 1, 3 do
        m.Emit(Sky, {
            Texture = Textures[`petal{i}`],
            EmissionDirection = Enum.NormalId.Bottom,
            Rate = 50,
            Lifetime = m.Fall(2.3, 3),
            Speed = NumberRange.new(2.3, 3),
            Acceleration = gravity,
            Drag = drag,
            SpreadAngle = Vector2.new(30, 30),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-120, 120),
            Squash = flutter,
            Size = NumberSequence.new(0.35 + i * 0.05),
            Transparency = numberSequence({ { 0, 1 }, { 0.05, 0 }, { 0.92, 0.1 }, { 1, 1 } }),
            Color = ColorSequence.new(m.C(`Petal{i}`)),
            LightEmission = 0.2,
            LightInfluence = 0.3,
            Brightness = 1.4,
        }, 2.5)
    end
    m.Emit(Volume, {
        Texture = Textures.soft,
        Rate = 70,
        Lifetime = NumberRange.new(5, 8),
        Speed = NumberRange.new(0.2, 0.6),
        SpreadAngle = Vector2.new(180, 180),
        Size = scaled(twinkle, 0.18),
        Color = ColorSequence.new(m.C("Pollen")),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 2.5,
    }, 0.6)
    for i = 1, 3 do
        m.Emit(Volume, {
            Texture = Textures.butterfly,
            FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2,
            FlipbookMode = Enum.ParticleFlipbookMode.Loop,
            FlipbookFramerate = NumberRange.new(10, 16),
            FlipbookStartRandom = true,
            Rate = 2,
            Lifetime = NumberRange.new(8, 12),
            Speed = NumberRange.new(1.5, 3),
            SpreadAngle = Vector2.new(180, 180),
            Rotation = NumberRange.new(-25, 25),
            Size = numberSequence({ { 0, 0 }, { 0.05, 0.7 }, { 0.95, 0.7 }, { 1, 0 } }),
            Color = ColorSequence.new(m.C(`Butterfly{i}`)),
            LightEmission = 0.3,
            LightInfluence = 0.3,
            Brightness = 1.5,
        }, 0.3)
    end
    m.Emit(Lens, {
        Texture = Textures.petal1,
        EmissionDirection = Enum.NormalId.Bottom,
        Rate = 6,
        Lifetime = NumberRange.new(5, 7),
        Speed = NumberRange.new(1.5, 2.5),
        SpreadAngle = Vector2.new(30, 30),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-120, 120),
        Squash = flutter,
        Size = NumberSequence.new(0.5),
        Transparency = numberSequence({ { 0, 1 }, { 0.15, 0.2 }, { 0.85, 0.25 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Petal1")),
        LightEmission = 0.2,
        LightInfluence = 0.3,
        Brightness = 1.4,
    }, 2.5)
    nearField(m, {
        Texture = Textures.petal1,
        Color = m.C("Petal1"),
        HazeColor = m.C("Pollen"),
        Rate = 55,
        Size = 0.3,
        Transparency = 0.25,
        Wind = 0.9,
    })
end)

mode("Autumn", {
    Lighting = { ClockTime = 16.4, Brightness = 2, Ambient = rgb(125, 105, 90), OutdoorAmbient = rgb(160, 130, 105), ExposureCompensation = 0.1 },
    Atmosphere = { Density = 0.32, Offset = 0.1, Color = rgb(230, 190, 150), Decay = rgb(170, 120, 90), Glare = 0.8, Haze = 1.8 },
    Clouds = { Cover = 0.55, Density = 0.35, Color = rgb(255, 235, 215) },
    Grade = { TintColor = rgb(255, 238, 220), Saturation = 0.12, Contrast = 0.06, Brightness = 0.01 },
    Bloom = { Intensity = 0.5, Size = 35, Threshold = 1.3 },
    SunRays = { Intensity = 0.13, Spread = 0.6 },
}, function(m)
    local gravity, drag = falling(1, 0.35)
    local leaves = {
        { Texture = Textures.maple, Color = m.C("Maple"), Size = 0.65 },
        { Texture = Textures.maple, Color = m.C("Red"), Size = 0.55 },
        { Texture = Textures.oak, Color = m.C("Oak"), Size = 0.55 },
        { Texture = Textures.birch, Color = m.C("Birch"), Size = 0.45 },
    }
    for _, leaf in leaves do
        m.Emit(Sky, {
            Texture = leaf.Texture,
            EmissionDirection = Enum.NormalId.Bottom,
            Rate = 32,
            Lifetime = m.Fall(2.2, 2.9),
            Speed = NumberRange.new(2.2, 2.9),
            Acceleration = gravity,
            Drag = drag,
            SpreadAngle = Vector2.new(30, 30),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-150, 150),
            Squash = flutter,
            Size = NumberSequence.new(leaf.Size),
            Transparency = numberSequence({ { 0, 1 }, { 0.04, 0 }, { 0.94, 0 }, { 1, 1 } }),
            Color = ColorSequence.new(leaf.Color),
            LightEmission = 0,
            LightInfluence = 0.7,
            Brightness = 1.3,
        }, 3)
    end
    m.Emit(Lens, {
        Texture = Textures.maple,
        EmissionDirection = Enum.NormalId.Bottom,
        Rate = 4,
        Lifetime = NumberRange.new(5, 7),
        Speed = NumberRange.new(1.5, 2.5),
        SpreadAngle = Vector2.new(30, 30),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-150, 150),
        Squash = flutter,
        Size = NumberSequence.new(0.8),
        Transparency = numberSequence({ { 0, 1 }, { 0.15, 0.1 }, { 0.85, 0.15 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Maple")),
        LightEmission = 0,
        LightInfluence = 0.7,
    }, 3)
    m.Emit(Volume, {
        Texture = Textures.soft,
        Rate = 50,
        Lifetime = NumberRange.new(5, 8),
        Speed = NumberRange.new(0.2, 0.5),
        SpreadAngle = Vector2.new(180, 180),
        Size = scaled(twinkle, 0.12),
        Color = ColorSequence.new(m.C("Motes")),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 2,
    }, 0.6)
    nearField(m, {
        Texture = Textures.maple,
        Color = m.C("Maple"),
        HazeColor = m.C("Motes"),
        Rate = 50,
        Size = 0.34,
        Transparency = 0.22,
        Wind = 1.2,
    })
end)

mode("Fireflies", {
    Lighting = { ClockTime = 21.3, Brightness = 0.9, Ambient = rgb(55, 65, 80), OutdoorAmbient = rgb(75, 90, 105), ExposureCompensation = 0.4 },
    Atmosphere = { Density = 0.35, Offset = 0.05, Color = rgb(60, 80, 90), Decay = rgb(25, 35, 45), Glare = 0, Haze = 1.5 },
    Clouds = { Cover = 0.3, Density = 0.2, Color = rgb(70, 80, 95) },
    Grade = { TintColor = rgb(220, 240, 235), Saturation = 0.05, Contrast = 0.08, Brightness = 0 },
    Bloom = { Intensity = 1.1, Size = 30, Threshold = 0.9 },
}, function(m)
    starDome(m, 40, 3, { m.C("Stars") })

    local meadow = newPart("Meadow", Vector3.new(activeRadius(m.Name) * 1.4, m.Height, activeRadius(m.Name) * 1.4), m.Folder)
    meadow.CFrame = Ground.CFrame * CFrame.new(0, m.Height / 2, 0)
    for i = 1, 3 do
        m.Emit(meadow, {
            Texture = Textures.soft,
            Rate = 45,
            Lifetime = NumberRange.new(6, 10),
            Speed = NumberRange.new(0.3, 0.8),
            SpreadAngle = Vector2.new(180, 180),
            Size = scaled(blink, 0.3),
            Color = ColorSequence.new(m.C(`Firefly{i}`)),
            LightEmission = 1,
            LightInfluence = 0,
            Brightness = 6,
        }, 0.15)
    end
    m.Emit(Lens, {
        Texture = Textures.soft,
        Rate = 5,
        Lifetime = NumberRange.new(5, 8),
        Speed = NumberRange.new(0.2, 0.6),
        SpreadAngle = Vector2.new(180, 180),
        Size = scaled(blink, 0.6),
        Color = ColorSequence.new(m.C("Firefly1")),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 4,
    }, 0.15)
    nearField(m, {
        Texture = Textures.soft,
        Color = m.C("Firefly1"),
        HazeColor = m.C("Mist"),
        Rate = 35,
        Size = 0.22,
        Transparency = 0.2,
        Wind = 0.2,
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 4,
        HazeRate = 6,
    })
    groundMist(m, m.C("Mist"), 0.86, 8)

    m.Update = function()
        meadow.CFrame = Ground.CFrame * CFrame.new(0, m.Height / 2, 0)
    end
end)

mode("Sandstorm", {
    Lighting = { ClockTime = 14.8, Brightness = 2.2, Ambient = rgb(150, 120, 90), OutdoorAmbient = rgb(190, 150, 110), ExposureCompensation = 0.05 },
    Atmosphere = { Density = 0.62, Offset = 0.2, Color = rgb(215, 170, 120), Decay = rgb(180, 120, 70), Glare = 1.2, Haze = 3.2 },
    Clouds = { Cover = 0.75, Density = 0.6, Color = rgb(220, 180, 130) },
    Grade = { TintColor = rgb(255, 225, 190), Saturation = -0.1, Contrast = 0.08, Brightness = 0.02 },
    Bloom = { Intensity = 0.4, Size = 30, Threshold = 1.4 },
    SunRays = { Intensity = 0.08, Spread = 0.8 },
}, function(m)

    local size = math.clamp(activeRadius(m.Name), 40, 140) * 2
    local storm = newPart("Storm", Vector3.new(size, m.Height, size), m.Folder)
    local drift = newPart("Drift", Vector3.new(size * 0.55, 1.5, size * 0.55), m.Folder)
    local gusts = newPart("Gusts", Vector3.new(28, 14, 28), m.Folder)
    local body = newPart("Body", Vector3.new(22, 12, 22), m.Folder)

    local function sand(parent, rate, lifetime, speed, spread, grainSize, transparency, color)
        return m.Emit(parent, {
            Texture = Textures.grain,
            Orientation = Enum.ParticleOrientation.VelocityParallel,
            EmissionDirection = Enum.NormalId.Front,
            Rate = rate,
            Lifetime = lifetime,
            Speed = speed,
            SpreadAngle = Vector2.new(spread, spread),
            Size = NumberSequence.new(grainSize),
            Transparency = numberSequence({ { 0, 1 }, { 0.12, transparency }, { 0.88, transparency + 0.08 }, { 1, 1 } }),
            Color = ColorSequence.new(color),
            LightEmission = 0.1,
            LightInfluence = 0.8,
        })
    end
    local stormSand = sand(storm, 420, NumberRange.new(1.2, 1.8), NumberRange.new(26, 40), 8, 0.55, 0.42, m.C("Sand"))
    sand(gusts, 220, NumberRange.new(0.8, 1.2), NumberRange.new(24, 36), 7, 0.45, 0.38, m.C("Sand"))
    sand(drift, 180, NumberRange.new(1, 1.6), NumberRange.new(18, 28), 4, 0.4, 0.32, m.C("Drift"))
    sand(body, 260, NumberRange.new(0.7, 1.2), NumberRange.new(14, 26), 18, 0.35, 0.3, m.C("Sand"))
    m.Emit(storm, {
        Texture = Textures.haze,
        EmissionDirection = Enum.NormalId.Front,
        Rate = 22,
        Lifetime = NumberRange.new(2.5, 4),
        Speed = NumberRange.new(12, 20),
        SpreadAngle = Vector2.new(12, 12),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-20, 20),
        Size = numberSequence({ { 0, 10 }, { 1, 18 } }),
        Transparency = numberSequence({ { 0, 1 }, { 0.2, 0.72 }, { 0.8, 0.72 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Dust")),
        LightEmission = 0,
        LightInfluence = 0.8,
    })
    nearField(m, {
        Texture = Textures.grain,
        Color = m.C("Sand"),
        HazeColor = m.C("Dust"),
        Rate = 140,
        Size = 0.38,
        Transparency = 0.28,
        Wind = 2,
        HazeRate = 16,
    })

    m.Update = function(t)
        local direction = windDirection(m.Name)
        if direction.Magnitude < 1e-3 then
            direction = Vector3.xAxis
        end
        local base = Ground.Position
        local mid = base + Vector3.new(0, m.Height / 2, 0)
        local cam = workspace.CurrentCamera
        local camera = (cam and cam.CFrame.Position) or mid
        storm.CFrame = CFrame.lookAt(mid, mid + direction) * CFrame.new(0, 0, size * 0.18)
        drift.CFrame = CFrame.lookAt(base + Vector3.new(0, 0.8, 0), base + Vector3.new(0, 0.8, 0) + direction)
        gusts.CFrame = CFrame.lookAt(camera, camera + direction) * CFrame.new(0, 0, 8)
        body.CFrame = CFrame.lookAt(base + Vector3.new(0, 5, 0), base + Vector3.new(0, 5, 0) + direction)
        if stormSand and stormSand.Parent then
            stormSand.TimeScale = 1 + 0.25 * math.sin(t * 0.8) + 0.1 * math.sin(t * 2.3)
        end
    end
end)

mode("Pestilence", {
    Lighting = { ClockTime = 17.8, Brightness = 1, Ambient = rgb(85, 95, 60), OutdoorAmbient = rgb(105, 115, 70), ExposureCompensation = -0.05 },
    Atmosphere = { Density = 0.55, Offset = 0.2, Color = rgb(140, 160, 90), Decay = rgb(80, 90, 40), Glare = 0.3, Haze = 2.6 },
    Clouds = { Cover = 0.9, Density = 0.75, Color = rgb(110, 120, 80) },
    Grade = { TintColor = rgb(220, 240, 190), Saturation = -0.35, Contrast = 0.15, Brightness = -0.03 },
    Bloom = { Intensity = 0.6, Size = 30, Threshold = 1.15 },
}, function(m)
    local gravity, drag = falling(0.6, 0.3)
    for i = 1, 3 do
        m.Emit(Sky, {
            Texture = Textures[`ash{i}`],
            EmissionDirection = Enum.NormalId.Bottom,
            Rate = 45,
            Lifetime = m.Fall(1.6, 2.1),
            Speed = NumberRange.new(1.6, 2.1),
            Acceleration = gravity,
            Drag = drag,
            SpreadAngle = Vector2.new(30, 30),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-70, 70),
            Squash = flutter,
            Size = NumberSequence.new(0.2 + i * 0.06),
            Transparency = numberSequence({ { 0, 1 }, { 0.05, 0.15 }, { 0.9, 0.25 }, { 1, 1 } }),
            Color = ColorSequence.new(m.C("Blight")),
            LightEmission = 0,
            LightInfluence = 1,
        }, 1.2)
    end

    m.Emit(Volume, {
        Texture = Textures.soft,
        EmissionDirection = Enum.NormalId.Top,
        Rate = 90,
        Lifetime = NumberRange.new(5, 9),
        Speed = NumberRange.new(0.3, 0.9),
        SpreadAngle = Vector2.new(60, 60),
        Acceleration = Vector3.new(0, 0.15, 0),
        Size = scaled(twinkle, 0.22),
        Color = colorSequence({ { 0, m.C("Spores") }, { 1, m.C("SporeFade") } }),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 3,
    }, 0.5)

    m.Emit(NearGround, {
        Texture = Textures.bubble,
        EmissionDirection = Enum.NormalId.Top,
        Rate = 25,
        Lifetime = NumberRange.new(1.2, 2),
        Speed = NumberRange.new(0.4, 1.2),
        SpreadAngle = Vector2.new(20, 20),
        Size = popSize(0.35),
        Transparency = popTransparency,
        Color = ColorSequence.new(m.C("Toxic")),
        LightEmission = 0.5,
        LightInfluence = 0.3,
        Brightness = 1.6,
    })

    groundMist(m, m.C("Miasma"), 0.72, 14)
    m.Emit(Volume, {
        Texture = Textures.haze,
        Rate = 6,
        Lifetime = NumberRange.new(8, 12),
        Speed = NumberRange.new(0.3, 0.8),
        SpreadAngle = Vector2.new(180, 20),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-5, 5),
        Size = numberSequence({ { 0, 14 }, { 1, 24 } }),
        Transparency = numberSequence({ { 0, 1 }, { 0.3, 0.8 }, { 0.7, 0.8 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Toxic")),
        LightEmission = 0.15,
        LightInfluence = 0.6,
    }, 0.4)
    nearField(m, {
        Texture = Textures.fly,
        Color = m.C("Flies"),
        HazeColor = m.C("Miasma"),
        Rate = 70,
        Size = 0.16,
        Transparency = 0.2,
        Wind = 0.8,
        HazeRate = 12,
    })

    local swarms = {}
    local function newHome()
        local angle = rng:NextNumber(0, math.pi * 2)
        local distance = rng:NextNumber(6, 45)
        return Vector3.new(math.cos(angle) * distance, rng:NextNumber(1, 5), math.sin(angle) * distance)
    end
    for i = 1, 7 do
        local home = newHome()
        local anchor = newPart("Swarm", Vector3.new(1.5, 1.5, 1.5), m.Folder)
        anchor.CFrame = CFrame.new(Ground.Position + home)
        m.Emit(anchor, {
            Texture = Textures.fly,
            Rate = 55,
            Lifetime = NumberRange.new(1, 1.8),
            Speed = NumberRange.new(3, 6),
            SpreadAngle = Vector2.new(180, 180),
            Drag = 4,
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-400, 400),
            Size = numberSequence({ { 0, 0 }, { 0.1, 0.16 }, { 0.9, 0.16 }, { 1, 0 } }),
            Color = ColorSequence.new(m.C("Flies")),
            LightEmission = 0,
            LightInfluence = 1,
        })
        swarms[i] = { Anchor = anchor, Home = home, Seed = rng:NextNumber(0, 100), Moved = 0 }
    end

    m.Update = function(t, dt)
        local center = Ground.Position
        for _, swarm in swarms do
            swarm.Moved += dt
            if swarm.Moved > rng:NextNumber(8, 16) then
                swarm.Moved = 0
                swarm.Home = newHome()
            end
            local s = swarm.Seed
            local wander = Vector3.new(
                math.sin(t * 1.7 + s) * 2 + math.sin(t * 6.3 + s * 2) * 0.6,
                math.sin(t * 2.1 + s * 3) * 0.8,
                math.cos(t * 1.3 + s) * 2 + math.cos(t * 5.7 + s * 4) * 0.6
            )
            local target = center + swarm.Home + wander
            local current = swarm.Anchor.Position
            swarm.Anchor.CFrame = CFrame.new(current:Lerp(target, math.min(1, dt * 2)))
        end
    end
end)

mode("Bubbles", {
    Lighting = { ClockTime = 10.5, Brightness = 2.6, Ambient = rgb(150, 140, 170), OutdoorAmbient = rgb(180, 175, 200), ExposureCompensation = 0.25 },
    Atmosphere = { Density = 0.28, Offset = 0.1, Color = rgb(210, 225, 255), Decay = rgb(220, 190, 240), Glare = 0.5, Haze = 1.2 },
    Clouds = { Cover = 0.4, Density = 0.25, Color = rgb(255, 255, 255) },
    Grade = { TintColor = rgb(245, 245, 255), Saturation = 0.2, Contrast = 0.03, Brightness = 0.03 },
    Bloom = { Intensity = 0.7, Size = 45, Threshold = 1 },
    SunRays = { Intensity = 0.1, Spread = 0.6 },
}, function(m)

    local field = newPart("BubbleField", Vector3.new(activeRadius(m.Name) * 1.6, m.Height, activeRadius(m.Name) * 1.6), m.Folder)
    field.CFrame = Ground.CFrame * CFrame.new(0, m.Height / 2, 0)
    for _, kind in { { Size = 0.45, Rate = 45 }, { Size = 0.9, Rate = 26 }, { Size = 1.6, Rate = 10 } } do
        m.Emit(Ground, {
            Texture = Textures.bubble,
            EmissionDirection = Enum.NormalId.Top,
            Rate = kind.Rate,
            Lifetime = NumberRange.new(8, 14),
            Speed = NumberRange.new(0.8, 2),
            SpreadAngle = Vector2.new(35, 35),
            Acceleration = Vector3.new(0, 0.18, 0),
            Drag = 0.35,
            Size = popSize(kind.Size),
            Transparency = popTransparency,
            Color = ColorSequence.new(m.C("Bubble")),
            LightEmission = 0.35,
            LightInfluence = 0.25,
            Brightness = 1.5,
        }, 0.9)
    end

    local prewarm = m.Emit(field, {
        Texture = Textures.bubble,
        Rate = 30,
        Lifetime = NumberRange.new(5, 9),
        Speed = NumberRange.new(0.4, 1),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, 0.18, 0),
        Drag = 0.35,
        Size = popSize(0.8),
        Transparency = popTransparency,
        Color = ColorSequence.new(m.C("Bubble")),
        LightEmission = 0.35,
        LightInfluence = 0.25,
        Brightness = 1.5,
    }, 0.9)
    prewarm:Emit(120)
    m.Emit(Lens, {
        Texture = Textures.bubble,
        Rate = 3,
        Lifetime = NumberRange.new(5, 8),
        Speed = NumberRange.new(0.3, 0.8),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, 0.2, 0),
        Drag = 0.35,
        Size = popSize(2.4),
        Transparency = numberSequence({ { 0, 1 }, { 0.08, 0.2 }, { 0.9, 0.2 }, { 0.96, 0.55 }, { 1, 1 } }),
        Color = ColorSequence.new(m.C("Bubble")),
        LightEmission = 0.35,
        LightInfluence = 0.25,
        Brightness = 1.5,
    }, 0.9)
    m.Emit(field, {
        Texture = Textures.star,
        Rate = 50,
        Lifetime = NumberRange.new(3, 6),
        Speed = NumberRange.new(0.2, 0.5),
        SpreadAngle = Vector2.new(180, 180),
        Size = scaled(twinkle, 0.35),
        Color = ColorSequence.new(m.C("Sparkle")),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 4,
    }, 0.4)
    m.Emit(field, {
        Texture = Textures.soft,
        Rate = 30,
        Lifetime = NumberRange.new(5, 8),
        Speed = NumberRange.new(0.2, 0.5),
        SpreadAngle = Vector2.new(180, 180),
        Size = scaled(twinkle, 0.3),
        Color = ColorSequence.new(m.C("Glow")),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 2,
    }, 0.5)
    nearField(m, {
        Texture = Textures.bubble,
        Color = m.C("Bubble"),
        HazeColor = m.C("Glow"),
        Rate = 45,
        Size = 0.4,
        Transparency = 0.2,
        Wind = 0.6,
        HazeRate = 8,
    })

    m.Update = function()
        field.CFrame = Ground.CFrame * CFrame.new(0, m.Height / 2, 0)
    end
end)

local function destroyModeFolder(folder)
    if folder and folder.Parent then
        folder:Destroy()
    end
end

local function purgeModeFolders(keep)
    if not Container then
        return
    end
    for _, child in Container:GetChildren() do
        if child:IsA("Folder") and Modes[child.Name] and child ~= keep then
            destroyModeFolder(child)
        end
    end
end

local function stopMode(immediate)
    local m = Active
    if not m then return end
    Active = nil

    if m.Stop then
        pcall(m.Stop)
    end

    if immediate then
        for _, entry in m.Emitters do
            pcall(function()
                entry.Emitter:Destroy()
            end)
        end
        destroyModeFolder(m.Folder)
        return
    end

    local originals = {}
    for i, entry in m.Emitters do
        if entry.Emitter and entry.Emitter.Parent then
            entry.Emitter.Enabled = false
            originals[i] = entry.Emitter.Transparency
        end
    end
    local start = os.clock()
    local fade
    fade = RunService.Heartbeat:Connect(function()
        local k = math.min((os.clock() - start) / Config.FadeTime, 1)
        for i, entry in m.Emitters do
            local original = originals[i]
            local emitter = entry.Emitter
            if original and emitter and emitter.Parent then
                local keypoints = {}
                for _, keypoint in original.Keypoints do
                    table.insert(keypoints, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value + (1 - keypoint.Value) * k))
                end
                emitter.Transparency = NumberSequence.new(keypoints)
            end
        end
        if k >= 1 then
            fade:Disconnect()
            for _, entry in m.Emitters do
                if entry.Emitter and entry.Emitter.Parent then
                    entry.Emitter:Destroy()
                end
            end
            destroyModeFolder(m.Folder)
        end
    end)
    table.insert(Connections, fade)
end

local function startMode(name)
    local def = Modes[name]
    if not def then return end

    purgeModeFolders()

    local m = {
        Name = name,
        Environment = def.Environment,
        Height = modeHeight(name),
        Emitters = {},
        Time = 0,
        Folder = create("Folder", { Name = name, Parent = Container }),
    }
    Column.Size = Vector3.new(Column.Size.X, m.Height, Column.Size.Z)

    function m.Fall(minSpeed, maxSpeed)
        return NumberRange.new(m.Height / maxSpeed, m.Height / minSpeed * 1.1)
    end

    function m.C(slot)
        local colors = Config.Colors[name]
        return colors and colors[slot] or Color3.new(1, 1, 1)
    end

    function m.Emit(parent, props, windScale)
        local rate = (tonumber(props.Rate) or 0) * rateScale(name)
        props.Rate = math.clamp(rate, 0, 90)
        if props.Brightness and props.Brightness > 2.5 then
            props.Brightness = 2.5
        end
        if props.Size then
            props.Size = scaleSequence(props.Size, modeSizeScale(name))
        end
        props.Parent = parent
        local emitter = create("ParticleEmitter", props)
        local entry = { Emitter = emitter, Base = props.Acceleration or Vector3.zero, Wind = windScale or 0 }
        table.insert(m.Emitters, entry)

        if parent == Sky and not props.LockedToPart then
            local lifetime = props.Lifetime and props.Lifetime.Max or 1
            local burst = math.min(math.floor(props.Rate * lifetime * 0.2), 40)
            if burst > 0 then
                local prewarm = emitter:Clone()
                prewarm.Enabled = false
                prewarm.Parent = Column
                prewarm:Emit(burst)
                table.insert(m.Emitters, { Emitter = prewarm, Base = entry.Base, Wind = entry.Wind })
                task.delay(lifetime, prewarm.Destroy, prewarm)
            end
        end
        return emitter
    end

    Active = m
    local ok, err = pcall(def.Build, m)
    if not ok then
        warn(`[Weather] {name} failed to build: {err}`)
    end
    for _, entry in m.Emitters do
        if entry.Emitter and entry.Emitter.Parent then
            entry.Emitter.Enabled = true
        end
    end
    if m.Update then
        local okUpdate, updateErr = pcall(m.Update, 0, 0)
        if not okUpdate then
            warn(`[Weather] {name} first update failed: {updateErr}`)
            m.Update = nil
        end
    end
    applyEnvironment(def.Environment)
end

local function saveSettings()
    if not Config.RememberMode then return end
    pcall(writefile, SettingsPath, HttpService:JSONEncode({ Mode = Config.Mode }))
end

local function loadSettings()
    if not Config.RememberMode or not (isfile and isfile(SettingsPath)) then return end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(SettingsPath))
    if ok and type(data) == "table" and (Modes[data.Mode] or data.Mode == "Off") then
        Config.Mode = data.Mode
    end
end

local function setMode(name, force)
    if Active and Active.Name == name and not force then return end
    if name ~= "Off" and not Modes[name] then return end
    if name == "Off" then
        if Config.Mode ~= "Off" and Modes[Config.Mode] then
            Config.LastMode = Config.Mode
        end
    else
        Config.LastMode = name
    end
    stopMode(force == true)
    Config.Mode = name
    if name == "Off" then
        Active = nil
        applyEnvironment(nil)
        purgeModeFolders()
        if Container then
            Container.Parent = nil
        end
    else
        if Container and not Container.Parent then
            Container.Parent = workspace.CurrentCamera
        end
        startMode(name)
    end
    saveSettings()
end

local function cycleMode()
    local index = table.find(ModeOrder, Config.Mode) or 0
    setMode(ModeOrder[index % #ModeOrder + 1])
end

local lastGround = nil
local lastGroundAt = 0
local lastGustAt = 0
local cachedGust = Vector3.zero
local lastWeatherTick = 0

local function update(dt)
    local m = Active
    if not m or Config.Mode == "Off" then
        return
    end

    local center = focusPosition()
    local now = os.clock()
    local ground
    if lastGround and now - lastGroundAt < 0.2 then
        ground = Vector3.new(center.X, lastGround.Y, center.Z)
    else
        ground = groundBelow(center, center.Y - 3)
        lastGround = ground
        lastGroundAt = now
    end
    local camera = workspace.CurrentCamera.CFrame.Position
    local height = m.Height or Config.Height
    local radius = activeRadius(m.Name)
    local area = radius * 2
    if Sky.Size.X ~= area then
        Sky.Size = Vector3.new(area, 1, area)
        Column.Size = Vector3.new(area, height, area)
        Volume.Size = Vector3.new(area, Volume.Size.Y, area)
        Ground.Size = Vector3.new(area, 0.2, area)
    elseif Column.Size.Y ~= height then
        Column.Size = Vector3.new(area, height, area)
    end
    if m.Name == "Stars" then
        local distance = modeStarDistance("Stars")
        local domeSize = distance * 2
        if Dome.Size.X ~= domeSize then
            Dome.Size = Vector3.one * domeSize
        end
    end

    Sky.CFrame = CFrame.new(center.X, center.Y + height, center.Z)
    Column.CFrame = CFrame.new(center.X, center.Y + height / 2, center.Z)
    Volume.CFrame = CFrame.new(center.X, ground.Y + Volume.Size.Y / 2, center.Z)
    Ground.CFrame = CFrame.new(center.X, ground.Y + 0.05, center.Z)
    NearSky.Size = Vector3.new(36, 1, 36)
    NearGround.Size = Vector3.new(36, 0.2, 36)
    NearSky.CFrame = CFrame.new(center.X, center.Y + math.min(height, 18), center.Z)
    NearGround.CFrame = CFrame.new(center.X, ground.Y + 0.05, center.Z)
    Dome.CFrame = CFrame.new(center)
    Lens.Size = Vector3.new(24, 18, 24)
    Lens.CFrame = CFrame.new(camera + Vector3.new(0, 2, 0))

    m.Time += dt
    local t = m.Time

    if now - lastGustAt >= 0.1 then
        lastGustAt = now
        cachedGust = Config.Wind * modeWindScale(m.Name) * (1 + 0.6 * math.sin(t * 0.35))
            + Vector3.new(math.sin(t * 0.7), 0, math.cos(t * 0.5)) * 0.8 * modeWindScale(m.Name)
        for _, entry in m.Emitters do
            if entry.Wind ~= 0 and entry.Emitter and entry.Emitter.Parent then
                entry.Emitter.Acceleration = entry.Base + cachedGust * entry.Wind
            end
        end
    end

    if m.Update then
        local ok, err = pcall(m.Update, t, dt)
        if not ok then
            warn(`[Weather] {m.Name} update failed: {err}`)
            m.Update = nil
        end
    end
end

local function main()
    loadTextures()
    loadSettings()
    captureEnvironment()

    local size = Config.Radius * 2
    Container = create("Folder", { Name = "TapologyWeather", Parent = workspace.CurrentCamera })
    Sky = newPart("Sky", Vector3.new(size, 1, size), Container)
    Column = newPart("Column", Vector3.new(size, Config.Height, size), Container)
    Volume = newPart("Volume", Vector3.new(size, 24, size), Container)
    Ground = newPart("Ground", Vector3.new(size, 0.2, size), Container)
    NearSky = newPart("NearSky", Vector3.new(50, 1, 50), Container)
    NearGround = newPart("NearGround", Vector3.new(50, 0.2, 50), Container)
    Dome = newPart("Dome", Vector3.one * Config.StarDistance * 2, Container)
    Lens = newPart("Lens", Vector3.new(30, 26, 30), Container)

    update(0)
    if Config.Mode ~= "Off" then
        startMode(Config.Mode)
    end

    table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
        local now = os.clock()
        if now - lastWeatherTick < 1 / 20 then
            return
        end
        local step = now - lastWeatherTick
        lastWeatherTick = now
        update(math.clamp(step, 0.05, 0.1))
    end))
    table.insert(Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not Config.Hotkeys or not UserInputService:IsKeyDown(Config.Modifier) then return end
        if input.KeyCode == Config.CycleKey then
            cycleMode()
            return
        end
        local name = Config.Keys[input.KeyCode]
        if name then
            setMode(name)
        end
    end))

    local rebuildToken = 0
    env.Weather = {
        Config = Config,
        Modes = ModeOrder,
        SetMode = setMode,

        SetColor = function(modeName, slot, color)
            Config.Colors[modeName] = Config.Colors[modeName] or {}
            Config.Colors[modeName][slot] = color
            if Active and Active.Name == modeName then
                rebuildToken += 1
                local token = rebuildToken
                task.delay(0.35, function()
                    if token == rebuildToken and Active and Active.Name == modeName then
                        setMode(modeName, true)
                    end
                end)
            end
        end,

        SetChangeEnvironment = function(on)
            Config.ChangeEnvironment = on and true or false
            applyEnvironment(Active and Active.Environment)
        end,

        SetParam = function(modeName, key, value)
            Config.ModeParams[modeName] = Config.ModeParams[modeName] or {}
            Config.ModeParams[modeName][key] = value
            if key == "Height" then
                Config.Heights[modeName] = value
            end
            if Active and Active.Name == modeName then
                if key == "Height" then
                    Active.Height = value
                end
                rebuildToken += 1
                local token = rebuildToken
                task.delay(0.35, function()
                    if token == rebuildToken and Active and Active.Name == modeName then
                        setMode(modeName, true)
                    end
                end)
            end
        end,
        Strike = function()
            if Active and Active.Name == "Rain" then
                strike(Active)
            end
        end,

        Reapply = function()
            if not Active or Active.Name == "Off" then
                return
            end
            applyEnvironment(Active.Environment, true)
        end,

        Rebuild = function()
            if not Active or Active.Name == "Off" then
                return
            end
            setMode(Active.Name, true)
        end,
        Unload = function()
            for _, connection in Connections do
                connection:Disconnect()
            end
            table.clear(Connections)
            Active = nil
            Container:Destroy()
            restoreEnvironment()
            env.Weather = nil
        end,
    }
end

TextureIds = {
    flake1 = "rbxassetid://79645306266230",
    flake2 = "rbxassetid://133424539659250",
    flake3 = "rbxassetid://72156116653308",
    soft = "rbxassetid://126113124163785",
    raindrop = "rbxassetid://139846859897029",
    splash = "rbxassetid://91125787375786",
    star = "rbxassetid://97979520465485",
    streak = "rbxassetid://81651000185831",
    ash1 = "rbxassetid://115864219323770",
    ash2 = "rbxassetid://71854731655512",
    ash3 = "rbxassetid://87064905267865",
    ember = "rbxassetid://80546770381782",
    petal1 = "rbxassetid://112586437979626",
    petal2 = "rbxassetid://71341499685050",
    petal3 = "rbxassetid://88001043515254",
    butterfly = "rbxassetid://138578077100518",
    haze = "rbxassetid://130890784990156",
    aurora = "rbxassetid://86499590710700",
    maple = "rbxassetid://74682057917220",
    oak = "rbxassetid://90776733413444",
    birch = "rbxassetid://93326338292493",
    rainsheet = "rbxassetid://83419859311993",
    grain = "rbxassetid://98885703554732",
    fly = "rbxassetid://129163843793947",
    bubble = "rbxassetid://112220434891323",
}

do
    local okWeather, errWeather = pcall(main)
    if not okWeather then
        warn("[Weather] main failed:", errWeather)
    end
end

end
]] },
    { name = "hiteffect", source = [[do

local warn = function() end

local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local TweenService = cloneref(game:GetService("TweenService"))

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local Config = {
    Enabled = false,
    Style = "Aether",
    Scale = 1,
    OnDamage = true,
    Demo = false,
    DemoEffects = { "Aether", "Blossom", "Inferno", "Plasma", "Frost", "Lightning", "Rift", "Starfall", "Cosmos", "Void" },
    DemoInterval = 1.2,
    DemoDistance = 12,

    Colors = {
        Aether = { Silk = rgb(255, 212, 135), Threads = rgb(120, 220, 255), Runes = rgb(150, 230, 255), Motes = rgb(255, 235, 180) },
        Blossom = { Glow = rgb(255, 160, 200), Petals = { rgb(255, 190, 215), rgb(255, 160, 200), rgb(255, 228, 238) } },
        Inferno = { Outer = rgb(255, 60, 15), Inner = rgb(255, 165, 50), Embers = rgb(255, 140, 40) },
        Plasma = { Core = rgb(170, 240, 255), Sparks = rgb(130, 230, 255) },
        Frost = { Ice = rgb(170, 228, 255), Flakes = rgb(230, 248, 255), Glints = rgb(205, 242, 255) },
        Lightning = { Bolt = rgb(225, 234, 255), Sparks = rgb(190, 208, 255) },
        Rift = { Cyan = rgb(40, 230, 255), Pixels = { rgb(255, 40, 95), rgb(40, 230, 255), rgb(235, 245, 255) } },
        Starfall = { Glow = rgb(255, 160, 60), Stars = rgb(255, 226, 150) },
        Cosmos = { Nebula = rgb(140, 70, 230), Stars = rgb(235, 235, 255), Rings = rgb(165, 145, 255) },
        Void = { Wisps = rgb(95, 45, 140), Embers = rgb(215, 145, 255) },
    },
    TextureFolder = "hiteffect_textures",
}

local TextureIds

local env = getgenv and getgenv() or _G
if env.HitEffects then
    env.HitEffects.Unload()
end

local LocalPlayer = Players.LocalPlayer
local base64decode = (crypt and crypt.base64decode) or base64_decode or (base64 and base64.decode)

local Textures = {}
local Effects = {}
local Container
local Unloaded = false

local function create(className, props)
    local instance = Instance.new(className)
    for key, value in props do
        if key ~= "Parent" then
            instance[key] = value
        end
    end
    instance.Parent = props.Parent
    return instance
end

local function numberSequence(points)
    local keypoints = {}
    for _, point in points do
        table.insert(keypoints, NumberSequenceKeypoint.new(point[1], point[2], point[3] or 0))
    end
    return NumberSequence.new(keypoints)
end

local function newPart(name, size, parent)
    return create("Part", {
        Name = name,
        Size = size,
        Anchored = true,
        CanCollide = false,
        CanQuery = false,
        CanTouch = false,
        CastShadow = false,
        Transparency = 1,
        Parent = parent,
    })
end

local function hash(text)
    local h = 0
    for i = 1, #text do
        h = (h * 31 + string.byte(text, i)) % 4294967291
    end
    return string.format("%08x", h)
end

local function loadTextures()
    for name, id in TextureIds do
        Textures[name] = id
    end
end

local function colorList(value)
    return typeof(value) == "table" and value or { value }
end

local function burst(position, count, color, props)
    local part = newPart("Burst", Vector3.one * (props.Spread or 0.4), Container)
    part.CFrame = CFrame.new(position)
    props.Spread = nil
    props.Enabled = false
    props.LightInfluence = props.LightInfluence or 0
    local colors = colorList(color)
    for _, c in colors do
        local emitterProps = table.clone(props)
        emitterProps.Color = emitterProps.Color or ColorSequence.new(c)
        emitterProps.Parent = part
        create("ParticleEmitter", emitterProps):Emit(math.ceil(count / #colors))
    end
    task.delay(props.Lifetime.Max + 0.2, part.Destroy, part)
end

local function flash(position, color, brightness, range, duration)
    local part = newPart("Flash", Vector3.one, Container)
    part.CFrame = CFrame.new(position)
    local light = create("PointLight", { Color = color, Brightness = brightness, Range = range, Shadows = false, Parent = part })
    TweenService:Create(light, TweenInfo.new(duration, Enum.EasingStyle.Quad), { Brightness = 0 }):Play()
    task.delay(duration, part.Destroy, part)
end

local function bloom(position, texture, color, from, to, duration, rotSpeed)
    burst(position, 1, color, {
        Texture = Textures[texture],
        Lifetime = NumberRange.new(duration),
        Speed = NumberRange.new(0),
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(rotSpeed or 0),
        Size = numberSequence({ { 0, from }, { 0.3, to * 0.85 }, { 1, to } }),
        Transparency = numberSequence({ { 0, 0.1 }, { 0.5, 0.35 }, { 1, 1 } }),
        LightEmission = 1,
        Brightness = 1.5,
    })
end

local petalFlutter = numberSequence({ { 0, 0 }, { 0.2, 0.6 }, { 0.4, -0.5 }, { 0.6, 0.6 }, { 0.8, -0.5 }, { 1, 0 } })

function Effects.Aether(position, colors, scale)
    flash(position, colors.Silk, 1, 9, 0.5)
    bloom(position, "rune", colors.Runes, 0.5 * scale, 3.4 * scale, 0.9, 60)
    burst(position, 12, colors.Threads, {
        Texture = Textures.sparkle,
        Lifetime = NumberRange.new(0.6, 1.1),
        Speed = NumberRange.new(2, 5),
        SpreadAngle = Vector2.new(180, 180),
        Drag = 3,
        Rotation = NumberRange.new(0, 90),
        Size = numberSequence({ { 0, 0.3 * scale }, { 1, 0 } }),
        LightEmission = 1,
        Brightness = 1.6,
    })
    burst(position, 10, colors.Motes, {
        Texture = Textures.dot,
        Lifetime = NumberRange.new(1, 1.6),
        Speed = NumberRange.new(0.5, 2),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, 2, 0),
        Size = numberSequence({ { 0, 0.11 * scale }, { 1, 0 } }),
        LightEmission = 1,
        Brightness = 1.6,
    })
end

function Effects.Blossom(position, colors, scale)
    flash(position, colors.Glow, 0.8, 8, 0.4)
    burst(position, 18, colors.Petals, {
        Texture = Textures.petal,
        Lifetime = NumberRange.new(1.6, 2.6),
        Speed = NumberRange.new(3, 7),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, -4, 0),
        Drag = 2.5,
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-200, 200),
        Squash = petalFlutter,
        Size = numberSequence({ { 0, 0.3 * scale }, { 0.85, 0.26 * scale }, { 1, 0 } }),
        Transparency = numberSequence({ { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } }),
        LightInfluence = 0.15,
        Brightness = 1.4,
    })
end

function Effects.Inferno(position, colors, scale)
    flash(position, colors.Outer, 1.5, 10, 0.35)
    burst(position, 14, colors.Inner, {
        Texture = Textures.flamelet,
        Color = ColorSequence.new(colors.Inner, colors.Outer),
        Lifetime = NumberRange.new(0.4, 0.8),
        Speed = NumberRange.new(2, 6),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, 8, 0),
        Drag = 2,
        Rotation = NumberRange.new(-20, 20),
        Size = numberSequence({ { 0, 0.6 * scale }, { 1, 0.05 } }),
        Transparency = numberSequence({ { 0, 0 }, { 1, 1 } }),
        LightEmission = 1,
        Brightness = 1.6,
    })
    burst(position, 16, colors.Embers, {
        Texture = Textures.dot,
        Lifetime = NumberRange.new(0.8, 1.5),
        Speed = NumberRange.new(3, 8),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, 3, 0),
        Drag = 2,
        Size = numberSequence({ { 0, 0.1 * scale }, { 1, 0 } }),
        LightEmission = 1,
        Brightness = 1.8,
    })
end

function Effects.Plasma(position, colors, scale)
    flash(position, colors.Core, 1.5, 10, 0.3)
    burst(position, 22, colors.Sparks, {
        Texture = Textures.spark,
        Orientation = Enum.ParticleOrientation.VelocityParallel,
        Lifetime = NumberRange.new(0.25, 0.5),
        Speed = NumberRange.new(10, 20),
        SpreadAngle = Vector2.new(180, 180),
        Drag = 4,
        Size = numberSequence({ { 0, 0.3 * scale }, { 1, 0.05 } }),
        LightEmission = 1,
        Brightness = 2,
    })
end

function Effects.Frost(position, colors, scale)
    flash(position, colors.Ice, 1, 9, 0.4)
    burst(position, 18, colors.Glints, {
        Texture = Textures.spark,
        Orientation = Enum.ParticleOrientation.VelocityParallel,
        Lifetime = NumberRange.new(0.3, 0.6),
        Speed = NumberRange.new(6, 14),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, -12, 0),
        Drag = 2,
        Size = numberSequence({ { 0, 0.3 * scale }, { 1, 0.05 } }),
        LightEmission = 1,
        Brightness = 1.8,
    })
    burst(position, 12, colors.Flakes, {
        Texture = Textures.flake,
        Lifetime = NumberRange.new(1, 1.8),
        Speed = NumberRange.new(1, 4),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, -2, 0),
        Drag = 2,
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-90, 90),
        Size = numberSequence({ { 0, 0.3 * scale }, { 1, 0.1 } }),
        Transparency = numberSequence({ { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } }),
        LightEmission = 0.6,
        Brightness = 1.5,
    })
end

function Effects.Lightning(position, colors, scale)
    flash(position, colors.Bolt, 2.5, 12, 0.3)
    burst(position, 24, colors.Sparks, {
        Texture = Textures.spark,
        Orientation = Enum.ParticleOrientation.VelocityParallel,
        Lifetime = NumberRange.new(0.25, 0.6),
        Speed = NumberRange.new(10, 22),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, -20, 0),
        Drag = 3,
        Size = numberSequence({ { 0, 0.26 * scale }, { 1, 0.05 } }),
        LightEmission = 1,
        Brightness = 2,
    })
end

function Effects.Rift(position, colors, scale)
    flash(position, colors.Cyan, 1, 8, 0.25)
    burst(position, 24, colors.Pixels, {
        Texture = Textures.pixel,
        Lifetime = NumberRange.new(0.3, 0.7),
        Speed = NumberRange.new(2, 7),
        SpreadAngle = Vector2.new(180, 180),
        Drag = 4,
        Size = numberSequence({ { 0, 0.22 * scale }, { 1, 0.22 * scale } }),
        Transparency = numberSequence({ { 0, 0 }, { 0.7, 0 }, { 1, 1 } }),
        LightEmission = 1,
        Brightness = 1.6,
    })
end

function Effects.Starfall(position, colors, scale)
    flash(position, colors.Glow, 1.2, 10, 0.5)
    burst(position, 18, colors.Stars, {
        Texture = Textures.sparkle,
        Lifetime = NumberRange.new(0.8, 1.5),
        Speed = NumberRange.new(3, 8),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = Vector3.new(0, -6, 0),
        Drag = 2,
        Rotation = NumberRange.new(0, 90),
        RotSpeed = NumberRange.new(-120, 120),
        Size = numberSequence({ { 0, 0.42 * scale }, { 1, 0 } }),
        LightEmission = 1,
        Brightness = 1.8,
    })
end

function Effects.Cosmos(position, colors, scale)
    flash(position, colors.Nebula, 1.2, 10, 0.5)
    bloom(position, "ring", colors.Rings, 0.2 * scale, 4 * scale, 0.7)
    burst(position, 18, colors.Stars, {
        Texture = Textures.sparkle,
        Lifetime = NumberRange.new(0.7, 1.3),
        Speed = NumberRange.new(2, 6),
        SpreadAngle = Vector2.new(180, 180),
        Drag = 2,
        Rotation = NumberRange.new(0, 90),
        Size = numberSequence({ { 0, 0.32 * scale }, { 1, 0 } }),
        LightEmission = 1,
        Brightness = 1.8,
    })
end

function Effects.Void(position, colors, scale)
    flash(position, colors.Embers, 1, 8, 0.4)
    burst(position, 8, colors.Wisps, {
        Texture = Textures.puff,
        Lifetime = NumberRange.new(1, 1.8),
        Speed = NumberRange.new(1, 3),
        SpreadAngle = Vector2.new(180, 180),
        Drag = 2,
        Rotation = NumberRange.new(0, 360),
        RotSpeed = NumberRange.new(-60, 60),
        Size = numberSequence({ { 0, 0.5 * scale }, { 1, 2 * scale } }),
        Transparency = numberSequence({ { 0, 0.4 }, { 1, 1 } }),
        LightEmission = 0.1,
    })
    burst(position, 14, colors.Embers, {
        Texture = Textures.dot,
        Lifetime = NumberRange.new(0.6, 1.2),
        Speed = NumberRange.new(3, 7),
        SpreadAngle = Vector2.new(180, 180),
        Drag = 3,
        Size = numberSequence({ { 0, 0.13 * scale }, { 1, 0 } }),
        LightEmission = 1,
        Brightness = 1.8,
    })
end

local function play(name, position, scale)
    name = name or Config.Style
    local effect, colors = Effects[name], Config.Colors[name]
    if Unloaded or not Config.Enabled or not effect or not colors then return false end
    effect(position, colors, (scale or 1) * Config.Scale)
    return true
end

local function main()
    loadTextures()
    Container = create("Folder", { Name = "HitEffects", Parent = workspace.CurrentCamera })

    task.spawn(function()
        local index = 0
        while not Unloaded do
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if Config.Demo and root then
                index = index % #Config.DemoEffects + 1
                local ok, err = pcall(play, Config.DemoEffects[index], root.CFrame * Vector3.new(0, 1, -Config.DemoDistance))
                if not ok then
                    warn(`[HitEffects] {err}`)
                end
            end
            task.wait(Config.DemoInterval)
        end
    end)

    local Restores = {}
    local function findModules()
        if not getgc or (getactors and #getactors() > 0) then return end
        for _, value in getgc(true) do
            if type(value) == "table" and rawget(value, "ScreenCull") and rawget(value, "NetworkClient") then
                local modules = {}
                for name, data in value do
                    modules[name] = type(data) == "table" and data.module ~= nil and data.module or data
                end
                return modules
            end
        end
    end
    local function entryHealth(entry)
        if not entry then
            return nil
        end
        if entry.getHealth then
            local ok, hp = pcall(entry.getHealth, entry)
            if ok and type(hp) == "number" then
                return hp
            end
        end
        if type(entry._health) == "number" then
            return entry._health
        end
        return nil
    end
    local function playIfDamaged(player, position, hpBefore)
        if not (Config.Enabled and Config.OnDamage) then
            return
        end
        if typeof(position) ~= "Vector3" then
            return
        end
        local modules = env._TapologyModules
        local rep = modules and modules.ReplicationInterface
        local entry = player and rep and rep.getEntry and rep.getEntry(player)
        local before = typeof(hpBefore) == "number" and hpBefore or entryHealth(entry) or 100
        task.delay(0.18, function()
            if Unloaded or not (Config.Enabled and Config.OnDamage) then
                return
            end
            entry = player and rep and rep.getEntry and rep.getEntry(player) or entry
            local after = entryHealth(entry)
            local damaged = typeof(after) == "number" and after < before - 0.25
            local dead = entry and (entry._alive == false or (typeof(after) == "number" and after <= 0))
            if damaged or dead then
                play(Config.Style, position, Config.Scale)
            end
        end)
    end
    local okModules, modules = pcall(findModules)
    modules = okModules and modules or nil
    if modules then
        env._TapologyModules = modules
    end
    if modules and modules.NetworkClient and type(modules.NetworkClient.send) == "function" then
        local network = modules.NetworkClient
        local send = network.send
        network.send = function(self, name, ...)
            if Config.Enabled and Config.OnDamage and name == "bullethit" then
                local _, player, position = ...
                if player and typeof(position) == "Vector3" then
                    local rep = modules.ReplicationInterface
                    local entry = rep and rep.getEntry and rep.getEntry(player)
                    playIfDamaged(player, position, entryHealth(entry))
                end
            end
            return send(self, name, ...)
        end
        table.insert(Restores, function()
            network.send = send
        end)
    end

    local effectNames = {}
    for name in Effects do
        table.insert(effectNames, name)
    end
    table.sort(effectNames)

    env.HitEffects = {
        Config = Config,
        Effects = effectNames,
        EffectDefs = Effects,
        Play = play,

        NotifyDamage = function(position, player, hpBefore)
            if typeof(position) == "Vector3" then
                if player then
                    playIfDamaged(player, position, hpBefore)
                elseif Config.Enabled and Config.OnDamage then
                    play(Config.Style, position, Config.Scale)
                end
            end
        end,
        SetEnabled = function(on)
            Config.Enabled = on and true or false
        end,
        SetStyle = function(name)
            if Effects[name] then
                Config.Style = name
            end
        end,

        SetColor = function(name, slot, color)
            Config.Colors[name] = Config.Colors[name] or {}
            Config.Colors[name][slot] = color
        end,
        Unload = function()
            Unloaded = true
            for _, restore in Restores do
                pcall(restore)
            end
            Container:Destroy()
            env.HitEffects = nil
        end,
    }
end

TextureIds = {
    petal = "rbxassetid://91106269226329",
    dot = "rbxassetid://79451523688005",
    spark = "rbxassetid://83337948032750",
    puff = "rbxassetid://78353513378754",
    pixel = "rbxassetid://98416523570354",
    ring = "rbxassetid://130480777986951",
    sparkle = "rbxassetid://86312741349859",
    flamelet = "rbxassetid://71817844601963",
    flake = "rbxassetid://75489274996945",
    rune = "rbxassetid://131541064840891",
}

do
    local okHit, errHit = pcall(main)
    if not okHit then
        warn("[HitEffects] main failed:", errHit)
    end
end

end
]] },
    { name = "killeffect", source = [=[do

local warn = function() end

local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local Config = {
    Enabled = false,
    Effect = "Dust",
    OnKill = true,
    Speed = 1,
    Scale = 1,
    Demo = false,
    DemoDistance = 10,
    DemoEffects = { "Dust", "Blossom", "Sparks", "Blackhole", "Debris", "Butterflies", "Shatter", "Glitch", "Ember", "Ascension", "Constellation" },
    DemoGap = 0.6,
    Colors = {
        Dust = { Dust = rgb(185, 228, 255), Fade = rgb(120, 175, 250) },
        Blossom = {
            Petals = { rgb(255, 190, 215), rgb(255, 160, 200), rgb(255, 225, 235), rgb(250, 140, 185) },
            Pollen = rgb(255, 240, 200),
            Flash = rgb(255, 200, 225),
        },

        Debris = { Dust = rgb(200, 195, 190), Fallback = rgb(165, 150, 135) },
        Shatter = { Glass = rgb(200, 235, 255), Sparkle = rgb(230, 245, 255), Flash = rgb(200, 230, 255) },
        Ember = {
            EmberHot = rgb(255, 200, 110), EmberCool = rgb(255, 80, 25),
            Ash = rgb(85, 78, 74), AshFade = rgb(55, 52, 50), Smoke = rgb(70, 65, 62), Glow = rgb(255, 140, 60),
        },
        Sparks = {
            Hot = rgb(255, 250, 225), Mid = rgb(255, 195, 80), Cool = rgb(255, 90, 30),
            Arc = rgb(255, 225, 160), Smoke = rgb(90, 85, 80), Flash = rgb(255, 200, 120),
        },
        Blackhole = {
            Body = rgb(220, 205, 255), Pulled = rgb(120, 60, 220),
            Disk = rgb(170, 90, 255), DiskInner = rgb(255, 170, 90), Ring = rgb(230, 210, 255), Core = rgb(0, 0, 0),
        },
        Glitch = { Main = rgb(120, 205, 225), Red = rgb(230, 40, 95), Cyan = rgb(40, 210, 240), Scan = rgb(120, 255, 240) },
        Butterflies = {
            Wings = { rgb(95, 170, 255), rgb(170, 120, 255), rgb(90, 230, 210) },
            Glitter = rgb(220, 235, 255),
        },
        Ascension = {
            Body = rgb(255, 238, 190), Fade = rgb(255, 215, 130), Pillar = rgb(255, 235, 180),
            Halo = rgb(255, 220, 140), Feathers = rgb(255, 250, 235),
        },
        Constellation = {
            Nebula = { rgb(90, 70, 220), rgb(190, 80, 210), rgb(50, 150, 230) },
            Dust = rgb(110, 125, 255), DustFade = rgb(200, 120, 255),
            Stars = rgb(230, 240, 255), Lines = rgb(150, 195, 255), Comet = rgb(205, 230, 255),
        },
    },
    Timing = {
        Dust = { Hold = 0.9, Sweep = 1.4 },
        Ember = { Hold = 0.6, Sweep = 1.3 },
        Blossom = { Gather = 0.35, Petals = 110, Linger = 2.5, Fade = 1.2 },
        Debris = { Appear = 0.25, Hold = 0.5, Sweep = 0.7, Drift = 2.2, Fade = 1.3 },
        Shatter = { Appear = 0.2, Hold = 0.35, Linger = 1.8, Fade = 1 },
        Sparks = { Crackle = 0.8 },
        Blackhole = { Form = 0.5, Pull = 1.9, Fall = 0.6, Collapse = 0.4 },
        Glitch = { Appear = 0.3, Glitch = 0.9, Scan = 1 },
        Butterflies = { Hold = 0.7, Sweep = 0.9 },
        Ascension = { Rise = 0.5, Hold = 0.6, Sweep = 1.2 },

        Constellation = { Link = 0.16, Hold = 0.8, Drift = 1.4, Dive = 40, Wave = 14, Scatter = 1.5 },
    },
    TextureFolder = "killeffect_textures",
}

local TextureIds

local env = getgenv and getgenv() or _G
if env.KillEffects then
    env.KillEffects.Unload()
end

local LocalPlayer = Players.LocalPlayer
local base64decode = (crypt and crypt.base64decode) or base64_decode or (base64 and base64.decode)
local rng = Random.new()

local Textures = {}
local Effects = {}
local Connections = {}
local Container
local Unloaded = false

local function create(className, props)
    local instance = Instance.new(className)
    for key, value in props do
        if key ~= "Parent" then
            instance[key] = value
        end
    end
    instance.Parent = props.Parent
    return instance
end

local function numberSequence(points)
    local keypoints = {}
    for _, point in points do
        table.insert(keypoints, NumberSequenceKeypoint.new(point[1], point[2], point[3] or 0))
    end
    return NumberSequence.new(keypoints)
end

local function colorSequence(points)
    local keypoints = {}
    for _, point in points do
        table.insert(keypoints, ColorSequenceKeypoint.new(point[1], point[2]))
    end
    return ColorSequence.new(keypoints)
end

local function newPart(name, size, parent)
    return create("Part", {
        Name = name,
        Size = size,
        Anchored = true,
        CanCollide = false,
        CanQuery = false,
        CanTouch = false,
        CastShadow = false,
        Transparency = 1,
        Parent = parent,
    })
end

local function solidPart(name, props)
    props.Name = name
    props.Anchored = true
    props.CanCollide = false
    props.CanQuery = false
    props.CanTouch = false
    props.CastShadow = false
    return create("Part", props)
end

local function hash(text)
    local h = 0
    for i = 1, #text do
        h = (h * 31 + string.byte(text, i)) % 4294967291
    end
    return string.format("%08x", h)
end

local function loadTextures()
    for name, id in TextureIds do
        Textures[name] = id
    end
end

local function heartbeat(callback)
    local connection
    local elapsed = 0
    connection = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if Unloaded or callback(dt, elapsed) == false then
            connection:Disconnect()
        end
    end)
    table.insert(Connections, connection)
end

local function shuffle(list)
    for i = #list, 2, -1 do
        local j = rng:NextInteger(1, i)
        list[i], list[j] = list[j], list[i]
    end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function groundBelow(position)
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character, Container }
    local hit = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -60, 0), rayParams)
    return hit and hit.Position.Y or position.Y - 3
end

local function randomRotation()
    return CFrame.Angles(rng:NextNumber(0, math.pi * 2), rng:NextNumber(0, math.pi * 2), rng:NextNumber(0, math.pi * 2))
end

local function burst(position, count, props)
    local part = newPart("Burst", Vector3.one * (props.Spread or 0.5), Container)
    part.CFrame = CFrame.new(position)
    props.Spread = nil
    props.Texture = props.Texture or Textures.dot
    props.Enabled = false
    props.LightInfluence = props.LightInfluence or 0
    props.Parent = part
    create("ParticleEmitter", props):Emit(count)
    task.delay(props.Lifetime.Max + 0.2, part.Destroy, part)
end

local function flash(position, color, brightness, range, duration)
    local part = newPart("Flash", Vector3.one, Container)
    part.CFrame = CFrame.new(position)
    local light = create("PointLight", { Color = color, Brightness = brightness, Range = range, Shadows = false, Parent = part })
    TweenService:Create(light, TweenInfo.new(duration, Enum.EasingStyle.Quad), { Brightness = 0 }):Play()
    task.delay(duration, part.Destroy, part)
end

local function flatImage(part, texture, color, transparency, brightness)
    local images = {}
    for _, face in { Enum.NormalId.Top, Enum.NormalId.Bottom } do
        local gui = create("SurfaceGui", {
            Face = face,
            LightInfluence = 0,
            Brightness = brightness or 2,
            SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
            PixelsPerStud = 40,
            Parent = part,
        })
        table.insert(images, create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = texture,
            ImageColor3 = color,
            ImageTransparency = transparency or 0,
            Parent = gui,
        }))
    end
    return images
end

local function setImages(images, props)
    for _, image in images do
        for key, value in props do
            image[key] = value
        end
    end
end

local function shockwave(cframe, color, from, to, duration, brightness)
    local part = newPart("Shockwave", Vector3.new(from, 0.02, from), Container)
    part.CFrame = cframe
    local images = flatImage(part, Textures.ring, color, 0.1, brightness)
    TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad), { Size = Vector3.new(to, 0.02, to) }):Play()
    for _, image in images do
        TweenService:Create(image, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { ImageTransparency = 1 }):Play()
    end
    task.delay(duration, part.Destroy, part)
end

local function findRoot(source)
    if not source then
        return nil
    end
    return source:FindFirstChild("HumanoidRootPart")
        or source:FindFirstChild("Torso")
        or source:FindFirstChild("UpperTorso")
        or source.PrimaryPart
        or source:FindFirstChildWhichIsA("BasePart", true)
end

local BODY_NAMES = {
    Head = true,
    Torso = true,
    ["Left Arm"] = true,
    ["Right Arm"] = true,
    ["Left Leg"] = true,
    ["Right Leg"] = true,
    UpperTorso = true,
    LowerTorso = true,
    LeftUpperArm = true,
    LeftLowerArm = true,
    LeftHand = true,
    RightUpperArm = true,
    RightLowerArm = true,
    RightHand = true,
    LeftUpperLeg = true,
    LeftLowerLeg = true,
    LeftFoot = true,
    RightUpperLeg = true,
    RightLowerLeg = true,
    RightFoot = true,
}

local function isBodyPartName(name)
    if BODY_NAMES[name] then
        return true
    end
    return name:find("Arm")
        or name:find("Leg")
        or name:find("Hand")
        or name:find("Foot")
        or name:find("Torso")
        or name == "Head"
end

local function bodyParts(source)
    local root = findRoot(source)
    local preferred = {}
    local parts = {}
    for _, descendant in source:GetDescendants() do
        if not descendant:IsA("BasePart") or descendant == root then
            continue
        end

        local named = isBodyPartName(descendant.Name)
        local visible = descendant.Transparency < 1
        if descendant.Size.Magnitude <= 0.05 and not named then
            continue
        end
        if named then
            table.insert(preferred, descendant)
        elseif visible then
            local parent = descendant.Parent
            local isBody = parent == source or (parent and (parent:IsA("Accessory") or parent:IsA("Model")))
            if isBody then
                table.insert(parts, descendant)
            end
        end
    end
    if #preferred > 0 then
        return preferred, root
    end
    if #parts > 0 then
        return parts, root
    end
    for _, descendant in source:GetDescendants() do
        if descendant:IsA("BasePart") and descendant ~= root and descendant.Size.Magnitude > 0.05 then
            table.insert(parts, descendant)
        end
    end
    return parts, root
end

local function bodyPieces(source, target)
    local parts, root = bodyParts(source)
    root = root or findRoot(source)
    if not root then
        return {}
    end
    local scale = math.clamp(Config.Scale or 1, 0.35, 3)
    local pieces = {}
    for _, part in parts do
        local size = part.Size * scale
        table.insert(pieces, {
            CFrame = target * root.CFrame:ToObjectSpace(part.CFrame),
            Size = size,
            Color = part.Color,
            Textured = part:FindFirstChildOfClass("SurfaceAppearance") ~= nil or part:IsA("MeshPart") and part.TextureID ~= "",
            Volume = size.X * size.Y * size.Z,
        })
    end
    return pieces
end

local queryParams = RaycastParams.new()
queryParams.FilterType = Enum.RaycastFilterType.Include

local function surfacePoints(source, target, perArea, maxTotal)
    local parts, root = bodyParts(source)
    root = root or findRoot(source)
    if not root then
        return {}
    end
    local toTarget = target * root.CFrame:Inverse()

    local totalArea = 0
    for _, part in parts do
        local s = part.Size
        totalArea += 2 * (s.X * s.Y + s.Y * s.Z + s.X * s.Z)
    end
    local density = math.min(perArea, maxTotal / math.max(totalArea, 1))

    local points = {}
    for _, part in parts do
        local size = part.Size
        local area = 2 * (size.X * size.Y + size.Y * size.Z + size.X * size.Z)
        local wanted = math.max(4, math.floor(area * density))
        local reach = size.Magnitude
        queryParams.FilterDescendantsInstances = { part }

        local found, tries = 0, 0
        while found < wanted and tries < wanted * 3 do
            tries += 1
            local direction = rng:NextUnitVector()
            local aim = part.CFrame * Vector3.new(rng:NextNumber(-0.35, 0.35) * size.X, rng:NextNumber(-0.35, 0.35) * size.Y, rng:NextNumber(-0.35, 0.35) * size.Z)
            local hit = workspace:Raycast(aim + direction * reach, -direction * reach * 1.2, queryParams)
            if hit then
                local point = hit.Position
                if rng:NextNumber() < 0.3 then
                    point = point:Lerp(aim, rng:NextNumber(0.15, 0.6))
                end
                table.insert(points, toTarget * point)
                found += 1
            end
        end

        if found == 0 then
            for _ = 1, wanted do
                table.insert(points, toTarget * (part.CFrame * Vector3.new(rng:NextNumber(-0.5, 0.5) * size.X, rng:NextNumber(-0.5, 0.5) * size.Y, rng:NextNumber(-0.5, 0.5) * size.Z)))
            end
        end
    end
    return points
end

local function bounds(pieces)
    local highest, lowest, center, volume = -math.huge, math.huge, Vector3.zero, 0
    for _, piece in pieces do
        local position = piece.CFrame.Position
        highest = math.max(highest, position.Y + piece.Size.Y / 2)
        lowest = math.min(lowest, position.Y - piece.Size.Y / 2)
        center += position * piece.Volume
        volume += piece.Volume
    end
    return highest, lowest, center / math.max(volume, 1e-3), volume
end

local function pointsCenter(points)
    local sum = Vector3.zero
    for _, point in points do
        sum += point
    end
    return sum / math.max(#points, 1)
end

local function randomPoint(piece)
    local size = piece.Size
    return piece.CFrame * Vector3.new(rng:NextNumber(-0.5, 0.5) * size.X, rng:NextNumber(-0.5, 0.5) * size.Y, rng:NextNumber(-0.5, 0.5) * size.Z)
end

local function weightedPiece(pieces, totalVolume)
    local pick = rng:NextNumber(0, totalVolume)
    for _, piece in pieces do
        pick -= piece.Volume
        if pick <= 0 then
            return piece
        end
    end
    return pieces[#pieces]
end

local function sweepDelay(piece, highest, lowest, sweep, upward)
    local height = math.max(highest - lowest, 1)
    local position, half = piece.CFrame.Position.Y, piece.Size.Y / 2
    local fraction = upward and (position - half - lowest) / height or (highest - position - half) / height
    return math.clamp(fraction, 0, 1) * sweep
end

local function split(points, shares)
    local copy = table.clone(points)
    shuffle(copy)
    local result, index = {}, 1
    for i, share in shares do
        local count = i == #shares and #copy - index + 1 or math.floor(#copy * share)
        result[i] = table.move(copy, index, index + count - 1, 1, {})
        index += count
    end
    return result
end

local function pointCloud(model, points, o)
    local count = o.Groups or 8
    local groups = {}
    for i = 1, count do
        groups[i] = { Index = i, Points = {}, Emitters = {} }
    end

    local group = o.Group
    if not group then
        local high, low = -math.huge, math.huge
        for _, point in points do
            high, low = math.max(high, point.Y), math.min(low, point.Y)
        end
        local span = math.max(high - low, 0.01)
        group = function(point)
            local f = (high - point.Y) / span
            if o.Upward then
                f = 1 - f
            end
            return math.clamp(math.floor(f * count) + 1, 1, count)
        end
    end
    for _, point in points do
        table.insert(groups[group(point)].Points, point)
    end

    local anchor = newPart("Cloud", Vector3.one, model)
    anchor.CFrame = CFrame.new(points[1] or Vector3.zero)
    local perGroup = o.PerGroup or 4
    local longest = 0
    for _, g in groups do
        shuffle(g.Points)
        longest = math.max(longest, #g.Points)
        for _ = 1, perGroup do
            local props = table.clone(o.Props)
            if o.GroupProps then
                for key, value in o.GroupProps(g.Index) do
                    props[key] = value
                end
            end
            props.Enabled = false
            props.TimeScale = 0
            props.LightInfluence = props.LightInfluence or 0
            local attachment = create("Attachment", { Parent = anchor })
            props.Parent = attachment
            table.insert(g.Emitters, { Attachment = attachment, Emitter = create("ParticleEmitter", props) })
        end
    end

    local cloud = { Groups = groups, FormTime = math.ceil(longest / perGroup) / 60 }

    function cloud.Emit()
        task.spawn(function()
            local frame = 0
            while frame * perGroup < longest and not Unloaded and model.Parent do
                local ready = {}
                for _, g in groups do
                    for k, slot in g.Emitters do
                        local point = g.Points[frame * perGroup + k]
                        if point then
                            slot.Attachment.WorldPosition = point
                            if o.Place then
                                o.Place(slot, point)
                            end
                            table.insert(ready, slot.Emitter)
                        end
                    end
                end
                RunService.RenderStepped:Wait()
                for _, emitter in ready do
                    emitter:Emit(1)
                end
                frame += 1
            end
        end)
        return cloud.FormTime
    end

    function cloud.Release(index, ramp)
        local g = groups[index]
        heartbeat(function(_, elapsed)
            local p = math.min(elapsed / math.max(ramp, 1e-3), 1)
            for _, slot in g.Emitters do
                slot.Emitter.TimeScale = p * p
            end
            return p < 1
        end)
    end

    function cloud.Sweep(duration, ramp, randomOrder)
        local order = {}
        for i = 1, count do
            order[i] = i
        end
        if randomOrder then
            shuffle(order)
        end
        for position, index in order do
            task.delay((position - 1) / math.max(count - 1, 1) * duration, cloud.Release, index, ramp)
        end
    end

    return cloud
end

local function simulate(bodies, params)
    local groundY = params.GroundY
    heartbeat(function(dt, elapsed)
        local alive = false
        for _, body in bodies do
            if body.Done then continue end
            alive = true
            if elapsed < (body.Release or 0) then continue end

            if not body.Resting then
                local velocity = body.Velocity + Vector3.new(0, -params.Gravity * dt, 0)
                velocity *= math.exp(-params.Drag * dt)
                if params.Flutter then
                    local s = body.Seed
                    velocity += Vector3.new(math.sin(elapsed * 3.1 + s), 0, math.cos(elapsed * 2.7 + s)) * params.Flutter * dt
                end
                body.Velocity = velocity
                body.Spin *= math.exp(-(params.SpinDrag or 0) * dt)
                body.Rotation *= CFrame.Angles(body.Spin.X * dt, body.Spin.Y * dt, body.Spin.Z * dt)
                local position = body.Position + velocity * dt

                if groundY and position.Y <= groundY + body.Rest then
                    position = Vector3.new(position.X, groundY + body.Rest, position.Z)
                    if params.Bounce and velocity.Y < -5 and (body.Bounces or 0) < 2 then
                        body.Bounces = (body.Bounces or 0) + 1
                        body.Velocity = Vector3.new(velocity.X * 0.55, -velocity.Y * params.Bounce, velocity.Z * 0.55)
                        body.Spin *= 0.5
                    else
                        local _, yaw = body.Rotation:ToEulerAnglesYXZ()
                        body.Rotation = CFrame.Angles(0, yaw, 0) * (body.Flat or CFrame.identity)
                            * CFrame.Angles(rng:NextNumber(-0.08, 0.08), 0, rng:NextNumber(-0.08, 0.08))
                        body.Resting = true
                        body.FadeAt = body.FadeAt or elapsed + params.Linger
                    end
                end
                body.Position = position
                body.Part.CFrame = CFrame.new(position) * body.Rotation
            end

            if body.FadeAt and elapsed >= body.FadeAt then
                local p = math.min((elapsed - body.FadeAt) / params.Fade, 1)
                body.SetFade(p)
                if p >= 1 then
                    body.Done = true
                    body.Part:Destroy()
                end
            end
        end
        return alive
    end)
end

function Effects.Dust(ctx)
    local colors, timing = Config.Colors.Dust, Config.Timing.Dust
    local target = ctx.Target
    local breeze = -target.LookVector * 0.7 + target.RightVector * 0.4 + target.UpVector * 0.5
    local cloud = pointCloud(ctx.Model, surfacePoints(ctx.Source, target, 30, 1300), {
        Groups = 10,
        PerGroup = 6,
        Props = {
            Texture = Textures.dot,
            Lifetime = NumberRange.new(2.2, 3.4),
            Speed = NumberRange.new(0.4, 2.2),
            SpreadAngle = Vector2.new(180, 180),
            Acceleration = breeze,
            Drag = 0.55,
            Size = numberSequence({ { 0, 0.1 }, { 0.4, 0.2 }, { 1, 0.46 } }),
            Transparency = numberSequence({ { 0, 0.05 }, { 0.45, 0.3 }, { 1, 1 } }),
            Color = colorSequence({ { 0, colors.Dust }, { 1, colors.Fade } }),
            LightEmission = 0.25,
            LightInfluence = 0.25,
            Brightness = 1.2,
        },
    })
    local form = cloud.Emit()
    task.delay(form + timing.Hold, cloud.Sweep, timing.Sweep, 0.45)
    return form + timing.Hold + timing.Sweep + 4
end

function Effects.Ember(ctx)
    local colors, timing = Config.Colors.Ember, Config.Timing.Ember
    local target = ctx.Target
    local points = surfacePoints(ctx.Source, target, 26, 1100)
    local parts = split(points, { 0.55, 0.45 })
    local function cloudOf(subset, props)
        return pointCloud(ctx.Model, subset, { Groups = 9, PerGroup = 4, Upward = true, Props = props })
    end
    local embers = cloudOf(parts[1], {
        Texture = Textures.ember,
        Lifetime = NumberRange.new(1.6, 2.8),
        Speed = NumberRange.new(0.4, 1.6),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = target.UpVector * 3.4,
        Drag = 0.8,
        Size = numberSequence({ { 0, 0.12 }, { 0.6, 0.08 }, { 1, 0 } }),
        Transparency = numberSequence({ { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } }),
        Color = colorSequence({ { 0, colors.EmberHot }, { 1, colors.EmberCool } }),
        LightEmission = 1,
        Brightness = 3,
    })
    local ash = cloudOf(parts[2], {
        Texture = Textures.dot,
        Lifetime = NumberRange.new(1.8, 3),
        Speed = NumberRange.new(0.3, 1.2),
        SpreadAngle = Vector2.new(180, 180),
        Acceleration = target.UpVector * -2.4 + target.RightVector * 0.5,
        Drag = 0.9,
        Size = numberSequence({ { 0, 0.11 }, { 1, 0.2 } }),
        Transparency = numberSequence({ { 0, 0.1 }, { 0.6, 0.4 }, { 1, 1 } }),
        Color = colorSequence({ { 0, colors.Ash }, { 1, colors.AshFade } }),
        LightEmission = 0,
        LightInfluence = 1,
    })
    local form = math.max(embers.Emit(), ash.Emit())
    local _, lowest, center = bounds(ctx.Pieces)
    task.delay(form + timing.Hold, function()
        if Unloaded then return end
        flash(Vector3.new(center.X, lowest + 1, center.Z), colors.Glow, 2.2, 16, timing.Sweep + 1)
        embers.Sweep(timing.Sweep, 0.3)
        ash.Sweep(timing.Sweep, 0.3)
        for i = 0, 4 do
            task.delay(i / 4 * timing.Sweep, function()
                burst(Vector3.new(center.X, lowest + (center.Y - lowest) * 2 * i / 4, center.Z), 6, {
                    Texture = Textures.puff,
                    Spread = 1.5,
                    Lifetime = NumberRange.new(1.8, 2.6),
                    Speed = NumberRange.new(0.3, 0.8),
                    SpreadAngle = Vector2.new(40, 40),
                    Acceleration = Vector3.new(0, 1.2, 0),
                    Rotation = NumberRange.new(0, 360),
                    RotSpeed = NumberRange.new(-30, 30),
                    Size = numberSequence({ { 0, 0.6 }, { 1, 2.4 } }),
                    Transparency = numberSequence({ { 0, 1 }, { 0.2, 0.75 }, { 1, 1 } }),
                    Color = ColorSequence.new(colors.Smoke),
                    LightInfluence = 1,
                })
            end)
        end
    end)
    return form + timing.Hold + timing.Sweep + 3.5
end

function Effects.Sparks(ctx)
    local colors, timing = Config.Colors.Sparks, Config.Timing.Sparks
    local target = ctx.Target
    local points = surfacePoints(ctx.Source, target, 22, 900)
    local center = pointsCenter(points)
    local groundY = groundBelow(center)

    local glints = pointCloud(ctx.Model, points, {
        Groups = 1,
        PerGroup = 30,
        Props = {
            Texture = Textures.glint,
            Lifetime = NumberRange.new(0.12, 0.2),
            Speed = NumberRange.new(0),
            Rotation = NumberRange.new(0, 90),
            Size = NumberSequence.new(0.22),
            Transparency = numberSequence({ { 0, 0.1 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Hot),
            LightEmission = 1,
            Brightness = 2.5,
        },
    })
    local sparks = pointCloud(ctx.Model, points, {
        Groups = 1,
        PerGroup = 30,
        Props = {
            Texture = Textures.spark,
            Orientation = Enum.ParticleOrientation.VelocityParallel,
            Lifetime = NumberRange.new(0.5, 1.1),
            Speed = NumberRange.new(8, 22),
            SpreadAngle = Vector2.new(180, 180),
            Acceleration = Vector3.new(0, -30, 0),
            Drag = 0.9,
            Size = numberSequence({ { 0, 0.4 }, { 1, 0.12 } }),
            Transparency = numberSequence({ { 0, 1 }, { 0.02, 0 }, { 0.7, 0.2 }, { 1, 1 } }),
            Color = colorSequence({ { 0, colors.Hot }, { 0.35, colors.Mid }, { 1, colors.Cool } }),
            LightEmission = 1,
            Brightness = 4,
        },
    })
    local form = math.max(glints.Emit(), sparks.Emit())

    local arcAnchor = newPart("Arcs", Vector3.one, ctx.Model)
    arcAnchor.CFrame = CFrame.new(center)
    local arcs = {}
    for i = 1, 5 do
        local a0 = create("Attachment", { Parent = arcAnchor })
        local a1 = create("Attachment", { Parent = arcAnchor })
        arcs[i] = {
            A0 = a0,
            A1 = a1,
            Beam = create("Beam", {
                Attachment0 = a0,
                Attachment1 = a1,
                Texture = Textures.arc,
                TextureMode = Enum.TextureMode.Stretch,
                Width0 = 0.35,
                Width1 = 0.35,
                Segments = 10,
                FaceCamera = true,
                Color = ColorSequence.new(colors.Arc),
                LightEmission = 1,
                LightInfluence = 0,
                Brightness = 4,
                Enabled = false,
                Parent = arcAnchor,
            }),
        }
    end
    local crackleEnd = form + timing.Crackle
    local nextJump = 0
    heartbeat(function(_, elapsed)
        if elapsed >= crackleEnd then
            for _, a in arcs do
                a.Beam.Enabled = false
            end
            return false
        end
        if elapsed >= form and elapsed >= nextJump then
            nextJump = elapsed + 0.05
            for _, a in arcs do
                local on = rng:NextNumber() < 0.65
                a.Beam.Enabled = on
                if on then
                    a.A0.WorldPosition = points[rng:NextInteger(1, #points)]
                    a.A1.WorldPosition = points[rng:NextInteger(1, #points)]
                    a.Beam.CurveSize0 = rng:NextNumber(-1.5, 1.5)
                    a.Beam.CurveSize1 = rng:NextNumber(-1.5, 1.5)
                end
            end
        end
    end)

    task.delay(crackleEnd, function()
        if Unloaded then return end
        glints.Release(1, 0.01)
        sparks.Release(1, 0.01)
        flash(center, colors.Flash, 5, 22, 0.7)
        burst(Vector3.new(center.X, groundY + 0.3, center.Z), 16, {
            Texture = Textures.puff,
            Spread = 2.5,
            Lifetime = NumberRange.new(1.5, 2.5),
            Speed = NumberRange.new(0.5, 1.5),
            SpreadAngle = Vector2.new(60, 60),
            Acceleration = Vector3.new(0, 1, 0),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-30, 30),
            Size = numberSequence({ { 0, 1 }, { 1, 3.5 } }),
            Transparency = numberSequence({ { 0, 1 }, { 0.15, 0.7 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Smoke),
            LightInfluence = 1,
        })
    end)
    return crackleEnd + 2.8
end

function Effects.Blackhole(ctx)
    local colors, timing = Config.Colors.Blackhole, Config.Timing.Blackhole
    local target = ctx.Target
    local points = surfacePoints(ctx.Source, target, 26, 1000)
    local center = pointsCenter(points)

    local fall = timing.Fall
    local reach = 0
    for _, point in points do
        reach = math.max(reach, (point - center).Magnitude)
    end
    local shells = 10
    local cloud = pointCloud(ctx.Model, points, {
        Groups = shells,
        PerGroup = 4,
        Group = function(point)
            local f = (point - center).Magnitude / math.max(reach, 0.01)
            return math.clamp(math.floor(f * shells) + 1, 1, shells)
        end,
        Place = function(slot, point)
            slot.Attachment.WorldCFrame = CFrame.lookAt(point, center)
            slot.Emitter.Speed = NumberRange.new((center - point).Magnitude / fall)
        end,
        Props = {
            Texture = Textures.dot,
            EmissionDirection = Enum.NormalId.Front,
            Lifetime = NumberRange.new(fall),
            SpreadAngle = Vector2.zero,
            Drag = 0,
            Size = numberSequence({ { 0, 0.11 }, { 0.7, 0.07 }, { 1, 0 } }),
            Transparency = numberSequence({ { 0, 0 }, { 0.85, 0.1 }, { 1, 1 } }),
            Color = colorSequence({ { 0, colors.Body }, { 0.6, colors.Pulled }, { 1, colors.Disk } }),
            LightEmission = 0.6,
            Brightness = 1.6,
        },
    })
    local form = cloud.Emit()

    local core = solidPart("Core", {
        Shape = Enum.PartType.Ball,
        Size = Vector3.one * 0.05,
        Color = colors.Core,
        Material = Enum.Material.SmoothPlastic,
        CFrame = CFrame.new(center),
        Parent = ctx.Model,
    })
    local tilt = CFrame.new(center) * CFrame.Angles(math.rad(14), 0, math.rad(-8))
    local disk = newPart("Disk", Vector3.new(0.1, 0.02, 0.1), ctx.Model)
    disk.CFrame = tilt
    local outer = flatImage(disk, Textures.swirl, colors.Disk, 0, 2.5)
    local innerDisk = newPart("InnerDisk", Vector3.new(0.1, 0.02, 0.1), ctx.Model)
    innerDisk.CFrame = tilt
    local inner = flatImage(innerDisk, Textures.swirl, colors.DiskInner, 0.2, 3)
    local lens = create("BillboardGui", { Size = UDim2.fromScale(0, 0), LightInfluence = 0, Brightness = 3, Adornee = core, Parent = core })
    local lensImage = create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Image = Textures.ring,
        ImageColor3 = colors.Ring,
        ImageTransparency = 0.2,
        Parent = lens,
    })

    local opened = form + timing.Form
    local pullEnd = opened + timing.Pull
    local finished = pullEnd + timing.Collapse
    local grow = TweenInfo.new(timing.Form, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.delay(form, function()
        if Unloaded then return end
        TweenService:Create(core, grow, { Size = Vector3.one * 1.3 }):Play()
        TweenService:Create(disk, grow, { Size = Vector3.new(7, 0.02, 7) }):Play()
        TweenService:Create(innerDisk, grow, { Size = Vector3.new(3.6, 0.02, 3.6) }):Play()
        TweenService:Create(lens, grow, { Size = UDim2.fromScale(2.6, 2.6) }):Play()
    end)
    task.delay(opened, cloud.Sweep, math.max(timing.Pull - fall * 1.55, 0.1), fall * 0.8, false)

    heartbeat(function(_, elapsed)
        if elapsed > finished then
            return false
        end
        setImages(outer, { Rotation = (elapsed * 220) % 360 })
        setImages(inner, { Rotation = (-elapsed * 380) % 360 })
        lensImage.Rotation = (elapsed * 60) % 360
        if elapsed > pullEnd then
            local p = (elapsed - pullEnd) / timing.Collapse
            local s = (1 - p) ^ 2
            core.Size = Vector3.one * 1.3 * s + Vector3.one * 0.01
            disk.Size = Vector3.new(7 * s + 0.01, 0.02, 7 * s + 0.01)
            innerDisk.Size = Vector3.new(3.6 * s + 0.01, 0.02, 3.6 * s + 0.01)
            lens.Size = UDim2.fromScale(2.6 * (1 + p * 0.6), 2.6 * (1 + p * 0.6))
            lensImage.ImageTransparency = 0.2 + 0.8 * p
        end
    end)

    task.delay(finished, function()
        if Unloaded then return end
        core.Transparency = 1
        flash(center, colors.Ring, 6, 20, 0.6)
        shockwave(tilt, colors.Disk, 1, 18, 0.7, 3)
        burst(center, 60, {
            Texture = Textures.glint,
            Lifetime = NumberRange.new(0.5, 1),
            Speed = NumberRange.new(10, 22),
            SpreadAngle = Vector2.new(180, 180),
            Drag = 3,
            Rotation = NumberRange.new(0, 90),
            Size = numberSequence({ { 0, 0.3 }, { 1, 0 } }),
            Color = colorSequence({ { 0, colors.Ring }, { 1, colors.Disk } }),
            LightEmission = 1,
            Brightness = 3,
        })
    end)
    return finished + 1.2
end

function Effects.Blossom(ctx)
    local colors, timing = Config.Colors.Blossom, Config.Timing.Blossom
    local pieces = ctx.Pieces
    local _, _, center, volume = bounds(pieces)
    local groundY = groundBelow(center)

    burst(center, 70, {
        Spread = 2,
        Lifetime = NumberRange.new(1.2, 2),
        Speed = NumberRange.new(4, 9),
        SpreadAngle = Vector2.new(180, 180),
        Drag = 2.5,
        Acceleration = Vector3.new(0, -1.5, 0),
        Size = numberSequence({ { 0, 0.1 }, { 1, 0 } }),
        Transparency = numberSequence({ { 0, 0 }, { 0.8, 0.3 }, { 1, 1 } }),
        Color = ColorSequence.new(colors.Pollen),
        LightEmission = 0.8,
        Brightness = 2,
    })
    flash(center, colors.Flash, 2.5, 14, 0.8)

    local bodies = {}
    for _ = 1, timing.Petals do
        local origin = randomPoint(weightedPiece(pieces, volume))
        local scale = rng:NextNumber(0.9, 1.5)
        local part = newPart("Petal", Vector3.new(0.5 * scale, 0.02, 0.42 * scale), ctx.Model)
        local rotation = randomRotation()
        part.CFrame = CFrame.new(origin) * rotation
        local images = flatImage(part, Textures.petal, colors.Petals[rng:NextInteger(1, #colors.Petals)], 1, 1)
        for _, image in images do
            image.Parent.LightInfluence = 1
            TweenService:Create(image, TweenInfo.new(timing.Gather), { ImageTransparency = 0 }):Play()
        end

        local outward = (origin - center) * Vector3.new(1, 0.35, 1)
        outward = outward.Magnitude > 0.05 and outward.Unit or rng:NextUnitVector()
        table.insert(bodies, {
            Part = part,
            Position = origin,
            Rotation = rotation,
            Velocity = outward * rng:NextNumber(12, 22) + Vector3.new(0, rng:NextNumber(8, 15), 0),
            Spin = Vector3.new(rng:NextNumber(-6, 6), rng:NextNumber(-4, 4), rng:NextNumber(-6, 6)),
            Seed = rng:NextNumber(0, 100),
            Release = timing.Gather,
            Rest = 0.02,
            SetFade = function(p)
                setImages(images, { ImageTransparency = p })
            end,
        })
    end

    simulate(bodies, {

        GroundY = groundY, Gravity = 6.5, Drag = 2.8, Flutter = 11, SpinDrag = 0.3,
        Linger = timing.Linger, Fade = timing.Fade,
    })
    return timing.Gather + 6 + timing.Linger + timing.Fade
end

function Effects.Debris(ctx)
    local colors, timing = Config.Colors.Debris, Config.Timing.Debris
    local pieces = ctx.Pieces
    local highest, lowest, center = bounds(pieces)
    local away = -ctx.Target.LookVector

    local bodies = {}
    for _, piece in pieces do
        local release = timing.Appear + timing.Hold + sweepDelay(piece, highest, lowest, timing.Sweep, false)
        local count = math.clamp(math.floor(piece.Volume * 10), 2, 18)
        local _, _, brightness = piece.Color:ToHSV()
        local shade = (piece.Textured or brightness < 0.08) and colors.Fallback or piece.Color
        for _ = 1, count do
            local size = Vector3.new(rng:NextNumber(0.2, 0.55), rng:NextNumber(0.2, 0.55), rng:NextNumber(0.2, 0.55))
            size = Vector3.new(math.min(size.X, piece.Size.X), math.min(size.Y, piece.Size.Y), math.min(size.Z, piece.Size.Z))
            local origin = randomPoint(piece)
            local rotation = piece.CFrame.Rotation
            local part = solidPart("Chunk", {
                Size = size,
                Color = shade:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.25)),
                Material = Enum.Material.Slate,
                Transparency = 1,
                CFrame = CFrame.new(origin) * rotation,
                Parent = ctx.Model,
            })
            TweenService:Create(part, TweenInfo.new(timing.Appear), { Transparency = 0 }):Play()

            local outward = origin - center
            outward = outward.Magnitude > 0.05 and outward.Unit or rng:NextUnitVector()
            local baseSize = size
            table.insert(bodies, {
                Part = part,
                Position = origin,
                Rotation = rotation,
                Velocity = outward * rng:NextNumber(0.8, 2.2) + away * rng:NextNumber(0.5, 1.4) + Vector3.new(0, rng:NextNumber(0.6, 1.8), 0),
                Spin = Vector3.new(rng:NextNumber(-1.6, 1.6), rng:NextNumber(-1.6, 1.6), rng:NextNumber(-1.6, 1.6)),
                Seed = rng:NextNumber(0, 100),
                Release = release,
                Rest = 0,
                FadeAt = release + timing.Drift + rng:NextNumber(-0.4, 0.6),
                SetFade = function(p)
                    part.Transparency = p
                    part.Size = baseSize * (1 - 0.6 * p)
                end,
            })
        end

        task.delay(release, function()
            if Unloaded then return end
            burst(piece.CFrame.Position, math.clamp(math.floor(piece.Volume * 10), 3, 20), {
                Texture = Textures.puff,
                Spread = math.max(piece.Size.X, piece.Size.Y, piece.Size.Z),
                Lifetime = NumberRange.new(1.4, 2.4),
                Speed = NumberRange.new(0.3, 1),
                SpreadAngle = Vector2.new(180, 180),
                Drag = 0.8,
                Acceleration = away * 0.6 + Vector3.new(0, 0.5, 0),
                Rotation = NumberRange.new(0, 360),
                RotSpeed = NumberRange.new(-40, 40),
                Size = numberSequence({ { 0, 0.3 }, { 1, 1.4 } }),
                Transparency = numberSequence({ { 0, 0.5 }, { 1, 1 } }),
                Color = ColorSequence.new(colors.Dust),
                LightInfluence = 1,
            })
        end)
    end

    simulate(bodies, { Gravity = -0.25, Drag = 0.15, SpinDrag = 0.05, Linger = 0, Fade = timing.Fade })
    return timing.Appear + timing.Hold + timing.Sweep + timing.Drift + timing.Fade + 1
end

function Effects.Shatter(ctx)
    local colors, timing = Config.Colors.Shatter, Config.Timing.Shatter
    local pieces = ctx.Pieces
    local _, _, center = bounds(pieces)
    local groundY = groundBelow(center)
    local release = timing.Appear + timing.Hold

    local bodies = {}
    for _, piece in pieces do
        local count = math.clamp(math.floor(piece.Volume * 14), 3, 22)
        for _ = 1, count do
            local size = Vector3.new(rng:NextNumber(0.25, 0.7), rng:NextNumber(0.35, 0.9), 0.06)
            local origin = randomPoint(piece)
            local rotation = piece.CFrame.Rotation * CFrame.Angles(0, 0, rng:NextNumber(0, math.pi * 2))

            local part = solidPart("Shard", {
                Size = size,
                Color = colors.Glass,
                Material = Enum.Material.Ice,
                Reflectance = 0.15,
                Transparency = 1,
                CFrame = CFrame.new(origin) * rotation,
                Parent = ctx.Model,
            })
            TweenService:Create(part, TweenInfo.new(timing.Appear), { Transparency = 0.1 }):Play()

            local outward = origin - center
            outward = outward.Magnitude > 0.05 and outward.Unit or rng:NextUnitVector()
            table.insert(bodies, {
                Part = part,
                Position = origin,
                Rotation = rotation,
                Velocity = outward * rng:NextNumber(8, 18) + Vector3.new(0, rng:NextNumber(4, 9), 0),
                Spin = Vector3.new(rng:NextNumber(-10, 10), rng:NextNumber(-10, 10), rng:NextNumber(-10, 10)),
                Seed = rng:NextNumber(0, 100),
                Release = release,
                Rest = size.Z / 2,
                Flat = CFrame.Angles(math.pi / 2, 0, 0),
                SetFade = function(p)
                    part.Transparency = 0.1 + 0.9 * p
                end,
            })
        end
    end

    task.delay(release, function()
        if Unloaded then return end
        flash(center, colors.Flash, 4, 18, 0.5)
        shockwave(CFrame.new(center.X, groundY + 0.05, center.Z), colors.Sparkle, 1, 10, 0.45, 2)
        burst(center, 70, {
            Texture = Textures.glint,
            Spread = 2.5,
            Lifetime = NumberRange.new(0.5, 1),
            Speed = NumberRange.new(6, 14),
            SpreadAngle = Vector2.new(180, 180),
            Drag = 3,
            Rotation = NumberRange.new(0, 90),
            Size = numberSequence({ { 0, 0.35 }, { 1, 0 } }),
            Color = ColorSequence.new(colors.Sparkle),
            LightEmission = 1,
            Brightness = 3,
        })
    end)

    simulate(bodies, {
        GroundY = groundY, Gravity = 45, Drag = 0.3, Bounce = 0.35, SpinDrag = 0.8,
        Linger = timing.Linger, Fade = timing.Fade,
    })
    return release + 3 + timing.Linger + timing.Fade
end

function Effects.Glitch(ctx)
    local colors, timing = Config.Colors.Glitch, Config.Timing.Glitch
    local target = ctx.Target
    local right = target.RightVector
    local points = surfacePoints(ctx.Source, target, 10, 320)
    local highest, lowest = -math.huge, math.huge
    for _, point in points do
        highest, lowest = math.max(highest, point.Y), math.min(lowest, point.Y)
    end
    local center = pointsCenter(points)

    local voxels = {}
    for i, point in points do
        local roll = rng:NextNumber()
        local channel = roll < 0.14 and "Red" or roll < 0.28 and "Cyan" or "Main"
        local part = solidPart("Voxel", {
            Size = Vector3.one * rng:NextNumber(0.16, 0.26),
            Color = colors[channel],
            Material = Enum.Material.Neon,
            Transparency = 1,
            CFrame = CFrame.new(point) * target.Rotation,
            Parent = ctx.Model,
        })
        voxels[i] = {
            Part = part,
            Home = point,
            Shown = rng:NextNumber(0, timing.Appear),
            Split = channel ~= "Main" and (channel == "Red" and -1 or 1) or 0,
            Alpha = channel == "Main" and 0.15 or 0.35,
        }
    end

    local scanPart = newPart("Scan", Vector3.new(4, 0.04, 4), ctx.Model)
    local scanImages = flatImage(scanPart, Textures.pixel, colors.Scan, 0.25, 2.5)
    local peel = create("ParticleEmitter", {
        Texture = Textures.pixel,
        Rate = 0,
        Lifetime = NumberRange.new(0.5, 1.1),
        Speed = NumberRange.new(1.5, 5),
        SpreadAngle = Vector2.new(180, 25),
        Acceleration = right * 5,
        Drag = 1.5,
        Size = numberSequence({ { 0, 0.16 }, { 1, 0 } }),
        Color = colorSequence({ { 0, colors.Cyan }, { 1, colors.Red } }),
        LightEmission = 0.8,
        LightInfluence = 0,
        Brightness = 2,
        Parent = scanPart,
    })

    local glitchStart, scanStart = timing.Appear, timing.Appear + timing.Glitch
    local finished = scanStart + timing.Scan
    local slices, nextTick = {}, 0
    local moveParts, moveCFrames = {}, {}
    heartbeat(function(_, elapsed)
        if elapsed >= nextTick then
            nextTick = elapsed + 0.06
            table.clear(slices)
            if elapsed >= glitchStart and elapsed < scanStart then
                for _ = 1, rng:NextInteger(1, 3) do
                    local y = rng:NextNumber(lowest, highest)
                    table.insert(slices, { Low = y, High = y + rng:NextNumber(0.2, 0.8), Shift = rng:NextNumber(-0.9, 0.9) })
                end
            end
        end

        local scanY = elapsed >= scanStart and highest - (elapsed - scanStart) / timing.Scan * (highest - lowest + 0.4) or math.huge
        local deleted = 0
        table.clear(moveParts)
        table.clear(moveCFrames)
        for _, voxel in voxels do
            if voxel.Dead then continue end
            local home = voxel.Home
            if home.Y > scanY then
                voxel.Dead = true
                voxel.Part.Transparency = 1
                deleted += 1
                continue
            end
            local shift = 0
            for _, slice in slices do
                if home.Y >= slice.Low and home.Y <= slice.High then
                    shift = slice.Shift
                end
            end
            if elapsed >= glitchStart then
                shift += voxel.Split * (0.08 + rng:NextNumber(0, 0.12))
            end
            local visible = elapsed >= voxel.Shown and not (elapsed >= glitchStart and rng:NextNumber() < 0.05)
            voxel.Part.Transparency = visible and voxel.Alpha or 1
            table.insert(moveParts, voxel.Part)
            table.insert(moveCFrames, CFrame.new(home + right * shift) * target.Rotation)
        end
        workspace:BulkMoveTo(moveParts, moveCFrames, Enum.BulkMoveMode.FireCFrameChanged)

        if scanY ~= math.huge then
            scanPart.CFrame = CFrame.new(center.X, scanY, center.Z) * target.Rotation
            setImages(scanImages, { ImageTransparency = 0.25 + 0.5 * math.max(0, (elapsed - finished + 0.3) / 0.3) })
            if deleted > 0 then
                peel:Emit(deleted * 3)
            end
        else
            setImages(scanImages, { ImageTransparency = 1 })
        end
        return elapsed < finished + 1.2
    end)
    return finished + 1.4
end

function Effects.Butterflies(ctx)
    local colors, timing = Config.Colors.Butterflies, Config.Timing.Butterflies
    local target = ctx.Target
    local points = surfacePoints(ctx.Source, target, 6, 180)
    local flocks = split(points, { 0.34, 0.33, 0.33 })
    local clouds = {}
    for i, subset in flocks do
        clouds[i] = pointCloud(ctx.Model, subset, {
            Groups = 6,
            PerGroup = 3,
            Props = {
                Texture = Textures.butterfly,
                FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2,
                FlipbookMode = Enum.ParticleFlipbookMode.Loop,
                FlipbookFramerate = NumberRange.new(12, 18),
                FlipbookStartRandom = true,
                Lifetime = NumberRange.new(3, 4.5),
                Speed = NumberRange.new(1.5, 4),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = target.UpVector * 1.6 - target.LookVector * 0.8,
                Drag = 0.6,
                Rotation = NumberRange.new(-25, 25),
                Size = numberSequence({ { 0, 0.34 }, { 0.85, 0.34 }, { 1, 0 } }),
                Transparency = numberSequence({ { 0, 0 }, { 0.8, 0 }, { 1, 1 } }),
                Color = ColorSequence.new(colors.Wings[i]),
                LightEmission = 0.35,
                LightInfluence = 0.4,
                Brightness = 1.4,
            },
        })
    end
    local glitter = pointCloud(ctx.Model, surfacePoints(ctx.Source, target, 14, 500), {
        Groups = 6,
        PerGroup = 4,
        Props = {
            Texture = Textures.glint,
            Lifetime = NumberRange.new(1.2, 2.2),
            Speed = NumberRange.new(0.3, 1.2),
            SpreadAngle = Vector2.new(180, 180),
            Acceleration = target.UpVector * 0.8,
            Drag = 0.8,
            Rotation = NumberRange.new(0, 90),
            Size = numberSequence({ { 0, 0.12 }, { 0.5, 0.18 }, { 1, 0 } }),
            Transparency = numberSequence({ { 0, 0.3 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Glitter),
            LightEmission = 0.8,
            Brightness = 2,
        },
    })

    local form = glitter.Emit()
    for _, cloud in clouds do
        form = math.max(form, cloud.Emit())
    end
    task.delay(form + timing.Hold, function()
        if Unloaded then return end
        for _, cloud in clouds do
            cloud.Sweep(timing.Sweep, 0.35)
        end
        glitter.Sweep(timing.Sweep, 0.35)
    end)
    return form + timing.Hold + timing.Sweep + 5
end

function Effects.Ascension(ctx)
    local colors, timing = Config.Colors.Ascension, Config.Timing.Ascension
    local target = ctx.Target
    local points = surfacePoints(ctx.Source, target, 26, 1000)
    local center = pointsCenter(points)
    local groundY = groundBelow(center)
    local highest = -math.huge
    for _, point in points do
        highest = math.max(highest, point.Y)
    end

    local cloud = pointCloud(ctx.Model, points, {
        Groups = 8,
        PerGroup = 5,
        Props = {
            Texture = Textures.dot,
            Lifetime = NumberRange.new(2.4, 3.4),
            Speed = NumberRange.new(0.2, 0.8),
            SpreadAngle = Vector2.new(180, 180),
            Acceleration = target.UpVector * 5,
            Drag = 0.6,
            Size = numberSequence({ { 0, 0.1 }, { 1, 0.24 } }),
            Transparency = numberSequence({ { 0, 0 }, { 0.6, 0.3 }, { 1, 1 } }),
            Color = colorSequence({ { 0, colors.Body }, { 1, colors.Fade } }),
            LightEmission = 0.6,
            Brightness = 1.6,
        },
    })
    local form = cloud.Emit()

    local pillarAnchor = newPart("Pillar", Vector3.one, ctx.Model)
    pillarAnchor.CFrame = CFrame.new(center.X, groundY, center.Z)
    local a0 = create("Attachment", { Parent = pillarAnchor })
    local a1 = create("Attachment", { Position = Vector3.new(0, 70, 0), Parent = pillarAnchor })
    local pillar = create("Beam", {
        Attachment0 = a0,
        Attachment1 = a1,
        Texture = Textures.ray,
        TextureMode = Enum.TextureMode.Stretch,
        Width0 = 0,
        Width1 = 0,
        Segments = 1,
        FaceCamera = true,
        Color = ColorSequence.new(colors.Pillar),
        Transparency = numberSequence({ { 0, 0.25 }, { 0.7, 0.45 }, { 1, 1 } }),
        LightEmission = 1,
        LightInfluence = 0,
        Brightness = 2.5,
        Parent = pillarAnchor,
    })
    local halo = newPart("Halo", Vector3.new(0.1, 0.02, 0.1), ctx.Model)
    local haloImages = flatImage(halo, Textures.ring, colors.Halo, 1, 3)

    local start = form
    local release = start + timing.Rise + timing.Hold
    local finished = release + timing.Sweep + 3.5
    heartbeat(function(_, elapsed)
        if elapsed > finished then
            return false
        end
        local rise = math.clamp((elapsed - start) / timing.Rise, 0, 1)
        local fade = math.clamp((elapsed - release - timing.Sweep) / 2, 0, 1)
        local width = 4.5 * (1 - (1 - rise) ^ 3) * (1 - fade)
        pillar.Width0, pillar.Width1 = width, width * 1.4

        local lift = math.max(0, elapsed - release) * 2
        halo.Size = Vector3.new(2.2 * rise + 0.01, 0.02, 2.2 * rise + 0.01)
        halo.CFrame = CFrame.new(center.X, highest + 0.6 + lift, center.Z) * CFrame.Angles(0, elapsed * 1.5, 0)
        setImages(haloImages, { ImageTransparency = 1 - rise * (1 - fade) * 0.9 })
    end)

    task.delay(start, function()
        if Unloaded then return end
        flash(center, colors.Pillar, 3, 18, timing.Rise + timing.Hold + timing.Sweep + 1)
        shockwave(CFrame.new(center.X, groundY + 0.05, center.Z), colors.Halo, 1, 9, 1, 2)
    end)
    task.delay(release, function()
        if Unloaded then return end
        cloud.Sweep(timing.Sweep, 0.5)
        burst(center, 26, {
            Texture = Textures.feather,
            Spread = 2,
            Lifetime = NumberRange.new(3, 4.5),
            Speed = NumberRange.new(1, 3),
            SpreadAngle = Vector2.new(180, 180),
            Acceleration = Vector3.new(0, -0.9, 0),
            Drag = 1.4,
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-60, 60),
            Squash = numberSequence({ { 0, 0 }, { 0.25, 0.5 }, { 0.5, -0.4 }, { 0.75, 0.5 }, { 1, 0 } }),
            Size = numberSequence({ { 0, 0 }, { 0.08, 0.55 }, { 0.9, 0.5 }, { 1, 0 } }),
            Transparency = numberSequence({ { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Feathers),
            LightEmission = 0.3,
            LightInfluence = 0.5,
            Brightness = 1.5,
        })
    end)
    return finished
end

function Effects.Constellation(ctx)
    local colors, timing = Config.Colors.Constellation, Config.Timing.Constellation
    local source, target = ctx.Source, ctx.Target
    local points = surfacePoints(source, target, 26, 1000)
    local center = pointsCenter(points)
    local frame = CFrame.new(center) * target.Rotation
    local sourceRoot = findRoot(source)
    local toTarget = sourceRoot and (target * sourceRoot.CFrame:Inverse()) or target

    local stars, edges = {}, {}
    local function starAt(position)
        for i, star in stars do
            if (star.World - position).Magnitude < 0.75 then
                star.Count += 1
                star.World = star.World:Lerp(position, 1 / star.Count)
                return i
            end
        end
        table.insert(stars, { World = position, Count = 1 })
        return #stars
    end
    for _, part in bodyParts(source) do
        if part.Parent == source then
            local cframe, size = toTarget * part.CFrame, part.Size
            if part.Name == "Head" then
                starAt(cframe.Position)
            else
                local axis = size.X >= size.Y and size.X >= size.Z and Vector3.xAxis or size.Y >= size.Z and Vector3.yAxis or Vector3.zAxis
                local reach = axis * (axis:Dot(size) * 0.4)
                local a, b = starAt(cframe * reach), starAt(cframe * -reach)
                if a ~= b then
                    table.insert(edges, { a, b })
                end
            end
        end
    end
    if #stars == 0 then
        return 0
    end

    local parent = {}
    local function find(i)
        while parent[i] and parent[i] ~= i do
            i = parent[i]
        end
        return i
    end
    for i in stars do
        parent[i] = i
    end
    for _, edge in edges do
        parent[find(edge[1])] = find(edge[2])
    end
    local pairsByDistance = {}
    for i = 1, #stars do
        for j = i + 1, #stars do
            table.insert(pairsByDistance, { i, j, (stars[i].World - stars[j].World).Magnitude })
        end
    end
    table.sort(pairsByDistance, function(p, q)
        return p[3] < q[3]
    end)
    for _, pair in pairsByDistance do
        if find(pair[1]) ~= find(pair[2]) then
            parent[find(pair[1])] = find(pair[2])
            table.insert(edges, { pair[1], pair[2] })
        end
    end

    local links = {}
    for i in stars do
        links[i] = {}
    end
    for index, edge in edges do
        table.insert(links[edge[1]], index)
        table.insert(links[edge[2]], index)
    end
    local first = 1
    for i, star in stars do
        if star.World.Y > stars[first].World.Y then
            first = i
        end
    end
    stars[first].Appear = 0
    local queue, drawEnd = { first }, 0
    while #queue > 0 do
        local current = table.remove(queue, 1)
        for _, index in links[current] do
            local edge = edges[index]
            local other = edge[1] == current and edge[2] or edge[1]
            if not edge.Start then
                local length = (stars[other].World - stars[current].World).Magnitude
                edge.Start = stars[current].Appear
                edge.From, edge.To = current, other
                edge.End = edge.Start + timing.Link * math.clamp(length / 1.2, 0.6, 1.8)
                if not stars[other].Appear then
                    stars[other].Appear = edge.End
                    table.insert(queue, other)
                end
                drawEnd = math.max(drawEnd, edge.End)
            end
        end
    end

    local dustPoints, speckPoints = table.unpack(split(points, { 0.94, 0.06 }))
    local dust = pointCloud(ctx.Model, dustPoints, {
        Groups = 8,
        PerGroup = 4,
        Props = {
            Texture = Textures.dot,
            Lifetime = NumberRange.new(2, 3),
            Speed = NumberRange.new(0.3, 1.4),
            SpreadAngle = Vector2.new(180, 180),
            Acceleration = Vector3.new(0, 0.3, 0),
            Drag = 0.7,
            Size = numberSequence({ { 0, 0.09 }, { 1, 0.2 } }),
            Transparency = numberSequence({ { 0, 0.05 }, { 0.6, 0.35 }, { 1, 1 } }),
            Color = colorSequence({ { 0, colors.Dust }, { 1, colors.DustFade } }),
            LightEmission = 0.2,
            Brightness = 1.2,
        },
    })
    local specks = pointCloud(ctx.Model, speckPoints, {
        Groups = 1,
        PerGroup = 4,
        Props = {
            Texture = Textures.star,
            Lifetime = NumberRange.new(1.6, 2.6),
            Speed = NumberRange.new(0.2, 1),
            SpreadAngle = Vector2.new(180, 180),
            Drag = 0.7,
            Rotation = NumberRange.new(0, 90),
            Size = numberSequence({ { 0, 0.2 }, { 1, 0.08 } }),
            Transparency = numberSequence({ { 0, 0.1 }, { 0.7, 0.35 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Stars),
            LightEmission = 0.6,
            Brightness = 1.6,
        },
    })
    local form = math.max(dust.Emit(), specks.Emit())
    local release = form + drawEnd + timing.Hold
    local cometStart = release + 0.15

    local impact = Vector3.zero
    for _, star in stars do
        impact += star.World
    end
    impact /= #stars
    local fallDirection = -(target.UpVector + target.RightVector * 0.9).Unit
    local entry = impact - fallDirection * 18
    local keys = { { Position = entry, Time = 0 }, { Position = impact, Time = 18 / timing.Dive } }
    local impactTime = cometStart + keys[2].Time
    local lastHit = impactTime
    for _, star in stars do
        local away = star.World - impact
        local distance = away.Magnitude
        star.Hit = impactTime + distance / timing.Wave
        lastHit = math.max(lastHit, star.Hit)
        local push = (distance > 0.01 and away.Unit or rng:NextUnitVector()) + fallDirection * 0.25 + rng:NextUnitVector() * 0.35
        star.Drift = frame:VectorToObjectSpace(push.Unit) * rng:NextNumber(4, 7)
        star.Spin = rng:NextNumber(-140, 140)
    end
    local finished = lastHit + timing.Scatter + 0.2

    local highest, lowest = -math.huge, math.huge
    for _, point in points do
        highest, lowest = math.max(highest, point.Y), math.min(lowest, point.Y)
    end
    for i = 1, 3 do
        local height = lowest + (highest - lowest) * (i - 0.5) / 3
        burst(Vector3.new(center.X, height, center.Z), 3, {
            Texture = Textures.nebula,
            Spread = 1.6,
            Lifetime = NumberRange.new(cometStart + 0.6 - form),
            Speed = NumberRange.new(0.05, 0.2),
            SpreadAngle = Vector2.new(180, 180),
            Rotation = NumberRange.new(0, 360),
            RotSpeed = NumberRange.new(-8, 8),
            Size = numberSequence({ { 0, 1 }, { 0.15, 2.6 }, { 1, 3.6 } }),
            Transparency = numberSequence({ { 0, 1 }, { 0.15, 0.8 }, { 0.75, 0.84 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Nebula[(i - 1) % #colors.Nebula + 1]),
            LightEmission = 0,
            Brightness = 1,
        })
    end

    local anchor = newPart("Sky", Vector3.one, ctx.Model)
    anchor.CFrame = frame
    local glow = create("PointLight", { Color = colors.Lines, Brightness = 0, Range = 10, Shadows = false, Parent = anchor })
    for i, star in stars do
        star.Local = frame:PointToObjectSpace(star.World)
        star.Current = star.Local
        star.Attachment = create("Attachment", { Position = star.Local, Parent = anchor })
        star.Gui = create("BillboardGui", {
            Size = UDim2.fromScale(0, 0),
            LightInfluence = 0,
            Brightness = 1.8,
            Adornee = star.Attachment,
            Parent = star.Attachment,
        })
        star.Image = create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = Textures.star,
            ImageColor3 = colors.Stars,
            Rotation = rng:NextNumber(-12, 12),
            Parent = star.Gui,
        })
        star.Base = i == first and 2.2 or rng:NextNumber(1.3, 1.7)
        star.Phase = rng:NextNumber(0, math.pi * 2)
        star.Rotation = star.Image.Rotation
        task.delay(form + star.Appear, function()
            if Unloaded then return end
            burst(star.World, 3, {
                Texture = Textures.glint,
                Lifetime = NumberRange.new(0.3, 0.5),
                Speed = NumberRange.new(1, 2.5),
                SpreadAngle = Vector2.new(180, 180),
                Drag = 4,
                Rotation = NumberRange.new(0, 90),
                Size = numberSequence({ { 0, 0.2 }, { 1, 0 } }),
                Color = ColorSequence.new(colors.Stars),
                LightEmission = 0.6,
                Brightness = 1.5,
            })
        end)

        task.delay(star.Hit, function()
            if Unloaded then return end
            burst(star.World, 5, {
                Texture = Textures.star,
                Spread = 0.3,
                Lifetime = NumberRange.new(0.7, 1.3),
                Speed = NumberRange.new(1.5, 4.5),
                SpreadAngle = Vector2.new(180, 180),
                Drag = 2.2,
                Rotation = NumberRange.new(0, 90),
                RotSpeed = NumberRange.new(-90, 90),
                Size = numberSequence({ { 0, 0.42 }, { 1, 0 } }),
                Transparency = numberSequence({ { 0, 0 }, { 0.6, 0.25 }, { 1, 1 } }),
                Color = ColorSequence.new(colors.Stars),
                LightEmission = 0.5,
                Brightness = 1.6,
            })
        end)
    end
    for _, edge in edges do
        edge.Tip = create("Attachment", { Position = stars[edge.From].Local, Parent = anchor })
        edge.Beam = create("Beam", {
            Attachment0 = stars[edge.From].Attachment,
            Attachment1 = edge.Tip,
            Texture = Textures.line,
            TextureMode = Enum.TextureMode.Stretch,
            Width0 = 0.06,
            Width1 = 0.06,
            Segments = 1,
            FaceCamera = true,
            Color = ColorSequence.new(colors.Lines),
            Transparency = NumberSequence.new(0.25),
            LightEmission = 0.6,
            LightInfluence = 0,
            Brightness = 1.5,
            Enabled = false,
            Parent = anchor,
        })
    end

    heartbeat(function(_, elapsed)
        if elapsed > finished then
            return false
        end
        local t = elapsed - form
        local intact = 0
        for _, star in stars do
            local a = math.clamp((t - star.Appear) / 0.3, 0, 1) - 1
            local pop = 1 + 2.7 * a ^ 3 + 1.7 * a ^ 2
            local size = star.Base * (t >= star.Appear and pop or 0) * (1 + 0.08 * math.sin(elapsed * 5 + star.Phase))
            local s = elapsed - star.Hit
            if s >= 0 then

                local fade = math.clamp(s / timing.Scatter, 0, 1)
                star.Current = star.Local + star.Drift * ((1 - math.exp(-1.6 * s)) / 1.6) + Vector3.new(0, 0.25 * s, 0)
                size *= (1 + 0.6 * math.exp(-s * 12)) * (1 - 0.55 * fade)
                star.Image.ImageTransparency = 0.1 + 0.9 * fade ^ 1.3
                star.Image.Rotation = star.Rotation + s * star.Spin
            else
                intact += 1
                star.Image.ImageTransparency = 0.1
            end
            star.Gui.Size = UDim2.fromScale(size, size)
            star.Attachment.Position = star.Current
        end
        glow.Brightness = 0.6 * math.clamp(t / math.max(drawEnd, 0.1), 0, 1) * intact / #stars

        for _, edge in edges do
            local from, to = stars[edge.From], stars[edge.To]
            local d = math.clamp((t - edge.Start) / math.max(edge.End - edge.Start, 1e-3), 0, 1)
            local snapped = math.clamp((elapsed - math.min(from.Hit, to.Hit)) / 0.25, 0, 1)
            edge.Beam.Enabled = t > edge.Start and snapped < 1
            edge.Tip.Position = from.Current:Lerp(to.Current, 1 - (1 - d) ^ 2)
            edge.Beam.Transparency = NumberSequence.new(0.25 + 0.75 * snapped)
        end
    end)

    task.delay(release, function()
        if Unloaded then return end
        dust.Sweep(timing.Drift, 0.6, true)
        specks.Sweep(timing.Drift, 0.6, true)
    end)

    task.delay(cometStart, function()
        if Unloaded then return end
        local comet = newPart("Comet", Vector3.one * 0.2, ctx.Model)
        comet.CFrame = CFrame.new(entry)
        local t0 = create("Attachment", { Position = Vector3.new(0, 0.12, 0), Parent = comet })
        local t1 = create("Attachment", { Position = Vector3.new(0, -0.12, 0), Parent = comet })
        create("Trail", {
            Attachment0 = t0,
            Attachment1 = t1,
            Lifetime = 0.3,
            FaceCamera = true,
            WidthScale = numberSequence({ { 0, 1 }, { 1, 0 } }),
            Transparency = numberSequence({ { 0, 0.1 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Comet),
            LightEmission = 0.7,
            LightInfluence = 0,
            Brightness = 2,
            Parent = comet,
        })
        local head = create("BillboardGui", { Size = UDim2.fromScale(1.3, 1.3), LightInfluence = 0, Brightness = 2.2, Adornee = comet, Parent = comet })
        local headImage = create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = Textures.star,
            ImageColor3 = colors.Comet,
            Parent = head,
        })
        local segment = 1
        heartbeat(function(_, elapsed)
            while keys[segment + 1] and elapsed >= keys[segment + 1].Time do
                segment += 1
            end
            local a, b = keys[segment], keys[segment + 1]
            if not b then
                head.Enabled = false
                task.delay(0.35, comet.Destroy, comet)
                return false
            end
            local f = (elapsed - a.Time) / math.max(b.Time - a.Time, 1e-3)
            comet.CFrame = CFrame.new(a.Position:Lerp(b.Position, f))
        end)
    end)

    task.delay(impactTime, function()
        if Unloaded then return end
        flash(impact, colors.Comet, 1.2, 12, 0.5)
        burst(impact, 16, {
            Texture = Textures.star,
            Spread = 0.4,
            Lifetime = NumberRange.new(0.6, 1.1),
            Speed = NumberRange.new(5, 11),
            SpreadAngle = Vector2.new(180, 180),
            Drag = 3,
            Rotation = NumberRange.new(0, 90),
            RotSpeed = NumberRange.new(-120, 120),
            Size = numberSequence({ { 0, 0.5 }, { 1, 0 } }),
            Transparency = numberSequence({ { 0, 0 }, { 0.6, 0.3 }, { 1, 1 } }),
            Color = ColorSequence.new(colors.Comet),
            LightEmission = 0.5,
            Brightness = 1.6,
        })
    end)
    return finished
end

local function scaleTiming(effectName)
    local base = Config.Timing[effectName]
    if not base then
        return nil, nil
    end
    local speed = math.clamp(Config.Speed or 1, 0.25, 3)
    if math.abs(speed - 1) < 1e-3 then
        return nil, nil
    end
    local scaled = {}
    for key, value in base do
        if type(value) == "number" then

            if key == "Dive" or key == "Wave" or key == "Petals" then
                scaled[key] = value * speed
            else
                scaled[key] = value / speed
            end
        else
            scaled[key] = value
        end
    end
    return base, scaled
end

local function play(effectName, target, source)
    if Unloaded or not Config.Enabled then
        return 0
    end
    effectName = effectName or Config.Effect
    local effect = Effects[effectName]
    source = source or LocalPlayer.Character
    if typeof(source) ~= "Instance" then
        return 0
    end
    local root = findRoot(source)
    if not effect or not root then
        return 0
    end

    if not source:FindFirstChild("HumanoidRootPart") and root.Name ~= "HumanoidRootPart" then
        pcall(function()
            root.Name = "HumanoidRootPart"
        end)
    end

    if typeof(target) == "Vector3" then
        target = CFrame.new(target)
    end
    target = target or root.CFrame * CFrame.new(0, 0, -Config.DemoDistance) * CFrame.Angles(0, math.pi, 0)
    local pieces = bodyPieces(source, target)
    if #pieces == 0 then
        return 0
    end

    local saved, scaled = scaleTiming(effectName)
    if saved and scaled then
        Config.Timing[effectName] = scaled
    end

    local model = create("Model", { Name = effectName, Parent = Container })
    local ok, duration = pcall(effect, { Model = model, Source = source, Target = target, Pieces = pieces })
    if saved then
        Config.Timing[effectName] = saved
    end
    if not ok then
        warn(`[KillEffects] {duration}`)
        model:Destroy()
        return 0
    end
    duration = tonumber(duration) or 2

    duration = duration / math.clamp(Config.Speed or 1, 0.25, 3)
    task.delay(duration, model.Destroy, model)
    return duration
end

local function findModules()
    if not getgc or (getactors and #getactors() > 0) then
        return nil
    end
    for _, value in getgc(true) do
        if type(value) == "table" and rawget(value, "ScreenCull") and rawget(value, "NetworkClient") then
            local modules = {}
            for name, data in value do
                modules[name] = type(data) == "table" and data.module ~= nil and data.module or data
            end
            return modules
        end
    end
end

local function buildModelFromHash(tpo)
    if not tpo then
        return nil
    end
    local hash = tpo._characterModelHash
    if type(hash) ~= "table" then
        return nil
    end
    local rootPart = nil
    pcall(function()
        rootPart = tpo.getRootPart and tpo:getRootPart() or tpo._rootPart
    end)
    local rootCf = rootPart and rootPart.CFrame or CFrame.new()
    local model = Instance.new("Model")
    model.Name = "PFKillBody"
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.Transparency = 1
    hrp.Anchored = true
    hrp.CanCollide = false
    hrp.CFrame = rootCf
    hrp.Parent = model
    local count = 0
    for name, part in hash do
        if typeof(part) == "Instance" and part:IsA("BasePart") then
            local piece = Instance.new("Part")
            piece.Name = tostring(name)
            local size = part.Size
            if size.Magnitude < 0.2 then
                size = Vector3.new(1, 1, 1)
            end
            piece.Size = size
            piece.CFrame = part.CFrame
            piece.Color = part.Color
            piece.Material = Enum.Material.SmoothPlastic
            piece.Anchored = true
            piece.CanCollide = false
            piece.CanQuery = false
            piece.CanTouch = false
            piece.Transparency = 0
            piece.Parent = model
            count += 1
        end
    end
    if count == 0 then
        model:Destroy()
        return nil
    end
    return model, hrp
end

local function characterFromEntry(entry)
    if not entry then
        return nil
    end
    local tpo = entry._thirdPersonObject
    if not tpo then
        return nil
    end
    local model = nil
    pcall(function()
        model = tpo.getCharacterModel and tpo:getCharacterModel() or tpo._character
    end)
    if typeof(model) ~= "Instance" then
        local hash = tpo._characterModelHash
        if type(hash) == "table" then
            for _, part in hash do
                if typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent then
                    model = part:FindFirstAncestorOfClass("Model") or part.Parent
                    break
                end
            end
        end
    end
    local root = nil
    pcall(function()
        root = tpo.getRootPart and tpo:getRootPart() or tpo._rootPart
    end)
    root = root or (typeof(model) == "Instance" and findRoot(model)) or nil
    return model, root, tpo
end

local function main()
    loadTextures()
    Container = create("Folder", { Name = "KillEffects", Parent = workspace.CurrentCamera })

    local Restores = {}
    local damagedAt = {}
    local bodyCache = {}
    local playedAt = {}
    local Modules = findModules()

    local function clearCache(player)
        local cached = bodyCache[player]
        if cached and cached.model then
            pcall(function()
                cached.model:Destroy()
            end)
        end
        bodyCache[player] = nil
    end

    local function snapshotPlayer(player, entry)
        local model, root, tpo = characterFromEntry(entry)
        local clone = nil
        local rootCf = root and root.CFrame or nil

        if tpo then
            local hashModel, hashRoot = buildModelFromHash(tpo)
            if hashModel then
                clone = hashModel
                rootCf = hashRoot and hashRoot.CFrame or rootCf
            end
        end

        if not clone and typeof(model) == "Instance" then
            local ok, copied = pcall(function()
                return model:Clone()
            end)
            if ok and typeof(copied) == "Instance" then
                clone = copied
            end
        end
        if not clone then
            return
        end

        clone.Name = "KillSnap"
        clone.Parent = nil
        for _, d in clone:GetDescendants() do
            if d:IsA("BasePart") then
                d.Anchored = true
                d.CanCollide = false
                d.CanQuery = false
                d.CanTouch = false
                if d.Transparency >= 1 and d.Name ~= "HumanoidRootPart" then
                    d.Transparency = 0
                end
            end
        end
        if not rootCf then
            local cloneRoot = findRoot(clone)
            rootCf = cloneRoot and cloneRoot.CFrame or CFrame.new()
        end
        clearCache(player)
        bodyCache[player] = {
            model = clone,
            cf = rootCf,
            at = os.clock(),
        }
    end

    local function playForPlayer(player, fallbackCf)
        if Unloaded or not Config.Enabled or not Config.OnKill then
            return
        end
        local now = os.clock()
        if playedAt[player] and now - playedAt[player] < 0.75 then
            return
        end
        local stamped = damagedAt[player]
        if stamped and now - stamped > 5 then
            return
        end
        if not stamped and not fallbackCf then
            return
        end
        playedAt[player] = now
        damagedAt[player] = nil

        local cached = bodyCache[player]
        local clone = cached and cached.model
        local target = (cached and cached.cf) or fallbackCf
        bodyCache[player] = nil

        if typeof(clone) ~= "Instance" then

            clone = Instance.new("Model")
            clone.Name = "KillStandIn"
            local root = Instance.new("Part")
            root.Name = "HumanoidRootPart"
            root.Size = Vector3.new(2, 2, 1)
            root.Transparency = 1
            root.Anchored = true
            root.CanCollide = false
            if typeof(target) == "CFrame" then
                root.CFrame = target
            elseif typeof(target) == "Vector3" then
                root.CFrame = CFrame.new(target)
            else
                root.CFrame = CFrame.new()
            end
            root.Parent = clone
            for _, info in {
                { "Head", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 1.5, 0) },
                { "Torso", Vector3.new(2, 2, 1), CFrame.new() },
                { "Left Arm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 0, 0) },
                { "Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 0, 0) },
                { "Left Leg", Vector3.new(1, 2, 1), CFrame.new(-0.5, -2, 0) },
                { "Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, -2, 0) },
            } do
                local part = Instance.new("Part")
                part.Name = info[1]
                part.Size = info[2]
                part.Anchored = true
                part.CanCollide = false
                part.Color = Color3.fromRGB(200, 200, 210)
                part.CFrame = root.CFrame * info[3]
                part.Parent = clone
            end
        end

        clone.Parent = Container
        local cloneRoot = findRoot(clone)
        if cloneRoot and cloneRoot.Name ~= "HumanoidRootPart" then
            pcall(function()
                cloneRoot.Name = "HumanoidRootPart"
            end)
        end

        for _, d in clone:GetDescendants() do
            if d:IsA("BasePart") then
                d.CanCollide = false
                d.Anchored = true
                if d.Transparency >= 1 then
                    d.Transparency = 0
                end
            end
        end
        if typeof(target) ~= "CFrame" then
            if typeof(target) == "Vector3" then
                target = CFrame.new(target)
            else
                target = cloneRoot and cloneRoot.CFrame or CFrame.new()
            end
        end
        task.defer(function()
            local ok, dur = pcall(play, Config.Effect, target, clone)
            task.delay(((ok and tonumber(dur)) or 3) + 0.75, function()
                if clone and clone.Parent then
                    clone:Destroy()
                end
            end)
        end)
    end

    local function entryHealth(entry)
        if not entry then
            return nil
        end
        if entry.getHealth then
            local ok, hp = pcall(entry.getHealth, entry)
            if ok and type(hp) == "number" then
                return hp
            end
        end
        if type(entry._health) == "number" then
            return entry._health
        end
        return nil
    end

    local function markDamaged(player, entry)
        if not player then
            return
        end
        damagedAt[player] = os.clock()
        entry = entry or (Modules and Modules.ReplicationInterface and Modules.ReplicationInterface.getEntry and Modules.ReplicationInterface.getEntry(player))
        if entry then
            pcall(snapshotPlayer, player, entry)
        end
    end

    local function notifyKill(player, fallbackCf)
        if not player or player == LocalPlayer then
            return
        end
        damagedAt[player] = damagedAt[player] or os.clock()
        local cached = bodyCache[player]
        local cf = fallbackCf or (cached and cached.cf) or nil
        if typeof(cf) == "Vector3" then
            cf = CFrame.new(cf)
        end
        playForPlayer(player, cf)
    end

    if Modules and Modules.NetworkClient and type(Modules.NetworkClient.send) == "function" then
        local network = Modules.NetworkClient
        local send = network.send
        network.send = function(self, name, ...)
            if Config.Enabled and Config.OnKill and name == "bullethit" then
                local _, player = ...
                if player then
                    local entry = Modules.ReplicationInterface and Modules.ReplicationInterface.getEntry and Modules.ReplicationInterface.getEntry(player)
                    local hpBefore = entryHealth(entry)

                    if entry then
                        pcall(snapshotPlayer, player, entry)
                    end
                    task.delay(0.18, function()
                        if Unloaded or not (Config.Enabled and Config.OnKill) then
                            return
                        end
                        entry = Modules.ReplicationInterface and Modules.ReplicationInterface.getEntry and Modules.ReplicationInterface.getEntry(player) or entry
                        local hpAfter = entryHealth(entry)
                        local damaged = typeof(hpBefore) == "number" and typeof(hpAfter) == "number" and hpAfter < hpBefore - 0.25
                        local dead = entry and (entry._alive == false or (typeof(hpAfter) == "number" and hpAfter <= 0))
                        if damaged or dead then
                            markDamaged(player, entry)
                            if dead then
                                notifyKill(player)
                            end
                        end
                    end)
                end
            end
            return send(self, name, ...)
        end
        table.insert(Restores, function()
            network.send = send
        end)
    end

    local pse = Modules and Modules.PlayerStatusEvents
    if pse and pse.onPlayerDied and (pse.onPlayerDied.connect or pse.onPlayerDied.Connect) then
        local connect = pse.onPlayerDied.connect or pse.onPlayerDied.Connect
        table.insert(Connections, connect(pse.onPlayerDied, function(data)
            if Unloaded or not Config.Enabled or not Config.OnKill or type(data) ~= "table" then
                return
            end
            local victim = data.victim or data.player or data.Player
            local attacker = data.attacker or data.killer or data.Killer
            local attackerOk = attacker == LocalPlayer
                or (typeof(attacker) == "Instance" and attacker:IsA("Player") and attacker.UserId == LocalPlayer.UserId)
                or (type(attacker) == "string" and (attacker == LocalPlayer.Name or attacker == tostring(LocalPlayer.UserId)))
                or damagedAt[victim] ~= nil
            if not attackerOk or not victim or victim == LocalPlayer then
                return
            end
            damagedAt[victim] = damagedAt[victim] or os.clock()
            local cached = bodyCache[victim]
            notifyKill(victim, cached and cached.cf or nil)
        end))
    end

    if Modules and Modules.ReplicationInterface then
        table.insert(Connections, RunService.Heartbeat:Connect(function()
            if Unloaded or not Config.Enabled or not Config.OnKill then
                return
            end
            pcall(Modules.ReplicationInterface.operateOnAllEntries, function(player, entry)
                local stamped = damagedAt[player]
                if not stamped then
                    return
                end
                if os.clock() - stamped < 0.05 then
                    return
                end

                if entry._alive ~= false then
                    local hpOk, hp = true, 100
                    if entry.getHealth then
                        hpOk, hp = pcall(entry.getHealth, entry)
                    end
                    if hpOk and typeof(hp) == "number" and hp > 0 then
                        if not bodyCache[player] or os.clock() - (bodyCache[player].at or 0) > 0.2 then
                            snapshotPlayer(player, entry)
                        end
                        return
                    end
                end
                playForPlayer(player, bodyCache[player] and bodyCache[player].cf or entry._receivedPosition and CFrame.new(entry._receivedPosition) or nil)
            end)
        end))
    end

    table.insert(Restores, function()
        for player in bodyCache do
            clearCache(player)
        end
        table.clear(bodyCache)
        table.clear(damagedAt)
        table.clear(playedAt)
    end)

    task.spawn(function()
        local index = 0
        while not Unloaded do
            local wait = 1
            if Config.Demo then
                index = index % #Config.DemoEffects + 1
                local ok, result = pcall(play, Config.DemoEffects[index])
                if ok then
                    wait = math.max((tonumber(result) or 2) * 0.75, 2) + Config.DemoGap
                else
                    warn(`[KillEffects] {result}`)
                end
            end
            task.wait(wait)
        end
    end)

    local effectNames = {}
    for name in Effects do
        table.insert(effectNames, name)
    end
    table.sort(effectNames)

    env.KillEffects = {
        Config = Config,
        Effects = effectNames,
        EffectDefs = Effects,
        Play = play,

        NotifyDamage = markDamaged,
        NotifyKill = notifyKill,
        SetEnabled = function(on)
            Config.Enabled = on and true or false
        end,
        SetEffect = function(name)
            if Effects[name] then
                Config.Effect = name
            end
        end,
        SetSpeed = function(value)
            Config.Speed = math.clamp(tonumber(value) or 1, 0.25, 3)
        end,
        SetScale = function(value)
            Config.Scale = math.clamp(tonumber(value) or 1, 0.35, 3)
        end,

        SetColor = function(effectName, slot, color)
            Config.Colors[effectName] = Config.Colors[effectName] or {}
            Config.Colors[effectName][slot] = color
        end,
        Unload = function()
            Unloaded = true
            for _, connection in Connections do
                connection:Disconnect()
            end
            table.clear(Connections)
            for _, restore in Restores do
                pcall(restore)
            end
            table.clear(Restores)
            if Container then
                Container:Destroy()
            end
            env.KillEffects = nil
        end,
    }
end

TextureIds = {
    dot = "rbxassetid://79451523688005",
    petal = "rbxassetid://91106269226329",
    puff = "rbxassetid://105339311737422",
    glint = "rbxassetid://80819042809873",
    ember = "rbxassetid://131265282730044",
    spark = "rbxassetid://83337948032750",
    arc = "rbxassetid://137171593273887",
    swirl = "rbxassetid://112339946092674",
    ring = "rbxassetid://130480777986951",
    pixel = "rbxassetid://98416523570354",
    butterfly = "rbxassetid://140497468226737",
    ray = "rbxassetid://78335664913090",
    feather = "rbxassetid://131624527200833",
    star = "rbxassetid://105260989921589",
    nebula = "rbxassetid://137135863795287",
    line = "rbxassetid://111587888494612",
}

do
    local okKill, errKill = pcall(main)
    if not okKill then
        warn("[KillEffects] main failed:", errKill)
    end
end

end
]=] },
    { name = "tracer", source = [=[do

local warn = function() end

local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local SoundService = cloneref(game:GetService("SoundService"))

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local Config = {
    Enabled = false,
    Style = "Aether",
    Demo = false,
    DemoStyles = { "Aether", "Blossom", "Inferno", "Plasma", "Frost", "Lightning", "Rift", "Starfall", "Cosmos", "Void" },
    DemoInterval = 1.1,
    DemoDistance = 16,
    DemoSpan = 36,
    OnShoot = false,
    MaxDistance = 2000,

    TaperPeak = 0.3,
    Pieces = 8,
    Width = 1,
    Lifetime = 1,
    HitSounds = false,
    MuteGameHitSounds = true,
    HitSound = "Impact",
    HitSoundVolume = 1,
    HitSoundPitch = 1,
    HitLogs = false,
    HitLogDuration = 3.5,
    HitSoundIds = {
        Impact = "rbxassetid://9113500510",
        Gamesense = "rbxassetid://4817809188",
        Neverlose = "rbxassetid://6607339542",
        Bell = "rbxassetid://6532297512",
        Cod = "rbxassetid://5685988853",
        Click = "rbxassetid://12222208",
        Metal = "rbxassetid://8917041751",
        Soft = "rbxassetid://9113809773",
        Classic = "rbxassetid://131961136",
        Perc = "rbxassetid://9114221361",
        Pop = "rbxassetid://9114220987",
        Snap = "rbxassetid://9120092149",
        Ding = "rbxassetid://8255306220",
        Hitmarker = "rbxassetid://705502934",
        Ping = "rbxasset://sounds/electronicpingshort.mp3",
    },

    Styles = {
        Aether = { Speed = 95, Linger = 0.7, Fade = 0.8, Width = 1 },
        Blossom = { Speed = 110, Linger = 0.8, Fade = 0.8, Width = 1 },
        Inferno = { Speed = 160, Linger = 0.5, Fade = 0.6, Width = 1 },
        Plasma = { Speed = 220, Linger = 0.3, Fade = 0.4, Width = 1 },
        Frost = { Speed = 130, Linger = 0.6, Fade = 0.8, Width = 1 },
        Lightning = { Speed = math.huge, Linger = 0.35, Fade = 0.3, Width = 1 },
        Rift = { Speed = 260, Linger = 0.4, Fade = 0.3, Width = 1 },
        Starfall = { Speed = 75, Linger = 0.4, Fade = 0.8, Width = 1 },
        Cosmos = { Speed = 90, Linger = 0.6, Fade = 0.9, Width = 1 },
        Void = { Speed = 150, Linger = 0.5, Fade = 0.9, Width = 1 },
    },

    Colors = {
        Aether = { Silk = rgb(255, 212, 135), Threads = rgb(120, 220, 255), Motes = rgb(255, 235, 180) },
        Blossom = {
            Garland = rgb(255, 160, 200), Pollen = rgb(255, 238, 200),
            Petals = { rgb(255, 190, 215), rgb(255, 160, 200), rgb(255, 228, 238) },
        },
        Inferno = { Outer = rgb(255, 60, 15), Inner = rgb(255, 165, 50), Embers = rgb(255, 140, 40), Smoke = rgb(60, 45, 40) },
        Plasma = { Core = rgb(170, 240, 255), Strands = rgb(170, 100, 255), Sparks = rgb(130, 230, 255) },
        Frost = { Ice = rgb(170, 228, 255), Flakes = rgb(230, 248, 255), Glints = rgb(205, 242, 255), Mist = rgb(170, 215, 240) },
        Lightning = { Bolt = rgb(225, 234, 255), Sparks = rgb(190, 208, 255) },
        Rift = {
            Carrier = rgb(235, 245, 255), Red = rgb(255, 40, 95), Cyan = rgb(40, 230, 255),
            Pixels = { rgb(255, 40, 95), rgb(40, 230, 255), rgb(235, 245, 255) },
        },
        Starfall = { Trail = rgb(255, 205, 110), Glow = rgb(255, 160, 60), Stars = rgb(255, 226, 150) },
        Cosmos = { Nebula = rgb(140, 70, 230), Stars = rgb(235, 235, 255), Dust = rgb(255, 120, 200), Rings = rgb(165, 145, 255) },
        Void = { Smoke = rgb(80, 32, 125), Wisps = rgb(95, 45, 140), Embers = rgb(215, 145, 255) },
    },
    TextureFolder = "tracer_textures",
}

local TextureIds, TextureAspect

local env = getgenv and getgenv() or _G
if env.Tracers then
    env.Tracers.Unload()
end

local LocalPlayer = Players.LocalPlayer
local base64decode = (crypt and crypt.base64decode) or base64_decode or (base64 and base64.decode)
local rng = Random.new()

local Textures = {}
local Styles = {}
local Connections = {}
local Container
local Unloaded = false

local function create(className, props)
    local instance = Instance.new(className)
    for key, value in props do
        if key ~= "Parent" then
            instance[key] = value
        end
    end
    instance.Parent = props.Parent
    return instance
end

local function numberSequence(points)
    local keypoints = {}
    for _, point in points do
        table.insert(keypoints, NumberSequenceKeypoint.new(point[1], point[2], point[3] or 0))
    end
    return NumberSequence.new(keypoints)
end

local function scaleSequence(sequence, factor)
    local keypoints = {}
    for _, point in sequence.Keypoints do
        table.insert(keypoints, NumberSequenceKeypoint.new(point.Time, point.Value * factor, point.Envelope * factor))
    end
    return NumberSequence.new(keypoints)
end

local function newPart(name, size, parent)
    return create("Part", {
        Name = name,
        Size = size,
        Anchored = true,
        CanCollide = false,
        CanQuery = false,
        CanTouch = false,
        CastShadow = false,
        Transparency = 1,
        Parent = parent,
    })
end

local function hash(text)
    local h = 0
    for i = 1, #text do
        h = (h * 31 + string.byte(text, i)) % 4294967291
    end
    return string.format("%08x", h)
end

local function loadTextures()
    for name, id in TextureIds do
        Textures[name] = id
    end
end

local function heartbeat(callback)
    local connection
    local elapsed = 0
    connection = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if Unloaded or callback(dt, elapsed) == false then
            connection:Disconnect()
        end
    end)
    table.insert(Connections, connection)
end

local function colorList(value)
    return typeof(value) == "table" and value or { value }
end

local function taper(u)
    local peak = Config.TaperPeak
    if u < peak then
        return math.max(0.06, 1 - (1 - u / peak) ^ 2)
    end
    return math.max(0.06, 1 - ((u - peak) / (1 - peak)) ^ 1.4 * 0.94)
end

local function enemyOf(instance)
    local model = instance and instance:FindFirstAncestorOfClass("Model")
    while model do
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if humanoid then
            return model ~= LocalPlayer.Character and humanoid.Health > 0 and model or nil
        end
        model = model:FindFirstAncestorOfClass("Model")
    end
end

local petalFlutter = numberSequence({ { 0, 0 }, { 0.2, 0.6 }, { 0.4, -0.5 }, { 0.6, 0.6 }, { 0.8, -0.5 }, { 1, 0 } })

Styles.Aether = {
    Layers = {
        { Texture = "aether", Color = "Silk", Width = 0.75, Scroll = 1.2, LightEmission = 0.8, Brightness = 1.4 },
        { Texture = "glowbeam", Color = "Threads", Width = 0.05, Curve = 0.7, Spin = 5, Phase = 0, LightEmission = 1, Brightness = 2 },
        { Texture = "glowbeam", Color = "Threads", Width = 0.05, Curve = 0.7, Spin = 5, Phase = math.pi, LightEmission = 1, Brightness = 2 },
    },
    Shed = {
        {
            Texture = "dot", Color = "Motes", PerStud = 0.35, Rate = 0.3,
            Props = {
                Lifetime = NumberRange.new(1.2, 2),
                Speed = NumberRange.new(0.2, 0.6),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, 1.4, 0),
                Size = numberSequence({ { 0, 0.09 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.6,
            },
        },
        {
            Texture = "sparkle", Color = "Threads", PerStud = 0.15, Rate = 0.1,
            Props = {
                Lifetime = NumberRange.new(0.5, 0.9),
                Speed = NumberRange.new(0),
                Rotation = NumberRange.new(0, 90),
                Size = numberSequence({ { 0, 0 }, { 0.4, 0.28 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.6,
            },
        },
    },
}

Styles.Blossom = {
    Layers = {
        { Texture = "blossom", Color = "Garland", Width = 0.8, Scroll = 0.7, LightEmission = 0.1, Brightness = 1.3 },
    },
    Shed = {
        {
            Texture = "petal", Color = "Petals", PerStud = 0.4, Rate = 0.25,
            Props = {
                Lifetime = NumberRange.new(2.2, 3.4),
                Speed = NumberRange.new(0.4, 1.6),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, -3, 0),
                Drag = 1.3,
                Rotation = NumberRange.new(0, 360),
                RotSpeed = NumberRange.new(-160, 160),
                Squash = petalFlutter,
                Size = numberSequence({ { 0, 0 }, { 0.06, 0.3 }, { 0.85, 0.26 }, { 1, 0 } }),
                Transparency = numberSequence({ { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } }),
                LightEmission = 0.1,
                LightInfluence = 0.15,
                Brightness = 1.4,
            },
        },
        {
            Texture = "dot", Color = "Pollen", PerStud = 0.25, Rate = 0.1,
            Props = {
                Lifetime = NumberRange.new(1, 1.8),
                Speed = NumberRange.new(0.2, 0.8),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, 0.4, 0),
                Size = numberSequence({ { 0, 0.08 }, { 1, 0 } }),
                LightEmission = 0.8,
                Brightness = 1.5,
            },
        },
    },
}

Styles.Inferno = {
    Layers = {
        { Texture = "flame", Color = "Outer", Width = 0.8, Scroll = 3, LightEmission = 0.8, Brightness = 1.2 },
        { Texture = "flame", Color = "Inner", Width = 0.32, Scroll = 4.5, Transparency = 0.2, LightEmission = 0.8, Brightness = 1.2 },
    },
    Shed = {
        {
            Texture = "flamelet", Gradient = { "Inner", "Outer" }, PerStud = 0.45, Rate = 0.6,
            Props = {
                Lifetime = NumberRange.new(0.35, 0.7),
                Speed = NumberRange.new(0.5, 1.5),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, 7, 0),
                Rotation = NumberRange.new(-15, 15),
                Size = numberSequence({ { 0, 0.42 }, { 1, 0.05 } }),
                Transparency = numberSequence({ { 0, 0.1 }, { 1, 1 } }),
                LightEmission = 1,
                Brightness = 1.6,
            },
        },
        {
            Texture = "dot", Color = "Embers", PerStud = 0.3, Rate = 0.35,
            Props = {
                Lifetime = NumberRange.new(0.8, 1.4),
                Speed = NumberRange.new(1, 3),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, 4, 0),
                Drag = 1,
                Size = numberSequence({ { 0, 0.08 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.8,
            },
        },
        {
            Texture = "puff", Color = "Smoke", PerStud = 0.1, Rate = 0.15,
            Props = {
                Lifetime = NumberRange.new(1, 1.6),
                Speed = NumberRange.new(0.3, 0.8),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, 2, 0),
                Rotation = NumberRange.new(0, 360),
                RotSpeed = NumberRange.new(-30, 30),
                Size = numberSequence({ { 0, 0.5 }, { 1, 1.6 } }),
                Transparency = numberSequence({ { 0, 1 }, { 0.2, 0.65 }, { 1, 1 } }),
                LightEmission = 0,
                LightInfluence = 0.5,
            },
        },
    },
}

Styles.Plasma = {
    Layers = {
        { Texture = "plasma", Color = "Core", Width = 0.32, Scroll = 5, Transparency = 0.1, LightEmission = 1, Brightness = 1.3 },
        { Texture = "glowbeam", Color = "Strands", Width = 0.09, Curve = 0.8, Spin = 11, Phase = 0, LightEmission = 0.8, Brightness = 2.2 },
        { Texture = "glowbeam", Color = "Strands", Width = 0.09, Curve = 0.8, Spin = 11, Phase = math.pi, LightEmission = 0.8, Brightness = 2.2 },
    },
    Shed = {
        {
            Texture = "spark", Color = "Sparks", PerStud = 0.4, Rate = 0,
            Props = {
                Orientation = Enum.ParticleOrientation.VelocityParallel,
                Lifetime = NumberRange.new(0.2, 0.45),
                Speed = NumberRange.new(6, 12),
                SpreadAngle = Vector2.new(180, 180),
                Drag = 4,
                Size = numberSequence({ { 0, 0.24 }, { 1, 0.04 } }),
                LightEmission = 1,
                Brightness = 2,
            },
        },
        {
            Texture = "dot", Color = "Strands", PerStud = 0.3, Rate = 0.3,
            Props = {
                Lifetime = NumberRange.new(0.5, 1),
                Speed = NumberRange.new(0.3, 1),
                SpreadAngle = Vector2.new(180, 180),
                Size = numberSequence({ { 0, 0.14 }, { 1, 0 } }),
                Transparency = numberSequence({ { 0, 0.1 }, { 1, 1 } }),
                LightEmission = 1,
                Brightness = 1.6,
            },
        },
    },
}

Styles.Frost = {
    Layers = {
        { Texture = "frost", Color = "Ice", Width = 0.7, Scroll = 0.5, LightEmission = 0.7, Brightness = 1.5 },
    },
    Shed = {
        {
            Texture = "flake", Color = "Flakes", PerStud = 0.25, Rate = 0.25,
            Props = {
                Lifetime = NumberRange.new(1.6, 2.6),
                Speed = NumberRange.new(0.2, 0.8),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, -1.2, 0),
                Drag = 0.5,
                Rotation = NumberRange.new(0, 360),
                RotSpeed = NumberRange.new(-60, 60),
                Size = numberSequence({ { 0, 0 }, { 0.1, 0.22 }, { 1, 0.15 } }),
                Transparency = numberSequence({ { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } }),
                LightEmission = 0.6,
                Brightness = 1.5,
            },
        },
        {
            Texture = "sparkle", Color = "Glints", PerStud = 0.2, Rate = 0.15,
            Props = {
                Lifetime = NumberRange.new(0.3, 0.6),
                Speed = NumberRange.new(0),
                Rotation = NumberRange.new(0, 90),
                Size = numberSequence({ { 0, 0 }, { 0.5, 0.32 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.8,
            },
        },
        {
            Texture = "puff", Color = "Mist", PerStud = 0.08, Rate = 0.12,
            Props = {
                Lifetime = NumberRange.new(1.2, 2),
                Speed = NumberRange.new(0.1, 0.4),
                SpreadAngle = Vector2.new(180, 180),
                Rotation = NumberRange.new(0, 360),
                RotSpeed = NumberRange.new(-20, 20),
                Size = numberSequence({ { 0, 0.6 }, { 1, 1.8 } }),
                Transparency = numberSequence({ { 0, 1 }, { 0.25, 0.75 }, { 1, 1 } }),
                LightEmission = 0.2,
            },
        },
    },
}

Styles.Lightning = {
    Chain = { Spacing = 2.4, Jitter = 0.55, Interval = 0.05, Forks = 3 },
    Layers = {
        { Texture = "lightning", Color = "Bolt", Width = 0.4, Chain = true, LightEmission = 1, Brightness = 2.2 },
    },
    Shed = {
        {
            Texture = "spark", Color = "Sparks", PerStud = 0.25, Rate = 0.5,
            Props = {
                Orientation = Enum.ParticleOrientation.VelocityParallel,
                Lifetime = NumberRange.new(0.15, 0.35),
                Speed = NumberRange.new(5, 11),
                SpreadAngle = Vector2.new(180, 180),
                Drag = 5,
                Size = numberSequence({ { 0, 0.2 }, { 1, 0.04 } }),
                LightEmission = 1,
                Brightness = 2,
            },
        },
    },
}

Styles.Rift = {
    Layers = {
        { Texture = "glitch", Color = "Red", Width = 0.42, Shift = 0.16, Transparency = 0.25, LightEmission = 1, Brightness = 1.6 },
        { Texture = "glitch", Color = "Cyan", Width = 0.42, Shift = 0.16, Transparency = 0.25, LightEmission = 1, Brightness = 1.6 },
        { Texture = "glitch", Color = "Carrier", Width = 0.42, Scroll = 2, LightEmission = 1, Brightness = 1.4 },
    },
    Shed = {
        {
            Texture = "pixel", Color = "Pixels", PerStud = 0.45, Rate = 0.35,
            Props = {
                Lifetime = NumberRange.new(0.25, 0.6),
                Speed = NumberRange.new(0.2, 1.5),
                SpreadAngle = Vector2.new(180, 180),
                Size = numberSequence({ { 0, 0.16 }, { 1, 0.16 } }),
                Transparency = numberSequence({ { 0, 0 }, { 0.7, 0 }, { 1, 1 } }),
                LightEmission = 1,
                Brightness = 1.6,
            },
        },
    },
}

Styles.Starfall = {
    Layers = {
        { Texture = "startrail", Color = "Trail", Width = 0.5, Scroll = 1.5, LightEmission = 1, Brightness = 1.6 },
    },
    Shed = {
        {
            Texture = "sparkle", Color = "Stars", PerStud = 0.35, Rate = 0.3,
            Props = {
                Lifetime = NumberRange.new(1, 1.8),
                Speed = NumberRange.new(0.3, 1.2),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, -4, 0),
                Drag = 1,
                Rotation = NumberRange.new(0, 90),
                RotSpeed = NumberRange.new(-90, 90),
                Size = numberSequence({ { 0, 0.34 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.8,
            },
        },
        {
            Texture = "dot", Color = "Glow", PerStud = 0.4, Rate = 0.25,
            Props = {
                Lifetime = NumberRange.new(0.6, 1.2),
                Speed = NumberRange.new(0.2, 0.8),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, -1.5, 0),
                Size = numberSequence({ { 0, 0.1 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.5,
            },
        },
    },
    Trail = {
        Texture = "sparkle", Color = "Stars", Rate = 55,
        Props = {
            Lifetime = NumberRange.new(0.4, 0.9),
            Speed = NumberRange.new(1, 3),
            SpreadAngle = Vector2.new(180, 180),
            Acceleration = Vector3.new(0, -5, 0),
            Drag = 2,
            Rotation = NumberRange.new(0, 90),
            Size = numberSequence({ { 0, 0.32 }, { 1, 0 } }),
            LightEmission = 1,
            Brightness = 2,
        },
    },
}

Styles.Cosmos = {
    Layers = {
        { Texture = "cosmos", Color = "Nebula", Width = 0.85, Scroll = 0.6, LightEmission = 0.6, Brightness = 1.6 },
        { Texture = "startrail", Color = "Stars", Width = 0.3, Scroll = 1.5, Transparency = 0.2, LightEmission = 1, Brightness = 1.4 },
    },
    Shed = {
        {
            Texture = "sparkle", Color = "Stars", PerStud = 0.3, Rate = 0.3,
            Props = {
                Lifetime = NumberRange.new(0.8, 1.5),
                Speed = NumberRange.new(0.1, 0.4),
                SpreadAngle = Vector2.new(180, 180),
                Rotation = NumberRange.new(0, 90),
                Size = numberSequence({ { 0, 0 }, { 0.3, 0.3 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.8,
            },
        },
        {
            Texture = "ring", Color = "Rings", PerStud = 0.05, Rate = 0,
            Props = {
                Lifetime = NumberRange.new(0.8, 1.2),
                Speed = NumberRange.new(0),
                Size = numberSequence({ { 0, 0 }, { 1, 1.6 } }),
                Transparency = numberSequence({ { 0, 0.3 }, { 1, 1 } }),
                LightEmission = 1,
                Brightness = 1.4,
            },
        },
        {
            Texture = "dot", Color = "Dust", PerStud = 0.3, Rate = 0.25,
            Props = {
                Lifetime = NumberRange.new(1, 1.6),
                Speed = NumberRange.new(0.2, 0.6),
                SpreadAngle = Vector2.new(180, 180),
                Size = numberSequence({ { 0, 0.1 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.6,
            },
        },
    },
}

Styles.Void = {
    Layers = {
        { Texture = "void", Color = "Smoke", Width = 1.1, Scroll = -0.6, Transparency = 0.1, LightEmission = 0.15, LightInfluence = 0, Brightness = 1.3 },
    },
    Shed = {
        {
            Texture = "puff", Color = "Wisps", PerStud = 0.25, Rate = 0.35,
            Props = {
                Lifetime = NumberRange.new(1.2, 2),
                Speed = NumberRange.new(0.3, 1),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, 0.8, 0),
                Rotation = NumberRange.new(0, 360),
                RotSpeed = NumberRange.new(-40, 40),
                Size = numberSequence({ { 0, 0.35 }, { 1, 1.4 } }),
                Transparency = numberSequence({ { 0, 1 }, { 0.2, 0.5 }, { 1, 1 } }),
                LightEmission = 0.1,
                Brightness = 1.3,
            },
        },
        {
            Texture = "dot", Color = "Embers", PerStud = 0.3, Rate = 0.25,
            Props = {
                Lifetime = NumberRange.new(0.8, 1.5),
                Speed = NumberRange.new(0.5, 1.5),
                SpreadAngle = Vector2.new(180, 180),
                Acceleration = Vector3.new(0, 1, 0),
                Size = numberSequence({ { 0, 0.1 }, { 1, 0 } }),
                LightEmission = 1,
                Brightness = 1.8,
            },
        },
    },
}

local function fire(from, to, styleName, hit, force)
    styleName = styleName or Config.Style
    local style, settings, colors = Styles[styleName], Config.Styles[styleName], Config.Colors[styleName]
    if Unloaded or (not force and not Config.Enabled) or not style or not settings or not colors then return end
    local length = (to - from).Magnitude
    if length < 0.1 then return end

    local scale = (settings.Width or 1) * (Config.Width or 1)
    local lifeScale = math.clamp(tonumber(Config.Lifetime) or 1, 0.1, 5)
    local frame = CFrame.lookAt(from, to)
    local travel = settings.Speed == math.huge and 0 or length / settings.Speed
    local fadeStart = travel + (settings.Linger or 0.4) * lifeScale
    local finished = fadeStart + (settings.Fade or 0.5) * lifeScale
    local pieces = Config.Pieces

    local model = create("Model", { Name = styleName, Parent = Container })
    local anchor = newPart("Tracer", Vector3.one, model)
    anchor.CFrame = frame
    local tip = create("Attachment", { Parent = anchor })

    local function newBeam(layer, a0, a1, width0, width1)
        return create("Beam", {
            Attachment0 = a0,
            Attachment1 = a1,
            Texture = Textures[layer.Texture],
            TextureMode = Enum.TextureMode.Wrap,
            TextureLength = 1,
            TextureSpeed = layer.Scroll or 0,
            Width0 = width0,
            Width1 = width1,
            Segments = layer.Curve and 16 or 1,
            FaceCamera = true,
            Color = ColorSequence.new(colorList(colors[layer.Color])[1]),
            LightEmission = layer.LightEmission or 1,
            LightInfluence = layer.LightInfluence or 0,
            Brightness = layer.Brightness or 1,
            Parent = anchor,
        })
    end

    local ribbons, strands, bolt = {}, {}, nil
    for _, layer in style.Layers do
        local width = layer.Width * scale
        if layer.Chain then
            local count = math.max(2, math.ceil(length / style.Chain.Spacing))
            bolt = { Nodes = {}, Beams = {}, Forks = {}, Layer = layer }
            for i = 0, count do
                bolt.Nodes[i] = create("Attachment", { Position = Vector3.new(0, 0, -length * i / count), Parent = anchor })
            end
            for i = 1, count do
                table.insert(bolt.Beams, newBeam(layer, bolt.Nodes[i - 1], bolt.Nodes[i], width * taper((i - 1) / count), width * taper(i / count)))
            end
            for _ = 1, style.Chain.Forks do
                local a0 = create("Attachment", { Parent = anchor })
                local a1 = create("Attachment", { Parent = anchor })
                table.insert(bolt.Forks, { A0 = a0, A1 = a1, Beam = newBeam(layer, a0, a1, width * 0.4, width * 0.05) })
            end
        elseif layer.Curve then
            local a0 = create("Attachment", { Parent = anchor })
            local a1 = create("Attachment", { Parent = anchor })
            table.insert(strands, { A0 = a0, A1 = a1, Layer = layer, Beam = newBeam(layer, a0, a1, width * 0.3, width * 0.3) })
        else
            local ribbon = { Layer = layer, Width = width, Nodes = {}, Beams = {}, Shift = Vector3.zero }
            for k = 0, pieces do
                ribbon.Nodes[k] = create("Attachment", { Parent = anchor })
            end
            for k = 1, pieces do
                ribbon.Beams[k] = newBeam(layer, ribbon.Nodes[k - 1], ribbon.Nodes[k], width * taper((k - 1) / pieces), width * taper(k / pieces))
            end
            table.insert(ribbons, ribbon)
        end
    end

    local function jitterBolt()
        local nodes, count = bolt.Nodes, #bolt.Nodes
        for i = 1, count - 1 do
            local amount = style.Chain.Jitter * scale * math.sin(math.pi * i / count) ^ 0.5
            nodes[i].Position = Vector3.new(rng:NextNumber(-amount, amount), rng:NextNumber(-amount, amount), -length * i / count)
        end
        for _, fork in bolt.Forks do
            local on = rng:NextNumber() < 0.7
            fork.Beam.Enabled = on
            if on then
                local base = nodes[rng:NextInteger(1, count - 1)].Position
                local side = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), 0).Unit
                fork.A0.Position = base
                fork.A1.Position = base + side * rng:NextNumber(0.8, 2) * scale + Vector3.new(0, 0, -rng:NextNumber(0.5, 1.5))
            end
        end
    end

    local segments = {}
    local segmentCount = math.clamp(math.ceil(length / 4), 1, 14)
    local segmentLength = length / segmentCount
    for i = 1, segmentCount do
        local u = (i - 0.5) / segmentCount
        local profile = taper(u)
        local part = newPart("Shed", Vector3.new(0.3 * scale * profile, 0.3 * scale * profile, segmentLength), model)
        part.CFrame = frame * CFrame.new(0, 0, -segmentLength * (i - 0.5))
        local emitters = {}
        for _, shed in style.Shed or {} do
            local list = shed.Gradient and { false } or colorList(colors[shed.Color])
            for _, color in list do
                local props = table.clone(shed.Props)
                props.Texture = Textures[shed.Texture]
                props.Color = shed.Gradient and ColorSequence.new(colors[shed.Gradient[1]], colors[shed.Gradient[2]]) or ColorSequence.new(color)
                props.Size = scaleSequence(props.Size, scale * (0.35 + 0.65 * profile))
                props.Shape = Enum.ParticleEmitterShape.Box
                props.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
                props.Rate = shed.Rate * segmentLength * profile / #list
                props.Enabled = false
                props.LightInfluence = props.LightInfluence or 0
                props.Parent = part
                table.insert(emitters, { Emitter = create("ParticleEmitter", props), Count = shed.PerStud * segmentLength * profile / #list })
            end
        end
        segments[i] = { Pass = travel * u, Emitters = emitters }
    end

    local trail
    if style.Trail and travel > 0 then
        local props = table.clone(style.Trail.Props)
        props.Texture = Textures[style.Trail.Texture]
        props.Color = ColorSequence.new(colorList(colors[style.Trail.Color])[1])
        props.Size = scaleSequence(props.Size, scale)
        props.Rate = style.Trail.Rate
        props.LightInfluence = props.LightInfluence or 0
        props.Parent = tip
        trail = create("ParticleEmitter", props)
    end

    local impacted, lastJitter, lastShift = false, -math.huge, -math.huge
    heartbeat(function(_, elapsed)
        local d = travel > 0 and math.min(elapsed / travel, 1) * length or length
        local f = math.clamp((elapsed - fadeStart) / settings.Fade, 0, 1)
        local tailZ = -d * 0.8 * f * f
        local span = math.max(d + tailZ, 0.01)
        tip.Position = Vector3.new(0, 0, -d)
        local transparencyOf = function(base)
            return NumberSequence.new(base + (1 - base) * f)
        end
        local thin = 1 - 0.5 * f

        if elapsed - lastShift >= 0.06 then
            lastShift = elapsed
            for _, ribbon in ribbons do
                local amount = (ribbon.Layer.Shift or 0) * scale
                ribbon.Shift = amount > 0 and Vector3.new(rng:NextNumber(-amount, amount), rng:NextNumber(-amount, amount), 0) or Vector3.zero
            end
        end
        for _, ribbon in ribbons do
            local layer = ribbon.Layer
            local pieceLength = span / pieces
            local tile = ribbon.Width * TextureAspect[layer.Texture]
            local repeats = math.max(1, math.floor(pieceLength / tile + 0.5))
            for k = 0, pieces do
                local u = k / pieces
                ribbon.Nodes[k].Position = Vector3.new(0, 0, tailZ - span * u) + ribbon.Shift * taper(u)
            end
            local transparency = transparencyOf(layer.Transparency or 0)
            for k, beam in ribbon.Beams do
                beam.TextureLength = math.max(pieceLength / repeats, 0.05)
                beam.Transparency = transparency
                beam.Width0 = ribbon.Width * taper((k - 1) / pieces) * thin
                beam.Width1 = ribbon.Width * taper(k / pieces) * thin
            end
        end
        for _, strand in strands do
            local layer = strand.Layer
            local angle = elapsed * layer.Spin + layer.Phase
            strand.A0.CFrame = CFrame.new(0, 0, tailZ) * CFrame.Angles(0, 0, angle)
            strand.A1.CFrame = CFrame.new(0, 0, -d) * CFrame.Angles(0, 0, angle)
            local curve = math.min(layer.Curve * scale, span / 3)
            strand.Beam.CurveSize0, strand.Beam.CurveSize1 = curve, curve
            strand.Beam.Transparency = transparencyOf(layer.Transparency or 0)
        end
        if bolt then
            if f < 1 and elapsed - lastJitter >= style.Chain.Interval then
                lastJitter = elapsed
                jitterBolt()
            end
            local transparency = transparencyOf(bolt.Layer.Transparency or 0)
            for _, beam in bolt.Beams do
                beam.Transparency = transparency
            end
            for _, fork in bolt.Forks do
                fork.Beam.Transparency = transparency
            end
        end

        for _, segment in segments do
            if not segment.Passed and elapsed >= segment.Pass then
                segment.Passed = true
                for _, e in segment.Emitters do
                    local count = math.floor(e.Count + rng:NextNumber())
                    if count > 0 then
                        e.Emitter:Emit(count)
                    end
                    e.Emitter.Enabled = e.Emitter.Rate > 0
                end
            end
            if not segment.Stopped and elapsed >= fadeStart + settings.Fade * 0.4 then
                segment.Stopped = true
                for _, e in segment.Emitters do
                    e.Emitter.Enabled = false
                end
            end
        end

        if not impacted and elapsed >= travel then
            impacted = true
            if trail then
                trail.Enabled = false
            end

            if hit == true then
                local hitFx = env.HitEffects
                if hitFx and hitFx.Config and hitFx.Config.Enabled and hitFx.Config.OnDamage ~= false and hitFx.Play then
                    local style = styleName or hitFx.Config.Style
                    task.defer(function()
                        pcall(hitFx.Play, style, to)
                    end)
                end
            end
        end

        if elapsed >= finished then
            for _, beam in anchor:GetChildren() do
                if beam:IsA("Beam") then
                    beam.Enabled = false
                end
            end
            task.delay(3.6, model.Destroy, model)
            return false
        end
    end)
    return finished
end

local function segmentTravel(from, to, styleName)
    styleName = styleName or Config.Style
    local settings = Config.Styles[styleName]
    if not settings then
        return 0
    end
    local length = (to - from).Magnitude
    if length < 0.1 then
        return 0
    end
    if settings.Speed == math.huge or not settings.Speed or settings.Speed <= 0 then
        return 0
    end
    return length / settings.Speed
end

local function firePath(points, styleName, hit, force)
    if Unloaded or (not force and not Config.Enabled) or type(points) ~= "table" or #points < 2 then
        return
    end
    styleName = styleName or Config.Style
    local cleaned = {}
    for i = 1, #points do
        local p = points[i]
        if typeof(p) == "Vector3" and p.X == p.X and p.Y == p.Y and p.Z == p.Z then
            local prev = cleaned[#cleaned]
            if not prev or (p - prev).Magnitude >= 0.1 then
                cleaned[#cleaned + 1] = p
            end
        end
    end
    if #cleaned < 2 then
        return
    end

    local function step(index)
        if Unloaded or (not force and not Config.Enabled) or index >= #cleaned then
            return
        end
        local from, to = cleaned[index], cleaned[index + 1]
        local isLast = index + 1 >= #cleaned
        fire(from, to, styleName, isLast and hit or nil, force)
        if index + 1 < #cleaned then
            local delay = segmentTravel(from, to, styleName)
            if delay <= 0 then
                step(index + 1)
            else
                task.delay(delay, function()
                    step(index + 1)
                end)
            end
        end
    end
    step(1)
end

local function pathTravel(points, styleName)
    if type(points) ~= "table" or #points < 2 then
        return 0
    end
    local total = 0
    for i = 1, #points - 1 do
        total += segmentTravel(points[i], points[i + 1], styleName)
    end
    return total
end

local function main()
    loadTextures()
    Container = create("Folder", { Name = "Tracers", Parent = workspace.CurrentCamera })

    task.spawn(function()
        local index, flip = 0, false
        while not Unloaded do
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if Config.Demo and root then
                index = index % #Config.DemoStyles + 1
                flip = not flip
                local half = Config.DemoSpan / 2
                local height = rng:NextNumber(0.5, 3)
                local a = root.CFrame * Vector3.new(-half, height, -Config.DemoDistance)
                local b = root.CFrame * Vector3.new(half, height + rng:NextNumber(-1.5, 1.5), -Config.DemoDistance - rng:NextNumber(-4, 4))
                if flip then
                    a, b = b, a
                end
                local ok, err = pcall(fire, a, b, Config.DemoStyles[index])
                if not ok then
                    warn(`[Tracers] {err}`)
                end
            end
            task.wait(Config.DemoInterval)
        end
    end)

    local function ragebotActive()
        local rage = env.Rage
        return type(rage) == "table" and type(rage.Config) == "table" and rage.Config.Enabled == true
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    table.insert(Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not Config.Enabled or not Config.OnShoot or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if ragebotActive() then
            return
        end
        local character = LocalPlayer.Character
        local tool = character and character:FindFirstChildOfClass("Tool")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not tool or not root then return end
        local handle = tool:FindFirstChild("Handle")
        local from = handle and handle:IsA("BasePart") and handle.Position or root.Position
        local mouse = UserInputService:GetMouseLocation()
        local ray = workspace.CurrentCamera:ViewportPointToRay(mouse.X, mouse.Y)
        rayParams.FilterDescendantsInstances = { character, Container }
        local hit = workspace:Raycast(ray.Origin, ray.Direction * Config.MaxDistance, rayParams)
        fire(from, hit and hit.Position or ray.Origin + ray.Direction * Config.MaxDistance, Config.Style, hit and hit.Instance)
    end))

    local Restores = {}
    local function findModules()
        if not getgc or (getactors and #getactors() > 0) then return end
        for _, value in getgc(true) do
            if type(value) == "table" and rawget(value, "ScreenCull") and rawget(value, "NetworkClient") then
                local modules = {}
                for name, data in value do
                    modules[name] = type(data) == "table" and data.module ~= nil and data.module or data
                end
                return modules
            end
        end
    end
    local okModules, modules = pcall(findModules)
    modules = okModules and modules or nil
    if modules then
        env._TapologyModules = modules
    end

    local lastHitSoundAt = 0
    local function playHitSound(force)
        if not force and not Config.HitSounds then
            return false
        end
        local now = os.clock()
        if now - lastHitSoundAt < 0.035 then
            return false
        end
        lastHitSoundAt = now
        local id = Config.HitSoundIds and Config.HitSoundIds[Config.HitSound]
        if type(id) ~= "string" or id == "" then
            return false
        end
        local sound = Instance.new("Sound")
        sound.Name = "TapologyHitSound"
        sound.SoundId = id
        sound.Volume = math.clamp(tonumber(Config.HitSoundVolume) or 1, 0, 5)
        sound.PlaybackSpeed = math.clamp(tonumber(Config.HitSoundPitch) or 1, 0.1, 3)
        sound.Looped = false
        sound.PlayOnRemove = false
        sound.Parent = SoundService
        local played = false
        if typeof(SoundService.PlayLocalSound) == "function" then
            played = pcall(function()
                SoundService:PlayLocalSound(sound)
            end)
        end
        if not played then
            played = pcall(function()
                sound:Play()
            end)
        else

            pcall(function()
                sound:Play()
            end)
        end
        task.delay(4, function()
            if sound then
                sound:Destroy()
            end
        end)
        return played
    end

    local function entryHealth(entry)
        if not entry then
            return nil
        end
        if entry.getHealth then
            local ok, hp = pcall(entry.getHealth, entry)
            if ok and type(hp) == "number" then
                return hp
            end
        end
        if type(entry._health) == "number" then
            return entry._health
        end
        return nil
    end

    local function resolveEntry(player)
        local rep = modules and modules.ReplicationInterface
        if not (player and rep and rep.getEntry) then
            return nil
        end
        local ok, entry = pcall(rep.getEntry, rep, player)
        if ok then
            return entry
        end
        ok, entry = pcall(rep.getEntry, player)
        return ok and entry or nil
    end

    local armedHits = {}
    local markerHits = {}

    local function notifyHitMarker(player, partOrPos)
        local onMarker = env._TapologyOnHitMarker
        if type(onMarker) ~= "function" then
            return
        end
        local key = tostring(player)
        local now = os.clock()
        if markerHits[key] and now - markerHits[key] < 0.03 then
            return
        end
        markerHits[key] = now
        pcall(onMarker, player, partOrPos)
    end

    local function notifyHit(player, partOrPos)
        if Config.HitSounds then
            playHitSound(true)
        end
        notifyHitMarker(player, partOrPos)
        if Config.HitLogs then
            local rage = env.Rage
            local label = partOrPos
            if typeof(partOrPos) == "Vector3" then
                label = nil
            end
            if rage and rage.LogHit then
                rage.LogHit(player.Name, label)
            else
                local ui = env.Tapology or env.Library
                if ui and ui.Notify then
                    ui:Notify(string.format("hit ( %s )%s", player.Name, label and (" · " .. tostring(label)) or ""), Config.HitLogDuration or 3.5)
                end
            end
        end
    end

    local function armManualHit(player, partOrPos, opts)
        if not player or player == LocalPlayer then
            return
        end
        opts = opts or {}

        if opts.marker ~= false then
            notifyHitMarker(player, partOrPos)
        end
        if os.clock() < (env._TapologySkipHitLogUntil or 0) then
            return
        end
        if armedHits[player] and os.clock() - armedHits[player] < 0.04 then
            return
        end
        armedHits[player] = os.clock()
        local entry = resolveEntry(player)
        local hpBefore = entryHealth(entry)
        if typeof(hpBefore) ~= "number" then
            hpBefore = 100
        end
        task.spawn(function()
            for _ = 1, 14 do
                task.wait(0.07)
                if Unloaded then
                    return
                end
                if os.clock() < (env._TapologySkipHitLogUntil or 0) then
                    return
                end
                entry = resolveEntry(player) or entry
                local hpAfter = entryHealth(entry)
                local damaged = typeof(hpAfter) == "number" and hpAfter < hpBefore - 0.15
                local dead = entry and (entry._alive == false or (typeof(hpAfter) == "number" and hpAfter <= 0))
                if damaged or dead then

                    if Config.HitSounds then
                        playHitSound(true)
                    end
                    if Config.HitLogs then
                        local rage = env.Rage
                        local label = partOrPos
                        if typeof(partOrPos) == "Vector3" then
                            label = nil
                        end
                        if rage and rage.LogHit then
                            rage.LogHit(player.Name, label)
                        else
                            local ui = env.Tapology or env.Library
                            if ui and ui.Notify then
                                ui:Notify(string.format("hit ( %s )%s", player.Name, label and (" · " .. tostring(label)) or ""), Config.HitLogDuration or 3.5)
                            end
                        end
                    end
                    return
                end
                if typeof(hpAfter) == "number" then
                    hpBefore = math.min(hpBefore, hpAfter)
                end
            end
        end)
    end

    local function muzzlePosition(fallback)
        local from = fallback
        local weapons = modules and modules.WeaponControllerInterface
        local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
        local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
        local barrel = weapon and weapon._barrelPart
        if typeof(barrel) == "Instance" and barrel:IsA("BasePart") then
            from = barrel.Position + barrel.CFrame.LookVector * math.max(barrel.Size.Z * 0.5, 0.05)
        end
        return from, weapon
    end

    local function fireMuzzleToImpact(from, direction, styleName, force)

        if not force and ragebotActive() then
            return
        end
        if typeof(from) ~= "Vector3" or typeof(direction) ~= "Vector3" or direction.Magnitude < 1e-4 then
            return
        end
        direction = direction.Unit
        local ignore = { workspace.CurrentCamera, Container }
        local playersFolder = workspace:FindFirstChild("Players")
        local ignoreFolder = workspace:FindFirstChild("Ignore")
        if playersFolder then
            ignore[#ignore + 1] = playersFolder
        end
        if ignoreFolder then
            ignore[#ignore + 1] = ignoreFolder
        end
        local character = LocalPlayer.Character
        if character then
            ignore[#ignore + 1] = character
        end
        rayParams.FilterDescendantsInstances = ignore
        local maxDist = math.clamp(tonumber(Config.MaxDistance) or 2000, 50, 5000)
        local hit = workspace:Raycast(from, direction * maxDist, rayParams)
        local to = hit and hit.Position or (from + direction * maxDist)
        task.defer(fire, from, to, styleName or Config.Style, hit and hit.Instance, force)
    end

    local function unpackBulletHit(...)
        local args = table.pack(...)
        local player, hitPos, partName
        for i = 1, args.n do
            local value = args[i]
            if typeof(value) == "Instance" and value:IsA("Player") and not player then
                player = value
            elseif typeof(value) == "Vector3" and not hitPos then
                hitPos = value
            elseif typeof(value) == "Instance" and value:IsA("BasePart") and not hitPos then
                hitPos = value
            elseif type(value) == "string" and not partName then
                partName = value
            elseif type(value) == "table" and typeof(value._player) == "Instance" and not player then
                player = value._player
            end
        end
        return player, hitPos or partName
    end

    if modules and modules.BulletObject and type(modules.BulletObject.new) == "function" then
        local nextNew = modules.BulletObject.new
        modules.BulletObject.new = function(data, ...)
            if type(data) == "table" and data.onplayerhit then
                local prevHit = data.onplayerhit
                data.onplayerhit = function(...)
                    local player, where = unpackBulletHit(...)
                    if player and player ~= LocalPlayer then

                        armManualHit(player, where)
                    end
                    return prevHit(...)
                end
                if Config.Enabled and typeof(data.position) == "Vector3" and typeof(data.velocity) == "Vector3" and data.velocity.Magnitude > 1e-4 then
                    local from = muzzlePosition(data.position)
                    fireMuzzleToImpact(from, data.velocity, Config.Style, false)
                end
            end
            return nextNew(data, ...)
        end
        table.insert(Restores, function()
            modules.BulletObject.new = nextNew
        end)
    end

    if modules and modules.NetworkClient and type(modules.NetworkClient.send) == "function" then
        local network = modules.NetworkClient
        local nextSend = network.send
        network.send = function(self, name, ...)
            local eventName = name
            local a = table.pack(...)

            if type(self) == "string" then
                eventName = self
                a = table.pack(name, ...)
            end
            if eventName == "newbullets" and Config.Enabled then
                local bulletData = a[2]
                if type(bulletData) == "table" then
                    local bullets = bulletData.bullets
                    local first = type(bullets) == "table" and bullets[1]
                    local direction = type(first) == "table" and first[1]
                    local fallback = bulletData.firepos or bulletData.camerapos
                    if typeof(direction) == "Vector3" and typeof(fallback) == "Vector3" then
                        local from = muzzlePosition(fallback)
                        fireMuzzleToImpact(from, direction, Config.Style, false)
                    end
                end
            elseif eventName == "bullethit" then

                local player, where = unpackBulletHit(table.unpack(a, 1, a.n))
                if player and player ~= LocalPlayer then
                    armManualHit(player, where)
                end
            end
            if type(self) == "string" then
                return nextSend(self, name, ...)
            end
            return nextSend(self, name, ...)
        end
        table.insert(Restores, function()
            network.send = nextSend
        end)
    end

    env.Tracers = {
        Config = Config,
        Styles = (function()
            local names = {}
            for name in Config.Styles do
                table.insert(names, name)
            end
            table.sort(names)
            return names
        end)(),
        HitSounds = (function()
            local names = {}
            for name in Config.HitSoundIds do
                table.insert(names, name)
            end
            table.sort(names)
            return names
        end)(),
        StyleDefs = Styles,
        Fire = fire,
        FirePath = firePath,
        PathTravel = pathTravel,
        PlayHitSound = playHitSound,
        SetEnabled = function(on)
            Config.Enabled = on and true or false
        end,
        SetStyle = function(styleName)
            if Config.Styles[styleName] then
                Config.Style = styleName
            end
        end,

        SetColor = function(styleName, slot, color)
            Config.Colors[styleName] = Config.Colors[styleName] or {}
            Config.Colors[styleName][slot] = color
        end,
        Unload = function()
            Unloaded = true
            for _, connection in Connections do
                connection:Disconnect()
            end
            for _, restore in Restores do
                pcall(restore)
            end
            Container:Destroy()
            env.Tracers = nil
        end,
    }
end

TextureIds = {
    blossom = "rbxassetid://129556989689384",
    plasma = "rbxassetid://94136981752496",
    lightning = "rbxassetid://111593746793021",
    startrail = "rbxassetid://85942207251913",
    void = "rbxassetid://110093922567787",
    aether = "rbxassetid://90054071953795",
    flame = "rbxassetid://97446809758616",
    frost = "rbxassetid://80128546239435",
    glitch = "rbxassetid://100727003138673",
    cosmos = "rbxassetid://133771181538188",
    glowbeam = "rbxassetid://78577585159137",
    petal = "rbxassetid://91106269226329",
    dot = "rbxassetid://79451523688005",
    spark = "rbxassetid://83337948032750",
    puff = "rbxassetid://98688240512895",
    pixel = "rbxassetid://98416523570354",
    ring = "rbxassetid://130480777986951",
    sparkle = "rbxassetid://86312741349859",
    flamelet = "rbxassetid://122232318996052",
    flake = "rbxassetid://75489274996945",
}
TextureAspect = {
    blossom = 4,
    plasma = 4,
    lightning = 4,
    startrail = 4,
    void = 2,
    aether = 4,
    flame = 2.66667,
    frost = 2.66667,
    glitch = 4,
    cosmos = 2.66667,
    glowbeam = 2,
    petal = 1,
    dot = 1,
    spark = 1,
    puff = 1,
    pixel = 1,
    ring = 1,
    sparkle = 1,
    flamelet = 1,
    flake = 1,
}

do
    local okTracers, errTracers = pcall(main)
    if not okTracers then
        warn("[Tracers] main failed:", errTracers)
    end
end

end
]=] },
    { name = "rage", source = [[local cloneref = cloneref or function(instance)
    return instance
end
local workspace = cloneref(workspace)

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local GuiService = cloneref(game:GetService("GuiService"))

local Config = {

    Enabled = false,
    Priority = "Closest to Crosshair",
    FirePositionScanning = true,
    FirePositionOffset = 10,
    HitPositionScanning = true,
    ConstrainHitPositions = true,
    Prediction = true,
    PredictionWindow = 0.12,
    PredictionIterations = 8,
    PredictionMaxTime = 5,
    MaxPredictionSpeed = 150,
    PredictionResetDistance = 20,
    HitboxPointScale = 0.35,
    HitPositionScanMode = "V1",
    HitPositionOffset = 10,
    ShootEffects = true,
    UseFOV = false,
    FOVRadius = 350,
    MaxDistance = 1500,
    MaxTargets = 12,
    MaxBulletChecks = 40,
    MaxFrameChecks = 128,
    ScanBudgetMs = 5,
    ScanMissCooldown = 0.01,
    ModuleTimeout = 15,

    Mode = "default",
    WhitelistFriendlyStatus = true,
    Targets = {},
    Friendlies = {},

    Resolver = false,
    ResolverCooldown = 1.0,
    ResolverStrength = 4,
    ResolverHeight = 0.35,
    ResolverHold = 0.45,
    ResolverFlash = 0.35,

    AntiAim = false,
    PitchAmount = 0,
    YawAmount = 180,

    FakeLag = false,
    FakeLagAmount = 1.2,
    FakeLagHold = 0.35,
    FakeLagSmooth = 0.45,

    Indicators = true,
    IndicatorRagebot = true,
    IndicatorResolver = true,
    IndicatorRageActive = Color3.fromRGB(255, 255, 255),
    IndicatorRageIdle = Color3.fromRGB(255, 255, 255),
    IndicatorResolverReady = Color3.fromRGB(255, 255, 255),
    IndicatorResolverCooldown = Color3.fromRGB(180, 180, 190),
}

local env = getgenv and getgenv() or _G
if env.RageBot and env.RageBot.Unload then
    pcall(env.RageBot.Unload)
end
if env.Rage and env.Rage.Unload then
    pcall(env.Rage.Unload)
end

local LocalPlayer = Players.LocalPlayer
local PhantomForces = game.PlaceId == 292439477 or game.PlaceId == 299659045
local Connections = {}
local Restores = {}
local Unloaded = false
local Controller
local Runtime = { Status = "Starting", LastError = nil, Checks = 0, ScanMisses = 0, Shots = 0 }

local Modules
if PhantomForces and type(getfflag) == "function" and type(setfflag) == "function" then
    pcall(function()
        if tostring(getfflag("DebugRunParallelLuaOnMainThread")):lower() ~= "true" then
            setfflag("DebugRunParallelLuaOnMainThread", "True")
        end
    end)
end

local moduleNames = {
    "ScreenCull", "NetworkClient", "ReplicationInterface", "BulletCheck",
    "CharacterInterface", "GameClock", "PublicSettings", "WeaponControllerInterface",
    "Effects", "AudioSystem", "HudCrosshairsInterface", "RoundSystemClientFactory", "CameraInterface",
}

local function usableModules(modules)
    return type(modules) == "table"
        and type(modules.NetworkClient) == "table" and type(modules.NetworkClient.send) == "function"
        and type(modules.ReplicationInterface) == "table"
        and type(modules.ReplicationInterface.operateOnAllEntries) == "function"
        and type(modules.WeaponControllerInterface) == "table"
        and type(modules.WeaponControllerInterface.getActiveWeaponController) == "function"
        and type(modules.BulletCheck) == "function"
        and type(modules.PublicSettings) == "table"
end

local function findModules()
    if env._TapologyModules and usableModules(env._TapologyModules) then
        return env._TapologyModules
    end
    if shared and type(shared.require) == "function" then
        local found = {}
        for _, name in ipairs(moduleNames) do
            local ok, value = pcall(shared.require, name)
        if ok then
                found[name] = value
        end
    end
        if usableModules(found) then
            return found
        end
    end
    if type(getgc) ~= "function" then
        return
    end
    for _, value in ipairs(getgc(true)) do
        if type(value) == "table" and rawget(value, "ScreenCull") and rawget(value, "NetworkClient") then
            local found = {}
            for name, data in pairs(value) do
                found[name] = type(data) == "table" and rawget(data, "module") ~= nil and rawget(data, "module") or data
            end
            if usableModules(found) then
                return found
            end
        end
    end
end

local function number(value, fallback, low, high)
    value = tonumber(value)
    if not value or value ~= value then
        value = fallback
    end
    return math.clamp(value, low, high)
end

local function marked(player)
    if Config.WhitelistFriendlyStatus and Config.Friendlies[player] then
        return false
    end
    return true
end

local function isFiniteVec3(v)
    return typeof(v) == "Vector3"
        and v.X == v.X and v.Y == v.Y and v.Z == v.Z
        and math.abs(v.X) < 1e6 and math.abs(v.Y) < 1e6 and math.abs(v.Z) < 1e6
end

local function characterHash(entry)
    return entry and entry._thirdPersonObject and entry._thirdPersonObject._characterModelHash
end

local function entryAimPos(entry)
    local hash = characterHash(entry)
    if hash and hash.Head and isFiniteVec3(hash.Head.Position) then
        return hash.Head.Position
    end
    return entry._receivedPosition
end

local function entryHealth(entry)
    if entry.getHealth then
        local ok, hp = pcall(entry.getHealth, entry)
        if ok and type(hp) == "number" then
            return hp
        end
    end
    if type(entry._health) == "number" then
        return entry._health
    end
    return 100
end

local function priorityScore(entry, origin, camera, mouse)
    local position = entryAimPos(entry)
    if not isFiniteVec3(position) then
        return math.huge
    end
    local distance = (position - origin).Magnitude
    if distance > number(Config.MaxDistance, 1500, 1, 10000) then
        return math.huge
    end
    local screenScore
    if camera then
        local screen, onScreen = camera:WorldToViewportPoint(position)
        if onScreen and screen.Z > 0 then
            local dx, dy = screen.X - mouse.X, screen.Y - mouse.Y
            screenScore = dx * dx + dy * dy
        end
    end
    if Config.UseFOV then
        local radius = number(Config.FOVRadius, 350, 1, 5000)
        if not screenScore or screenScore > radius * radius then
            return math.huge
        end
    end
    if Config.Priority == "Closest to Local" then
        return distance
    end
    if Config.Priority == "Lowest Health" then
        return entryHealth(entry) + distance * 0.001
    end
    return screenScore or (1e9 + distance)
end

local frameCheckBudget, frameCheckDeadline = 0, 0
local ScanStates = setmetatable({}, { __mode = "k" })

local function getClosestPlayers(origin)
    local ordered = {}
    if not (Modules and Modules.ReplicationInterface) then
        return ordered
    end
    local camera = workspace.CurrentCamera
    local mouse = UserInputService:GetMouseLocation()
    local okInset, inset = pcall(GuiService.GetGuiInset, GuiService)
    if okInset then
        mouse = mouse - inset
    end
    local scored = {}
    local ok, reason = pcall(Modules.ReplicationInterface.operateOnAllEntries, function(player, entry)
        local hash = characterHash(entry)
        if not player or not player.Parent or not entry._isEnemy or not hash or not hash.Head or not marked(player) then
            return
        end
        if entryHealth(entry) <= 0 then
            return
        end
        local score = priorityScore(entry, origin, camera, mouse)
        if score ~= score or score == math.huge then
            return
        end
        scored[#scored + 1] = {
            entry = entry,
            score = score,
            selected = Config.Targets[player] == true,
            id = player.UserId or 0,
        }
    end)
    if not ok then
        Runtime.LastError = tostring(reason)
        return ordered
    end
    table.sort(scored, function(a, b)
        if a.selected ~= b.selected then
            return a.selected
        end
        if a.score == b.score then
            return a.id < b.id
        end
        return a.score < b.score
    end)
    for index = 1, math.min(#scored, number(Config.MaxTargets, 12, 1, 12)) do
        ordered[index] = scored[index].entry
    end
    return ordered
end

local function trajectory(origin, acceleration, target, speed)
    if not isFiniteVec3(origin) or not isFiniteVec3(acceleration) or not isFiniteVec3(target)
        or type(speed) ~= "number" or speed ~= speed or speed <= 0 or speed == math.huge
    then
        return
    end
    local delta = target - origin
    local distanceSquared = delta:Dot(delta)
    if distanceSquared < 1e-8 then
        return
    end
    local a = acceleration:Dot(acceleration) * 0.25
    if a < 1e-12 then
        return delta.Unit * speed, math.sqrt(distanceSquared) / speed
    end
    local b = -(delta:Dot(acceleration) + speed * speed)
    local discriminant = b * b - 4 * a * distanceSquared
    if discriminant < 0 then
        return
    end
    local root = math.sqrt(discriminant)
    local q = -0.5 * (b + (b >= 0 and root or -root))
    local first = q / a
    local second = q ~= 0 and distanceSquared / q or math.huge
    local timeSquared = math.min(first > 0 and first or math.huge, second > 0 and second or math.huge)
    if timeSquared == math.huge then
        return
    end
    local flightTime = math.sqrt(timeSquared)
    if flightTime <= 0 then
        return
    end
    local velocity = (delta - acceleration * (0.5 * timeSquared)) / flightTime
    if isFiniteVec3(velocity) then
        return velocity, flightTime
    end
end

local MotionStates = setmetatable({}, { __mode = "k" })

local function sampleMotion()
    local interface = Modules and Modules.ReplicationInterface
    if not interface then
        return
    end
    local now = os.clock()
    interface.operateOnAllEntries(function(_, entry)
        local hash = characterHash(entry)
        local head = hash and hash.Head
        if not head or not head.Parent or not entry._isEnemy or entryHealth(entry) <= 0 then
            MotionStates[entry] = nil
            return
        end
        local root = hash.Torso or hash.UpperTorso or head
        if not root.Parent then
            root = head
        end
        local position = root.Position
        if not isFiniteVec3(position) then
            return
        end
        local state = MotionStates[entry]
        local jumpLimit = number(Config.PredictionResetDistance, 20, 2, 100)
        if not state or state.Head ~= head or (position - state.Position).Magnitude > jumpLimit then
            state = {
                Head = head,
                Position = position,
                Samples = {},
                Velocity = Vector3.zero,
                ResetAt = state and now or nil,
            }
            MotionStates[entry] = state
        end
        local samples = state.Samples
        local last = samples[#samples]
        if last and now - last.Time < 0.005 then
            return
        end
        samples[#samples + 1] = { Time = now, Position = position }
        state.Position = position
        local window = number(Config.PredictionWindow, 0.12, 0.03, 0.3)
        while #samples > 2 and now - samples[1].Time > window do
            table.remove(samples, 1)
        end
        local count = #samples
        if count < 2 or now - samples[1].Time < 0.015 then
            return
        end
        local sumTime, sumTimeSquared = 0, 0
        local sumPosition, sumWeighted = Vector3.zero, Vector3.zero
        for _, sample in ipairs(samples) do
            local time = sample.Time - now
            local displacement = sample.Position - position
            sumTime = sumTime + time
            sumTimeSquared = sumTimeSquared + time * time
            sumPosition = sumPosition + displacement
            sumWeighted = sumWeighted + displacement * time
        end
        local denominator = count * sumTimeSquared - sumTime * sumTime
        if denominator <= 1e-10 then
            return
        end
        local velocity = (sumWeighted * count - sumPosition * sumTime) / denominator
        local maximum = number(Config.MaxPredictionSpeed, 150, 1, 500)
        if isFiniteVec3(velocity) and velocity.Magnitude <= maximum then
            state.Velocity = velocity.Magnitude < 0.5 and Vector3.zero or velocity
            state.UpdatedAt = now
        else
            state.Samples = { { Time = now, Position = position } }
            state.Velocity = Vector3.zero
            state.UpdatedAt = now
        end
    end)
end

local function targetVelocity(entry)
    if Config.Prediction == false then
        return Vector3.zero
    end
    local state = entry and MotionStates[entry]
    if state and state.ResetAt and not state.UpdatedAt and os.clock() - state.ResetAt < 0.15 then
        return Vector3.zero
    end
    if state and state.UpdatedAt and os.clock() - state.UpdatedAt < 0.15 then
        return state.Velocity
    end
    local velocity = entry and entry._velspring and entry._velspring.t
    if isFiniteVec3(velocity) and velocity.Magnitude <= number(Config.MaxPredictionSpeed, 150, 1, 500) then
        return velocity
    end
    return Vector3.zero
end

local scanVerticesV1 = {
    Vector3.new(0, 0, -1),
    Vector3.new(0, -1, 0),
    Vector3.new(-1, 0, 0),
    Vector3.new(0, 1, 0),
    Vector3.new(1, 0, 0),
    Vector3.new(0, 0, 1),
}

local scanVerticesV2 = {
    Vector3.new(1, 0, 0),
    Vector3.new(-1, 0, 0),
    Vector3.new(0, 1, 0),
    Vector3.new(0, -1, 0),
    Vector3.new(0, 0, 1),
    Vector3.new(0, 0, -1),
    Vector3.new(0.707, 0.707, 0),
    Vector3.new(0.707, -0.707, 0),
    Vector3.new(-0.707, 0.707, 0),
    Vector3.new(-0.707, -0.707, 0),
    Vector3.new(0.707, 0, 0.707),
    Vector3.new(0.707, 0, -0.707),
    Vector3.new(-0.707, 0, 0.707),
    Vector3.new(-0.707, 0, -0.707),
}

local function getPositionOffsets(origin, target, offset, mode)
    mode = mode == "V2" and "V2" or "V1"
    local maxOffset = mode == "V2" and 28 or 16
    offset = number(offset, 0, 0, maxOffset)
    if offset < 0.001 or (target - origin).Magnitude < 0.001 then
        return { origin }
    end
    local look = CFrame.new(origin, target)
    local offsets = {}

    local function push(point)
        if isFiniteVec3(point) then
            offsets[#offsets + 1] = point
        end
    end

    if mode == "V1" then
        local cframe = look
        for _, vertex in scanVerticesV1 do
            push(cframe * (vertex * offset))
        end
    else
        for _, scale in { 0.55, 1 } do
            local radius = offset * scale
            for _, vertex in scanVerticesV2 do
                push(look * (vertex * radius))
            end
        end
    end

    if #offsets == 0 then
        return { origin }
    end
    return offsets
end

local function interceptTrajectory(origin, acceleration, target, speed, movement)
    if not isFiniteVec3(movement) then
        movement = Vector3.zero
    end
    local velocity, time = trajectory(origin, acceleration, target, speed)
    if not velocity then
        return
    end
    local lifetime = Modules and Modules.PublicSettings and Modules.PublicSettings.bulletLifeTime
    local limit = type(lifetime) == "number" and lifetime > 0 and lifetime or number(Config.PredictionMaxTime, 5, 0.1, 20)
    if time > limit then
        return
    end
    if movement.Magnitude < 0.001 then
        return velocity, time, target
    end
    local iterations = math.floor(number(Config.PredictionIterations, 8, 3, 16))
    for _ = 1, iterations do
        local predicted = target + movement * time
        velocity, time = trajectory(origin, acceleration, predicted, speed)
        if not velocity or time > limit then
            return
        end
        local destination = target + movement * time
        local impact = origin + velocity * time + acceleration * (0.5 * time * time)
        if (impact - destination).Magnitude <= 0.01
            and math.abs(velocity.Magnitude - speed) <= math.max(0.001, speed * 0.00001)
        then
            return velocity, time, destination
        end
                    end
                end

local function headScanPoints(entry, fallback, origin)
    local hash = entry and characterHash(entry)
    local head = hash and hash.Head
    if not Config.ConstrainHitPositions or not head or not head.Parent then
        return getPositionOffsets(fallback, origin, Config.HitPositionOffset, Config.HitPositionScanMode)
    end
    local scale = number(Config.HitboxPointScale, 0.35, 0.05, 0.45)
    local offset = number(Config.HitPositionOffset, 10, 0, 28)
    local extent = head.Size * scale
    extent = Vector3.new(math.min(extent.X, offset), math.min(extent.Y, offset), math.min(extent.Z, offset))
    local vertices = {
        Vector3.new(1, 0, 0),
        Vector3.new(-1, 0, 0),
        Vector3.new(0, 1, 0),
        Vector3.new(0, -1, 0),
        Vector3.new(0, 0, 1),
        Vector3.new(0, 0, -1),
    }
    if Config.HitPositionScanMode == "V2" then
        for x = -1, 1, 2 do
            for y = -1, 1, 2 do
                for z = -1, 1, 2 do
                    vertices[#vertices + 1] = Vector3.new(x, y, z)
                end
            end
    end
end
    local points = {}
    for _, vertex in ipairs(vertices) do
        points[#points + 1] = head.CFrame:PointToWorldSpace(
            Vector3.new(vertex.X * extent.X, vertex.Y * extent.Y, vertex.Z * extent.Z)
        )
    end
    return points
end

local function tryBulletPath(bulletCheck, origin, target, acceleration, speed, penetration, movement)
    local velocity, flightTime, predicted = interceptTrajectory(origin, acceleration, target, speed, movement)
    if not velocity then
        return false, false, nil, nil
    end
    local ok, result = pcall(bulletCheck, origin, predicted, velocity, acceleration, penetration, 1 / 50)
    return true, ok and result and true or false, velocity, flightTime, predicted
end

local function edgePeekPoints(origin, target, reach)
    local points = {}
    if not (isFiniteVec3(origin) and isFiniteVec3(target)) then
        return points
    end
    reach = number(reach, 10, 0.25, 12)
    local delta = target - origin
    local dist = delta.Magnitude
    if dist < 1.5 then
        return points
    end
    local dir = delta.Unit
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = {}
    if LocalPlayer.Character then
        ignore[#ignore + 1] = LocalPlayer.Character
    end
    local interface = Modules and Modules.ReplicationInterface
    if interface then
        pcall(interface.operateOnAllEntries, function(_, entry)
            local hash = characterHash(entry)
            local head = hash and hash.Head
            if head and head.Parent then
                ignore[#ignore + 1] = head.Parent
            end
        end)
    end
    params.FilterDescendantsInstances = ignore
    local hit = workspace:Raycast(origin, dir * (dist - 0.75), params)
    if not hit then
        return points
    end
    local normal = hit.Normal
    if normal.Magnitude < 1e-4 then
        return points
    end
    normal = normal.Unit
    local right = dir:Cross(Vector3.yAxis)
    if right.Magnitude < 1e-3 then
        right = dir:Cross(Vector3.xAxis)
    end
    right = right.Unit
    local up = right:Cross(dir)
    if up.Magnitude < 1e-3 then
        up = Vector3.yAxis
    else
        up = up.Unit
    end
    local axes = {
        right, -right, up, -up,
        (right + up).Unit, (right - up).Unit,
        (-right + up).Unit, (-right - up).Unit,
    }
    local function cap(point)
        local offset = point - origin
        if offset.Magnitude > reach then
            return origin + offset.Unit * reach
        end
        return point
    end
    local function push(point)
        if not isFiniteVec3(point) or #points >= 10 then
            return
        end
        point = cap(point)
        for _, existing in ipairs(points) do
            if (existing - point).Magnitude < 0.2 then
                return
            end
        end
        points[#points + 1] = point
    end
    for _, axis in ipairs(axes) do
        if #points >= 10 then
                break
            end
        local best
        local lo, hi = 0.2, reach
        for _ = 1, 4 do
            local mid = (lo + hi) * 0.5
            local candidate = cap(origin + axis * mid + normal * 0.35)
            local toTarget = target - candidate
            local blocked = toTarget.Magnitude > 0.5 and workspace:Raycast(candidate, toTarget, params)
            local clear = not blocked or (blocked.Position - target).Magnitude < 3
            if clear then
                best = candidate
                hi = mid
            else
                lo = mid
        end
    end
        if best then
            push(best)
                    end
                end
    return points
end

local function headEdgePoints(entry, origin, target)
    local hash = entry and characterHash(entry)
    local head = hash and hash.Head
    local points = {}
    if not (head and head.Parent and isFiniteVec3(target)) then
        return points
    end
    local reach = number(Config.HitPositionOffset, 10, 0, 12)
    local scale = number(Config.HitboxPointScale, 0.35, 0.05, 0.45)
    local extent = head.Size * scale
    local toUs = origin - target
    if toUs.Magnitude < 1e-3 then
        return points
    end
    toUs = toUs.Unit
    local right = toUs:Cross(Vector3.yAxis)
    if right.Magnitude < 1e-3 then
        right = Vector3.xAxis
    else
        right = right.Unit
    end

    local bias = {
        toUs,
        (toUs + right).Unit,
        (toUs - right).Unit,
        (toUs + Vector3.yAxis).Unit,
        (toUs * 0.6 + right).Unit,
    }
    for _, dir in ipairs(bias) do
        local localDir = head.CFrame:VectorToObjectSpace(dir)
        local corner = Vector3.new(
            math.clamp(localDir.X, -1, 1) * math.min(extent.X, reach),
            math.clamp(localDir.Y, -1, 1) * math.min(extent.Y, reach),
            math.clamp(localDir.Z, -1, 1) * math.min(extent.Z, reach)
        )
        local point = head.CFrame:PointToWorldSpace(corner)
        if isFiniteVec3(point) then
            points[#points + 1] = point
        end
    end
    return points
end

local function scanPositions(origin, target, acceleration, speed, penetration, entry)
    if not isFiniteVec3(origin) or not isFiniteVec3(target) or not isFiniteVec3(acceleration)
        or type(speed) ~= "number" or speed ~= speed or speed <= 0
    then
        return
    end
    local bulletCheck = Modules and Modules.BulletCheck
    if type(bulletCheck) ~= "function" then
        return
    end
    local movement = targetVelocity(entry)
    local checks = 0
    local limit = number(Config.MaxBulletChecks, 10, 1, 128)
    local function canProbe()
        return checks < limit and frameCheckBudget > 0 and os.clock() < frameCheckDeadline
    end
    local function probe(newOrigin, newTarget)
        checks = checks + 1
        frameCheckBudget = frameCheckBudget - 1
        Runtime.Checks = Runtime.Checks + 1
        local _, hit, velocity, flightTime, predicted =
            tryBulletPath(bulletCheck, newOrigin, newTarget, acceleration, speed, penetration, movement)
        if hit then
            return newOrigin, predicted, velocity, flightTime
        end
    end
    if not canProbe() then
        return
    end
    local o, t, v, flightTime = probe(origin, target)
    if o then
        return o, t, v, flightTime
    end
    local origins, targets = { origin }, { target }
    local function append(list, points)
        for _, point in ipairs(points) do
            local unique = true
            for _, existing in ipairs(list) do
                if (point - existing).Magnitude < 0.001 then
                    unique = false
                    break
            end
        end
            if unique then
                list[#list + 1] = point
            end
    end
end
    local edgeMode = Config.Mode == "edge"
    if edgeMode and Config.FirePositionScanning then
        local slot = entry and ScanStates[entry]
        local reach = number(Config.FirePositionOffset, 10, 0, 12)
        local peeked
        if slot and slot.edgePoints and slot.edgeReach == reach and os.clock() - (slot.edgeAt or 0) < 0.12 then
            peeked = slot.edgePoints
        else
            peeked = edgePeekPoints(origin, target, reach)
            if entry then
                slot = slot or { cursor = 1 }
                slot.edgePoints = peeked
                slot.edgeAt = os.clock()
                slot.edgeReach = reach
                ScanStates[entry] = slot
            end
        end
        append(origins, peeked)
    end
    if Config.FirePositionScanning and not edgeMode then
        append(origins, getPositionOffsets(origin, target, Config.FirePositionOffset, "V1"))
    elseif Config.FirePositionScanning and edgeMode then

        append(origins, getPositionOffsets(origin, target, math.min(Config.FirePositionOffset, 6), "V1"))
    end
    if edgeMode and Config.HitPositionScanning then
        append(targets, headEdgePoints(entry, origin, target))
    end
    if Config.HitPositionScanning and not edgeMode then
        append(targets, headScanPoints(entry, target, origin))
    end
    local paths = {}
    for index = 2, #origins do
        paths[#paths + 1] = { origins[index], target }
    end
    for index = 2, #targets do
        paths[#paths + 1] = { origin, targets[index] }
    end
    for first = 2, #origins do
        for second = 2, #targets do
            paths[#paths + 1] = { origins[first], targets[second] }
        end
    end
    if #paths == 0 then
        return
    end
    local saved = entry and ScanStates[entry] or nil
    local key = tostring(Config.Mode)
        .. ":"
        .. tostring(Config.FirePositionScanning)
        .. ":"
        .. tostring(Config.FirePositionOffset)
        .. ":"
        .. tostring(Config.HitPositionScanning)
        .. ":"
        .. tostring(Config.HitPositionOffset)
        .. ":"
        .. tostring(Config.HitPositionScanMode)
    if not saved or saved.key ~= key then
        local carried = saved
        saved = { cursor = 1, key = key }
        if carried then
            saved.edgePoints = carried.edgePoints
            saved.edgeAt = carried.edgeAt
            saved.edgeReach = carried.edgeReach
        end
        if entry then
            ScanStates[entry] = saved
        end
    end
    local cursor = saved.cursor
    for visited = 0, #paths - 1 do
        if not canProbe() then
            break
        end
        local index = 1 + (cursor - 1 + visited) % #paths
        saved.cursor = 1 + index % #paths
        local path = paths[index]
        o, t, v, flightTime = probe(path[1], path[2])
        if o then
            return o, t, v, flightTime
        end
    end
end

local function targetDistance(entry, origin)
    local aim = entry and entryAimPos(entry)
    if not (isFiniteVec3(aim) and isFiniteVec3(origin)) then
        return nil
    end
    return math.floor((aim - origin).Magnitude + 0.5)
end

local function fireDelayForWeapon(data, weapon)
    local rpm = tonumber(data and data.firerate) or 600
    if type(data and data.firerate) == "table" then
        local index = weapon and weapon._firemodeIndex or 1
        rpm = tonumber(data.firerate[index]) or tonumber(data.firerate[1]) or rpm
    end
    if weapon and weapon._aiming and data and data.aimedfirerate then
        rpm = tonumber(data.aimedfirerate) or rpm
    end
    rpm = math.clamp(rpm, 60, 3000)
    return 60 / rpm
end

local PendingHits = {}
local ticket = 0
local nextShot = 0
local lastOrigin
local realOrigin
local originUpdatedAt = -math.huge

local function fallbackOrigin()
    if os.clock() - originUpdatedAt <= 0.25 and isFiniteVec3(lastOrigin) then
        return lastOrigin
    end
    if os.clock() - originUpdatedAt <= 0.25 and isFiniteVec3(realOrigin) then
        return realOrigin
    end
    local charInterface = Modules and Modules.CharacterInterface
    local object = charInterface and charInterface.getCharacterObject and charInterface.getCharacterObject()
    local root = object and object.getRootPart and object:getRootPart()
    if root and isFiniteVec3(root.Position) then
        return root.Position
    end
    local cam = workspace.CurrentCamera
    return cam and cam.CFrame.Position or nil
end

local function gameTime()
    local clock = Modules and Modules.GameClock
    if clock and type(clock.getTime) == "function" then
        local ok, t = pcall(clock.getTime)
        if ok and type(t) == "number" then
            return t
        end
    end
    local network = Modules and Modules.NetworkClient
    if network and type(network.getTime) == "function" then
        local ok, t = pcall(network.getTime)
        if ok and type(t) == "number" then
            return t
        end
    end
    return nil
end

local function nextBulletTicket(weapon)
    ticket += 1
    if weapon and debug and debug.getupvalue and debug.setupvalue and type(weapon.fireRound) == "function" then
        local ok, current = pcall(debug.getupvalue, weapon.fireRound, 11)
        if ok and type(current) == "number" then
            ticket = math.max(ticket, current + 1)
            pcall(debug.setupvalue, weapon.fireRound, 11, ticket)
        end
    end
    return ticket
end

local halfPi = math.pi * 0.5
local function wrapYaw(y)
    local pi = math.pi
    local tau = pi * 2
    y = y % tau
    if y < 0 then
        y += tau
    end
    return y - pi
end

local function applyAAAngles(angles)
    if typeof(angles) ~= "Vector3" or not isFiniteVec3(angles) then
        return angles
    end
    if not Config.AntiAim then
        return angles
    end
    local x = math.rad(number(Config.PitchAmount, 0, -89, 89))
    local y = wrapYaw(math.rad(number(Config.YawAmount, 180, -180, 180)))
    x = math.clamp(x, -halfPi, halfPi)
    return Vector3.new(x, y, 0)
end

local FAKE_LAG_HARD_CAP = 2.8
local fakeLag = {
    lastRefreshTime = 0,
    lastSentPosition = nil,
    heldUntil = 0,
}

local function applyFakeLag(position)
    if not isFiniteVec3(position) then
        return position
    end
    local now = os.clock()
    local amount = number(Config.FakeLagAmount, 1.2, 0, FAKE_LAG_HARD_CAP)
    local hold = number(Config.FakeLagHold, 0.35, 0.05, 3)
    local smooth = number(Config.FakeLagSmooth, 0.45, 0, 1)

    if not fakeLag.lastSentPosition then
        fakeLag.lastSentPosition = position
        fakeLag.lastRefreshTime = now
        fakeLag.heldUntil = now + hold
        return position
    end

    if now < fakeLag.heldUntil then
        local held = fakeLag.lastSentPosition
        local delta = held - position
        if delta.Magnitude > amount then
            held = position + delta.Unit * amount
        end
        fakeLag.lastSentPosition = held
        return held
    end

    local yaw = math.random() * math.pi * 2
    local candidate = position + Vector3.new(math.cos(yaw) * amount, 0, math.sin(yaw) * amount)
    if smooth < 1 then
        candidate = fakeLag.lastSentPosition:Lerp(candidate, smooth)
    end
    local fromReal = candidate - position
    if fromReal.Magnitude > amount then
        candidate = position + fromReal.Unit * amount
    end
    local fromLast = candidate - fakeLag.lastSentPosition
    local jumpCap = math.min(amount, FAKE_LAG_HARD_CAP)
    if fromLast.Magnitude > jumpCap and fromLast.Magnitude > 1e-4 then
        candidate = fakeLag.lastSentPosition + fromLast.Unit * jumpCap
    end
    fakeLag.lastSentPosition = candidate
    fakeLag.lastRefreshTime = now
    fakeLag.heldUntil = now + hold
    return candidate
end

local resolverState = {
    phase = "cooldown",
    cycleStart = 0,
    flashUntil = 0,
    holdUntil = 0,
    entry = nil,
    offset = Vector3.zero,
    worldPoint = nil,
    name = nil,
    bases = setmetatable({}, { __mode = "k" }),
}

local function captureBases(entry)
    local hash = characterHash(entry)
    if not hash then
        return
    end
    local bases = resolverState.bases[entry]
    if not bases then
        bases = {}
        resolverState.bases[entry] = bases
    end
    for name, part in pairs(hash) do
        if typeof(part) == "Instance" and part:IsA("BasePart") then
            bases[name] = part.CFrame
        end
    end
end

local function clearRelocate(entry)
    if not entry then
        return
    end
    local bases = resolverState.bases[entry]
    local hash = characterHash(entry)
    if bases and hash then
        for name, cf in pairs(bases) do
            local part = hash[name]
            if typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent and typeof(cf) == "CFrame" then
                pcall(function()
                    part.CFrame = cf
        end)
    end
        end
    end
    resolverState.bases[entry] = nil
end

local function applyRelocate(entry, worldPoint)
    if not (entry and isFiniteVec3(worldPoint)) then
        return false
    end
    local hash = characterHash(entry)
    local head = hash and hash.Head
    if not (head and head.Parent and isFiniteVec3(head.Position)) then
        return false
    end
    local delta = worldPoint - head.Position
    if delta.Magnitude < 1e-4 then
        return true
    end
    for _, part in pairs(hash) do
        if typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent then
            pcall(function()
                part.CFrame = part.CFrame + delta
            end)
        end
    end
    return true
end

local function findOrbitResolvePoint(origin, entry, accel, speed, penetration)
    local aim = entryAimPos(entry) or entry._receivedPosition
    if not isFiniteVec3(aim) then
        return nil
    end
    local vel = targetVelocity(entry)
    local predicted = aim + vel * 0.12
    local height = number(Config.ResolverHeight, 0.35, -2, 3)
    predicted = predicted + Vector3.new(0, height, 0)
    local strength = number(Config.ResolverStrength, 4, 0.5, 10)
    local bulletCheck = Modules and Modules.BulletCheck
    local movement = vel
    local candidates = {}

    for _, point in ipairs(edgePeekPoints(origin, predicted, math.min(strength, 10))) do
        candidates[#candidates + 1] = point
    end
    candidates[#candidates + 1] = predicted
    for i = 0, 7 do
        local a = (i / 8) * math.pi * 2
        candidates[#candidates + 1] = predicted
            + Vector3.new(math.cos(a) * strength, 0, math.sin(a) * strength)
    end
    for i = 0, 7 do
        local a = (i / 8) * math.pi * 2 + 0.4
        candidates[#candidates + 1] = predicted
            + Vector3.new(math.cos(a) * strength * 0.55, height * 0.5, math.sin(a) * strength * 0.55)
    end
    if type(bulletCheck) == "function" and isFiniteVec3(origin) and accel and speed and penetration then
        for _, point in ipairs(candidates) do
            local _, hit = tryBulletPath(bulletCheck, origin, point, accel, speed, penetration, movement)
            if hit then
                return point
            end
        end
    end
    return candidates[2] or predicted
end

local function resolverCooldownLeft()
    if resolverState.phase == "resolved" then
        return 0
    end
    local cool = number(Config.ResolverCooldown, 1, 0.1, 5)
    local elapsed = os.clock() - (resolverState.cycleStart or 0)
    return math.max(0, cool - elapsed)
end

local function resolverTick(origin, accel, speed, penetration)
    if not Config.Resolver then
        if resolverState.entry then
            clearRelocate(resolverState.entry)
            resolverState.entry = nil
        end
        resolverState.phase = "cooldown"
        return
    end
    local now = os.clock()
    local flash = number(Config.ResolverFlash, 0.35, 0.1, 1.5)
    local hold = number(Config.ResolverHold, 0.45, 0.1, 3)

    if resolverState.cycleStart <= 0 then
        resolverState.cycleStart = now
        resolverState.phase = "cooldown"
    end

    if resolverState.entry then
        if now <= resolverState.holdUntil then
            local received = resolverState.entry._receivedPosition
            if isFiniteVec3(received) and isFiniteVec3(resolverState.offset) then
                resolverState.worldPoint = received + resolverState.offset
            end
            if isFiniteVec3(resolverState.worldPoint) then
                applyRelocate(resolverState.entry, resolverState.worldPoint)
            end
        else
            clearRelocate(resolverState.entry)
            resolverState.entry = nil
            resolverState.worldPoint = nil
        end
    end

    if resolverState.phase == "resolved" then
        if now >= resolverState.flashUntil then
            resolverState.phase = "cooldown"
            resolverState.cycleStart = now
        end
        return
    end

    if resolverCooldownLeft() > 0.001 then
        return
    end

    local closest = isFiniteVec3(origin) and getClosestPlayers(origin) or {}
    local entry = closest and closest[1]
    local point = entry and findOrbitResolvePoint(origin, entry, accel, speed, penetration)
    if entry and isFiniteVec3(point) then
        captureBases(entry)
        local received = entry._receivedPosition
        resolverState.offset = isFiniteVec3(received) and (point - received) or Vector3.zero
        resolverState.worldPoint = point
        applyRelocate(entry, point)
        resolverState.entry = entry
        resolverState.name = entry._player and entry._player.Name or "target"
    else
        resolverState.entry = nil
        resolverState.worldPoint = nil
        resolverState.name = nil
    end
    resolverState.phase = "resolved"
    resolverState.flashUntil = now + flash
    resolverState.holdUntil = now + hold
end

local function startModules()
    local network = Modules.NetworkClient
    local settings = Modules.PublicSettings
    local weapons = Modules.WeaponControllerInterface
    local effects = Modules.Effects
    local audio = Modules.AudioSystem
    local crosshairs = Modules.HudCrosshairsInterface
    local roundSystem = Modules.RoundSystemClientFactory
        and Modules.RoundSystemClientFactory.getClientRoundSystem
        and Modules.RoundSystemClientFactory.getClientRoundSystem()
    local cameraInterface = Modules.CameraInterface

    if network and type(network.send) == "function" then
        local send = network.send
        local wrapper = function(self, name, ...)
            if name == "repupdate" then
                local position, angles = ...
                if isFiniteVec3(position) then
                    originUpdatedAt = os.clock()
                    realOrigin = position
                    lastOrigin = position
                end

                if Config.AntiAim or Config.FakeLag then
                    if Config.FakeLag and isFiniteVec3(position) then
                        position = applyFakeLag(position)
                    else
                        fakeLag.lastSentPosition = nil
                        fakeLag.heldUntil = 0
                    end
                    if Config.AntiAim then
                        angles = applyAAAngles(typeof(angles) == "Vector3" and angles or Vector3.zero)
                    end
                    return send(self, name, position, angles, select(3, ...))
                end
            end
            return send(self, name, ...)
        end
        network.send = wrapper
        table.insert(Restores, function()
            if network.send == wrapper then
                network.send = send
            end
        end)

        table.insert(Connections, RunService.Heartbeat:Connect(function()
            if Unloaded or not Config.Enabled or Config.Prediction == false then
                return
            end
            local ok, reason = pcall(sampleMotion)
            if not ok then
                Runtime.LastError = tostring(reason)
            end
        end))

        table.insert(Connections, RunService.Heartbeat:Connect(function()
            if Unloaded then
                return
            end
            local origin = fallbackOrigin()
            local accel = settings and settings.bulletAcceleration
            local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
            local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
            local data = weapon and weapon._weaponData
            local speed = data and data.bulletspeed
            local penetration = data and data.penetrationdepth
            local ok, reason = pcall(resolverTick, origin, accel, speed, penetration)
            if not ok then
                Runtime.LastError = tostring(reason)
            end
    end))

        local function update()
            if Unloaded or not Config.Enabled then
                    return
                end
            if roundSystem and roundSystem.roundLock then
                return
            end
            local now = os.clock()
            if now < nextShot then
                return
            end

            Config.WhitelistFriendlyStatus = true

            local controller = weapons and weapons.getActiveWeaponController and weapons.getActiveWeaponController()
            local weapon = controller and controller.getActiveWeapon and controller:getActiveWeapon()
            local data = weapon and weapon._weaponData
            local origin
            local barrel = weapon and weapon._barrelPart
            if barrel and barrel.Parent and isFiniteVec3(barrel.Position) then
                origin = barrel.Position
            end
            origin = origin or fallbackOrigin()
            if not (weapon and data and origin and settings and settings.bulletAcceleration) then
                    return
                end
            if not weapon.uniqueId or not data.bulletspeed or not data.penetrationdepth then
                return
            end
            if (weapon._magCount or 0) < 1 and (weapon._spareCount or 0) < 1 then
                        return
                    end

            local camPos = origin
        pcall(function()
                local active = cameraInterface and cameraInterface.getActiveCamera and cameraInterface.getActiveCamera()
                if active and active.getBaseCFrame then
                    local p = active:getBaseCFrame().Position
                    if isFiniteVec3(p) then
                        camPos = p
    end
end
            end)

            local accel = settings.bulletAcceleration
            local speed = data.bulletspeed
            local penetration = data.penetrationdepth
            local closest = getClosestPlayers(origin)
            local fired = false
            frameCheckBudget = number(Config.MaxFrameChecks, 128, 1, 256)
            frameCheckDeadline = os.clock() + number(Config.ScanBudgetMs, 5, 1, 8) / 1000

            for _, entry in closest do
                if not (entry and entry._player and entry._player.Parent) then
                    continue
                end
                local aim = entryAimPos(entry)
                if not isFiniteVec3(aim) or (aim - origin).Magnitude > number(Config.MaxDistance, 1500, 1, 10000) then
                    continue
                end

                local newOrigin, newTarget, velocity, flightTime = scanPositions(origin, aim, accel, speed, penetration, entry)
                if not (newOrigin and newTarget and velocity and velocity.Magnitude > 1e-3) then
                    continue
                end

                if (weapon._magCount or 0) < 1 then
                    local spare = weapon._spareCount or 0
                    if spare < 1 then
                    return
                end
                    local magSize = math.max(1, math.floor(tonumber(data.magsize) or spare))
                    local load = math.min(magSize, spare)
                    weapon._magCount = load
                    weapon._spareCount = spare - load
                    pcall(send, network, "reload")
                end
                local direction = velocity
                local bullets = {}
                local bulletData = {
                    camerapos = camPos,
                    firepos = newOrigin,
                    bullets = bullets,
                }
                local pelletCount = math.clamp(math.floor(tonumber(data.pelletcount) or 1), 1, 128)
                local netTime = gameTime()
                if type(netTime) ~= "number" or type(flightTime) ~= "number" then
                    Runtime.LastError = "Synchronized shot time unavailable"
                    break
                end
                for _ = 1, pelletCount do
                    table.insert(bullets, { direction, nextBulletTicket(weapon) })
                end

                local sent = pcall(send, network, "newbullets", weapon.uniqueId, bulletData, netTime)
                if not sent then
                    break
                end
                fired = true
                Runtime.Shots = Runtime.Shots + 1
                Runtime.ClearName = entry._player.Name
                Runtime.ClearUntil = os.clock() + 0.35
                Runtime.ClearDist = math.floor((aim - origin).Magnitude + 0.5)

                do
                    local tracers = env.Tracers
                    if tracers and type(tracers.FirePath) == "function" then
                        local playerPos = realOrigin
                        if not isFiniteVec3(playerPos) then
                            playerPos = lastOrigin
                        end
                        if not isFiniteVec3(playerPos) then
                            local char = LocalPlayer.Character
                            local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
                            if root and root:IsA("BasePart") then
                                playerPos = root.Position
                            end
                        end
                        if not isFiniteVec3(playerPos) then
                            playerPos = origin
                        end
                        local style = tracers.Config and tracers.Config.Style
                        pcall(tracers.FirePath, { playerPos, newOrigin, newTarget }, style, entry._player, true)
                    elseif tracers and type(tracers.Fire) == "function" then
                        local style = tracers.Config and tracers.Config.Style
                        pcall(tracers.Fire, origin, newOrigin, style, nil, true)
                        pcall(tracers.Fire, newOrigin, newTarget, style, entry._player, true)
                    end
                end

                local shotPlayer, shotWeapon, shotHead = entry._player, weapon.uniqueId, characterHash(entry).Head

        pcall(function()
                    local onMarker = env._TapologyOnHitMarker
                    if type(onMarker) == "function" then
                        onMarker(shotPlayer, newTarget)
                end
            end)
                local pending
                pending = task.delay(flightTime, function()
                    PendingHits[pending] = nil
                    if Unloaded or not shotPlayer.Parent then
                        return
                    end
                    local hash = characterHash(entry)
                    if not hash or hash.Head ~= shotHead or entryHealth(entry) <= 0 then
                        return
                    end
                    local hitTime = gameTime() or netTime + flightTime
                    for _, bullet in ipairs(bullets) do
                        local reported, reason =
                            pcall(send, network, "bullethit", shotWeapon, shotPlayer, newTarget, "Head", bullet[2], hitTime)
                        if not reported then
                            Runtime.LastError = tostring(reason)
                        end
                    end
                end)
                PendingHits[pending] = true

                if Config.ShootEffects and weapon._barrelPart then
                    local barrelPart = weapon._barrelPart
                    if effects and effects.muzzleflash then
                        pcall(effects.muzzleflash, barrelPart, data.hideflash, 0.9)
                    end
                    if audio and audio.playSoundId and data.firesoundid then
                        pcall(audio.playSoundId, data.firesoundid, 2, data.firevolume, data.firepitch, barrelPart, nil, 0, 0.05)
                    end
                    if crosshairs and crosshairs.fireImpulse and data.crossexpansion and not weapon._aiming then
                        pcall(crosshairs.fireImpulse, data.crossexpansion)
                    end
                end

                nextShot = now + fireDelayForWeapon(data, weapon)
                weapon._magCount = math.max((weapon._magCount or 1) - 1, 0)
                if (weapon._magCount or 0) < 1 and (weapon._spareCount or 0) >= 1 then
                    local spare = weapon._spareCount or 0
                    local magSize = math.max(1, math.floor(tonumber(data.magsize) or spare))
                    local load = math.min(magSize, spare)
                    weapon._magCount = load
                    weapon._spareCount = spare - load
                    pcall(send, network, "reload")
                end
                break
            end

            if not fired then
                Runtime.ScanMisses = Runtime.ScanMisses + 1
                nextShot = now + number(Config.ScanMissCooldown, 0.12, 0.01, 1)
            end
        end
        table.insert(Connections, RunService.Heartbeat:Connect(function()
            local ok, reason = pcall(update)
            if not ok then
                Runtime.LastError = tostring(reason)
                Runtime.Status = "Update error"
                nextShot = os.clock() + 0.25
            end
    end))
    end
end

local indicatorGui
local indicatorRageRow
local indicatorResolverRow
local INDICATOR_TEXT_SIZE = 12

local function accentColor()
    local ui = env.Tapology or env.Library
    local theme = ui and ui.Config and ui.Config.Theme
    if theme and typeof(theme.Accent) == "Color3" then
        return theme.Accent
    end
    return Color3.fromRGB(108, 147, 255)
end

local function indicatorFont()
    local ui = env.Tapology or env.Library
    if ui and ui.Font then
        return ui.Font
    end
    local esp = env.ESP
    if esp and esp.Font then
        return esp.Font
    end
    return Font.fromEnum(Enum.Font.Code)
end

local function ensureIndicators()
    if indicatorGui and indicatorGui.Parent then
                    return
                end
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 2)
    if not playerGui then
        return
    end
    indicatorGui = Instance.new("ScreenGui")
    indicatorGui.Name = "TapologyRageIndicators"
    indicatorGui.IgnoreGuiInset = true
    indicatorGui.ResetOnSpawn = false
    indicatorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    indicatorGui.Parent = playerGui

    local font = indicatorFont()
    local function makeRow(name)
        local row = Instance.new("Frame")
        row.Name = name
        row.BackgroundTransparency = 1
        row.AnchorPoint = Vector2.new(0.5, 0)
        row.AutomaticSize = Enum.AutomaticSize.X
        row.Size = UDim2.fromOffset(0, INDICATOR_TEXT_SIZE)
        row.Visible = false
        row.Parent = indicatorGui
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 0)
        layout.Parent = row
        local function makeText(labelName, order)
            local label = Instance.new("TextLabel")
            label.Name = labelName
            label.BackgroundTransparency = 1
            label.AutomaticSize = Enum.AutomaticSize.X
            label.Size = UDim2.fromOffset(0, INDICATOR_TEXT_SIZE)
            label.FontFace = font
            label.TextSize = INDICATOR_TEXT_SIZE
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextYAlignment = Enum.TextYAlignment.Center
            label.LayoutOrder = order
            label.ZIndex = 5
            label.Parent = row
            local stroke = Instance.new("UIStroke")
            stroke.Name = "Outline"
            stroke.Thickness = 1
            stroke.Color = Color3.new(0, 0, 0)
            stroke.LineJoinMode = Enum.LineJoinMode.Miter
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
            stroke.Parent = label
            return label
        end
        return { Row = row, Prefix = makeText("Prefix", 1), Info = makeText("Info", 2) }
    end
    indicatorRageRow = makeRow("Ragebot")
    indicatorResolverRow = makeRow("Resolver")
end

local function destroyIndicators()
    if indicatorGui then
        pcall(function()
            indicatorGui:Destroy()
        end)
    end
    indicatorGui, indicatorRageRow, indicatorResolverRow = nil, nil, nil
end

local function paintRow(row, y, prefix, info, infoColor)
    if not row then
        return
    end
    local font = indicatorFont()
    row.Row.Visible = true
    row.Row.Size = UDim2.fromOffset(0, INDICATOR_TEXT_SIZE)
    row.Row.Position = UDim2.new(0.5, 0, 0.5, y)
    for _, label in { row.Prefix, row.Info } do
        label.FontFace = font
        label.TextSize = INDICATOR_TEXT_SIZE
        label.Size = UDim2.fromOffset(0, INDICATOR_TEXT_SIZE)
        local stroke = label:FindFirstChild("Outline")
        if stroke and stroke:IsA("UIStroke") then
            stroke.Thickness = 1
            stroke.Color = Color3.new(0, 0, 0)
            stroke.Transparency = 0
            stroke.LineJoinMode = Enum.LineJoinMode.Miter
        end
    end
    row.Prefix.Text = prefix
    row.Prefix.TextColor3 = accentColor()
    row.Info.Text = info
    row.Info.TextColor3 = infoColor or Color3.new(1, 1, 1)
end

local function animatedDots()
    local phase = math.floor(os.clock() * 3) % 4
    if phase <= 0 then
        return ""
    end
    return string.rep(".", phase)
end

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if not Config.Indicators then
        if indicatorGui then
            destroyIndicators()
        end
        return
    end
    ensureIndicators()
    if not indicatorRageRow or not indicatorResolverRow then
        return
    end
    local line = INDICATOR_TEXT_SIZE + 4
    local y = 20
    local dots = animatedDots()
    if Config.IndicatorRagebot then
        local info, color = " off" .. dots, Config.IndicatorRageIdle
        if Config.Enabled then
            local origin = fallbackOrigin()
            local closest = isFiniteVec3(origin) and getClosestPlayers(origin) or {}
            local entry = closest[1]
            if entry and entry._player then
                local dist = targetDistance(entry, origin)
                local mode = Config.Mode == "edge" and "edge" or "default"
                local fresh = Runtime.ClearName == entry._player.Name and os.clock() < (Runtime.ClearUntil or 0)
                if fresh then
                    info = string.format(" %s clear %sm%s", entry._player.Name, tostring(Runtime.ClearDist or dist or 0), dots)
                elseif dist then
                    info = string.format(" %s %s %sm%s", entry._player.Name, mode, tostring(dist), dots)
                else
                    info = string.format(" %s %s%s", entry._player.Name, mode, dots)
                end
                color = Config.IndicatorRageActive
            else
                info = " scanning" .. dots
            end
        end
        paintRow(indicatorRageRow, y, "ragebot :", info, color)
        y += line
    else
        indicatorRageRow.Row.Visible = false
    end
    if Config.IndicatorResolver then
        local info, color
        if not Config.Resolver then
            info = " off"
            color = Config.IndicatorResolverCooldown
        elseif resolverState.phase == "resolved" then
            info = " resolved!"
            color = Config.IndicatorResolverReady
        else
            info = string.format(" %.1f", resolverCooldownLeft())
            color = Config.IndicatorResolverCooldown
        end
        paintRow(indicatorResolverRow, y, "resolver :", info, color)
    else
        indicatorResolverRow.Row.Visible = false
    end
end))

Controller = {
    Config = Config,
    Available = false,
    Runtime = Runtime,
    SetEnabled = function(on)
        Config.Enabled = on and true or false
    end,
    GetAntiAimAngles = function(angles)
        return applyAAAngles(angles)
    end,
    GetResolverState = function()
        if not Config.Resolver then
            return "off"
        end
        if resolverState.phase == "resolved" then
            return "resolved"
        end
        if resolverCooldownLeft() > 0.01 then
            return "cooldown"
        end
        return "ready"
    end,
    GetResolverCooldown = resolverCooldownLeft,
    SetTarget = function(player, on)
        Config.Targets[player] = on and true or nil
    end,
    SetFriendly = function(player, on)
        Config.Friendlies[player] = on and true or nil
    end,
    Unload = function()
        if Unloaded then
            return
        end
    Unloaded = true
        Controller.Available = false
        Runtime.Status = "Unloaded"
        Config.Enabled = false
        if resolverState.entry then
            clearRelocate(resolverState.entry)
        end
        for pending in pairs(PendingHits) do
            pcall(task.cancel, pending)
        end
        table.clear(PendingHits)
        for _, connection in Connections do
            pcall(function()
                connection:Disconnect()
            end)
    end
    table.clear(Connections)
        for _, restore in Restores do
            pcall(restore)
    end
    table.clear(Restores)
        destroyIndicators()
        if env.Rage == Controller then
    env.Rage = nil
        end
        if env.RageBot == Controller then
            env.RageBot = nil
        end
    end,
}

env.RageBot, env.Rage = Controller, Controller

if not PhantomForces then
    Runtime.Status = "Unsupported place"
    Config.Enabled = false
else
    task.spawn(function()
        Runtime.Status = "Finding modules"
        local deadline = os.clock() + number(Config.ModuleTimeout, 15, 1, 120)
        repeat
            if Unloaded then
                return
            end
            local ok, found = pcall(findModules)
            if ok and found then
                Modules = found
                env._TapologyModules = env._TapologyModules or found
                local connectionCount, restoreCount = #Connections, #Restores
                local started, reason = pcall(startModules)
                if Unloaded then
                    for index = #Connections, connectionCount + 1, -1 do
                        pcall(function()
                            Connections[index]:Disconnect()
                        end)
                        Connections[index] = nil
                    end
                    for index = #Restores, restoreCount + 1, -1 do
                        pcall(Restores[index])
                        Restores[index] = nil
                    end
                    return
                end
                if started then
                    Controller.Available = true
                    Runtime.Status = "Ready"
                    Runtime.LastError = nil
                    return
                end
                Runtime.LastError = tostring(reason)
                for index = #Connections, connectionCount + 1, -1 do
                    pcall(function()
                        Connections[index]:Disconnect()
                    end)
                    Connections[index] = nil
                end
                for index = #Restores, restoreCount + 1, -1 do
                    pcall(Restores[index])
                    Restores[index] = nil
                end
            elseif not ok then
                Runtime.LastError = tostring(found)
            end
            task.wait(1)
        until Unloaded or os.clock() >= deadline
        if not Unloaded then
            Runtime.Status = "Modules unavailable"
        end
    end)
end
]] },
}

for _, mod in ipairs(Modules) do
    local fn, err = loadstring(mod.source, "@" .. mod.name)
    if not fn then
        error("[Tapology] " .. mod.name .. " compile failed: " .. tostring(err))
    end
    local ok, result = pcall(fn)
    if not ok then
        error("[Tapology] " .. mod.name .. " failed: " .. tostring(result))
    end
    print("[Tapology] Loaded module:", mod.name)
end

