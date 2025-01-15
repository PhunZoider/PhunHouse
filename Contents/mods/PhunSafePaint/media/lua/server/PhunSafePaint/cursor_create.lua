require "BuildingObjects/ISBuildingObject"
PhunSafePaintCreateCursor = ISBuildingObject:derive("PhunSafePaintCreateCursor");
local Cursor = PhunSafePaintCreateCursor
local PP = PhunSafePaint

function Cursor:create(x, y, z, north, sprite)

    local sq = getWorld():getCell():getGridSquare(x, y, z)
    if self:isValid(sq) then
        local safehouse = PP:createSafehouse(self.area.x, self.area.y, self.area.x + (self.area.x2 - self.area.x),
            self.area.y + (self.area.y2 - self.area.y), self.character:getUsername())
        PP:highlightSafehouse(safehouse)
    end
end

function Cursor:walkTo(x, y, z)
    if ISBuildMenu.cheat then
        return true
    end
    local square = getCell():getGridSquare(x, y, z)
    local playerObj = self.character
    return luautils.walkAdj(playerObj, square, true)
end

function Cursor:setArea(square)
    self.renderX = square:getX()
    self.renderY = square:getY()
    self.renderZ = square:getZ()

    local a = math.floor(math.sqrt(PP.settings.MinSizeForNew or 9))
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
    self.area = area
    self.squares = PP:getSafehouseSquares(area)
    self.squareInfo = PP:squaresDistanceToNextSafehouse(self.squares, self.character)
    return self.area
end

function Cursor:isValid(square)

    if self.lastDirectionInfo and not self.lastDirectionInfo.enabled then
        return false
    end

    if not self.area then
        self:setArea(square)
    end

    local area = self.area
    if not area then
        return false
    end

    local uses = self.character:getInventory():getUsesTypeRecurse("RepellentPaint")
    return uses > #area

end

function Cursor:getDirection(x, y)
    for k, v in pairs(self.edges) do
        if x >= v.x and x <= v.x2 and y >= v.y and y <= v.y2 then
            return k, v
        end
    end
end

function Cursor:render(x, y, z, square)

    if not self.floorSprite then
        self.floorSprite = IsoSprite.new()
        self.floorSprite:LoadFramesNoDirPageSimple('media/ui/FloorTileCursor.png')
    end

    self.currentObject = nil

    local hc = getCore():getGoodHighlitedColor()
    local bc = getCore():getBadHighlitedColor()

    local area = self:setArea(square)

    local distance = PP:getEdgeDistances(area, self.character)

    local uses = self.character:getInventory():getUsesTypeRecurse("RepellentPaint")
    -- local squarez = self.squares

    for i, v in ipairs(self.squares or {}) do

        local info = self.squareInfo[i]

        if uses > 1 and info.enabled then
            self.floorSprite:RenderGhostTileColor(v:getX(), v:getY(), 0, hc:getR(), hc:getG(), hc:getB(), 0.8)
        else
            if not info.enabled then
                local text = getText("UI_PhunSafe_Err_Too_Close_To_Existing")
                HaloTextHelper.addText(self.character, text, HaloTextHelper.getColorRed())
            end
            self.floorSprite:RenderGhostTileColor(v:getX(), v:getY(), 0, bc:getR(), bc:getG(), bc:getB(), 0.8)
        end
        uses = uses - 1
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

function Cursor:deactivate()
    -- PP:safehouseRemoveHighlight()
end

function Cursor:getObjectList()
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

function Cursor:new(character)
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
    o.objectIndex = 1
    o.renderX = -1
    o.renderY = -1
    o.renderZ = -1
    return o
end

