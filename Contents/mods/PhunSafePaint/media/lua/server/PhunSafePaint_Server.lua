if not isServer() then
    return
end

function PhunSafePaint:replaceSafehouse(safehouse, x, y, x2, y2)

    local players = {}

    local respawners = {}
    local playersRespawn = safehouse.playersRespawn
    if playersRespawn then
        for i = 0, playersRespawn:size() - 1 do
            respawners[safehouse:getPlayers():get(i)] = true
        end
    end
    for i = 0, safehouse:getPlayers():size() - 1 do
        table.insert(players, {
            username = safehouse:getPlayers():get(i),
            respawn = respawners[safehouse:getPlayers():get(i)] == true
        })
    end
    local ownerName = safehouse:getOwner()
    local playerObj = getPlayerByRealUserName(ownerName)
    print(tostring(playerObj))
    SafeHouse.removeSafehouse(safehouse)
    return self:createSafehouse(x, y, x2, y2, ownerName, players)
end

function PhunSafePaint:createSafehouse(x, y, x2, y2, owner, players, title, remote)

    local safeObj = SafeHouse.addSafeHouse(x, y, x2 - x, y2 - y, owner, remote == true);
    safeObj:setTitle(title or (tostring(x) .. "," .. tostring(y) .. ", " .. tostring(getTimestamp())));
    safeObj:setOwner(owner);
    safeObj:updateSafehouse(getPlayer());

    for _, v in ipairs(players or {}) do
        safeObj:addPlayer(v.username)
        if v.respawn then
            safeObj:setRespawnInSafehouse(true, v.username)
        end
    end

    safeObj:syncSafehouse();
    return safeObj
end

local Commands = {}

Commands[PhunSafePaint.commands.replaceSafehouse] = function(playerObj, args)

    print("replaceSafehouse")
    PhunTools:printTable(args)

    local playerObj = getPlayerByUserName(args.player)
    print(tostring(playerObj))
    print(playerObj:getUsername())

end

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PhunSafePaint.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)
