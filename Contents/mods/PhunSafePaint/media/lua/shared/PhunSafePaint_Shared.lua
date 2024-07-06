PhunSafePaint = {
    inied = false,
    name = "PhunSafePaint",
    settings = {},
    commands = {
        replaceSafehouse = "replaceSafehouse"
    },
    players = {},
    events = {},
    safehouse = nil,
    isHighlighted = false,
    highlightedArea = nil,
    highlightEndTimestamp = 0,
    ignoreMinDistantIfMutualPlayer = false
}

for _, event in pairs(PhunSafePaint.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function PhunSafePaint:ini()
    if not self.inied then
        self.inied = true
        print(self.name .. " inied!!!!!")
    end

end

local function removeHighlight()

    if PhunSafePaint.highlightEndTimestamp < getTimestamp() then
        Events.EveryOneMinute.Remove(removeHighlight)
        local ps = PhunSafePaint
        if ps.isHighlighted and ps.highlightedArea then
            local toRemove = PhunTools:boxToSquares(ps.highlightedArea.x, ps.highlightedArea.x2, ps.highlightedArea.y,
                ps.highlightedArea.y2)
            PhunTools:removeHighlightedSquares(toRemove)
        end
        ps.isHighlighted = false
        ps.highlightedArea = nil
        ps.safehouse = nil
    end

end

function PhunSafePaint:removeHighlight(inSeconds)

    if inSeconds == false or inSeconds == true then
        -- now
        self.highlightEndTimestamp = 0
        removeHighlight()
        return

    end

    inSeconds = inSeconds or 5
    self.highlightEndTimestamp = getTimestamp() + inSeconds
    Events.EveryOneMinute.Add(removeHighlight)

end

function PhunSafePaint:highlightSafehouse(safehouse)
    self:removeHighlight(true)
    self.safehouse = safehouse
    self.isHighlighted = true
    self.highlightedArea = {
        x = safehouse:getX(),
        y = safehouse:getY(),
        x2 = safehouse:getX() + safehouse:getW(),
        y2 = safehouse:getY() + safehouse:getH()
    }
    local squares = self:getSafehouseSquares(safehouse)
    PhunTools:highlightSquares(squares)
end

Events.OnInitGlobalModData.Add(function()
    PhunSafePaint:ini()
end)
