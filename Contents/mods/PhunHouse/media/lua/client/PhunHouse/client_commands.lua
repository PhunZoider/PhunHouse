if isServer() then
    return
end
local PP = PhunHouse
local Commands = {}

Commands[PP.commands.resize] = function(args)
    local house = PP.getSafehouseByOwner(args.owner or getPlayer(), args.x, args.y)
    house:syncSafehouse()
    triggerEvent("OnSafehousesChanged")
    PP.highlight(house, getPlayer())
end

return Commands
