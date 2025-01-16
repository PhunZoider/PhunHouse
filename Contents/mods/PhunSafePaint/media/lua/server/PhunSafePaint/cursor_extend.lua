require "BuildingObjects/ISBuildingObject"
local PP = PhunSafePaint
PhunSafePaintCursor = ISBuildingObject:derive("PhunSafePaintCursor");
local Cursor = PhunSafePaintCursor

function Cursor:getBoundary(x, y)

    if x >= self.safehouse:getX2() then
        -- assert we are growing to the right
        return self.boundaries.right
    elseif x <= self.safehouse:getX() then
        -- assert we are growing to the left
        return self.boundaries.left
    elseif y >= self.safehouse:getY2() then
        -- assert we are growing to the bottom
        return self.boundaries.bottom
    elseif y <= self.safehouse:getY() then
        -- assert we are growing to the top
        return self.boundaries.top
    end
end

function Cursor:walkTo(x, y, z)

    local square = getSquare(x, y, z or 0)
    local boundary = self:getBoundary(x, y)
    local area = {
        x = self.safehouse:getX(),
        y = self.safehouse:getY(),
        x2 = self.safehouse:getX2(),
        y2 = self.safehouse:getY2()
    }

    if square:getX() >= self.safehouse:getX2() then
        -- assert we are growing to the right
        area.x2 = area.x2 + 1
    elseif square:getX() <= self.safehouse:getX() then
        -- assert we are growing to the left
        area.x = area.x - 1
    elseif square:getY() >= self.safehouse:getY2() then
        -- assert we are growing to the bottom
        area.y2 = area.y2 + 1
    elseif square:getY() <= self.safehouse:getY() then
        -- assert we are growing to the top
        area.y = area.y - 1
    end

    -- walk to the square
    ISTimedActionQueue.add(ISWalkToTimedAction:new(self.character, square))

    -- paint the area
    ISTimedActionQueue.add(PhunSpawnActionPaint:new(self.character, area, self.safehouse, boundary, function()
        self:refreshSafehouse()
    end, 20))
end

function Cursor:isValid(square)

    local boundary = self:getBoundary(square:getX(), square:getY())
    local boundaryValid = boundary and PP.isValidArea(self.character, boundary)
    return boundaryValid and boundary and #boundary > 0

end

function Cursor:render(x, y, z, square)

    if not self.floorSprite then
        self.floorSprite = IsoSprite.new()
        self.floorSprite:LoadFramesNoDirPageSimple('media/ui/FloorTileCursor.png')
    end

    local boundary = self:getBoundary(x, y)

    if not boundary then
        return
    end

    local uses = self.character:getInventory():getUsesTypeRecurse("SafetyPaint") or 0
    local max = PP.settings.MaxTotalArea > 0 and (PP.settings.MaxTotalArea - self.size) or nil
    local tooClose = false
    local blockedZone = false

    for _, v in ipairs(boundary) do
        if uses > 0 and (max == nil or max) > 0 and v.enabled then
            self.floorSprite:RenderGhostTileColor(v.x, v.y, 0, self.goodColor:getR(), self.goodColor:getG(),
                self.goodColor:getB(), 0.8)
        else
            self.floorSprite:RenderGhostTileColor(v.x, v.y, 0, self.badColor:getR(), self.badColor:getG(),
                self.badColor:getB(), 0.8)
            if not tooClose and v.errDistance then
                tooClose = true
            end
            if not blockedZone and v.errZoneSafehouse then
                blockedZone = true
            end
        end
        uses = uses - (PP.settings.Consumption or 1)
        if max ~= nil then
            max = max - 1
        end
    end

    if uses < 0 then
        HaloTextHelper.addText(self.character, getText("UI_PhunSafe_Err_Insufficinet_Paint"),
            HaloTextHelper.getColorRed())
    end
    if max < 0 then
        HaloTextHelper.addText(self.character, getText("UI_PhunSafe_Err_Max_Size"), HaloTextHelper.getColorRed())
    end
    if tooClose then
        HaloTextHelper.addText(self.character, getText("UI_PhunSafe_Err_Too_Close_To_Existing"),
            HaloTextHelper.getColorRed())
    end
    if blockedZone then
        HaloTextHelper.addText(self.character, getText("UI_PhunSafe_Err_Blocked"), HaloTextHelper.getColorRed())
    end

end

function Cursor:refreshSafehouse()
    self.boundaries = PP.getExtArea(self.safehouse)
    local squares = PP.getSafehouseSquares(self.safehouse)
    self.size = #squares
end

function Cursor:new(character, safehouse)
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

    o.boundaries = PP.getExtArea(safehouse)
    o.goodColor = getCore():getGoodHighlitedColor()
    o.badColor = getCore():getBadHighlitedColor()
    o.safehouse = safehouse
    local squares = PP.getSafehouseSquares(safehouse)
    o.size = #squares

    o.objectIndex = 1
    o.renderX = -1
    o.renderY = -1
    o.renderZ = -1
    o:refreshSafehouse()
    return o
end

