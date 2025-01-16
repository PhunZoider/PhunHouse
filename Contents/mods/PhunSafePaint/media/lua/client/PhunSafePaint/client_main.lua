if isServer() then
    return
end

local PP = PhunSafePaint

function PP:highlightSafehouse(safehouse)
    self:safehouseRemoveHighlight(safehouse)
    self.safehouse = safehouse
    self.isHighlighted = true
    self.highlightedArea = {
        x = safehouse:getX(),
        y = safehouse:getY(),
        x2 = safehouse:getX() + safehouse:getW(),
        y2 = safehouse:getY() + safehouse:getH()
    }
    local squares = self:getSafehouseSquares(safehouse)

    local c = {
        a = 0.5,
        r = 1,
        g = 0,
        b = 0
    };
    for _, square in ipairs(squares) do
        local objects = square:getObjects();
        for j = 0, objects:size() - 1 do
            local obj = objects:get(j);
            obj:setHighlighted(true, false);
            obj:setHighlightColor(c.r, c.g, c.b, c.a);
        end
    end

end

function PP:xyzToSquares(xyzs)
    local squares = ArrayList.new();
    for _, xyz in ipairs(xyzs or {}) do
        local square = getSquare(xyz.x, xyz.y, xyz.z or 0)
        if square then
            squares:add(square);
        end
    end
    return squares;
end

function PP:removeHighlightedArea(xyzs)
    local squares = self:xyzToSquares(xyzs);
    if squares:size() > 0 then
        self:removeHighlightedSquares(squares);
    end
end

function PP:boxToSquares(x1, x2, y1, y2)
    local area = {}

    for i = x1, x2 do
        for j = y1, y2 do
            table.insert(area, getSquare(i, j, 0))
        end
    end

    return area

end

function PP:safehouseRemoveHighlight(safehouse)

    local area = {
        x = safehouse:getX(),
        y = safehouse:getY(),
        x2 = safehouse:getX() + safehouse:getW(),
        y2 = safehouse:getY() + safehouse:getH()
    }
    local squares = self:boxToSquares(area.x, area.x2, area.y, area.y2)
    for _, square in ipairs(squares) do
        local objects = square:getObjects();
        for j = 0, objects:size() - 1 do
            local obj = objects:get(j);
            obj:setHighlighted(false, false);
        end
    end
end

function PP:highlightClosestSafehouse(playerObj, remove)
    local safehouse = self:getClosestPlayerSafehouse(playerObj)
    if safehouse then
        self:highlightSafehouse(safehouse, remove)
    end
end

function PP:playerHasEnoughPaintForBoundary(playerObj, boundary)
    local uses = playerObj:getInventory():getUsesTypeRecurse("RepellentPaint") or 0
    for _, v in ipairs(boundary or {}) do
        uses = uses - (PP.settings.Consumption or 1)
    end
    return uses >= 0
end

function PP:boundaryIsValid(playerObj, boundary)
    local uses = playerObj:getInventory():getUsesTypeRecurse("RepellentPaint") or 0

    local tooClose = false
    local blockedZone = false

    for _, v in ipairs(boundary) do
        if not v.enabled then
            return false
        end
        if uses <= 0 then
            return false
        end
        if v.errDistance then
            return false
        end
        if v.errZoneSafehouse then
            return false
        end
        uses = uses - (PP.settings.Consumption or 1)
    end
    return true
end
