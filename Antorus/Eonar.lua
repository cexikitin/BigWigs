--------------------------------------------------------------------------------
-- TODO List:
-- Normal mode wave data

--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Eonar the Life-Binder", nil, 2025, 1712)
if not mod then return end
mod:RegisterEnableMob(122500) -- Essence of Eonar
mod.engageId = 2075
mod.respawnTime = 30

--------------------------------------------------------------------------------
-- Locals
--

local rainofFelCounter = 1
local spearCounter = 1
local finalDoomCounter = 1
local lifeForceCounter = 1
local lifeForceNeeded = 4
local engageTime = 0

local timersNormal = {
	--[[ Rain of Fel ]]--
	[248332] = {30, 31, 35, 45, 80, 50, 20, 35}, -- XXX vary a lot across logs

	--[[ Waves ]]--
	["top"] = {
		{120, "destructor"}, -- XXX not confirmed
		{240, "destructor"} -- XXX estimate
	},
	["mid"] = {
		{6, "destructor"},
		{74, "destructor"},
		{175, "obfuscator"}, -- XXX not confirmed
		{300, "destructor"} -- XXX not confirmed
	},
	["bot"] = {
		{44, "destructor"},
		{130, nil}, -- XXX not confirmed
		{225, "destructor"}
	},
	["air"] = {
		{230, nil} -- XXX not confirmed
	}
}

local timersHeroic = {
	--[[ Rain of Fel ]]--
	[248332] = {15, 38.5, 10, 45, 34.5, 19, 19, 29, 44.5, 35, 97},

	--[[ Spear of Doom ]] --
	[248861] = {29.7, 59.6, 64.5, 40.3, 84.6, 35.2, 65.7},

	--[[ Waves ]]-- -- XXX Check these after implementation
	["top"] = {
		{68, "obfuscator"},
		{87, "destructor"},
		{192, "small_adds"},
		{320, "destructor"},
	},
	["mid"] = {
		{6.8, "destructor"},
		{114, "purifier"},
		{215, "purifier"}, -- Also spawns a obfuscator
		{320, "destructor"},
	},
	["bot"] = {
		{35, "destructor"},
		{190, "destructor"}, -- Also spawns a purifier
		{320, "obfuscator"},
	},
	["air"] = {
		{159, nil},
		{285, nil},
	}
}

local timersMythic = {
	--[[ Rain of Fel ]]--
	[248332] = {6, 29, 25, 48.5, 5, 20, 50.5, 25, 4.5, 46, 24, 4},

	--[[ Spear of Doom ]] --
	[248861] = {15, 75, 75, 75, 25, 75, 75},

	--[[ Final Doom ]]--
	[249121] = {60.5, 116.5, 100, 103, 100}, -- confirm via logs

	--[[ Waves ]]--
	["top"] = {
		{38, "destructor"},
		{145, "small_adds"},
		{328, "obfuscator"},
		{355, "purifier"},
		{403, "destructor"}, -- confirm / exact time needed
	},
	["mid"] = {
		{6, "destructor"},
		{65, "purifier"},
		{133, "purifier"},
		{278, "obfuscator"},
		{403, "destructor"}, -- confirm / exact time needed
	},
	["bot"] = {
		{38, "obfuscator"},
		{108, "destructor"},
		{208, "purifier"},
		{297, "small_adds"},
		{403, "obfuscator"}, -- confirm / exact time needed
	},
	["air"] = {
		{165, nil}, -- confirm / exact time needed
		{270, nil}, -- confirm / exact time needed
		{360, nil}, -- confirm / exact time needed
		{480, nil}, -- confirm / exact time needed
	}
}

local timers = mod:Mythic() and timersMythic or mod:Heroic() and timersHeroic or timersNormal

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:GetLocale()
if L then
	L.warp_in = mod:SpellName(246888)
	L.warp_in_desc = "Shows timers and messages for each wave, along with any special adds in the wave."
	L.warp_in_icon = "inv_artifact_dimensionalrift"

	L.lifeforce_casts = "%s (%d/%d)"

	L.lane_text = "%s: %s" -- example: Top: Purifier
	L.top_lane = "Top"
	L.mid_lane = "Mid"
	L.bot_lane = "Bot"

	L.purifier = "Purifier" -- Fel-Powered Purifier
	L.destructor = "Destructor" -- Fel-Infused Destructor
	L.obfuscator = "Obfuscator" -- Fel-Charged Obfuscator
	L.bats = "Fel Bats"
	L.small_adds = CL.small_adds
end

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"warp_in",
		250048, -- Life Force
		248861, -- Spear of Doom
		{248332, "SAY", "FLASH"}, -- Rain of Fel
		249121, -- Final Doom
		249934, -- Purge
		{250693, "SAY", "FLASH"}, -- Arcane Buildup
		{250691, "SAY", "FLASH"}, -- Burning Embers
		250140, -- Foul Steps
	},{
		["warp_in"] = "general",
		[249121] = "mythic",
	}
end

function mod:OnBossEnable()
	self:RegisterUnitEvent("UNIT_POWER", nil, "boss1")
	self:Log("SPELL_CAST_START", "LifeForce", 250048)
	self:Log("SPELL_CAST_SUCCESS", "LifeForceSuccess", 250048)

	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE") -- Spear of Doom

	self:Log("SPELL_AURA_APPLIED", "RainofFel", 248332)
	self:Log("SPELL_AURA_REMOVED", "RainofFelRemoved", 248332)

	--[[ Mythic ]]--
	self:Log("SPELL_CAST_START", "FinalDoom", 249121)
	self:Log("SPELL_CAST_START", "Purge", 249934)

	self:Log("SPELL_AURA_APPLIED", "ArcaneBuildup", 250693) -- Feedback - Arcane Singularity
	self:Log("SPELL_AURA_REMOVED", "ArcaneBuildupRemoved", 250693)

	self:Log("SPELL_AURA_APPLIED", "BurningEmbers", 250691) -- Feedback - Burning Embers
	self:Log("SPELL_AURA_REMOVED", "BurningEmbersRemoved", 250691)

	self:Log("SPELL_AURA_APPLIED", "FoulSteps", 250140) -- Feedback - Foul Steps
	self:Log("SPELL_AURA_APPLIED_DOSE", "FoulSteps", 250140)
end

function mod:OnEngage()
	timers = self:Mythic() and timersMythic or self:Heroic() and timersHeroic or timersNormal
	rainofFelCounter = 1
	spearCounter = 1
	finalDoomCounter = 1
	lifeForceCounter = 1

	engageTime = GetTime()
	self:StartWaveTimer("top", 1) -- Top wave spawns
	self:StartWaveTimer("mid", 1) -- Middle wave spawns
	self:StartWaveTimer("bot", 1) -- Bottom wave spawns
	self:StartWaveTimer("air", 1) -- Air wave spawns

	self:Bar(248332, timers[248332][rainofFelCounter]) -- Rain of Fel

	if self:Heroic() or self:Mythic() then
		self:CDBar(248861, timers[248861][spearCounter]) -- Spear of Doom
	end
	if self:Mythic() then
		self:CDBar(249121, timers[249121][finalDoomCounter], CL.count:format(self:SpellName(249121), finalDoomCounter)) -- Final Doom
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:StartWaveTimer(lane, count)
	local wavetimer = timers and timers[lane][count]
	if not wavetimer then
		-- No wave info
		return
	end

	local time, addType = unpack(wavetimer)
	local length = floor(time - (GetTime() - engageTime))

	local laneText, icon = nil, nil
	if lane == "top" then
		laneText = L.top_lane
		icon = "misc_arrowlup"
	elseif lane == "mid" then
		laneText = L.mid_lane
		icon = "misc_arrowright"
	elseif lane == "bot" then
		laneText = L.bot_lane
		icon = "misc_arrowdown"
	elseif lane == "air" then
		laneText = L.bats
		icon = "inv_batpet"
	end

	local addTypeText = L[addType]
	local barText = addTypeText and L.lane_text:format(laneText, addTypeText) or laneText

	self:Bar("warp_in", length, barText, icon)
	self:DelayedMessage("warp_in", length, "Attention", barText, icon, "Alert")
	self:ScheduleTimer("StartWaveTimer", length, lane, count+1)
end

function mod:UNIT_POWER(unit)
	local power = UnitPower(unit)
	if power >= 80 then
		self:Message(250048, "Neutral", "Info", L.lifeforce_casts:format(CL.soon:format(self:SpellName(250048)), lifeForceCounter, lifeForceNeeded)) -- Life Force
		self:UnregisterUnitEvent("UNIT_POWER", unit)
	end
end

function mod:LifeForce(args)
	self:Message(args.spellId, "Positive", "Long", L.lifeforce_casts:format(CL.casting:format(args.spellName), lifeForceCounter, lifeForceNeeded))
	lifeForceCounter = lifeForceCounter + 1
end

function mod:LifeForceSuccess()
	self:RegisterUnitEvent("UNIT_POWER", nil, "boss1")
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if msg:find("248861") then -- Spear of Doom
		self:Message(248861, "Important", "Warning")
		spearCounter = spearCounter + 1
		self:CDBar(248861, timers[248861][spearCounter])
	end
end

do
	local playerList, prev = mod:NewTargetList(), 0
	function mod:RainofFel(args)
		if self:Me(args.destGUID) then
			self:Say(args.spellId)
			self:Flash(args.spellId)
			self:SayCountdown(args.spellId, 5)
		end
		playerList[#playerList+1] = args.destName
		if #playerList == 1 then
			self:ScheduleTimer("TargetMessage", 0.3, args.spellId, playerList, "Important", "Alarm")
			local t = GetTime()
			if t-prev > 5 then -- prevent a wrong bar if Rain of Fel gets delayed late
				prev = t
				rainofFelCounter = rainofFelCounter + 1
				self:Bar(args.spellId, timers[args.spellId][rainofFelCounter])
			end
		end
	end

	function mod:RainofFelRemoved(args)
		if self:Me(args.destGUID) then
			self:CancelSayCountdown(args.spellId)
		end
	end
end

function mod:FinalDoom(args)
	self:Message(args.spellId, "Important", "Warning", CL.count:format(args.spellName, finalDoomCounter))
	self:CastBar(args.spellId, 50, CL.count:format(args.spellName, finalDoomCounter))
	finalDoomCounter = finalDoomCounter + 1
	self:Bar(args.spellId, timers[args.spellId][finalDoomCounter], CL.count:format(args.spellName, finalDoomCounter))
end

function mod:Purge(args)
	self:StopBar(CL.cast:format(CL.count:format(self:SpellName(249121), finalDoomCounter-1)))
	self:Message(249121, "Positive", "Info", CL.interrupted:format(self:SpellName(249121))) -- Final Doom
	self:CastBar(args.spellId, 20)
end

function mod:ArcaneBuildup(args)
	if self:Me(args.destGUID) then
		self:TargetMessage(args.spellId, args.destName, "Personal", "Alarm")
		self:Say(args.spellId)
		self:Flash(args.spellId)
		self:SayCountdown(args.spellId, 5)
	end
end

function mod:ArcaneBuildupRemoved(args)
	if self:Me(args.destGUID) then
		self:CancelSayCountdown(args.spellId)
	end
end

function mod:BurningEmbers(args)
	if self:Me(args.destGUID) then
		self:TargetMessage(args.spellId, args.destName, "Personal", "Alarm")
		self:Say(args.spellId)
		self:Flash(args.spellId)
		self:SayCountdown(args.spellId, 5)
	end
end

function mod:BurningEmbersRemoved(args)
	if self:Me(args.destGUID) then
		self:CancelSayCountdown(args.spellId)
	end
end

function mod:FoulSteps(args)
	local amount = args.amount or 1
	if self:Me(args.destGUID) and amount % 3 == 0 then
		self:StackMessage(args.spellId, args.destName, amount, "Personal", "Alarm")
	end
end
