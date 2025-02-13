if isServer() then
    return
end
local Commands = require("PhunHouse/client_commands")
require("PhunHouse/context")
local PP = PhunHouse

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
            if itemType == "HousePaint" then
                PP:doPaintContext(playerObj, context, playerObj:getX(), playerObj:getY(), playerObj:getZ())
            end
        end
    end
end)
