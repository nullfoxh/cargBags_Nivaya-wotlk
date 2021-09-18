-- Name: MrPlow
-- Author: Wobin
-- Email: wobster@gmail.com
-- Description: MrPlow is a physical restacker/defragger/sorter. It will
-- physically move the items in your inventory to suit certain rules.
--
-- Notes: This is an OO rewrite of the original, which was a horrific
-- convolution of spaghetti code, considering we didn't have Ace2 back then in
-- those old Ace days =P
--
-- It's also an exercise in "What the hell was I thinking at the time" we all
-- run into when refactoring code. Hopefully this write is a whole lot clearer
-- as to the mechanism of how MrPlow does stuff.
--
-- ETA - pft, what was I thinking? coroutines? clearer? yeah right =P
--
MrPlow = LibStub("AceAddon-3.0"):NewAddon("MrPlow", "AceConsole-3.0")

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")

local getTable
local returnTable
local db
local meta

MrPlow.PlowEngine = CreateFrame("Frame", "PlowEngine")
MrPlow.PlowScheduler = CreateFrame("Frame", "PlowScheduler")

local myldb = ldb:NewDataObject("MrPlow", {
    type = "launcher",
		text = "Mr Plow",
    icon = "Interface\\Addons\\MrPlow\\Icon.tga",
    OnClick = function(clickedframe, button)
			if(button == "LeftButton") then	
				MrPlow:DoStuff("theworks")
			else
				MrPlow:DoStuff("banktheworks")
			end
    end,
})


-- Pool of frames to reuse.
MrPlow.tablePool = setmetatable({}, 
	( {__index = function(self, n)
			if n==0 then
				return table.remove(self) or {}
			end
		end})
	)

function MrPlow.getTable(...)
	local newTable = MrPlow.tablePool[0]
	local args = select("#", ...)
	if args > 0 then
		for i=1, args do
			table.insert(newTable, (select(i, ...)))
		end
	end
        newTable.recycled = nil
	setmetatable(newTable, meta)
	return newTable
end

function MrPlow.returnTable(frame)
        if not frame or frame.recycled then return end
	for i,v in pairs(frame) do
		if type(frame[i]) == "table" then
			returnTable(frame[i])
		end
		frame[i] = nil
	end
        frame.recycled = true
	table.insert(MrPlow.tablePool, frame)
end

getTable = MrPlow.getTable
returnTable = MrPlow.returnTable

function MrPlow:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("MrPlowDB", { profile = {IgnoreItems = { [6265] = true },
								IgnoreSlots = {},
								IgnoreBags = {},
								IgnoreGuild = {},
								EmptySpace = "Bottom",
								} });
	db = self.db.profile;
	self:RegisterChatCommand( "mrplow", "DoStuff")
	self:RegisterChatCommand( "mp", "DoStuff")
	MrPlow.PlowEngine:Enable();
	MrPlow:InitialiseOptions();
	meta  = MrPlow:getTable()
	meta.__mode = "v"
	icon:Register("MrPlowLDB", myldb,	db)
end

function MrPlow:DoStuff(args)
	
	args = args:lower()
	
	if args == "stack" then
		MrPlow:Print("MrPlow restacks your items")
		PlowEngine:RunJob(PlowEngine.Restack, 0,1,2,3,4)
	elseif args == "defrag" then
		MrPlow:Print("MrPlow shakes all your bags hard to pack them better")
		PlowEngine:RunJob(PlowEngine.Defragment,0,1,2,3,4)
	elseif args == "sort" then
		MrPlow:Print("MrPlow begins to sort your items")
		PlowEngine:RunJob(PlowEngine.MassSort,0,1,2,3,4)
	elseif args == "consolidate" then
		MrPlow:Print("MrPlow begins to consolidate your bags")
		PlowEngine:RunJob(PlowEngine.Consolidate,0,1,2,3,4)

	elseif args == "bankstack" or args == "bank stack" then
		MrPlow:Print("MrPlow restacks the items to fit")
		PlowEngine:RunJob(PlowEngine.Restack,-1,5,6,7,8,9,10,11)
	elseif args == "bankdefrag" or args == "bank defrag" then
		MrPlow:Print("MrPlow shoves all the items to the side")
		PlowEngine:RunJob(PlowEngine.Defragment,-1,5,6,7,8,9,10,11)
	elseif args == "banksort" or args == "bank sort" then
		MrPlow:Print("MrPlow beings to sort your bank items")
		PlowEngine:RunJob(PlowEngine.MassSort,-1,5,6,7,8,9,10,11)
	elseif args == "bankconsolidate" or args == "bank consolidate" then
		MrPlow:Print("MrPlow begins to consolidate your bank")
		PlowEngine:RunJob(PlowEngine.Consolidate,-1,5,6,7,8,9,10,11)
  
	elseif args == "gbankstack" or args == "gbank stack" then
		MrPlow:Print("Stacking the guildbank, use /mp stop if you get caught in a loop")
		PlowEngine:RunGuildBankJob(PlowEngine.Restack)
	elseif args == "gbankdefrag" or args == "gbank defrag" then
		MrPlow:Print("Defragging the guildbank, use /mp stop if you get caught in a loop")
		PlowEngine:RunGuildBankJob(PlowEngine.Defragment)
	elseif args == "gbanksort" or args == "gbank sort" then
		MrPlow:Print("Sorting the guildbank, use /mp stop if you get caught in a loop")
		PlowEngine:RunGuildBankJob(PlowEngine.MassSort)

	elseif args == "theworks" then
		MrPlow:Print("MrPlow begins a full rework of your inventory")
		PlowEngine:RunJob(PlowEngine.Restack,0,1,2,3,4)
		PlowEngine:RunJob(PlowEngine.Consolidate,0,1,2,3,4)
		PlowEngine:RunJob(PlowEngine.Defragment, 0,1,2,3,4)
		PlowEngine:RunJob(PlowEngine.MassSort, 0,1,2,3,4)
		PlowEngine:RunJob(PlowEngine.Restack,0,1,2,3,4)
  elseif args == "banktheworks" or args == "bank theworks" then
		MrPlow:Print("MrPlow begins a full rework of your bank")
		PlowEngine:RunJob(PlowEngine.Restack,-1,5,6,7,8,9,10,11)
		PlowEngine:RunJob(PlowEngine.Consolidate,-1,5,6,7,8,9,10,11)
		PlowEngine:RunJob(PlowEngine.Defragment,-1,5,6,7,8,9,10,11)
		PlowEngine:RunJob(PlowEngine.MassSort,-1,5,6,7,8,9,10,11)
		PlowEngine:RunJob(PlowEngine.Restack,-1,5,6,7,8,9,10,11)
  elseif args == "gbanktheworks" or args == "gbank theworks" then
		MrPlow:Print("Doing the works on the guildbank, use /mp stop if you get caught in a loop")
		PlowEngine:RunGuildBankJob(PlowEngine.Restack)
		PlowEngine:RunGuildBankJob(PlowEngine.Defragment)
		PlowEngine:RunGuildBankJob(PlowEngine.MassSort)
		PlowEngine:RunGuildBankJob(PlowEngine.Restack)
	elseif args == "stop" or args == "omg" then
		MrPlow:Print("MrPlow comes to a screeching halt")
		PlowEngine:StopEverything()
	elseif args:find("add") then
		PlowEngine:AddWatchList(args)
	elseif args:find("clear") then
		PlowEngine:ClearWatchList()
	elseif args:find("watching") then
		PlowEngine:ShowWatchList()
	elseif args:find("minimap") then
		if db.hide then
			icon:Show("MrPlowLDB")
			db.hide = nil
		else
			icon:Hide("MrPlowLDB")
			db.hide = true
		end
	end
	PlowScheduler:Show()
end

function MrPlow:OnClick()
	self.PlowEngine:SortMe();
end

function MrPlow:IgnoreSlots(bag, slot)
	if not db.IgnoreSlots[bag] then
		db.IgnoreSlots[bag] = getTable()
	end
	db.IgnoreSlots[bag][slot] = true
end

function MrPlow:UnignoreSlots(bag, slot)
	db.IgnoreSlots[bag][slot] = nil

	if not next(db.IgnoreSlots[bag]) then
		returnTable(db.IgnoreSlots[bag])
	end
end
