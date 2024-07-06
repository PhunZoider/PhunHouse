local PhunSafePaint = PhunSafePaint

function PhunSafePaint:getNearestSafehouse(playerObj, x, y, limit)
    -- if ther isn't one within this many blocks, don't bother
    limit = limit or 50 -- default to 50
    local data = PhunSafePaint:getClosestPlayerSafehouseDistance(playerObj)
    if data and (data.distance or 0) < limit then
        return data.safehouse
    end
end

function PhunSafePaint:doPaintContext(player, context, x, y, z)

    local playerObj = nil
    if instanceof(player, "IsoPlayer") then
        playerObj = player
    else
        playerObj = getSpecificPlayer(player)
    end

    if self:canCreateHere(playerObj, x, y) then
        context:addOptionOnTop(getText("UI_PhunSafe_Create"), playerObj, function()
            local bo = PhunSafePaintCreateCursor:new(playerObj)
            getCell():setDrag(bo, bo.player)
        end)
    end

    if self:canExtendHere(playerObj, x, y) then

        context:addOptionOnTop(getText("UI_PhunSafe_Extend"), playerObj, function()
            local safehouse = PhunSafePaint:getNearestSafehouse(playerObj)
            if safehouse then
                PhunSafePaint:highlightSafehouse(safehouse)
                local area = PhunSafePaint:getAreaOfSafehouse(safehouse)
                if area then
                    local bo = PhunSafePaintCursor:new(playerObj, safehouse)
                    getCell():setDrag(bo, bo.player)
                end
            end
        end)

    end

end
