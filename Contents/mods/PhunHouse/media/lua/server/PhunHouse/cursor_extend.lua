require "BuildingObjects/ISBuildingObject"
local Core = PhunHouse
PhunHouseCursor = ISBuildingObject:derive("PhunHouseCursor");
local Cursor = PhunHouseCursor

function Cursor:create(x, y, z, north, sprite)
    local boundary = self:getBoundary(x, y)
    local square = getSquare(x, y, z or 0)
    local boundary = self:getBoundary(x, y)
    self.area = {
        x = self.safehouse:getX(),
        y = self.safehouse:getY(),
        x2 = self.safehouse:getX2(),
        y2 = self.safehouse:getY2()
    }

    if square:getX() >= self.safehouse:getX2() then
        -- assert we are growing to the right
        self.area.x2 = self.area.x2 + 1
    elseif square:getX() <= self.safehouse:getX() then
        -- assert we are growing to the left
        self.area.x = self.area.x - 1
    elseif square:getY() >= self.safehouse:getY2() then
        -- assert we are growing to the bottom
        self.area.y2 = self.area.y2 + 1
    elseif square:getY() <= self.safehouse:getY() then
        -- assert we are growing to the top
        self.area.y = self.area.y - 1
    end

    if isClient() then
        sendClientCommand(Core.name, Core.commands.resize, {
            owner = self.safehouse:getOwner(),
            x = self.area.x,
            y = self.area.y,
            w = self.area.x2 - self.area.x,
            h = self.area.y2 - self.area.y
        })
        Core.consume(self.character, self.area)
    end

    self.safehouse = Core.resizeByOwner(self.safehouse:getOwner(), self.area.x, self.area.y, self.area.x2 - self.area.x,
        self.area.y2 - self.area.y)

    Core.consume(self.character, boundary)
    self:refreshSafehouse()
    getWorld():getCell():setDrag(nil, 0);
end

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
    self.area = {
        x = self.safehouse:getX(),
        y = self.safehouse:getY(),
        x2 = self.safehouse:getX2(),
        y2 = self.safehouse:getY2()
    }

    if square:getX() >= self.safehouse:getX2() then
        -- assert we are growing to the right
        self.area.x2 = self.area.x2 + 1
    elseif square:getX() <= self.safehouse:getX() then
        -- assert we are growing to the left
        self.area.x = self.area.x - 1
    elseif square:getY() >= self.safehouse:getY2() then
        -- assert we are growing to the bottom
        self.area.y2 = self.area.y2 + 1
    elseif square:getY() <= self.safehouse:getY() then
        -- assert we are growing to the top
        self.area.y = self.area.y - 1
    end

    -- walk to the square
    ISTimedActionQueue.add(ISWalkToTimedAction:new(self.character, square))
    ISTimedActionQueue.add(PhunSpawnActionCreate:new(self.character, self.area, 20))
    -- paint the area
    -- ISTimedActionQueue.add(PhunSpawnActionPaint:new(self.character, area, self.safehouse, boundary, function()
    --     self:refreshSafehouse()
    -- end, 20))
end

function Cursor:isValid(square)

    local boundary = self:getBoundary(square:getX(), square:getY())
    local boundaryValid = boundary and Core.isValidArea(self.character, boundary)
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

    local uses = self.character:getInventory():getUsesTypeRecurse("HousePaint") or 0
    local max = Core.settings.MaxTotalArea > 0 and (Core.settings.MaxTotalArea - self.size) or nil
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
        uses = uses - (Core.settings.Consumption or 1)
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
    self.boundaries = Core.getExtArea(self.safehouse)
    local squares = Core.getSafehouseSquares(self.safehouse)
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

    o.boundaries = Core.getExtArea(safehouse)
    o.goodColor = getCore():getGoodHighlitedColor()
    o.badColor = getCore():getBadHighlitedColor()
    o.safehouse = safehouse
    local squares = Core.getSafehouseSquares(safehouse)
    o.size = #squares

    o.objectIndex = 1
    o.renderX = -1
    o.renderY = -1
    o.renderZ = -1
    o:refreshSafehouse()
    return o
end

