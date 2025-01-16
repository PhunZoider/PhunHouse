require "TimedActions/ISBaseTimedAction"
local PP = PhunSafePaint
PhunSpawnActionCreate = ISBaseTimedAction:derive("PhunSpawnActionCreate");
local Action = PhunSpawnActionCreate

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
    PP.create(self.area.x, self.area.y, self.area.x2, self.area.y2, self.character:getUsername())
    PP.consume(self.character, self.area)
    ISBaseTimedAction.perform(self);
end

function Action:new(player, area, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.player = player:getPlayerNum();
    o.character = player
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = time;
    o.area = area
    if ISBuildMenu.cheat then
        o.maxTime = 1;
    end
    o.caloriesModifier = 4;
    return o;
end
