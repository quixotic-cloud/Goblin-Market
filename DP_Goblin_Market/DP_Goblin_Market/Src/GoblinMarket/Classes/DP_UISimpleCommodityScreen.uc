class DP_UISimpleCommodityScreen extends UIInventory;

// From GPIntelOptions
var array<MissionIntelOption> arrIntelItems;
// var array<Commodity>		arrItems;
var int						iSelectedItem;
var array<StateObjectReference> m_arrRefs;

var bool		m_bShowButton;
var bool		m_bInfoOnly;
var EUIState	m_eMainColor;
var EUIConfirmButtonStyle m_eStyle;
var int ConfirmButtonX;
var int ConfirmButtonY;

var UIText OptionDescText;

var public localized String m_strBuy;

simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	// Implement in subclasses
}

simulated function GetItems()
{
	// Implement in subclasses
}

//-------------- UI LAYOUT --------------------------------------------------------
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	// Move and resize list to accommodate label
	List.OnItemDoubleClicked = OnPurchaseClicked;

	SetBuiltLabel("");

	GetItems();

	// May need to remove this...
	SetChooseResearchLayout();
	PopulateData();
}

// This may be where we replace the items with the hacker rewards
// Where do we add intel description
// ArrItems is populated in child class in getItems method
simulated function PopulateData()
{
//	local Commodity Template;
	local MissionIntelOption Template;
	// Using this from Elad's suggestion...
	local UIMechaListItem MyItem;
	local int i;

	List.ClearItems();
	// May need to comment this out..
//	PopulateItemCard();
	
	for(i = 0; i < arrIntelItems.Length; i++)
	{
		MyItem = none; 
		Template = arrIntelItems[i];
		if(i < m_arrRefs.Length)
		{
			Spawn(class'DP_UIInventory_ListItem', List.itemContainer).InitInventoryListCommodity(Template, m_arrRefs[i], GetButtonString(i), m_eStyle, ConfirmButtonX, ConfirmButtonY);
//		MyItem=Spawn(class'UIMechaListItem', List.itemContainer).InitListItem();
//		MyItem.UpdateDataButton(string(arrIntelItems[i].IntelRewardName), GetButtonString(i), OnPurchaseClicked);
		}
		else
		{
			Spawn(class'DP_UIInventory_ListItem', List.itemContainer).InitInventoryListCommodity(Template, , GetButtonString(i), m_eStyle, ConfirmButtonX, ConfirmButtonY);
//		MyItem=Spawn(class'UIMechaListItem', List.itemContainer).InitListItem();
//		MyItem.UpdateDataButton("NOTHING HERE MOVE ALONG", GetButtonString(i), OnPurchaseClicked);
		}
	}

//	if(List.ItemCount > 0)
//	{
//		List.SetSelectedIndex(0);
//		if( bUseSimpleCard )
//			PopulateSimpleCommodityCard(UIInventory_ListItem(List.GetItem(0)).ItemComodity, UIInventory_ListItem(List.GetItem(0)).ItemRef);
//		else
//			PopulateResearchCard(UIInventory_ListItem(List.GetItem(0)).ItemComodity, UIInventory_ListItem(List.GetItem(0)).ItemRef);
//	}

	if(List.ItemCount == 0 && m_strEmptyListTitle != "")
	{
		TitleHeader.SetText(m_strTitle, m_strEmptyListTitle);
		SetCategory("");
	}
}

// Use this to create initial list population above and then delete!
simulated function SelectIntelItem(UIList ContainerList, int ItemIndex)
{
	local MissionIntelOption SelectedOption;
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;
	local XComGameState_MissionSite MissionState;
	
	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	//SelectedOption = GetMission().IntelOptions[ItemIndex];
	//MissionState = XComGameState_MissionSite(XCOMHISTORY.GetGameStateForObjectID(MissionRef.ObjectID));
	//SelectedOption = MissionState.IntelOptions[ItemIndex];
	SelectedOption = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(UIMission(Screen).MissionRef.ObjectID)).IntelOptions[ItemIndex];
	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(SelectedOption.IntelRewardName);

	OptionDescText.SetText(OptionTemplate.GetDescription(none));
}

//simulated function int GetItemIndex(Commodity Item)
simulated function int GetItemIndex(MissionIntelOption Item)
{
	local int i;

	for(i = 0; i < arrIntelItems.Length; i++)
	{
		if(arrIntelItems[i] == Item)
		{
			return i;
		}
	}

	return -1;
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
//simulated function String GetItemString(int ItemIndex)
//{
//	if( ItemIndex > -1 && ItemIndex < arrItems.Length )
//	{
//		return arrItems[ItemIndex].Title;
//	}
//	else
//	{
//		return "";
//	}
//}
simulated function X2HackRewardTemplate GetItemTemplate(int ItemIndex)
{
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;
	
	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(arrIntelItems[ItemIndex].IntelRewardName);
	return OptionTemplate;
}
simulated function String GetItemImage(int ItemIndex)
{
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;
	
	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(arrIntelItems[ItemIndex].IntelRewardName);

	if( ItemIndex > -1 && ItemIndex < arrIntelItems.Length )
	{
		return OptionTemplate.RewardImagePath;
	}
	else
	{
		return "";
	}
}

simulated function String GetItemCostString(int ItemIndex)
{
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;
	
	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(arrIntelItems[ItemIndex].IntelRewardName);
	if( ItemIndex > -1 && ItemIndex < arrIntelItems.Length )
	{
		return ""$int(((OptionTemplate.MaxIntelCost+OptionTemplate.MinHackSuccess)/2.0f)) ;
	}
	else
	{
		return "";
	}
}

//simulated function String GetItemReqString(int ItemIndex)
//{
//	if( ItemIndex > -1 && ItemIndex < arrItems.Length )
//	{
//		return class'UIUtilities_Strategy'.static.GetStrategyReqString(arrItems[ItemIndex].Requirements);
//	}
//	else
//	{
//		return "";
//	}
//}

//simulated function String GetItemDurationString(int ItemIndex)
//{
//	if (ItemIndex > -1 && ItemIndex < arrItems.Length)
//	{
//		return class'UIUtilities_Text'.static.GetTimeRemainingString(arrItems[ItemIndex].OrderHours);
//	}
//	else
//	{
//		return "";
//	}
//}

simulated function String GetItemDescString(int ItemIndex)
{
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;
	
	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(arrIntelItems[ItemIndex].IntelRewardName);

	if( ItemIndex > -1 && ItemIndex < arrIntelItems.Length )
	{
		return OptionTemplate.GetDescription(none);
	}
	else
	{
		return "";
	}
}

simulated function bool NeedsAttention(int ItemIndex)
{
	// Implement in subclasses
	return false;
}
simulated function bool ShouldShowGoodState(int ItemIndex)
{
	// Implement in subclasses
	return false;
}

// TODO: Use null check for list, but replace with intel check
simulated function bool CanAffordItem(int ItemIndex)
{
	if( ItemIndex > -1 && ItemIndex < arrIntelItems.Length )
	{
//		return XComHQ.CanAffordCommodity(arrItems[ItemIndex]);
		return CanAffordIntelOptions(arrIntelItems[ItemIndex]);
	}
	else
	{
		return false;
	}
}

// Original logic that assumes player purchases all intel options at once.
//simulated function bool CanAffordIntelOptions()
simulated function bool CanAffordIntelOptions(MissionIntelOption IntelOption)
{
//	return (GetTotalIntelCost() <= GetAvailableIntel());
	return (GetIntelCost(IntelOption) <= GetAvailableIntel());
}

// Gets the player's intel amount
simulated function int GetAvailableIntel()
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().GetResourceAmount('Intel');
}

// gets the until cost of the reward. Not sure if one reward at a time.
simulated function int GetIntelCost(MissionIntelOption IntelOption)
{
	return class'UIUtilities_Strategy'.static.GetCostQuantity(IntelOption.Cost, 'Intel');
}

//Gets the total cost of all intel options selected. Will not be used in BM type list
//simulated function int GetTotalIntelCost()
//{
//	local MissionIntelOption IntelOption;
//	local int TotalCost;

//	foreach SelectedOptions(IntelOption)
//	{
//		TotalCost += class'UIUtilities_Strategy'.static.GetCostQuantity(IntelOption.Cost, 'Intel');
//	}

//	return TotalCost;
//}

// Not seeing where this is called in the code, so commenting out due to type Commodity
// This is called in DP_UIInventory_ListItem. Not sure what it's checking against though
simulated function bool MeetsItemReqs(int ItemIndex)
{
	if( ItemIndex > -1 && ItemIndex < arrIntelItems.Length )
	{
//		return XComHQ.MeetsCommodityRequirements(arrItems[ItemIndex]);
		return true;
	}
	else
	{
		return false;
	}
}

simulated function bool IsItemPurchased(int ItemIndex)
{
	// Implement in subclasses
	return false;
}
//simulated function bool ShouldShowCostPanel()
//{
//	return !IsInfoOnly() && GetItemCostString(iSelectedItem) != "";
//}
//
//simulated function bool ShouldShowReqPanel()
//{
//	return !IsInfoOnly() && GetItemReqString(iSelectedItem) != "";
//}
//
//simulated function bool ShouldShowDurationPanel()
//{
//	return !IsInfoOnly() && arrItems[iSelectedItem].OrderHours > 0;
//}

//simulated function EUIState GetDurationColor(int ItemIndex)
//{
//	return eUIState_Good;
//}

//simulated function bool HasButton()
//{
//	return m_bShowButton;
//}

simulated function String GetButtonString(int ItemIndex)
{
	return m_strBuy;
}

//simulated function EUIState GetMainColor()
//{
//	return m_eMainColor;
//}

//simulated function bool IsInfoOnly()
//{
//	return m_bInfoOnly;
//}

defaultproperties
{
	m_bShowButton = true
	m_bInfoOnly = false
	m_eMainColor = eUIState_Normal
	m_eStyle = eUIConfirmButtonStyle_Default //word button
	ConfirmButtonX = 2
}	ConfirmButtonY = 0