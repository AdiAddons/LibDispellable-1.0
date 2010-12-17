--[[
LibDispellable-1.0 - Test whether the player can really dispell a buff or debuff, given its talents.
Copyright (C) 2009-2010 Adirelle

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

local MAJOR, MINOR = "LibDispellable-1.0", 2
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
	lib.eventFrame:RegisterEvent('PLAYER_TALENT_UPDATE')
end

-- ----------------------------------------------------------------------------
-- Data
-- ----------------------------------------------------------------------------

lib.defensive = lib.defensive or {}
lib.byName = lib.byName or {}

local rageEffects = {
	12292, -- Death Wish (Warrior)
	18499, -- Berserker Rage (Warrior)
	76691, -- Vengeance (all tanks)
	-- Actualy a tons**t of skills are named Enrage, let's hope most are dispellable...
	12880, -- Enrage (Warrior)
	57516, -- Enrage (Warrior)
	5229,  -- Enrage (Druid)
	72143, -- Enrage (Shambling Horror)
}

-- ----------------------------------------------------------------------------
-- Detect available dispel skiils
-- ----------------------------------------------------------------------------

local function CheckSpell(spellID, pet)
	return IsSpellKnown(spellID, pet) and spellID or nil
end

local function CheckTalent(tab, index)
	return (select(5, GetTalentInfo(tab, index)) or 0) >= 1
end

local function AddTranquilizingSpell(spellID)
	if IsSpellKnown(spellID) then
		for i, rageID in pairs(rageEffects) do
			local name = GetSpellInfo(rageID)
			if name then
				lib.byName[name] = spellID
			end
		end
	end
end

function lib:UpdateSpells()
	wipe(self.defensive)
	wipe(self.byName)
	self.offensive = nil

	local _, class = UnitClass("player")

	if class == "HUNTER" then
		self.offensive = CheckSpell(19801) -- Tranquilizing Shot
		AddTranquilizingSpell(19801) -- Tranquilizing Shot

	elseif class == "SHAMAN" then
		self.offensive = CheckSpell(370) -- Purge
		if IsSpellKnown(51886) then -- Cleanse Spirit
			self.defensive.Curse = 51886
			if CheckTalent(3, 12) then -- Improved Cleanse Spirit
				self.defensive.Magic = 51886
			end
		end

	elseif class == "WARLOCK" then
		self.offensive = CheckSpell(19505, true) -- Devour Magic (Felhunter)
		self.defensive.Magic = CheckSpell(89808, true) -- Singe Magic (Imp)

	elseif class == "MAGE" then
		self.defensive.Curse = CheckSpell(475) -- Remove Curse

	elseif class == "PRIEST" then
		self.offensive = CheckSpell(527) -- Dispel Magic
		self.defensive.Magic = self.offensive -- Dispel Magic
		self.defensive.Disease = CheckSpell(528) -- Cure Disease

	elseif class == "DRUID" then
		if IsSpellKnown(2782) then  -- Remove Corruption
			self.defensive.Curse = 2782
			self.defensive.Poison = 2782
			if CheckTalent(3, 17) then -- Nature's Cure
				self.defensive.Magic = 2782
			end
		end
		AddTranquilizingSpell(2908) -- Soothe

	elseif class == "ROGUE" then
		AddTranquilizingSpell(5938) -- Shiv

	elseif class == "PALADIN" then
		if IsSpellKnown(4987) then -- Cleanse
			self.defensive.Poison = 4987
			self.defensive.Disease = 4987
			if CheckTalent(1, 14) then -- Sacred Cleansing
				self.defensive.Magic = 4987
			end
		end
	end
end

-- ----------------------------------------------------------------------------
-- Simple query method
-- ----------------------------------------------------------------------------

--- Test if the player can dispel the spell with given.
-- @name LibDispellable:CanDispell
-- @param unit (string) The unit id on which the spell is.
-- @param dispelType (string) The dispel mechanisms, as returned by UnitAura.
-- @param name (string, optional) The buff name, used to test rage effects.
-- @return canDispell, spellID (boolean, number) Whether this kind of spell can be dispelled and the spell to use to do so.
function lib:CanDispel(unit, dispelType, name)
	local spell
	if UnitCanAttack("player", unit) then
		spell = (dispelType == "Magic" and self.offensive) or (name and self.byName[name])
	elseif UnitCanAssist("player", unit) then
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
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitAura(unit, index, "HELPFUL")
		local dispel = (dispelType == "Magic" and lib.offensive) or (name and lib.byBame[name])
		if dispel then
			return index, dispel, name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID
		end
	until not name
end

local function debuffIterator(unit, index)
	repeat
		index = index + 1
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitAura(unit, index, "HARMFUL")
		local spell = name and dispelType and lib.defensive[dispelType]
		if spell then
			return index, spell, name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID
		end
	until not name
end

--- Iterate through unit (de)buffs that can be dispelled by the player.
-- @name LibDispellable:IterateDispellableAuras
-- @param unit (string) The unit to scan.
-- @param offensive (boolean) true to test buffs instead of debuffs (offensive dispel).
-- @return A triplet usable in the "in" part of a for ... in ... do loop.
-- @usage
--   for index, spellID, name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID in LibDispellable:IterateDispellableAuras("target", true) do
--     print("Can dispel", name, "on target using", GetSpellInfo(spellID))
--   end
function lib:IterateDispellableAuras(unit, offensive)
	if offensive and UnitCanAttack("player", unit) and self.offensive then
		return buffIterator, unit, 0
	elseif not offensive and UnitCanAssist("player", unit) and next(self.defensive) then
		return debuffIterator, unit, 0
	else
		return noop
	end
end

-- Initialization
if IsLoggedIn() then
	lib:UpdateSpells()
end

