require("PhunSafePaint_Context")
require("PhunSafePaint_Safehouse")

local PhunSafePaint = PhunSafePaint

Events.OnFillInventoryObjectContextMenu.Add(function(playerNum, context, items)

    local item = nil
    local playerObj = getSpecificPlayer(playerNum)
    for i = 1, #items do
        if not instanceof(items[i], "InventoryItem") then
            item = items[i].items[1]
        else
            item = items[i]
        end

        if item then
            local itemType = item:getType()
            if itemType == "RepellentPaint" then

                PhunSafePaint:doPaintContext(playerObj, context, playerObj:getX(), playerObj:getY(), playerObj:getZ())

            end
        end
    end
end)

Events.OnPlayerMove.Add(function(playerObj)
    if PhunSafePaint.isHighlighted then
        -- are we still in area?
        local x, y = playerObj:getX(), playerObj:getY()
        local area = PhunSafePaint.highlightedArea
        if x < (area.x - 10) or x > (area.x2 + 10) or y < (area.y - 10) or y > (area.y2 + 10) then
            PhunSafePaint:highlightClosestSafehouse(playerObj, true)
        end
    end
end)
