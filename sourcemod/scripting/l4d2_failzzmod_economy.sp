#include <sourcemod>
//#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <left4dhooks>

public Plugin:myinfo = 
{
	name = "FailzzMod Economy",
	author = "Derpduck",
	description = "Prototype for FailzzMod economy system",
	version = "0.1",
	url = "https://github.com/Derpduck/Derpduck-L4D2-Scripts"
}

#define AUTH_ADT_LENGTH (ByteCountToCells(64))
ArrayList g_steamIDs
ArrayList g_playerMoney

enum PlayerTeam
{
    PlayerTeam_None = 0,
    PlayerTeam_Spectator,
    PlayerTeam_Survivor,
    PlayerTeam_Infected
}

//Menu Constants
#define CHOICE_SHOTGUNS "#choice_shotguns"
#define CHOICE_AUTOMATIC "#choice_automatic"
#define CHOICE_SNIPERS "#choice_snipers"
#define CHOICE_HEAVY "#choice_heavy"
#define CHOICE_SECONDARY "#choice_secondary"
#define CHOICE_THROWABLE "#choice_throwable"
#define CHOICE_HEALING "#choice_healing"
/*
#define CHOICE_UPGRADES "#choice_upgrades"
*/

#define BUY_SHOTGUN_PUMP "#buy_shotgun_pump"
#define BUY_SHOTGUN_CHROME "#buy_shotgun_chrome"
#define BUY_SHOTGUN_AUTO "#buy_shotgun_auto"
#define BUY_SHOTGUN_SPAS "#buy_shotgun_spas"
#define BUY_UZI "#buy_uzi"
#define BUY_UZI_SILENCED "#buy_uzi_silenced"
#define BUY_UZI_MP5 "#buy_uzi_mp5"
#define BUY_RIFLE_M16 "#buy_rifle_m16"
#define BUY_RIFLE_AK47 "#buy_rifle_ak47"
#define BUY_RIFLE_DESERT "#buy_rifle_desert"
#define BUY_RIFLE_SG552 "#buy_rifle_sg552"
#define BUY_SNIPER_HUNTING "#buy_sniper_hunting"
#define BUY_SNIPER_MILITARY "#buy_sniper_military"
#define BUY_SNIPER_SCOUT "#buy_sniper_scout"
#define BUY_SNIPER_AWP "#buy_sniper_awp"
#define BUY_M60 "#buy_m60"
#define BUY_GRENADELAUNCHER "#buy_grenadelauncher"
#define BUY_CHAINSAW "#buy_chainsaw"
#define BUY_PISTOL "#buy_pistol"
#define BUY_PISTOL_MAGNUM "#buy_pistol_magnum"
#define BUY_MOLOTOV "#buy_molotov"
#define BUY_PIPEBOMB "#buy_pipebomb"
#define BUY_BILEBOMB "#buy_bilebomb"
#define BUY_PAINPILLS "#buy_painpills"
#define BUY_ADRENALINE "#buy_adrenaline"
#define BUY_MEDKIT "#buy_medkit"
#define BUY_DEFIB "#buy_defib"

#define CHOICE_MELEE_BLUNT "#buy_melee_blunt"
#define CHOICE_MELEE_SHARP "#buy_melee_sharp"

#define BUY_BASEBALLBAT "#buy_baseballbat"
#define BUY_CRICKETBAT "#buy_cricketbat"
#define BUY_GUITAR "#buy_guitar"
#define BUY_FRYINGPAN "#buy_fryingpan"
#define BUY_GOLFCLUB "#buy_golfclub"
#define BUY_SHOVEL "#buy_shovel"
#define BUY_TONFA "#buy_tonfa"
#define BUY_CROWBAR "#buy_crowbar"
#define BUY_FIRAXE "#buy_firaxe"
#define BUY_KATANA "#buy_katana"
#define BUY_KNIFE "#buy_knife"
#define BUY_MACHETE "#buy_machete"
#define BUY_PITCHFORK "#buy_pitchfork"

bool canBuy = false

ConVar startingMoney, maximumMoney;

/*
//AWARD CONDITIONS
ConVar conAllowPerRoundAwards, conPersonalSurvivorIncap, conPersonalSurvivorKilled, conPersonalAbility, conPersonalHealth, conPersonalDistance, conPersonalPenaltyIncap, conPersonalPenaltyDeath;

//AWARD AMOUNTS
ConVar awardRoundEnd, awardMapEnd, awardWonMap, awardLostMap, awardConsecutiveLoss, awardExtraConsecutiveLoss, awardKilledTank, awardKilledWitch, awardWipedSurvivors, awardSurvivorIncapped, awardSurvivorKilled, awardAbilityLanded, awardCapDuration, awardHealthGreen, awardHealthYellow, awardHealthRed, awardHealthTempOnly, awardDistanceBonus;

//PENALTY AMOUNTS
ConVar penaltyIncapped, penaltyDeath;
*/

//ITEM PRICES
ConVar priceShotgunPump, priceShotgunChrome, priceUzi, priceUziSilenced, priceUziMP5, priceRifleM16, priceRifleAK47, priceRifleDesert, priceRifleSG552, priceShotgunAuto, priceShotgunSpas, priceSniperHunting, priceSniperMilitary, priceSniperScout, priceSniperAWP;
ConVar priceM60, priceGrenadeLauncher, priceChainsaw;
ConVar pricePistol, priceMagnum, priceMeleeBlunt, priceMeleeSharp;
ConVar priceMolotov, pricePipebomb, priceBilebomb;
ConVar pricePainPills, priceAdrenaline, priceMedkit, priceDefibrillator;
/*
ConVar priceLaser, priceFireAmmo, priceExplosiveAmmo;
ConVar priceGnome, priceCola;
*/

public OnPluginStart()
{
	HookEvent("round_start", EventHook:RoundStartEvent, EventHookMode_PostNoCopy)
	
	LoadTranslations("economy_menu.phrases")
	RegConsoleCmd("buy", Buy_Menu)
	
	//CreateConVar(const char[] name, const char[] defaultValue, const char[] description, int flags, bool hasMin, float min, bool hasMax, float max)
	
	startingMoney				= CreateConVar("starting_money",				"1000",		"Amount of money players start out with")
	maximumMoney				= CreateConVar("maximum_money",					"16000",	"Maximum amount of money players are allowed to have")
	
	//AWARD CONDITIONS
	/*
	conAllowPerRoundAwards		= CreateConVar("condition_allow_per_round_awards",	"0",	"Can applicable awards be given at the end of a round (0 = Only on map end, 1 = Each round, where applicable)")
	conPersonalSurvivorIncap	= CreateConVar("condition_personal_survivor_incap",	"0",	"Is survivor incapped bonus money awarded to the entire team or individually (0 = Entire Team, 1 = Individually)")
	conPersonalSurvivorKilled	= CreateConVar("condition_personal_survivor_kill",	"0",	"Is survivor kill bonus money awarded to the entire team or individually (0 = Entire Team, 1 = Individually)")
	conPersonalAbility			= CreateConVar("condition_personal_ability",		"0",	"Is ability landing bonus money awarded to the entire team or individually (0 = Entire Team, 1 = Individually)")
	conPersonalHealth			= CreateConVar("condition_personal_health",			"0",	"Is health bonus money awarded to the entire team or individually (0 = Entire Team, 1 = Individually)")
	conPersonalDistance			= CreateConVar("condition_personal_distance",		"0",	"Is distance bonus money awarded to the entire team or individually (0 = Entire Team, 1 = Individually)")
	conPersonalPenaltyIncap		= CreateConVar("condition_personal_penalty_incap",	"1",	"Is incap penalty money taken from the entire team or individually (0 = Entire Team, 1 = Individually)")
	conPersonalPenaltyDeath		= CreateConVar("condition_personal_penalty_death",	"1",	"Is death penalty money taken from the entire team or individually (0 = Entire Team, 1 = Individually)")
	
	//AWARD AMOUNTS
	awardRoundEnd				= CreateConVar("award_round_end",				"0",	"Money awarded on (half) round end (0 = No Award)")
	awardMapEnd					= CreateConVar("award_map_end",					"500",	"Money awarded on (full) map end (0 = No Award)")
	awardWonMap					= CreateConVar("award_won_map",					"500",	"Money awarded for winning a map (0 = No Award)")
	awardLostMap				= CreateConVar("award_lost_map",				"0",	"Money awarded for losing a map (0 = No Award)")
	awardConsecutiveLoss		= CreateConVar("award_consecutive_loss",		"350",	"Money awarded for losing 2 maps consecutively (0 = No Award)")
	awardExtraConsecutiveLoss	= CreateConVar("award_extra_consecutive_loss",	"700",	"Money awarded for losing more than 2 maps consecutively (0 = No Award)")
	awardKilledTank				= CreateConVar("award_killed_tank",				"250",	"Money awarded for killing a tank (0 = No Award)")
	awardKilledWitch			= CreateConVar("award_killed_witch",			"25",	"Money awarded for killing a witch (without her running away/incapping a survivor) (0 = No Award)")
	awardWipedSurvivors			= CreateConVar("award_wiped_survivors",			"300",	"Money awarded for killing all the survivors (0 = No Award)")
	awardSurvivorIncapped		= CreateConVar("award_survivor_incapped",		"10",	"Money awarded each time a survivor is incapped (0 = No Award)")
	awardSurvivorKilled			= CreateConVar("award_survivor_incapped",		"50",	"Money awarded each time a survivor is killed (0 = No Award)")
	awardAbilityLanded			= CreateConVar("award_ability_landed",			"15",	"Money awarded each time an infected ability lands (0 = No Award)")
	awardCapDuration			= CreateConVar("award_cap_duration",			"5",	"Money awarded for every 3 seconds a survivor is pinned (0 = No Award)")
	awardHealthGreen			= CreateConVar("award_health_green",			"100",	"Money awarded for each survivor that completes the map with green health (0 = No Award)")
	awardHealthYellow			= CreateConVar("award_health_yellow",			"60",	"Money awarded for each survivor that completes the map with yellow health (0 = No Award)")
	awardHealthRed				= CreateConVar("award_health_red",				"30",	"Money awarded for each survivor that completes the map with red health (0 = No Award)")
	awardHealthTempOnly			= CreateConVar("award_health_temp_only",		"20",	"Money awarded for each survivor that completes the map with only temporary health (0 = No Award)")
	awardDistanceBonus			= CreateConVar("award_distance_bonus",			"1",	"Money awarded for distance points gained by survivors (multiplier of distance value) (0 = No Award)")
	
	//PENALTY AMOUNTS
	penaltyIncapped				= CreateConVar("penalty_incapped",				"0",	"Money lost for being incapped (0 = No Penalty)")
	penaltyDeath				= CreateConVar("penalty_death",					"0",	"Money lost for being killed as a survivor (0 = No Penalty)")
	*/
	
	//ITEM PRICES
	//T1s
	priceShotgunPump			= CreateConVar("price_shotgun_pump",			"500",	"Cost of weapon: pumpshotgun")
	priceShotgunChrome			= CreateConVar("price_shotgun_chrome",			"500",	"Cost of weapon: shotgun_chrome")
	priceUzi					= CreateConVar("price_uzi",						"500",	"Cost of weapon: smg")
	priceUziSilenced			= CreateConVar("price_uzi_silenced",			"500",	"Cost of weapon: smg_silenced")
	priceUziMP5					= CreateConVar("price_uzi_mp5",					"500",	"Cost of weapon: smg_mp5")
	//T2s
	priceRifleM16				= CreateConVar("price_rifle_m16",				"1000",	"Cost of weapon: rifle")
	priceRifleAK47				= CreateConVar("price_rifle_ak47",				"1000",	"Cost of weapon: rifle_ak47")
	priceRifleDesert			= CreateConVar("price_rifle_desert",			"1000",	"Cost of weapon: rifle_desert")
	priceRifleSG552				= CreateConVar("price_rifle_sg552",				"1000",	"Cost of weapon: rifle_sg552")
	priceShotgunAuto			= CreateConVar("price_shotgun_auto",			"1000",	"Cost of weapon: autoshotgun")
	priceShotgunSpas			= CreateConVar("price_shotgun_spas",			"1000",	"Cost of weapon: shotgun_spas")
	priceSniperHunting			= CreateConVar("price_sniper_hunting",			"1000",	"Cost of weapon: hunting_rifle")
	priceSniperMilitary			= CreateConVar("price_sniper_military",			"1000",	"Cost of weapon: sniper_military")
	priceSniperScout			= CreateConVar("price_sniper_scout",			"1000",	"Cost of weapon: sniper_scout")
	priceSniperAWP				= CreateConVar("price_sniper_awp",				"1000",	"Cost of weapon: sniper_awp")
	//T3s
	priceM60					= CreateConVar("price_m60",						"1500",	"Cost of weapon: rifle_m60")
	priceGrenadeLauncher		= CreateConVar("price_grenade_launcher",		"1500",	"Cost of weapon: grenade_launcher")
	priceChainsaw				= CreateConVar("price_chainsaw",				"1500",	"Cost of weapon: chainsaw")
	//Secondaries
	pricePistol					= CreateConVar("price_pistol",					"100",	"Cost of weapon: pistol (per pistol)")
	priceMagnum					= CreateConVar("price_pistol_magnum",			"500",	"Cost of weapon: pistol_magnum")
	priceMeleeBlunt				= CreateConVar("price_melee_blunt",				"500",	"Cost of weapon(s): baseball_bat, cricket_bat, electric_guitar, frying_pan, golfclub, shovel, tonfa")
	priceMeleeSharp				= CreateConVar("price_melee_sharp",				"600",	"Cost of weapon(s): crowbar, fireaxe, katana, knife, machete, pitchfork")
	//Throwables
	priceMolotov				= CreateConVar("price_molotov",					"700",	"Cost of weapon: molotov")
	pricePipebomb				= CreateConVar("price_pipe_bomb",				"700",	"Cost of weapon: pipe_bomb")
	priceBilebomb				= CreateConVar("price_bile_bomb",				"800",	"Cost of weapon: vomitjar")
	//Healing Items
	pricePainPills				= CreateConVar("price_pain_pills",				"400",	"Cost of weapon: pain_pills")
	priceAdrenaline				= CreateConVar("price_adrenaline",				"600",	"Cost of weapon: adrenaline")
	priceMedkit					= CreateConVar("price_medkit",					"1200",	"Cost of weapon: first_aid_kit")
	priceDefibrillator			= CreateConVar("price_defibrillator",			"3000",	"Cost of weapon: defibrillator")
	/*
	//Upgrades
	priceLaser					= CreateConVar("price_laser",					"1500",	"Cost of upgrade: laser sights")
	priceFireAmmo				= CreateConVar("price_fire_ammo",				"2000",	"Cost of upgrade: upgradepack_incendiary")
	priceExplosiveAmmo			= CreateConVar("price_explosive_ammo",			"5000",	"Cost of upgrade: upgradepack_explosive")
	//Fun
	priceGnome					= CreateConVar("price_gnome",					"50",	"Cost of item: gnome")
	priceCola					= CreateConVar("price_cola",					"50",	"Cost of item: cola_bottles")
	*/
	
	//Initalize money tracking
	g_steamIDs = new ArrayList(AUTH_ADT_LENGTH)
	g_playerMoney = new ArrayList(AUTH_ADT_LENGTH)
	g_steamIDs.Clear()
	g_playerMoney.Clear()
	
	CreateTimer(10.0, test)
}

static Action:test(Handle timer)
{
	GiveMoney(1, 500)
	
	CreateTimer(10.0, test)
}

/*
	INITIALIZE CLIENTS
*/
public OnClientPutInServer(client)
{
	AddClientToList(client)
}

static AddClientToList(client)
{
	//Valid client
	if (IsValidClient(client))
	{
		char steamID[64]
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))
		
		//Client is in array
		new index = FindStringInArray(g_steamIDs,steamID)
		if (index == -1)
		{
			//Add them to arrays and give starting money
			new startMoney = GetConVarInt(startingMoney)
			PushArrayString(g_steamIDs, steamID)
			PushArrayCell(g_playerMoney, startMoney)
			
			PrintToChatAll("Added client: %s at index: %i with money: %i", steamID, index, startMoney)
		}
	}
}

static RemoveClientFromList(client)
{
	//Valid client
	if (IsValidClient(client))
	{
		char steamID[64]
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))
		
		//Client is in array
		new index = FindStringInArray(g_steamIDs,steamID)
		if (index != -1)
		{
			//Remove them from arrays
			RemoveFromArray(g_steamIDs, index)
			RemoveFromArray(g_playerMoney, index)
			
			PrintToChatAll("Removed client: %s at index: %i", steamID, index)
		}
	}
}

static RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(10.0, RoundStartEvent_Delay)
}

static Action:RoundStartEvent_Delay(Handle timer)
{
	int pointsTeamA = L4D2Direct_GetVSCampaignScore(0)
	int pointsTeamB = L4D2Direct_GetVSCampaignScore(1)
	
	//Check if a new game has started
	if (pointsTeamA == 0 && pointsTeamB == 0)
	{
		//Reset all money
		ResetMoney()
		canBuy = true
	}
}

static ResetMoney()
{
	g_steamIDs.Clear()
	g_playerMoney.Clear()
	
	//Add all valid players currently in-game
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			AddClientToList(i)
		}
	}
}

/*
	BUY MENUS
*/
static BuyMenuDrawMoney(client, param2)
{
	char buffer[255]
	int money = GetMoney(client)
	Format(buffer, sizeof(buffer), "Your Money: $%i", money)
	
	Panel panel = view_as<Panel>(param2)
	panel.DrawText(" ")
	panel.DrawText(buffer)
}

static Action Buy_Menu(int client, int args)
{
	OpenBuyMenu(client)
}

static OpenBuyMenu(int client)
{
	if (canBuy)
	{
		if (GetClientTeam(client) == PlayerTeam_Survivor)
		{
			Menu menu = new Menu(BuyMenuHandler, MenuAction_Display|MenuAction_Select|MenuAction_Cancel|MenuAction_End)
			menu.SetTitle("%s", "FailzzMod Buy Menu", LANG_SERVER)
			
			menu.AddItem(CHOICE_SHOTGUNS, "Shotguns")
			menu.AddItem(CHOICE_AUTOMATIC, "SMGs / Rifles")
			menu.AddItem(CHOICE_SNIPERS, "Sniper Rifles")
			menu.AddItem(CHOICE_HEAVY, "Heavy Weapons")
			menu.AddItem(CHOICE_SECONDARY, "Secondary Weapons")
			menu.AddItem(CHOICE_THROWABLE, "Throwables")
			menu.AddItem(CHOICE_HEALING, "Healing Items")
			//menu.AddItem(CHOICE_UPGRADES, "Upgrades")
			
			menu.ExitButton = true
			menu.Display(client, MENU_TIME_FOREVER)
		}
		else
		{
			PrintToServer("Not on survivor")
			//BuyMenuDrawMoney(client, param2)
			//Make a separate money only menu
		}
	}
}

static int BuyMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			BuyMenuDrawMoney(param1, param2)
		}

		case MenuAction_Select:
		{
			char selection[32];
			menu.GetItem(param2, selection, sizeof(selection))
			
			if (StrEqual(selection, CHOICE_SHOTGUNS))
			{
				OpenMenu_Shotguns(param1)
			}
			else if (StrEqual(selection, CHOICE_AUTOMATIC))
			{
				OpenMenu_Automatic(param1)
			}
			else if (StrEqual(selection, CHOICE_SNIPERS))
			{
				OpenMenu_Snipers(param1)
			}
			else if (StrEqual(selection, CHOICE_HEAVY))
			{
				OpenMenu_Heavy(param1)
			}
			else if (StrEqual(selection, CHOICE_SECONDARY))
			{
				OpenMenu_Secondary(param1)
			}
			else if (StrEqual(selection, CHOICE_THROWABLE))
			{
				OpenMenu_Throwable(param1)
			}
			else if (StrEqual(selection, CHOICE_HEALING))
			{
				OpenMenu_Healing(param1)
			}
			/*
			else if (StrEqual(selection, CHOICE_UPGRADES))
			{
			}
			*/
			
			PrintToServer("Client %d selected %s", param1, selection)
		}

		case MenuAction_Cancel:
		{
			if (canBuy && param2 == -6)
			{
				OpenBuyMenu(param1)
			}
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2)
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}
}

static OpenMenu_Shotguns(int client)
{
	if (canBuy)
	{
		Menu menu = new Menu(BuyMenuHandler_Shotguns, MenuAction_Display|MenuAction_Select|MenuAction_Cancel|MenuAction_End)
		menu.SetTitle("%s", "Buy: Shotguns", LANG_SERVER)
		
		//Generate weapon strings
		new price1 = GetConVarInt(priceShotgunPump);	char option1[255]; Format(option1, sizeof(option1), "Remmington Pump ($%i)", price1)
		new price2 = GetConVarInt(priceShotgunChrome);	char option2[255]; Format(option2, sizeof(option2), "Chrome Pump ($%i)", price2)
		new price3 = GetConVarInt(priceShotgunAuto);	char option3[255]; Format(option3, sizeof(option3), "M4 Tactical Auto ($%i)", price3)
		new price4 = GetConVarInt(priceShotgunSpas);	char option4[255]; Format(option4, sizeof(option4), "SPAS Combat Auto ($%i)", price4)
		
		//Add options to menu
		menu.AddItem(BUY_SHOTGUN_PUMP, option1)
		menu.AddItem(BUY_SHOTGUN_CHROME, option2)
		menu.AddItem(BUY_SHOTGUN_AUTO, option3)
		menu.AddItem(BUY_SHOTGUN_SPAS, option4)
		
		menu.ExitButton = true
		menu.ExitBackButton = true
		menu.Display(client, MENU_TIME_FOREVER)
	}
}

static int BuyMenuHandler_Shotguns(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			BuyMenuDrawMoney(param1, param2)
		}

		case MenuAction_Select:
		{
			char selection[32];
			menu.GetItem(param2, selection, sizeof(selection))
			
			if (StrEqual(selection, BUY_SHOTGUN_PUMP))
			{
				MenuBuyItem(param1, "pumpshotgun")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_SHOTGUN_CHROME))
			{
				MenuBuyItem(param1, "shotgun_chrome")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_SHOTGUN_AUTO))
			{
				MenuBuyItem(param1, "autoshotgun")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_SHOTGUN_SPAS))
			{
				MenuBuyItem(param1, "shotgun_spas")
				OpenBuyMenu(param1)
			}
			
			PrintToServer("Client %d selected %s", param1, selection)
		}

		case MenuAction_Cancel:
		{
			if (canBuy && param2 == -6)
			{
				OpenBuyMenu(param1)
			}
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2)
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}
}

static OpenMenu_Automatic(int client)
{
	if (canBuy)
	{
		Menu menu = new Menu(BuyMenuHandler_Automatic, MenuAction_Display|MenuAction_Select|MenuAction_Cancel|MenuAction_End)
		menu.SetTitle("%s", "Buy: Automatic Weapons", LANG_SERVER)
		
		//Generate weapon strings
		new price1 = GetConVarInt(priceUzi);			char option1[255]; Format(option1, sizeof(option1), "SMG ($%i)", price1)
		new price2 = GetConVarInt(priceUziSilenced);	char option2[255]; Format(option2, sizeof(option2), "Silenced Mac-10 ($%i)", price2)
		new price3 = GetConVarInt(priceUziMP5);			char option3[255]; Format(option3, sizeof(option3), "H&K MP5 ($%i)", price3)
		new price4 = GetConVarInt(priceRifleDesert);	char option4[255]; Format(option4, sizeof(option4), "SCAR Desert Rifle ($%i)", price4)
		new price5 = GetConVarInt(priceRifleM16);		char option5[255]; Format(option5, sizeof(option5), "M16 Assault Rifle ($%i)", price5)
		new price6 = GetConVarInt(priceRifleAK47);		char option6[255]; Format(option6, sizeof(option6), "AK-47 ($%i)", price6)
		new price7 = GetConVarInt(priceRifleSG552);		char option7[255]; Format(option7, sizeof(option7), "SG 552 ($%i)", price7)
		
		//Add options to menu
		menu.AddItem(BUY_UZI, option1)
		menu.AddItem(BUY_UZI_SILENCED, option2)
		menu.AddItem(BUY_UZI_MP5, option3)
		menu.AddItem(BUY_RIFLE_DESERT, option4)
		menu.AddItem(BUY_RIFLE_M16, option5)
		menu.AddItem(BUY_RIFLE_AK47, option6)
		menu.AddItem(BUY_RIFLE_SG552, option7)
		
		menu.ExitButton = true
		menu.ExitBackButton = true
		menu.Display(client, MENU_TIME_FOREVER)
	}
}

static int BuyMenuHandler_Automatic(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			BuyMenuDrawMoney(param1, param2)
		}

		case MenuAction_Select:
		{
			char selection[32];
			menu.GetItem(param2, selection, sizeof(selection))
			
			if (StrEqual(selection, BUY_UZI))
			{
				MenuBuyItem(param1, "smg")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_UZI_SILENCED))
			{
				MenuBuyItem(param1, "smg_silenced")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_UZI_MP5))
			{
				MenuBuyItem(param1, "smg_mp5")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_RIFLE_M16))
			{
				MenuBuyItem(param1, "rifle")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_RIFLE_AK47))
			{
				MenuBuyItem(param1, "rifle_ak47")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_RIFLE_DESERT))
			{
				MenuBuyItem(param1, "rifle_desert")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_RIFLE_SG552))
			{
				MenuBuyItem(param1, "rifle_sg552")
				OpenBuyMenu(param1)
			}
			
			PrintToServer("Client %d selected %s", param1, selection)
		}

		case MenuAction_Cancel:
		{
			if (canBuy && param2 == -6)
			{
				OpenBuyMenu(param1)
			}
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2)
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}
}

static OpenMenu_Snipers(int client)
{
	if (canBuy)
	{
		Menu menu = new Menu(BuyMenuHandler_Snipers, MenuAction_Display|MenuAction_Select|MenuAction_Cancel|MenuAction_End)
		menu.SetTitle("%s", "Buy: Sniper Rifles", LANG_SERVER)
		
		//Generate weapon strings
		new price1 = GetConVarInt(priceSniperScout);	char option1[255]; Format(option1, sizeof(option1), "Steyr Scout ($%i)", price1)
		new price2 = GetConVarInt(priceSniperHunting);	char option2[255]; Format(option2, sizeof(option2), "Hunting Rifle ($%i)", price2)
		new price3 = GetConVarInt(priceSniperMilitary);	char option3[255]; Format(option3, sizeof(option3), "Military Rifle ($%i)", price3)
		new price4 = GetConVarInt(priceSniperAWP);		char option4[255]; Format(option4, sizeof(option4), "AWP ($%i)", price4)
		
		//Add options to menu
		menu.AddItem(BUY_SNIPER_SCOUT, option1)
		menu.AddItem(BUY_SNIPER_HUNTING, option2)
		menu.AddItem(BUY_SNIPER_MILITARY, option3)
		menu.AddItem(BUY_SNIPER_AWP, option4)
		
		menu.ExitButton = true
		menu.ExitBackButton = true
		menu.Display(client, MENU_TIME_FOREVER)
	}
}

static int BuyMenuHandler_Snipers(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			BuyMenuDrawMoney(param1, param2)
		}

		case MenuAction_Select:
		{
			char selection[32];
			menu.GetItem(param2, selection, sizeof(selection))
			
			if (StrEqual(selection, BUY_SNIPER_SCOUT))
			{
				MenuBuyItem(param1, "sniper_scout")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_SNIPER_HUNTING))
			{
				MenuBuyItem(param1, "hunting_rifle")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_SNIPER_MILITARY))
			{
				MenuBuyItem(param1, "sniper_military")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_SNIPER_AWP))
			{
				MenuBuyItem(param1, "sniper_awp")
				OpenBuyMenu(param1)
			}
			
			PrintToServer("Client %d selected %s", param1, selection)
		}

		case MenuAction_Cancel:
		{
			if (canBuy && param2 == -6)
			{
				OpenBuyMenu(param1)
			}
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2)
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}
}

static OpenMenu_Heavy(int client)
{
	if (canBuy)
	{
		Menu menu = new Menu(BuyMenuHandler_Heavy, MenuAction_Display|MenuAction_Select|MenuAction_Cancel|MenuAction_End)
		menu.SetTitle("%s", "Buy: Heavy Weapons", LANG_SERVER)
		
		//Generate weapon strings
		new price1 = GetConVarInt(priceM60);				char option1[255]; Format(option1, sizeof(option1), "M60 Machine Gun ($%i)", price1)
		new price2 = GetConVarInt(priceGrenadeLauncher);	char option2[255]; Format(option2, sizeof(option2), "Grenade Launcher ($%i)", price2)
		new price3 = GetConVarInt(priceChainsaw);			char option3[255]; Format(option3, sizeof(option3), "Chainsaw ($%i)", price3)
		
		//Add options to menu
		menu.AddItem(BUY_M60, option1)
		menu.AddItem(BUY_GRENADELAUNCHER, option2)
		menu.AddItem(BUY_CHAINSAW, option3)
		
		menu.ExitButton = true
		menu.ExitBackButton = true
		menu.Display(client, MENU_TIME_FOREVER)
	}
}

static int BuyMenuHandler_Heavy(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			BuyMenuDrawMoney(param1, param2)
		}

		case MenuAction_Select:
		{
			char selection[32];
			menu.GetItem(param2, selection, sizeof(selection))
			
			if (StrEqual(selection, BUY_M60))
			{
				MenuBuyItem(param1, "rifle_m60")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_GRENADELAUNCHER))
			{
				MenuBuyItem(param1, "grenade_launcher")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_CHAINSAW))
			{
				MenuBuyItem(param1, "chainsaw")
				OpenBuyMenu(param1)
			}
			
			PrintToServer("Client %d selected %s", param1, selection)
		}

		case MenuAction_Cancel:
		{
			if (canBuy && param2 == -6)
			{
				OpenBuyMenu(param1)
			}
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2)
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}
}

static OpenMenu_Secondary(int client)
{
	if (canBuy)
	{
		Menu menu = new Menu(BuyMenuHandler_Secondary, MenuAction_Display|MenuAction_Select|MenuAction_Cancel|MenuAction_End)
		menu.SetTitle("%s", "Buy: Secondary Weapons", LANG_SERVER)
		
		//Generate weapon strings
		new price1 = GetConVarInt(pricePistol);		char option1[255]; Format(option1, sizeof(option1), "Pistol ($%i)", price1)
		new price2 = GetConVarInt(priceMagnum);		char option2[255]; Format(option2, sizeof(option2), "Desert Eagle ($%i)", price2)
		new price3 = GetConVarInt(priceMeleeBlunt);	char option3[255]; Format(option3, sizeof(option3), "Blunt Melee Weapons ($%i)", price3)
		new price4 = GetConVarInt(priceMeleeSharp);	char option4[255]; Format(option4, sizeof(option4), "Sharp Melee Weapons ($%i)", price4)
		
		//Add options to menu
		menu.AddItem(BUY_PISTOL, option1)
		menu.AddItem(BUY_PISTOL_MAGNUM, option2)
		menu.AddItem(CHOICE_MELEE_BLUNT, option3)
		menu.AddItem(CHOICE_MELEE_SHARP, option4)
		
		menu.ExitButton = true
		menu.ExitBackButton = true
		menu.Display(client, MENU_TIME_FOREVER)
	}
}

static int BuyMenuHandler_Secondary(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			BuyMenuDrawMoney(param1, param2)
		}

		case MenuAction_Select:
		{
			char selection[32];
			menu.GetItem(param2, selection, sizeof(selection))
			
			if (StrEqual(selection, BUY_PISTOL))
			{
				MenuBuyItem(param1, "pistol")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_PISTOL_MAGNUM))
			{
				MenuBuyItem(param1, "pistol_magnum")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, CHOICE_MELEE_BLUNT))
			{
				OpenMenu_Blunt(param1)
			}
			else if (StrEqual(selection, CHOICE_MELEE_SHARP))
			{
				OpenMenu_Sharp(param1)
			}
			
			PrintToServer("Client %d selected %s", param1, selection)
		}

		case MenuAction_Cancel:
		{
			if (canBuy && param2 == -6)
			{
				OpenBuyMenu(param1)
			}
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2)
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}
}

static OpenMenu_Blunt(int client)
{
	if (canBuy)
	{
		Menu menu = new Menu(BuyMenuHandler_Blunt, MenuAction_Display|MenuAction_Select|MenuAction_Cancel|MenuAction_End)
		menu.SetTitle("%s", "Buy: Blunt Melee Weapons", LANG_SERVER)
		
		//Generate weapon strings
		new price1 = GetConVarInt(priceMeleeBlunt)
		char option1[255]; Format(option1, sizeof(option1), "Baseball Bat ($%i)", price1)
		char option2[255]; Format(option2, sizeof(option2), "Cricket Bat ($%i)", price1)
		char option3[255]; Format(option3, sizeof(option3), "Electric Guitar ($%i)", price1)
		char option4[255]; Format(option4, sizeof(option4), "Frying Pan ($%i)", price1)
		char option5[255]; Format(option5, sizeof(option5), "Golfclub ($%i)", price1)
		char option6[255]; Format(option6, sizeof(option6), "Shovel ($%i)", price1)
		char option7[255]; Format(option7, sizeof(option7), "Tonfa ($%i)", price1)
		
		//Add options to menu
		menu.AddItem(BUY_BASEBALLBAT, option1)
		menu.AddItem(BUY_CRICKETBAT, option2)
		menu.AddItem(BUY_GUITAR, option3)
		menu.AddItem(BUY_FRYINGPAN, option4)
		menu.AddItem(BUY_GOLFCLUB, option5)
		menu.AddItem(BUY_SHOVEL, option6)
		menu.AddItem(BUY_TONFA, option7)
		
		menu.ExitButton = true
		menu.ExitBackButton = true
		menu.Display(client, MENU_TIME_FOREVER)
	}
}

static int BuyMenuHandler_Blunt(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			BuyMenuDrawMoney(param1, param2)
		}

		case MenuAction_Select:
		{
			char selection[32];
			menu.GetItem(param2, selection, sizeof(selection))
			
			if (StrEqual(selection, BUY_BASEBALLBAT))
			{
				MenuBuyItem(param1, "baseball_bat", 1)
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_CRICKETBAT))
			{
				MenuBuyItem(param1, "cricket_bat", 1)
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_GUITAR))
			{
				MenuBuyItem(param1, "electric_guitar", 1)
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_FRYINGPAN))
			{
				MenuBuyItem(param1, "frying_pan", 1)
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_GOLFCLUB))
			{
				MenuBuyItem(param1, "golfclub", 1)
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_SHOVEL))
			{
				MenuBuyItem(param1, "shovel", 1)
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_TONFA))
			{
				MenuBuyItem(param1, "tonfa", 1)
				OpenBuyMenu(param1)
			}
			
			PrintToServer("Client %d selected %s", param1, selection)
		}

		case MenuAction_Cancel:
		{
			if (canBuy && param2 == -6)
			{
				OpenMenu_Secondary(param1)
			}
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2)
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}
}

static OpenMenu_Sharp(int client)
{
	if (canBuy)
	{
		Menu menu = new Menu(BuyMenuHandler_Sharp, MenuAction_Display|MenuAction_Select|MenuAction_Cancel|MenuAction_End)
		menu.SetTitle("%s", "Buy: Sharp Melee Weapons", LANG_SERVER)
		
		//Generate weapon strings
		new price1 = GetConVarInt(priceMeleeSharp)
		char option1[255]; Format(option1, sizeof(option1), "Crowbar ($%i)", price1)
		char option2[255]; Format(option2, sizeof(option2), "Fire Axe ($%i)", price1)
		char option3[255]; Format(option3, sizeof(option3), "Katana ($%i)", price1)
		char option4[255]; Format(option4, sizeof(option4), "Knife ($%i)", price1)
		char option5[255]; Format(option5, sizeof(option5), "Machete ($%i)", price1)
		char option6[255]; Format(option6, sizeof(option6), "Pitchfork ($%i)", price1)
		
		//Add options to menu
		menu.AddItem(BUY_CROWBAR, option1)
		menu.AddItem(BUY_FIRAXE, option2)
		menu.AddItem(BUY_KATANA, option3)
		menu.AddItem(BUY_KNIFE, option4)
		menu.AddItem(BUY_MACHETE, option5)
		menu.AddItem(BUY_PITCHFORK, option6)
		
		menu.ExitButton = true
		menu.ExitBackButton = true
		menu.Display(client, MENU_TIME_FOREVER)
	}
}

static int BuyMenuHandler_Sharp(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			BuyMenuDrawMoney(param1, param2)
		}

		case MenuAction_Select:
		{
			char selection[32];
			menu.GetItem(param2, selection, sizeof(selection))
			
			if (StrEqual(selection, BUY_CROWBAR))
			{
				MenuBuyItem(param1, "crowbar", 1)
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_FIRAXE))
			{
				MenuBuyItem(param1, "fireaxe", 1)
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_KATANA))
			{
				MenuBuyItem(param1, "katana", 1)
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_KNIFE))
			{
				MenuBuyItem(param1, "knife", 1)
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_MACHETE))
			{
				MenuBuyItem(param1, "machete", 1)
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_PITCHFORK))
			{
				MenuBuyItem(param1, "pitchfork", 1)
				OpenBuyMenu(param1)
			}
			
			PrintToServer("Client %d selected %s", param1, selection)
		}

		case MenuAction_Cancel:
		{
			if (canBuy && param2 == -6)
			{
				OpenMenu_Secondary(param1)
			}
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2)
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}
}

static OpenMenu_Throwable(int client)
{
	if (canBuy)
	{
		Menu menu = new Menu(BuyMenuHandler_Throwable, MenuAction_Display|MenuAction_Select|MenuAction_Cancel|MenuAction_End)
		menu.SetTitle("%s", "Buy: Throwables", LANG_SERVER)
		
		//Generate weapon strings
		new price1 = GetConVarInt(priceMolotov);	char option1[255]; Format(option1, sizeof(option1), "Molotov ($%i)", price1)
		new price2 = GetConVarInt(pricePipebomb);	char option2[255]; Format(option2, sizeof(option2), "Pipe Bomb ($%i)", price2)
		new price3 = GetConVarInt(priceBilebomb);	char option3[255]; Format(option3, sizeof(option3), "Bile Bomb ($%i)", price3)
		
		//Add options to menu
		menu.AddItem(BUY_MOLOTOV, option1)
		menu.AddItem(BUY_PIPEBOMB, option2)
		menu.AddItem(BUY_BILEBOMB, option3)
		
		menu.ExitButton = true
		menu.ExitBackButton = true
		menu.Display(client, MENU_TIME_FOREVER)
	}
}

static int BuyMenuHandler_Throwable(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			BuyMenuDrawMoney(param1, param2)
		}

		case MenuAction_Select:
		{
			char selection[32];
			menu.GetItem(param2, selection, sizeof(selection))
			
			if (StrEqual(selection, BUY_MOLOTOV))
			{
				MenuBuyItem(param1, "molotov")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_PIPEBOMB))
			{
				MenuBuyItem(param1, "pipe_bomb")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_BILEBOMB))
			{
				MenuBuyItem(param1, "vomitjar")
				OpenBuyMenu(param1)
			}
			
			PrintToServer("Client %d selected %s", param1, selection)
		}

		case MenuAction_Cancel:
		{
			if (canBuy && param2 == -6)
			{
				OpenBuyMenu(param1)
			}
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2)
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}
}

static OpenMenu_Healing(int client)
{
	if (canBuy)
	{
		Menu menu = new Menu(BuyMenuHandler_Healing, MenuAction_Display|MenuAction_Select|MenuAction_Cancel|MenuAction_End)
		menu.SetTitle("%s", "Buy: Healing Items", LANG_SERVER)
		
		//Generate weapon strings
		new price1 = GetConVarInt(pricePainPills);		char option1[255]; Format(option1, sizeof(option1), "Pain Pills ($%i)", price1)
		new price2 = GetConVarInt(priceAdrenaline);		char option2[255]; Format(option2, sizeof(option2), "Adrenaline ($%i)", price2)
		new price3 = GetConVarInt(priceMedkit);			char option3[255]; Format(option3, sizeof(option3), "First Aid Kit ($%i)", price3)
		new price4 = GetConVarInt(priceDefibrillator);	char option4[255]; Format(option4, sizeof(option4), "Defibrillator ($%i)", price4)
		
		//Add options to menu
		menu.AddItem(BUY_PAINPILLS, option1)
		menu.AddItem(BUY_ADRENALINE, option2)
		menu.AddItem(BUY_MEDKIT, option3)
		menu.AddItem(BUY_DEFIB, option4)
		
		menu.ExitButton = true
		menu.ExitBackButton = true
		menu.Display(client, MENU_TIME_FOREVER)
	}
}

static int BuyMenuHandler_Healing(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			BuyMenuDrawMoney(param1, param2)
		}

		case MenuAction_Select:
		{
			char selection[32];
			menu.GetItem(param2, selection, sizeof(selection))
			
			if (StrEqual(selection, BUY_PAINPILLS))
			{
				MenuBuyItem(param1, "pain_pills")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_ADRENALINE))
			{
				MenuBuyItem(param1, "adrenaline")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_MEDKIT))
			{
				MenuBuyItem(param1, "first_aid_kit")
				OpenBuyMenu(param1)
			}
			else if (StrEqual(selection, BUY_DEFIB))
			{
				MenuBuyItem(param1, "defibrillator")
				OpenBuyMenu(param1)
			}
			
			PrintToServer("Client %d selected %s", param1, selection)
		}

		case MenuAction_Cancel:
		{
			if (canBuy && param2 == -6)
			{
				OpenBuyMenu(param1)
			}
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2)
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}
}

/*
	ITEM BUYING FUNCTIONS
*/
static MenuBuyItem(client, const char[] item, int itemType = 0)
{
	if (canBuy)
	{
		int index = GetClientIndex(client)
		if (index != -1)
		{
			new currentMoney = GetMoney(client)
			new itemPrice = GetItemPrice(item)
			
			if (currentMoney >= itemPrice)
			{
				SpendMoney(client, itemPrice)
				GiveClientItem(client, item, itemType)
			}
		}
	}
}

static GiveClientItem(client, const char[] item, int itemType = 0)
{
	new flagsGive = GetCommandFlags("give")
	new flagsUpgradeAdd = GetCommandFlags("upgrade_add")
	SetCommandFlags("give", flagsGive & ~FCVAR_CHEAT)
	SetCommandFlags("upgrade_add", flagsGive & ~FCVAR_CHEAT)
	
	char buffer[255]
	switch(itemType)
	{
		//Standard Weapons
		case 0:
		{
			Format(buffer, sizeof(buffer), "give weapon_%s", item)
		}
		//Melee Weapons
		case 1:
		{
			Format(buffer, sizeof(buffer), "give %s", item)
		}
		//Upgrades
		case 2:
		{
			Format(buffer, sizeof(buffer), "upgrade_add %s", item)
		}
	}
	
	FakeClientCommand(client, buffer)
	SetCommandFlags("give", flagsGive|FCVAR_CHEAT)
	SetCommandFlags("upgrade_add", flagsUpgradeAdd|FCVAR_CHEAT)
}

static int GetItemPrice(const char[] item)
{
	//Spaghetti Time
	int itemPrice = 0
	
	//Shotguns
	if (StrEqual(item, "pumpshotgun"))
	{
		itemPrice = GetConVarInt(priceShotgunPump)
	}
	else if (StrEqual(item, "shotgun_chrome"))
	{
		itemPrice = GetConVarInt(priceShotgunChrome)
	}
	else if (StrEqual(item, "autoshotgun"))
	{
		itemPrice = GetConVarInt(priceShotgunAuto)
	}
	else if (StrEqual(item, "shotgun_spas"))
	{
		itemPrice = GetConVarInt(priceShotgunSpas)
	}
	//Uzis
	else if (StrEqual(item, "smg"))
	{
		itemPrice = GetConVarInt(priceUzi)
	}
	else if (StrEqual(item, "smg_silenced"))
	{
		itemPrice = GetConVarInt(priceUziSilenced)
	}
	else if (StrEqual(item, "smg_mp5"))
	{
		itemPrice = GetConVarInt(priceUziMP5)
	}
	//Rifles
	else if (StrEqual(item, "rifle"))
	{
		itemPrice = GetConVarInt(priceRifleM16)
	}
	else if (StrEqual(item, "rifle_ak47"))
	{
		itemPrice = GetConVarInt(priceRifleAK47)
	}
	else if (StrEqual(item, "rifle_desert"))
	{
		itemPrice = GetConVarInt(priceRifleDesert)
	}
	else if (StrEqual(item, "rifle_sg552"))
	{
		itemPrice = GetConVarInt(priceRifleSG552)
	}
	//Snipers
	else if (StrEqual(item, "hunting_rifle"))
	{
		itemPrice = GetConVarInt(priceSniperHunting)
	}
	else if (StrEqual(item, "sniper_military"))
	{
		itemPrice = GetConVarInt(priceSniperMilitary)
	}
	else if (StrEqual(item, "sniper_scout"))
	{
		itemPrice = GetConVarInt(priceSniperScout)
	}
	else if (StrEqual(item, "sniper_awp"))
	{
		itemPrice = GetConVarInt(priceSniperAWP)
	}
	//Heavy
	else if (StrEqual(item, "rifle_m60"))
	{
		itemPrice = GetConVarInt(priceM60)
	}
	else if (StrEqual(item, "grenade_launcher"))
	{
		itemPrice = GetConVarInt(priceGrenadeLauncher)
	}
	else if (StrEqual(item, "chainsaw"))
	{
		itemPrice = GetConVarInt(priceChainsaw)
	}
	//Pistols
	else if (StrEqual(item, "pistol"))
	{
		itemPrice = GetConVarInt(pricePistol)
	}
	else if (StrEqual(item, "pistol_magnum"))
	{
		itemPrice = GetConVarInt(priceMagnum)
	}
	//Throwables
	else if (StrEqual(item, "molotov"))
	{
		itemPrice = GetConVarInt(priceMolotov)
	}
	else if (StrEqual(item, "pipe_bomb"))
	{
		itemPrice = GetConVarInt(pricePipebomb)
	}
	else if (StrEqual(item, "vomitjar"))
	{
		itemPrice = GetConVarInt(priceBilebomb)
	}
	//Healing Items
	else if (StrEqual(item, "pain_pills"))
	{
		itemPrice = GetConVarInt(pricePainPills)
	}
	else if (StrEqual(item, "adrenaline"))
	{
		itemPrice = GetConVarInt(priceAdrenaline)
	}
	else if (StrEqual(item, "first_aid_kit"))
	{
		itemPrice = GetConVarInt(priceMedkit)
	}
	else if (StrEqual(item, "defibrillator"))
	{
		itemPrice = GetConVarInt(priceDefibrillator)
	}
	//Blunt Melees
	else if (StrEqual(item, "baseball_bat") || StrEqual(item, "cricket_bat") || StrEqual(item, "electric_guitar") || StrEqual(item, "frying_pan") || StrEqual(item, "golfclub") || StrEqual(item, "shovel") || StrEqual(item, "tonfa"))
	{
		itemPrice = GetConVarInt(priceMeleeBlunt)
	}
	//Sharp Melees
	else if (StrEqual(item, "crowbar") || StrEqual(item, "fireaxe") || StrEqual(item, "katana") || StrEqual(item, "knife") || StrEqual(item, "machete") || StrEqual(item, "pitchfork"))
	{
		itemPrice = GetConVarInt(priceMeleeSharp)
	}
	//Invalid item
	else
	{
		
	}
	
	return itemPrice;
}

/*
	MONEY
*/
stock int GetMoney(client)
{
	int index = GetClientIndex(client)
	if (index != -1)
	{
		new currentMoney = GetArrayCell(g_playerMoney, index)
		return currentMoney;
	}
	return -1;
}

static GiveMoney(client, int amount)
{
	int index = GetClientIndex(client)
	if (index != -1)
	{
		new maxMoney = GetConVarInt(maximumMoney)
		new currentMoney = GetArrayCell(g_playerMoney, index)
		new newMoney = currentMoney + amount
		
		//Limit money to maximum amount
		if (newMoney <= maxMoney)
		{
			SetArrayCell(g_playerMoney, index, newMoney)
		}
		else
		{
			SetArrayCell(g_playerMoney, index, maxMoney)
		}
	}
	
}

static SpendMoney(client, int amount)
{
	int index = GetClientIndex(client)
	if (index != -1)
	{
		new currentMoney = GetArrayCell(g_playerMoney, index)
		new newMoney = currentMoney - amount
		
		//Prevent money going into negatives
		if (newMoney >= 0)
		{
			SetArrayCell(g_playerMoney, index, newMoney)
		}
		else
		{
			SetArrayCell(g_playerMoney, index, 0)
		}
	}
	
}

static bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && !IsFakeClient(client));
}

static int GetClientIndex(int client)
{
	if (IsValidClient(client))
	{
		char steamID[64]
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))
		new index = FindStringInArray(g_steamIDs,steamID)
		return index;
	}
	return -1;
}

/*
NOTES:

Ideas:
saferoom door is locked for [x] seconds at the start of each round (non-doored saferooms can teleport you back in like ready up)
way to drop any item/buy for your team
money transfer system - lets you send money (in fixed amounts e.g. $500 etc) to a teammate
maybe some kind of refund system for not needing to use an item when the round ends, maybe this could be an optional award given when reaching the saferoom (but by default no bonus would be awarded for saving your medkit etc)
speed bonus - bonus awarded for being faster than the other team (e.g. at least 1 minute faster), hard to make it account for all situations and maps though, and would have to ignore tank fights. maybe it can be awarded for each 25% of distance. would just end up rewarding the winning team more most of the time though
money could be a single pool shared by the entire team, but then it could be griefed by people spamming buys or someone switching to grief
something to control ammo pile density (e.g. multiply density per map)
buy menu is always shown until you leave saferoom, but you can always buy stuff if you go back to the starting saferoom (otherwise people could end up with no weapon)
interacting with ammo pile/pill cabinet can let you buy maybe? or maybe a custom buying point, but custom maps could be an issue
detect campaign length using functions/mission file, option to have multiplier for shorter/longer than normal campaigns (maybe bonus applied to start money)
weapon upgrades are  permanent
weapon upgrade changes:
	-fire ammo, some kind of nerf like reducing damage dealt, increasing reload time
	-explosive ammo no longer stumbles
	-laser does not give as much accuracy
	-increase deploy time
	-only 1 person can take upgrade from box
weakest link "bank" money for scoring
or wager on winning
get more points the longer you have someone capped (15 points for inital cap, 5 for every 2 seconds on them)
extra points per each kill should be fine really



Todo:
steam id is assigned default starting money on joining, track money between map changes
display amount of money everyone on your team has
account for round resets (revert money/items back to what it was at start of round)
functions to lock saferoom/keep players in
functions to optionally remove item and weapon spawns - need something to allow ammo piles to spawn though, or replace weapons with ammo
variables to enable heavy weapons, upgrades, etc menu
admin commands to set money
show and allow buy menu a bit after round start, hide it when round is going live but still allow buying



Other Notes:
health bonuses will ignore any healing items in the player's inventory
penalties/rewards for incaps vs deaths could have issues, e.g. cases where a player dies instantly without incapping, or incaps then instantly dies from hurt trigger, and timing for when players die if a wipe happens (e.g. before or after round is "over")
make sure points arent gained/lost once round is over


not sure how to handle abuses of the system:
player joins and buys a bunch of stuff for their team then leaves
player switches teams between rounds
what to do when someone leaves (if they dont come back money is wasted and team is at a disadvantage)


*/
