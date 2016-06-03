class DP_DefaultMissionSources_TemplateExchanger extends X2AmbientNarrativeCriteria;



var XComGameState_CampaignSettings Settings;

static function array<X2DataTemplate> CreateTemplates(){
	local array<X2DataTemplate> EmptyArray;
	local DP_DefaultMissionSources_TemplateExchanger Exchanger;
	
	`log("Make Goblin Market start modifiying Mission Source Templates");
	Exchanger = new class'DP_DefaultMissionSources_TemplateExchanger';
	Exchanger.Settings = GameStateMagic();
	Exchanger.ModifyTemplates();

	`XCOMHISTORY.ResetHistory(); // yeah, lets do that, nothing happend anyway...

	`log("Goblin Market modifications finished");

	//We don't create any new templates, only modify existing mission templates
	//AddItem(none) prevents array non initialized warning, although the access of none shows up in the debug log
	EmptyArray.AddItem(none);
	return EmptyArray;
}

//Code from: http://forums.nexusmods.com/index.php?/topic/3839560-template-modification-without-screenlisteners/
//Used to set a difficulty level during start up, because the templates we want to modify have difficulty variants
//These variants can only be accessed when the gamestate is in the corresponding difficulty
static function XComGameState_CampaignSettings GameStateMagic(){
	local XComGameStateHistory History;
	local XComGameStateContext_StrategyGameRule StrategyStartContext;
	local XComGameState StartState;
	local XComGameState_CampaignSettings GameSettings;

	History = `XCOMHISTORY;

	StrategyStartContext = XComGameStateContext_StrategyGameRule(class'XComGameStateContext_StrategyGameRule'.static.CreateXComGameStateContext());
	StrategyStartContext.GameRuleType = eStrategyGameRule_StrategyGameStart;
	StartState = History.CreateNewGameState(false, StrategyStartContext);
	History.AddGameStateToHistory(StartState);

	GameSettings = new class'XComGameState_CampaignSettings'; // Do not use CreateStateObject() here
	StartState.AddStateObject(GameSettings);

	return GameSettings;
}

function ModifyTemplates(){
	
	HandleTemplate('MissionSource_GuerillaOp');
	HandleTemplate('MissionSource_Retaliation');
	HandleTemplate('MissionSource_SupplyRaid');
	HandleTemplate('MissionSource_Council');
	HandleTemplate('MissionSource_LandedUFO');
	HandleTemplate('MissionSource_AlienNetwork');
	HandleTemplate('MissionSource_BlackSite');
	HandleTemplate('MissionSource_Forge');
	HandleTemplate('MissionSource_PsiGate');
}

function HandleTemplate(name templateName){
	local X2MissionSourceTemplate Template;

	Template = X2MissionSourceTemplate(GetManager().FindStrategyElementTemplate(templateName));

	if (Template == none)
	{
		`log("Could not find template:"@string(templateName));
		return;
	}

	if (Template.bShouldCreateDifficultyVariants){
		HandleDifficultyVariants(Template, templateName);
	} else {
		`log("Modify single template:"@string(templateName));
		HandleSingleTemplate(Template, templateName);
	}
}

function HandleDifficultyVariants(X2MissionSourceTemplate Base, name templateName) {
	local X2MissionSourceTemplate Template;
	local int difficulty;
	local string diffString;

	HandleSingleTemplate(Base, templateName);
	`log("Modified base template:"@string(templateName));

	for(difficulty = `MIN_DIFFICULTY_INDEX; difficulty <= `MAX_DIFFICULTY_INDEX; ++difficulty)
	{
		Settings.SetDifficulty(difficulty);
		diffString = string(class'XComGameState_CampaignSettings'.static.GetDifficultyFromSettings());

		Template = X2MissionSourceTemplate(GetManager().FindStrategyElementTemplate(templateName));

		if(Template == none) {
			`log("Could not find difficulty variant:" @string(templateName) @"with difficulty:" @diffString);
			return;
		}

		`log("Modify difficulty variant:" @string(templateName) @"with difficulty:" @diffString);
		HandleSingleTemplate(Template, templateName);
		
	}
}

function HandleSingleTemplate(X2MissionSourceTemplate Template, name templateName) {
	Template = ReplaceFunctions(Template, templateName);
	GetManager().AddStrategyElementTemplate(Template, true);
}

 function X2MissionSourceTemplate ReplaceFunctions(X2MissionSourceTemplate Template, name templateName)
 {

		//local XComGameState_HeadquartersXcom XComHQ;
		//XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		Template.bIntelHackRewards = true;

		if (templateName == 'MissionSource_GuerillaOp')
		{
		Template.bIntelHackRewards = true;
		}

		if (templateName == 'MissionSource_Retaliation')
		{
		Template.bIntelHackRewards = true;
		Template.OnSuccessFn = RetaliationOnSuccess;
		}
		
		if (templateName == 'MissionSource_SupplyRaid')
		{
		Template.bIntelHackRewards = true;
		Template.OnSuccessFn = SupplyRaidOnSuccess;
		}

		if (templateName == 'MissionSource_Council')
		{
		Template.bIntelHackRewards = true;
		Template.OnSuccessFn = CouncilOnSuccess;
		}

		if (templateName == 'MissionSource_LandedUFO')
		{
		Template.bIntelHackRewards = true;
		Template.OnSuccessFn = LandedUFOOnSuccess;
		}

		if (templateName == 'MissionSource_AlienNetwork')
		{
		Template.bIntelHackRewards = true;
		Template.OnSuccessFn = AlienNetworkOnSuccess;
		}
			return Template;

}

function SupplyRaidOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	GiveRewards(NewGameState, MissionState);
	SpawnPointOfInterest(NewGameState, MissionState);
	RemoveIntelRewards(NewGameState, MissionState);
	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_SupplyRaidsCompleted');
}


function RetaliationOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	GiveRewards(NewGameState, MissionState);
	ModifyContinentSupplyYield(NewGameState, MissionState, class'XComGameState_WorldRegion'.static.GetRetaliationSuccessSupplyChangePercent());
	SpawnPointOfInterest(NewGameState, MissionState);
	RemoveIntelRewards(NewGameState, MissionState);
	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_RetaliationsStopped');
}

function CouncilOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local array<int> ExcludeIndices;

	ExcludeIndices = GetCouncilExcludeRewards(MissionState);
	MissionState.bUsePartialSuccessText = (ExcludeIndices.Length > 0);
	GiveRewards(NewGameState, MissionState, ExcludeIndices);
	RemoveIntelRewards(NewGameState, MissionState);
	SpawnPointOfInterest(NewGameState, MissionState);
	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_CouncilMissionsCompleted');
}

function LandedUFOOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	GiveRewards(NewGameState, MissionState);
	SpawnPointOfInterest(NewGameState, MissionState);
	RemoveIntelRewards(NewGameState, MissionState);
	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_LandedUFOsCompleted');
}


function AlienNetworkOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_WorldRegion RegionState;
	local StateObjectReference EmptyRef;
	local PendingDoom DoomPending;
	local int DoomToRemove;
	local XGParamTag ParamTag;
	local string FacilityDestroyed;

	FacilityDestroyed = class'X2StrategyElement_DefaultMissionSources'.default.m_strFacilityDestroyed;
	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	ResHQ.AttemptSpawnRandomPOI(NewGameState);

	AlienHQ = GetAndAddAlienHQ(NewGameState);
	
	AlienHQ.DelayDoomTimers(AlienHQ.GetFacilityDestructionDoomDelay());
	AlienHQ.DelayFacilityTimer(AlienHQ.GetFacilityDestructionDoomDelay());

	RegionState = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(MissionState.Region.ObjectID));

	if (RegionState == none)
	{
		RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', MissionState.Region.ObjectID));
		NewGameState.AddStateObject(RegionState);
	}

	GiveRewards(NewGameState, MissionState);
	RegionState.AlienFacility = EmptyRef;
	RemoveIntelRewards(NewGameState, MissionState);
		  
	if(MissionState.Doom > 0)
	{
		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		DoomToRemove = MissionState.Doom;
		DoomPending.Doom = -DoomToRemove;
		ParamTag.StrValue0 = MissionState.GetWorldRegion().GetDisplayName();
		DoomPending.DoomMessage = `XEXPAND.ExpandString(FacilityDestroyed);
		AlienHQ.PendingDoomData.AddItem(DoomPending);

		ParamTag.StrValue0 = string(DoomToRemove);

		if(DoomToRemove == 1)
		{
			class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strAvatarProgressReducedSingular), false);
		}
		else
		{
			class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strAvatarProgressReducedPlural), false);
		}
	}

	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, class'UIRewardsRecap'.default.m_strAvatarProjectDelayed, false);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_AlienFacilitiesDestroyed');
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_AvatarProgressReduced', DoomToRemove);
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersAlien GetAndAddAlienHQ(XComGameState NewGameState)
{
	local XComGameState_HeadquartersAlien AlienHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersAlien', AlienHQ)
	{
		break;
	}

	if(AlienHQ == none)
	{
		AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
		NewGameState.AddStateObject(AlienHQ);
	}

	return AlienHQ;
}
//----------------------------------------------
function array<int> GetCouncilExcludeRewards(XComGameState_MissionSite MissionState)
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local array<int> ExcludeIndices;
	local int idx;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	`assert(BattleData.m_iMissionID == MissionState.ObjectID);

	for(idx = 0; idx < BattleData.MapData.ActiveMission.MissionObjectives.Length; idx++)
	{
		if(BattleData.MapData.ActiveMission.MissionObjectives[idx].ObjectiveName == 'Capture' &&
		   !BattleData.MapData.ActiveMission.MissionObjectives[idx].bCompleted)
		{
			ExcludeIndices.AddItem(1);
		}
	}

	return ExcludeIndices;
}
//------------------------------------------------------------------
function RemoveIntelRewards(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local MissionIntelOption IntelOption;
	local XComGameState_MissionSite AllMissionStates;
	local XComGameState_Intel IntelState;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', AllMissionStates)
	{
		foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
		{
			break;
		}

		if (XComHQ == none)
		{
			XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			NewGameState.AddStateObject(XComHQ);
		}

		foreach AllMissionStates.PurchasedIntelOptions(IntelOption)
		{
			XComHQ.TacticalGameplayTags.RemoveItem(IntelOption.IntelRewardName);
		}
	}
	IntelState = XComGameState_Intel(History.GetSingleGameStateObjectForClass(class'XComGameState_Intel'));
	IntelState = XComGameState_Intel(NewGameState.CreateStateObject(class'XComGameState_Intel'));

	IntelState.DidSpendIntel = false;
	IntelState.SpentIntel = 0;
	NewGameState.AddStateObject(IntelState);

}
//--------------------------------------------------------------------------
function SpawnPointOfInterest(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameStateHistory History;
	local XComGameState_PointOfInterest POIState;
	local XComGameState_BlackMarket BlackMarketState;

	History = `XCOMHISTORY;
	BlackMarketState = XComGameState_BlackMarket(History.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));

	if (!BlackMarketState.ShowBlackMarket(NewGameState) && MissionState.POIToSpawn.ObjectID != 0)
	{
		POIState = XComGameState_PointOfInterest(History.GetGameStateForObjectID(MissionState.POIToSpawn.ObjectID));
		
		if (POIState != none)
		{
			POIState = XComGameState_PointOfInterest(NewGameState.CreateStateObject(class'XComGameState_PointOfInterest', POIState.ObjectID));
			NewGameState.AddStateObject(POIState);
			POIState.Spawn(NewGameState);
		}
	}
}

//---------------------------------------------

function ModifyContinentSupplyYield(XComGameState NewGameState, XComGameState_MissionSite MissionState, float DeltaYieldPercent, optional int DeltaFromLevelChange = 0, optional bool bRecord = true)
{
	local XComGameStateHistory History;
	local XComGameState_Continent ContinentState;
	local XComGameState_WorldRegion RegionState;
	local XGParamTag ParamTag;
	local int idx, TotalDelta, OldIncome, NewIncome;

	if(DeltaYieldPercent != 1.0)
	{
		// All Regions in continent get permanent supply bonus
		RegionState = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(MissionState.Region.ObjectID));
		TotalDelta = DeltaFromLevelChange;

		if(RegionState == none)
		{
			RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', MissionState.Region.ObjectID));
			NewGameState.AddStateObject(RegionState);
		}

		History = `XCOMHISTORY;
		ContinentState = XComGameState_Continent(History.GetGameStateForObjectID(RegionState.Continent.ObjectID));

		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		
		
		for(idx = 0; idx < ContinentState.Regions.Length; idx++)
		{
			RegionState = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(ContinentState.Regions[idx].ObjectID));

			if(RegionState == none)
			{
				RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', ContinentState.Regions[idx].ObjectID));
				NewGameState.AddStateObject(RegionState);
			}

			OldIncome = RegionState.GetSupplyDropReward();
			RegionState.BaseSupplyDrop *= DeltaYieldPercent;

			if(RegionState.HaveMadeContact())
			{
				NewIncome = RegionState.GetSupplyDropReward();
				TotalDelta += (NewIncome - OldIncome);
			}
		}

		if(bRecord)
		{
			if(DeltaYieldPercent < 1.0)
			{
				ParamTag.StrValue0 = ContinentState.GetMyTemplate().DisplayName;
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strDecreasedContinentalSupplyOutput), true);
				ParamTag.StrValue0 = string(-TotalDelta);
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strDecreasedSupplyIncome), true);
			}
			else
			{
				ParamTag.StrValue0 = ContinentState.GetMyTemplate().DisplayName;
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strIncreasedContinentalSupplyOutput), false);
				ParamTag.StrValue0 = string(TotalDelta);
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strIncreasedSupplyIncome), false);
			}
		}
	}
}

//--------------------------------------------
function GiveRewards(XComGameState NewGameState, XComGameState_MissionSite MissionState, optional array<int> ExcludeIndices)
{
	local XComGameStateHistory History;
	local XComGameState_Reward RewardState;
	local int idx;

	History = `XCOMHISTORY;

	// First Check if we need to exclude some rewards
	for(idx = 0; idx < MissionState.Rewards.Length; idx++)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(MissionState.Rewards[idx].ObjectID));
		if(RewardState != none)
		{
			if(ExcludeIndices.Find(idx) != INDEX_NONE)
			{
				RewardState.CleanUpReward(NewGameState);
				NewGameState.RemoveStateObject(RewardState.ObjectID);
				MissionState.Rewards.Remove(idx, 1);
				idx--;
			}
		}
	}

	class'XComGameState_HeadquartersResistance'.static.SetRecapRewardString(NewGameState, MissionState.GetRewardAmountString());

	// @mnauta: set VIP rewards string is deprecated, leaving blank
	class'XComGameState_HeadquartersResistance'.static.SetVIPRewardString(NewGameState, "" /*REWARDS!*/);

	for(idx = 0; idx < MissionState.Rewards.Length; idx++)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(MissionState.Rewards[idx].ObjectID));

		// Give rewards
		if(RewardState != none)
		{
			RewardState.GiveReward(NewGameState);
		}

		// Remove the reward state objects
		NewGameState.RemoveStateObject(RewardState.ObjectID);
	}

	MissionState.Rewards.Length = 0;
}

static function X2StrategyElementTemplateManager GetManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}