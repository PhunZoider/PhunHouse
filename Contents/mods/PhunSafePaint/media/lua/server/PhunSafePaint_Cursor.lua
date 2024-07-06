require "BuildingObjects/ISBuildingObject"

PhunSafePaintCursor = ISBuildingObject:derive("PhunSafePaintCursor");

function PhunSafePaintCursor:create(x, y, z, north, sprite)

    local sq = getWorld():getCell():getGridSquare(x, y, z)
    if self:isValid(sq) then

        local areas = self:getArea(sq)

        for _, v in ipairs(areas) do
            local item = self.character:getInventory():getFirstTypeRecurse("RepellentPaint")
            item:Use()
        end

        if self.lastDirectionInfo and not self.lastDirectionInfo.enabled then
            return false
        end

        if not self.safehouse then
            return false
        end

        local x = self.safehouse:getX()
        local y = self.safehouse:getY()
        local x2 = self.safehouse:getX() + self.safehouse:getW()
        local y2 = self.safehouse:getY() + self.safehouse:getH()

        if self.lastDirection == "ne" then
            y = y - 1
            self.safehouse:setY(y)
            self.safehouse:setH(self.safehouse:getH() + 1)
        elseif self.lastDirection == "nw" then
            x = x - 1
            self.safehouse:setX(x)
            self.safehouse:setW(self.safehouse:getW() + 1)
        elseif self.lastDirection == "se" then
            x2 = x2 + 1
            self.safehouse:setW(self.safehouse:getW() + 1)
        elseif self.lastDirection == "sw" then
            y2 = y2 + 1
            self.safehouse:setH(self.safehouse:getH() + 1)
        end

        self.safehouse = PhunSafePaint:replaceSafehouse(self.safehouse, self.character, x, y, x2, y2)

        self:refreshSafehouse()
        PhunSafePaint:highlightSafehouse(self.safehouse)

    end
end

function PhunSafePaintCursor:walkTo(x, y, z)
    if ISBuildMenu.cheat then
        return true
    end
    local square = getCell():getGridSquare(x, y, z)
    local playerObj = self.character
    return luautils.walkAdj(playerObj, square, true)
end

function PhunSafePaintCursor:getArea(square)
    self.renderX = square:getX()
    self.renderY = square:getY()
    self.renderZ = square:getZ()

    local safehouseXyz = PhunSafePaint:getAreaOfSafehouse(self.safehouse)
    local result = nil

    if (self.renderX + 1 == safehouseXyz.x) and (self.renderY < safehouseXyz.y2) and (self.renderY >= safehouseXyz.y) then
        -- NW
        result = {}
        for i = safehouseXyz.y, safehouseXyz.y2 - 1 do
            table.insert(result, {
                x = safehouseXyz.x - 1,
                y = i
            })
        end
    elseif (self.renderX == safehouseXyz.x2) and (self.renderY < safehouseXyz.y2) and (self.renderY >= safehouseXyz.y) then
        -- SE
        result = {}
        for i = safehouseXyz.y, safehouseXyz.y2 - 1 do
            table.insert(result, {
                x = safehouseXyz.x2,
                y = i
            })
        end

    elseif (self.renderY + 1 == safehouseXyz.y) and (self.renderX >= safehouseXyz.x) and
        (self.renderX < safehouseXyz.x2) then
        -- NE
        result = {}
        for i = safehouseXyz.x, safehouseXyz.x2 - 1 do
            table.insert(result, {
                x = i,
                y = safehouseXyz.y - 1
            })
        end

    elseif (self.renderY == safehouseXyz.y2) and (self.renderX >= safehouseXyz.x) and (self.renderX < safehouseXyz.x2) then
        -- SW
        result = {}
        for i = safehouseXyz.x, safehouseXyz.x2 - 1 do
            table.insert(result, {
                x = i,
                y = safehouseXyz.y2
            })
        end
    end

    return result

end

function PhunSafePaintCursor:isValid(square)

    if self.lastDirectionInfo and not self.lastDirectionInfo.enabled then
        return false
    end

    local area = self:getArea(square)
    if not area then
        return false
    end

    local uses = self.character:getInventory():getUsesTypeRecurse("RepellentPaint")
    return uses > #area

end

function PhunSafePaintCursor:getDirection(x, y)
    for k, v in pairs(self.edges) do
        if x >= v.x and x <= v.x2 and y >= v.y and y <= v.y2 then
            return k, v
        end
    end
end

function PhunSafePaintCursor:render(x, y, z, square)

    if not self.floorSprite then
        self.floorSprite = IsoSprite.new()
        self.floorSprite:LoadFramesNoDirPageSimple('media/ui/FloorTileCursor.png')
    end

    self.currentObject = nil

    local hc = getCore():getGoodHighlitedColor()
    local bc = getCore():getBadHighlitedColor()

    local direction, directionInfo = self:getDirection(x, y)

    local lastDirection = self.lastDirection or nil
    local directionChanged = lastDirection ~= direction

    self.lastDirection = direction
    self.lastDirectionInfo = directionInfo

    local isEnabled = (directionInfo and directionInfo.enabled == true)

    local uses = self.character:getInventory():getUsesTypeRecurse("RepellentPaint")
    local squarez = self:getArea(square)
    if squarez and type(squarez) == "table" then
        for _, v in ipairs(squarez or {}) do
            if uses > 1 and isEnabled then
                self.floorSprite:RenderGhostTileColor(v.x, v.y, 0, hc:getR(), hc:getG(), hc:getB(), 0.8)
            else
                if not isEnabled and directionChanged then
                    local text = "Too close to another safehouse"
                    HaloTextHelper.addText(self.character, text, HaloTextHelper.getColorRed())

                end
                self.floorSprite:RenderGhostTileColor(v.x, v.y, 0, bc:getR(), bc:getG(), bc:getB(), 0.8)
            end
            uses = uses - 1
        end
    else
        self.floorSprite:RenderGhostTileColor(x, y, z, hc:getR(), hc:getG(), hc:getB(), 0.8)
    end

    if self.currentSquare ~= square then
        self.objectIndex = 1
        self.currentSquare = square
    end

    self.renderX = x
    self.renderY = y
    self.renderZ = z

    local objects = self:getObjectList()
    if self.objectIndex > #objects then
        self.objectIndex = #objects
    end
    if self.objectIndex >= 1 and self.objectIndex <= #objects then
        local object = objects[self.objectIndex]
        local color = {
            r = getCore():getGoodHighlitedColor():getR(),
            g = getCore():getGoodHighlitedColor():getG(),
            b = getCore():getGoodHighlitedColor():getB()
        }

        local offsetX, offsetY = 0, (object:getRenderYOffset() * Core.getTileScale())
        -- corner walls need special handling here
        if object:getSprite():getProperties():Is("CornerNorthWall") then -- if it has one, it will have the other
            if self.cornerCounter == 0 and object:getSprite():getProperties():Is("CornerNorthWall") then
                getSprite(object:getSprite():getProperties():Val("CornerNorthWall")):RenderGhostTileColor(x, y, z,
                    offsetX, offsetY, color.r, color.g, color.b, 0.8)
            elseif self.cornerCounter == 1 and object:getSprite():getProperties():Is("CornerWestWall") then
                getSprite(object:getSprite():getProperties():Val("CornerWestWall")):RenderGhostTileColor(x, y, z,
                    offsetX, offsetY, color.r, color.g, color.b, 0.8)
            end
        else
            object:getSprite():RenderGhostTileColor(x, y, z, offsetX, offsetY, color.r, color.g, color.b, 0.8)
        end

        self.currentObject = object
    end
end

function PhunSafePaintCursor:deactivate()
    PhunSafePaint:removeHighlight()
end

function PhunSafePaintCursor:getObjectList()
    local square = getCell():getGridSquare(self.renderX, self.renderY, self.renderZ)
    if not square then
        return {}
    end
    local objects = {}
    for i = square:getObjects():size(), 1, -1 do
        local destroy = square:getObjects():get(i - 1)
        table.insert(objects, destroy)
    end
    return objects
end

function PhunSafePaintCursor:refreshSafehouse()
    -- edges of safehouse
    self.edges = PhunSafePaint:getDistanceOfEdges(self.safehouse)

    -- update edges to reflect the boundary we can extend to
    self.edges.ne.x = self.edges.ne.x
    self.edges.ne.x2 = self.edges.ne.x2 - 1
    self.edges.ne.y = self.edges.ne.y - 1
    self.edges.ne.y2 = self.edges.ne.y2 - 1

    self.edges.nw.x = self.edges.nw.x - 1
    self.edges.nw.x2 = self.edges.nw.x2 - 1
    self.edges.nw.y = self.edges.nw.y
    self.edges.nw.y2 = self.edges.nw.y2 - 1

    self.edges.se.y = self.edges.se.y
    self.edges.se.y2 = self.edges.se.y2 - 1

    self.edges.sw.x = self.edges.sw.x
    self.edges.sw.x2 = self.edges.sw.x2 - 1

    -- edges of other safehouses
    local edges = PhunSafePaint:getEdgeDistances(self.safehouse, self.character)

    local results = {}
    for k, v in pairs(edges) do
        self.edges[k].enabled = true

        if v.closest then
            if v.closest.info then
                self.edges[k].closest = {
                    id = v.closest.info.id,
                    owner = v.closest.info.owner
                }
            end
            if v.closest.distance then
                if not self.edges[k].closest then
                    self.edges[k].closest = {}
                end
                self.edges[k].closest.distance = v.closest.distance
                if v.closest.distance <= (SandboxVars.PhunSafePaint_MinDistanceBetweenSafehouses or 25) then
                    self.edges[k].enabled = false
                    self.edges[k].closest.enabled = false
                end
            end
        end
    end
    PhunTools:printTable(self.edges)
end

function PhunSafePaintCursor:new(character, safehouse)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o:init()
    o.character = character
    o.player = character:getPlayerNum()
    o.skipBuildAction = true
    o.noNeedHammer = false
    o.skipWalk = false
    o.renderFloorHelper = true
    o.edges = PhunSafePaint:getDistanceOfEdges(safehouse)

    -- update edges to 
    o.edges.ne.x = o.edges.ne.x + 1
    o.edges.ne.x2 = o.edges.ne.x2 + 1

    o.edges.nw.y = o.edges.nw.y + 1
    o.edges.nw.y2 = o.edges.nw.y2 + 1

    o.edges.se.y = o.edges.se.y - 1
    o.edges.se.y2 = o.edges.se.y2 - 1

    o.edges.sw.x = o.edges.sw.x - 1
    o.edges.sw.x2 = o.edges.sw.x2 - 1

    o.safehouse = safehouse
    o.objectIndex = 1
    o.renderX = -1
    o.renderY = -1
    o.renderZ = -1
    o:refreshSafehouse()
    return o
end

