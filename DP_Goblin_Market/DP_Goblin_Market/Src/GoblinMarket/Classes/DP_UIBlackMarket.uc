
class DP_UIBlackMarket extends UIScreen;

//TODO: Uncomment out to randomize text welcome messages.
//const NUM_WELCOMES = 7;

//var public localized String m_strTitle;
var public localized String m_strBuy;
var public localized String m_strSell;
var public localized String m_strImage;
//var public localized String m_strWelcome[NUM_WELCOMES];
//var public localized String m_strInterests[3];

var UIPanel LibraryPanel;
var UIButton Button1, Button2, Button3;
var UIImage ImageTarget;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState NewGameState;

	super.InitScreen(InitController, InitMovie, InitName);
	BuildScreen();
	self.SetAlpha(1);
	//class'DP_DefaultMissionSources_TemplateExchanger'.static.CreateTemplates();
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: On Black Market Open");
	`XEVENTMGR.TriggerEvent('OnBlackMarketOpen', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

simulated function BuildScreen()
{
	local UIPanel ButtonGroup;

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Black_Market_Enter");

	LibraryPanel = Spawn(class'UIPanel', self);
	LibraryPanel.bAnimateOnInit = false;
	LibraryPanel.InitPanel('', 'BlackMarketMenu');
		
	ButtonGroup = Spawn(class'UIPanel', LibraryPanel);
	ButtonGroup.InitPanel('ButtonGroup', '');

	Button1 = Spawn(class'UIButton', ButtonGroup);
	Button1.SetResizeToText(false);
//	Button1.InitButton('Button0', m_strBuy);
	Button1.InitButton('Button0', "BUY");
//		Button1.SetDisabled(false, "");

	Button2 = Spawn(class'UIButton', ButtonGroup);
	Button2.SetResizeToText(false);
//	Button2.InitButton('Button1', m_strSell);
	Button2.InitButton('Button1', "LEAVE");
//		Button2.SetDisabled(false);
	
	Button3 = Spawn(class'UIButton', ButtonGroup);
	Button3.SetResizeToText(false);
	Button3.InitButton('Button2', "");

	// TODO: Replace with custom ImageTarget
	ImageTarget = Spawn(class'UIImage', LibraryPanel).InitImage('MarketMenuImage');
	ImageTarget.LoadImage(m_strImage);

	//-----------------------------------------------

//	LibraryPanel.MC.FunctionString("SetMenuQuote", m_strWelcome[Rand(NUM_WELCOMES)]);
	LibraryPanel.MC.FunctionString("SetMenuQuote", "The Goblins Welcome You To Their Market!");

	LibraryPanel.MC.BeginFunctionOp("SetMenuInterest");
//	LibraryPanel.MC.QueueString(m_strInterestTitle);
	LibraryPanel.MC.QueueString("Testing with Shorter Text");
//	LibraryPanel.MC.QueueString(GetInterestsString());
	LibraryPanel.MC.QueueString("Using Shorter Text");
	LibraryPanel.MC.EndOp();

	Button1.OnClickedDelegate = OnBuyClicked;
	// Using this for our "Leave" button
	Button2.OnClickedDelegate = OnSellClicked;
	Button3.Hide();

	LibraryPanel.MC.BeginFunctionOp("SetGreeble");
//	LibraryPanel.MC.QueueString(class'UIAlert'.default.m_strBlackMarketFooterLeft);
	LibraryPanel.MC.QueueString("Put Something Cool Here");
	LibraryPanel.MC.QueueString(class'UIAlert'.default.m_strBlackMarketFooterRight);
//	LibraryPanel.MC.QueueString(class'UIAlert'.default.m_strBlackMarketLogoString);
    LibraryPanel.MC.QueueString("GOBY MART!");
	LibraryPanel.MC.EndOp();

	LibraryPanel.MC.FunctionVoid("AnimateIn");

	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.ClearButtonHelp();
	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.AddBackButton(CloseScreen);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	
	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.ClearButtonHelp();
	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.AddBackButton(CloseScreen);
}


//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnBuyClicked(UIButton button)
{
//	`HQPRES.UIBlackMarketBuy();
	DP_UIBlackMarketBuy();

}
// If you change this title, then you'll need to create a new button delegate
simulated function OnSellClicked(UIButton button)
{
	local DP_UIMission_Council MyScreen;
    CloseScreen();
	MyScreen=DP_UIMission_Council(`ScreenStack.GetFirstInstanceOf(class'UIMission'));
	if(MyScreen!=none)
	{
		MyScreen.ExposeOLC(button);
	}
	self.Removed();
}

// Override for custom cleanup logic// TODO: Move custom logic to UIMission for use in all 7 mission types...simulated function OnRemoved()
{
	super.OnRemoved();
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function DP_UIBlackMarketBuy(){	local DP_UIBlackMarket_Buy kScreen;	kScreen = Spawn(class'DP_UIBlackMarket_Buy', self);	`ScreenStack.Push(kScreen);	`log("-------------DOING THE BUY SCREEN-----------------",true,'Team Dragonpunk Goblin Market');}

simulated function CloseScreen()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Black_Market_Ambience_Loop_Stop");
	super.CloseScreen();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		CloseScreen();
		break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_START:
		`HQPRES.UIPauseMenu(, true);
		break;
	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}


//==============================================================================

defaultproperties
{
	InputState = eInputState_Consume;
	Package = "/ package/gfxBlackMarket/BlackMarket";
	bConsumeMouseEvents = true;
}