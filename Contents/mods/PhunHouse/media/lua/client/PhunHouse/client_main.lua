if isServer() then
    return
end

local PP = PhunHouse

local currentlyHighlighted = {}

local function watchHighlight()
    for playerObj, vals in pairs(currentlyHighlighted or {}) do
        local x, y = playerObj:getX(), playerObj:getY()
        local area = PP.getAreaOfSafehouse(vals.house)
        if (x < (area.x - 5) or x > (area.x2 + 5) or y < (area.y - 5) or y > (area.y2 + 5)) then
            print("Player moved out of safehouse. removing highlight")
            PP.highlight(vals.house, playerObj, true)
            -- Events.EveryOneMinute.Remove(watchHighlight)
        else
            print("Player still in safehouse")
        end
    end
end

function PP.highlight(safehouse, playerObj, remove)

    if not safehouse then
        return
    end

    -- if currentlyHighlighted[playerObj] and currentlyHighlighted[playerObj].house then
    --     PP.highlight(currentlyHighlighted[playerObj].house, playerObj, true)
    --     currentlyHighlighted[playerObj] = nil
    --     print("Removing old highlight")
    --     Events.EveryOneMinute.Remove(watchHighlight)
    -- end

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
                currentlyHighlighted[playerObj] = {
                    house = safehouse,
                    when = getTimestamp()
                }
                print("Setting highlight")
                Events.EveryOneMinute.Add(watchHighlight)
            else
                obj:setHighlighted(false, false);
                obj:setHighlightColor(c.r, c.g, c.b, c.a);
                currentlyHighlighted[playerObj] = nil
                print("Removing old highlight")
                Events.EveryOneMinute.Remove(watchHighlight)
            end

        end
    end

end

function PP.highlightClosest(playerObj)

    local safehouse = PP.getClosest(playerObj)
    PP.highlight(safehouse, playerObj)
end

function PP.isValidArea(playerObj, areas)
    local uses = playerObj:getInventory():getUsesTypeRecurse("HousePaint") or 0
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
