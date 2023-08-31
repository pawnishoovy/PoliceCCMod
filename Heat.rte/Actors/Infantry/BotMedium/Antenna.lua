

function Create(self)
	self.wireStartPoint = Vector(-6,-3)
	self.wireEndPoint = Vector(-6,-18)
	self.wireLengthMax = 15
	
	self.wirePointPosX = self.Pos.X
	self.wirePointPosY = self.Pos.Y
	
	self.wirePointVelX = 0
	self.wirePointVelY = 0
	
	self.color = 55
end

function Update(self)
	local posA = Vector(self.Pos.X, self.Pos.Y) + Vector(self.wireStartPoint.X * self.FlipFactor, self.wireStartPoint.Y):RadRotate(self.RotAngle)
	local posB = Vector(self.Pos.X, self.Pos.Y) + Vector(self.wireEndPoint.X * self.FlipFactor, self.wireEndPoint.Y):RadRotate(self.RotAngle)
	--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + self.wirePointA, 5);
	--PrimitiveMan:DrawLinePrimitive(posA, posB, 5);
	-- Physics
	local v = Vector(self.wirePointVelX, self.wirePointVelY) - SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs * 0.3 -- Gravity
	
	-- Pull the point to wire Stat and End points
	for i, point in ipairs({self.wireStartPoint, self.wireEndPoint}) do
		point = Vector(self.Pos.X, self.Pos.Y) + Vector(point.X * self.FlipFactor, point.Y):RadRotate(self.RotAngle)
		local dif = SceneMan:ShortestDistance(Vector(self.wirePointPosX, self.wirePointPosY), point,SceneMan.SceneWrapsX)
		v = v + dif * math.min(math.max((dif.Magnitude / 5) - 1, 0), 6) * TimerMan.DeltaTimeSecs * 15
	end
	
	v = v / (1 + TimerMan.DeltaTimeSecs * 6.0) -- Air Friction
	
	self.wirePointVelX = v.X
	self.wirePointVelY = v.Y
	
	self.wirePointPosX = self.wirePointPosX + self.wirePointVelX * rte.PxTravelledPerFrame
	self.wirePointPosY = self.wirePointPosY + self.wirePointVelY * rte.PxTravelledPerFrame
	
	-- Limit Position
	local posCenter = (posA + posB) * 0.5
	local newPos = SceneMan:ShortestDistance(posCenter, Vector(self.wirePointPosX, self.wirePointPosY), SceneMan.SceneWrapsX)
	newPos = posCenter + newPos:SetMagnitude(math.min(newPos.Magnitude, self.wireLengthMax))
	self.wirePointPosX = newPos.X
	self.wirePointPosY = newPos.Y
	
	-- DEBUG
	--PrimitiveMan:DrawLinePrimitive(posA, posA, 13);
	--PrimitiveMan:DrawLinePrimitive(posB, posB, 13);
	local pos = Vector(self.wirePointPosX, self.wirePointPosY)
	--PrimitiveMan:DrawLinePrimitive(pos, pos + SceneMan:ShortestDistance(pos,posA,SceneMan.SceneWrapsX), 5);
	--PrimitiveMan:DrawLinePrimitive(pos, pos + SceneMan:ShortestDistance(pos,posB,SceneMan.SceneWrapsX), 5);
	
	local maxi = 3
	local pointLast = Vector(0,0)
	for i = 0, maxi do
		local fac = i / maxi
		local p1 =  posA - self.Pos
		local p2 =  posA - self.Pos + Vector(0,-3):RadRotate(self.RotAngle)
		local p3 =  pos - self.Pos
		
		local point = p1 * math.pow(1 - fac, 2) + p2 * 2 * (1 - fac) * fac + p3 * math.pow(fac, 2)
		
		--PrimitiveMan:DrawLinePrimitive(self.Pos + p1, self.Pos + p2, 13)
		--PrimitiveMan:DrawLinePrimitive(self.Pos + p3, self.Pos + p2, 13)
		if i > 0 then
			PrimitiveMan:DrawLinePrimitive(self.Pos + point, self.Pos + pointLast, self.color)
		end
		pointLast = point
		
		--PrimitiveMan:DrawCirclePrimitive(self.Pos + p1, 1, 13);
		--PrimitiveMan:DrawCirclePrimitive(self.Pos + p2, 1, 13);
		--PrimitiveMan:DrawCirclePrimitive(self.Pos + p3, 1, 13);
	end
	
	-- Simple fix for scene wrapping
	
	if SceneMan.SceneWrapsX then
		if self.wirePointPosX > SceneMan.SceneWidth then
			self.wirePointPosX = self.wirePointPosX - SceneMan.SceneWidth
		elseif self.wirePointPosX < 0 then
			self.wirePointPosX = self.wirePointPosX + SceneMan.SceneWidth
		end
	end
	
	-- what the fuck?
	-- explanation: without this... thing, this script is the most demanding script in the game
	-- with it, it's not even a blip on the radar
	-- thanks luajit
	
	return
	
	if SceneMan.SceneWrapsX then
		if self.wirePointPosX > SceneMan.SceneWidth then
			self.wirePointPosX = self.wirePointPosX - SceneMan.SceneWidth
		elseif self.wirePointPosX < 0 then
			self.wirePointPosX = self.wirePointPosX + SceneMan.SceneWidth
		end
	end
end 