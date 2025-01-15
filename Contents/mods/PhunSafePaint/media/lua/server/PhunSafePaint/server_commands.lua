if isClient() then
    return
end
local PP = PhunSafePaint
local Commands = {}

Commands[PP.commands.resize] = function(playerObj, args)
    print("resizeByOwner", playerObj:getUsername(), args.x, args.y, args.w, args.h)
    PP:resizeByOwner(args.owner or playerObj:getUsername(), args.x, args.y, args.w, args.h)
    sendServerCommand(playerObj, PP.name, PP.commands.resize, args)
end

return Commands
