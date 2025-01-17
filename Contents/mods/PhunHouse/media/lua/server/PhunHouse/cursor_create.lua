require "BuildingObjects/ISBuildingObject"
PhunHouseCreateCursor = ISBuildingObject:derive("PhunHouseCreateCursor");
local Cursor = PhunHouseCreateCursor
local Core = PhunHouse

function Cursor:create(x, y, z, north, sprite)

    local house = Core.create(self.area.x, self.area.y, self.area.x2, self.area.y2, self.character:getUsername())
    Core.highlight(house, self.character)
    Core.consume(self.character, self.area)
    getWorld():getCell():setDrag(nil, 0);
end

function Cursor:walkTo(x, y, z)

    local square = getSquare(x, y, z or 0)

    -- walk to the square
    ISTimedActionQueue.add(ISWalkToTimedAction:new(self.character, square))

    -- paint the area
    ISTimedActionQueue.add(PhunSpawnActionCreate:new(self.character, self.area, 20))
end

function Cursor:setArea(square)
    self.renderX = square:getX()
    self.renderY = square:getY()
    self.renderZ = square:getZ()

    local a = math.floor(math.sqrt(Core.settings.MinSizeForNew or 9))
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

    self.areas = {}
    for i = area.x, area.x2 - 1 do
        for j = area.y, area.y2 - 1 do
            table.insert(self.areas, {
                x = i,
                y = j,
                enabled = true
            })
        end
    end

    local safehouses = SafeHouse:getSafehouseList()
    for i = 1, safehouses:size(), 1 do

        local sh = safehouses:get(i - 1)

        Core.validateAreas(sh, self.areas)

    end
    return self.area
end

function Cursor:isValid(square)

    if not self.area or not self.areas or #self.areas < 0 then
        return false
    end
    return Core.isValidArea(self.character, self.areas)

end

function Cursor:render(x, y, z, square)

    if not self.floorSprite then
        self.floorSprite = IsoSprite.new()
        self.floorSprite:LoadFramesNoDirPageSimple('media/ui/FloorTileCursor.png')
    end

    local area = self:setArea(square)

    local uses = self.character:getInventory():getUsesTypeRecurse("HousePaint")

    local tooClose = false
    local blockedZone = false
    for i, v in ipairs(self.areas or {}) do

        if uses > 1 and v.enabled then
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
    end

    if uses < 0 then
        HaloTextHelper.addText(self.character, "Insufficient paint", HaloTextHelper.getColorRed())
    end
    if tooClose then
        HaloTextHelper.addText(self.character, getText("UI_PhunSafe_Err_Too_Close_To_Existing"),
            HaloTextHelper.getColorRed())
    end
    if blockedZone then
        HaloTextHelper.addText(self.character, getText("UI_PhunSafe_Err_Blocked"), HaloTextHelper.getColorRed())
    end

end

function Cursor:new(character)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o:init()
    o.goodColor = getCore():getGoodHighlitedColor()
    o.badColor = getCore():getBadHighlitedColor()
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

