function WantedLevelScript:CalculateSectors(spacing, heightDifferenceTolerance, minimumSize)
	-- Calculate suitable landing spots
	self.terrainPointSpacing = spacing or 16
	self.terrainPointAmout = math.floor(SceneMan.SceneWidth / self.terrainPointSpacing)
	self.terrainPointHeightDifferenceTolerance = heightDifferenceTolerance or 16
	
	self.terrainPointTable = {}
	
	-- Add all points
	for i = 0, self.terrainPointAmout do
		table.insert(self.terrainPointTable, SceneMan:MovePointToGround(Vector(self.terrainPointSpacing * i, 100), 0, 0))
	end
	
	-- Calculate Sectors
	self.sectorTable = {}
	self.sectorMinimumSize = (minimumSize or 2)
	 
	local temporarySectorPoints = {}
	for i, point in ipairs(self.terrainPointTable) do
		local edge = (i == 1 or i == #self.terrainPointTable)
		local neighbourLeft = nil
		local neighbourRight = nil
		
		if i == 1 then
			neighbourLeft = self.terrainPointTable[#self.terrainPointTable]
		else
			neighbourLeft = self.terrainPointTable[i - 1]
		end
		
		if i == #self.terrainPointTable then
			neighbourRight = self.terrainPointTable[1]
		else
			neighbourRight = self.terrainPointTable[i + 1]
		end
		
		local difLeft = SceneMan:ShortestDistance(point, neighbourLeft,SceneMan.SceneWrapsX)
		local difRight = SceneMan:ShortestDistance(point, neighbourRight,SceneMan.SceneWrapsX)
		
		local edgeLeft = math.abs(difLeft.Y) < self.terrainPointHeightDifferenceTolerance
		local edgeRight = math.abs(difRight.Y) < self.terrainPointHeightDifferenceTolerance
		
		-- Is left edge -> start sector
		-- Is right edge -> end sector
		-- Is right and left edge -> !unusable!
		if (edgeLeft or edgeRight) then
			if not edgeRight or edge then
				table.insert(temporarySectorPoints, point)
				
				if #temporarySectorPoints > self.sectorMinimumSize then
					local sector = {}
					local vectorStart = temporarySectorPoints[1]
					local vectorEnd = temporarySectorPoints[#temporarySectorPoints]
					
					sector.Start = Vector(vectorStart.X, vectorStart.Y)
					sector.End = Vector(vectorEnd.X, vectorEnd.Y)
					
					table.insert(self.sectorTable, sector)
				end
				
				temporarySectorPoints = {}
			else
				table.insert(temporarySectorPoints, point)
			end
		end
		
	end
end

function WantedLevelScript:PickSector(minimumSize)
	if #self.sectorTable > 0 then
		local sectorPool = {}
		for i, sector in ipairs(self.sectorTable) do
			local size = math.abs(SceneMan:ShortestDistance(sector.Start, sector.End,SceneMan.SceneWrapsX).X)
			if size > minimumSize then
				table.insert(sectorPool, sector)
			end
		end
		
		if #sectorPool > 0 then
			return sectorPool[math.random(1, #sectorPool)]
		else
			return nil
		end
	else
		print("ERROR: THERE ARE NO SECTORS, CALCULATE THEM FIRST YOU MORON") -- :-)
		print("OR THE MAP IS JUST RETARDED, CONSIDER USING BETTER ONE")
		return nil
	end
end

function WantedLevelScript:StartScript()
	--self:CalculateSectors(16, 16, 2)
	self.sectorTable = {}
	self.terrainPointTable = {}
	
	self.spawnMessageTable = {
		"nigga melon",
		"bottom text",
		"filipe rulezzz"
	}
	
	
	self.spawnTicketsMax = math.random(3,5)
	self.spawnTickets = self.spawnTicketsMax
	self.spawnTier = 1 -- start with 0 and ends with 3
	
	--self.spawnDelayMin = 4000 -- IN MS
	--self.spawnDelayMax = 5000
	self.spawnDelayMin = 120 -- IN S
	self.spawnDelayMax = 180
	
	self.spawnDelay = math.random(self.spawnDelayMin, self.spawnDelayMax)
	self.spawnTimer = 0
end

function WantedLevelScript:UpdateScript()
	
	--if self.spawnTimer:IsPastSimMS(self.spawnDelay) then
	if self.spawnTickets > 0 then -- We run out of tickets!
		if self.spawnTimer > self.spawnDelay then -- Time to spawn!
			self:CalculateSectors(16, 16, 2)
			
			--- Show super cool message
			-- Let them know that they are fucked
			local text = self.spawnMessageTable[math.random(1, #self.spawnMessageTable)]
			ToGameActivity(ActivityMan:GetActivity()):GetBanner(GUIBanner.YELLOW, 0):ShowText(text, GUIBanner.FLYBYLEFTWARD, 1500, Vector(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight), 0.4, 4000, 0);
			ToGameActivity(ActivityMan:GetActivity()):GetBanner(GUIBanner.RED, 0):ShowText(text, GUIBanner.FLYBYRIGHTWARD, 1500, Vector(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight), 0.4, 4000, 0);
			
			-- How many crafts?
			local module = "Heat.rte"
			
			local reinforcementAmout = 1 -- Base
			local reinforcementCraft = "HS Craft"
			local reinforcementCraftSize = 116
			local reinforcementTeam = -1
			local reinforcementSector = nil
			
			--SetScrollTarget
			
			reinforcementAmout = reinforcementAmout + (math.random(1,3) <= self.spawnTier and 1 or 0) -- Chance based on tier
			reinforcementAmout = reinforcementAmout + (math.random(1,3) < self.spawnTier and 1 or 0) -- Chance based on tier
			reinforcementAmout = reinforcementAmout + (math.random(1,5) < 2 and 1 or 0) -- Chance based on pure luck
			
			-- Now get a nice spot to land
			for i = 0, (reinforcementAmout - 1) do
				reinforcementSector = WantedLevelScript:PickSector(reinforcementCraftSize * (reinforcementAmout - i))
				if reinforcementSector ~= nil then
					reinforcementAmout = reinforcementAmout - i
					break
				end
			end
			
			if reinforcementSector ~= nil then
				-- Spawn them cops!
				for i = 0, (reinforcementAmout - 1) do
					local x = reinforcementSector.Start.X + SceneMan:ShortestDistance(reinforcementSector.Start, reinforcementSector.End,SceneMan.SceneWrapsX).X / reinforcementAmout * i
					if reinforcementAmout == 1 then -- Middle
						x = reinforcementSector.Start.X + SceneMan:ShortestDistance(reinforcementSector.Start, reinforcementSector.End,SceneMan.SceneWrapsX).X * 0.5
					end
					local pos = Vector(x, - math.random(0,50))
					
					local ship = CreateACDropShip(reinforcementCraft, module)
					
					local actorsInCargo = math.min(ship.MaxPassengers, math.random(1,3));
					
					--The max allowed weight of this craft plus cargo
					local craftMaxMass = ship.MaxMass;
					if craftMaxMass < 0 then
						craftMaxMass = math.huge;
					elseif craftMaxMass < 1 then
						craftMaxMass = ship.Mass + 400;	--MaxMass not defined
					end
					
					--Set the ship up with a cargo of a few armed and equipped actors
					for i = 1, actorsInCargo do
						--Get any Actor from the CPU's native tech
						local passenger = nil;
						if math.random(1,3) <= self.spawnTier then
							passenger = RandomAHuman("Actors - Heavy", module);
						else
							passenger = RandomAHuman("Actors - Light", module);
						end
						--Equip it with tools and guns if it's a humanoid
						if IsAHuman(passenger) then
							if math.random(1,3) <= self.spawnTier then
								passenger:AddInventoryItem(RandomHDFirearm("Weapons - Heavy", module));
							else
								passenger:AddInventoryItem(RandomHDFirearm("Weapons - Light", module));
							end
							passenger:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", module));
							if math.random() < 0.2 then
								passenger:AddInventoryItem(RandomHDFirearm("Tools - Diggers", module));
							end
							if math.random() < 0.2 then
								passenger:AddInventoryItem(RandomTDExplosive("Bombs", module));
							end
							
							if math.random() < 0.2 then
								passenger:AddInventoryItem(RandomTDExplosive("Gundrone", module));
							end
							if math.random() < 0.2 then
								passenger:AddInventoryItem(RandomTDExplosive("Buzzdrone", module));
							end
							
						end
						--Set AI mode and team so it knows who and what to fight for!
						passenger.AIMode = Actor.AIMODE_BRAINHUNT
						passenger.Team = reinforcementTeam
						passenger.IgnoresTeamHits = true

						--Yes we can; so add it to the cargo hold
						ship:AddInventoryItem(passenger);
						passenger = nil;
					end
					
					ship.Pos = pos
					ship.Vel = Vector(math.random(-5,5), math.random(0, -15))
					ship.Team = reinforcementTeam
					
					MovableMan:AddActor(ship);
				end
			else
				-- Too bad! no spawning for today!
				print("ERROR: NO SUITABLE SECTORS FOUND")
			end
			
			
			
			self.spawnTier = math.floor((1 - (self.spawnTickets / self.spawnTicketsMax)) * self.spawnTicketsMax + 0.5)
			self.spawnTickets = self.spawnTickets - 1
			
			-- Reset Timer
			--self.spawnTimer:Reset()
			self.spawnTimer = 0
			self.spawnDelay = math.random(self.spawnDelayMin, self.spawnDelayMax)
		else
			self.spawnTimer = self.spawnTimer + TimerMan.DeltaTimeSecs -- Why this over timer? Timer might not stop when paused so I better use this
		end
	end
	
	-- TimerMan.DeltaTimeSecs
	-- Debug points
	--[[
	if #self.terrainPointTable > 0 then
		for i, point in ipairs(self.terrainPointTable) do
			local edge = (i == 1 or i == #self.terrainPointTable)
			local neighbourLeft = nil
			local neighbourRight = nil
			
			if i == 1 then
				neighbourLeft = self.terrainPointTable[#self.terrainPointTable]
			else
				neighbourLeft = self.terrainPointTable[i - 1]
			end
			
			if i == #self.terrainPointTable then
				neighbourRight = self.terrainPointTable[1]
			else
				neighbourRight = self.terrainPointTable[i + 1]
			end
			
			local difLeft = SceneMan:ShortestDistance(point, neighbourLeft,SceneMan.SceneWrapsX)
			local difRight = SceneMan:ShortestDistance(point, neighbourRight,SceneMan.SceneWrapsX)
			
			if math.abs(difLeft.Y) < self.terrainPointHeightDifferenceTolerance then
				--PrimitiveMan:DrawLinePrimitive(point, point + difLeft, 122);
			end
			if math.abs(difRight.Y) < self.terrainPointHeightDifferenceTolerance then
				--PrimitiveMan:DrawLinePrimitive(point, point + difRight, 122);
			end
			
			if edge then
				PrimitiveMan:DrawCirclePrimitive(point, 1, 13)
			else
				PrimitiveMan:DrawCirclePrimitive(point, 1, 5)
			end
			
		end
	end]]
	
	-- Debug sectors
	--[[
	if #self.sectorTable > 0 then
		for i, sector in ipairs(self.sectorTable) do
			PrimitiveMan:DrawLinePrimitive(sector.Start, sector.Start + SceneMan:ShortestDistance(sector.Start, sector.End,SceneMan.SceneWrapsX), 122);
			PrimitiveMan:DrawLinePrimitive(sector.Start + Vector(0, 10), sector.Start + Vector(0, -10), 122);
			PrimitiveMan:DrawLinePrimitive(sector.End + Vector(0, 10), sector.End + Vector(0, -10), 122);
			
			PrimitiveMan:DrawCirclePrimitive(sector.Start, 3, 13)
			PrimitiveMan:DrawCirclePrimitive(sector.End, 3, 149)
		end
	end]]
end

function WantedLevelScript:EndScript()
end

function WantedLevelScript:PauseScript()
end

function WantedLevelScript:CraftEnteredOrbit()
end
