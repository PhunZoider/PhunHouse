if isServer() then
    return
end
local PP = PhunSafePaint

function PP:getNearestSafehouse(playerObj, x, y, limit)
    -- if ther isn't one within this many blocks, don't bother
    limit = limit or 50 -- default to 50
    local data = self:getClosestPlayerSafehouseDistance(playerObj)
    if data and (data.distance or 0) < limit then
        return data.safehouse
    end
end

function PP:doPaintContext(player, context, x, y, z)

    local playerObj = nil
    if instanceof(player, "IsoPlayer") then
        playerObj = player
    else
        playerObj = getSpecificPlayer(player)
    end

    local closest = self:getClosestSafehouseTo(x, y)

    local canCreate = self:canCreateHere(playerObj, x, y)

    local memberOf = closest and self:playerIsMemberOf(closest, playerObj)
    local option = context:addOptionOnTop(getText("UI_PhunSafe_Create"), playerObj, function()
        local bo = PhunSafePaintCreateCursor:new(playerObj)
        getCell():setDrag(bo, bo.player)
    end)
    local toolTip = ISToolTip:new();
    toolTip:setVisible(false);
    toolTip:setName("Create Safehouse");
    option.notAvailable = not canCreate
    if not canCreate then
        toolTip.description = "You cannot create a safehouse here"
    else
        toolTip.description = "Create a new safehouse here where you are set as the owner"
    end
    option.toolTip = toolTip;

    local toolTipText = getText("UI_PhunSafe_Extend_Tooltip")
    local toolTipEnabled = true

    if closest then
        local distance, closestX, closestY = self:getDistanceFromPlayer(closest, playerObj)

        if not self:playerIsMemberOf(closest, playerObj) and not self:canIgnore() then
            -- not a member
            toolTipText = getText("UI_PhunSafe_Extend_Tooltip_Err_Not_Member")
            toolTipEnabled = false

        elseif distance > 10 then
            -- too far
            toolTipText = getText("UI_PhunSafe_Extend_Tooltip_Err_Get_Closer")
            toolTipEnabled = false

        end

    end

    local option = context:addOptionOnTop(getText("UI_PhunSafe_Extend"), playerObj, function()
        if closest then
            local square = playerObj:getCurrentSquare()
            PP:highlightSafehouse(closest)
            local area = PP:getAreaOfSafehouse(closest)
            if area then
                local bo = PhunSafePaintCursor:new(playerObj, closest)
                getCell():setDrag(bo, bo.player)
            end
        end
    end)
    local toolTip = ISToolTip:new();
    toolTip:setVisible(false);
    toolTip:setName(getText("UI_PhunSafe_Extend"));
    toolTip.description = toolTipText
    option.notAvailable = not toolTipEnabled
    option.toolTip = toolTip;

end
