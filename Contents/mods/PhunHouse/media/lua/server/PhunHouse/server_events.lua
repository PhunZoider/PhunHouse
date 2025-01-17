if isClient() then
    return
end
local Commands = require("PhunHouse/server_commands")
local PP = PhunHouse

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == PP.name and Commands[command] then
        Commands[command](player, args)
    end
end)
