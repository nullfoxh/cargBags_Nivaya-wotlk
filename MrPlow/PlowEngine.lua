
-- The engine behind the movement of the items. This should take simple
-- arguments and move the items as per requirement.



local PlowEngine = MrPlow.PlowEngine
local PlowScheduler = MrPlow.PlowScheduler

local db 
local getTable = MrPlow.getTable
local returnTable = MrPlow.returnTable
MrPlow.currentProcess = nil
local currentProcess = MrPlow.currentProcess
local BagList = {}
local CurrentMove = nil

local Clean  = getTable()
local GuildBanking = false

local L = LibStub("AceLocale-3.0"):GetLocale("MrPlow", true)

local PT = LibStub("LibPeriodicTable-3.1")

local infoFunc = GetContainerItemInfo
local linkFunc = GetContainerItemLink
local pickFunc = PickupContainerItem
local splitFunc = SplitContainerItem

function PlowEngine:Enable()
	db = MrPlow.db.profile
	PlowEngine:SetScript("OnUpdate", PlowEngine.OnUpdate)
	PlowScheduler:SetScript("OnUpdate", PlowScheduler.OnUpdate)
end

local sortCategories = {"Consumable.Potion", 
						"Consumable.Warlock",
						"Consumable.Water.Basic", 
						"Consumable.Water.Conjured", 
						"Consumable.Food.Edible.Bread.Conjured",
						"Consumable.Weapon Buff.Poison", 
						"Consumable.Weapon Buff.Stone", 
						"Consumable.Weapon Buff.Oil",
						}

local itemCategories = {
	ARMOR = 1,
	WEAPON = 2,
	QUEST = 3,
	KEY = 4,
	RECIPE = 5,
	REAGENT = 6,
  GEM = 7,
	TRADEGOODS = 8,
	CONSUMABLE = 9,
	GLYPH = 10,
	CONTAINER = 11,
	QUIVER = 12,
	MISCELLANEOUS = 13,
	PROJECTILE = 14
}

local itemRanking = {
	[L["Armor"]] = itemCategories.ARMOR,
	[L["Weapon"]] = itemCategories.WEAPON,
	[L["Quest"]] = itemCategories.QUEST,
	[L["Key"]] = itemCategories.KEY,
	[L["Recipe"]] = itemCategories.RECIPE,
	[L["Reagent"]] = itemCategories.REAGENT,
  [L["Gem"]] = itemCategories.GEM,
	[L["Glyph"]] = itemCategories.GLYPH,
	[L["Consumable"]] = itemCategories.CONSUMABLE,
	[L["Container"]] = itemCategories.CONTAINER,
	[L["Quiver"]] = itemCategories.QUIVER,
	[L["Miscellaneous"]] = itemCategories.MISCELLANEOUS,
	[L["Projectile"]] = itemCategories.PROJECTILE,
	[L["Trade Goods"]] = itemCategories.TRADEGOODS 
}
local specialBagContents = {
	["Misc.Bag.Special.Ammo"]			=	"Reagent.Ammo.Bullet",
	["Misc.Bag.Special.Quiver"]			=	"Reagent.Ammo.Arrow",
	["Misc.Bag.Special.Enchanting"]		=	"Misc.Container.ItemsInType.Enchanting",
	["Misc.Bag.Special.Engineering"]		=	"Misc.Container.ItemsInType.Engineering",
	["Misc.Bag.Special.Herb"]			=	"Misc.Container.ItemsInType.Herb",
	["Misc.Bag.Special.Jewelcrafting"]	=	"Misc.Container.ItemsInType.Gem",
	["Misc.Bag.Special.Mining"]			=	"Misc.Container.ItemsInType.Mining",
	["Misc.Bag.Special.Soul Shard"]		=	"Misc.Container.ItemsInType.Soul Shard",
	["Misc.Bag.Special.Inscription"] = "Misc.Container.ItemsInType.Inscription"
}

-- Trade Good sorting
local ingredientRanking = {
	-- Mining Blacksmithing
	["Tradeskill.Mat.ByType.Ore"]=						1,
	["Tradeskill.Mat.ByType.Stone"]=					2,
	["Tradeskill.Mat.ByType.Bar"]=						3,
	["Tradeskill.Mat.ByType.Grinding Stone"]= 4,
	-- Tailoring
	["Tradeskill.Mat.ByType.Thread"]=					5,
	["Tradeskill.Mat.ByType.Spider Silk"]=		6,
	["Tradeskill.Mat.ByType.Cloth"]=					7,
	["Tradeskill.Mat.ByType.Bolt"]=						8,
	["Tradeskill.Mat.ByType.Dye"]=						9,
	-- Enchanting
	["Tradeskill.Mat.ByType.Rod"]=						10,
	["Tradeskill.Mat.ByType.Essence"]=				11,
	["Tradeskill.Mat.ByType.Shard"]=					12,
	["Tradeskill.Mat.ByType.Dust"]=						13,
	-- Engineering
	["Tradeskill.Mat.ByType.Part"]=						14,
	["Tradeskill.Mat.ByType.Flux"]=						15,
	["Tradeskill.Mat.ByType.Powder"]=					16,
	-- Jewelcrafting
	["Tradeskill.Mat.ByType.Gem"]=						17,
	["Tradeskill.Mat.ByType.Pearl"]=					18,
	-- Herbalism Alchemy
	["Tradeskill.Mat.ByType.Herb"]=						19,
	["Tradeskill.Mat.ByType.Oil"]=						20,
	["Tradeskill.Mat.ByType.Vial"]=						21,
	-- Leatherworking
	["Tradeskill.Mat.ByType.Leather"]=				22,
	["Tradeskill.Mat.ByType.Hide"]=						23,
	["Tradeskill.Mat.ByType.Scale"]=					24,
	["Tradeskill.Mat.ByType.Salt"]=						25,
	-- Inscription
	["Tradeskill.Mat.ByType.Pigment"]=				26,
	["Tradeskill.Mat.ByType.Ink"]=						27,
	["Tradeskill.Mat.ByType.Parchment"]=			28,
	-- Cooking
	["Tradeskill.Mat.ByType.Spice"]=					29,
	-- Elemental
	["Tradeskill.Mat.ByType.Elemental"]=			30,
	["Tradeskill.Mat.ByType.Mote"]=						31,
	["Tradeskill.Mat.ByType.Primal"]=					32,
	["Tradeskill.Mat.ByType.Crystallized"]=		33,
	["Tradeskill.Mat.ByType.Eternal"]=				34,
	-- Nether/orbs/etc
	["Tradeskill.Mat.ByType.Crystal"]=				35,
}

local maxSort = 36 -- Default to this

local armWepRank = {
	INVTYPE_HEAD = 1,
	INVTYPE_NECK = 2,
	INVTYPE_SHOULDER = 3,
	INVTYPE_BODY = 4,
	INVTYPE_CHEST = 5,
	INVTYPE_ROBE = 5,
	INVTYPE_WAIST = 6,
	INVTYPE_LEGS = 7,
	INVTYPE_FEET = 8,
	INVTYPE_WRIST = 9,
	INVTYPE_HAND = 10,
	INVTYPE_FINGER = 11,
	INVTYPE_TRINKET = 12,
	INVTYPE_CLOAK = 13,
	INVTYPE_WEAPON = 14,
	INVTYPE_SHIELD = 15,
	INVTYPE_2HWEAPON = 16,
	INVTYPE_WEAPONMAINHAND = 18,
	INVTYPE_WEAPONOFFHAND = 19,
	INVTYPE_HOLDABLE = 20,
	INVTYPE_RANGED = 21,
	INVTYPE_THROWN = 22,
	INVTYPE_RANGEDRIGHT = 23,
	INVTYPE_AMMO = 24,
	INVTYPE_RELIC = 25,
	INVTYPE_TABARD = 26,
}
local maxRank = 27

local PlowList = nil -- getTable() -- Storage for the Joblisting

local JobQueue = getTable() -- Storage for the jobQueue

PlowEngine:Hide() -- Prevent update
PlowScheduler:Hide()

-- This function is to take a function and a list of bags, and process them
-- intelligently, ie, move all profession bags out as separate processes and
-- deal with them after the main batch as a separate job
function PlowEngine:RunJob(PlowFunction, ...)
	local FullBagList = {}
	local NormalBags = {}
	local SpecialBags = {}
	
	if currentProcess then return end

	if select("#", ...) > 1 then
		FullBagList = getTable(...)
	end

	for _,v in ipairs(FullBagList) do
			if v > 0 and 
					GetInventoryItemLink("player", ContainerIDToInventoryID(v)) and 
					PT:ItemInSet(GetInventoryItemLink("player", ContainerIDToInventoryID(v)), "Misc.Bag.Special") then
				table.insert(SpecialBags, v)
			else
				table.insert(NormalBags, v)
			end
	end

	if not currentProcess then
		if not JobQueue then JobQueue = getTable() end	
		PlowList = getTable()
		if PlowFunction == PlowEngine.Consolidate then
			if #SpecialBags > 0 then
				for i,v in ipairs(SpecialBags) do
					table.insert(JobQueue, { PlowFunction, self, NormalBags, {v}})
				end
			end
			return
		end
		if #NormalBags > 0 then
			table.insert(JobQueue, { PlowFunction, self, NormalBags})
		end
		if #SpecialBags > 0 then
			for i,v in ipairs(SpecialBags) do
				table.insert(JobQueue, {PlowFunction, self, {v}})
			end
		end
	end

	infoFunc = GetContainerItemInfo
	linkFunc = GetContainerItemLink
	pickFunc = PickupContainerItem
	splitFunc = SplitContainerItem
	GuildBanking = false
end

function PlowEngine:RunGuildBankJob(PlowFunction)
	if not currentProcess then
		if not JobQueue then JobQueue = getTable() end
		PlowList = getTable()
		table.insert(JobQueue, {PlowFunction, self, {GetCurrentGuildBankTab()}})
		infoFunc = GetGuildBankItemInfo
		linkFunc = GetGuildBankItemLink
		pickFunc = PickupGuildBankItem
		splitFunc = SplitGuildBankItem
		GuildBanking = true
	end
end
-- This function is to move items into other bags, be they bank bags or specifically to 
-- special bags, like herb/enchant/etc. Quite simply, fill up all the spots in the BagsTo
-- with items from BagsFrom (if it fits).
-- Requirements: The bags in BagsTo are all of the same type. Which means that depending on
-- how this is called, we will have to subseparate the bags into their special types.
--
-- Consolidate is direction agnostic
function PlowEngine:Consolidate(BagsFrom, BagsTo)
	local empty = getTable()
	-- Find out how much space we have
	for bag, slot in self:NextSlot(BagsTo) do
		if not GetContainerItemLink(bag, slot) then -- we're empty
			table.insert(empty, getTable(bag, slot))
		end
	end
	-- Now check if we're speshul.
	local isSpecial, bagType = PT:ItemInSet(GetInventoryItemLink("player", ContainerIDToInventoryID(BagsTo[1])), "Misc.Bag.Special")
	if isSpecial then
		for bag, slot in self:NextSlot(BagsFrom) do
			if #empty > 0 then -- if there's room...
				local link = select(3, (GetContainerItemLink(bag, slot) or ""):find("item:(%d+):"))
				if link and PT:ItemInSet(link, specialBagContents[bagType]) then
					local freeslot = table.remove(empty,1)
					PlowEngine:MoveSlot(bag, slot, 0, freeslot[1], freeslot[2])
				end
			end
		end
	end
	-- Now run	
	if #PlowList > 0 then
		PlowEngine:Show()
	else
		MrPlow.currentFunction = nil
		currentProcess = nil
		returnTable(empty)
	end 
end

-- This function finds non-empty stacks of the same item, and restacks them so
-- that it fills the least number of slots possible, with the remaining
-- unempty stack at the head of the line so that any auto insertion/removal (looting,
-- ammo usage, spell component usage etc) will use that non-full stack rather
-- than a full one, maintaining the compression as much as possible.
--
-- Restack is direction agnostic
function PlowEngine:Restack(...)
	local db = MrPlow.db.profile
	local notFull = getTable()
	local dupe = getTable()

	if select("#", ...) > 0 then
		BagList = getTable(...)
		if BagList[1] == self then 
			table.remove(BagList, 1)
		end
	end

	for bag, slot in self:NextSlot(BagList, true) do	
		while true do --If we're locked, yield til we're not
			if(select(3, infoFunc(bag,slot))) then
				if not PlowEngine:IsShown() then PlowEngine:Show() end
				coroutine.yield(self)
			else
				break;
			end
		end	
		local link = select(3, (linkFunc(bag, slot) or ""):find("item:(%d+):"))
		if link then
			if not db.IgnoreItems[link] then -- if we're not ignoring this specific item
				local stackSize = select(2, infoFunc(bag, slot))
				local fullStack = select(8, GetItemInfo(link))
				if not dupe[link] then
					dupe[link] = getTable()
				end
				table.insert(dupe[link], getTable(bag, slot, stackSize, fullStack))
			end
		end
	end
	--
	--Well, now we have two lists. notFull, which ostensibly lists the
	--items that have duplicates, and stores the last position found that does
	--not have a full stack. And dupe, which stores all the stacks previous to
	--the one marked in notFull that are not full in forward order.
	
	-- So we now move through the lists and restack as required. Take from the
	-- first of the duplicate stacks, and move it to the 'notFull' last stack.
	-- This way we fill all stacks from the end back, leaving the uneven stack
	-- at the front of the list
	--
	
	local function GetLastUnfilled(stack)
		for i=#stack,1,-1 do
			if stack[i][3] < stack[i][4] then
				return i
			end
		end
		return -1
	end

	local function GetFirstNonempty(stack)
		for i=1,#stack do
			if stack[i][3] > 0 then
				return i
			end
		end
		return -1
	end

	for item, stacks in pairs(dupe) do
		while #stacks > 0 do
			-- Each dupe has {Bag, Slot, Current Stack Size, Max Stack Size}
			local target = GetLastUnfilled(stacks)
			local source = GetFirstNonempty(stacks)
			
			if target < 0 or target <= source then -- If we're have no unfilled stacks or if the last unfilled is the same as the first nonempty
				break;
			end
			
			target, source = stacks[target], stacks[source]

			local toFill = target[4] - target[3]
			
			if source[3] < toFill then
				-- if we can't fill the final stack, move the whole first stack
				-- across
				PlowEngine:MoveSlot(source[1], source[2], source[3], target[1], target[2])
				target[3] = target[3] + source[3]
				source[3] = 0
			else
				-- if we -can- totally fill the final stack with leftovers
				-- move what we can across
				PlowEngine:MoveSlot(source[1], source[2], toFill, target[1], target[2])
				target[3] = target[3] + toFill 
				source[3] = source[3] - toFill
			end
		end
	end
   -- Now run	
	if #PlowList > 0 then
		currentProcess = PlowEngine.Restack
		PlowEngine:Show()
	else
		MrPlow.currentFunction = nil
		currentProcess = nil
		returnTable(dupe)
		returnTable(notFull)
	end --]]
end


function PlowEngine:Defragment(...)
	local db = MrPlow.db.profile
	local full = getTable()
	local empty = getTable()

	if select("#", ...) > 0 then
		BagList = getTable(...)
	end
	for bag, slot in self:NextSlot(BagList) do
		local link = select(3, (linkFunc(bag, slot) or ""):find("item:(%d+):"))
		if not link then -- empty slot
			table.insert(empty, getTable(bag, slot))
		elseif not db.IgnoreItems[link] then -- if full and not ignored
			table.insert(full, 1, getTable(bag, slot))
		end
	end            
	-- Now we have two lists. Depending on where we want the empty space (at
	-- the top or bottom) we have a list of empty spaces and a list of full
	-- spaces going in the opposite direction. Now we take from the full list,
	-- and move each item into the empty list. 
	
	while next(full) do
		local loose = table.remove(full, 1) -- get the last full slot
		local space = table.remove(empty, 1) -- and the first available empty slot
		local lPosition, sPosition
		
		if loose and space then
			lPosition = 100* loose[1] + loose[2]
			sPosition = 100* space[1] + space[2]
		end
		-- Now if the space is past the item (depending on which direction
		-- we're defragging in...) 
		if (not loose or not space) or -- We don't have anything to move or place to move it
			(sPosition > lPosition and db.EmptySpace ~= "Top") 
			or (sPosition < lPosition and db.EmptySpace == "Top") then -- We've crossed over the midpoint
		   
			if loose then
				returnTable(loose)
			end
			if space then
				returnTable(space)
			end
			returnTable(empty)
			returnTable(full)
			break
		end
		-- Otherwise, move away!
		PlowEngine:MoveSlot(loose[1], loose[2], -1, space[1], space[2])
   end
   -- Now run	
	if #PlowList > 0 then
		currentProcess = PlowEngine.Defragment
		PlowEngine:Show()
	else
		currentProcess = nil
		returnTable(empty)
		returnTable(full)
	end
   
end

-----------------Sort Functions -----------------------------------------
-- Better to define them locally outside the function so they're only created 
-- once rather than every time the function is run. I'm kinda considering a
-- cascading set of sort functions so it goes through the top level and
-- filters down until if there's no rule, it sticks to alphabetical, and then
-- stacksize. Separating them out into different functions makes it easier to
-- insert finer grain filters at a later date.
--
-- Lets see:
--					ID
--          Alpha
--          Rarity
--          Location
--          PT-Categorical (tradegoods etc)
--          Specific PT (conjured)
--          ItemRank
--          Junk - Top level check
local watch = {}

function SortItemID(a,b)
	return a.itemID < b.itemID
end

function SortAlpha(a,b)
	if a.itemName == b.itemName then
		local pass, ret = pcall(function() return SortItemID(a,b) end)
		if pass then
			return ret
		else
			ErrorPrint(a,b, "SortItemId: "..ret)
			return true
		end
	end
	if watch[a.itemID] and watch[b.itemID] then
		MrPlow:Print("Alpha: "..a.itemName.." vs "..b.itemName)
	end
	return a.itemName < b.itemName
end

function SortILevel(a, b)
	if a.itemLevel == b.itemLevel or (a.GlyphType and b.GlyphType and a.itemType == "Glyph") then
		local pass, ret = pcall(function() return SortAlpha(a,b) end)
		if pass then
			return ret
		else
			ErrorPrint(a,b, "SortAlpha: "..ret)
			return true
		end
	end
	if watch[a.itemID] and watch[b.itemID] then
		MrPlow:Print("iLevel: "..a.itemName.." - "..a.itemLevel.." vs "..b.itemLevel.." - "..b.itemName)
	end
	return a.itemLevel > b.itemLevel
end


function SortGlyphType(a, b)
	if not(a.GlyphType and b.GlyphType) or a.GlyphType == b.GlyphType then
		local pass, ret = pcall(function() return SortILevel(a,b) end)
		if pass then return ret
		else 
			ErrorPrint(a,b, "SortILevel: "..ret)
			return true
		end
	end
	return a.GlyphType < b.GlyphType
end


function SortSubType(a, b)
	if a.itemSubType == b.itemSubType then
		local pass, ret = pcall(function() return SortGlyphType(a,b) end)
		if pass then
			return ret
		else
			ErrorPrint(a,b, "SortGlyphType: "..ret)
			return true
		end
	end
	if watch[a.itemID] and watch[b.itemID] then
		MrPlow:Print("subType: "..a.itemName.." - "..a.itemSubType.." vs "..b.itemSubType.." - "..b.itemName)
	end
	return a.itemSubType < b.itemSubType
end


function SortRarity(a, b)
	if a.itemRarity == b.itemRarity then
		local pass, ret = pcall(function() return SortSubType(a,b) end)
		if pass then 
			return ret
		else
			ErrorPrint(a,b,"SortSubType: "..ret)
			return true
		end
	end
	if watch[a.itemID] and watch[b.itemID] then
		MrPlow:Print("Rarity: "..a.itemName.." - "..a.itemRarity.." vs "..b.itemRarity.." - "..b.itemName)
	end
	return a.itemRarity > b.itemRarity
end

function SortLocation(a, b)
	if (a.itemArmWepRanking == b.itemArmWepRanking) then
		local pass, ret = pcall(function() return SortRarity(a, b) end)
		if pass then 
			return ret
		else
			ErrorPrint(a,b,"SortRarity: "..ret)
			return true
		end
	end
	if watch[a.itemID] and watch[b.itemID] then
		MrPlow:Print("Location: "..a.itemName.." - "..a.itemEquipLoc..a.itemArmWepRanking.." vs "..b.itemArmWepRanking..b.itemEquipLoc.." - "..b.itemName)
	end

	return a.itemArmWepRanking < b.itemArmWepRanking 
end

-- By this time, we're the same type of item so we only need to check one of
-- the inputs for details 
-- We're only going to subsort within the tradegoods and consumable category
-- so far as they're the only ones that are badly grouped and require PT
-- assistance to get viable results.
local TradeGoods = { [L["Trade Goods"]] = true, [L["Gem"]] = false }

function SortPTCategory(a, b)
	if (not(TradeGoods[a.itemType] and TradeGoods[b.itemType])) then
		return SortLocation(a, b)
	end

	local aTG, aSet =	PT:ItemInSet(a.itemID, "Tradeskill.Mat.ByType")
	local bTG, bSet =	PT:ItemInSet(b.itemID, "Tradeskill.Mat.ByType")
	
		local aRank = ingredientRanking[aSet] or maxSort
		local bRank = ingredientRanking[bSet] or maxSort

		if watch[a.itemID] and watch[b.itemID] then
			MrPlow:Print("Set: "..a.itemName.." - "..aRank.." vs "..bRank.." - "..b.itemName)
		end
		if aRank == bRank then
			local pass, ret = pcall(function() return SortLocation(a, b) end)
			if pass then
				return ret
			else
				ErrorPrint(a,b, "SortLocation: "..ret)
				return true
			end
		else
			return aRank < bRank
		end
end

function SortSpecificPT(a, b)
	local aSet, bSet
	-- Step through each of the special consumable categories, and assign the first available
	for i=1,#sortCategories do
		aSet = select(2, PT:ItemInSet( a.itemID, sortCategories[i])) 
		if aSet then break end
	end
	for i=1,#sortCategories do
		bSet = select(2, PT:ItemInSet( b.itemID, sortCategories[i])) 
		if bSet then break end
	end
	
	if not aSet and not bSet then
		local pass, ret = pcall(function() return SortPTCategory(a,b) end)
		if pass then 
			return ret
		else
			ErrorPrint(a,b,"PTCat: "..ret)
			return true
		end
	end

	-- Same type? Then filter further
	if aSet then a.Set = aSet end
	if bSet then b.Set = bSet end

	if watch[a.itemID] and watch[b.itemID] then
		MrPlow:Print("Set: "..a.itemName.." - "..aSet.." vs "..bSet.." - "..b.itemName)
	end
	if aSet == bSet then 
		return SortLocation(a, b)
		--One in the special group and the other not? Special group has priority to be at the end
	elseif (aSet and not bSet) or (not aSet and bSet) then 
		return (aSet and 1 or -1) > (bSet and 1 or -1)
	elseif aSet and bSet then
		return aSet < bSet
	end
end

function SortItemRanking(a,b)
	if a.itemRanking == b.itemRanking then
		local pass, ret = pcall(function() return SortSpecificPT(a, b) end)
		if pass then 
			return ret
		else
			ErrorPrint(a,b,"Specific PT: "..ret)
			return true
		end
	end
	if watch[a.itemID] and watch[b.itemID] then
		MrPlow:Print("Ranking: "..a.itemName.." - "..a.itemRanking.." vs "..b.itemRanking.." - "..b.itemName)
	end
	return a.itemRanking < b.itemRanking
end

-- Does this actually work? I'm trying to drop the junk at the end of the
-- grouping, depending on where the empty space is set to be at the top or
-- bottom. If A is not junk, and B is, A is less than B. If A is junk and
-- B isn't then A is greater than B.
function SortJunk(a, b)
	if (a.itemRarity > 0 and b.itemRarity > 0) or (a.itemRarity == b.itemRarity) then
		local pass, ret = pcall(function() return SortItemRanking(a,b) end)
		if pass then 
			return ret
		else
			ErrorPrint(a,b,"Item Ranking: "..ret)
			return true
		end
	else
		return a.itemRarity > b.itemRarity
	end
end

function TopLevelSort(a,b)
	if a and b then
		local pass, ret = pcall(function() return SortJunk(a,b) end)
		if pass then
		if watch[a.itemID] and watch[b.itemID] then
			MrPlow:Print("Return is "..a.itemName.." is " ..(ret and "less than " or "more than ")..b.itemName)
		end
			return ret
		else
			ErrorPrint(a,b,"Junk: "..ret)
			return true
		end
	else
		return true
	end
end

function ErrorPrint(a,b,func)
	MrPlow:Print("Error in "..func.." between "..a.itemName.." at "..a.bag..":"..a.slot.." and "..b.itemName.." at "..b.bag..":"..b.slot)
end

local Item = getTable()

Item.mt = getTable()

Item.mt.__lt = function(a, b)
    return TopLevelSort(a,b)
end

Item.mt.__eq = function(a, b)
		if watch[a.itemID] and watch[b.itemID] then
			MrPlow:Print("Equating stuff")
		end
	if a.itemID == b.itemID then
		return true
	else
		return false
	end
end


local function GlyphType(a)
	if strfind(a.itemTexture, "INV_Glyph_Major") then
		a.GlyphType = 0
	else
		a.GlyphType = 1
	end
end

Item.new = function(position, ItemID, bag, slot)
	local item = getTable()
	local tbag = bag
	setmetatable(item, Item.mt)
  item.pos = position
	item.itemName, item.itemLink, item.itemRarity, item.itemLevel, item.itemMinLevel, 
	item.itemType, item.itemSubType, item.itemStackCount, item.itemEquipLoc, item.itemTexture = GetItemInfo(ItemID)
	item.itemID = ItemID 
  item.itemRanking = itemRanking[item.itemType]
  if not item.itemRanking then item.itemRanking = -1 end
	item.itemArmWepRanking = armWepRank[item.itemEquipLoc]
	if not item.itemArmWepRanking then item.itemArmWepRanking = maxRank end
	item.bag = bag
	item.slot = slot
	item.Set = item.itemEquipLoc
	if item.itemType == "Glyph" then GlyphType(item) end
	return item
end


-- The new mass movement sort. Kinda a binary sort in regards to movement.
-- This will be a whole lot more CPU intensive as it's not predetermining
-- the movement path, but depending on the current layout to determine what
-- needs to be moved. Experimental.
--
-- Okay, here's the information we have
--
-- Current Bag/Slot
-- Current Position
-- Sorted Position
-- Sorted Bag/Slot
--
-- What we need is to check that what we're swapping with isn't already where it's supposed to be.
function PlowEngine:MassSort(...)
  local Current = getTable()
  local Sorted = getTable()
  local Dirty  = getTable()
	local itemPosition = 0	
	if select("#", ...) > 0 then
		BagList = getTable(...)
		Clean = getTable() 
	end
	for bag, slot in self:NextSlot(BagList) do 
		if not (db.IgnoreSlots[bag] and db.IgnoreSlots[bag][slot]) then
			while true do
				if(select(3, infoFunc(bag,slot))) then
					if not PlowEngine:IsShown() then PlowEngine:Show() end
					coroutine.yield(self)
				else
					break;
				end
			end				
			local link = select(3, (linkFunc(bag, slot) or ""):find("item:(%d+)"))
			if link and not db.IgnoreItems[link] then
				local item = Item.new(itemPosition, link, bag, slot)
				table.insert(Sorted, item)
				table.insert(Current, getTable(bag, slot, item))
				table.insert(Dirty, false);
				itemPosition = itemPosition + 1
			end
		end
	end
	table.sort(Sorted)

	local function GetLast(item)
		for i=#Current,1,-1 do
			if not Dirty[i] and Current[i][3] == item then -- If we've not moved and matched the item
				return i
			end
		end
		return -1
	end

	for i=1,#Sorted do
	  local item = Sorted[i]
		if item ~= Current[i][3] then -- if the item isn't already in this position
			if not Dirty[i] then
				local Match = GetLast(item)
				if Match > 0 then
					PlowEngine:MoveSlot(Current[i][1], Current[i][2], -1, Current[Match][1], Current[Match][2])
					Dirty[i] = true
					Dirty[Match] = true
				end
			else
				Dirty[i] = true
			end
		else
			Dirty[i] = true; -- We're in the right place already so mark this not to be moved
		end
  end
	
	returnTable(Dirty)
	returnTable(Sorted)
	returnTable(Current)

	if #PlowList > 0 then
		currentProcess = PlowEngine.MassSort
		PlowEngine:Show()
	else
		currentProcess = nil
		returnTable(BagList)
		returnTable(Clean)
	end
end


-- separated out for later refactoring in regards to job control
function PlowEngine:MoveSlot(fromBag, fromSlot, amount, toBag, toSlot)
	table.insert(PlowList, getTable(fromBag, fromSlot, amount, toBag, toSlot))
end



function PlowEngine:CheckMove(fromBag, fromSlot, amount, toBag, toSlot)

	while true do
		local _, _, locked1 = infoFunc(fromBag, fromSlot)
		local _, _, locked2 = infoFunc(toBag, toSlot)
		if locked1 or locked2 or (GuildBanking and Paused < 0.2) then
			coroutine.yield(self, fromBag, fromSlot, amount, toBag, toSlot)
		else
			if GuildBanking then Paused = 0 end
			break
		end
	end

	-- Grab either a part, or the whole of a particular slot
	if amount > 0 then
		splitFunc(fromBag, fromSlot, amount)
	else
		pickFunc(fromBag, fromSlot)
	end

	-- Drop it in the target
	if GetCursorInfo() then
		pickFunc(toBag, toSlot)
	end
end

function PlowScheduler.OnUpdate(self, elapsed, ...)
	if not currentProcess then 
		if JobQueue then
			if #JobQueue == 0 then 
				JobQueue = nil
				PlowEngine:Hide()
				PlowScheduler:Hide()
				return
			end
			if #JobQueue > 0 then
				local nextCall = table.remove(JobQueue, 1)
				if(#nextCall > 3) then
					nextCall[1](nextCall[2], nextCall[3], nextCall[4])
				else
					nextCall[1](nextCall[2], unpack(nextCall[3]))
				end
				return
			end
		end
	end
end

function PlowEngine.OnUpdate(self, elapsed, ...)		
	
	if not currentProcess then return end
	if GuildBanking then -- oh god delaaaay
		Paused = (Paused or 0) + elapsed
	end

	-- If we have bags to operate on, and PlowList is empty and we're not currently working on a suspended move, then run again.:
	if sortbags and coroutine.status(sortbags) == "suspended" then
		coroutine.resume(sortbags)
		return
	end
	if BagList and #BagList > 0 and #PlowList == 0 and midmove and coroutine.status(midmove) == "dead" then
		sortbags = coroutine.create(currentProcess)
		coroutine.resume(sortbags, self)
	end
	if not midmove or coroutine.status(midmove) == "dead" then 
		if #PlowList > 0 then
			CurrentMove = table.remove(PlowList, 1)
			midmove = coroutine.create(self.CheckMove)
		end
	else
		coroutine.resume(midmove, self, CurrentMove[1], CurrentMove[2], CurrentMove[3], CurrentMove[4], CurrentMove[5]) 
	end
end

-- coroutine iterator for bag lists
-- Basically this will take a list of bags to create an iterator for, and, depending on what -sort- of 'bag', ie
-- inventory, or guildbank will return the appropriate -next- [bag|tab]/slot
-- 51-56 will be guildbankslots
function PlowEngine:ProcessBags(BagList, BagIndex, Slot)
	local maxSlot
	
	if GuildBanking then
		maxSlot = 98
	else
		maxSlot = GetContainerNumSlots(BagList[BagIndex])
	end
	if MrPlow:IsIgnored(BagList[BagIndex]) then
		return PlowEngine:ProcessBags(BagList, BagIndex + 1, 0)
	end

	if MrPlow:IsIgnored(BagList[BagIndex], Slot, GuildBanking) then
		return PlowEngine:ProcessBags(BagList, BagIndex, Slot + 1)
	end

	if Slot < maxSlot then
		return BagIndex, BagList[BagIndex], Slot + 1
	else
		if BagIndex < #BagList then
			return BagIndex + 1, BagList[BagIndex + 1], 1
		else
			return
		end
	end
end

function PlowEngine:ReverseProcessBags(BagList, BagIndex, Slot)
	local maxSlot
	if GuildBanking then
		maxSlot = 98
	else
		if BagIndex > 1 then
			maxSlot = GetContainerNumSlots(BagList[BagIndex - 1])		
		end
	end
	
	if MrPlow:IsIgnored(BagList[BagIndex]) or GetContainerNumSlots(BagList[BagIndex]) == 0 then
		return PlowEngine:ReverseProcessBags(BagList, BagIndex - 1, GetContainerNumSlots(BagList[BagIndex - 1]))
	end

	if MrPlow:IsIgnored(BagList[BagIndex], Slot, GuildBanking) then
		return PlowEngine:ReverseProcessBags(BagList, BagIndex, Slot - 1)
	end

	if Slot > 1 then
		return BagIndex, BagList[BagIndex], Slot - 1
	else
		if BagIndex > 1 then
			return BagIndex -1, BagList[BagIndex - 1], maxSlot
		else
			return
		end
	end
end

function PlowEngine:NextSlot(BagList, ForceForward)
	local bagindex, slot, bag = 1, 0
	local sortFunc = self.ProcessBags

	if db.EmptySpace == "Top"  and not ForceForward then 
		sortFunc = self.ReverseProcessBags 
		bagindex, slot = #BagList, GetContainerNumSlots(BagList[#BagList]) + 1
	end

	return function()
		bagindex, bag, slot = sortFunc(self, BagList, bagindex, slot)
		return bag, slot
	end
end

function PlowEngine:StopEverything()
	PlowEngine:Hide()
	PlowScheduler:Hide()
	currentProcess = nil
	JobQueue = nil
	PlowList = nil
end

function PlowEngine:AddWatchList(ItemList)
		local link
		for link in ItemList:gmatch("%bH|") do
			local item = select(3, link:find("item:(%d+):"))
			watch[item] = true
			MrPlow:Print("Adding "..GetItemInfo(item))
		end
end

function PlowEngine:ClearWatchList()
	watch = {}
end

function PlowEngine:ShowWatchList()
	MrPlow:Print("Currently watching:")
	for item,_ in pairs(watch) do
		local _, link = GetItemInfo(item)
		MrPlow:Print(link)
	end
end
