local db 

function MrPlow:InitialiseOptions()
	db = MrPlow.db.profile
end

local createBorder = function(self, point)
	local bc = self:CreateTexture(nil, "OVERLAY")
	bc:SetTexture"Interface\\Buttons\\UI-ActionButton-Border"
	bc:SetBlendMode"ADD"
	bc:SetAlpha(.8)

	bc:SetPoint("CENTER", point or self)
	return bc
end

local colorTable = setmetatable({
	["ignore-slot"] = {r = .9, g = 0, b = 0, s = 60},
	["ignore-item"] = {r = 1, g = 1, b = 0, s = 60},
}, {__call = function(self, val)
	local c = self[val]
	if(c) then return c.r, c.g, c.b, c.s end
end})

function MrPlow:Overlay(frame, quality)
	if frame[quality] then
		if frame[quality]:IsVisible() then 
			frame[quality]:Hide()
		else 
			frame[quality]:Show()
		end
		return		
	end

	local bc = createBorder(frame, point)
	frame[quality] = bc
	local border = bc
	if(border) then
		r, g, b, s = colorTable(quality)
		border:SetVertexColor(r, g, b)
		border:SetWidth(s)
		border:SetHeight(s)
		border:Show()
	end
end

function MrPlow:IsIgnored(bag, slot, guild)
	if not guild then
		if db.IgnoreBags[bag] then
			return true
		end
		if not slot then
			return false
		end
	end
	
	if guild and db.IgnoreGuild[bag] and db.IgnoreGuild[bag][slot] then
		return true
	end

	if db.IgnoreSlots[bag] and db.IgnoreSlots[bag][slot] then
		return true
	end
	return false
end

function MrPlow:Ignore(bag, slot, guild)
	if not guild and not slot then
		db.IgnoreBags[bag] = 1
		return
	end
	if guild then
		if not db.IgnoreGuild[bag] then db.IgnoreGuild[bag] = {} end
		db.IgnoreGuild[bag][slot] = 1
		return
	end
	if not db.IgnoreSlots[bag] then db.IgnoreSlots[bag] = {} end
	db.IgnoreSlots[bag][slot] = 1
end

function MrPlow:Unignore(bag, slot, guild)
	if not guild and not slot then
		db.IgnoreBags[bag] = nil
		return
	end
	if guild then
		db.IgnoreGuild[bag][slot] = nil
		return
	end
	db.IgnoreSlots[bag][slot] = nil
end

BagFrames = {}

function MrPlow:ScanFrame(children, parent)
   local FullFrameList = children and children or {GetMouseFocus():GetChildren()}
   for i,v in ipairs(FullFrameList) do
      if v["GetID"] then
         if not parent then
            parent = true
            self:ScanFrame({v:GetChildren()}, parent)
         end
         if v:GetID() ~= 0 and v:GetName():find("%d.*%d") then
            BagFrames[v:GetParent():GetID().."-"..v:GetID()] = v:GetName()         
         end         
      end
   end
end

function MrPlow:ScanAllFrames()
	BagFrames = {}
	local frame = EnumerateFrames()
	while frame do
		if frame:IsVisible() and frame["GetID"] and frame:GetParent() and frame:GetParent()["GetID"] and
							frame:GetID() ~=0 and frame:GetName():find("%d.*%d") then
			BagFrames[frame:GetParent():GetID().."-"..frame:GetID()] = frame:GetName()
		end
		frame = EnumerateFrames(frame)
	end
end

function MrPlow:OverlayBags()
	self:ScanAllFrames()
	for b,bag in pairs(db.IgnoreSlots) do
   	for s,_ in pairs(bag) do
			if BagFrames[b.."-"..s] then
				MrPlow:Overlay(getglobal(BagFrames[b.."-"..s]), "ignore-slot")
      end
   	end
	end
end

-- Once again, thank you Kyahx for your ever useful mousey code
--
local mouser = CreateFrame("Frame")
mouser.setCursor = _G.SetCursor

function mouser:OnUpdate(elap)

  local frame = GetMouseFocus()
  local name = frame and frame:GetName() or tostring(frame)

  SetCursor("CAST_CURSOR")
  
	if not frame then return end

	-- Adding to slot ignore
  if IsMouseButtonDown("RightButton") then
		self:Stop()
		if frame["GetID"] and frame:GetParent()["GetID"] then
			local guild = false

			if name:find("GuildBank") then guild = true end
			
			MrPlow:Ignore( frame:GetID(), frame:GetParent():GetID(), guild)
			MrPlow:Overlay(frame, "ignore-slot")
			return
		end
	end

  if IsMouseButtonDown("LeftButton") then
    self:Stop()
		if frame["GetID"] and frame:GetParent()["GetID"] then
			local ItemFunc = GetContainerItemLink
			if name:find("GuildBank") then ItemFunc = GetGuildBankItemLink end
			local link = select(3, ItemFunc(frame:GetParent():GetID(), frame:GetID()):find("item:(%d+):"))
			MrPlow:Print("Ignoring "..link.." - "..ItemFunc(frame:GetParent():GetID(), frame:GetID()))
			db.IgnoreItems[tonumber(link)] = true
			MrPlow:Overlay(frame, "ignore-item")
    end
  end
end

function mouser:Start()
   self:SetScript("OnUpdate", self.OnUpdate)
end

function mouser:Stop()
   
   self:SetScript("OnUpdate", nil)
end
hooksecurefunc(_G.GameMenuFrame, "Show", function() mouser:Stop() end)

function MrPlow:StartMouser()
	mouser:Start()
end

