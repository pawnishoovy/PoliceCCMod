function Create(self)

	-- detect indoors/outdoors, weaken range if outdoors
	--[[
	local outdoorRays = 0;	
	local indoorRays = 0;

	local Vector2 = Vector(0,-700); -- straight up
	local Vector2Left = Vector(0,-700):RadRotate(45*(math.pi/180));
	local Vector2Right = Vector(0,-700):RadRotate(-45*(math.pi/180));			
	local Vector2SlightLeft = Vector(0,-700):RadRotate(22.5*(math.pi/180));
	local Vector2SlightRight = Vector(0,-700):RadRotate(-22.5*(math.pi/180));		
	local Vector3 = Vector(0,0); -- dont need this but is needed as an arg
	local Vector4 = Vector(0,0); -- dont need this but is needed as an arg

	self.ray = SceneMan:CastObstacleRay(self.Pos, Vector2, Vector3, Vector4, self.RootID, self.Team, 128, 7);
	self.rayRight = SceneMan:CastObstacleRay(self.Pos, Vector2Right, Vector3, Vector4, self.RootID, self.Team, 128, 7);
	self.rayLeft = SceneMan:CastObstacleRay(self.Pos, Vector2Left, Vector3, Vector4, self.RootID, self.Team, 128, 7);			
	self.raySlightRight = SceneMan:CastObstacleRay(self.Pos, Vector2SlightRight, Vector3, Vector4, self.RootID, self.Team, 128, 7);
	self.raySlightLeft = SceneMan:CastObstacleRay(self.Pos, Vector2SlightLeft, Vector3, Vector4, self.RootID, self.Team, 128, 7);
	
	self.rayTable = {self.ray, self.rayRight, self.rayLeft, self.raySlightRight, self.raySlightLeft};

	for _, rayLength in ipairs(self.rayTable) do
		if rayLength < 0 then
			outdoorRays = outdoorRays + 1;
		else
			indoorRays = indoorRays + 1;
		end
	end
	
	if outdoorRays > indoorRays then
		self.range = 2.5 * self.Vel.Magnitude;
		self.Outdoors = true;
	else
		self.range = 5 * self.Vel.Magnitude;
	end]]
	self.range = 2.5 * self.Vel.Magnitude;
	self.strength = self.Mass * self.Vel.Magnitude;
	
	local maxi = 1	
	
	self.flash = true
	self.flashedActors = {}
end
function Update(self)
	--PrimitiveMan:DrawCirclePrimitive(self.Pos, self.range, 5)
	
	-- Run the effect on Update() to give other particles a chance to reach the target
	if self.flash then
		for actor in MovableMan.Actors do
			if actor.Team ~= self.Team then
				local dist = SceneMan:ShortestDistance(self.Pos, actor.Pos, SceneMan.SceneWrapsX);
				
				local distHead = nil
				if actor.Head then
					distHead = SceneMan:ShortestDistance(self.Pos, actor.Pos, SceneMan.SceneWrapsX);
				end
				if dist.Magnitude < self.range then
					
					local canFlash = false
					if SceneMan:CastStrengthSumRay(self.Pos, self.Pos + dist, 3, 0) < self.strength then
						canFlash = true
					elseif distHead and SceneMan:CastStrengthSumRay(self.Pos, self.Pos + distHead, 3, 0) < self.strength then
						canFlash = true
					end
					
					if canFlash and actor.ClassName ~= "ADoor" and actor.ClassName ~= "ACraft" then
						if actor.Status == 0 and IsAHuman(actor) then
							actor.Status = 1
						end
						if not self.Outdoors then -- only drop gun if we are indoors
							if math.random(1,3) < 2 and actor:GetController() then
								actor:GetController():SetState(Controller.WEAPON_DROP,true)
							end
						end
						actor:SetNumberValue("Flashed", 1)
						
						table.insert(self.flashedActors, actor.UniqueID)
					end
				end
			end
		end
		
		self.flash = false
	end
	for i, ID in ipairs(self.flashedActors) do
		local actor = ToActor(MovableMan:FindObjectByUniqueID(ID))
		if actor then
			actor = ToActor(actor)
			if actor.Status == 0 and IsAHuman(actor) then
				actor.Status = 1
			end
			local ctrl = actor:GetController()
			if ctrl then
				ctrl:SetState(Controller.WEAPON_FIRE,false)
				ctrl:SetState(Controller.AIM_SHARP,false)
				ctrl:SetState(Controller.MOVE_LEFT,false);
				ctrl:SetState(Controller.MOVE_RIGHT,false);
			end
		end
	end
	--self.ToDelete = true;
end