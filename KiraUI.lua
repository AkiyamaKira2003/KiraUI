--[[
    Kira UI
    Responsive Roblox UI library for tablet / desktop-style script hubs.

    Features:
      - Window dragging
      - Windows-like resizing from 4 edges + 4 corners
      - Responsive sidebar and 1/2-column masonry sections
      - Portal-based dropdowns (no clipping / ZIndex overlap bugs)
      - Slider, Toggle, Dropdown, Button, Label
      - Decoupled :OnChanged() state API
      - Rounded border / shadow
      - Status + Phase pill
      - RightShift (configurable) show/hide
      - Floating restore launcher when hidden
      - Mouse + touch support

    Example:
      local KiraUI = loadstring(game:HttpGet("RAW_GITHUB_URL"))()
      local Window = KiraUI:CreateWindow({...})
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local KiraUI = {}
KiraUI.__index = KiraUI
KiraUI.Version = "0.1.1"

KiraUI.Theme = {
    Background = Color3.fromRGB(15, 16, 22),
    Surface = Color3.fromRGB(22, 23, 31),
    Surface2 = Color3.fromRGB(29, 30, 40),
    Surface3 = Color3.fromRGB(36, 37, 49),
    Border = Color3.fromRGB(69, 72, 92),
    Accent = Color3.fromRGB(105, 113, 255),
    AccentSoft = Color3.fromRGB(70, 76, 170),
    Text = Color3.fromRGB(238, 239, 247),
    MutedText = Color3.fromRGB(149, 152, 170),
    Success = Color3.fromRGB(91, 218, 145),
    Warning = Color3.fromRGB(245, 188, 87),
    Danger = Color3.fromRGB(226, 83, 99),
    Shadow = Color3.fromRGB(0, 0, 0),
}

local function merge(base, override)
    local out = {}
    for key, value in pairs(base) do
        out[key] = value
    end
    for key, value in pairs(override or {}) do
        out[key] = value
    end
    return out
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then
        return
    end
    local ok, err = xpcall(fn, debug.traceback, ...)
    if not ok then
        warn("[Kira UI callback]", err)
    end
end

local function new(className, props, parent)
    local instance = Instance.new(className)
    for key, value in pairs(props or {}) do
        instance[key] = value
    end
    instance.Parent = parent
    return instance
end

local function corner(parent, radius)
    return new("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
    }, parent)
end

local function stroke(parent, color, transparency, thickness)
    return new("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
    }, parent)
end

local function padding(parent, left, right, top, bottom)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or left or 0),
    }, parent)
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function decimalsFromStep(step)
    local text = tostring(step or 1)
    local decimals = text:match("%.(%d+)")
    return decimals and #decimals or 0
end

local function roundToStep(value, minValue, step)
    step = step or 1
    if step <= 0 then
        return value
    end
    local snapped = minValue + math.floor(((value - minValue) / step) + 0.5) * step
    local decimals = decimalsFromStep(step)
    local power = 10 ^ decimals
    return math.floor(snapped * power + 0.5) / power
end

local function formatNumber(value, step)
    local decimals = decimalsFromStep(step or 1)
    return string.format("%." .. tostring(decimals) .. "f", value)
end

local function makeValueObject(defaultValue, callback)
    local object = {
        Value = defaultValue,
        _listeners = {},
        _callback = callback,
    }

    function object:OnChanged(fn)
        if type(fn) == "function" then
            table.insert(self._listeners, fn)
        end
        return self
    end

    function object:_emit(value)
        safeCall(self._callback, value)
        for _, fn in ipairs(self._listeners) do
            safeCall(fn, value)
        end
    end

    return object
end

local function resolveParent()
    local target = PlayerGui
    if type(gethui) == "function" then
        pcall(function()
            target = gethui()
        end)
    end
    return target
end

local function getViewport()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return Vector2.new(1280, 720)
end

function KiraUI:CreateWindow(config)
    config = config or {}

    local theme = merge(self.Theme, config.Theme)
    local startSize = config.Size or Vector2.new(900, 540)
    local minSize = config.MinSize or Vector2.new(560, 380)
    local maxSize = config.MaxSize or Vector2.new(1280, 850)
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    local titleText = tostring(config.Title or "Kira UI")
    local subtitleText = tostring(config.Subtitle or "Responsive Roblox interface")
    local closeBehavior = string.lower(tostring(config.CloseBehavior or "hide"))
    local launcherEnabled = config.ShowLauncher ~= false
    local launcherText = tostring(config.LauncherText or "Open UI")
    local launcherPosition = config.LauncherPosition or UDim2.new(0, 18, 0.5, 0)
    local launcherAnchorPoint = config.LauncherAnchorPoint or Vector2.new(0, 0.5)
    local launcherSize = config.LauncherSize or UDim2.fromOffset(154, 44)

    local uiParent = resolveParent()

    if config.SingletonName then
        local previous = uiParent:FindFirstChild(config.SingletonName)
        if previous then
            previous:Destroy()
        end
    end

    local gui = new("ScreenGui", {
        Name = config.SingletonName or ("KiraUI_" .. tostring(math.random(100000, 999999))),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = config.DisplayOrder or 9999,
    }, uiParent)

    local window = {
        Gui = gui,
        Theme = theme,
        Tabs = {},
        _connections = {},
        _activeTab = nil,
        _openDropdown = nil,
        _hidden = false,
        _minimized = false,
        _destroyed = false,
        _minSize = minSize,
        _maxSize = maxSize,
        _toggleKey = toggleKey,
        _closeBehavior = closeBehavior,
        _launcherEnabled = launcherEnabled,
        _savedSize = startSize,
    }

    function window:_connect(signal, fn)
        local connection = signal:Connect(fn)
        table.insert(self._connections, connection)
        return connection
    end

    function window:_closeDropdown()
        if self._openDropdown and self._openDropdown.Close then
            self._openDropdown:Close()
        end
        self._openDropdown = nil
    end

    -- Full-screen portal used by dropdowns/toasts so section clipping can never cover them.
    local portal = new("Frame", {
        Name = "Portal",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        ZIndex = 900,
        Active = false,
    }, gui)
    window.Portal = portal

    local dismissLayer = new("TextButton", {
        Name = "DropdownDismiss",
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 901,
    }, portal)
    window.DropdownDismiss = dismissLayer

    window:_connect(dismissLayer.MouseButton1Click, function()
        window:_closeDropdown()
    end)

    local launcherButton = new("TextButton", {
        Name = "RestoreLauncher",
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        AnchorPoint = launcherAnchorPoint,
        Position = launcherPosition,
        Size = launcherSize,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = launcherText,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = false,
        Active = true,
        ZIndex = 950,
    }, gui)
    corner(launcherButton, 12)
    stroke(launcherButton, theme.Text, 0.72, 1)
    padding(launcherButton, 14, 14, 0, 0)
    window.LauncherButton = launcherButton

    local viewport = getViewport()
    local initialWidth = math.min(startSize.X, math.max(320, viewport.X - 24))
    local initialHeight = math.min(startSize.Y, math.max(260, viewport.Y - 24))
    local initialX = math.max(8, math.floor((viewport.X - initialWidth) / 2))
    local initialY = math.max(8, math.floor((viewport.Y - initialHeight) / 2))

    local host = new("Frame", {
        Name = "WindowHost",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(initialX, initialY),
        Size = UDim2.fromOffset(initialWidth, initialHeight),
        ZIndex = 10,
    }, gui)
    window.Host = host

    local sizeConstraint = new("UISizeConstraint", {}, host)
    window.SizeConstraint = sizeConstraint

    local function updateSizeConstraint()
        local vp = getViewport()
        sizeConstraint.MinSize = Vector2.new(
            math.min(minSize.X, math.max(240, vp.X - 16)),
            math.min(minSize.Y, math.max(180, vp.Y - 16))
        )
        sizeConstraint.MaxSize = Vector2.new(
            math.min(maxSize.X, math.max(sizeConstraint.MinSize.X, vp.X - 16)),
            math.min(maxSize.Y, math.max(sizeConstraint.MinSize.Y, vp.Y - 16))
        )
    end

    updateSizeConstraint()

    local shadow = new("Frame", {
        Name = "Shadow",
        BackgroundColor3 = theme.Shadow,
        BackgroundTransparency = 0.58,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(5, 7),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 10,
    }, host)
    corner(shadow, 18)

    local main = new("Frame", {
        Name = "Main",
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 11,
    }, host)
    corner(main, 18)
    stroke(main, theme.Border, 0.12, 1)
    window.Main = main

    -- Header
    local header = new("Frame", {
        Name = "Header",
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 60),
        ZIndex = 12,
        Active = true,
    }, main)

    local title = new("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(20, 8),
        Size = UDim2.new(1, -300, 0, 25),
        Font = Enum.Font.GothamBold,
        Text = titleText,
        TextSize = 19,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 13,
    }, header)

    local subtitle = new("TextLabel", {
        Name = "Subtitle",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(20, 33),
        Size = UDim2.new(1, -300, 0, 17),
        Font = Enum.Font.Gotham,
        Text = subtitleText,
        TextSize = 11,
        TextColor3 = theme.MutedText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 13,
    }, header)

    local phasePill = new("TextLabel", {
        Name = "Phase",
        BackgroundColor3 = theme.Surface3,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -94, 0, 16),
        Size = UDim2.fromOffset(128, 29),
        Font = Enum.Font.GothamBold,
        Text = tostring(config.Phase or "IDLE"),
        TextSize = 10,
        TextColor3 = theme.Success,
        ZIndex = 14,
    }, header)
    corner(phasePill, 9)

    local minimizeButton = new("TextButton", {
        Name = "Minimize",
        BackgroundColor3 = theme.Surface3,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -50, 0, 15),
        Size = UDim2.fromOffset(34, 31),
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "—",
        TextSize = 16,
        TextColor3 = theme.Text,
        ZIndex = 14,
    }, header)
    corner(minimizeButton, 9)

    local closeButton = new("TextButton", {
        Name = "Close",
        BackgroundColor3 = theme.Surface3,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 15),
        Size = UDim2.fromOffset(30, 31),
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextSize = 16,
        TextColor3 = theme.MutedText,
        ZIndex = 14,
    }, header)
    corner(closeButton, 9)

    -- Body
    local body = new("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 60),
        Size = UDim2.new(1, 0, 1, -98),
        ZIndex = 12,
    }, main)
    window.Body = body

    local sidebar = new("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, 180, 1, 0),
        ZIndex = 12,
    }, body)
    window.Sidebar = sidebar

    local nav = new("Frame", {
        Name = "Navigation",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 12),
        Size = UDim2.new(1, -20, 1, -24),
        ZIndex = 13,
    }, sidebar)

    local navLayout = new("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, nav)

    local content = new("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(180, 0),
        Size = UDim2.new(1, -180, 1, 0),
        ZIndex = 12,
    }, body)
    window.Content = content

    -- Status
    local statusBar = new("Frame", {
        Name = "StatusBar",
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 38),
        ZIndex = 12,
    }, main)
    window.StatusBar = statusBar

    local statusDot = new("Frame", {
        Name = "Dot",
        BackgroundColor3 = theme.Success,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(16, 15),
        Size = UDim2.fromOffset(8, 8),
        ZIndex = 13,
    }, statusBar)
    corner(statusDot, 20)

    local statusText = new("TextLabel", {
        Name = "Status",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(33, 0),
        Size = UDim2.new(1, -46, 1, 0),
        Font = Enum.Font.Gotham,
        Text = tostring(config.Status or "Kira UI ready"),
        TextSize = 11,
        TextColor3 = theme.MutedText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 13,
    }, statusBar)
    window.StatusText = statusText
    window.PhaseText = phasePill
    window.TitleText = title
    window.SubtitleText = subtitle
    window.StatusDot = statusDot

    function window:SetStatus(text, tone)
        statusText.Text = tostring(text or "")
        if tone == "danger" then
            statusDot.BackgroundColor3 = theme.Danger
        elseif tone == "warning" then
            statusDot.BackgroundColor3 = theme.Warning
        elseif tone == "muted" then
            statusDot.BackgroundColor3 = theme.MutedText
        else
            statusDot.BackgroundColor3 = theme.Success
        end
    end

    function window:SetPhase(text, tone)
        phasePill.Text = tostring(text or "")
        if tone == "danger" then
            phasePill.TextColor3 = theme.Danger
        elseif tone == "warning" then
            phasePill.TextColor3 = theme.Warning
        elseif tone == "muted" then
            phasePill.TextColor3 = theme.MutedText
        else
            phasePill.TextColor3 = theme.Success
        end
    end

    function window:SetTitle(text)
        title.Text = tostring(text or "")
    end

    -- Responsive system
    function window:_applyResponsive()
        if self._destroyed then
            return
        end

        local width = host.AbsoluteSize.X
        local compact = width < (config.SidebarBreakpoint or 720)
        local sidebarWidth = compact and 64 or 180

        sidebar.Size = UDim2.new(0, sidebarWidth, 1, 0)
        content.Position = UDim2.fromOffset(sidebarWidth, 0)
        content.Size = UDim2.new(1, -sidebarWidth, 1, 0)

        subtitle.Visible = width >= 680
        phasePill.Visible = width >= 610

        for _, tab in ipairs(self.Tabs) do
            if tab.NavLabel then
                tab.NavLabel.Visible = not compact
            end
            if tab.NavIcon then
                tab.NavIcon.Size = compact and UDim2.fromScale(1, 1) or UDim2.fromOffset(34, 40)
                tab.NavIcon.Position = UDim2.fromOffset(0, 0)
                tab.NavIcon.TextXAlignment = compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Center
            end
            if tab._relayout then
                task.defer(tab._relayout)
            end
        end
    end

    -- Tabs
    function window:AddTab(name, icon)
        name = tostring(name or "Tab")
        icon = tostring(icon or "•")

        local tab = {
            Name = name,
            Sections = {},
            Window = self,
        }

        local button = new("TextButton", {
            Name = "Tab_" .. name,
            BackgroundColor3 = theme.Surface2,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 42),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 14,
        }, nav)
        corner(button, 10)

        local iconLabel = new("TextLabel", {
            Name = "Icon",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(34, 42),
            Font = Enum.Font.GothamBold,
            Text = icon,
            TextSize = 14,
            TextColor3 = theme.MutedText,
            ZIndex = 15,
        }, button)

        local nameLabel = new("TextLabel", {
            Name = "Name",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(38, 0),
            Size = UDim2.new(1, -46, 1, 0),
            Font = Enum.Font.GothamMedium,
            Text = name,
            TextSize = 12,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 15,
        }, button)

        local page = new("ScrollingFrame", {
            Name = "Page_" .. name,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.Border,
            ScrollBarImageTransparency = 0.15,
            Visible = false,
            ZIndex = 13,
        }, content)

        tab.NavButton = button
        tab.NavIcon = iconLabel
        tab.NavLabel = nameLabel
        tab.Page = page

        local function relayout()
            if window._destroyed or not page.Parent then
                return
            end

            local pageWidth = page.AbsoluteSize.X
            if pageWidth <= 0 then
                return
            end

            local outerPadding = 16
            local gap = 12
            local usable = math.max(100, pageWidth - (outerPadding * 2))
            local twoColumns = usable >= (config.SectionBreakpoint or 660)
            local columnWidth = twoColumns and ((usable - gap) / 2) or usable
            local y1 = outerPadding
            local y2 = outerPadding

            for _, section in ipairs(tab.Sections) do
                local sectionHeight = section.Frame.Size.Y.Offset
                local full = (section.Span == "full" or section.Span == 2)

                if not twoColumns or full then
                    local y = twoColumns and math.max(y1, y2) or y1
                    section.Frame.Position = UDim2.fromOffset(outerPadding, y)
                    section.Frame.Size = UDim2.fromOffset(usable, sectionHeight)
                    local nextY = y + sectionHeight + gap
                    y1 = nextY
                    y2 = nextY
                else
                    if y1 <= y2 then
                        section.Frame.Position = UDim2.fromOffset(outerPadding, y1)
                        section.Frame.Size = UDim2.fromOffset(columnWidth, sectionHeight)
                        y1 = y1 + sectionHeight + gap
                    else
                        section.Frame.Position = UDim2.fromOffset(outerPadding + columnWidth + gap, y2)
                        section.Frame.Size = UDim2.fromOffset(columnWidth, sectionHeight)
                        y2 = y2 + sectionHeight + gap
                    end
                end
            end

            local bottom = math.max(y1, y2)
            page.CanvasSize = UDim2.fromOffset(0, math.max(0, bottom + outerPadding - gap))
        end

        tab._relayout = relayout

        window:_connect(page:GetPropertyChangedSignal("AbsoluteSize"), function()
            task.defer(relayout)
        end)

        function tab:AddSection(sectionName, options)
            options = options or {}
            local section = {
                Name = tostring(sectionName or "Section"),
                Span = options.Span or 1,
                Tab = self,
            }

            local frame = new("Frame", {
                Name = "Section_" .. section.Name,
                BackgroundColor3 = theme.Surface2,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(300, 72),
                ZIndex = 14,
            }, page)
            corner(frame, 13)
            stroke(frame, theme.Border, 0.42, 1)

            local headerLabel = new("TextLabel", {
                Name = "Header",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(14, 10),
                Size = UDim2.new(1, -28, 0, 23),
                Font = Enum.Font.GothamBold,
                Text = section.Name,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 15,
            }, frame)

            local controls = new("Frame", {
                Name = "Controls",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(14, 43),
                Size = UDim2.new(1, -28, 0, 0),
                ZIndex = 15,
            }, frame)

            local controlsLayout = new("UIListLayout", {
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, controls)

            section.Frame = frame
            section.Controls = controls
            section.Layout = controlsLayout
            section.Header = headerLabel

            local function updateSectionHeight()
                if not frame.Parent then
                    return
                end
                local contentHeight = controlsLayout.AbsoluteContentSize.Y
                controls.Size = UDim2.new(1, -28, 0, contentHeight)
                frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, math.max(68, 43 + contentHeight + 14))
                task.defer(relayout)
            end

            window:_connect(controlsLayout:GetPropertyChangedSignal("AbsoluteContentSize"), updateSectionHeight)

            local function controlFrame(height)
                return new("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, height),
                    ZIndex = 16,
                }, controls)
            end

            function section:AddToggle(options)
                options = options or {}
                local object = makeValueObject(options.Default == true, options.Callback)
                local row = controlFrame(42)

                local label = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -64, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = tostring(options.Text or options.Name or "Toggle"),
                    TextSize = 12,
                    TextColor3 = theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 17,
                }, row)

                local switch = new("TextButton", {
                    BackgroundColor3 = theme.Border,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(48, 26),
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 17,
                }, row)
                corner(switch, 20)

                local knob = new("Frame", {
                    BackgroundColor3 = theme.Text,
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(4, 4),
                    Size = UDim2.fromOffset(18, 18),
                    ZIndex = 18,
                }, switch)
                corner(knob, 20)

                local function render(animated)
                    local active = object.Value
                    local targetColor = active and theme.Accent or theme.Border
                    local targetPos = active and UDim2.new(1, -22, 0, 4) or UDim2.fromOffset(4, 4)
                    if animated then
                        TweenService:Create(switch, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {
                            BackgroundColor3 = targetColor,
                        }):Play()
                        TweenService:Create(knob, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {
                            Position = targetPos,
                        }):Play()
                    else
                        switch.BackgroundColor3 = targetColor
                        knob.Position = targetPos
                    end
                end

                function object:SetValue(value, silent)
                    value = value == true
                    if self.Value == value then
                        return self
                    end
                    self.Value = value
                    render(true)
                    if not silent then
                        self:_emit(value)
                    end
                    return self
                end

                window:_connect(switch.MouseButton1Click, function()
                    object:SetValue(not object.Value)
                end)

                render(false)
                object.Instance = row
                object.Switch = switch
                object.Label = label
                return object
            end

            function section:AddSlider(options)
                options = options or {}
                local minValue = tonumber(options.Min) or 0
                local maxValue = tonumber(options.Max) or 100
                local step = tonumber(options.Step) or 1
                if maxValue < minValue then
                    minValue, maxValue = maxValue, minValue
                end

                local default = clamp(tonumber(options.Default) or minValue, minValue, maxValue)
                default = roundToStep(default, minValue, step)

                local object = makeValueObject(default, options.Callback)
                local row = controlFrame(68)

                local label = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.new(1, -100, 0, 24),
                    Font = Enum.Font.GothamMedium,
                    Text = tostring(options.Text or options.Name or "Slider"),
                    TextSize = 11,
                    TextColor3 = theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 17,
                }, row)

                local valueLabel = new("TextLabel", {
                    BackgroundColor3 = theme.Surface3,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.fromOffset(86, 24),
                    Font = Enum.Font.GothamMedium,
                    TextSize = 10,
                    TextColor3 = theme.Text,
                    ZIndex = 17,
                }, row)
                corner(valueLabel, 7)

                local trackHitbox = new("TextButton", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(0, 31),
                    Size = UDim2.new(1, 0, 0, 34),
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 17,
                }, row)

                local track = new("Frame", {
                    BackgroundColor3 = theme.Border,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.new(1, 0, 0, 6),
                    ZIndex = 18,
                }, trackHitbox)
                corner(track, 10)

                local fill = new("Frame", {
                    BackgroundColor3 = theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.fromScale(0, 1),
                    ZIndex = 19,
                }, track)
                corner(fill, 10)

                local knob = new("Frame", {
                    BackgroundColor3 = theme.Text,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0, 0.5),
                    Size = UDim2.fromOffset(16, 16),
                    ZIndex = 20,
                }, track)
                corner(knob, 20)
                stroke(knob, theme.Accent, 0.05, 2)

                local suffix = tostring(options.Suffix or "")
                local draggingSlider = false

                local function ratioForValue(value)
                    if maxValue == minValue then
                        return 0
                    end
                    return clamp((value - minValue) / (maxValue - minValue), 0, 1)
                end

                local function render()
                    local ratio = ratioForValue(object.Value)
                    fill.Size = UDim2.new(ratio, 0, 1, 0)
                    knob.Position = UDim2.new(ratio, 0, 0.5, 0)
                    valueLabel.Text = formatNumber(object.Value, step) .. suffix
                end

                function object:SetValue(value, silent)
                    value = clamp(tonumber(value) or minValue, minValue, maxValue)
                    value = roundToStep(value, minValue, step)
                    if self.Value == value then
                        return self
                    end
                    self.Value = value
                    render()
                    if not silent then
                        self:_emit(value)
                    end
                    return self
                end

                local function setFromX(x)
                    local absoluteX = track.AbsolutePosition.X
                    local width = math.max(1, track.AbsoluteSize.X)
                    local ratio = clamp((x - absoluteX) / width, 0, 1)
                    object:SetValue(minValue + (maxValue - minValue) * ratio)
                end

                window:_connect(trackHitbox.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        draggingSlider = true
                        setFromX(input.Position.X)
                    end
                end)

                window:_connect(UserInputService.InputChanged, function(input)
                    if not draggingSlider then
                        return
                    end
                    if input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch then
                        setFromX(input.Position.X)
                    end
                end)

                window:_connect(UserInputService.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        draggingSlider = false
                    end
                end)

                render()
                object.Instance = row
                object.Label = label
                return object
            end

            function section:AddDropdown(options)
                options = options or {}
                local default = tostring(options.Default or "")
                local object = makeValueObject(default, options.Callback)
                local row = controlFrame(62)

                local label = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.new(1, 0, 0, 18),
                    Font = Enum.Font.Gotham,
                    Text = string.upper(tostring(options.Text or options.Name or "Dropdown")),
                    TextSize = 10,
                    TextColor3 = theme.MutedText,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 17,
                }, row)

                local trigger = new("TextButton", {
                    BackgroundColor3 = theme.Surface3,
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(0, 22),
                    Size = UDim2.new(1, 0, 0, 36),
                    Font = Enum.Font.GothamMedium,
                    Text = "",
                    TextSize = 11,
                    TextColor3 = theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                    ZIndex = 17,
                }, row)
                corner(trigger, 8)
                padding(trigger, 11, 11, 0, 0)

                local arrow = new("TextLabel", {
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -9, 0, 22),
                    Size = UDim2.fromOffset(20, 36),
                    Font = Enum.Font.GothamBold,
                    Text = "⌄",
                    TextSize = 13,
                    TextColor3 = theme.MutedText,
                    ZIndex = 18,
                }, row)

                local dropdownApi = {}
                local popup
                local currentOptions = {}

                local function getOptions()
                    local values
                    if type(options.Values) == "function" then
                        local ok, result = pcall(options.Values)
                        values = ok and result or {}
                    elseif type(options.Provider) == "function" then
                        local ok, result = pcall(options.Provider)
                        values = ok and result or {}
                    else
                        values = options.Values or options.Options or {}
                    end
                    local out = {}
                    for _, value in ipairs(values or {}) do
                        table.insert(out, tostring(value))
                    end
                    currentOptions = out
                    return out
                end

                local function renderTrigger()
                    trigger.Text = object.Value ~= "" and object.Value or tostring(options.Placeholder or "Select...")
                end

                local function close()
                    if popup then
                        popup:Destroy()
                        popup = nil
                    end
                    dismissLayer.Visible = false
                    arrow.Text = "⌄"
                    if window._openDropdown == dropdownApi then
                        window._openDropdown = nil
                    end
                end

                function dropdownApi:Close()
                    close()
                end

                function object:SetValue(value, silent)
                    value = tostring(value or "")
                    if self.Value == value then
                        renderTrigger()
                        return self
                    end
                    self.Value = value
                    renderTrigger()
                    if not silent then
                        self:_emit(value)
                    end
                    return self
                end

                function object:SetValues(values)
                    options.Values = values or {}
                    options.Provider = nil
                    return self
                end

                function object:Refresh()
                    getOptions()
                    return self
                end

                local function open()
                    window:_closeDropdown()
                    dismissLayer.Visible = true
                    arrow.Text = "⌃"

                    local values = getOptions()
                    local itemHeight = 34
                    local maxVisibleItems = options.MaxVisibleItems or 6
                    local popupHeight = math.min(math.max(1, #values) * itemHeight + 8, maxVisibleItems * itemHeight + 8)
                    local triggerPos = trigger.AbsolutePosition
                    local triggerSize = trigger.AbsoluteSize
                    local viewportSize = getViewport()

                    local x = triggerPos.X
                    local belowY = triggerPos.Y + triggerSize.Y + 6
                    local aboveY = triggerPos.Y - popupHeight - 6
                    local spaceBelow = viewportSize.Y - belowY
                    local y = (spaceBelow >= popupHeight or aboveY < 8) and belowY or aboveY

                    local popupWidth = math.max(triggerSize.X, options.MinPopupWidth or 180)
                    if x + popupWidth > viewportSize.X - 8 then
                        x = viewportSize.X - popupWidth - 8
                    end
                    x = math.max(8, x)
                    y = math.max(8, math.min(y, viewportSize.Y - popupHeight - 8))

                    popup = new("ScrollingFrame", {
                        Name = "DropdownPopup",
                        BackgroundColor3 = theme.Surface3,
                        BorderSizePixel = 0,
                        Position = UDim2.fromOffset(x, y),
                        Size = UDim2.fromOffset(popupWidth, popupHeight),
                        CanvasSize = UDim2.fromOffset(0, math.max(0, #values * itemHeight + 8)),
                        ScrollBarThickness = 2,
                        ScrollBarImageColor3 = theme.Border,
                        ScrollBarImageTransparency = 0.1,
                        ZIndex = 910,
                    }, portal)
                    corner(popup, 10)
                    stroke(popup, theme.Border, 0.18, 1)
                    padding(popup, 4, 4, 4, 4)

                    local list = new("UIListLayout", {
                        Padding = UDim.new(0, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }, popup)

                    if #values == 0 then
                        new("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, itemHeight),
                            Font = Enum.Font.Gotham,
                            Text = tostring(options.EmptyText or "No options"),
                            TextSize = 10,
                            TextColor3 = theme.MutedText,
                            ZIndex = 911,
                        }, popup)
                    else
                        for _, value in ipairs(values) do
                            local item = new("TextButton", {
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Size = UDim2.new(1, 0, 0, itemHeight),
                                Font = Enum.Font.GothamMedium,
                                Text = "  " .. value,
                                TextSize = 10,
                                TextColor3 = value == object.Value and theme.Accent or theme.Text,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                AutoButtonColor = false,
                                ZIndex = 911,
                            }, popup)

                            window:_connect(item.MouseEnter, function()
                                item.BackgroundTransparency = 0
                                item.BackgroundColor3 = theme.Surface2
                            end)
                            window:_connect(item.MouseLeave, function()
                                item.BackgroundTransparency = 1
                            end)
                            window:_connect(item.MouseButton1Click, function()
                                object:SetValue(value)
                                close()
                            end)
                        end
                    end

                    window._openDropdown = dropdownApi
                end

                window:_connect(trigger.MouseButton1Click, function()
                    if window._openDropdown == dropdownApi then
                        close()
                    else
                        open()
                    end
                end)

                renderTrigger()
                object.Instance = row
                object.Trigger = trigger
                object.Close = close
                return object
            end

            function section:AddButton(options)
                if type(options) == "string" then
                    options = { Text = options }
                else
                    options = options or {}
                end

                local row = controlFrame(options.Height or 38)
                local button = new("TextButton", {
                    BackgroundColor3 = options.Danger and theme.Danger or theme.Surface3,
                    BorderSizePixel = 0,
                    Size = UDim2.fromScale(1, 1),
                    Font = Enum.Font.GothamMedium,
                    Text = tostring(options.Text or "Button"),
                    TextSize = 11,
                    TextColor3 = theme.Text,
                    AutoButtonColor = false,
                    ZIndex = 17,
                }, row)
                corner(button, 8)

                window:_connect(button.MouseEnter, function()
                    if not options.Danger then
                        TweenService:Create(button, TweenInfo.new(0.12), {
                            BackgroundColor3 = theme.AccentSoft,
                        }):Play()
                    end
                end)
                window:_connect(button.MouseLeave, function()
                    if not options.Danger then
                        TweenService:Create(button, TweenInfo.new(0.12), {
                            BackgroundColor3 = theme.Surface3,
                        }):Play()
                    end
                end)
                window:_connect(button.MouseButton1Click, function()
                    safeCall(options.Callback)
                end)

                local object = {
                    Instance = row,
                    Button = button,
                }

                function object:SetText(text)
                    button.Text = tostring(text or "")
                    return self
                end

                return object
            end

            function section:AddLabel(options)
                if type(options) == "string" then
                    options = { Text = options }
                else
                    options = options or {}
                end

                local height = options.Height or (options.Wrap and 44 or 28)
                local row = controlFrame(height)
                local label = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Font = options.Bold and Enum.Font.GothamMedium or Enum.Font.Gotham,
                    Text = tostring(options.Text or ""),
                    TextSize = options.TextSize or 10,
                    TextColor3 = options.Muted and theme.MutedText or theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = options.Wrap == true,
                    ZIndex = 17,
                }, row)

                local object = {
                    Instance = row,
                    Label = label,
                    Value = label.Text,
                }

                function object:SetText(text)
                    self.Value = tostring(text or "")
                    label.Text = self.Value
                    return self
                end

                return object
            end

            table.insert(tab.Sections, section)
            task.defer(updateSectionHeight)
            task.defer(relayout)
            return section
        end

        table.insert(self.Tabs, tab)

        self:_connect(button.MouseButton1Click, function()
            self:SelectTab(tab)
        end)

        if not self._activeTab then
            self:SelectTab(tab)
        end

        task.defer(function()
            self:_applyResponsive()
            relayout()
        end)

        return tab
    end

    function window:SelectTab(tabOrName)
        local selected = tabOrName
        if type(tabOrName) == "string" then
            for _, tab in ipairs(self.Tabs) do
                if tab.Name == tabOrName then
                    selected = tab
                    break
                end
            end
        end

        if type(selected) ~= "table" then
            return
        end

        self:_closeDropdown()

        for _, tab in ipairs(self.Tabs) do
            local active = tab == selected
            tab.Page.Visible = active
            tab.NavButton.BackgroundColor3 = active and theme.Accent or theme.Surface2
            tab.NavIcon.TextColor3 = active and theme.Text or theme.MutedText
            tab.NavLabel.TextColor3 = theme.Text
        end

        self._activeTab = selected
        task.defer(selected._relayout)
    end

    -- Dragging
    do
        local dragging = false
        local dragStart = Vector2.zero
        local startPos = Vector2.zero

        window:_connect(header.InputBegan, function(input)
            if window._minimized and input.UserInputType == Enum.UserInputType.Touch then
                -- still draggable
            end

            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                window:_closeDropdown()
                dragStart = input.Position
                startPos = Vector2.new(host.Position.X.Offset, host.Position.Y.Offset)
            end
        end)

        window:_connect(UserInputService.InputChanged, function(input)
            if not dragging then
                return
            end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            local delta = input.Position - dragStart
            local viewportSize = getViewport()
            local hostSize = host.AbsoluteSize
            local margin = 8
            local x = clamp(startPos.X + delta.X, margin, math.max(margin, viewportSize.X - hostSize.X - margin))
            local y = clamp(startPos.Y + delta.Y, margin, math.max(margin, viewportSize.Y - hostSize.Y - margin))
            host.Position = UDim2.fromOffset(x, y)
        end)

        window:_connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    -- Windows-style resizing: N/S/E/W + four corners.
    local resizeHandles = {}
    local function addResizeHandle(name, direction, position, size)
        local handle = new("Frame", {
            Name = name,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = position,
            Size = size,
            Active = true,
            ZIndex = 100,
        }, host)
        table.insert(resizeHandles, handle)

        local resizing = false
        local startMouse = Vector2.zero
        local startLeft, startTop, startRight, startBottom

        window:_connect(handle.InputBegan, function(input)
            if window._minimized then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                window:_closeDropdown()
                startMouse = input.Position
                local pos = Vector2.new(host.Position.X.Offset, host.Position.Y.Offset)
                local sizeNow = Vector2.new(host.Size.X.Offset, host.Size.Y.Offset)
                startLeft = pos.X
                startTop = pos.Y
                startRight = pos.X + sizeNow.X
                startBottom = pos.Y + sizeNow.Y
            end
        end)

        window:_connect(UserInputService.InputChanged, function(input)
            if not resizing then
                return
            end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            local delta = input.Position - startMouse
            local left, top, right, bottom = startLeft, startTop, startRight, startBottom

            if direction:find("W") then left = startLeft + delta.X end
            if direction:find("E") then right = startRight + delta.X end
            if direction:find("N") then top = startTop + delta.Y end
            if direction:find("S") then bottom = startBottom + delta.Y end

            local viewportSize = getViewport()
            local margin = 8
            local effectiveMinW = math.min(window._minSize.X, math.max(240, viewportSize.X - margin * 2))
            local effectiveMinH = math.min(window._minSize.Y, math.max(180, viewportSize.Y - margin * 2))
            local effectiveMaxW = math.min(window._maxSize.X, viewportSize.X - margin * 2)
            local effectiveMaxH = math.min(window._maxSize.Y, viewportSize.Y - margin * 2)

            if direction:find("W") then
                local width = right - left
                if width < effectiveMinW then left = right - effectiveMinW end
                if width > effectiveMaxW then left = right - effectiveMaxW end
                left = math.max(margin, left)
            elseif direction:find("E") then
                local width = right - left
                if width < effectiveMinW then right = left + effectiveMinW end
                if width > effectiveMaxW then right = left + effectiveMaxW end
                right = math.min(viewportSize.X - margin, right)
            end

            if direction:find("N") then
                local height = bottom - top
                if height < effectiveMinH then top = bottom - effectiveMinH end
                if height > effectiveMaxH then top = bottom - effectiveMaxH end
                top = math.max(margin, top)
            elseif direction:find("S") then
                local height = bottom - top
                if height < effectiveMinH then bottom = top + effectiveMinH end
                if height > effectiveMaxH then bottom = top + effectiveMaxH end
                bottom = math.min(viewportSize.Y - margin, bottom)
            end

            -- Re-apply min constraints after screen-edge clamping.
            local width = right - left
            local height = bottom - top
            if width < effectiveMinW then
                if direction:find("W") then
                    left = right - effectiveMinW
                else
                    right = left + effectiveMinW
                end
            end
            if height < effectiveMinH then
                if direction:find("N") then
                    top = bottom - effectiveMinH
                else
                    bottom = top + effectiveMinH
                end
            end

            left = clamp(left, margin, viewportSize.X - margin - effectiveMinW)
            top = clamp(top, margin, viewportSize.Y - margin - effectiveMinH)
            right = clamp(right, left + effectiveMinW, viewportSize.X - margin)
            bottom = clamp(bottom, top + effectiveMinH, viewportSize.Y - margin)

            host.Position = UDim2.fromOffset(math.floor(left), math.floor(top))
            host.Size = UDim2.fromOffset(math.floor(right - left), math.floor(bottom - top))
            window._savedSize = Vector2.new(host.Size.X.Offset, host.Size.Y.Offset)
        end)

        window:_connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                resizing = false
            end
        end)
    end

    local edge = 7
    local cornerSize = 16
    addResizeHandle("ResizeN", "N", UDim2.fromOffset(cornerSize, 0), UDim2.new(1, -cornerSize * 2, 0, edge))
    addResizeHandle("ResizeS", "S", UDim2.new(0, cornerSize, 1, -edge), UDim2.new(1, -cornerSize * 2, 0, edge))
    addResizeHandle("ResizeW", "W", UDim2.fromOffset(0, cornerSize), UDim2.new(0, edge, 1, -cornerSize * 2))
    addResizeHandle("ResizeE", "E", UDim2.new(1, -edge, 0, cornerSize), UDim2.new(0, edge, 1, -cornerSize * 2))
    addResizeHandle("ResizeNW", "NW", UDim2.fromOffset(0, 0), UDim2.fromOffset(cornerSize, cornerSize))
    addResizeHandle("ResizeNE", "NE", UDim2.new(1, -cornerSize, 0, 0), UDim2.fromOffset(cornerSize, cornerSize))
    addResizeHandle("ResizeSW", "SW", UDim2.new(0, 0, 1, -cornerSize), UDim2.fromOffset(cornerSize, cornerSize))
    addResizeHandle("ResizeSE", "SE", UDim2.new(1, -cornerSize, 1, -cornerSize), UDim2.fromOffset(cornerSize, cornerSize))

    function window:SetMinimized(value)
        value = value == true
        if self._minimized == value then
            return
        end

        self:_closeDropdown()
        self._minimized = value

        if value then
            self._savedSize = Vector2.new(host.Size.X.Offset, host.Size.Y.Offset)
            body.Visible = false
            statusBar.Visible = false
            for _, handle in ipairs(resizeHandles) do
                handle.Active = false
            end
            minimizeButton.Text = "+"
            local vp = getViewport()
            local minimizedWidth = math.min(math.max(300, math.min(host.Size.X.Offset, 620)), math.max(280, vp.X - 16))
            -- Temporarily allow header-only height while minimized.
            sizeConstraint.MinSize = Vector2.new(math.min(sizeConstraint.MinSize.X, minimizedWidth), 60)
            TweenService:Create(host, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {
                Size = UDim2.fromOffset(minimizedWidth, 60),
            }):Play()
        else
            body.Visible = true
            statusBar.Visible = true
            for _, handle in ipairs(resizeHandles) do
                handle.Active = true
            end
            minimizeButton.Text = "—"
            updateSizeConstraint()
            local restore = self._savedSize or startSize
            local viewportSize = getViewport()
            restore = Vector2.new(
                math.min(restore.X, viewportSize.X - 16),
                math.min(restore.Y, viewportSize.Y - 16)
            )
            TweenService:Create(host, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {
                Size = UDim2.fromOffset(restore.X, restore.Y),
            }):Play()
            task.defer(function()
                self:_applyResponsive()
            end)
        end
    end

    function window:SetVisible(value)
        local hidden = not (value == true)
        if self._hidden == hidden then
            host.Visible = not self._hidden
            launcherButton.Visible = self._launcherEnabled and self._hidden
            return
        end

        self._hidden = hidden
        host.Visible = not self._hidden
        launcherButton.Visible = self._launcherEnabled and self._hidden

        if self._hidden then
            self:_closeDropdown()
        else
            task.defer(function()
                self:_applyResponsive()
            end)
        end
    end

    function window:IsVisible()
        return not self._hidden
    end

    function window:Toggle()
        self:SetVisible(self._hidden)
    end

    function window:Destroy()
        if self._destroyed then
            return
        end
        self._destroyed = true
        self:_closeDropdown()
        for _, connection in ipairs(self._connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        self._connections = {}
        if gui then
            gui:Destroy()
        end
    end

    window:_connect(minimizeButton.MouseButton1Click, function()
        window:SetMinimized(not window._minimized)
    end)

    window:_connect(closeButton.MouseButton1Click, function()
        if window._closeBehavior == "destroy" then
            window:Destroy()
        else
            window:SetVisible(false)
        end
    end)

    window:_connect(launcherButton.MouseButton1Click, function()
        window:SetVisible(true)
    end)

    window:_connect(host:GetPropertyChangedSignal("AbsoluteSize"), function()
        task.defer(function()
            window:_applyResponsive()
        end)
    end)

    window:_connect(UserInputService.InputBegan, function(input, processed)
        if processed or window._destroyed then
            return
        end
        if input.KeyCode == toggleKey then
            window:Toggle()
        end
    end)

    if workspace.CurrentCamera then
        window:_connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
            updateSizeConstraint()
            local vp = getViewport()
            local sizeNow = host.AbsoluteSize
            local newWidth = math.min(sizeNow.X, math.max(280, vp.X - 16))
            local newHeight = math.min(sizeNow.Y, math.max(200, vp.Y - 16))
            host.Size = UDim2.fromOffset(newWidth, newHeight)

            local pos = Vector2.new(host.Position.X.Offset, host.Position.Y.Offset)
            host.Position = UDim2.fromOffset(
                clamp(pos.X, 8, math.max(8, vp.X - newWidth - 8)),
                clamp(pos.Y, 8, math.max(8, vp.Y - newHeight - 8))
            )
            window:_closeDropdown()
            window:_applyResponsive()
        end)
    end

    window:_applyResponsive()
    return window
end

return KiraUI
