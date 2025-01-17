PhunHouse = {
    inied = false,
    name = "PhunHouse",
    settings = {},
    commands = {
        resize = "PhunHouseResize"
    },
    events = {},
    highlightedArea = nil,
    ignoreMinDistantIfMutualPlayer = false
}

local Core = PhunHouse
Core.settings = SandboxVars[Core.name] or {}
-- Setup any events
for _, event in pairs(Core.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function Core.debug(...)

    local args = {...}
    for i, v in ipairs(args) do
        if type(v) == "table" then
            self:printTable(v)
        else
            print(tostring(v))
        end
    end

end

function Core.printTable(t, indent)
    indent = indent or ""
    for key, value in pairs(t or {}) do
        if type(value) == "table" then
            print(indent .. key .. ":")
            Core.printTable(value, indent .. "  ")
        elseif type(value) ~= "function" then
            print(indent .. key .. ": " .. tostring(value))
        end
    end
end

function Core:ini()
    if not self.inied then
        self.inied = true
    end

end

function Core:canIgnore()
    return (isAdmin() or isDebugEnabled()) and self.settings.AdminsIgnoreRestrictions
end
