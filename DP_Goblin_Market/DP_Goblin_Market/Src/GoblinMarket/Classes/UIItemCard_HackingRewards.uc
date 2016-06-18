// This is an Unreal Script
                           
class UIItemCard_HackingRewards extends UIItemCard;


simulated function PopulateHackingItemCard(optional X2HackRewardTemplate ItemTemplate, optional StateObjectReference ItemRef)
{
	local string strDesc, strRequirement, strTitle;

	if( ItemTemplate == None )
	{
		Hide();
		return;
	}

	bWaitingForImageUpdate = false;

	strTitle = class'UIUtilities_Text'.static.GetColoredText(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(ItemTemplate.GetFriendlyName()), eUIState_Header, 24);
	strDesc = class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetDescription(none), eUIState_Normal, 24);//Description and requirements strings are reversed for item cards, desc appears at the very bottom of the card so not needed here
	strRequirement = class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetDescription(none), eUIState_Normal, 24);//Description and requirements strings are reversed for item cards, desc appears at the very bottom of the card so not needed here
	if(	ItemTemplate==none)
	{
		strTitle="Welcom to the Goblin Market";
		strDesc="Welcom to the Goblin Market";
		strRequirement="Welcom to the Goblin Market";
	}
	PopulateData(strTitle,"", strDesc, "");

	SetHackingItemImages(ItemTemplate, ItemRef);
	SetHackingItemCost(ItemTemplate, ItemRef);
}

simulated function SetHackingItemImages(optional X2HackRewardTemplate ItemTemplate, optional StateObjectReference ItemRef)
{
	MC.BeginFunctionOp("SetImageStack");
	MC.QueueString(ItemTemplate.RewardImagePath);
	MC.EndOp();
}
simulated function SetHackingItemCost(optional X2HackRewardTemplate ItemTemplate, optional StateObjectReference ItemRef)
{
	local string StrCost;
	StrCost= ItemTemplate.MinIntelCost @"-" @ItemTemplate.MaxIntelCost;
	MC.BeginFunctionOp("PopulateCostData");
	MC.QueueString(m_strCostLabel);
	MC.QueueString(StrCost);
	MC.QueueString("");
	MC.QueueString("");
	MC.EndOp();
}