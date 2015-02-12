--[[
LibDispellable-1.0 - Test whether the player can really dispell a buff or debuff, given its talents.
Copyright (C) 2009-2013 Adirelle (adirelle@gmail.com)

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

local MAJOR, MINOR = "LibDispellable-1.0", 27
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

lib.buff = lib.buff or {}
lib.debuff = lib.debuff or {}
lib.specialIDs = wipe(lib.specialIDs or {})
lib.spells = lib.spells or {}

for _, id in ipairs({
	-- Datamined using fetchEnrageList.sh (see source)
	4146, 8599, 12880, 15061, 15716, 16791, 18499, 18501, 19451, 19812,
	22428, 23128, 23257, 23342, 24689, 26041, 26051, 28371, 29340, 30485,
	31540, 31915, 32714, 33958, 34392, 34670, 37605, 37648, 37975, 38046,
	38166, 38664, 39031, 39575, 40076, 40601, 41254, 41364, 41447, 42705,
	42745, 43139, 43292, 43664, 47399, 48138, 48142, 48193, 48702, 49029,
	50420, 50636, 51170, 51513, 52071, 52262, 52309, 52461, 52470, 52537,
	53361, 54356, 54427, 54475, 54781, 55285, 55462, 56646, 56729, 56769,
	57733, 58942, 59465, 59694, 59697, 59707, 59828, 60075, 60177, 60430,
	61369, 63147, 63227, 66092, 66759, 67233, 68541, 69052, 70371, 72143,
	72203, 75998, 76100, 76487, 76816, 76862, 77238, 78722, 78943, 79420,
	80084, 80158, 80467, 81173, 81706, 81772, 82033, 82759, 86736, 90045,
	91668, 101109, 101110, 102134, 102989, 106925, 108169, 109889, 111220,
	111418, 115006, 115430, 115639, 116863, 116958, 117837, 118139, 118507,
	119629, 120093, 123914, 123936, 124019, 124172, 124309, 124840, 124976,
	125738, 125864, 126075, 126254, 126370, 126410, 127823, 127955, 128006,
	128231, 128248, 128809, 129016, 129874, 130196, 130202, 131150, 132710,
	134983, 135524, 135548, 135569, 135698, 137334, 140108, 141663, 142760,
	145554, 145692, 145974, 148295, 148852, 150759, 151553, 151965, 153909,
	154017, 154543, 155198, 155208, 155620, 156314, 157346, 158304, 158337,
	158456, 159479, 159748, 161601, 163121, 163483, 164257, 164324, 164811,
	164835, 165512, 168620, 172360, 172781, 173238, 173950, 174427, 175192,
	175337, 175463, 175586, 175743, 176023, 176048, 176214, 176396, 177152,
	178658,
}) do lib.specialIDs[id] = 'tranquilize' end

-- Spells that do not have a dispel type according to Blizzard API
-- but that can be dispelled anyway.
lib.specialIDs[144351] = "Magic" -- Mark of Arrogance (Sha of Pride encounter)

-- ----------------------------------------------------------------------------
-- Detect available dispel skills
-- ----------------------------------------------------------------------------

local function CheckSpell(spellID, pet)
	return IsSpellKnown(spellID, pet) and spellID or nil
end

function lib:UpdateSpells()
	wipe(self.buff)
	wipe(self.debuff)

	local _, class = UnitClass("player")

	if class == "DEATHKNIGHT" then
		if IsPlayerSpell(58631) then -- Glyph of Icy Touch
			self.buff.Magic = 45477 -- Icy Touch
		end

	elseif class == "DRUID" then
		local cure = CheckSpell(88423) -- Nature's Cure
		local rmCorruption = CheckSpell(2782) -- Remove Corruption
		self.debuff.Magic = cure
		self.debuff.Curse = cure or rmCorruption
		self.debuff.Poison = cure or rmCorruption
		self.buff.tranquilize = CheckSpell(2908) -- Soothe

	elseif class == "HUNTER" then
		self.buff.Magic = CheckSpell(19801) -- Tranquilizing Shot
		self.buff.tranquilize = self.buff.Magic

	elseif class == "MAGE" then
		self.debuff.Curse = CheckSpell(475) -- Remove Curse
		self.buff.Magic = CheckSpell(30449) -- Spellsteal

	elseif class == "MONK" then
		self.debuff.Disease = CheckSpell(115450) -- Detox
		self.debuff.Poison = self.debuff.Disease
		if IsSpellKnown(115451) then -- Internal Medicine
			self.debuff.Magic = self.debuff.Disease
		end

	elseif class == "PALADIN" then
		if IsSpellKnown(4987) then -- Cleanse
			self.debuff.Poison = 4987
			self.debuff.Disease = 4987
			if IsSpellKnown(53551) then -- Sacred Cleansing
				self.debuff.Magic = 4987
			end
		end

	elseif class == "PRIEST" then
		self.buff.Magic = CheckSpell(528) -- Dispel Magic
		self.debuff.Magic = CheckSpell(527) -- Purify
		self.debuff.Disease = self.debuff.Magic

	elseif class == "ROGUE" then
		self.buff.tranquilize = CheckSpell(5938) -- Shiv

	elseif class == "SHAMAN" then
		self.buff.Magic = CheckSpell(370) -- Purge
		if IsPlayerSpell(77130) then -- Purify Spirit
			self.debuff.Curse = 77130
			self.debuff.Magic = 77130
		else
			self.debuff.Curse = CheckSpell(51886) -- Cleanse Spirit
		end

	elseif class == "WARLOCK" then
		self.buff.Magic = CheckSpell(19505, true) or CheckSpell(115284, true) -- Devour Magic (Felhunter) or Clone Magic (Observer)
		-- IsSpellKnown(132411)/IsPlayerSpell(132411) always return false, so we check the texture of Command Demon instead
		local _, _, texture = GetSpellInfo(119898) -- Command Demon
		if string.find(texture, "spell_fel_elementaldevastation") then
			self.debuff.Magic = 132411 -- Single Magic (sacrificed imp with Grimoire of Sacrifice talent)
		else
			self.debuff.Magic = CheckSpell(89808, true) or CheckSpell(115276, true) -- Singe Magic (Imp) or Sear Magic (Fel Imp)
		end
	end

	wipe(self.spells)
	if self.buff.Magic then
		self.spells[self.buff.Magic] = 'offensive'
	end
	if self.buff.tranquilize then
		self.spells[self.buff.tranquilize] = 'tranquilize'
	end
	for dispelType, id in pairs(self.debuff) do
		self.spells[id] = 'defensive'
	end

end

--- Test if the specified aura is an enrage effect.
-- @name LibDispellable:IsEnrageEffect.
-- @param spellID (number) The spell ID.
-- @return boolean true if the aura is an enrage.
function lib:IsEnrageEffect(spellID)
	return lib.specialIDs[spellID or false] == "tranquilize"
end

--- Get the actual dispel mechanism of an aura, including tranquilize and special cases.
-- @name LibDispellable:GetDispelType
-- @param dispelType (string) The dispel mechanism as returned by UnitAura
-- @param spellID (number) The spell ID
-- @return dispelType (string) The actual dispel mechanism
function lib:GetDispelType(dispelType, spellID)
	if spellID and lib.specialIDs[spellID] then
		return lib.specialIDs[spellID]
	elseif dispelType and dispelType ~= "none" and dispelType ~= "" then
		return dispelType
	end
end

--- Check if an aura can be dispelled by anyone.
-- @name LibDispellable:IsDispellable
-- @param dispelType (string) The dispel mechanism as returned by UnitAura
-- @param spellID (number) The spell ID
-- @return boolean True if the aura can be dispelled in some way
function lib:IsDispellable(dispelType, spellID)
	return self:GetDispelType(dispelType, spellID) ~= nil
end

--- Check which player spell can be used to dispel an aura.
-- @name LibDispellable:GetDispelSpell
-- @param dispelType (string) The dispel mechanism as returned by UnitAura
-- @param spellID (number) The spell ID
-- @param isBuff (boolean) True if the spell is a buff, false if it is a debuff.
-- @return number The spell ID of the dispel, or nil if the player cannot dispel it.
function lib:GetDispelSpell(dispelType, spellID, isBuff)
	local actualDispelType = self:GetDispelType(dispelType, spellID)
	return actualDispelType and self[isBuff and "buff" or "debuff"][actualDispelType]
end

--- Test if the player can dispel the given aura on the given unit.
-- @name LibDispellable:CanDispel
-- @param unit (string) The unit id.
-- @param isBuff (boolean) True if the spell is a buff.
-- @param dispelType (string) The dispel mechanism, as returned by UnitAura.
-- @param spellID (number) The aura spell ID, as returned by UnitAura, used to test enrage effects.
-- @return boolean true if the player knows a spell to dispel the aura.
-- @return number The spell ID of the spell to dispel, or nil.
function lib:CanDispel(unit, isBuff, dispelType, spellID)
	if (isBuff and not UnitCanAttack("player", unit)) or (not isBuff and not UnitCanAssist("player", unit))then
		return false
	end
	local spell = lib:GetDispelSpell(dispelType, spellID, isBuff)
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
		local spell = lib:GetDispelSpell(dispelType, spellID, true)
		if spell then
			return index, spell, name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura
		end
	until not name
end

local function allBuffIterator(unit, index)
	repeat
		index = index + 1
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura = UnitBuff(unit, index)
		if lib:IsDispellable(dispelType, spellID) then
			return index, lib:GetDispelSpell(dispelType, spellID, true), name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura
		end
	until not name
end

local function debuffIterator(unit, index)
	repeat
		index = index + 1
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff = UnitDebuff(unit, index)
		local spell = lib:GetDispelSpell(dispelType, spellID, false)
		if spell then
			return index, spell, name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff
		end
	until not name
end

local function allDebuffIterator(unit, index)
	repeat
		index = index + 1
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff = UnitDebuff(unit, index)
		if lib:IsDispellable(dispelType, spellID) then
			return index, lib:GetDispelSpell(dispelType, spellID, false), name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff
		end
	until not name
end

--- Iterate through unit (de)buffs that can be dispelled by the player.
-- @name LibDispellable:IterateDispellableAuras
-- @param unit (string) The unit to scan.
-- @param buffs (boolean) true to test buffs instead of debuffs (offensive dispel).
-- @param allDispellable (boolean) Include auras that can be dispelled even if the player cannot.
-- @return A triplet usable in the "in" part of a for ... in ... do loop.
-- @usage
--   for index, spellID, name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff in LibDispellable:IterateDispellableAuras("target", true) do
--     print("Can dispel", name, "on target using", GetSpellInfo(spellID))
--   end
function lib:IterateDispellableAuras(unit, buffs, allDispellable)
	if buffs and UnitCanAttack("player", unit) and (allDispellable or next(self.buff)) then
		return (allDispellable and allBuffIterator or buffIterator), unit, 0
	elseif not buffs and UnitCanAssist("player", unit) and (allDispellable or next(self.debuff)) then
		return (allDispellable and allDebuffIterator or debuffIterator), unit, 0
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
	for index, spell in self:IterateDispellableAuras(unit, UnitCanAttack("player", unit)) do
		if spell == spellID then
			return true
		end
	end
	return false
end

--- Test if player can dispel anything.
-- @name LibDispellable:HasDispel
-- @return boolean true if the player has any spell that can be used to dispel something.
function lib:HasDispel()
	return next(self.spells)
end

--- Get an iterator of the dispel spells.
-- @name LibDispellable:IterateDispelSpells
-- @return a (iterator, data, index) triplet usable in for .. in loops.
--  Each iteration returns a spell id and the general dispel type: "offensive", "tranquilize" or "debuff"
function lib:IterateDispelSpells()
	return next, self.spells, nil
end

-- Initialization
if IsLoggedIn() then
	lib:UpdateSpells()
end
