# **KavoUI-GG**
A modern and structured Roblox-inspired UI library for **GameGuardian Lua scripts**.  
Designed to provide clean navigation, dynamic menus, toggles with icons, sliders, input fields, a welcome alert system, and a floating menu that **does not freeze the screen**.

KavoUI-GG aims to be the most intuitive UI framework for GameGuardian scripting.

---

## ✨ Features
- Floating UI mode (non-blocking gameplay)
- Tab → Section → Element architecture
- Buttons, Toggles, Sliders, Inputs
- Emoji toggle indicators (🟢 / 🔴)
- Automatic “Back” entries
- Global “Exit” option
- Optional dynamic welcome alert
- Stable internal navigation
- Zero dependencies
- **Can be used online directly from GitHub (no local download required)**

---

## 📦 Installation

### **Local file**
Download the file and load it in your script:

```lua
Kavo = loadfile("/storage/emulated/0/Download/KavoUI.lua")()
```

### **Online via GitHub (no download)**
You can load the library directly from your repository using:

```lua
local function import(url)
    return load(gg.makeRequest(url).content)()
end

Kavo = import("https://raw.githubusercontent.com/LiverMods/KavoGG/refs/heads/main/KavoUi.lua")
```

Replace `<username>` and `<repo>` with your GitHub names.

---

## 🧩 Basic Usage

### Create a window
```lua
local UI = Kavo:CreateWindow("My Menu")
```

### Create a tab
```lua
local tab = UI:CreateTab("Main")
```

### Create a section
```lua
local sec = tab:CreateSection("Features")
```

### Button
```lua
sec:AddButton("God Mode", function()
    gg.toast("God Mode Activated!")
end)
```

### Toggle
```lua
sec:AddToggle("Speed", false, function(state)
    gg.toast("Speed: " .. tostring(state))
end)
```

### Slider
```lua
sec:AddSlider("FOV", 10, 120, 60, function(value)
    gg.toast("FOV = " .. value)
end)
```

### Input
```lua
sec:AddInput("Player Name", "User", function(text)
    gg.toast("Name set to: " .. text)
end)
```

### Show (Floating Menu)
```lua
UI:Show()
```

---

## 📢 Welcome Message (Optional)

```lua
Kavo:Welcome("Welcome to the script!")
```

Rules:
- `nil` → No alert  
- `""` → Default welcome alert  
- `"Your text"` → Custom text alert  

---

## 📄 License
→ https://github.com/LiverMods/KavoGG/blob/main/LICENSE.md ←
