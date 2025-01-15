if isServer() then
    return
end
local PP = PhunSafePaint
local Commands = {}

Commands[PP.commands.resize] = function(args)
    local house = PP:getSafehouseByOwner(args.owner or getPlayer())
    house:syncSafehouse()
    triggerEvent("OnSafehousesChanged")
    PP:highlightSafehouse(house)
end

return Commands
