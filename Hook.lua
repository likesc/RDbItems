-- global
if RDbItems then return end

local itemDB = { version = 20300 } -- 2.3.0
RDbItems = itemDB

function itemDB.trace(...)
	local str = ""
	for i = 1, arg.n do
		str = i == 1 and tostring(arg[i]) or (str .. ", " .. tostring(arg[i]))
	end
	DEFAULT_CHAT_FRAME:AddMessage(str)
end

local function mkindex(list, column)
	local indexes = {}
	local len = table.getn(list) -- lua 5.0
	table.setn(indexes, len)
	for i = 1, len do
		indexes[i] = i
	end
	table.sort(indexes, function(a, b)
		return list[a][column] < list[b][column]
	end)
	return indexes
end

local function bsearch(list, column, value, first, last)
	if not value or first > last then
		return nil
	end
	local midd = bit.rshift(first + last, 1)
	local data = list[midd]
	local mono = data[column]
	if mono == value then
		return data
	elseif mono < value then
		return bsearch(list, column, value, midd + 1, last)
	else
		return bsearch(list, column, value, first, midd - 1)
	end
end

local function bsearch_index(list, indexes, column, value, first, last)
	if not value or first > last then
		return nil
	end
	local midd = bit.rshift(first + last, 1)
	local data = list[indexes[midd]]
	local mono = data[column]
	if mono == value then
		return data
	elseif mono < value then
		return bsearch_index(list, indexes, column, value, midd + 1, last)
	else
		return bsearch_index(list, indexes, column, value, first, midd - 1)
	end
end

-- column, e.g : {25, "Worn Shortsword", "破损的短剑", 2, 7},
local IDX_ID    = 1
local IDX_enUS  = 2
local IDX_zhCN  = 3
local IDX_LV    = 4
local IDX_PRICE = 5

-- lang and Opposite lang
local LANG = GetLocale() == "zhCN" and IDX_zhCN or IDX_enUS
local OPLANG = LANG == IDX_zhCN and IDX_enUS or IDX_zhCN

function load_of_name(name, list)
	if not list then
		list = itemDB.item
	end
	local indexes = list[0]
	if not indexes then
		indexes = mkindex(list, LANG)
		list[0] = indexes
	end
	return bsearch_index(list, indexes, LANG, name, 1, table.getn(indexes))
end

-- regexp
local link_name_rex = "%[([^%]]+)%]"
local link_type_id_rex = "|H(%l+):(%d+)"

local function load_itemdata(type, sid)
	local list = itemDB[type]
	return list and bsearch(list, 1, tonumber(sid), 1, table.getn(list))
end

itemDB.get = load_itemdata
itemDB.ofname = load_of_name

-- item:6948:0:0:0
-- |Hitem:7073:0:0:0:0:0:0:0:80:0:0:0:0|h
-- |Henchant:59387|h
local function link_parse(link)
	local _, _, type, sid = string.find(link, link_type_id_rex)
	return type, sid
end

local function link_locale(link, mode)
	if not mode then mode = RDbItemsCfg.mode end
	if not mode or not link then
		return link
	end
	local idx = mode == "en" and IDX_enUS or IDX_zhCN
	local data = load_itemdata(link_parse(link))
	if data then
		link = gsub(link, link_name_rex, "[".. data[idx] .."]")
	end
	return link
end

local function add_locales(tooltip, type, sid, count)
	local data = load_itemdata(type, sid)
	if not data then
		return
	end
	if type ~= "item" then
		tooltip:AddLine(data[OPLANG])
		tooltip:Show()
		return
	end
	local lv = data[IDX_LV]
	if not RDbItemsCfg.NoName then
		tooltip:AddLine(data[OPLANG])
	end
	if not count then count = 1 end
	if not RDbItemsCfg.NoPrice and count > 0 and data[IDX_PRICE] > 0 then
		SetTooltipMoney(tooltip, data[IDX_PRICE] * count)
	end
	local right = getglobal(tooltip:GetName().."TextRight".. tooltip:NumLines())
	if not RDbItemsCfg.NoPrice and lv > 1 and right and not right:IsVisible() then
		right:SetText("|cffddddddLv|r".. lv)
		right:Show()
		local moneyFrame = getglobal(tooltip:GetName().."MoneyFrame")
		if moneyFrame and moneyFrame:IsVisible() then
			tooltip:SetMinimumWidth(moneyFrame:GetWidth() + right:GetWidth() + 12)
		end
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
		if not hookFrame.itemLink then
			return
		end
		local type, sid = link_parse(hookFrame.itemLink)
		add_locales(GameTooltip, type, sid, hookFrame.itemCount)
	end)
	if AtlasLootItem_OnEnter then
		-- AtlasLoot\Core\AtlasLoot.lua "AtlasLootItem_OnEnter()"
		local Hook_AtlasLootItem_OnEnter = AtlasLootItem_OnEnter
		AtlasLootItem_OnEnter = function()
			Hook_AtlasLootItem_OnEnter()
			local sid = this.itemID
			if sid == 0 then
				return
			end
			local tooltip = AtlasLootTooltip
			local st = string.sub(sid, 1, 1)
			local type = "item"
			if st == "e" then
				type = "enchant"
				sid = string.sub(sid, 2)
			elseif st == "s" then
				sid = GetSpellInfoVanillaDB["craftspells"][tonumber(string.sub(sid, 2))]["craftItem"]
				tooltip = AtlasLootTooltip2
			end
			add_locales(tooltip, type, sid)
		end
	end
	-- SetItemRef, Called to handle clicks on Blizzard hyperlinks in chat
	local HookSetItemRef = SetItemRef
	SetItemRef = function(link, text, button)
		local type, sid = link_parse(text)
		if not sid then
			HookSetItemRef(link, text, button)
			return
		end
		if IsShiftKeyDown() then
			local data = load_itemdata(type, sid)
			if ChatFrameEditBox:IsVisible() then
				if data and RDbItemsCfg.mode then
					local idx = RDbItemsCfg.mode == "cn" and IDX_zhCN or IDX_enUS
					text = gsub(text, link_name_rex, "[".. data[idx] .."]")
				end
			elseif BrowseName and BrowseName:IsVisible() then
				if data then
					local idx = OPLANG == IDX_zhCN and IDX_enUS or IDX_zhCN
					BrowseName:SetText(data[idx])
				else
					local _, _, name = string.find(text, link_name_rex)
					BrowseName:SetText(name)
				end
			end
		end
		HookSetItemRef(link, text, button)
		if not IsAltKeyDown() and not IsShiftKeyDown() and not IsControlKeyDown() then
			add_locales(ItemRefTooltip, type, sid)
		end
	end
	-- .SetBagItem
	local HookSetBagItem = GameTooltip.SetBagItem
	function GameTooltip.SetBagItem(self, container, slot)
		hookFrame.itemLink = GetContainerItemLink(container, slot)
		if MerchantFrame:IsVisible() then
			hookFrame.itemCount = 0
		else
			local _, count = GetContainerItemInfo(container, slot)
			hookFrame.itemCount = count
		end
		return HookSetBagItem(self, container, slot)
	end
	-- .SetQuestLogItem
	local HookSetQuestLogItem = GameTooltip.SetQuestLogItem
	function GameTooltip.SetQuestLogItem(self, itemType, index)
		hookFrame.itemLink = GetQuestLogItemLink(itemType, index)
		if not hookFrame.itemLink then return end
		return HookSetQuestLogItem(self, itemType, index)
	end
	-- .SetQuestItem
	local HookSetQuestItem = GameTooltip.SetQuestItem
	function GameTooltip.SetQuestItem(self, itemType, index)
		hookFrame.itemLink = GetQuestItemLink(itemType, index)
		return HookSetQuestItem(self, itemType, index)
	end
	-- .SetLootItem
	local HookSetLootItem = GameTooltip.SetLootItem
	function GameTooltip.SetLootItem(self, slot)
		hookFrame.itemLink = GetLootSlotLink(slot)
		HookSetLootItem(self, slot)
	end
	-- .SetInboxItem
	local HookSetInboxItem = GameTooltip.SetInboxItem
	function GameTooltip.SetInboxItem(self, mailID, attachmentIndex)
		local name, _, count = GetInboxItem(mailID) -- there is no GetInboxItemLink
		local data = load_of_name(name)
		if data then
			hookFrame.itemLink = "|Hitem:" .. data[IDX_ID]
			hookFrame.itemCount = count
		end
		return HookSetInboxItem(self, mailID, attachmentIndex)
	end
	-- .SetInventoryItem
	local HookSetInventoryItem = GameTooltip.SetInventoryItem
	function GameTooltip.SetInventoryItem(self, unit, slot)
		hookFrame.itemLink = GetInventoryItemLink(unit, slot)
		hookFrame.itemCount = GetInventoryItemCount(unit, slot)
		return HookSetInventoryItem(self, unit, slot)
	end
	-- .SetLootRollItem
	local HookSetLootRollItem = GameTooltip.SetLootRollItem
	function GameTooltip.SetLootRollItem(self, id)
		hookFrame.itemLink = GetLootRollItemLink(id)
		return HookSetLootRollItem(self, id)
	end
	-- .SetMerchantItem
	local HookSetMerchantItem = GameTooltip.SetMerchantItem
	function GameTooltip.SetMerchantItem(self, index)
		hookFrame.itemLink = GetMerchantItemLink(index)
		hookFrame.itemCount = 0 -- 0 means don't show addon price
		return HookSetMerchantItem(self, index)
	end
	-- .SetBuybackItem
	local HookSetBuybackItem = GameTooltip.SetBuybackItem
	function GameTooltip.SetBuybackItem(self, index)
		local name = GetBuybackItemInfo(index)
		local data = load_of_name(name)
		if data then
			hookFrame.itemLink = "|Hitem:" .. data[IDX_ID]
			hookFrame.itemCount = 0 -- 0 means don't show addon price
		end
		return HookSetBuybackItem(self, index)
	end
	-- .SetCraftItem
	local HookSetCraftItem = GameTooltip.SetCraftItem
	function GameTooltip.SetCraftItem(self, skill, slot)
		hookFrame.itemLink = GetCraftReagentItemLink(skill, slot)
		return HookSetCraftItem(self, skill, slot)
	end
	-- .SetCraftSpell
	local HookSetCraftSpell = GameTooltip.SetCraftSpell
	function GameTooltip.SetCraftSpell(self, slot)
		hookFrame.itemLink = GetCraftItemLink(slot)
		return HookSetCraftSpell(self, slot)
	end
	-- .SetTradeSkillItem
	local HookSetTradeSkillItem = GameTooltip.SetTradeSkillItem
	function GameTooltip.SetTradeSkillItem(self, skillIndex, reagentIndex)
		if reagentIndex then
			hookFrame.itemLink = GetTradeSkillReagentItemLink(skillIndex, reagentIndex)
		else
			hookFrame.itemLink = GetTradeSkillItemLink(skillIndex)
		end
		return HookSetTradeSkillItem(self, skillIndex, reagentIndex)
	end
	-- .SetAuctionItem
	local HookSetAuctionItem = GameTooltip.SetAuctionItem
	function GameTooltip.SetAuctionItem(self, atype, index)
		local _, _, count = GetAuctionItemInfo(atype, index)
		hookFrame.itemCount = count
		hookFrame.itemLink = GetAuctionItemLink(atype, index)
		return HookSetAuctionItem(self, atype, index)
	end
	-- .SetAuctionSellItem
	local HookSetAuctionSellItem = GameTooltip.SetAuctionSellItem
	function GameTooltip.SetAuctionSellItem(self)
		local name, _, count = GetAuctionSellItemInfo() -- There is no GetAuctionSellItemLink
		local data = load_of_name(name)
		if data then
			hookFrame.itemLink = "|Hitem:" .. data[IDX_ID]
			hookFrame.itemCount = count
		end
		return HookSetAuctionSellItem(self)
	end
	-- .SetTradePlayerItem
	local HookSetTradePlayerItem = GameTooltip.SetTradePlayerItem
	function GameTooltip.SetTradePlayerItem(self, index)
		hookFrame.itemLink = GetTradePlayerItemLink(index)
		return HookSetTradePlayerItem(self, index)
	end
	-- .SetTradeTargetItem
	local HookSetTradeTargetItem = GameTooltip.SetTradeTargetItem
	function GameTooltip.SetTradeTargetItem(self, index)
		hookFrame.itemLink = GetTradeTargetItemLink(index)
		return HookSetTradeTargetItem(self, index)
	end
end


-- 拍卖行物品
local Bliz_GetAuctionItemLink = GetAuctionItemLink
local function Trans_GetAuctionItemLink(ty, index) return link_locale(Bliz_GetAuctionItemLink(ty, index)) end
-- 商人
local Bliz_GetMerchantItemLink = GetMerchantItemLink
local function Trans_GetMerchantItemLink(index) return link_locale(Bliz_GetMerchantItemLink(index)) end
-- 背包物品
local Bliz_GetContainerItemLink = GetContainerItemLink
local function Trans_GetContainerItemLink(bag, slot) return link_locale(Bliz_GetContainerItemLink(bag, slot)) end
-- 查看装备
local Bliz_GetInventoryItemLink = GetInventoryItemLink
local function Trans_GetInventoryItemLink(unit, slot) return link_locale(Bliz_GetInventoryItemLink(unit, slot)) end
-- 商业技能
local Bliz_GetTradeSkillItemLink = GetTradeSkillItemLink
local Bliz_GetTradeSkillReagentItemLink = GetTradeSkillReagentItemLink
local function Trans_GetTradeSkillItemLink(index) return link_locale(Bliz_GetTradeSkillItemLink(index)) end
local function Trans_GetTradeSkillReagentItemLink(index, id) return link_locale(Bliz_GetTradeSkillReagentItemLink(index, id)) end
-- 附魔
local Bliz_GetCraftItemLink = GetCraftItemLink
local Bliz_GetCraftReagentItemLink = GetCraftReagentItemLink
local function Trans_GetCraftItemLink(index) return link_locale(Bliz_GetCraftItemLink(index)) end
local function Trans_GetCraftReagentItemLink(index, id) return link_locale(Bliz_GetCraftReagentItemLink(index, id)) end
--  Loot
local Bliz_GetLootSlotLink = GetLootSlotLink
local function Trans_GetLootSlotLink(slot) return link_locale(Bliz_GetLootSlotLink(slot)) end

-- 打开拍卖行时 shift 点击背包物品
local HookContainerFrameItemButton_OnClick = ContainerFrameItemButton_OnClick
ContainerFrameItemButton_OnClick = function(button, ignoreShift)
	if IsShiftKeyDown() and not IsControlKeyDown() and not ignoreShift and not ChatFrameEditBox:IsVisible() and BrowseName and BrowseName:IsVisible() then
		local link = Bliz_GetContainerItemLink(this:GetParent():GetID(), this:GetID())
		local _, _, name = string.find(link, link_name_rex)
		BrowseName:SetText(name)
	else
		HookContainerFrameItemButton_OnClick(button, ignoreShift)
	end
end

-- Hook pfQuest start, ref pfQuest/compat/client.lua
local pfQuestOrigin, pfQuestLocale
if pfDB then
	pfQuestOrigin = pfDB["quests"]["loc"] -- 注：不能直接 HOOK 这个引用, 因为 pfQuest 对它依赖，比如与本地的 GetNumQuestLogEntries() 对比
	pfQuestLocale = pfQuestOrigin
	function pfQuestCompat.InsertQuestLink(questid, name)
		local questid = questid or 0
		local fallback = name or UNKNOWN
		local level = pfDB["quests"]["data"][questid] and pfDB["quests"]["data"][questid]["lvl"] or 0
		local name = pfQuestLocale[questid] and pfQuestLocale[questid]["T"] or fallback
		local hex = pfUI.api.rgbhex(GetDifficultyColor(level))
		ChatFrameEditBox:Show()
		if pfQuest_config["questlinks"] == "1" then
			ChatFrameEditBox:Insert(hex .. "|Hquest:" .. questid .. ":" .. level .. "|h[" .. name .. "]|h|r")
		else
			ChatFrameEditBox:Insert("[" .. name .. "]")
		end
	end
end

local function HookGetLocaleItemLink(mode)
	if mode and ((mode == "cn" and OPLANG == IDX_zhCN) or (mode == "en" and OPLANG == IDX_enUS)) then
		GetAuctionItemLink = Trans_GetAuctionItemLink
		GetMerchantItemLink = Trans_GetMerchantItemLink
		GetContainerItemLink = Trans_GetContainerItemLink
		GetInventoryItemLink = Trans_GetInventoryItemLink
		GetTradeSkillItemLink = Trans_GetTradeSkillItemLink
		GetTradeSkillReagentItemLink = Trans_GetTradeSkillReagentItemLink
		GetCraftReagentItemLink = Trans_GetCraftReagentItemLink
		GetCraftItemLink = Trans_GetCraftItemLink
		GetLootSlotLink = Trans_GetLootSlotLink
		if pfDB then
			pfQuestLocale = mode == "cn" and pfDB["quests"]["zhCN"] or pfDB["quests"]["enUS"]
		end
	else
		GetAuctionItemLink = Bliz_GetAuctionItemLink
		GetMerchantItemLink = Bliz_GetMerchantItemLink
		GetContainerItemLink = Bliz_GetContainerItemLink
		GetInventoryItemLink = Bliz_GetInventoryItemLink
		GetTradeSkillItemLink = Bliz_GetTradeSkillItemLink
		GetTradeSkillReagentItemLink = Bliz_GetTradeSkillReagentItemLink
		GetCraftReagentItemLink = Bliz_GetCraftReagentItemLink
		GetCraftItemLink = Bliz_GetCraftItemLink
		GetLootSlotLink = Bliz_GetLootSlotLink
		pfQuestLocale = pfQuestOrigin
	end
end

local function StateUpdate(rbtn)
	local mode = RDbItemsCfg.mode -- ## SavedVariables
	HookGetLocaleItemLink(mode)
	if mode == "en" then
		rbtn:SetText("E")
	elseif mode == "cn" then
		rbtn:SetText("中")
	else
		rbtn:SetText("--")
	end
end
-- global functions
function itemDB.TriStateToggle(rbtn)
	if RDbItemsCfg.mode == "en" then
		RDbItemsCfg.mode = "cn"
	elseif RDbItemsCfg.mode == "cn" then
		RDbItemsCfg.mode = nil
	else
		RDbItemsCfg.mode = "en"
	end
	StateUpdate(rbtn)
end

local Cheapest = { time = 0, ctrl = 0 }

function itemDB.Init(rbtn)
	if pfUI and pfUI.chat then
		rbtn:DisableDrawLayer("BACKGROUND")
		rbtn:ClearAllPoints()
		rbtn:SetParent(pfUI.chat.left.panelTop)
		rbtn:SetPoint("TOPRIGHT", pfUI.chat.left, "TOPRIGHT", -38, -1.5)
		rbtn:SetWidth(16)
		rbtn:SetHeight(16)
		rbtn:SetAlpha(0.5)
	end
	rbtn:RegisterEvent("VARIABLES_LOADED")
	rbtn:SetScript("OnEvent", function()
		if not RDbItemsCfg then RDbItemsCfg = {} end
		if not RDbItemsCfg.NoCheapest then
			rbtn:SetScript("OnUpdate", Cheapest.OnUpdate)
		end
		StateUpdate(rbtn)
		rbtn:UnregisterEvent("VARIABLES_LOADED")
		rbtn:SetScript("OnEvent", nil)
	end)
	HookGameTooltip()
	rbtn:Show()
end

--[[
用于将物品以指定的文字描述发送到聊天窗口,
 - "--"(auto): 直接使用当前客户端语言, 即不进行处理
 - "E"(英): 当往聊天窗口输物品链接时,使用英文名称
 - "中"(中文): 当往聊天窗口输物品链接时,使用中文名称

特性:
 - 支持 shift + 点击 输出到拍卖行, 这将会强制以英文输出, 目前支持 "背包","专业","聊天窗口中链接"
 - 打开背包按下 ctrl 后将会“高亮”(暗红)最便宜的垃圾物品
--]]

function Cheapest.OnUpdate()
	local time = GetTime()
	if (time - Cheapest.time) < 0.1 then return end -- 10FPS
	Cheapest.time = time
	-- MODIFIER_STATE_CHANGED
	local ctrl = IsControlKeyDown()
	if ctrl ~= Cheapest.ctrl then
		if ctrl == 1 then Cheapest:Query() end
		Cheapest.ctrl = ctrl
	end
end

function Cheapest.Flash(self, bagId, slot)
	local item
	if pfUI and pfUI.bags then
		item = pfUI.bags[bagId].slots[slot].frame
	elseif Bagnon or SUCC_bag then
		local bagnon = Bagnon or SUCC_bag
		if not bagnon:IsShown() then return end
		local index = slot
		for i = 0, bagId - 1 do
			index = index + GetContainerNumSlots(i)
		end
		item = getglobal(bagnon:GetName() .. "Item" .. index)
	elseif OneBag then
		item = OneBag.frame.bags[bagId][slot]
	else
		for i = 1, NUM_CONTAINER_FRAMES do
			local frame = getglobal("ContainerFrame".. i)
			if frame:GetID() == bagId then
				item = frame:IsShown() and getglobal("ContainerFrame" .. i .."Item" .. (GetContainerNumSlots(bagId) + 1 - slot)) or nil
				break
			end
		end
	end
	if item then
		-- TODO: Animation
		SetItemButtonTextureVertexColor(item, 1, 0, 0) -- #FF0000
		-- itemDB.trace(tostring(item:GetName()) .. ", bagid: ".. bagId ..", slot: ".. slot)
	end
end

function Cheapest.Query(self)
	local lastPrice, lastBag, lastSlot
	for bag = 0, NUM_BAG_SLOTS do
		for bagSlot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, bagSlot)
			local type, sid = link_parse(link or "")
			local data = load_itemdata(type, sid)
			if data and type == "item" then
				local _, _, itemRarity = GetItemInfo(tonumber(sid))
				local vendorPrice = data[IDX_PRICE]
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
	if lastSlot then
		self:Flash(lastBag, lastSlot)
	end
end
