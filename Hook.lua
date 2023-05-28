local LANG = GetLocale() ~= "enUS" and 1 or 2;

local function AName(id)
  return '|cffaaaaaa' .. RDbItems[id][LANG] .. '|r';
end

local function IdALvl(id)
	return "|cffaaaaaaLv ".. RDbItems[id][3] .. "|r","|cffaaaaaaID ".. id .. "|r";
end

-- item:6948:0:0:0
local function LinkToID(link)
	if link then
		local _, _, id = string.find(link, ":(%d+)");
		return tonumber(id);
	end
end

local function LinkToItemName(link)
	local _,_, name = string.find(link,"%[([^%]]+)%]");
	return name;
end

local function Add2Tooltip(tooltip, itemId)
	if RDbItems[itemId] then
		tooltip:AddLine(AName(itemId));
		if RDbItems[itemId][4] > 0 then SetTooltipMoney(tooltip, RDbItems[itemId][4]) end;
		tooltip:AddDoubleLine(IdALvl(itemId))
		tooltip:Show();
	end
end

local function LinkTrans(link, c)
	if not c then c = RDbItemsCC end;
	if LANG == 1 then -- 中文客户端
		if c == "en" then
			local itemId = LinkToID(link);
			if RDbItems[itemId] then
				link = gsub(link, "%[([^%]]+)%]", "[".. RDbItems[itemId][1] .."]")
			end
		end
	else
		if c == "cn" then
			local itemId = LinkToID(link);
			if RDbItems[itemId] then
				link = gsub(link, "%[([^%]]+)%]", "[".. RDbItems[itemId][2] .."]")
			end
		end
	end
	return link;
end

local Bliz_GameTooltip_SetInventoryItem = GameTooltip.SetInventoryItem;
GameTooltip.SetInventoryItem = function(self, unit, slot)
	-- DEFAULT_CHAT_FRAME:AddMessage(tostring(unit))
	local hasItem,hasCooldown, repairCost = Bliz_GameTooltip_SetInventoryItem(self, unit, slot);
	if hasItem then
		Add2Tooltip(self, LinkToID(GetInventoryItemLink(unit, slot)));
	end
	return hasItem,hasCooldown, repairCost;
end

local Bliz_PaperDollItemSlotButton_OnEnter = PaperDollItemSlotButton_OnEnter;
function PaperDollItemSlotButton_OnEnter()
	if GameTooltip:IsVisible() then return end;
	Bliz_PaperDollItemSlotButton_OnEnter(this);
end

-- 背包物品
local Bliz_GetContainerItemLink = GetContainerItemLink;
local function Trans_GetContainerItemLink(bag, slot) return LinkTrans(Bliz_GetContainerItemLink(bag, slot)) end;

-- overwrite FrameXML/ContainerFrame.lua
local Bliz_ContainerFrameItemButton_OnClick = ContainerFrameItemButton_OnClick;
ContainerFrameItemButton_OnClick = function(button, ignoreShift)
	if not IsControlKeyDown() and IsShiftKeyDown() and not ignoreShift and not ChatFrameEditBox:IsVisible() and BrowseName ~= nil and BrowseName:IsVisible() then
		local link = Bliz_GetContainerItemLink(this:GetParent():GetID(), this:GetID());
		if LANG == 1 then	-- 非英文, 未测试
			local itemId = LinkToID( link )
			if RDbItems[itemId] then
				BrowseName:SetText( RDbItems[itemId][1] )
			else
				BrowseName:SetText( LinkToItemName(link) ); -- 即使是中文客户端, 有些物品也是英文的
				DEFAULT_CHAT_FRAME:AddMessage( "目前暂时没有收录,请自行搜索..." );
				PlaySound("TellMessage");
			end
		else
			BrowseName:SetText( LinkToItemName(link) );
		end
	else
		Bliz_ContainerFrameItemButton_OnClick(button, ignoreShift);
	end
end

local Bliz_KeyRingItemButton_OnClick = KeyRingItemButton_OnClick;
KeyRingItemButton_OnClick = function(button)
	if not IsControlKeyDown() then
		if button == "LeftButton" and IsShiftKeyDown() then
			if ChatFrameEditBox:IsVisible() then
				local link = GetContainerItemLink(this:GetParent():GetID(), this:GetID());
				ChatFrameEditBox:Insert(LinkTrans(link));
			end
		else
			Bliz_KeyRingItemButton_OnClick(button);
		end
	end
end

-- 银行 copy from FrameXML/BankFrame.lua
local Bliz_BankFrameItemButtonGeneric_OnClick = BankFrameItemButtonGeneric_OnClick;
BankFrameItemButtonGeneric_OnClick = function(button)
	if ChatFrameEditBox:IsVisible() and IsShiftKeyDown() and not this.isBag and button == "LeftButton" then
		ChatFrameEditBox:Insert(LinkTrans(GetContainerItemLink(BANK_CONTAINER, this:GetID())));
	else
		Bliz_BankFrameItemButtonGeneric_OnClick(button)
	end
end

local Bliz_GameTooltip_SetLootItem = GameTooltip.SetLootItem;
GameTooltip.SetLootItem = function(self, slot)
	Bliz_GameTooltip_SetLootItem(self, slot);
	Add2Tooltip(self, LinkToID(GetLootSlotLink(slot)));
end

local Bliz_SetHyperlink = GameTooltip.SetHyperlink;
GameTooltip.SetHyperlink = function(self, link)
	Bliz_SetHyperlink(self, link);
	local _, _, linkType, itemIdStr = string.find(link, "(%l+):(%d+)");
	if linkType == "item" then
		Add2Tooltip(self, tonumber(itemIdStr));
	end
end

local Bliz_GameTooltip_SetLootRollItem = GameTooltip.SetLootRollItem;
GameTooltip.SetLootRollItem = function(self, rollID)
	Bliz_GameTooltip_SetLootRollItem(self, rollID);
	local _, _, linkType, itemIdStr = string.find(GetLootRollItemLink(rollID), "(%l+):(%d+)");
	if linkType == "item" then
		Add2Tooltip(self, tonumber(itemIdStr));
	end
end

local Bliz_SetItemRef = SetItemRef;
SetItemRef = function(item, link, button)
	local itemType, itemId;
	if not IsControlKeyDown() then
		itemId = LinkToID(item);
		if strsub(item, 1, 4) == "item" then
			if RDbItems[itemId] then
				itemType = "item";
				if IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then
					if RDbItemsCC == "en" then -- 强制选择,而不是使用 LinkTrans 来决定. 当转发聊天窗口中的 item 时
						link = gsub(link, "%[([^%]]+)%]", "[".. RDbItems[itemId][1] .."]");
					elseif RDbItemsCC == "cn" then
						link = gsub(link, "%[([^%]]+)%]", "[".. RDbItems[itemId][2] .."]");
					end
				end
			end;
		elseif RDbItemsEnchant and strsub(item, 1, 7) == "enchant" and RDbItemsEnchant[itemId] then
			itemType = "enchant";
			if IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then
				if RDbItemsCC == "en" then
					link = gsub(link, "%[([^%]]+)%]", "[".. RDbItemsEnchant[itemId][1] .."]");
				elseif RDbItemsCC == "cn" then
					link = gsub(link, "%[([^%]]+)%]", "[".. RDbItemsEnchant[itemId][2] .."]");
				end
			end
		end
	end

	Bliz_SetItemRef(item, link, button);

	if IsShiftKeyDown() then
		if not ChatFrameEditBox:IsVisible() and BrowseName ~= nil and BrowseName:IsVisible() and itemType == "item" then
			BrowseName:SetText(RDbItems[itemId][1]);
		end -- 1.121 附魔不可以附在纸上, 因此不考虑拍卖行中的附魔相关
	elseif itemType == "item" then
		Add2Tooltip(ItemRefTooltip, itemId); -- 实际对 link 的更改并不会影响 Tooltip 的显示
	elseif itemType == "enchant" then
		ItemRefTooltip:AddLine('|cffaaaaaa' .. RDbItemsEnchant[itemId][LANG] .. '|r');
		ItemRefTooltip:Show();
	end
end

local Bliz_GameTooltip_SetAuctionItem = GameTooltip.SetAuctionItem;
GameTooltip.SetAuctionItem = function(self, type, index)
	Bliz_GameTooltip_SetAuctionItem(self, type, index);
	Add2Tooltip(self, LinkToID(GetAuctionItemLink(type, index)));
end

-- 任务
local Bliz_GameTooltip_SetQuestItem = GameTooltip.SetQuestItem;
GameTooltip.SetQuestItem = function(self, itemType, index)
	Bliz_GameTooltip_SetQuestItem(self, itemType, index);
	Add2Tooltip(self, LinkToID(GetQuestItemLink(itemType,index)));
end
local Bliz_GameTooltip_SetQuestLogItem = GameTooltip.SetQuestLogItem;
GameTooltip.SetQuestLogItem = function(self, itemType, index)
	if itemType then
		Bliz_GameTooltip_SetQuestLogItem(self, itemType, index);
		Add2Tooltip(self, LinkToID(GetQuestLogItemLink(itemType,index)));
	end
end

-- 商业技能
local Bliz_GameTooltip_SetTradeSkillItem = GameTooltip.SetTradeSkillItem;
GameTooltip.SetTradeSkillItem = function(self, index, id)
	Bliz_GameTooltip_SetTradeSkillItem(self, index, id);
	local _, _,linkType, itemIdStr = string.find(id and GetTradeSkillReagentItemLink(index, id) or GetTradeSkillItemLink(index), "(%l+):(%d+)");
	local itemId = tonumber(itemIdStr);
	if linkType == "item" and RDbItems[itemId] then
		self:AddLine(AName(itemId));
		if not id then -- 有ID表示商业制造的物品所需求的物品
			if RDbItems[itemId][4] > 0 then SetTooltipMoney(self, RDbItems[itemId][4]) end;
			self:AddDoubleLine(IdALvl(itemId))
		end
		self:Show();
	end
end


-- 专业训练师, 可通过 GameTooltip:SetTrainerService 获得, 但是由于 classic 不支持 GetTrainerServiceItemLink 从而无法获得物品的 ID 值

-- 附魔, 材料
local Bliz_GameTooltip_SetCraftItem = GameTooltip.SetCraftItem;
GameTooltip.SetCraftItem = function(self, index, id)
	Bliz_GameTooltip_SetCraftItem(self, index, id);
	local itemId = LinkToID(GetCraftReagentItemLink(index, id))
	if RDbItems[itemId] then
		self:AddLine(AName(itemId));
		self:Show();
	end
end

-- 附魔,依赖于 RDbItemsEnchant
local function EnchantLinkTrans(link, c)
	if not c then c = RDbItemsCC end;
	if LANG == 1 then -- 中文客户端
		if c == "en" then
			local enchantId = LinkToID(link);
			if RDbItemsEnchant[enchantId] then
				link = gsub(link, "%[([^%]]+)%]", "[".. RDbItemsEnchant[enchantId][1] .."]")
			end
		end
	else
		if c == "cn" then
			local enchantId = LinkToID(link);
			if RDbItemsEnchant[enchantId] then
				link = gsub(link, "%[([^%]]+)%]", "[".. RDbItemsEnchant[enchantId][2] .."]")
			end
		end
	end
	return link;
end

if RDbItemsEnchant then
	local Bliz_GameTooltip_SetCraftSpell = GameTooltip.SetCraftSpell;
	GameTooltip.SetCraftSpell = function(self, index)
		Bliz_GameTooltip_SetCraftSpell(self, index);
		-- local _, _,linkType, itemIdStr = string.find(GetCraftItemLink(index),"(%l+):(%d+)")
		-- DEFAULT_CHAT_FRAME:AddMessage(linkType .. " - " .. itemIdStr)
		local enchantId = LinkToID(GetCraftItemLink(index));
		if RDbItemsEnchant[enchantId] then
			self:AddLine( '|cffaaaaaa' .. RDbItemsEnchant[enchantId][LANG] .. '|r' );
			self:Show();
		end
	end
end

-- 购买
local Bliz_GameTooltip_SetMerchantItem = GameTooltip.SetMerchantItem;
GameTooltip.SetMerchantItem = function(self, index)
	Bliz_GameTooltip_SetMerchantItem(self, index);
	local itemId = LinkToID(GetMerchantItemLink(index));
	if RDbItems[itemId] then
		self:AddLine(AName(itemId));
		self:Show();
	end
end

-- 点击商业技能时
local Bliz_GetTradeSkillReagentItemLink,Bliz_GetTradeSkillItemLink = GetTradeSkillReagentItemLink,GetTradeSkillItemLink;
local function Trans_GetTradeSkillReagentItemLink(index, id) return LinkTrans(Bliz_GetTradeSkillReagentItemLink(index, id)) end
local function Trans_GetTradeSkillItemLink(index) return LinkTrans(Bliz_GetTradeSkillItemLink(index)) end

-- 附魔
local Bliz_GetCraftItemLink, Bliz_GetCraftReagentItemLink = GetCraftItemLink, GetCraftReagentItemLink;
local function Trans_GetCraftItemLink(index) return EnchantLinkTrans(Bliz_GetCraftItemLink(index)) end;
local function Trans_GetCraftReagentItemLink(index, id) return LinkTrans(Bliz_GetCraftReagentItemLink(index, id)) end;

-- 拍卖行物品
local Bliz_GetAuctionItemLink = GetAuctionItemLink;
local function Trans_GetAuctionItemLink(ty, index) return LinkTrans(Bliz_GetAuctionItemLink(ty, index)) end;

-- 商人
local Bliz_GetMerchantItemLink = GetMerchantItemLink;
local function Trans_GetMerchantItemLink(index) return LinkTrans(Bliz_GetMerchantItemLink(index)) end;

-- 查看装备
local Bliz_GetInventoryItemLink = GetInventoryItemLink;
local function Trans_GetInventoryItemLink(unit, slot) return LinkTrans(Bliz_GetInventoryItemLink(unit, slot)) end;


--[[ -- EQL3 的更好..任务加上任务等级, copy from FrameXML/QuestLogFrame.lua
local Bliz_QuestLogTitleButton_OnClick = QuestLogTitleButton_OnClick;
QuestLogTitleButton_OnClick = function(button)
	if ChatFrameEditBox:IsVisible() and IsShiftKeyDown() then
		local title, lvl,elite = GetQuestLogTitle(this:GetID() + FauxScrollFrame_GetOffset(QuestLogListScrollFrame));
		ChatFrameEditBox:Insert("[".. lvl .. (elite == "Elite" and "+" or "") .."]" .. title );
	else
		Bliz_QuestLogTitleButton_OnClick(button);
	end
end
--]]

local function TransHook(mode)
	if not mode then
		GetTradeSkillReagentItemLink,GetTradeSkillItemLink = Bliz_GetTradeSkillReagentItemLink,Bliz_GetTradeSkillItemLink;
		if RDbItemsEnchant then GetCraftItemLink = Bliz_GetCraftItemLink end;
		GetCraftReagentItemLink = Bliz_GetCraftReagentItemLink;
		GetAuctionItemLink = Bliz_GetAuctionItemLink;
		GetMerchantItemLink = Bliz_GetMerchantItemLink;
		GetInventoryItemLink = Bliz_GetInventoryItemLink
		GetContainerItemLink = Bliz_GetContainerItemLink;
	else
		GetTradeSkillReagentItemLink,GetTradeSkillItemLink = Trans_GetTradeSkillReagentItemLink, Trans_GetTradeSkillItemLink;
		if RDbItemsEnchant then GetCraftItemLink = Trans_GetCraftItemLink end;
		GetCraftReagentItemLink = Trans_GetCraftReagentItemLink;
		GetAuctionItemLink = Trans_GetAuctionItemLink;
		GetMerchantItemLink = Trans_GetMerchantItemLink;
		GetInventoryItemLink = Trans_GetInventoryItemLink;
		GetContainerItemLink = Trans_GetContainerItemLink;
	end
end

 --

local function ModeUpdate(self)
	local mode = RDbItemsCC -- ## SavedVariables
	TransHook(mode)
	if mode == "en" then
		self:SetText("E")
	elseif mode == "cn" then
		self:SetText("中")
	else
		self:SetText("--")
	end
end

local function ModeToggle(self)
	if RDbItemsCC == "en" then
		RDbItemsCC = "cn"
	elseif RDbItemsCC == "cn" then
		RDbItemsCC = nil
	else
		RDbItemsCC = "en"
	end
	ModeUpdate(self)
end

function RDbFrameOnLoaded(self)
	self.ModeToggle = ModeToggle
	self:RegisterEvent("VARIABLES_LOADED");
	self:SetScript("OnEvent", function()
		local evt = event
		if evt == "VARIABLES_LOADED" then
			ModeUpdate(self)
		end
	end)
	DEFAULT_CHAT_FRAME:AddMessage(self:GetName() .. " loaded")
	-- Copy From FrameXML/ContainerFrame.lua,
	ContainerFrameItemButton_OnEnter = function()
		if not this.hasItem then return end
		if ( IsControlKeyDown() ) then -- 由于这个版本没找到 IsDressableItem 或类似方法, 因此不检测
			ShowInspectCursor();
		elseif IsShiftKeyDown() then
			ResetCursor();
		elseif MerchantFrame:IsVisible() then
			ShowContainerSellCursor(this:GetParent():GetID(), this:GetID());
		elseif this.readable then
			ShowInspectCursor();
		else
			ResetCursor();
		end

		if GameTooltip:IsVisible() then return end;
		GameTooltip:SetOwner(this, "ANCHOR_LEFT");
		local bag = this:GetParent():GetID();
		local slot = this:GetID();
		if bag == KEYRING_CONTAINER then -- 钥匙链并不属于背包中的物品, 而是像一个无限增长的装备slot
			Bliz_GameTooltip_SetInventoryItem(GameTooltip, "player", KeyRingButtonIDToInvSlotID(slot)); -- 在 github 中搜索 KEYRING_CONTAINER GameTooltip 获得这个 API
		else
			local hasCooldown, repairCost = GameTooltip:SetBagItem(bag, slot);
			if ( hasCooldown ) then
				this.updateTooltip = TOOLTIP_UPDATE_TIME;
			else
				this.updateTooltip = nil;
			end

			if ( InRepairMode() and (repairCost and repairCost > 0) ) then
				GameTooltip:AddLine(TEXT(REPAIR_COST), "", 1, 1, 1);
				SetTooltipMoney(GameTooltip, repairCost);
			end
		end

		local itemId = LinkToID(GetContainerItemLink(bag, slot));
		if RDbItems[itemId] then
			GameTooltip:AddLine(AName(itemId));
			if not MerchantFrame:IsVisible() and RDbItems[itemId][4] > 0 then SetTooltipMoney(GameTooltip, RDbItems[itemId][4] * this.count) end;
			GameTooltip:AddDoubleLine(IdALvl(itemId));
		end
		GameTooltip:Show();
		--for k,v in pairs(this) do
		--	DEFAULT_CHAT_FRAME:AddMessage(tostring(k) .. " - " ..tostring(v));
		--end
	end
end
--[[
用于将物品以指定的文字描述发送到聊天窗口,
 - @(auto): 直接使用当前客户端语言, 即不进行处理
 - E(英): 当往聊天窗口输物品链接时,使用英文名称
 - 中(中文): 当往聊天窗口输物品链接时,使用中文名称

特性:
 - 支持 shift + 点击 输出到拍卖行, 这将会强制以英文输出, 目前支持 "背包","专业","聊天窗口中链接"

更新:
 - 移除旧的slash模式, 通过点击聊天窗口的 `@` 按钮切换模式
--]]
