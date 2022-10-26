--[[
  TitanHonor: A simple Display of current Honor value
  Author: Blakenfeder
--]]

-- Define addon base object
local TitanHonor = {
  Const = {
    Id = "Honor",
    Name = "TitanHonor",
    DisplayName = "Titan Panel [Honor]",
    Version = "",
    Author = "",
  },
  IsInitialized = false,
}
function TitanHonor.GetCurrencyInfo()
  local i = 0
  for i = 1, C_CurrencyInfo.GetCurrencyListSize(), 1 do
    info = C_CurrencyInfo.GetCurrencyListInfo(i)    
    if tostring(info.iconFileID) == "1455894" then
      return info
    end
  end
end
function TitanHonor.Util_GetFormattedNumber(number)
  if number >= 1000 then
    return string.format("%d,%03d", number / 1000, number % 1000)
  else
    return string.format ("%d", number)
  end
end

-- Load metadata
TitanHonor.Const.Version = GetAddOnMetadata(TitanHonor.Const.Name, "Version")
TitanHonor.Const.Author = GetAddOnMetadata(TitanHonor.Const.Name, "Author")

-- Text colors (AARRGGBB)
local BKFD_C_BURGUNDY = "|cff993300"
local BKFD_C_GRAY = "|cff999999"
local BKFD_C_GREEN = "|cff00ff00"
local BKFD_C_ORANGE = "|cffff8000"
local BKFD_C_RED = "|cffff0000"
local BKFD_C_WHITE = "|cffffffff"
local BKFD_C_YELLOW = "|cffffcc00"

-- Text item colors (AARRGGBB)
local BKFD_C_COMMON = "|cffffffff"
local BKFD_C_UNCOMMON = "|cff1eff00"
local BKFD_C_RARE = "|cff0070dd"
local BKFD_C_EPIC = "|cffa335ee"
local BKFD_C_LEGENDARY = "|cffff8000"
local BKFD_C_ARTIFACT = "|cffe5cc80"
local BKFD_C_BLIZZARD = "|cff00ccff"

-- Load Library references
local LT = LibStub("AceLocale-3.0"):GetLocale("Titan", true)
local L = LibStub("AceLocale-3.0"):GetLocale(TitanHonor.Const.Id, true)

-- Currency update variables
local BKFD_HO_UPDATE_FREQUENCY = 0.0
local currencyCount = 0.0
local currencyMaximum
local seasonalCount = 0.0
local isSeasonal = false
local currencyDiscovered = false

function TitanPanelHonorButton_OnLoad(self)
  self.registry = {
    id = TitanHonor.Const.Id,
    category = "Information",
    version = TitanHonor.Const.Version,
    menuText = L["BKFD_TITAN_HO_MENU_TEXT"], 
    buttonTextFunction = "TitanPanelHonorButton_GetButtonText",
    tooltipTitle = BKFD_C_RARE..L["BKFD_TITAN_HO_TOOLTIP_TITLE"],
    tooltipTextFunction = "TitanPanelHonorButton_GetTooltipText",
    icon = "Interface\\Icons\\achievement_legionpvptier4",
    iconWidth = 16,
    controlVariables = {
      ShowIcon = true,
      ShowLabelText = true,
    },
    savedVariables = {
      ShowIcon = 1,
      ShowLabelText = false,
      ShowColoredText = false,
    },
    -- frequency = 2,
  };


  self:RegisterEvent("PLAYER_ENTERING_WORLD");
  self:RegisterEvent("PLAYER_LOGOUT");
end

function TitanPanelHonorButton_GetButtonText(id)
  local currencyCountText
  if not currencyCount then
    currencyCountText = "0"
  else  
    currencyCountText = TitanHonor.Util_GetFormattedNumber(currencyCount)
  end

  if (currencyMaximum and not(currencyMaximum == 0) and currencyCount and currencyMaximum == currencyCount) then
    currencyCountText = BKFD_C_RED..currencyCountText
  end

  return L["BKFD_TITAN_HO_BUTTON_LABEL"], TitanUtils_GetHighlightText(currencyCountText)
end

function TitanPanelHonorButton_GetTooltipText()
  if (not currencyDiscovered) then
    return
      L["BKFD_TITAN_HO_TOOLTIP_DESCRIPTION"].."\r"..
      " \r"..
      TitanUtils_GetHighlightText(L["BKFD_TITAN_HO_TOOLTIP_NOT_YET_DISCOVERED"])
  end

  -- Set which total value will be displayed
  local tooltipCurrencyCount = currencyCount
  if (isSeasonal) then
    tooltipCurrencyCount = seasonalCount
  end

  -- Set how the total value will be displayed
  local totalValue = string.format(
    "%s/%s",
    TitanHonor.Util_GetFormattedNumber(tooltipCurrencyCount),
    TitanHonor.Util_GetFormattedNumber(currencyMaximum)
  )
  if (not currencyMaximum or currencyMaximum == 0) then
    totalValue = string.format(
      "%s",
      TitanHonor.Util_GetFormattedNumber(tooltipCurrencyCount)
    )
  elseif (currencyMaximum == tooltipCurrencyCount) then
    totalValue = BKFD_C_RED..totalValue
  end
  
  local totalLabel = L["BKFD_TITAN_HO_TOOLTIP_COUNT_LABEL_TOTAL_MAXIMUM"]
  if (isSeasonal) then
    totalLabel = L["BKFD_TITAN_HO_TOOLTIP_COUNT_LABEL_TOTAL_SEASONAL"]
  elseif (not currencyMaximum or currencyMaximum == 0) then
    totalLabel = L["BKFD_TITAN_HO_TOOLTIP_COUNT_LABEL_TOTAL"]
  end

  return
    L["BKFD_TITAN_HO_TOOLTIP_DESCRIPTION"].."\r"..
    " \r"..
    totalLabel..TitanUtils_GetHighlightText(totalValue)
end

function TitanPanelHonorButton_OnUpdate(self, elapsed)
  BKFD_HO_UPDATE_FREQUENCY = BKFD_HO_UPDATE_FREQUENCY - elapsed;

  if BKFD_HO_UPDATE_FREQUENCY <= 0 then
    BKFD_HO_UPDATE_FREQUENCY = 1;

    local info = TitanHonor.GetCurrencyInfo()
    if (info) then
      currencyDiscovered = true
      currencyCount = tonumber(info.quantity)
      currencyMaximum = tonumber(info.maxQuantity)
      seasonalCount = tonumber(info.totalEarned)
      isSeasonal = info.useTotalEarnedForMaxQty
    end

    TitanPanelButton_UpdateButton(TitanHonor.Const.Id)
  end
end

function TitanPanelHonorButton_OnEvent(self, event, ...)
  if (event == "PLAYER_ENTERING_WORLD") then
    if (not TitanHonor.IsInitialized and DEFAULT_CHAT_FRAME) then
      DEFAULT_CHAT_FRAME:AddMessage(
        BKFD_C_YELLOW..TitanHonor.Const.DisplayName.." "..
        BKFD_C_GREEN..TitanHonor.Const.Version..
        BKFD_C_YELLOW.." by "..
        BKFD_C_ORANGE..TitanHonor.Const.Author)
      -- TitanHonor.GetCurrencyInfo()
      TitanPanelButton_UpdateButton(TitanHonor.Const.Id)
      TitanHonor.IsInitialized = true
    end
    return;
  end  
  if (event == "PLAYER_LOGOUT") then
    TitanHonor.IsInitialized = false;
    return;
  end
end

function TitanPanelRightClickMenu_PrepareHonorMenu()
  local id = TitanHonor.Const.Id;

  TitanPanelRightClickMenu_AddTitle(TitanPlugins[id].menuText)
  
  TitanPanelRightClickMenu_AddToggleIcon(id)
  TitanPanelRightClickMenu_AddToggleLabelText(id)
  TitanPanelRightClickMenu_AddSpacer()
  TitanPanelRightClickMenu_AddCommand(LT["TITAN_PANEL_MENU_HIDE"], id, TITAN_PANEL_MENU_FUNC_HIDE)
end