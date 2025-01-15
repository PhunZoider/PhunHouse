if isClient() then
    return
end
local Commands = require("PhunSafePaint/server_commands")
local PP = PhunSafePaint

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == PP.name and Commands[command] then
        Commands[command](player, args)
    end
end)
