require "TimedActions/ISBaseTimedAction"
local Core = PhunHouse
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
