local PhunSafePaint = PhunSafePaint

function PhunSafePaint:getPlayerSafehouses(playerObj)

    local safehouses = SafeHouse:getSafehouseList()
    local safehouseCount = safehouses:size()

    if safehouseCount == 0 then
        return nil
    end

    local houses = {}

    for index = 1, safehouseCount, 1 do

        local safehouse = safehouses:get(index - 1)

        if self:playerIsMemberOf(safehouse, playerObj) then
            table.insert(houses, safehouse)
        end
    end
    return houses
end

function PhunSafePaint:canCreateHere(playerObj, x, y)

    if not isAdmin() and SandboxVars.PhunSafePaint.PhunSafePaint_MinSizeForNew > 0 then
        local existing = self:getPlayerSafehouses(playerObj)

        if not existing or #existing == 0 then
            return true
        end
    end
    return false
end

function PhunSafePaint:canExtendHere(playerObj, x, y, variance)

    if not isAdmin() then
        local data = PhunSafePaint:getClosestPlayerSafehouseDistance(playerObj)

        if data then
            local safehouse = data.safehouse
            if safehouse then
                variance = variance or 10
                local newX = safehouse:getX() - variance
                local newX2 = safehouse:getX() + safehouse:getW() + variance
                local newY = safehouse:getY() - variance
                local newY2 = safehouse:getY() + safehouse:getH() + variance

                local left = x >= newX
                local right = x <= newX2
                local top = y >= newY
                local bottom = y <= newY2

                return left and right and top and bottom
            end
        end
    end
    return false
end

function PhunSafePaint:getAreaOfSafehouse(safehouse)
    if safehouse and safehouse.getX then
        return {
            x = safehouse:getX(),
            y = safehouse:getY(),
            x2 = safehouse:getX() + safehouse:getW(),
            y2 = safehouse:getY() + safehouse:getH()
        }
    elseif safehouse.x2 then
        -- assert its coords
        local a = math.floor(math.sqrt(SandboxVars.PhunSafePaint.PhunSafePaint_MinSizeForNew or 9))
        local even = a % 2 == 0

        local area = {
            x = square:getX(),
            y = square:getY(),
            x2 = square:getX() + a,
            y2 = square:getY() + a
        }
        if not even then
            -- make cursor the centre?
            area.x = area.x - math.floor(a / 2)
            area.y = area.y - math.floor(a / 2)
            area.x2 = area.x + a
            area.y2 = area.y + a
        end
        return area
    end
end

function PhunSafePaint:playerIsMemberOf(safehouse, playerObj)
    local name = playerObj:getUsername()
    if safehouse:getOwner() == name then
        return true
    end
    local players = safehouse:getPlayers()
    for i = 0, players:size() - 1 do
        if players:get(i) == name then
            print("Player")
            return true
        end
    end
end

function PhunSafePaint:getClosestPlayerSafehouseDistance(playerObj)
    local x, y, z = playerObj:getX(), playerObj:getY(), playerObj:getZ()
    local safehouses = self:getPlayerSafehouses(playerObj)
    local closest = nil
    if safehouses and #safehouses > 0 then
        for i = 1, #safehouses, 1 do
            local safehouse = safehouses[i]
            if self:playerIsMemberOf(safehouse, playerObj) then
                local players = safehouse:getPlayers()

                local centerPoint = {
                    x = safehouse:getX() + (safehouse:getW() / 2),
                    y = safehouse:getY() + (safehouse:getH() / 2)
                }
                local distance = math.abs(centerPoint.x - x) + math.abs(centerPoint.y - y)
                if not closest or distance < closest.distance then
                    closest = {
                        safehouse = safehouse,
                        distance = distance
                    }
                end
            end
        end
    end
    return closest
end

function PhunSafePaint:getClosestPlayerSafehouse(playerObj)
    local closest = self:getClosestPlayerSafehouseDistance(playerObj)

    if closest then
        return closest.safehouse
    end
end

function PhunSafePaint:highlightClosestSafehouse(playerObj, remove)
    local safehouse = self:getClosestPlayerSafehouse(playerObj)
    if safehouse then
        self:highlightSafehouse(safehouse, remove)
    end
end

function PhunSafePaint:getSafehouseSquares(safehouse)
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

local function getDistanceFromEdges(fromEdge, comparedEdge)
    local dx = math.max(fromEdge.x - comparedEdge.x2, comparedEdge.x - fromEdge.x2, 0)
    local dy = math.max(fromEdge.y - comparedEdge.y2, comparedEdge.y - fromEdge.y2, 0)
    return math.sqrt(dx ^ 2 + dy ^ 2)
end

function PhunSafePaint:squaresDistanceToNextSafehouse(squares, excludePlayerObj, excludeSafehouse)

    local result = {}

    for i, v in ipairs(squares) do

        local canBe = true -- SafeHouse.canBeSafehouse(v, excludePlayerObj)
        local allowed = SafeHouse.allowSafeHouse(excludePlayerObj)

        local distance, info = self:squareDistanceToNextSafehouse(v, excludePlayerObj, excludeSafehouse)
        if distance then
            table.insert(result, {
                square = v,
                canBe = canBe,
                allowed = allowed,
                distance = distance,
                id = info.id,
                owner = info.owner,
                squareId = v:getID(),
                enabled = distance > (SandboxVars.PhunSafePaint_MinDistanceBetweenSafehouses or 25)
            })
        else
            table.insert(result, {
                squareId = v:getID(),
                canBe = canBe,
                allowed = allowed,
                enabled = true
            })
        end
    end
    return result
end

function PhunSafePaint:squareDistanceToNextSafehouse(square, excludePlayerObj, excludeSafehouse)
    return self:distanceToNextSafehouse(square:getX(), square:getY(), excludePlayerObj, excludeSafehouse)
end

function PhunSafePaint:distanceToNextSafehouse(x, y, excludePlayerObj, excludeSafehouse)

    local safehouses = SafeHouse:getSafehouseList()
    local safehouseCount = safehouses:size()
    local closest = {}
    local minDistance = nil
    local minInfo = nil
    for index = 1, safehouseCount, 1 do
        local sh = safehouses:get(index - 1)
        if sh ~= excludeSafehouse then

            -- do we ignore if we are a member?
            if not self.ignoreMinDistantIfMutualPlayer or
                (self.ignoreMinDistantIfMutualPlayer and excludePlayerObj and
                    self:playerIsMemberOf(sh, excludePlayerObj)) then

                local edges = self:getDistanceOfEdges(sh)
                edges.id = sh:getId()
                edges.owner = sh:getOwner()

                local minx = math.min(math.abs(sh:getX() - x), math.abs(sh:getX() + sh:getW() - x))
                local miny = math.min(math.abs(sh:getY() - y), math.abs(sh:getY() + sh:getH() - y))
                local d = math.sqrt(minx ^ 2 + miny ^ 2)

                if minDistance == nil or d < minDistance then
                    minDistance = d
                    minInfo = {
                        id = sh:getId(),
                        owner = sh:getOwner()
                    }
                end
            end
        end
    end
    return minDistance, minInfo

end

function PhunSafePaint:getEdgeDistances(fromSafehouse, excludePlayerObj)

    -- source edges
    local source = self:getDistanceOfEdges(fromSafehouse)

    local safehouses = SafeHouse:getSafehouseList()
    local safehouseCount = safehouses:size()

    if safehouseCount == 0 then
        return nil
    end

    local closestNE = {
        distance = nil
    }
    local closestNW = {
        distance = nil
    }
    local closestSE = {
        distance = nil
    }
    local closestSW = {
        distance = nil
    }

    local closest = {
        ne = {},
        nw = {},
        se = {},
        sw = {}
    }

    for index = 1, safehouseCount, 1 do
        local sh = safehouses:get(index - 1)
        if sh ~= fromSafehouse then

            -- do we ignore if we are a member?
            if not self.ignoreMinDistantIfMutualPlayer or
                (self.ignoreMinDistantIfMutualPlayer and self:playerIsMemberOf(sh, excludePlayerObj)) then

                local edges = self:getDistanceOfEdges(sh)
                edges.id = sh:getId()
                edges.owner = sh:getOwner()

                for sk, sv in pairs(source) do
                    local d = nil
                    for ek, ev in pairs(edges) do
                        if closest[ek] then
                            local r = getDistanceFromEdges(sv, ev)
                            if d == nil or r < d then
                                d = r
                            end

                        end

                    end
                    if closest[sk].distance == nil or d < closest[sk].distance then
                        closest[sk] = {
                            distance = d,
                            info = edges
                        }
                    end
                end
            end
        end
    end
    source.ne.closest = closest.ne
    source.nw.closest = closest.nw
    source.se.closest = closest.se
    source.sw.closest = closest.sw
    return source

end

function PhunSafePaint:getDistanceOfEdges(fromSafehouse)

    local edgeX, edgeY, edgeX2, edgeY2 = nil, nil, nil, nil

    if fromSafehouse.getX and fromSafehouse.getW then
        -- assert its a safehouse
        edgeX = fromSafehouse:getX()
        edgeX2 = fromSafehouse:getX() + fromSafehouse:getW()
        edgeY = fromSafehouse:getY()
        edgeY2 = fromSafehouse:getY() + fromSafehouse:getH()
    elseif fromSafehouse.x then
        edgeX = fromSafehouse.x
        edgeX2 = fromSafehouse.x2
        edgeY = fromSafehouse.y
        edgeY2 = fromSafehouse.y2
    end

    local edges = {
        ne = {
            x = edgeX,
            y = edgeY,
            x2 = edgeX2,
            y2 = edgeY
        },
        nw = {
            x = edgeX,
            y = edgeY,
            x2 = edgeX,
            y2 = edgeY2
        },
        se = {
            x = edgeX2,
            y = edgeY,
            x2 = edgeX2,
            y2 = edgeY2
        },
        sw = {
            x = edgeX,
            y = edgeY2,
            x2 = edgeX2,
            y2 = edgeY2
        }
    }

    return edges

end

function PhunSafePaint:replaceSafehouse(safehouse, owner, x, y, x2, y2)

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
    safehouse:removeSafeHouse(getPlayerFromUsername(ownerName))
    return self:createSafehouse(x, y, x2, y2, ownerName, players)
end

function PhunSafePaint:createSafehouse(x, y, x2, y2, ownerName, players, title, remote)

    local safeObj = SafeHouse.addSafeHouse(x, y, x2 - x, y2 - y, ownerName, remote == true);
    safeObj:setTitle(title or (tostring(x) .. "," .. tostring(y) .. ", " .. tostring(getTimestamp())));
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
