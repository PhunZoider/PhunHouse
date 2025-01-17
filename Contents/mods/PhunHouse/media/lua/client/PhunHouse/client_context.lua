if isServer() then
    return
end
local PP = PhunHouse

function PP:doPaintContext(player, context, x, y, z)

    local playerObj = nil
    if instanceof(player, "IsoPlayer") then
        playerObj = player
    else
        playerObj = getSpecificPlayer(player)
    end

    local closest = PP.getClosest(playerObj)
    local houses = PP.getPlayerSafehouses(playerObj, true)

    local canCreate = true
    local cannotCreateReasons = nil
    if not PP:canIgnore() then

        if houses and PP.settings.MaxNumberOfOwned > 0 and #houses >= PP.settings.MaxNumberOfOwned then
            cannotCreateReasons = getText("UI_PhunSafe_Create_Tooltip_Err_Max_Owned")
        end
        if closest then
            local distance = PP.getDistanceOfSafehouse(playerObj:getX(), playerObj:getY(), closest)
            if distance <= PP.settings.MinDistanceBetweenSafehouses then
                cannotCreateReasons = getText("UI_PhunSafe_Create_Tooltip_Err_TooClose")
            end
        end
    end

    local option = context:addOptionOnTop(getText("UI_PhunSafe_Create"), playerObj, function()
        local bo = PhunHouseCreateCursor:new(playerObj)
        getCell():setDrag(bo, bo.player)
    end)
    local toolTip = ISToolTip:new();
    toolTip:setVisible(false);
    toolTip:setName(getText("UI_PhunSafe_Create"));
    option.notAvailable = cannotCreateReasons ~= nil
    if cannotCreateReasons ~= nil then
        toolTip.description = cannotCreateReasons
    else
        toolTip.description = getText("UI_PhunSafe_Create_Tooltip")
    end
    option.toolTip = toolTip;

    local toolTipText = getText("UI_PhunSafe_Extend_Tooltip")
    local toolTipEnabled = true

    if closest and houses then
        local distance = PP.getDistanceOfSafehouse(playerObj:getX(), playerObj:getY(), closest)

        if not PP.playerIsMemberOf(closest, playerObj) and not PP:canIgnore() then
            -- not a member
            toolTipText = getText("UI_PhunSafe_Extend_Tooltip_Err_Not_Member")
            toolTipEnabled = false

        elseif distance > 10 then
            -- too far
            toolTipText = getText("UI_PhunSafe_Extend_Tooltip_Err_Get_Closer")
            toolTipEnabled = false

        end
    elseif not houses then
        toolTipText = getText("UI_PhunSafe_Extend_Tooltip_Err_No_Safehouse")
        toolTipEnabled = false
    else
        toolTipText = getText("UI_PhunSafe_Extend_Tooltip_Err_Get_Closer")
        toolTipEnabled = false
    end

    local option = context:addOptionOnTop(getText("UI_PhunSafe_Extend"), playerObj, function()
        if closest then
            local square = playerObj:getCurrentSquare()
            PP.highlight(closest, playerObj)
            local area = PP.getAreaOfSafehouse(closest)
            if area then
                local bo = PhunHouseCursor:new(playerObj, closest)
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
