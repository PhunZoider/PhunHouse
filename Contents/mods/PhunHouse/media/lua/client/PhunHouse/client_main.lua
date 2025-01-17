if isServer() then
    return
end

local Core = PhunHouse

local function removeHighlight(playerObj)
    Core.highlight(nil, playerObj, true)
end

local function watchHighlight(playerObj)

    local house = playerObj:getModData().PhunHouse
    local safehouse = house and Core.getSafehouseByOwner(house.owner, house.x, house.y)
    if not safehouse then
        Events.OnPlayerUpdate.Remove(watchHighlight)
    else
        if house.when < getTimestamp() - 2 then
            -- playerObj:Say("Highlight expired")
            Core.highlight(safehouse, playerObj, true)
        elseif (house.when < getTimestamp() - 2) and house.x > playerObj:getX() and (house.x + house.w) <
            playerObj:getX() and house.y > playerObj:getY() and (house.y + house.h) < playerObj:getY() then
            -- playerObj:Say("Highlight out of bounds")
            Core.highlight(safehouse, playerObj, true)
        end
    end

end

function Core.highlight(safehouse, playerObj, remove)

    if not safehouse then
        return
    end
    local c = {
        a = 0.5,
        r = 1,
        g = 0,
        b = 0
    };

    local alpha = 0.49
    local squares = Core.getSafehouseSquares(safehouse) or {}
    local function fn()
        for _, square in ipairs(squares) do
            local objects = square:getObjects();
            for j = 0, objects:size() - 1 do
                local obj = objects:get(j);
                if alpha > 0 then
                    obj:setHighlighted(true, false);
                    obj:setHighlightColor(c.r, c.g, c.b, alpha);
                else
                    obj:setHighlighted(false, false);
                    obj:setHighlightColor(c.r, c.g, c.b, c.a);
                end
            end
        end
        if alpha <= 0 then
            Events.OnTick.Remove(fn)
        end
        alpha = alpha - 0.025
    end

    for _, square in ipairs(squares) do
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

    if remove then
        playerObj:getModData().PhunHouse = nil
        Events.OnPlayerUpdate.Remove(watchHighlight)
        Events.OnTick.Add(fn)
    else
        Events.OnTick.Remove(fn)
        playerObj:getModData().PhunHouse = {
            x = safehouse:getX(),
            y = safehouse:getY(),
            owner = safehouse:getOwner(),
            w = safehouse:getW(),
            h = safehouse:getH(),
            when = getTimestamp()
        }
        Events.OnPlayerUpdate.Add(watchHighlight)
    end

end

function Core.highlightClosest(playerObj)

    local safehouse = Core.getClosest(playerObj)
    Core.highlight(safehouse, playerObj)
end

function Core.isValidArea(playerObj, areas)
    local uses = playerObj:getInventory():getUsesTypeRecurse("HousePaint") or 0
    local tooClose = false
    local blockedZone = false

    if #areas > Core.settings.MaxTotalArea then
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
        uses = uses - (Core.settings.Consumption or 1)
    end
    return true
end
