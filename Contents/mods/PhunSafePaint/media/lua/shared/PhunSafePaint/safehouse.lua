require "PhunSafePaint/core"
local Core = PhunSafePaint

-- Function to clamp a value within a range
local function clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end

function Core:getSafehouseByOwner(owner)

    local name = owner and type(owner) == "string" and owner or owner:getUsername()

    local safehouses = SafeHouse:getSafehouseList()
    local safehouseCount = safehouses:size()

    if safehouseCount == 0 then
        return nil
    end

    local houses = {}

    for index = 1, safehouseCount, 1 do
        local safehouse = safehouses:get(index - 1)
        if safehouse:getOwner() == name then
            return safehouse
        end
    end

end

function Core:getPlayerSafehouses(playerObj)

    local safehouses = SafeHouse:getSafehouseList()
    local safehouseCount = safehouses:size()

    if safehouseCount == 0 then
        return nil
    end

    local houses = {}

    for index = 1, safehouseCount, 1 do

        local safehouse = safehouses:get(index - 1)
        if self:canIgnore() then
            table.insert(houses, safehouse)
        elseif self:playerIsMemberOf(safehouse, playerObj) then
            table.insert(houses, safehouse)
        elseif safehouse:getOwner() == playerObj:getUsername() then
            table.insert(houses, safehouse)
        end
    end
    return houses
end

function Core:resizeByOwner(owner, x, y, w, h)

    local house = self:getSafehouseByOwner(owner)
    if house then
        return self:resize(house, x, y, w, h)
    end

end

function Core:resize(safehouse, x, y, w, h)

    safehouse:setX(x)
    safehouse:setY(y)
    safehouse:setW(w)
    safehouse:setH(h)
    safehouse:syncSafehouse();
    triggerEvent("OnSafehousesChanged")
    return safehouse

end

function Core:canCreateHere(playerObj, x, y)

    if self:canIgnore() then
        return true
    elseif self.settings.MinSizeForNew > 0 then
        local existing = self:getPlayerSafehouses(playerObj)
        return not existing or #existing == 0
    end
    return false
end

function Core:canExtendHere(playerObj, x, y, variance)

    local data = self:getClosestPlayerSafehouseDistance(playerObj)

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

    return false
end

function Core:getClosestPlayerSafehouse(playerObj)
    local closest = self:getClosestPlayerSafehouseDistance(playerObj)
    if closest then
        return closest.safehouse
    end
end

function Core:getClosestSafehouseTo(x, y)
    local safehouses = SafeHouse:getSafehouseList()
    local safehouseCount = safehouses:size()
    local closest = nil
    local minDistance = nil
    for index = 1, safehouseCount, 1 do
        local sh = safehouses:get(index - 1)
        if x > sh:getX() and x < sh:getX() + sh:getW() and y > sh:getY() and y < sh:getY() + sh:getH() then
            -- player is within the safehouse
            return sh
        end
        local distance = self:getDistanceOfSafehouse(x, y, sh)
        if not minDistance or distance < minDistance then
            minDistance = distance
            closest = sh
        end
    end
    return closest
end

function Core:getClosestPlayerSafehouseDistance(playerObj)
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

function Core:playerIsMemberOf(safehouse, playerObj)
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

function Core:getAreaOfSafehouse(safehouse)
    if safehouse and safehouse.getX then
        return {
            x = safehouse:getX(),
            y = safehouse:getY(),
            x2 = safehouse:getX() + safehouse:getW(),
            y2 = safehouse:getY() + safehouse:getH()
        }
    elseif safehouse.x2 then
        -- assert its coords
        local a = math.floor(math.sqrt(self.settings.MinSizeForNew or 9))
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

function Core:getSafehouseSquares(safehouse)
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

function Core:squaresDistanceToNextSafehouse(squares, excludePlayerObj, excludeSafehouse)

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
                enabled = distance > (self.settings.MinDistanceBetweenSafehouses or 25)
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

function Core:squareDistanceToNextSafehouse(square, excludePlayerObj, excludeSafehouse)
    return self:distanceToNextSafehouse(square:getX(), square:getY(), excludePlayerObj, excludeSafehouse)
end

function Core:distanceToNextSafehouse(x, y, excludePlayerObj, excludeSafehouse)

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

local zones = nil

function Core:processBoundary(safehouse, face)
    if zones == nil then
        if PhunZones then
            zones = PhunZones or false
        end
    end
    for j, v in ipairs(face) do
        local distance = math.floor(self:getDistanceOfSafehouse(v.x, v.y, safehouse))
        if not v.distance then
            v.distance = distance
        elseif v.distance < distance then
            v.distance = distance
        end
        if v.enabled == nil then
            v.enabled = true
        end
        if v.distance > 0 and v.distance <= self.settings.MinDistanceBetweenSafehouses then
            v.enabled = false
        end
        if zones and zones:getLocation(v.x, v.y).safehouse == false then
            v.enabled = false
            v.errZoneSafehouse = true
        end
    end
end

function Core:getBoundaryInformation(area)

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
            self:processBoundary(sh, v)
        end

    end
    return results

end

function Core:getExtensionBoundaryInformation(safehouse)

    local x, y, x2, y2 = safehouse:getX(), safehouse:getY(), safehouse:getX2(), safehouse:getY2()
    -- local area = self:getAreaOfSafehouse(safehouse)
    -- expand boundary by 1
    -- area.x = area.x - 1
    -- area.y = area.y - 1
    -- area.x2 = area.x2 + 1
    -- area.y2 = area.y2 + 1
    local area = {
        x = x - 1,
        y = y - 1,
        x2 = x2,
        y2 = y2
    }
    return self:getBoundaryInformation(area)

end

function Core:getEdgeDistances(fromSafehouse, excludePlayerObj)

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

function Core:getClosestPoint(x, y, x1, y1, x2, y2)

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

function Core:getDistanceOfSafehouse(x, y, safehouse)
    if x > safehouse:getX() and x < safehouse:getX() + safehouse:getW() and y > safehouse:getY() and y <
        safehouse:getY() + safehouse:getH() then
        -- player is within the safehouse
        return -1
    end

    return self:getClosestPoint(x, y, safehouse:getX(), safehouse:getY(), safehouse:getX() + safehouse:getW(),
        safehouse:getY() + safehouse:getH())

end

function Core:getDistanceFromPlayer(safehouse, player)
    return self:getDistanceOfSafehouse(player:getX(), player:getY(), safehouse)
end

function Core:getDistanceOfEdges(fromSafehouse)

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
