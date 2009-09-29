local L = setmetatable({}, {__index=function(t,i) return i end})
local defaults, defaultsPC, db, dbpc = {}, {}

local function Print(...) print("|cFF33FF99EquipSetBanker|r:", ...) end
local debugf = tekDebug and tekDebug:GetFrame("EquipSetBanker")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end end

local EquipSetBanker = CreateFrame("Frame")
EquipSetBanker:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
EquipSetBanker:RegisterEvent("ADDON_LOADED")
EquipSetBanker:Hide()

-- Main frame setup
EquipSetBanker:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
      tile = true, tileSize = 16, edgeSize = 16, 
      insets = { left = 4, right = 4, top = 4, bottom = 4 }});
EquipSetBanker:SetBackdropColor(0,0,0,1);
EquipSetBanker:SetWidth(214)
EquipSetBanker:SetHeight(250)
EquipSetBanker:SetPoint("TOP", UIParent, "TOP", 0, -20)
EquipSetBanker:SetMovable(true)
EquipSetBanker:EnableMouse(true)
EquipSetBanker:SetScript("OnMouseDown", function(self) self:StartMoving() end)
EquipSetBanker:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

local closeBtn = CreateFrame("Button", nil, EquipSetBanker, "UIPanelCloseButton")
closeBtn:SetWidth(24); closeBtn:SetHeight(24);
closeBtn:SetPoint("TOPRIGHT")
closeBtn:SetScript("OnClick", function(self) self:GetParent():Hide() end)

local titleString = EquipSetBanker:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
titleString:SetPoint("TOP", 0, -6)
titleString:SetText("EquipSetBanker")

local helpString = EquipSetBanker:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
helpString:SetPoint("BOTTOM", 0, 6)
helpString:SetText("Click a set to move it\nto or from your bank.")

--[[
local withdrawBtn = CreateFrame("Button", nil, EquipSetBanker, "UIPanelButtonTemplate")
withdrawBtn:SetHighlightFontObject(GameFontHighlightSmall)
withdrawBtn:SetNormalFontObject(GameFontNormalSmall)
withdrawBtn:SetWidth(68); withdrawBtn:SetHeight(16)
withdrawBtn:SetPoint("BOTTOMLEFT", EquipSetBanker, "BOTTOM", 1, 5)
withdrawBtn:SetText("Withdraw")

local depositBtn = CreateFrame("Button", nil, EquipSetBanker, "UIPanelButtonTemplate")
depositBtn:SetHighlightFontObject(GameFontHighlightSmall)
depositBtn:SetNormalFontObject(GameFontNormalSmall)
depositBtn:SetWidth(68); depositBtn:SetHeight(16)
depositBtn:SetPoint("BOTTOMRIGHT", EquipSetBanker, "BOTTOM", -1, 5)
depositBtn:SetText("Deposit")
]]

-- The next four functions were borrowed from SetBanker

local function FindEmptyBagSlot(num)
	local count = 0;
	for bag = 0, NUM_BAG_SLOTS do
		local freeSlots, bagType = GetContainerNumFreeSlots(bag);
		if freeSlots > 0 and bagType == 0 then
			for slot = 1, GetContainerNumSlots(bag) do
				if not GetContainerItemInfo(bag, slot) then
					if count >= num then
						return bag, slot;
					else
						count = count + 1;
					end
				end
			end
		end
	end
	return nil, nil;
end

local function FindEmptyBankSlot(num)
	local count = 0;
	if GetContainerNumFreeSlots(BANK_CONTAINER) > 0 then
		for slot = 1, GetContainerNumSlots(BANK_CONTAINER) do
			if not GetContainerItemInfo(BANK_CONTAINER, slot) then
				if count >= num then
					return BANK_CONTAINER, slot;
				else
					count = count + 1;
				end
			end
		end
	end
	for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
		local freeSlots, bagType = GetContainerNumFreeSlots(bag);
		if freeSlots > 0 and bagType == 0 then
			for slot = 1, GetContainerNumSlots(bag) do
				if not GetContainerItemInfo(bag, slot) then
					if count >= num then
						return bag, slot;
					else
						count = count + 1;
					end
				end
			end
		end
	end
	return nil, nil;
end

local function Withdraw(name)
	local setLocs = GetEquipmentSetLocations(name);
	local numSlots = 0;
	for slot, loc in pairs(setLocs) do
		local player, bank, bags, srcSlot, srcBag = EquipmentManager_UnpackLocation(loc);
		local destBag, destSlot = FindEmptyBagSlot(numSlots);
		if bank and not bags and destBag and destSlot then
			ClearCursor();
			PickupInventoryItem(srcSlot);
			PickupContainerItem(destBag, destSlot);
			numSlots = numSlots + 1;
		elseif bank and bags and destBag and destSlot then
			ClearCursor();
			PickupContainerItem(srcBag, srcSlot);
			PickupContainerItem(destBag, destSlot);
			numSlots = numSlots + 1;
		end
	end
end

local function Deposit(name)
	local setLocs = GetEquipmentSetLocations(name);
	local numSlots = 0;
	for slot, loc in pairs(setLocs) do
		local player, bank, bags, srcSlot, srcBag = EquipmentManager_UnpackLocation(loc);
		local destBag, destSlot = FindEmptyBankSlot(numSlots);
		if player and not bags and destBag and destSlot then
			ClearCursor();
			PickupInventoryItem(srcSlot);
			PickupContainerItem(destBag, destSlot);
			numSlots = numSlots + 1;
		elseif bags and not bank and destBag and destSlot then
			ClearCursor();
			PickupContainerItem(srcBag, srcSlot);
			PickupContainerItem(destBag, destSlot);
			numSlots = numSlots + 1;
		end
	end
end

local function MakeButton(name, parent, ...)
	local btn = CreateFrame("Button", name, parent, "PopupButtonTemplate")
	btn:SetScale(0.85)
	btn:SetPoint(...)

	-- Helper functions
	btn.SetText = function(self, text)
		_G[btn:GetName().."Name"]:SetText(text)
	end

	btn.SetTexture = function(self, texture)
		_G[self:GetName().."Icon"]:SetTexture(texture)
	end

	btn.SetPartial = function(self, isPartial)
		if isPartial ~= true then
			_G[self:GetName().."Icon"]:SetVertexColor(1, 1, 1);
		else
			_G[self:GetName().."Icon"]:SetVertexColor(1, 0.25, 0.25);
		end
	end

	--Tooltip code
	btn:SetScript("OnEnter", function(self) 
		if self.name then 
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

			local itemCount, equippedCount, inventoryCount, bankCount = 0, 0, 0, 0
			local setLocations = GetEquipmentSetLocations(self.name)
			for slot, loc in pairs(setLocations) do
				local player, bank, bags, slot, bag = EquipmentManager_UnpackLocation(loc);

				if player or bank or bags then
					itemCount = itemCount + 1
					if player and not bags then equippedCount = equippedCount + 1 end
					if bags and not player then inventoryCount = inventoryCount + 1 end
					if (not player and not bags) or bank then bankCount = bankCount + 1 end
				end
			end

			GameTooltip:AddDoubleLine("|cffffffff"..self.name.."|r", itemCount)
			GameTooltip:AddLine(equippedCount.." items equipped")
			GameTooltip:AddLine(inventoryCount.." items in inventory")
			GameTooltip:Show()
		end 
	end)
	btn:SetScript("OnLeave", function() 
		GameTooltip:Hide() 
	end)

	btn:SetScript("OnClick", function(self,button)
			if self.sectionType == "Bag" then
				Deposit(self.name)
			elseif self.sectionType == "Bank" then
				Withdraw(self.name)
			else
				print("Huh?")
			end
	end)

	-- Default texture is the empty bag slot texture
	btn:SetTexture("Interface/PaperDoll/UI-Backpack-EmptySlot")

	return btn
end

local function MakeSection(sectionType, label, parent, ...)
	local buttons = {}
	local padding = 8

	local fs1 = parent:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
	fs1:SetPoint(...)
	fs1:SetHeight(16)
	fs1:SetText(label)

	local btn
	local count = 1
	local point, relTo, relPoint, xofs, yofs = "TOPLEFT", fs1, "BOTTOMLEFT", 0, -5
	local firstInRow = nil
	for row = 0,1 do
		for col = 0,4 do
			btn = MakeButton("EquipSetBankerSetButton"..sectionType..count, parent, point, relTo, relPoint, xofs, yofs)
			btn.sectionType = sectionType
			point = "LEFT"; relTo = btn; relPoint = "RIGHT"; xofs = padding; yofs = 0
			if firstInRow == nil then firstInRow = btn end
			table.insert(buttons, btn)
			count = count+1
		end
		xofs = 0
		yofs = -padding
		point = "TOPLEFT"
		relPoint = "BOTTOMLEFT"
		relTo = firstInRow
		firstInRow = nil
	end

	return buttons
end

local inBagsSetButtons = MakeSection("Bag", "In Bags/Equipped", EquipSetBanker, "TOPLEFT", 12, -25)
local inBankSetButtons = MakeSection("Bank", "In Bank", EquipSetBanker, "TOPLEFT", 12, -125)

--[[
			local player, bank, bags, slot, bag = EquipmentManager_UnpackLocation(location)
			player == true		if the 
--]]
local function Refresh()
	local bankedSets, availableSets = {}, {}
	for index = 1,GetNumEquipmentSets() do
		local name, icon, setID = GetEquipmentSetInfo(index)
		local itemLocations = GetEquipmentSetLocations(name)

		Debug("Refreshing "..name)
		local available, banked =  nil, nil
		for itemSlot, location in pairs(itemLocations) do
			local player, bank, bags, slot, bag = EquipmentManager_UnpackLocation(location)
			if player then available = true end
			if (location == -1) or bank ~= false then banked = true end
			Debug(itemSlot, player, bank, bags, slot, bag, available, banked)
		end

		local info = { name=name, icon=icon }
		if banked and available then info.partial = true end
		if banked then table.insert(bankedSets, info) end
		if available then table.insert(availableSets, info) end
	end

	for i,btn in ipairs(inBagsSetButtons) do
		if availableSets[i] then
			btn.name = availableSets[i].name
			btn:SetTexture(availableSets[i].icon)
			btn:SetText(availableSets[i].name)
			-- if availableSets[i].partial then btn:SetPartial(true) end
		else
			btn.name = nil
			btn:SetTexture("Interface/PaperDoll/UI-Backpack-EmptySlot")
			-- btn:SetPartial(false)
			btn:SetText("")
		end
	end

	for i,btn in ipairs(inBankSetButtons) do
		if bankedSets[i] then
			btn.name = bankedSets[i].name
			btn:SetTexture(bankedSets[i].icon)
			btn:SetText(bankedSets[i].name)
			-- if bankedSets[i].partial then btn:SetPartial(true) end
		else
			btn.name = nil
			btn:SetTexture("Interface/PaperDoll/UI-Backpack-EmptySlot")
			btn:SetText("")
			-- btn:SetPartial(false)
		end
	end
end

EquipSetBanker:SetScript("OnShow", Refresh)

--[[ Event Handlers ]]

function EquipSetBanker:ADDON_LOADED(event, addon)
	if addon:lower() ~= "equipsetbanker" then return end

	EquipSetBankerDB, EquipSetBankerDBPC = setmetatable(EquipSetBankerDB or {}, {__index = defaults}), setmetatable(EquipSetBankerDBPC or {}, {__index = defaultsPC})
	db, dbpc = EquipSetBankerDB, EquipSetBankerDBPC

	-- Do anything you need to do after addon has loaded

	LibStub("tekKonfig-AboutPanel").new(nil, "EquipSetBanker") -- Make first arg nil if no parent config panel

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end


function EquipSetBanker:PLAYER_LOGIN()
	self:RegisterEvent("PLAYER_LOGOUT")

	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("BAG_UPDATE")

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

function EquipSetBanker:PLAYER_LOGOUT()
	for i,v in pairs(defaults) do if db[i] == v then db[i] = nil end end
	for i,v in pairs(defaultsPC) do if dbpc[i] == v then dbpc[i] = nil end end

	-- Do anything you need to do as the player logs out
end

function EquipSetBanker:BANKFRAME_OPENED()
	self:Show()
end

function EquipSetBanker:BANKFRAME_CLOSED()
	self:Hide()
end

function EquipSetBanker:UNIT_INVENTORY_CHANGED()
	Refresh()
end

function EquipSetBanker:BAG_UPDATE(bagID)
	if self:IsVisible() then
		Refresh()
	end
end

--[[ Slash Command Registration ]]

SLASH_EQUIPSETBANKER1 = "/esb"
SLASH_EQUIPSETBANKER2 = "/equipsetbanker"
SlashCmdList.EQUIPSETBANKER = function(msg)
	if EquipSetBanker:IsVisible() then
		EquipSetBanker:Hide()
	else
		EquipSetBanker:Show()
	end
end

