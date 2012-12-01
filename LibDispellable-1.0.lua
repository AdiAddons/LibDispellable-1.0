--[[
LibDispellable-1.0 - Test whether the player can really dispell a buff or debuff, given its talents.
Copyright (C) 2009-2012 Adirelle (adirelle@gmail.com)

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.
    * Redistribution of a stand alone version is strictly prohibited without
      prior written authorization from the LibDispellable project manager.
    * Neither the name of the LibDispellable authors nor the names of its contributors
      may be used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]

local MAJOR, MINOR = "LibDispellable-1.0", 11
--@debug@
MINOR = 999999999
--@end-debug@
assert(LibStub, MAJOR.." requires LibStub")
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

-- ----------------------------------------------------------------------------
-- Event dispatcher
-- ----------------------------------------------------------------------------

if not lib.eventFrame then
	lib.eventFrame = CreateFrame("Frame")
	lib.eventFrame:SetScript('OnEvent', function() return lib:UpdateSpells() end)
	lib.eventFrame:RegisterEvent('SPELLS_CHANGED')
end

-- ----------------------------------------------------------------------------
-- Data
-- ----------------------------------------------------------------------------

lib.defensive = lib.defensive or {}
lib.enrageEffectIDs = wipe(lib.enrageEffectIDs or {})
lib.spells = {}

for _, id in ipairs({
	-- Datamined using fetchEnrageList.sh (see source)
	134, 256, 772, 4146, 8599, 12880, 14201, 14202, 14203, 14204, 15061, 15716,
	18501, 19451, 19812, 22428, 23128, 23257, 23342, 24689, 25503, 26041, 26051,
	28371, 29131, 29340, 30485, 31540, 31915, 32714, 33958, 34392, 34670, 37605,
	37648, 37975, 38046, 38166, 38664, 39031, 39575, 40076, 40601, 41254, 41364,
	41447, 42705, 42745, 43139, 43292, 43664, 47399, 48138, 48142, 48193, 48391,
	48702, 49029, 50420, 50636, 51170, 51513, 51662, 52071, 52262, 52309, 52461,
	52470, 52537, 53361, 54356, 54427, 54475, 54508, 54781, 55285, 55462, 56646,
	56729, 56769, 57514, 57516, 57518, 57519, 57520, 57521, 57522, 57733, 58942,
	59465, 59694, 59697, 59707, 59828, 60075, 60177, 60430, 61369, 62071, 63147,
	63227, 63848, 66092, 66759, 67233, 67657, 67658, 67659, 68541, 69052, 70371,
	72143, 72146, 72147, 72148, 72203, 75998, 76100, 76487, 76691, 76816, 76862,
	77238, 78722, 78943, 79420, 80084, 80158, 80467, 81706, 81772, 82033, 82759,
	86736, 90045, 90872, 91668, 92946, 95436, 95459, 101109, 101110, 102134,
	102989, 108169, 108566, 109889
}) do lib.enrageEffectIDs[id] = true end

-- ----------------------------------------------------------------------------
-- Detect available dispel skiils
-- ----------------------------------------------------------------------------

local function CheckSpell(spellID, pet)
	return IsSpellKnown(spellID, pet) and spellID or nil
end

function lib:UpdateSpells()
	wipe(self.defensive)
	self.offensive = nil

	local _, class = UnitClass("player")

	if class == "HUNTER" then
		self.offensive = CheckSpell(19801) -- Tranquilizing Shot
		self.tranquilize = self.offensive

	elseif class == "SHAMAN" then
		self.offensive = CheckSpell(370) -- Purge
		if IsSpellKnown(77130) then -- Purify Spirit
			self.defensive.Curse = 77130
			self.defensive.Magic = 77130
		else
			self.defensive.Curse = CheckSpell(51886) -- Cleanse Spirit
		end

	elseif class == "WARLOCK" then
		self.offensive = CheckSpell(19505, true) -- Devour Magic (Felhunter)
		self.defensive.Magic = CheckSpell(89808, true) -- Singe Magic (Imp)

	elseif class == "MAGE" then
		self.defensive.Curse = CheckSpell(475) -- Remove Curse

	elseif class == "PRIEST" then
		self.offensive = CheckSpell(528) -- Dispel Magic
		self.defensive.Magic = CheckSpell(527) -- Purify
		self.defensive.Disease = self.defensive.Magic

	elseif class == "DRUID" then
		if IsSpellKnown(88423) then -- Nature's Cure
			self.defensive.Curse = 88423
			self.defensive.Magic = 88423
		else
			self.defensive.Curse = CheckSpell(2782) -- Remove Corruption
		end
		self.defensive.Poison = self.defensive.Curse
		self.tranquilize = CheckSpell(2908) -- Soothe

	elseif class == "ROGUE" then
		self.tranquilize = CheckSpell(5938) -- Shiv

	elseif class == "PALADIN" then
		if IsSpellKnown(4987) then -- Cleanse
			self.defensive.Poison = 4987
			self.defensive.Disease = 4987
			if IsSpellKnown(53551) then -- Sacred Cleansing
				self.defensive.Magic = 4987
			end
		end

	elseif class == "MONK" then
		self.defensive.Disease = CheckSpell(115450) -- Detox
		self.defensive.Poison = self.defensive.Disease

	end

	wipe(self.spells)
	if self.offensive then
		self.spells[self.offensive] = 'offensive'
	end
	if self.tranquilize then
		self.spells[self.tranquilize] = 'tranquilize'
	end
	for dispelType, id in pairs(self.defensive) do
		self.spells[id] = 'defensive'
	end

end

-- ----------------------------------------------------------------------------
-- Enrage test method
-- ----------------------------------------------------------------------------

--- Test if the specified spell is an enrage effect
-- @name LibDispellable:IsEnrageEffect
-- @param spellID (number) The spell ID
-- @return isEnrage (boolean) true if the passed spell ID
function lib:IsEnrageEffect(spellID)
	return spellID and lib.enrageEffectIDs[spellID]
end

-- ----------------------------------------------------------------------------
-- Simple query method
-- ----------------------------------------------------------------------------

--- Test if the player can dispel the given (de)buff on the given unit.
-- @name LibDispellable:CanDispel
-- @param unit (string) The unit id.
-- @param offensive (boolean) True to test offensive dispel, i.e. enemy buffs.
-- @param dispelType (string) The dispel mechanism, as returned by UnitAura.
-- @param spellID (number, optional) The buff spell ID, as returned by UnitAura, used to test enrage effects.
-- @return canDispel, spellID (boolean, number) Whether this kind of spell can be dispelled and the spell to use to do so.
function lib:CanDispel(unit, offensive, dispelType, spellID)
	local spell
	if offensive and UnitCanAttack("player", unit) then
		spell = (dispelType == "Magic" and self.offensive) or (self:IsEnrageEffect(spellID) and self.tranquilize)
	elseif not offensive and UnitCanAssist("player", unit) then
		spell = dispelType and self.defensive[dispelType]
	end
	return not not spell, spell or nil
end

-- ----------------------------------------------------------------------------
-- Iterators
-- ----------------------------------------------------------------------------

local function noop() end

local function buffIterator(unit, index)
	repeat
		index = index + 1
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura = UnitBuff(unit, index)
		local dispel = (dispelType == "Magic" and lib.offensive) or (spellID and lib.enrageEffectIDs[spellID] and lib.tranquilize)
		if dispel then
			return index, dispel, name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura
		end
	until not name
end

local function debuffIterator(unit, index)
	repeat
		index = index + 1
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff = UnitDebuff(unit, index)
		local spell = name and dispelType and lib.defensive[dispelType]
		if spell then
			return index, spell, name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff
		end
	until not name
end

--- Iterate through unit (de)buffs that can be dispelled by the player.
-- @name LibDispellable:IterateDispellableAuras
-- @param unit (string) The unit to scan.
-- @param offensive (boolean) true to test buffs instead of debuffs (offensive dispel).
-- @return A triplet usable in the "in" part of a for ... in ... do loop.
-- @usage
--   for index, spellID, name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff in LibDispellable:IterateDispellableAuras("target", true) do
--     print("Can dispel", name, "on target using", GetSpellInfo(spellID))
--   end
function lib:IterateDispellableAuras(unit, offensive)
	if offensive and UnitCanAttack("player", unit) and (self.offensive or self.tranquilize) then
		return buffIterator, unit, 0
	elseif not offensive and UnitCanAssist("player", unit) and next(self.defensive) then
		return debuffIterator, unit, 0
	else
		return noop
	end
end

--- Test if the given spell can be used to dispel something on the given unit.
-- @name LibDispellable:CanDispelWith
-- @param unit (string) The unit to check.
-- @param spellID (number) The spell to use.
-- @return true if the
-- @usage
--   if LibDispellable:CanDispelWith('focus', 4987) then
--     -- Tell the user that Cleanse (id 4987) could be used to dispel something from the focus
--   end
function lib:CanDispelWith(unit, spellID)
	local dispelType = spellID and self.spells[spellID]
	if UnitCanAttack("player", unit) then
		if dispelType == 'offensive' then
			for index = 1, math.huge do
				local name, _, _, _, dispelType = UnitBuff(unit, index)
				if not name then
					return false
				elseif dispelType == 'Magic' then
					return true
				end
			end
		elseif dispelType == 'tranquilize' then
			for index = 1, math.huge do
				local name, _, _, _, _, _, _, _, _, _, buffID = UnitBuff(unit, index)
				if not name then
					return false
				elseif self:IsEnrageEffect(buffID) then
					return true
				end
			end
		end
	elseif dispelType == 'defensive' and UnitCanAssist("player", unit) then
		for index = 1, math.huge do
			local name, _, _, _, dispelType = UnitDebuff(unit, index)
			if not name then
				return false
			elseif self.defensive[dispelType] == spellID then
				return true
			end
		end
	end
	return false
end

-- Initialization
if IsLoggedIn() then
	lib:UpdateSpells()
end
