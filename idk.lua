local RitualHub = {}

RitualHub.Name = "Ritual Hub"
RitualHub.Version = "1.0"

RitualHub.Theme = {
    Background = "#111116",
    Secondary = "#18181F",
    Accent = "#8B5CF6",
    Text = "#FFFFFF",
    SubText = "#9B9BA7"
}

RitualHub.Tabs = {
    "Main",
    "Combat",
    "Fruits",
    "Teleport",
    "Settings"
}

RitualHub.Buttons = {
    Main = {
        "Auto Farm",
        "Auto Quest",
        "Collect Chests"
    },

    Combat = {
        "Auto Attack",
        "Kill Aura",
        "Fast Attack"
    },

    Fruits = {
        "Fruit Finder",
        "Auto Collect",
        "Fruit ESP"
    },

    Teleport = {
        "First Sea",
        "Second Sea",
        "Third Sea"
    },

    Settings = {
        "UI Settings",
        "Keybinds",
        "Destroy UI"
    }
}

function RitualHub:CreateButton(name, callback)
    print("[Ritual Hub] Button created:", name)

    return {
        Name = name,
        Callback = callback
    }
end

function RitualHub:CreateToggle(name, callback)
    local enabled = false

    return {
        Name = name,

        Toggle = function()
            enabled = not enabled
            callback(enabled)
        end
    }
end

function RitualHub:Open()
    print("╔════════════════════╗")
    print("       RITUAL HUB")
    print("╚════════════════════╝")
end

function RitualHub:Destroy()
    print("[Ritual Hub] UI destroyed")
end

RitualHub:Open()

return RitualHub
