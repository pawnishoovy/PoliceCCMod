-- Unique Faction ID
local factionid = "Heat";
--print ("Loading "..factionid)

CF_Factions[#CF_Factions + 1] = factionid

-- Faction name
CF_FactionNames[factionid] = "The Heat";
-- Faction description
CF_FactionDescriptions[factionid] = "The Heat, in space! Nothing escapes the long arm of the law! Weaponry ranging from nimble auto-aiming pistols to massive death lazers with units to match.";
-- Set true if faction is selectable by player or AI
CF_FactionPlayable[factionid] = true;

-- Main module used to check if mod is installed and as backward compatibility layer with v1-faction files enabled missions
CF_RequiredModules[factionid] = {"Base.rte", "Heat.rte"}

-- Set faction nature
CF_FactionNatures[factionid] = CF_FactionTypes.SYNTHETIC;

-- Define faction bonuses, in percents
CF_ScanBonuses[factionid] = 10
CF_RelationsBonuses[factionid] = 0
CF_ExpansionBonuses[factionid] = 0

CF_MineBonuses[factionid] = 5
CF_LabBonuses[factionid] = 5
CF_AirfieldBonuses[factionid] = 5
CF_SuperWeaponBonuses[factionid] = 0
CF_FactoryBonuses[factionid] = 5
CF_CloneBonuses[factionid] = 5
CF_HospitalBonuses[factionid] = 15


-- Define brain unit
CF_Brains[factionid] = "Sergeant Leader";
CF_BrainModules[factionid] = "Heat.rte";
CF_BrainClasses[factionid] = "AHuman";
CF_BrainPrices[factionid] = 500;

-- Define dropship	
CF_Crafts[factionid] = "HS Craft";
CF_CraftModules[factionid] = "Heat.rte";
CF_CraftClasses[factionid] = "ACDropShip";
CF_CraftPrices[factionid] = 300;

-- Define superweapon script
CF_SuperWeaponScripts[factionid] = "UnmappedLands2.rte/SuperWeapons/NapalmBombing.lua"

-- Define buyable actors available for purchase or unlocks
CF_ActNames[factionid] = {}
CF_ActPresets[factionid] = {}
CF_ActModules[factionid] = {}
CF_ActPrices[factionid] = {}
CF_ActDescriptions[factionid] = {}
CF_ActUnlockData[factionid] = {}
CF_ActClasses[factionid] = {}
CF_ActTypes[factionid] = {}
CF_ActPowers[factionid] = {}
CF_ActOffsets[factionid] = {}

local i = 0

i = #CF_ActNames[factionid] + 1
CF_ActNames[factionid][i] = "Arrestant"
CF_ActPresets[factionid][i] = "Arrestant Drone"
CF_ActModules[factionid][i] = "Heat.rte"
CF_ActPrices[factionid][i] = 130
CF_ActDescriptions[factionid][i] = "Agile police drone."
CF_ActUnlockData[factionid][i] = 0
CF_ActTypes[factionid][i] = CF_ActorTypes.LIGHT;
CF_ActPowers[factionid][i] = 3

i = #CF_ActNames[factionid] + 1
CF_ActNames[factionid][i] = "Enforcer"
CF_ActPresets[factionid][i] = "Enforcer Surrogate"
CF_ActModules[factionid][i] = "Heat.rte"
CF_ActPrices[factionid][i] = 150
CF_ActDescriptions[factionid][i] = "Sturdy police robot."
CF_ActUnlockData[factionid][i] = 800
CF_ActTypes[factionid][i] = CF_ActorTypes.LIGHT;
CF_ActPowers[factionid][i] = 3

i = #CF_ActNames[factionid] + 1
CF_ActNames[factionid][i] = "Police Sergeant"
CF_ActPresets[factionid][i] = "Sergeant"
CF_ActModules[factionid][i] = "Heat.rte"
CF_ActPrices[factionid][i] = 300
CF_ActDescriptions[factionid][i] = "The Sarge himself come to help you out. Bring his shield out with O."
CF_ActUnlockData[factionid][i] = 2000
CF_ActTypes[factionid][i] = CF_ActorTypes.HEAVY;
CF_ActPowers[factionid][i] = 6



i = #CF_ActNames[factionid] + 1
CF_ActNames[factionid][i] = "Anti-Air Drone"
CF_ActPresets[factionid][i] = "Anti-Air Drone"
CF_ActModules[factionid][i] = "Base.rte"
CF_ActPrices[factionid][i] = 225
CF_ActDescriptions[factionid][i] = "Tradstar's Anti-Air Drone sports a machine gun plus a pair of fully automated surface to air missiles for bringing down any unwanted visitors above your landing zone."
CF_ActUnlockData[factionid][i] = 750
CF_ActClasses[factionid][i] = "ACrab"
CF_ActTypes[factionid][i] = CF_ActorTypes.ARMOR;
CF_ActPowers[factionid][i] = 3
CF_ActOffsets[factionid][i] = Vector(0,12)

i = #CF_ActNames[factionid] + 1
CF_ActNames[factionid][i] = "Medic Drone"
CF_ActPresets[factionid][i] = "Medic Drone"
CF_ActModules[factionid][i] = "Coalition.rte"
CF_ActPrices[factionid][i] = 110
CF_ActDescriptions[factionid][i] = "Send this into the battlefield and place it near a unit to create a forcefield around it that heals nearby actors."
CF_ActUnlockData[factionid][i] = 500
CF_ActClasses[factionid][i] = "ACrab"
CF_ActTypes[factionid][i] = CF_ActorTypes.ARMOR;
CF_ActPowers[factionid][i] = 0
CF_ActOffsets[factionid][i] = Vector(0,12)



-- Define buyable items available for purchase or unlocks
CF_ItmNames[factionid] = {}
CF_ItmPresets[factionid] = {}
CF_ItmModules[factionid] = {}
CF_ItmPrices[factionid] = {}
CF_ItmDescriptions[factionid] = {}
CF_ItmUnlockData[factionid] = {}
CF_ItmClasses[factionid] = {}
CF_ItmTypes[factionid] = {}
CF_ItmPowers[factionid] = {}

local i = 0
i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "Light Digger"
CF_ItmPresets[factionid][i] = "Light Digger"
CF_ItmModules[factionid][i] = "Base.rte"
CF_ItmPrices[factionid][i] = 10
CF_ItmDescriptions[factionid][i] = "Lightest in the digger family. Cheapest of them all and works as a nice melee weapon on soft targets."
CF_ItmUnlockData[factionid][i] = 0 -- 0 means available at start
CF_ItmTypes[factionid][i] = CF_WeaponTypes.DIGGER;
CF_ItmPowers[factionid][i] = 1

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "Medium Digger"
CF_ItmPresets[factionid][i] = "Medium Digger"
CF_ItmModules[factionid][i] = "Base.rte"
CF_ItmPrices[factionid][i] = 40
CF_ItmDescriptions[factionid][i] = "Stronger digger. This one can pierce rocks with some effort and dig impressive tunnels and its melee weapon capabilities are much greater."
CF_ItmUnlockData[factionid][i] = 500
CF_ItmTypes[factionid][i] = CF_WeaponTypes.DIGGER;
CF_ItmPowers[factionid][i] = 4

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "Heavy Digger"
CF_ItmPresets[factionid][i] = "Heavy Digger"
CF_ItmModules[factionid][i] = "Base.rte"
CF_ItmPrices[factionid][i] = 100
CF_ItmDescriptions[factionid][i] = "Heaviest and the most powerful of them all. Eats concrete with great hunger and allows you to make complex mining caves incredibly fast. Shreds anyone unfortunate who stand in its way."
CF_ItmUnlockData[factionid][i] = 1000
CF_ItmTypes[factionid][i] = CF_WeaponTypes.DIGGER;
CF_ItmPowers[factionid][i] = 8

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "Riot Shield"
CF_ItmPresets[factionid][i] = "Riot Shield"
CF_ItmModules[factionid][i] = "Base.rte"
CF_ItmPrices[factionid][i] = 20
CF_ItmDescriptions[factionid][i] = "This metal shield provides excellent additional frontal protection to the user and it can stop numerous hits before breaking up."
CF_ItmUnlockData[factionid][i] = 500
CF_ItmClasses[factionid][i] = "HeldDevice"
CF_ItmTypes[factionid][i] = CF_WeaponTypes.SHIELD;
CF_ItmPowers[factionid][i] = 1

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "Fragmatic Grenade"
CF_ItmPresets[factionid][i] = "Fragmatic Grenade"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 15
CF_ItmDescriptions[factionid][i] = "High-knowledge grenade with clearly timed fuse."
CF_ItmUnlockData[factionid][i] = 150
CF_ItmClasses[factionid][i] = "TDExplosive"
CF_ItmTypes[factionid][i] = CF_WeaponTypes.GRENADE;
CF_ItmPowers[factionid][i] = 1

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "Chrononade"
CF_ItmPresets[factionid][i] = "Chrononade"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 40
CF_ItmDescriptions[factionid][i] = "Area-slowing experimental grenade. Responsible use recommended."
CF_ItmUnlockData[factionid][i] = 600
CF_ItmClasses[factionid][i] = "TDExplosive"
CF_ItmTypes[factionid][i] = CF_WeaponTypes.GRENADE;
CF_ItmPowers[factionid][i] = 5

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "Buzzdrone"
CF_ItmPresets[factionid][i] = "Buzzdrone Deploy"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 40
CF_ItmDescriptions[factionid][i] = "Throwable buzzsaw drone. Definitely ethical to use on criminals, right?"
CF_ItmUnlockData[factionid][i] = 300
CF_ItmClasses[factionid][i] = "TDExplosive"
CF_ItmTypes[factionid][i] = CF_WeaponTypes.GRENADE;
CF_ItmPowers[factionid][i] = 2

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "Gundrone"
CF_ItmPresets[factionid][i] = "Gundrone Deploy"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 60
CF_ItmDescriptions[factionid][i] = "Throwable gundrone."
CF_ItmUnlockData[factionid][i] = 500
CF_ItmClasses[factionid][i] = "TDExplosive"
CF_ItmTypes[factionid][i] = CF_WeaponTypes.GRENADE;
CF_ItmPowers[factionid][i] = 3

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "Light Scanner"
CF_ItmPresets[factionid][i] = "Light Scanner"
CF_ItmModules[factionid][i] = "Base.rte"
CF_ItmPrices[factionid][i] = 10
CF_ItmDescriptions[factionid][i] = "Lightest in the scanner family. Cheapest of them all and can only scan a small area."
CF_ItmUnlockData[factionid][i] = 150
CF_ItmTypes[factionid][i] = CF_WeaponTypes.TOOL;
CF_ItmPowers[factionid][i] = 0

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "Medium Scanner"
CF_ItmPresets[factionid][i] = "Medium Scanner"
CF_ItmModules[factionid][i] = "Base.rte"
CF_ItmPrices[factionid][i] = 40
CF_ItmDescriptions[factionid][i] = "Medium scanner. This scanner is stronger and can reveal a larger area."
CF_ItmUnlockData[factionid][i] = 250
CF_ItmTypes[factionid][i] = CF_WeaponTypes.TOOL;
CF_ItmPowers[factionid][i] = 0

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "Heavy Scanner"
CF_ItmPresets[factionid][i] = "Heavy Scanner"
CF_ItmModules[factionid][i] = "Base.rte"
CF_ItmPrices[factionid][i] = 70
CF_ItmDescriptions[factionid][i] = "Strongest scanner out of the three. Can reveal a large area."
CF_ItmUnlockData[factionid][i] = 450
CF_ItmTypes[factionid][i] = CF_WeaponTypes.TOOL;
CF_ItmPowers[factionid][i] = 0

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "Lightningstar"
CF_ItmPresets[factionid][i] = "Lightningstar"
CF_ItmModules[factionid][i] = "CCU.rte"
CF_ItmPrices[factionid][i] = 30
CF_ItmDescriptions[factionid][i] = "Theoretically non-lethal extending electric mace. Will easily kill."
CF_ItmUnlockData[factionid][i] = 100
CF_ItmTypes[factionid][i] = CF_WeaponTypes.TOOL;
CF_ItmPowers[factionid][i] = 0

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "BCK-12 Centress"
CF_ItmPresets[factionid][i] = "BCK-12 Centress"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 25
CF_ItmDescriptions[factionid][i] = "Auto-eject recoil-absorbing pistol."
CF_ItmUnlockData[factionid][i] = 0
CF_ItmTypes[factionid][i] = CF_WeaponTypes.PISTOL;
CF_ItmPowers[factionid][i] = 2

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "Judge"
CF_ItmPresets[factionid][i] = "Judge"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 35
CF_ItmDescriptions[factionid][i] = "Smart, powerful revolver. Use V to switch smart-mode on/off."
CF_ItmUnlockData[factionid][i] = 150
CF_ItmTypes[factionid][i] = CF_WeaponTypes.PISTOL;
CF_ItmPowers[factionid][i] = 3

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "CLIER-95"
CF_ItmPresets[factionid][i] = "CLIER-95"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 40
CF_ItmDescriptions[factionid][i] = "Submachinegun with laser and flashbang, H and V respectively."
CF_ItmUnlockData[factionid][i] = 0
CF_ItmTypes[factionid][i] = CF_WeaponTypes.RIFLE;
CF_ItmPowers[factionid][i] = 1

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "H-M Federal"
CF_ItmPresets[factionid][i] = "H-M Federal"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 55
CF_ItmDescriptions[factionid][i] = "Select-fire battle rifle, use V to switch."
CF_ItmUnlockData[factionid][i] = 50
CF_ItmTypes[factionid][i] = CF_WeaponTypes.RIFLE;
CF_ItmPowers[factionid][i] = 1

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "ASSAILANT Rifle"
CF_ItmPresets[factionid][i] = "ASSAILANT Rifle"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 70
CF_ItmDescriptions[factionid][i] = "Dangerous automatic rifle with underbarrel grenade - V to use."
CF_ItmUnlockData[factionid][i] = 200
CF_ItmTypes[factionid][i] = CF_WeaponTypes.RIFLE;
CF_ItmPowers[factionid][i] = 2

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "HBBP-L Director"
CF_ItmPresets[factionid][i] = "HBBP-L Director"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 70
CF_ItmDescriptions[factionid][i] = "Self-heat-managing laser rifle. Best in short bursts."
CF_ItmUnlockData[factionid][i] = 400
CF_ItmTypes[factionid][i] = CF_WeaponTypes.RIFLE;
CF_ItmPowers[factionid][i] = 5

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "U-Tazer"
CF_ItmPresets[factionid][i] = "U-Tazer"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 70
CF_ItmDescriptions[factionid][i] = "Lightning gun! Tazer, but extremely large."
CF_ItmUnlockData[factionid][i] = 600
CF_ItmTypes[factionid][i] = CF_WeaponTypes.RIFLE;
CF_ItmPowers[factionid][i] = 6

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "FBR Disabler"
CF_ItmPresets[factionid][i] = "FBR Disabler"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 75
CF_ItmDescriptions[factionid][i] = "Fully-automatic crowd control rifle. Flak rounds."
CF_ItmUnlockData[factionid][i] = 800
CF_ItmTypes[factionid][i] = CF_WeaponTypes.RIFLE;
CF_ItmPowers[factionid][i] = 5

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "Jury"
CF_ItmPresets[factionid][i] = "Jury"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 105
CF_ItmDescriptions[factionid][i] = "High-capacity machine-gun that can fire half its magazine at once with V."
CF_ItmUnlockData[factionid][i] = 400
CF_ItmTypes[factionid][i] = CF_WeaponTypes.HEAVY;
CF_ItmPowers[factionid][i] = 5

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "Executioner"
CF_ItmPresets[factionid][i] = "Executioner"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 150
CF_ItmDescriptions[factionid][i] = "Shielded, self-charging sniper rifle."
CF_ItmUnlockData[factionid][i] = 800
CF_ItmTypes[factionid][i] = CF_WeaponTypes.SNIPER;
CF_ItmPowers[factionid][i] = 6

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "2-3DB Raider"
CF_ItmPresets[factionid][i] = "2-3DB Raider"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 75
CF_ItmDescriptions[factionid][i] = "Plasma-injected burst-fire double barrel shotgun."
CF_ItmUnlockData[factionid][i] = 200
CF_ItmTypes[factionid][i] = CF_WeaponTypes.SHOTGUN;
CF_ItmPowers[factionid][i] = 4

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "BL Co-operator"
CF_ItmPresets[factionid][i] = "BL Co-operator"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 110
CF_ItmDescriptions[factionid][i] = "Short-lived death ray."
CF_ItmUnlockData[factionid][i] = 1500
CF_ItmTypes[factionid][i] = CF_WeaponTypes.HEAVY;
CF_ItmPowers[factionid][i] = 9

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "34-20 Riotbreaker"
CF_ItmPresets[factionid][i] = "34-20 Riotbreaker"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 105
CF_ItmDescriptions[factionid][i] = "Pump-action grenade launcher."
CF_ItmUnlockData[factionid][i] = 1000
CF_ItmTypes[factionid][i] = CF_WeaponTypes.HEAVY;
CF_ItmPowers[factionid][i] = 8

i = #CF_ItmNames[factionid] + 1
CF_ItmNames[factionid][i] = "SM Liberator"
CF_ItmPresets[factionid][i] = "SM Liberator"
CF_ItmModules[factionid][i] = "Heat.rte"
CF_ItmPrices[factionid][i] = 135
CF_ItmDescriptions[factionid][i] = "Shoulder-mounted missile launching platform. Full targetting suite."
CF_ItmUnlockData[factionid][i] = 2000
CF_ItmTypes[factionid][i] = CF_WeaponTypes.HEAVY;
CF_ItmPowers[factionid][i] = 10
