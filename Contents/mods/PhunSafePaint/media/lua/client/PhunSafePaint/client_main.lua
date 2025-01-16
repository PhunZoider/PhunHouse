if isServer() then
    return
end

local PP = PhunSafePaint

local currentlyHighlighted = {}

local function watchHighlight()
    for playerObj, safehouse in pairs(currentlyHighlighted or {}) do
        local x, y = playerObj:getX(), playerObj:getY()
        local area = PP.getAreaOfSafehouse(safehouse)
        if x < (area.x - 10) or x > (area.x2 + 10) or y < (area.y - 10) or y > (area.y2 + 10) then
            PP.highlight(playerObj, false)
            Events.EveryOneMinute.Remove(watchHighlight)
        end
    end
end

function PP.highlight(safehouse, remove)

    if not safehouse then
        return
    end

    PP.isHighlighted = not remove

    local c = {
        a = 0.5,
        r = 1,
        g = 0,
        b = 0
    };

    for _, square in ipairs(PP.getSafehouseSquares(safehouse) or {}) do
        local objects = square:getObjects();
        for j = 0, objects:size() - 1 do
            local obj = objects:get(j);
            if remove ~= true then
                obj:setHighlighted(true, false);
                obj:setHighlightColor(c.r, c.g, c.b, c.a);
            else
                obj:setHighlighted(false, false);
                obj:setHighlightColor(c.r, c.g, c.b, c.a);
            end

        end
    end

end

function PP.highlightClosest(playerObj)
    if currentlyHighlighted[playerObj] then
        PP.highlight(currentlyHighlighted[playerObj], true)
        currentlyHighlighted[playerObj] = nil
        Events.EveryOneMinute.Remove(watchHighlight)
    end
    local safehouse = PP.getClosest(playerObj)
    if safehouse then
        currentlyHighlighted[playerObj] = safehouse
        Events.EveryOneMinute.Add(watchHighlight)
    end
    PP.highlight(safehouse)
end

function PP.isValidArea(playerObj, areas)
    local uses = playerObj:getInventory():getUsesTypeRecurse("SafetyPaint") or 0
    local tooClose = false
    local blockedZone = false

    if #areas > PP.settings.MaxTotalArea then
        return false
    end

    for _, v in ipairs(areas) do
        if not v.enabled then
            return false
        end
        if uses <= 0 then
            return false
        end
        if v.errDistance then
            return false
        end
        if v.errZoneSafehouse then
            return false
        end
        uses = uses - (PP.settings.Consumption or 1)
    end
    return true
end
