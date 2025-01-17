require "TimedActions/ISBaseTimedAction"
local PP = PhunHouse
PhunSpawnActionPaint = ISBaseTimedAction:derive("Action_Paint_Area");
local Action = PhunSpawnActionPaint

function Action:isValid()
    return true
end

function Action:waitToStart()
    self.character:faceThisObject(self.thumpable)
    return self.character:shouldBeTurning()
end

function Action:update()
    self.character:faceThisObject(self.thumpable)
    self.character:setMetabolicTarget(Metabolics.LightWork);
end

function Action:stop()
    if self.sound then
        self.character:stopOrTriggerSound(self.sound)
    end
    ISBaseTimedAction.stop(self);
end

function Action:start()
    self:setActionAnim(CharacterActionAnims.Paint)
    self:setOverrideHandModels("PaintBrush", nil)
    self.character:faceThisObject(self.thumpable)
    self.sound = self.character:playSound("Painting")
end

function Action:perform()

    if self.sound then
        self.character:stopOrTriggerSound(self.sound)
    end
    if not isServer() then
        sendClientCommand(PP.name, PP.commands.resize, {
            owner = self.safehouse:getOwner(),
            x = self.area.x,
            y = self.area.y,
            w = self.area.x2 - self.area.x,
            h = self.area.y2 - self.area.y
        })
        PP.consume(self.character, self.area)
    end
    self.safehouse = PP.resizeByOwner(self.safehouse:getOwner(), self.area.x, self.area.y, self.area.x2 - self.area.x,
        self.area.y2 - self.area.y)
    -- self:refreshSafehouse()
    if self.refreshCallback then
        self.refreshCallback()
    end
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function Action:new(player, area, safehouse, boundary, refreshCallback, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.refreshCallback = refreshCallback
    o.boundary = boundary
    o.player = player:getPlayerNum();
    o.character = player
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = time;
    o.area = area
    o.safehouse = safehouse
    return o;
end
