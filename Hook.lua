-- global
RDbItems = {}
local itemDB = RDbItems

-- [25] = {"Worn Shortsword", "破损的短剑", 2, 7},
local IDX_enUS = 1
local IDX_zhCN = 2
local IDX_LV = 3
local IDX_PRICE = 4

-- Opposite language
local OPLANG = GetLocale() == "zhCN" and IDX_enUS or IDX_zhCN

local function trace(s)
	DEFAULT_CHAT_FRAME:AddMessage(tostring(s))
end

local function LoadItemInfo(type, sid)
	local tab = itemDB[type]
	return tab and tab[tonumber(sid)] or nil
end

-- item:6948:0:0:0
-- |Hitem:7073:0:0:0:0:0:0:0:80:0:0:0:0|h
-- |Henchant:59387|h
local function LinkParse(link)
	local _, _, type, sid = string.find(link, "|H(%l+):(%d+)")
	return type, sid
end

local function LinkLocale(link, cc)
	local idx = IDX_zhCN
	if cc == "en" then
		idx = IDX_enUS
	end
	if not cc or not link then
		return link
	end
	local itemInfo = LoadItemInfo(LinkParse(link))
	if itemInfo then
		link = gsub(link, "%[([^%]]+)%]", "[".. itemInfo[idx] .."]")
	end
	return link
end

local function LinkOppoSite(link, cc)
	if not cc then cc = RDbItemsCC end
	if OPLANG == IDX_zhCN then -- enUS client
		if cc == "cn" then
			link = LinkLocale(link, cc)
		end
	else
		if cc == "en" then
			link = LinkLocale(link, cc)
		end
	end
	return link
end

local function AddLocales(tooltip, type, sid, count)
	local itemInfo = LoadItemInfo(type, sid)
	if not itemInfo then
		return
	end
	if type ~= "item" then
		tooltip:AddLine(itemInfo[OPLANG])
		tooltip:Show()
		return
	end
	local lv = itemInfo[IDX_LV]
	if lv > 1 then
		tooltip:AddDoubleLine(itemInfo[OPLANG], "|cff999999Lv|r|cffffffff".. lv .. "|r")
	else
		tooltip:AddLine(itemInfo[OPLANG])
	end
	if not count then count = 1 end
	if count > 0 and itemInfo[IDX_PRICE] > 0 then
		SetTooltipMoney(tooltip, itemInfo[IDX_PRICE] * count)
	end
	tooltip:Show()
end

local function HookGameTooltip()
	-- copies from ShaguTweak/mods/verdor-value.lua
	local hookFrame = CreateFrame("Frame", nil, GameTooltip)
	hookFrame:SetScript("OnHide", function()
		hookFrame.itemLink = nil
		hookFrame.itemCount = nil
	end)
	hookFrame:SetScript("OnShow", function()
		if not GameTooltip.itemLink then
			return
		end
		local type, sid = LinkParse(GameTooltip.itemLink)
		AddLocales(GameTooltip, type, sid, GameTooltip.itemCount)
	end)
	-- SetItemRef, Called to handle clicks on Blizzard hyperlinks in chat
	local HookSetItemRef = SetItemRef
	SetItemRef = function(link, text, button)
		local type, sid = LinkParse(text)
		if not sid then
			HookSetItemRef(link, text, button)
			return
		end
		if IsShiftKeyDown() and ChatFrameEditBox:IsVisible() and RDbItemsCC then
			local idx = RDbItemsCC == "cn" and IDX_zhCN or IDX_enUS
			local inf = LoadItemInfo(type, sid)
			if inf then
				text = gsub(text, "%[([^%]]+)%]", "[".. inf[idx] .."]")
			end
		end
		HookSetItemRef(link, text, button)
		if not IsAltKeyDown() and not IsShiftKeyDown() and not IsControlKeyDown() then
			AddLocales(ItemRefTooltip, type, sid)
		end
	end
	-- .SetBagItem
	local HookSetBagItem = GameTooltip.SetBagItem
	function GameTooltip.SetBagItem(self, container, slot)
		self.itemLink = GetContainerItemLink(container, slot)
		if MerchantFrame:IsVisible() then
			self.itemCount = 0
		else
			_, self.itemCount = GetContainerItemInfo(container, slot)
		end
		return HookSetBagItem(self, container, slot)
	end
	-- .SetQuestLogItem
	local HookSetQuestLogItem = GameTooltip.SetQuestLogItem
	function GameTooltip.SetQuestLogItem(self, itemType, index)
		self.itemLink = GetQuestLogItemLink(itemType, index)
		if not self.itemLink then return end
		return HookSetQuestLogItem(self, itemType, index)
	end
	-- .SetQuestItem
	local HookSetQuestItem = GameTooltip.SetQuestItem
	function GameTooltip.SetQuestItem(self, itemType, index)
		self.itemLink = GetQuestItemLink(itemType, index)
		return HookSetQuestItem(self, itemType, index)
	end
	-- .SetLootItem
	local HookSetLootItem = GameTooltip.SetLootItem
	function GameTooltip.SetLootItem(self, slot)
		self.itemLink = GetLootSlotLink(slot)
		HookSetLootItem(self, slot)
	end
	-- .SetInboxItem
	local HookSetInboxItem = GameTooltip.SetInboxItem
	function GameTooltip.SetInboxItem(self, mailID, attachmentIndex)
		_, _, self.itemCount = GetInboxItem(mailID)
		self.itemLink = GetInboxItemLink(mailID, attachmentIndex)
		return HookSetInboxItem(self, mailID, attachmentIndex)
	end
	-- .SetInventoryItem
	local HookSetInventoryItem = GameTooltip.SetInventoryItem
	function GameTooltip.SetInventoryItem(self, unit, slot)
		self.itemLink = GetInventoryItemLink(unit, slot)
		return HookSetInventoryItem(self, unit, slot)
	end
	-- .SetLootRollItem
	local HookSetLootRollItem = GameTooltip.SetLootRollItem
	function GameTooltip.SetLootRollItem(self, id)
		self.itemLink = GetLootRollItemLink(id)
		return HookSetLootRollItem(self, id)
	end
	-- .SetMerchantItem
	local HookSetMerchantItem = GameTooltip.SetMerchantItem
	function GameTooltip.SetMerchantItem(self, merchantIndex)
		self.itemLink = GetMerchantItemLink(merchantIndex)
		self.itemCount = 0 -- 0 means don't show addon price
		return HookSetMerchantItem(self, merchantIndex)
	end
	-- .SetBuybackItem
	local HookSetBuybackItem = GameTooltip.SetBuybackItem
	function GameTooltip.SetBuybackItem(self, merchantIndex)
		self.itemLink = GetMerchantItemLink(merchantIndex)
		self.itemCount = 0 -- 0 means don't show addon price
		return HookSetBuybackItem(self, merchantIndex)
	end
	-- .SetCraftItem
	local HookSetCraftItem = GameTooltip.SetCraftItem
	function GameTooltip.SetCraftItem(self, skill, slot)
		self.itemLink = GetCraftReagentItemLink(skill, slot)
		return HookSetCraftItem(self, skill, slot)
	end
	-- .SetCraftSpell
	local HookSetCraftSpell = GameTooltip.SetCraftSpell
	function GameTooltip.SetCraftSpell(self, slot)
		self.itemLink = GetCraftItemLink(slot)
		return HookSetCraftSpell(self, slot)
	end
	-- .SetTradeSkillItem
	local HookSetTradeSkillItem = GameTooltip.SetTradeSkillItem
	function GameTooltip.SetTradeSkillItem(self, skillIndex, reagentIndex)
		if reagentIndex then
			self.itemLink = GetTradeSkillReagentItemLink(skillIndex, reagentIndex)
		else
			self.itemLink = GetTradeSkillItemLink(skillIndex)
		end
		return HookSetTradeSkillItem(self, skillIndex, reagentIndex)
	end
	-- .SetAuctionItem
	local HookSetAuctionItem = GameTooltip.SetAuctionItem
	function GameTooltip.SetAuctionItem(self, atype, index)
		_, _, self.itemCount = GetAuctionItemInfo(atype, index)
		self.itemLink = GetAuctionItemLink(atype, index)
		return HookSetAuctionItem(self, atype, index)
	end
	-- .SetAuctionSellItem
	--local HookSetAuctionSellItem = GameTooltip.SetAuctionSellItem
	--function GameTooltip.SetAuctionSellItem(self)
	--	_, _, self.itemCount = GetAuctionSellItemInfo()
	--	self.itemLink = ??? There is no GetAuctionSellItemLink
	--	return HookSetAuctionSellItem(self)
	--end
	-- .SetTradePlayerItem
	local HookSetTradePlayerItem = GameTooltip.SetTradePlayerItem
	function GameTooltip.SetTradePlayerItem(self, index)
		self.itemLink = GetTradePlayerItemLink(index)
		return HookSetTradePlayerItem(self, index)
	end
	-- .SetTradeTargetItem
	local HookSetTradeTargetItem = GameTooltip.SetTradeTargetItem
	function GameTooltip.SetTradeTargetItem(self, index)
		self.itemLink = GetTradeTargetItemLink(index)
		return HookSetTradeTargetItem(self, index)
	end
end


-- 拍卖行物品
local Bliz_GetAuctionItemLink = GetAuctionItemLink;
local function Trans_GetAuctionItemLink(ty, index) return LinkLocale(Bliz_GetAuctionItemLink(ty, index), RDbItemsCC) end;
-- 商人
local Bliz_GetMerchantItemLink = GetMerchantItemLink;
local function Trans_GetMerchantItemLink(index) return LinkLocale(Bliz_GetMerchantItemLink(index), RDbItemsCC) end;
-- 背包物品
local Bliz_GetContainerItemLink = GetContainerItemLink;
local function Trans_GetContainerItemLink(bag, slot) return LinkLocale(Bliz_GetContainerItemLink(bag, slot), RDbItemsCC) end;
-- 查看装备
local Bliz_GetInventoryItemLink = GetInventoryItemLink;
local function Trans_GetInventoryItemLink(unit, slot) return LinkLocale(Bliz_GetInventoryItemLink(unit, slot), RDbItemsCC) end;
-- 商业技能
local Bliz_GetTradeSkillItemLink = GetTradeSkillItemLink
local Bliz_GetTradeSkillReagentItemLink = GetTradeSkillReagentItemLink
local function Trans_GetTradeSkillItemLink(index) return LinkLocale(Bliz_GetTradeSkillItemLink(index), RDbItemsCC) end
local function Trans_GetTradeSkillReagentItemLink(index, id) return LinkLocale(Bliz_GetTradeSkillReagentItemLink(index, id), RDbItemsCC) end
-- 附魔
local Bliz_GetCraftItemLink = GetCraftItemLink
local Bliz_GetCraftReagentItemLink = GetCraftReagentItemLink
local function Trans_GetCraftItemLink(index) return LinkLocale(Bliz_GetCraftItemLink(index), RDbItemsCC) end;
local function Trans_GetCraftReagentItemLink(index, id) return LinkLocale(Bliz_GetCraftReagentItemLink(index, id), RDbItemsCC) end;

local function HookGetXXXItemLink(mode)
	if not mode then return end
	if mode == "cn"  then
		GetAuctionItemLink = Trans_GetAuctionItemLink
		GetMerchantItemLink = Trans_GetMerchantItemLink
		GetContainerItemLink = Trans_GetContainerItemLink
		GetInventoryItemLink = Trans_GetInventoryItemLink
		GetTradeSkillItemLink = Trans_GetTradeSkillItemLink
		GetTradeSkillReagentItemLink = Trans_GetTradeSkillReagentItemLink
		GetCraftReagentItemLink = Trans_GetCraftReagentItemLink
		GetCraftItemLink = Trans_GetCraftItemLink
	else
		GetAuctionItemLink = Bliz_GetAuctionItemLink
		GetMerchantItemLink = Bliz_GetMerchantItemLink
		GetContainerItemLink = Bliz_GetContainerItemLink
		GetInventoryItemLink = Bliz_GetInventoryItemLink
		GetTradeSkillItemLink = Bliz_GetTradeSkillItemLink
		GetTradeSkillReagentItemLink = Bliz_GetTradeSkillReagentItemLink
		GetCraftReagentItemLink = Bliz_GetCraftReagentItemLink
		GetCraftItemLink = Bliz_GetCraftItemLink
	end
end

local function StateUpdate(self)
	local mode = RDbItemsCC -- ## SavedVariables
	HookGetXXXItemLink(mode)
	if mode == "en" then
		self:SetText("E")
	elseif mode == "cn" then
		self:SetText("中")
	else
		self:SetText("--")
	end
end

function RDbFrameOnLoaded(self)
	function self.TriStateToggle(self)
		if RDbItemsCC == "en" then
			RDbItemsCC = "cn"
		elseif RDbItemsCC == "cn" then
			RDbItemsCC = nil
		else
			RDbItemsCC = "en"
		end
		StateUpdate(self)
	end
	self:RegisterEvent("VARIABLES_LOADED");
	self:SetScript("OnEvent", function()
		if event == "VARIABLES_LOADED" then
			StateUpdate(self)
		end
	end)
	HookGameTooltip()
	DEFAULT_CHAT_FRAME:AddMessage(self:GetName() .. " loaded")
end
--[[
用于将物品以指定的文字描述发送到聊天窗口,
 - "--"(auto): 直接使用当前客户端语言, 即不进行处理
 - "E"(英): 当往聊天窗口输物品链接时,使用英文名称
 - "中"(中文): 当往聊天窗口输物品链接时,使用中文名称

特性:
 - 支持 shift + 点击 输出到拍卖行, 这将会强制以英文输出, 目前支持 "背包","专业","聊天窗口中链接"
--]]


--[[
-- 需要 MODIFIER_STATE_CHANGED 事件, "OnUpdate" 损耗似乎有点高
-- 需要一个 item 上的动画

local function SetBagItemGlow(bagId, slot)
	local item = nil
	if IsAddOnLoaded("OneBag3") then
		item = _G["OneBagFrameBag"..bagId.."Item"..slot]
	else
		for i = 1, NUM_CONTAINER_FRAMES, 1 do
			local frame = getglobal("ContainerFrame"..i)
			if frame:GetID() == bagId and frame:IsShown() then
				item = getglobal("ContainerFrame"..i.."Item"..(GetContainerNumSlots(bagId) + 1 - slot))
			end
		end
	end
	if item then
		--item.NewItemTexture:SetAtlas("bags-glow-orange")
		--item.NewItemTexture:Show()
		--item.flashAnim:Play()
		-- item.NormalTexture:Play()
		-- "NormalTexture"
		-- trace(tostring(item:GetName()) .. ", bagid: ".. bagId ..", slot: ".. slot)
	end
end
local function GlowCheapestGrey()
	local lastPrice, lastBag, lastSlot
	for bag = 0, NUM_BAG_SLOTS do
		for bagSlot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, bagSlot)
			if link then
				local type, sid = LinkParse(link)
				local itemInfo = LoadItemInfo(type, sid)
				if itemInfo and type == "item" then
					local _, _, itemRarity = GetItemInfo(tonumber(sid))
					local vendorPrice = itemInfo[IDX_PRICE]
					if itemRarity == 0 and vendorPrice > 0 then
						local _, itemCount = GetContainerItemInfo(bag, bagSlot)
						local totalVendorPrice = vendorPrice * itemCount
						if not lastPrice or lastPrice > totalVendorPrice then
							lastPrice = totalVendorPrice
							lastBag = bag
							lastSlot = bagSlot
						end
					end
				end
			end
		end
	end
	if lastSlot then
		SetBagItemGlow(lastBag, lastSlot)
	end
end
--]]