function WantedLevelScript:CalculateSectors(spacing, heightDifferenceTolerance, minimumSize)
	-- Calculate suitable landing spots
	self.terrainPointSpacing = spacing or 16
	self.terrainPointAmount = math.floor(SceneMan.SceneWidth / self.terrainPointSpacing)
	self.terrainPointHeightDifferenceTolerance = heightDifferenceTolerance or 16
	
	self.terrainPointTable = {}
	
	-- Add all points
	for i = 0, self.terrainPointAmount do
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
			if size > minimumSize and sector.Start.Y > 200 and sector.End.Y > 200 then
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

function WantedLevelScript:RandomizeFromTable(tab)
	local highestNumber = 0
	local result
	for i, data in ipairs(tab) do
		local randomNumber = RangeRand(0,1) * data.Chance
		if highestNumber < randomNumber then
			highestNumber = randomNumber
			result = data.Name
		end
	end
	return result
end

function WantedLevelScript:CalculateReinforcements()
	local module = "Heat.rte"
	
	local budget = self.spawnBudgetTable[self.spawnTier]
	self.spawnBudgetMax = math.max(self.spawnBudgetMax, math.random(budget.Min, budget.Max))
	self.spawnBudget = self.spawnBudgetMax
	
	self.spawnActors = {}
	
	local eliteSpeaker = false
	while self.spawnBudget > self.spawnBudgetMinimum do
		local data = self.spawnActorTable[math.random(1, #self.spawnActorTable)]
		if data and data.UnlockTier <= self.spawnTier and data.Cost <= self.spawnBudget then
			local actor = CreateAHuman(data.Name, module)
			
			-- Speaker VO stuff (because pawnis could't resist to add speaker VO)
			if not eliteSpeaker then
				if data.Name == "Corporal" then
					eliteSpeaker = true
					-- Save bunch-o data
					-- pawnis please save bunch of important stuff to variables here
					
					local gender = math.random(0,1)
					actor:SetNumberValue("Gender", gender)
				elseif data.Name == "Sergeant" then
					eliteSpeaker = true
					-- Save bunch-o data
					-- here too
				end
			end
			
			--Equip it with tools and guns if it's a humanoid
			if IsAHuman(actor) then
				if data.Elite == true or math.random() < 0.15 then
					local weapon = CreateHDFirearm(WantedLevelScript:RandomizeFromTable(self.spawnWeaponEliteTable), module)
					actor:AddInventoryItem(weapon)
				else
					local weapon = CreateHDFirearm(WantedLevelScript:RandomizeFromTable(self.spawnWeaponCommonTable), module)
					actor:AddInventoryItem(weapon)
				end
				actor:AddInventoryItem(RandomHDFirearm("Weapons - Secondary", module));
				
				if math.random() < 0.2 then
					actor:AddInventoryItem(RandomHDFirearm("Tools - Diggers", module));
				end
				if math.random() < 0.2 then
					actor:AddInventoryItem(RandomTDExplosive("Bombs", module));
				end
				
				if module == "Heat.rte" then -- Deployable drones
					if math.random() < 0.075 then
						actor:AddInventoryItem(RandomTDExplosive("Gundrone", module));
					end
					if math.random() < 0.075 then
						actor:AddInventoryItem(RandomTDExplosive("Buzzdrone", module));
					end
				end
				
			end
			
			self.spawnBudget = self.spawnBudget - data.Cost
			table.insert(self.spawnActors, actor)
		end
	end
end

function WantedLevelScript:SpawnReinforcements()
	-- How many crafts?
	local module = "Heat.rte"
	
	local reinforcementAmount = 1 -- Base
	local reinforcementCraft = "HS Craft"
	local reinforcementCraftSize = 116
	local reinforcementCraftMaxPassengers = 3
	local reinforcementTeam = self.spawnTeam
	local reinforcementSector = nil
	
	reinforcementAmount = math.ceil(#self.spawnActors / reinforcementCraftMaxPassengers)
	--SetScrollTarget
	
	-- Now get a nice spot to land
	for i = 0, (reinforcementAmount - 1) do
		reinforcementSector = WantedLevelScript:PickSector(reinforcementCraftSize * (reinforcementAmount - i))
		if reinforcementSector ~= nil then
			reinforcementAmount = reinforcementAmount - i
			break
		end
	end
	
	if reinforcementSector ~= nil and reinforcementAmount > 0 then
		local spawnedAnything = false
		
		-- Spawn them!
		for i = 0, (reinforcementAmount - 1) do
			local x = reinforcementSector.Start.X + SceneMan:ShortestDistance(reinforcementSector.Start, reinforcementSector.End,SceneMan.SceneWrapsX).X / reinforcementAmount * i
			if reinforcementAmount == 1 then -- Middle
				x = reinforcementSector.Start.X + SceneMan:ShortestDistance(reinforcementSector.Start, reinforcementSector.End,SceneMan.SceneWrapsX).X * 0.5
			end
			local pos = Vector(x, -math.random(0,50))
			
			local ship = CreateACDropShip(reinforcementCraft, module)
			
			local actorsInCargo = 0
			
			--The max allowed weight of this craft plus cargo
			local craftMaxMass = ship.MaxMass;
			if craftMaxMass < 0 then
				craftMaxMass = math.huge;
			elseif craftMaxMass < 1 then
				craftMaxMass = ship.Mass + 400;	--MaxMass not defined
			end
			
			--Set the ship up with a cargo of a few armed and equipped actors
			while (actorsInCargo < reinforcementCraftMaxPassengers and #self.spawnActors > 0) do
				local passenger = self.spawnActors[1]
				table.remove(self.spawnActors, 1)
				
				-- Set AI mode and team so it knows who and what to fight for!
				passenger.AIMode = Actor.AIMODE_BRAINHUNT
				passenger.Team = reinforcementTeam
				passenger.IgnoresTeamHits = true

				-- Add it to the cargo hold
				ship:AddInventoryItem(passenger);
				passenger = nil;
				
				-- Companion Drone
				if module == "Heat.rte" and (self.spawnBudget > 0 or math.random() < (0.1 * self.spawnTier)) then
					local drone = CreateActor(math.random(1,2) < 2 and "Gundrone" or "Buzzdrone", module) -- Predeployed drone
					drone:SetNumberValue("AIMode", 1) -- Follow someone!
					drone.Team = reinforcementTeam
					drone.IgnoresTeamHits = true
					
					-- Add it to the cargo hold
					ship:AddInventoryItem(drone);
					drone = nil;
					
					if self.spawnBudget > 0 then
						self.spawnBudget = self.spawnBudget - 1
					end
				end
				
				actorsInCargo = actorsInCargo + 1
			end
			
			if ship:IsInventoryEmpty() == false then
				ship.Pos = pos
				ship.Vel = Vector(0, math.random(0, 15))
				ship.Team = reinforcementTeam
				
				MovableMan:AddActor(ship);
				
				spawnedAnything = true -- Double check
			else
				DeleteEntity(ship) -- Don't spawn empty craft, sill!
			end
		end
		
		if spawnedAnything then
			-- Ticket has been used
			self.spawnTickets = self.spawnTickets - 1
			self.spawnTier = math.min(math.floor((1 - (self.spawnTickets / self.spawnTicketsMax)) * self.spawnTicketsMax + 0.5), self.spawnTierMax)
			
			--- Show super cool message
			-- Let them know that they are fucked
			local text = self.spawnMessageTable[math.random(1, #self.spawnMessageTable)]
			
			ToGameActivity(ActivityMan:GetActivity()):GetBanner(GUIBanner.YELLOW, 0):ShowText(text, GUIBanner.FLYBYLEFTWARD, 1500, Vector(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight), 0.4, 4000, 0);
			ToGameActivity(ActivityMan:GetActivity()):GetBanner(GUIBanner.RED, 0):ShowText(text, GUIBanner.FLYBYRIGHTWARD, 1500, Vector(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight), 0.4, 4000, 0);
		end
		
		self.spawnActors = {}
	else
		-- Too bad! no spawning for today!
		print("ERROR: NO SUITABLE SECTORS FOUND")
	end
end

function WantedLevelScript:StartScript()
	--self:CalculateSectors(16, 16, 2)
	self.sectorTable = {}
	self.terrainPointTable = {}
	
	self.spawnMessageTable = {
		"The Heat is here!",
		"Get down, cops!",
		"It's the fuzz!",
		"Cops!",
		"They're here!",
		"Stop right there!"
	}
	
	ActivityMan:GetActivity():SetTeamAISkill(-1, Activity.UNFAIRSKILL)
	
	self.spawnTicketsMax = math.random(4,6)
	self.spawnTickets = self.spawnTicketsMax
	self.spawnTierMax = 3
	self.spawnTier = 1 -- start with 0 and ends with 3
	
	self.spawnBudgetMax = 0
	self.spawnBudget = self.spawnBudgetMax
	self.spawnBudgetMinimum = 2
	
	self.spawnActors = {}
	
	self.spawnActorTable = {
		{Name = "Arrestant Drone", Cost = 2, UnlockTier = 1, Elite = false},
		{Name = "Enforcer Surrogate", Cost = 3, UnlockTier = 1, Elite = false},
		{Name = "Corporal", Cost = 4, UnlockTier = 2, Elite = true},
		{Name = "Sergeant", Cost = 6, UnlockTier = 3, Elite = true}
	}
	
	self.spawnActorSupportTable = {
		{Name = "Buzzdrone", Cost = 1},
		{Name = "Gundrone", Cost = 1}
	}
	
	self.spawnWeaponCommonTable = {
		-- Common
		{Name = "CLIER-95", Chance = 7},
		{Name = "H-M Federal", Chance = 7},
		{Name = "ASSAILANT Rifle", Chance = 7},
		{Name = "FBR Disabler", Chance = 7},
		-- Uncommon
		{Name = "U-Tazer", Chance = 6},
		{Name = "2-3DB Raider", Chance = 6},
		{Name = "HBBP-L Director", Chance = 6},
		{Name = "Jury", Chance = 6},
		{Name = "34-20 Riotbreaker", Chance = 6},
		-- Rare
		{Name = "Executioner", Chance = 5},
		{Name = "BL Co-operator", Chance = 5},
		{Name = "SM Liberator", Chance = 5}
	}
	self.spawnWeaponEliteTable = {	
		-- Common
		{Name = "CLIER-95", Chance = 5},
		{Name = "H-M Federal", Chance = 5},
		{Name = "ASSAILANT Rifle", Chance = 6},
		{Name = "FBR Disabler", Chance = 6},
		-- Uncommon
		{Name = "U-Tazer", Chance = 7},
		{Name = "2-3DB Raider", Chance = 7},
		{Name = "HBBP-L Director", Chance = 7},
		{Name = "Jury", Chance = 7},
		{Name = "34-20 Riotbreaker", Chance = 7},
		-- Rare
		{Name = "Executioner", Chance = 6},
		{Name = "BL Co-operator", Chance = 6},
		{Name = "SM Liberator", Chance = 6}
	}
	
	
	self.spawnBudgetTable = {
		{Min = 6, Max = 10},
		{Min = 12, Max = 20},
		{Min = 18, Max = 26}
	}
	--[[
	self.spawnBudgetTable = {
		{Min = 8, Max = 13},
		{Min = 16, Max = 26},
		{Min = 24, Max = 34}
	}]]
	
	self.spawnTeam = -1
	if ActivityMan:GetActivity().TeamCount < 4 then
		self.spawnTeam = ActivityMan:GetActivity().TeamCount -- it just works ¯\_(ツ)_/¯
	end
	
	--self.spawnDelayMin = 4000 -- IN MS
	--self.spawnDelayMax = 5000
	self.spawnDelayMin = 90 -- IN S
	self.spawnDelayMax = 170
	
	self.spawnDelay = math.random(self.spawnDelayMin, self.spawnDelayMax)
	self.spawnTimer = 0
end

function WantedLevelScript:UpdateScript()
	
	--if self.spawnTimer:IsPastSimMS(self.spawnDelay) then
	if self.spawnTickets > 0 then -- We run out of tickets!
		if self.spawnTimer > self.spawnDelay then -- Time to spawn!
			self:CalculateSectors(16, 16, 2)
			
			self:SpawnReinforcements()
			
			-- Reset Timer and other data
			-- RESET YOUR VARIABLES HERE PAWNIS < ----
			self.spawnTimer = 0
			self.spawnDelay = math.random(self.spawnDelayMin, self.spawnDelayMax)
		elseif self.spawnTimer > (self.spawnDelay - 15) and #self.spawnActors < 1 then -- Precalculate actors and play sounds!
			local reinforcementCraftMaxPassengers = 3
			local reinforcementAmount = math.ceil(#self.spawnActors / reinforcementCraftMaxPassengers)
			
			if reinforcementAmount > 3 then -- 4
			
			elseif reinforcementAmount > 2 then -- 3
			
			elseif reinforcementAmount > 1 then -- 2
				
			else -- 1
				
			end
			
			self:CalculateReinforcements()
			
		elseif ToGameActivity(ActivityMan:GetActivity()).ActivityState ~= Activity.OVER then
			if ToGameActivity(ActivityMan:GetActivity()).ActivityState ~= Activity.EDITING then
				self.spawnTimer = self.spawnTimer + TimerMan.DeltaTimeSecs -- Why this over timer? Timer might not stop when paused so I better use this
			else -- WAVE DEFENCE HEHE
				self.spawnTimer = 0
				self.spawnTickets = math.max(self.spawnTickets, 1)
			end
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
