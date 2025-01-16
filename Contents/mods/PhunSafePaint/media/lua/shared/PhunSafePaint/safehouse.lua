require "PhunSafePaint/core"
local Core = PhunSafePaint

-- Function to calculate the squared Euclidean distance
local function distance_squared(obj, x, y)
    local dx = obj:getX() - (x or 0)
    local dy = obj:getY() - (y or 0)
    return dx * dx + dy * dy -- Squared distance (avoids sqrt for performance)
end

-- get the players safehouse or at least the closest owned safehouse
function Core.getSafehouseByOwner(owner, x, y)

    local player = type(owner) == "string" and getPlayerFromUsername(owner) or owner
    local houses = Core.getPlayerSafehouses(player, true)

    if #houses == 0 then
        return nil
    end
    if #houses == 1 then
        return houses[1]
    end

    table.sort(houses, function(a, b)
        return distance_squared(a, x, y) < distance_squared(b, x, y)
    end)

    return houses[1]
end

-- get all safehouses owned by or a member of this player
function Core.getPlayerSafehouses(playerObj, asOwner)

    local safehouses = SafeHouse:getSafehouseList()
    local safehouseCount = safehouses:size()

    if safehouseCount == 0 then
        return nil
    end

    local houses = {}

    local name = playerObj
    if playerObj.getUsername then
        name = playerObj:getUsername()
    end

    for index = 1, safehouseCount, 1 do

        local safehouse = safehouses:get(index - 1)
        if Core:canIgnore() then
            table.insert(houses, safehouse)
        elseif asOwner ~= true and Core.playerIsMemberOf(safehouse, playerObj) then
            table.insert(houses, safehouse)
        elseif safehouse:getOwner() == name then
            table.insert(houses, safehouse)
        end
    end
    return houses
end

-- resize the safehouse owned by this player
function Core.resizeByOwner(owner, x, y, w, h)

    local house = Core.getSafehouseByOwner(owner)
    if house then
        return Core.resize(house, x, y, w, h)
    end

end

-- resize the safehouse
function Core.resize(safehouse, x, y, w, h)

    safehouse:setX(x)
    safehouse:setY(y)
    safehouse:setW(w)
    safehouse:setH(h)
    safehouse:syncSafehouse();
    triggerEvent("OnSafehousesChanged")
    return safehouse

end

-- get the distance to the closest safehouse from player
function Core.getClosest(playerObj, asOwner)

    local houses = Core.getPlayerSafehouses(playerObj, asOwner)
    if not houses then
        return nil
    end
    local x, y = playerObj:getX(), playerObj:getY()
    table.sort(houses, function(a, b)
        return distance_squared(a, x, y) < distance_squared(b, x, y)
    end)

    return houses[1]
end

-- check if player is an owner or a member of this safehouse
function Core.playerIsMemberOf(safehouse, playerObj)
    local name = playerObj:getUsername()
    if safehouse:getOwner() == name then
        return true
    end
    local players = safehouse:getPlayers()
    for i = 0, players:size() - 1 do
        if players:get(i) == name then
            return true
        end
    end
end

function Core.getAreaOfSafehouse(safehouse)

    return {
        x = safehouse:getX(),
        y = safehouse:getY(),
        x2 = safehouse:getX2(),
        y2 = safehouse:getY2()
    }

end

function Core.getSafehouseSquares(safehouse)
    if not safehouse then
        return
    end
    local x = safehouse.getX and safehouse:getX() or safehouse.x;
    local x2 = (safehouse.getX2 and safehouse:getX2() or safehouse.x2) - 1
    local y = safehouse.getY and safehouse:getY() or safehouse.y;
    local y2 = (safehouse.getY2 and safehouse:getY2() or safehouse.y2) - 1;
    local area = {}

    for i = x, x2 do
        for j = y, y2 do
            table.insert(area, getSquare(i, j, 0))
        end
    end

    return area
end

function Core.consume(player, area)
    for i = area.x, area.x2 - 1 do
        for j = area.y, area.y2 - 1 do
            for i = 1, (Core.settings.Consumption or 1) do
                local item = player:getInventory():getFirstTypeRecurse("SafetyPaint")
                if item then
                    item:Use()
                end
            end
        end
    end
end

-- Crate a new safehouse
function Core.create(x, y, x2, y2, ownerName, players, title, remote)

    local safeObj = SafeHouse.addSafeHouse(x, y, x2 - x, y2 - y, ownerName, remote == true);
    safeObj:setTitle(title or (ownerName .. "'s Safehouse"));
    safeObj:updateSafehouse(getPlayer());

    for _, v in ipairs(players or {}) do
        safeObj:addPlayer(v.username)
        if v.respawn then
            safeObj:setRespawnInSafehouse(true, v.username)
        end
    end

    safeObj:syncSafehouse();
    triggerEvent("OnSafehouseChanged");
    return safeObj
end

local zones = nil

function Core.validateAreas(safehouse, areas, skipDistanceCheck)
    if zones == nil then
        if PhunZones then
            zones = PhunZones or false
        end
    end
    for j, v in ipairs(areas) do
        if v.enabled == nil then
            v.enabled = true
        end
        if skipDistanceCheck ~= true then
            local distance = math.floor(Core.getDistanceOfSafehouse(v.x, v.y, safehouse))
            if not v.distance then
                v.distance = distance
            elseif v.distance < distance then
                v.distance = distance
            end
            if v.distance > 0 and v.distance <= Core.settings.MinDistanceBetweenSafehouses then
                v.enabled = false
            end
        end
        if zones and zones:getLocation(v.x, v.y).safehouse == false then
            v.enabled = false
            v.errZoneSafehouse = true
        end
    end
end

-- turn an area into table of boundaries
function Core.getExtensionAreas(area, sourceSafehouse)

    -- get the boundaries of the area as left, right, top, bottom
    local results = {
        left = {},
        right = {},
        top = {},
        bottom = {}
    }
    -- exclude corners
    for i = area.y + 1, area.y2 - 1, 1 do
        table.insert(results.left, {
            x = area.x,
            y = i
        })
        table.insert(results.right, {
            x = area.x2,
            y = i
        })
    end
    -- exclude corners
    for i = area.x + 1, area.x2 - 1, 1 do
        table.insert(results.top, {
            x = i,
            y = area.y
        })
        table.insert(results.bottom, {
            x = i,
            y = area.y2
        })
    end

    local safehouses = SafeHouse:getSafehouseList()
    for i = 1, safehouses:size(), 1 do

        local sh = safehouses:get(i - 1)

        for k, v in pairs(results) do
            if sourceSafehouse and sh == sourceSafehouse then
                Core.validateAreas(sh, v, true)
            else
                Core.validateAreas(sh, v)
            end
        end

    end
    return results

end

-- enlarge the area of the safehouse by 1 square in each direction
function Core.getExtArea(safehouse)

    local x, y, x2, y2 = safehouse:getX(), safehouse:getY(), safehouse:getX2(), safehouse:getY2()
    local area = {
        x = x - 1,
        y = y - 1,
        x2 = x2,
        y2 = y2
    }
    -- return info about the new area as left, right, top, bottom
    return Core.getExtensionAreas(area, safehouse)

end

-- get the closest point of the area to x, y
function Core.getClosestPoint(x, y, x1, y1, x2, y2)

    local minX = math.min(x1, x2)
    local maxX = math.max(x1, x2)
    local minY = math.min(y1, y2)
    local maxY = math.max(y1, y2)

    -- Check if the point is inside the area
    if x >= minX and x <= maxX and y >= minY and y <= maxY then
        -- Calculate distances to each edge
        local distanceToLeft = x - minX
        local distanceToRight = maxX - x
        local distanceToTop = y - minY
        local distanceToBottom = maxY - y

        -- Return the smallest distance to any edge
        return math.min(distanceToLeft, distanceToRight, distanceToTop, distanceToBottom)
    else
        -- If the point is outside, calculate the closest edge
        local closestX = math.max(minX, math.min(x, maxX))
        local closestY = math.max(minY, math.min(y, maxY))

        -- Calculate the distance to the closest boundary
        local dx = x - closestX
        local dy = y - closestY
        return math.sqrt(dx * dx + dy * dy)
    end

end

-- get distance of the point to the safehouse
function Core.getDistanceOfSafehouse(x, y, safehouse)
    if x > safehouse:getX() and x < safehouse:getX() + safehouse:getW() and y > safehouse:getY() and y <
        safehouse:getY() + safehouse:getH() then
        return -1
    end

    return Core.getClosestPoint(x, y, safehouse:getX(), safehouse:getY(), safehouse:getX() + safehouse:getW(),
        safehouse:getY() + safehouse:getH())

end
