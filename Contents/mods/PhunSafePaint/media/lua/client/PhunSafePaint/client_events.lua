if isServer() then
    return
end
local Commands = require("PhunSafePaint/client_commands")
require("PhunSafePaint/context")
local PP = PhunSafePaint

Events.OnPlayerMove.Add(function(playerObj)
    if PP.isHighlighted then
        -- are we still in area?
        local x, y = playerObj:getX(), playerObj:getY()
        local area = PP.highlightedArea
        if x < (area.x - 10) or x > (area.x2 + 10) or y < (area.y - 10) or y > (area.y2 + 10) then
            PP:highlightClosestSafehouse(playerObj, true)
        end
    end
end)

Events.OnServerCommand.Add(function(module, command, args)
    if module == PP.name and Commands[command] then
        Commands[command](args)
    end
end)

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

                PP:doPaintContext(playerObj, context, playerObj:getX(), playerObj:getY(), playerObj:getZ())

            end
        end
    end
end)
