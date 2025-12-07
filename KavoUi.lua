-- KavoUI-GG (Floating UI / Stack-Based Navigation)
-- Save as: KavoUI.lua

local Kavo = {}

function Kavo:CreateWindow(title)
    local window = {
        title = title or "Menu",
        tabs = {},
        currentTab = 1,
        currentSection = nil,

        -- Dynamic navigation stack (each entry = {title=..., options={ {text=..., action=function} } })
        _stack = {}
    }

    ------------------------------------------------------
    -- Dynamic Menu Stack API
    ------------------------------------------------------
    
    function window:openMenu(menu)
        -- Replaces the entire stack and opens the new menu on top
        self._stack = {}
        if menu then table.insert(self._stack, menu) end
    end

    function window:pushMenu(menu)
        -- Pushes a new menu into the stack (nested navigation)
        if menu then table.insert(self._stack, menu) end
    end

    function window:backMenu()
        -- Returns one level back
        if #self._stack > 0 then
            table.remove(self._stack)
        end
    end

    ------------------------------------------------------
    -- Tab / Section / Element Creation
    ------------------------------------------------------
    function window:CreateTab(name)
        local tab = { name = name, sections = {} }

        function tab:CreateSection(title)
            local section = { title = title, elements = {} }

            -- Creates a button (simple action)
            function section:AddButton(text, callback)
                table.insert(self.elements, { type = "button", text = text, callback = callback })
            end

            -- Creates a toggle (boolean state)
            function section:AddToggle(text, default, callback)
                table.insert(self.elements, {
                    type = "toggle",
                    text = text,
                    state = default and true or false,
                    callback = callback
                })
            end

            -- Creates a numeric slider (min/max/default)
            function section:AddSlider(text, min, max, default, callback)
                table.insert(self.elements, {
                    type = "slider",
                    text = text,
                    min = min,
                    max = max,
                    value = default or min,
                    callback = callback
                })
            end

            -- Creates a text input
            function section:AddInput(text, default, callback)
                table.insert(self.elements, {
                    type = "input",
                    text = text,
                    value = default or "",
                    callback = callback
                })
            end

            table.insert(tab.sections, section)
            return section
        end

        table.insert(window.tabs, tab)
        return tab
    end

    ------------------------------------------------------
    -- Utility Functions
    ------------------------------------------------------
    
    -- Safe gg.choice wrapper (handles "touch outside" as last option)
    local function safe_choice(list, header)
        local choice = gg.choice(list, nil, header)
        if choice == nil then
            -- Touch outside → default to last option (usually "Back")
            return #list
        end
        return choice
    end

    -- Safe callback executor with error capture
    local function call_safe(fn, ...)
        if not fn then return end
        local ok, err = pcall(fn, ...)
        if not ok then
            gg.toast("Error: " .. tostring(err))
        end
    end

    ------------------------------------------------------
    -- Main UI Loop (Floating Mode)
    ------------------------------------------------------
    function window:Show()
        gg.showUiButton()

        while true do
            if gg.isVisible(true) then
                gg.setVisible(false)

                ------------------------------------------------------
                -- If stack has menus, show top-level dynamic menu
                ------------------------------------------------------
                if #self._stack > 0 then
                    local top = self._stack[#self._stack]

                    -- Build option list
                    local opts = {}
                    for i, o in ipairs(top.options or {}) do
                        table.insert(opts, o.text or ("Option " .. i))
                    end
                    table.insert(opts, "↩ Back")

                    local pick = safe_choice(opts, top.title or "Menu")

                    if pick == #opts then
                        -- Back in stack
                        self:backMenu()
                    else
                        local opt = top.options[pick]
                        if opt and opt.action then
                            call_safe(opt.action) -- Action may push new menus
                        end
                    end
                    goto continue
                end

                ------------------------------------------------------
                -- Tab Selection
                ------------------------------------------------------
                local tabList = {}
                for _, t in ipairs(self.tabs) do
                    table.insert(tabList, t.name)
                end
                table.insert(tabList, "❌ Exit")

                local t = safe_choice(tabList, self.title)

                if t == #tabList then
                    -- Exit confirmation
                    local confirm = gg.choice({"Yes", "No"}, nil, "Exit?")
                    if confirm == 1 then os.exit() end
                    goto continue
                end

                local tab = self.tabs[t]
                self.currentTab = t

                ------------------------------------------------------
                -- Section Loop
                ------------------------------------------------------
                while true do
                    local secList = {}
                    for _, s in ipairs(tab.sections) do
                        table.insert(secList, s.title)
                    end
                    table.insert(secList, "↩ Back")

                    local s = safe_choice(secList, tab.name)
                    if s == #secList then break end

                    local section = tab.sections[s]

                    ------------------------------------------------------
                    -- Element Loop
                    ------------------------------------------------------
                    while true do
                        local elemList = {}
                        for _, e in ipairs(section.elements) do
                            if e.type == "toggle" then
                                table.insert(elemList, e.text .. " : " .. (e.state and "🟢 ON" or "🔴 OFF"))
                            elseif e.type == "slider" then
                                table.insert(elemList, e.text .. " : " .. tostring(e.value))
                            elseif e.type == "input" then
                                table.insert(elemList, e.text .. " : " .. tostring(e.value))
                            else
                                table.insert(elemList, e.text)
                            end
                        end
                        table.insert(elemList, "↩ Back")

                        local eIdx = safe_choice(elemList, section.title)
                        if eIdx == #elemList then break end

                        local el = section.elements[eIdx]

                        ------------------------------------------------------
                        -- Element Behavior
                        ------------------------------------------------------

                        if el.type == "button" then
                            call_safe(el.callback)

                        elseif el.type == "toggle" then
                            -- Confirmation dialog
                            local res = gg.choice({"Yes", "No"}, nil, "Confirm: " .. el.text .. " ?")
                            if res == 1 then
                                el.state = not el.state
                                call_safe(el.callback, el.state)
                                gg.toast(el.text .. " → " .. (el.state and "🟢 ON" or "🔴 OFF"))
                            else
                                gg.toast("Canceled")
                            end

                        elseif el.type == "slider" then
                            local prompt = el.text .. " (" .. el.min .. "-" .. el.max .. ")"
                            local val = gg.prompt({prompt}, {el.value}, {"number"})

                            if val then
                                local n = tonumber(val[1])
                                if n then
                                    if n < el.min then n = el.min end
                                    if n > el.max then n = el.max end
                                    el.value = n
                                    call_safe(el.callback, n)
                                    gg.toast(el.text .. " → " .. tostring(n))
                                end
                            else
                                gg.toast("Canceled")
                            end

                        elseif el.type == "input" then
                            local val = gg.prompt({el.text}, {el.value}, {"text"})
                            if val then
                                el.value = val[1]
                                call_safe(el.callback, el.value)
                                gg.toast(el.text .. " → " .. el.value)
                            else
                                gg.toast("Canceled")
                            end
                        end
                    end
                end
            end
            ::continue::
        end
    end

    return window
end

------------------------------------------------------
-- Public Stack Helpers for Convenience
------------------------------------------------------
function Kavo.openMenu(window, menu)
    if type(window) ~= "table" or not window.pushMenu then
        return nil, "Usage: Kavo.openMenu(window, menu)"
    end
    window:openMenu(menu)
end

function Kavo.pushMenu(window, menu)
    if type(window) ~= "table" or not window.pushMenu then
        return nil, "Usage: Kavo.pushMenu(window, menu)"
    end
    window:pushMenu(menu)
end

function Kavo.backMenu(window)
    if type(window) ~= "table" or not window.backMenu then
        return nil, "Usage: Kavo.backMenu(window)"
    end
    window:backMenu()
end

------------------------------------------------------
-- Dynamic Welcome Alert
------------------------------------------------------
function Kavo:Welcome(msg)
    -- nil → no alert
    -- "" → default welcome message
    -- "text" → custom message
    if msg == nil then return end
    if msg == "" then
        gg.alert("Welcome to the menu!", "KavoUI-GG")
    else
        gg.alert(msg)
    end
end

return Kavo
