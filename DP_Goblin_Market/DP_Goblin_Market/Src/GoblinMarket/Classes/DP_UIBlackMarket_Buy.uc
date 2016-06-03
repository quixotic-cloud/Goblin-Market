// class UIBlackMarket_Buy extends UISimpleCommodityScreen;
class DP_UIBlackMarket_Buy extends DP_UISimpleCommodityScreen;

var localized String IntelAvailableLabel;
var localized String IntelOptionsLabel;
var localized String IntelCostLabel;
var localized String IntelTotalLabel;

// List may not be needed
var UIList List;
var UIText OptionDescText;
var UIText TotalIntelText;

var array<MissionIntelOption> SelectedOptions;

//----------------------------------------------------------------------------
// MEMBERS

//Creates the Screen/UI. From original BM_Buy class
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	m_strTitle = ""; //Clear the header out intentionally. 	
	super.InitScreen(InitController, InitMovie, InitName);
	SetBlackMarketLayout();

	MC.BeginFunctionOp("SetGreeble");
	MC.QueueString(class'UIAlert'.default.m_strBlackMarketFooterLeft);
	MC.QueueString(class'UIAlert'.default.m_strBlackMarketFooterRight);
//	MC.QueueString(class'UIAlert'.default.m_strBlackMarketLogoString);
	MC.QueueString("GOBLIN MARKET");
	MC.EndOp();
}

//Iterator uses to populate the UI (where is this iterated?)
// We want to get almost all rewards for Goblin Market
// TODO: Perhaps filter out some rewards based on mission type or being too OP
//simulated function SelectIntelItem(UIList ContainerList, int ItemIndex)
//{
//	local MissionIntelOption SelectedOption;
//	local X2HackRewardTemplateManager HackRewardTemplateManager;
//	local X2HackRewardTemplate OptionTemplate;
	
//	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
//	SelectedOption = GetMission().IntelOptions[ItemIndex];
//	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(SelectedOption.IntelRewardName);

//	OptionDescText.SetText(OptionTemplate.GetDescription(none));
//}

//-------------- EVENT HANDLING --------------------------------------------------------

//Manges the original BM_Buy logic for repopulating list
simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	if (itemIndex != iSelectedItem)
	{
		iSelectedItem = itemIndex;
	}
	// This line expects type commodity. Replace with intel logic
	if( CanAffordItem(iSelectedItem) )
	{
		PlaySFX("StrategyUI_Purchase_Item");
		// Use all lines of code here except for this one..
//		GetMarket().BuyBlackMarketItem(arrItems[iSelectedItem].RewardRef);
		GetItems();
		// Spawns inventory item for parent class. Replace with intel population for list
		PopulateData();

	}
	else
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
	}
	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------

//Repurpose this to get Hacker reward template and state
//simulated function XComGameState_BlackMarket GetMarket()
//{
//	return class'UIUtilities_Strategy'.static.GetBlackMarket();
//}

// Override from parent class. Called during list population.
// All our buttons should say "buy" or "buy for mission"
simulated function String GetButtonString(int ItemIndex)
{

//		return m_strBuy;
		return "BUY";
}

// Not sure if this gets the bought intel options, or ones available to purchase for the mission
simulated function array<MissionIntelOption> GetMissionIntelOptions()
{
//	return GetMission().IntelOptions;
	return XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(UIMission(Screen).MissionRef.ObjectID)).IntelOptions;
}

//Sends the bought items to game to make changes. Will be replaced by IntelOptions mission code
simulated function GetItems()
{
//	local XComGameState NewGameState;
//	local XComGameState_BlackMarket BlackMarketState;

//	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Tech Rushes");
//	BlackMarketState = XComGameState_BlackMarket(NewGameState.CreateStateObject(class'XComGameState_BlackMarket', GetMarket().ObjectID));
//	NewGameState.AddStateObject(BlackMarketState);
//	BlackMarketState.UpdateTechRushItems(NewGameState);
//	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

//	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Repopulates Items from available list. Need to rewrite logic for Intel...
	// Checkbox system doesn't remove already bought intel items...
	// TODO: This is where we need to populate the list with unpurchased hacker rewards
//	arrItems = GetMarket().GetForSaleList();
	arrIntelItems = GetMissionIntelOptions();
}

// Buys the selected rewards. Will need to change to purchase rewards one at a time. Make Global?
simulated function BuyIntelOptions()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local MissionIntelOption IntelOption;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Buy Mission Intel Options");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	// Delete this and mirror the single use logic in BM_Buy + repopulation
	foreach SelectedOptions(IntelOption)
	{
		XComHQ.TacticalGameplayTags.AddItem(IntelOption.IntelRewardName);
		XComHQ.PayStrategyCost(NewGameState, IntelOption.Cost, XComHQ.MissionOptionScalars);
	}

	// Save the purchased options
	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(UIMission(Screen).MissionRef.ObjectID));
//	MissionState = GetMission();
//	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(UIMission(Screen).MissionRef.ObjectID));
	NewGameState.AddStateObject(MissionState);
	MissionState.PurchasedIntelOptions = SelectedOptions;

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		// Understand this better. Might be worth calling even if no intel is bought.
		History.CleanupPendingGameState(NewGameState);
	}
}

defaultproperties
{
	bConsumeMouseEvents = true;
}
