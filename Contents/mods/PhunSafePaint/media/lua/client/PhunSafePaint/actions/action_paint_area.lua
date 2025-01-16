require "TimedActions/ISBaseTimedAction"
local PP = PhunSafePaint
PhunSpawnActionPaint = ISBaseTimedAction:derive("Action_Paint_Area");
local Action = PhunSpawnActionPaint

function Action:isValid()
    -- am I in range?

    -- do I have enough paint

    -- is area valid

    return true
end

function Action:update()
    -- self.character:faceThisObject(self.computer)
end

function Action:start()
    self.sound = self.character:playSound("Painting")
end

function Action:stop()
    ISBaseTimedAction.stop(self);
end

function Action:perform()

    if isClient() then
        sendClientCommand(PP.name, PP.commands.resize, {
            owner = self.safehouse:getOwner(),
            x = self.area.x,
            y = self.area.y,
            w = self.area.x2 - self.area.x,
            h = self.area.y2 - self.area.y
        })

        for _, v in ipairs(self.boundary or {}) do
            for i = 1, (PP.settings.Consumption or 1) do
                local item = self.character:getInventory():getFirstTypeRecurse("RepellentPaint")
                item:Use()
            end
        end
    end
    self.safehouse = PhunSafePaint:resizeByOwner(self.safehouse:getOwner(), self.area.x, self.area.y,
        self.area.x2 - self.area.x, self.area.y2 - self.area.y)
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
