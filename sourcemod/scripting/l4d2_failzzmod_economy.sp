#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <left4dhooks>

public Plugin:myinfo = 
{
	name = "FailzzMod Economy",
	author = "Derpduck",
	description = "A CS:GO-style economy system in L4D2, for FailzzMod",
	version = "1",
	url = "https://github.com/Derpduck/Derpduck-L4D2-Scripts"
}

//Return survivors to saferoom
#define NULL_VELOCITY view_as<float>({0.0, 0.0, 0.0})

//TRACK STEAM IDs
#define AUTH_ADT_LENGTH (ByteCountToCells(64))
ArrayList g_steamIDs
ArrayList g_playerMoney

//MENU DEFINES
//Base menu choices
#define CHOICE_SHOTGUNS "#choice_shotguns"
#define CHOICE_AUTOMATIC "#choice_automatic"
#define CHOICE_SNIPERS "#choice_snipers"
#define CHOICE_HEAVY "#choice_heavy"
#define CHOICE_SECONDARY "#choice_secondary"
#define CHOICE_THROWABLE "#choice_throwable"
#define CHOICE_HEALING "#choice_healing"
#define CHOICE_UPGRADES "#choice_upgrades"
//Items
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
//Melee menus
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

//ENUMS
enum
{
	teamNone,
	teamSpectator,
	teamSurvivor,
	teamInfected
}

//CONSTANTS
//const SPAWNFLAGS_IGNORE_USE = 32768

//VARIABLES
//Round state
bool g_bCanBuy = false
bool g_bRoundLive = false
bool g_bSaferoomLocked = false
int g_iTimeSinceRoundStarted = 0
//Valid melee weapons
int g_iValidMeleeCount = 0
new String:g_sValidMelees[16][32]
int g_iTeamALostCounter = 0
int g_iTeamBLostCounter = 0
int g_iAreTeamsFlipped = 0
int g_iPointsTeamA = 0
int g_iPointsTeamB = 0
//Cappers landing and cap duration
int g_iSmokerChokeID = 0
int g_iHunterPounceID = 0
int g_iJockeyRideID = 0
int g_iChargerPummelID = 0

/*
	CONVARS
*/
//BUY TIME
ConVar	initialBuyTime, extendedBuyTime;
//MONEY
ConVar	startingMoney, maximumMoney;
//AWARD AMOUNTS
ConVar	awardRoundEnd, awardWonMap, awardLostMap, awardConsecutiveLoss, awardExtraConsecutiveLoss,
		awardKilledTank, awardKilledWitch,
		awardWipedSurvivors, awardSurvivorIncapped, awardSurvivorKilled,
		awardAbilityLanded, awardSkilledAbilityLanded, awardLongPinTime,
		awardHealthGreen, awardHealthYellow, awardHealthRed, awardHealthTempOnly,
		awardDistanceMultiplier;
//ITEM PRICES
ConVar	priceShotgunPump, priceShotgunChrome,
		priceUzi, priceUziSilenced, priceUziMP5,
		priceRifleM16, priceRifleAK47, priceRifleDesert, priceRifleSG552,
		priceShotgunAuto, priceShotgunSpas,
		priceSniperHunting, priceSniperMilitary, priceSniperScout, priceSniperAWP,
		priceM60, priceGrenadeLauncher, priceChainsaw,
		pricePistol, priceMagnum,
		priceMeleeBlunt, priceMeleeSharp,
		priceMolotov, pricePipebomb, priceBilebomb,
		pricePainPills, priceAdrenaline, priceMedkit, priceDefibrillator;
/*
ConVar	priceLaser, priceFireAmmo, priceExplosiveAmmo;
*/

ConVar economyDebug;

public OnPluginStart()
{
	//HOOKS
	//Round state
	HookEvent("round_start", EventHook:RoundStartEvent, EventHookMode_PostNoCopy)
	//Player finished loading in
	HookEvent("player_activate", EventHook:PlayerActivateEvent, EventHookMode_Post)
	//General award events
	HookEvent("player_death", EventHook:PlayerDeathEvent, EventHookMode_Post)
	HookEvent("witch_killed", EventHook:WitchKilledEvent, EventHookMode_Post)
	HookEvent("player_incapacitated", EventHook:PlayerIncappedEvent, EventHookMode_Post)
	//Infected ability award events
	HookEvent("choke_start", EventHook:ChokeStartEvent, EventHookMode_Post) //Smoker
	HookEvent("tongue_release", EventHook:TongueReleaseEvent, EventHookMode_Post) //Smoker
	HookEvent("jockey_ride", EventHook:JockeyRideEvent, EventHookMode_Post) //Jockey
	HookEvent("jockey_ride_end", EventHook:JockeyRideEndEvent, EventHookMode_Post) //Jockey
	HookEvent("charger_pummel_start", EventHook:ChargerPummelStartEvent, EventHookMode_Post) //Charger
	HookEvent("charger_pummel_end", EventHook:ChargerPummelEndEvent, EventHookMode_Post) //Charger
	HookEvent("lunge_pounce", EventHook:HunterPounceEvent, EventHookMode_Post) //Hunter
	HookEvent("pounce_stopped", EventHook:HunterPounceStoppedEvent, EventHookMode_Post) //Hunter
	HookEvent("player_now_it", EventHook:BoomerLandedEvent, EventHookMode_Post) //Boomer
	//Skilled ability award events
	HookEvent("player_falldamage", EventHook:PlayerFalldamageEvent, EventHookMode_Post) //Fall damage
	HookEvent("player_ledge_grab", EventHook:PlayerLedgeGrabEvent, EventHookMode_Post) //Ledge hangs
	HookEvent("charger_impact", EventHook:ChargerImpactEvent, EventHookMode_Post) //Multi charges
	
	//Debug mode
	economyDebug = CreateConVar("economy_debug",				"0",		"Enable some debug prints")
	
	//ADMIN COMMANDS
	RegAdminCmd("givemoney", GiveMoney_Cmd, ADMFLAG_GENERIC, "Gives specified amount of money to player")
	RegAdminCmd("removemoney", RemoveMoney_Cmd, ADMFLAG_GENERIC, "Removes specified amount of money from player")
	RegAdminCmd("extendbuy", ExtendBuy_Cmd, ADMFLAG_GENERIC, "Extends buy time by 30 seconds (even if buy time has ended)")
	
	//CLIENT COMMANDS
	RegConsoleCmd("buy", Buy_Menu)
	RegConsoleCmd("money", Money_Cmd)
	
	//BUY TIME
	initialBuyTime				= CreateConVar("initial_buy_time",				"45",		"Amount of time to buy before the round starts and players are allowed out of the saferoom")
	extendedBuyTime				= CreateConVar("extended_buy_time",				"30",		"Amount of time allowed to buy items after the round starts")
	
	//MONEY
	startingMoney				= CreateConVar("starting_money",				"1600",		"Amount of money players start out with upon joining for the first time")
	maximumMoney				= CreateConVar("maximum_money",					"16000",	"Maximum amount of money players are allowed to have") //Placeholder value
	
	//AWARD AMOUNTS
	awardRoundEnd				= CreateConVar("award_round_end",				"1600",		"Money awarded to survivors on (half) round end (0 = No Award) [Team]")
	awardWonMap					= CreateConVar("award_won_map",					"1200",		"Money awarded for winning a map (0 = No Award) [Team]")
	awardLostMap				= CreateConVar("award_lost_map",				"900",		"Money awarded for losing a map (0 = No Award) [Team]")
	awardConsecutiveLoss		= CreateConVar("award_consecutive_loss",		"1000",		"Extra money awarded for losing 2 maps consecutively (0 = No Award) [Team]")
	awardExtraConsecutiveLoss	= CreateConVar("award_extra_consecutive_loss",	"1100",		"Extra money awarded for losing 3 or more maps consecutively (0 = No Award) [Team]")
	awardKilledTank				= CreateConVar("award_killed_tank",				"150",		"Money awarded for killing a tank (0 = No Award) [Team]") //Placeholder value
	awardKilledWitch			= CreateConVar("award_killed_witch",			"75",		"Money awarded for killing a witch in 1 shot (0 = No Award) [Team / Personal (default)]") //Placeholder value
	awardWipedSurvivors			= CreateConVar("award_wiped_survivors",			"200",		"Money awarded for killing all the survivors (0 = No Award) [Team]") //Placeholder value
	awardSurvivorIncapped		= CreateConVar("award_survivor_incapped",		"25",		"Money awarded for incapping a survivor (0 = No Award) [Personal]") //Placeholder value
	awardSurvivorKilled			= CreateConVar("award_survivor_killed",			"50",		"Money awarded for killing a survivor (0 = No Award) [Personal]") //Placeholder value
	awardAbilityLanded			= CreateConVar("award_ability_landed",			"5",		"Money awarded for landing an infected ability (excludes spitter) (0 = No Award) [Personal]") //Placeholder value
	awardSkilledAbilityLanded	= CreateConVar("award_skill_ability_landed",	"10",		"Money awarded for landing infected abilities skillfully (0 = No Award) [Personal]") //Placeholder value
	awardLongPinTime			= CreateConVar("award_long_pin_time",			"20",		"Money awarded for pinning a survivor for more than 5 seconds (0 = No Award) [Personal]") //Placeholder value
	awardHealthGreen			= CreateConVar("award_health_green",			"75",		"Money awarded for each survivor that completes the map with green health (0 = No Award) [Team / Personal (default)]") //Placeholder value
	awardHealthYellow			= CreateConVar("award_health_yellow",			"30",		"Money awarded for each survivor that completes the map with yellow health (0 = No Award) [Team / Personal (default)]") //Placeholder value
	awardHealthRed				= CreateConVar("award_health_red",				"15",		"Money awarded for each survivor that completes the map with red health (0 = No Award) [Team / Personal (default)]") //Placeholder value
	awardHealthTempOnly			= CreateConVar("award_health_temp_only",		"10",		"Money awarded for each survivor that completes the map with only temporary health (0 = No Award) [Team / Personal (default)]") //Placeholder value
	awardDistanceMultiplier		= CreateConVar("award_distance_multiplier",		"0.25",		"Multiplier of distance points as money awarded (0 = No Award)") //Placeholder value
	
	//ITEM PRICES
	//Shotguns
	priceShotgunPump			= CreateConVar("price_shotgun_pump",			"1050",		"Cost of weapon: pumpshotgun")
	priceShotgunChrome			= CreateConVar("price_shotgun_chrome",			"1100",		"Cost of weapon: shotgun_chrome")
	priceShotgunAuto			= CreateConVar("price_shotgun_auto",			"2200",		"Cost of weapon: autoshotgun")
	priceShotgunSpas			= CreateConVar("price_shotgun_spas",			"2300",		"Cost of weapon: shotgun_spas")
	//Uzis
	priceUzi					= CreateConVar("price_uzi",						"1050",		"Cost of weapon: smg")
	priceUziSilenced			= CreateConVar("price_uzi_silenced",			"1150",		"Cost of weapon: smg_silenced")
	priceUziMP5					= CreateConVar("price_uzi_mp5",					"1200",		"Cost of weapon: smg_mp5")
	//Rifles
	priceRifleM16				= CreateConVar("price_rifle_m16",				"2900",		"Cost of weapon: rifle")
	priceRifleAK47				= CreateConVar("price_rifle_ak47",				"2500",		"Cost of weapon: rifle_ak47")
	priceRifleDesert			= CreateConVar("price_rifle_desert",			"2050",		"Cost of weapon: rifle_desert")
	priceRifleSG552				= CreateConVar("price_rifle_sg552",				"3100",		"Cost of weapon: rifle_sg552")
	//Snipers
	priceSniperHunting			= CreateConVar("price_sniper_hunting",			"4500",		"Cost of weapon: hunting_rifle")
	priceSniperMilitary			= CreateConVar("price_sniper_military",			"4750",		"Cost of weapon: sniper_military")
	priceSniperScout			= CreateConVar("price_sniper_scout",			"1700",		"Cost of weapon: sniper_scout")
	priceSniperAWP				= CreateConVar("price_sniper_awp",				"4200",		"Cost of weapon: sniper_awp")
	//Heavy Weaopns
	priceM60					= CreateConVar("price_m60",						"4500",		"Cost of weapon: rifle_m60") //Placeholder value
	priceGrenadeLauncher		= CreateConVar("price_grenade_launcher",		"16000",		"Cost of weapon: grenade_launcher") //Placeholder value
	priceChainsaw				= CreateConVar("price_chainsaw",				"16000",		"Cost of weapon: chainsaw") //Placeholder value
	//Secondaries
	pricePistol					= CreateConVar("price_pistol",					"250",		"Cost of weapon: pistol (per pistol)")
	priceMagnum					= CreateConVar("price_pistol_magnum",			"700",		"Cost of weapon: pistol_magnum")
	priceMeleeBlunt				= CreateConVar("price_melee_blunt",				"500",		"Cost of weapon(s): baseball_bat, cricket_bat, electric_guitar, frying_pan, golfclub, shovel, tonfa")
	priceMeleeSharp				= CreateConVar("price_melee_sharp",				"700",		"Cost of weapon(s): crowbar, fireaxe, katana, knife, machete, pitchfork")
	//Throwables
	priceMolotov				= CreateConVar("price_molotov",					"300",		"Cost of weapon: molotov")
	pricePipebomb				= CreateConVar("price_pipe_bomb",				"400",		"Cost of weapon: pipe_bomb")
	priceBilebomb				= CreateConVar("price_bile_bomb",				"600",		"Cost of weapon: vomitjar")
	//Healing Items
	pricePainPills				= CreateConVar("price_pain_pills",				"400",		"Cost of weapon: pain_pills")
	priceAdrenaline				= CreateConVar("price_adrenaline",				"650",		"Cost of weapon: adrenaline")
	priceMedkit					= CreateConVar("price_medkit",					"1000",		"Cost of weapon: first_aid_kit")
	priceDefibrillator			= CreateConVar("price_defibrillator",			"1400",		"Cost of weapon: defibrillator")
	/*
	//Upgrades
	priceLaser					= CreateConVar("price_laser",					"2500",	"Cost of upgrade: laser sights") //Placeholder value
	priceFireAmmo				= CreateConVar("price_fire_ammo",				"3000",	"Cost of upgrade: upgradepack_incendiary") //Placeholder value
	priceExplosiveAmmo			= CreateConVar("price_explosive_ammo",			"5000",	"Cost of upgrade: upgradepack_explosive") //Placeholder value
	*/
	
	//Initalize money tracking
	g_steamIDs = new ArrayList(AUTH_ADT_LENGTH)
	g_playerMoney = new ArrayList(AUTH_ADT_LENGTH)
	g_steamIDs.Clear()
	g_playerMoney.Clear()
}

//Return valid melee's for current campaign
static GetValidMelees()
{
	new tableValidMelees = FindStringTable("MeleeWeapons")
	g_iValidMeleeCount = GetStringTableNumStrings(tableValidMelees)
	
	for (int i = 0; i < g_iValidMeleeCount; i++)
	{
		ReadStringTable(tableValidMelees, i, g_sValidMelees[i], 32)
	}
}

/*
	INITIALIZE CLIENTS
*/
//When client connects in begin tracking money
public OnClientPutInServer(client)
{
	AddClientToList(client)
}

//Client finished loading in, show menu
static Action:PlayerActivateEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"))
	
	//Show menu if client is survivor and it is possible to buy
	if (IsValidClient(client))
	{
		if (GetClientTeam(client) == teamSurvivor)
		{
			if (g_bCanBuy)
			{
				CreateTimer(1.0, BuyMenuAutoShow, client)
				int currentTime = GetTime()
				int timeLeft = currentTime - g_iTimeSinceRoundStarted
				PrintToChatAll("%i - %i",currentTime, g_iTimeSinceRoundStarted)
				if (g_iTimeSinceRoundStarted != 0)
				{
					CPrintToChat(client, "{olive}[ECO]{default} You have {green}%i{default} seconds left to {blue}!buy{default}.", timeLeft)
				}
			}
		}
	}
}

//Add client to money tracking arrays
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
		}
		
		//Show menu if client is survivor
		if (GetClientTeam(client) == teamSurvivor)
		{
			if (g_bCanBuy)
			{
				if (GetClientMenu(client) != MenuSource_None)
				{
					CreateTimer(1.0, BuyMenuAutoShow, client)
				}
			}
		}
	}
}

//Remove clients from money tracking list - stock since we don't use this
stock RemoveClientFromList(client)
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
		}
	}
}

//Show menu to joining clients
static Action:BuyMenuAutoShow(Handle timer, client)
{
	OpenBuyMenu(client)
}

//When round starts keep survivors in the saferoom and initialize  buying system
static RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bCanBuy = false
	g_bRoundLive = false
	GetValidMelees()
	g_iTimeSinceRoundStarted = 0
	CreateTimer(15.0, RoundStartEvent_Delay)
	
	LockSaferoom()
}

//Round start event on delay
static Action:RoundStartEvent_Delay(Handle timer)
{
	//Reset global variables
	g_iAreTeamsFlipped = AreTeamsFlipped()
	
	g_iPointsTeamA = 0
	g_iPointsTeamB = 0
	
	g_iSmokerChokeID = 0
	g_iHunterPounceID = 0
	g_iJockeyRideID = 0
	g_iChargerPummelID = 0
	
	//Check if a new game has started (both teams have 0 points)
	int isSecondHalf = InSecondHalfOfRound()
	if (isSecondHalf)
	{
		int pointsTeamA = L4D2Direct_GetVSCampaignScore(0)
		int pointsTeamB = L4D2Direct_GetVSCampaignScore(1)
		
		if (pointsTeamA == 0 && pointsTeamB == 0)
		{
			//Reset all money
			ResetMoney()
			g_iTeamALostCounter = 0
			g_iTeamBLostCounter = 0
		}
	}
	
	//Enable buying and create menu for survivors
	g_bCanBuy = true
	g_iTimeSinceRoundStarted = GetTime()
	
	int buyTime = GetConVarInt(initialBuyTime)
	int extraBuyTime = GetConVarInt(extendedBuyTime)
	CreateTimer(float(buyTime), EndLockTime)
	
	CPrintToChatAll("{olive}[ECO]{default} Survivors have {green}%i (+%i){default} seconds to {blue}!buy{default}.", buyTime, extraBuyTime)
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (GetClientTeam(i) == teamSurvivor)
			{
				OpenBuyMenu(i)
				PrintTeamFunds(i, teamSurvivor)
			}
		}
	}
}

//Print team's money to chat
static PrintTeamFunds(client, int team)
{
	decl String:name[MAX_NAME_LENGTH]
	GetClientName(client, name, sizeof(name))
	int clientMoney = GetMoney(client)
	CPrintToChat(client, "{olive}[ECO]{default} {blue}%s{default}: {green}$%i", name, clientMoney)
	
	//Go through players and print other survivors
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (GetClientTeam(i) == team)
			{
				if (i != client)
				{
					GetClientName(i, name, sizeof(name))
					clientMoney = GetMoney(i)
					CPrintToChat(client, "{olive}[ECO]{default} {blue}%s{default}: {green}$%i", name, clientMoney)
				}
			}
		}
	}
}

static Action:Money_Cmd(int client, int args)
{
	PrintTeamFunds(client, GetClientTeam(client))
}

//Open saferooms
static Action:EndLockTime(Handle timer)
{
	g_bRoundLive = true
	UnlockSaferoom()
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (GetClientTeam(i) == teamSurvivor)
			{
				ReturnSurvivorToSaferoom(i, false)
			}
		}
	}
	
	//Allow buying for specified time after unlocking saferoom
	int extraBuyTime = GetConVarInt(extendedBuyTime)
	CreateTimer(float(extraBuyTime), EndBuyTime)
	CPrintToChatAll("{olive}[ECO]{default} Round is live! {green}%i{default} seconds left to {blue}!buy{default}.", extraBuyTime)
}

//End buy time
static Action:EndBuyTime(Handle timer)
{
	g_bCanBuy = false
	g_iTimeSinceRoundStarted = 0
	
	//If player is a bot once buy time expires, give them some items
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivorBot(i))
		{
			//Basic T1 loadout
			BotBuyItems(i, 0)
		}
	}
}

//Completely reset money tracking, re-add all currently loaded clients
static ResetMoney()
{
	g_steamIDs.Clear()
	g_playerMoney.Clear()
	
	//Add all valid players currently in-game
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			AddClientToList(i)
		}
	}
}

//Give bots a random T1 and pills
static BotBuyItems(int client, int loadoutType = 0)
{
	//T1 loadout
	switch(loadoutType)
	{
		//Basic T1 loadout
		case 0:
		{
			//Pick a random T1 weapon to give
			int randomChoose = GetRandomInt(0, 3)
			switch(randomChoose)
			{
				case 0:
				{
					GiveClientItem(client, "smg")
				}
				case 1:
				{
					GiveClientItem(client, "smg_silenced")
				}
				case 2:
				{
					GiveClientItem(client, "pumpshotgun")
				}
				case 3:
				{
					GiveClientItem(client, "shotgun_chrome")
				}
			}
			
			//Give pills
			GiveClientItem(client, "pain_pills")
		}
		//T1 with medkit
		case 1:
		{
			//Pick a random T1 weapon to give
			int randomChoose = GetRandomInt(0, 3)
			switch(randomChoose)
			{
				case 0:
				{
					GiveClientItem(client, "smg")
				}
				case 1:
				{
					GiveClientItem(client, "smg_silenced")
				}
				case 2:
				{
					GiveClientItem(client, "pumpshotgun")
				}
				case 3:
				{
					GiveClientItem(client, "shotgun_chrome")
				}
			}
			
			//Give medkit
			GiveClientItem(client, "first_aid_kit")
		}
	}
}

/*
	BUY TIME
*/
//Lock saferoom doors
static LockSaferoom()
{
	g_bSaferoomLocked = true
	
	/*
	new saferoomDoor = -1
	while ((saferoomDoor = FindEntityByClassname(saferoomDoor, "prop_door_rotating_checkpoint")) != -1)
	{
		int iFlags = GetEntProp(saferoomDoor, Prop_Data, "m_spawnflags")
		int newFlags = iFlags + SPAWNFLAGS_IGNORE_USE
		PrintToChatAll("%i", iFlags)
		char[64] flagsString
		Format(flagsString, sizeof(flagsString), "", money)
		
		//SetVariantString("spawnflags 32768")
		//AcceptEntityInput(saferoomDoor, "AddOutput")
	}
	*/
}

//Unlock saferoom doors
static UnlockSaferoom()
{
	g_bSaferoomLocked = false
	
	/*
	new saferoomDoor = -1
	while ((saferoomDoor = FindEntityByClassname(saferoomDoor, "prop_door_rotating_checkpoint")) != -1)
	{
		int iFlags = GetEntProp(saferoomDoor, Prop_Data, "m_spawnflags")
		PrintToChatAll("%i", iFlags)
		//SetVariantString("spawnflags 8192")
		//AcceptEntityInput(saferoomDoor, "AddOutput")
	}
	*/
}

//Prevent survivors from leaving saferoom during buy time
public Action:L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if (g_bSaferoomLocked)
	{
		ReturnSurvivorToSaferoom(client, false)
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

//Teleport survivors back to the saferoom
static ReturnSurvivorToSaferoom(client, bool flagsSet = true)
{
	int warp_flags
	if (!flagsSet)
	{
		warp_flags = GetCommandFlags("warp_to_start_area")
		SetCommandFlags("warp_to_start_area", warp_flags & ~FCVAR_CHEAT)
	}

	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
	{
		L4D_ReviveSurvivor(client)
	}

	FakeClientCommand(client, "warp_to_start_area")

	if (!flagsSet)
	{
		SetCommandFlags("warp_to_start_area", warp_flags)
	}
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VELOCITY)
}

/*
	MONEY EVENTS
*/
//End of (half) round
public Action:L4D2_OnEndVersusModeRound(bool:countSurvivors)
{
	g_bRoundLive = false
	
	//Delay to allow for scores to be updated
	CreateTimer(2.0, RoundEndEvent_Delay)
}

//Delayed round end function to allow scores to update
static Action:RoundEndEvent_Delay(Handle timer)
{
	int isSecondHalf = InSecondHalfOfRound()
	int aliveSurvivors = GetUprightSurvivors()
	
	//Award amounts
	int i_awardRoundEnd = GetConVarInt(awardRoundEnd)
	int i_awardWonMap = GetConVarInt(awardWonMap)
	int i_awardLostMap = GetConVarInt(awardLostMap)
	int i_awardConsecutiveLoss = GetConVarInt(awardConsecutiveLoss)
	int i_awardExtraConsecutiveLoss = GetConVarInt(awardExtraConsecutiveLoss)
	int i_awardWipedSurvivors = GetConVarInt(awardWipedSurvivors)
	int i_awardHealthGreen = GetConVarInt(awardHealthGreen)
	int i_awardHealthYellow = GetConVarInt(awardHealthYellow)
	int i_awardHealthRed = GetConVarInt(awardHealthRed)
	int i_awardHealthTempOnly = GetConVarInt(awardHealthTempOnly)
	float f_awardDistanceMultiplier = GetConVarFloat(awardDistanceMultiplier)
	
	//Team scores
	int teamA = teamSurvivor
	int teamB = teamInfected
	int distancePointsTeamA = 0
	int distancePointsTeamB = 0
	int teamATotalAward = 0
	int teamBTotalAward = 0
	
	//Account for team flipping
	if (g_iAreTeamsFlipped == 1)
	{
		teamA = teamInfected
		teamB = teamSurvivor
	}
	
	//HALF ROUND END AWARDS
	if (teamA == teamSurvivor)
	{
		//Award distance points
		distancePointsTeamA = RoundToCeil(GetVersusProgressDistance(0) * f_awardDistanceMultiplier)
		AwardTeam(teamA, distancePointsTeamA, "Distance Points")
		teamATotalAward += distancePointsTeamA
		
		//Save points earned this map
		g_iPointsTeamA = L4D_GetTeamScore(1, false)
	}
	else if (teamB == teamSurvivor)
	{
		//Award distance points
		distancePointsTeamB = RoundToCeil(GetVersusProgressDistance(1) * f_awardDistanceMultiplier)
		AwardTeam(teamB, distancePointsTeamB, "Distance Points")
		teamBTotalAward += distancePointsTeamB
		
		//Save points earned this map
		g_iPointsTeamB = L4D_GetTeamScore(2, false)
	}
	
	//Survivor team wiped, award infected
	if (aliveSurvivors == 0)
	{
		if (teamA == teamInfected)
		{
			AwardTeam(teamA, i_awardWipedSurvivors, "Wiping Survivors")
			teamATotalAward += i_awardWipedSurvivors
		}
		else
		{
			AwardTeam(teamB, i_awardWipedSurvivors, "Wiping Survivors")
			teamBTotalAward += i_awardWipedSurvivors
		}
	}
	
	//MAP END AWARDS
	//Determine which team won the map overall, award win/loss bonuses to respective teams
	if (isSecondHalf == 1)
	{
		//Award base amount to both teams
		AwardTeam(teamA, i_awardRoundEnd, "Round End")
		teamATotalAward += i_awardRoundEnd
		AwardTeam(teamB, i_awardRoundEnd, "Round End")
		teamBTotalAward += i_awardRoundEnd
		
		//Team A won
		if (g_iPointsTeamA > g_iPointsTeamB)
		{
			//Win award
			AwardTeam(teamA, i_awardWonMap, "Winning Map")
			teamATotalAward += i_awardWonMap
			
			g_iTeamALostCounter = 0
			g_iTeamBLostCounter++
			
			//Loss award
			switch(g_iTeamBLostCounter)
			{
				//1st loss
				case 1:
				{
					AwardTeam(teamB, i_awardLostMap, "Losing Map")
					teamBTotalAward += i_awardLostMap
				}
				//2nd loss in a row
				case 2:
				{
					AwardTeam(teamB, i_awardConsecutiveLoss, "Consecutive Map Loss")
					teamBTotalAward += i_awardConsecutiveLoss
				}
				//3rd+ loss in a row
				default:
				{
					AwardTeam(teamB, i_awardExtraConsecutiveLoss, "Multiple Consecutive Map Loss")
					teamBTotalAward += i_awardExtraConsecutiveLoss
				}
			}
		}
		//Team B won
		else if (g_iPointsTeamA < g_iPointsTeamB)
		{
			//Win award
			AwardTeam(teamB, i_awardWonMap, "Winning Map")
			teamBTotalAward += i_awardWonMap
			
			g_iTeamBLostCounter = 0
			g_iTeamALostCounter++
			
			//Loss award
			switch(g_iTeamALostCounter)
			{
				//1st loss
				case 1:
				{
					AwardTeam(teamA, i_awardLostMap, "Losing Map")
					teamATotalAward += i_awardLostMap
				}
				//2nd loss in a row
				case 2:
				{
					AwardTeam(teamA, i_awardConsecutiveLoss, "Consecutive Map Loss")
					teamATotalAward += i_awardConsecutiveLoss
				}
				//3rd+ loss in a row
				default:
				{
					AwardTeam(teamA, i_awardExtraConsecutiveLoss, "Multiple Consecutive Map Loss")
					teamATotalAward += i_awardExtraConsecutiveLoss
				}
			}
		}
		//Tie
		else
		{
			AwardTeam(teamA, i_awardWonMap, "Tied Map")
			AwardTeam(teamB, i_awardWonMap, "Tied Map")
			teamATotalAward += i_awardWonMap
			teamBTotalAward += i_awardWonMap
			
			g_iTeamALostCounter = 0
			g_iTeamBLostCounter = 0
		}
	}
	
	//Print team earnings
	PrintEarningsTeam(teamA, teamATotalAward, 0, isSecondHalf, g_iTeamALostCounter)
	PrintEarningsTeam(teamB, teamBTotalAward, 0, isSecondHalf, g_iTeamBLostCounter)
	
	//Reset earnings tracker
	teamATotalAward = 0
	teamBTotalAward = 0
	
	//PERSONAL AWARDS
	//Go through all clients
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			int personalBonus = 0
			
			//Survivor awards
			if (GetClientTeam(i) == teamSurvivor)
			{
				if (aliveSurvivors > 0)
				{
					//Bonus based on health
					if (IsPlayerAlive(i) && !IsPlayerIncap(i) && !IsPlayerLedged(i))
					{
						int permaHealth = GetSurvivorPermanentHealth(i)
						//int tempHealth = GetSurvivorTemporaryHealth(i)
						
						if (permaHealth == 0)
						{
							GiveMoney(i, i_awardHealthTempOnly)
							personalBonus += i_awardHealthTempOnly
							EarningsToConsole(i, i_awardHealthTempOnly, "Only Temporary Health")
						}
						else if (permaHealth <= 24)
						{
							GiveMoney(i, i_awardHealthRed)
							personalBonus += i_awardHealthRed
							EarningsToConsole(i, i_awardHealthRed, "Red Health")
						}
						else if (permaHealth <= 39)
						{
							GiveMoney(i, i_awardHealthYellow)
							personalBonus += i_awardHealthYellow
							EarningsToConsole(i, i_awardHealthYellow, "Orange Health")
						}
						else
						{
							GiveMoney(i, i_awardHealthGreen)
							personalBonus += i_awardHealthGreen
							EarningsToConsole(i, i_awardHealthGreen, "Green Health")
						}
					}
				}
			}
			
			if (personalBonus > 0)
			{
				CPrintToChat(i, "{olive}[ECO]{default} You earned: {green}$%i{default} personal bonus money!", personalBonus)
			}
		}
	}
}

//Awards related to players dying
static Action:PlayerDeathEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bRoundLive)
	{
		new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"))
		new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"))
		char s_victimName[64]
		GetEventString(hEvent, "victimname", s_victimName, sizeof(s_victimName))
		
		char s_atkname[64]
		GetEventString(hEvent, "attackername", s_atkname, sizeof(s_atkname))
		if (GetConVarInt(economyDebug) == 1)
		{
			PrintToChatAll("DEBUG PLAYER DEATH: attacker id: %i, infected name: %s",attacker,s_atkname)
		}
		
		//Tank killed, award survivors
		if (StrEqual(s_victimName, "Tank", false))
		{
			//Award amounts
			int i_awardKilledTank = GetConVarInt(awardKilledTank)
			
			AwardTeam(teamSurvivor, i_awardKilledTank, "Killed Tank")
			PrintEarningsTeam(teamSurvivor, i_awardKilledTank, 1)
		}
		
		//Survivor killed, award the infected that killed them
		if (GetClientTeam(victim) == teamSurvivor)
		{
			//Award amounts
			int i_awardSurvivorKilled = GetConVarInt(awardSurvivorKilled)
			
			//For SOME reason the attacker is set to userid 0 with certain SI
			if (IsValidClient(attacker))
			{
				if (GetClientTeam(attacker) == teamInfected)
				{
					GiveMoney(attacker, i_awardSurvivorKilled)
					EarningsToConsole(attacker, i_awardSurvivorKilled, "Killed Survivor")
					CPrintToChat(attacker, "{olive}[ECO]{default} You earned: {green}$%i{default} for {red}killing a survivor{default}!", i_awardSurvivorKilled)
				}
			}
			//We don't know who killed the survivor, so award all infected equally
			//Need to change this because having a valid attacker that is a survivor will not give any reward at all
			else
			{
				int i_awardSurvivorKilled_Unknown = RoundToFloor(float(i_awardSurvivorKilled) / 4)
				AwardTeam(teamInfected, i_awardSurvivorKilled_Unknown, "Survivor Killed [Unknown Killer]")
				PrintEarningsTeam(teamInfected, i_awardSurvivorKilled_Unknown, 2)
			}
		}
	}
}

//Awards when a witch is killed
static WitchKilledEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bRoundLive)
	{
		new killer = GetClientOfUserId(GetEventInt(hEvent, "userid"))
		new fullCrown = GetEventBool(hEvent, "oneshot")
		
		//Only award 1-shot crowns
		if (fullCrown)
		{
			//Witch killed successfully, award the survivor that crowned her
			if (IsValidClient(killer))
			{
				if (GetClientTeam(killer) == teamSurvivor)
				{
					//Award amounts
					int i_awardKilledWitch = GetConVarInt(awardKilledWitch)
					
					GiveMoney(killer, i_awardKilledWitch)
					EarningsToConsole(killer, i_awardKilledWitch, "Crowned Witch")
					CPrintToChat(killer, "{olive}[ECO]{default} You earned: {green}$%i{default} for {blue}crowning the witch{default}!", i_awardKilledWitch)
				}
			}
		}
	}
}

//Awards when a player is incapped
static PlayerIncappedEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bRoundLive)
	{
		new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"))
		new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"))
		
		if (GetClientTeam(victim) == teamSurvivor)
		{
			if (IsValidClient(attacker))
			{
				if (GetClientTeam(attacker) == teamInfected)
				{
					//Award amounts
					int i_awardSurvivorIncapped = GetConVarInt(awardSurvivorIncapped)
					
					GiveMoney(attacker, i_awardSurvivorIncapped)
					EarningsToConsole(attacker, i_awardSurvivorIncapped, "Survivor Incapped")
					CPrintToChat(attacker, "{olive}[ECO]{default} You earned: {green}$%i{default} for {red}incapping a survivor{default}!", i_awardSurvivorIncapped)
				}
			}
		}
	}
}

//INFECTED ABILITY AWARDS
//SMOKER
//Pull started and dealt damage
static ChokeStartEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bRoundLive)
	{
		new infected = GetClientOfUserId(GetEventInt(hEvent, "userid"))
		
		if (IsValidClient(infected))
		{
			//Award amounts
			int i_awardAbilityLanded = GetConVarInt(awardAbilityLanded)
			
			GiveMoney(infected, i_awardAbilityLanded)
			EarningsToConsole(infected, i_awardAbilityLanded, "Survivor Capped")
			CPrintToChat(infected, "{olive}[ECO]{default} You earned: {green}$%i{default} for {red}capping a survivor{default}!", i_awardAbilityLanded)
			
			//Start timer for long cap duration, only supports 1 infected of this type
			g_iSmokerChokeID = infected
			CreateTimer(5.0, ChokeStartEvent_LongCap, infected)
		}
	}
}

//Pull stopped
static TongueReleaseEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new infected = GetClientOfUserId(GetEventInt(hEvent, "userid"))
	if (IsValidClient(infected))
	{
		g_iSmokerChokeID = 0
	}
}

//Pull timer
static Action:ChokeStartEvent_LongCap(Handle timer, infected)
{
	if (g_bRoundLive)
	{
		if (g_iSmokerChokeID != 0 && infected == g_iSmokerChokeID)
		{
			if (IsValidClient(infected))
			{
				//Award amounts
				int i_awardLongPinTime = GetConVarInt(awardLongPinTime)
				
				GiveMoney(infected, i_awardLongPinTime)
				EarningsToConsole(infected, i_awardLongPinTime, "Long Cap Time")
				CPrintToChat(infected, "{olive}[ECO]{default} You earned: {green}$%i{default} for {red}long cap duration{default}!", i_awardLongPinTime)
			}
		}
	}
}

//JOCKEY
//Ride started
static JockeyRideEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bRoundLive)
	{
		new infected = GetClientOfUserId(GetEventInt(hEvent, "userid"))
		
		if (IsValidClient(infected))
		{
			//Award amounts
			int i_awardAbilityLanded = GetConVarInt(awardAbilityLanded)
			
			GiveMoney(infected, i_awardAbilityLanded)
			EarningsToConsole(infected, i_awardAbilityLanded, "Survivor Capped")
			CPrintToChat(infected, "{olive}[ECO]{default} You earned: {green}$%i{default} for {red}capping a survivor{default}!", i_awardAbilityLanded)
			
			//Start timer for long cap duration, only supports 1 infected of this type
			g_iJockeyRideID = infected
			CreateTimer(5.0, JockeyRideEvent_LongCap, infected)
		}
	}
}

//Ride ended
static JockeyRideEndEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new infected = GetClientOfUserId(GetEventInt(hEvent, "userid"))
	if (IsValidClient(infected))
	{
		g_iJockeyRideID = 0
	}
}

//Ride timer
static Action:JockeyRideEvent_LongCap(Handle timer, infected)
{
	if (g_bRoundLive)
	{
		if (g_iJockeyRideID != 0 && infected == g_iJockeyRideID)
		{
			if (IsValidClient(infected))
			{
				//Award amounts
				int i_awardLongPinTime = GetConVarInt(awardLongPinTime)
				
				GiveMoney(infected, i_awardLongPinTime)
				EarningsToConsole(infected, i_awardLongPinTime, "Long Cap Time")
				CPrintToChat(infected, "{olive}[ECO]{default} You earned: {green}$%i{default} for {red}long cap duration{default}!", i_awardLongPinTime)
			}
		}
	}
}

//CHARGER
//Charger pummel start
static ChargerPummelStartEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bRoundLive)
	{
		new infected = GetClientOfUserId(GetEventInt(hEvent, "userid"))
		
		if (IsValidClient(infected))
		{
			//Award amounts
			int i_awardAbilityLanded = GetConVarInt(awardAbilityLanded)
			
			GiveMoney(infected, i_awardAbilityLanded)
			EarningsToConsole(infected, i_awardAbilityLanded, "Survivor Capped")
			CPrintToChat(infected, "{olive}[ECO]{default} You earned: {green}$%i{default} for {red}capping a survivor{default}!", i_awardAbilityLanded)
			
			//Start timer for long cap duration, only supports 1 infected of this type
			g_iChargerPummelID = infected
			CreateTimer(5.0, ChargerPummelEvent_LongCap, infected)
		}
	}
}

//Charger pummel end
static ChargerPummelEndEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new infected = GetClientOfUserId(GetEventInt(hEvent, "userid"))
	if (IsValidClient(infected))
	{
		g_iChargerPummelID = 0
	}
}

//Charger pummel timer
static Action:ChargerPummelEvent_LongCap(Handle timer, infected)
{
	if (g_bRoundLive)
	{
		if (g_iChargerPummelID != 0 && infected == g_iChargerPummelID)
		{
			if (IsValidClient(infected))
			{
				//Award amounts
				int i_awardLongPinTime = GetConVarInt(awardLongPinTime)
				
				GiveMoney(infected, i_awardLongPinTime)
				EarningsToConsole(infected, i_awardLongPinTime, "Long Cap Time")
				CPrintToChat(infected, "{olive}[ECO]{default} You earned: {green}$%i{default} for {red}long cap duration{default}!", i_awardLongPinTime)
			}
		}
	}
}

//HUNTER
//Hunter pounce landed
static HunterPounceEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bRoundLive)
	{
		new infected = GetClientOfUserId(GetEventInt(hEvent, "userid"))
		
		if (IsValidClient(infected))
		{
			//Award amounts
			int i_awardAbilityLanded = GetConVarInt(awardAbilityLanded)
			
			GiveMoney(infected, i_awardAbilityLanded)
			EarningsToConsole(infected, i_awardAbilityLanded, "Survivor Capped")
			CPrintToChat(infected, "{olive}[ECO]{default} You earned: {green}$%i{default} for {red}capping a survivor{default}!", i_awardAbilityLanded)
			
			//Start timer for long cap duration, only supports 1 infected of this type
			g_iHunterPounceID = infected
			CreateTimer(5.0, HunterPounceEvent_LongCap, infected)
			
			//High damage pounce - 600 distance seems to get 15 damage
			new distance = GetEventInt(hEvent, "distance")
			
			if (distance >= 600)
			{
				//Award amounts
				int i_awardSkilledAbilityLanded = GetConVarInt(awardSkilledAbilityLanded)
				
				GiveMoney(infected, i_awardSkilledAbilityLanded)
				EarningsToConsole(infected, i_awardSkilledAbilityLanded, "High Damage Pounce")
				CPrintToChat(infected, "{olive}[ECO]{default} You earned: {green}$%i{default} for landing a {red}high damage pounce{default}!", i_awardSkilledAbilityLanded)
			}
		}
	}
}

//Hunter pounce end
static HunterPounceStoppedEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new infected = GetClientOfUserId(GetEventInt(hEvent, "userid"))
	if (IsValidClient(infected))
	{
		g_iHunterPounceID = 0
	}
}

//Hunter pounce timer
static Action:HunterPounceEvent_LongCap(Handle timer, infected)
{
	if (g_bRoundLive)
	{
		if (g_iHunterPounceID != 0 && infected == g_iHunterPounceID)
		{
			if (IsValidClient(infected))
			{
				//Award amounts
				int i_awardLongPinTime = GetConVarInt(awardLongPinTime)
				
				GiveMoney(infected, i_awardLongPinTime)
				EarningsToConsole(infected, i_awardLongPinTime, "Long Cap Time")
				CPrintToChat(infected, "{olive}[ECO]{default} You earned: {green}$%i{default} for {red}long cap duration{default}!", i_awardLongPinTime)
			}
		}
	}
}

//Boomer
static BoomerLandedEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bRoundLive)
	{
		new infected = GetClientOfUserId(GetEventInt(hEvent, "attacker"))
		
		if (IsValidClient(infected))
		{
			//Award amounts
			int i_awardAbilityLanded = GetConVarInt(awardAbilityLanded)
			
			GiveMoney(infected, i_awardAbilityLanded)
			EarningsToConsole(infected, i_awardAbilityLanded, "Survivor Boomed")
			CPrintToChat(infected, "{olive}[ECO]{default} You earned: {green}$%i{default} for {red}booming a survivor{default}!", i_awardAbilityLanded)
		}
	}
}

//Skilled abilities: quad booms, quad charge, triple/quad punch (maybe double too), capping victim witch attacks, tri/quad cap landing

//Fall damage from infected
static PlayerFalldamageEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bRoundLive)
	{
		new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"))
		new causer = GetClientOfUserId(GetEventInt(hEvent, "causer"))
		new damage = GetEventInt(hEvent, "damage")
		
		if (damage > 40)
		{
			if (GetClientTeam(victim) == teamSurvivor)
			{
				if (IsValidClient(causer))
				{
					if (GetClientTeam(causer) == teamInfected)
					{
						//Award amounts
						int i_awardSkilledAbilityLanded = GetConVarInt(awardSkilledAbilityLanded)
						
						GiveMoney(causer, i_awardSkilledAbilityLanded)
						EarningsToConsole(causer, i_awardSkilledAbilityLanded, "High Fall Damage")
						CPrintToChat(causer, "{olive}[ECO]{default} You earned: {green}$%i{default} for {red}inflicting fall damage{default}!", i_awardSkilledAbilityLanded)
					}
				}
			}
		}
	}
}

//Ledge hangs from infected
static PlayerLedgeGrabEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bRoundLive)
	{
		new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"))
		new causer = GetClientOfUserId(GetEventInt(hEvent, "causer"))
		
		if (GetClientTeam(victim) == teamSurvivor)
		{
			if (IsValidClient(causer))
			{
				if (GetClientTeam(causer) == teamInfected)
				{
					//Award amounts
					int i_awardSkilledAbilityLanded = GetConVarInt(awardSkilledAbilityLanded)
					
					GiveMoney(causer, i_awardSkilledAbilityLanded)
					EarningsToConsole(causer, i_awardSkilledAbilityLanded, "Ledge Hang")
					CPrintToChat(causer, "{olive}[ECO]{default} You earned: {green}$%i{default} for {red}ledge hanging a survivor{default}!", i_awardSkilledAbilityLanded)
				}
			}
		}
	}
}

//Multi-charges
static ChargerImpactEvent(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if (g_bRoundLive)
	{
		new infected = GetClientOfUserId(GetEventInt(hEvent, "userid"))
		
		if (IsValidClient(infected))
		{
			if (GetClientTeam(infected) == teamInfected)
			{
				//Award amounts - Half the standard amount per survivor hit
				int i_awardSkilledAbilityLanded = GetConVarInt(awardSkilledAbilityLanded)
				int i_awardSkilledAbilityLanded_MultiCharge = RoundToFloor(float(i_awardSkilledAbilityLanded) / 2)
				
				GiveMoney(infected, i_awardSkilledAbilityLanded_MultiCharge)
				EarningsToConsole(infected, i_awardSkilledAbilityLanded_MultiCharge, "Ledge Hang")
				CPrintToChat(infected, "{olive}[ECO]{default} You earned: {green}$%i{default} for landing a {red}multi-charge{default}!", i_awardSkilledAbilityLanded_MultiCharge)
			}
		}
	}
}

/*
	MONEY FUNCTIONS
*/
//Returns the current money a client has
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

//Award money to an entire team
static AwardTeam(team, int amount, const char[] reason = "[Unspecified]")
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (GetClientTeam(i) == team)
			{
				GiveMoney(i, amount)
				EarningsToConsole(i, amount, reason)
			}
		}
	}
}

//Print total earnings for team
static PrintEarningsTeam(team, int amount, int reason = 0, int isSecondHalf = 0, int lossCount = 0)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (GetClientTeam(i) == team)
			{
				switch(reason)
				{
					//Generic round end
					case 0:
					{
						if (isSecondHalf == 1)
						{
							if (lossCount == 0)
							{
								CPrintToChat(i, "{olive}[ECO]{default} Your team earned: {green}$%i{default} for {blue}winning{default} this round!", amount)
							}
							else
							{
								CPrintToChat(i, "{olive}[ECO]{default} Your team earned: {green}$%i{default} for {red}losing{default} this round!", amount)
							}
						}
						else
						{
							CPrintToChat(i, "{olive}[ECO]{default} Your team earned: {green}$%i{default} for this round!", amount)
						}
					}
					//Killed tank
					case 1:
					{
						CPrintToChat(i, "{olive}[ECO]{default} Your team earned: {green}$%i{default} for {blue}killing the tank{default}!", amount)
					}
					//Survivor died (unknown killer/self inflicted)
					case 2:
					{
						CPrintToChat(i, "{olive}[ECO]{default} Your team earned: {green}$%i{default} for {red}a survivor dying{default}!", amount)
					}
				}
			}
		}
	}
}

//Print to console when money is earned
static EarningsToConsole(client, int amount, const char[] reason = "[Unspecified]")
{
	PrintToConsole(client, "\x03Earned: $%i for: %s", amount, reason)
}

//Gives money to a client
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

//Spends a client's money
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

/*
	BUY MENUS
*/
//Draw buy menu footer
static BuyMenuDrawMoney(client, param2)
{
	char buffer[32]
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
	if (g_bCanBuy)
	{
		if (GetClientTeam(client) == teamSurvivor)
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
			InvalidBuyMessage(client, 2)
		}
	}
	else
	{
		InvalidBuyMessage(client, 0)
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
			else if (StrEqual(selection, CHOICE_UPGRADES))
			{
			}
			
			PrintToServer("Client %d selected %s", param1, selection)
		}

		case MenuAction_Cancel:
		{
			if (g_bCanBuy && param2 == -6)
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
	if (g_bCanBuy)
	{
		if (GetClientTeam(client) == teamSurvivor)
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
		else
		{
			InvalidBuyMessage(client, 2)
		}
	}
	else
	{
		InvalidBuyMessage(client, 0)
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
			if (g_bCanBuy && param2 == -6)
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
	if (g_bCanBuy)
	{
		if (GetClientTeam(client) == teamSurvivor)
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
		else
		{
			InvalidBuyMessage(client, 2)
		}
	}
	else
	{
		InvalidBuyMessage(client, 0)
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
			if (g_bCanBuy && param2 == -6)
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
	if (g_bCanBuy)
	{
		if (GetClientTeam(client) == teamSurvivor)
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
		else
		{
			InvalidBuyMessage(client, 2)
		}
	}
	else
	{
		InvalidBuyMessage(client, 0)
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
			if (g_bCanBuy && param2 == -6)
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
	if (g_bCanBuy)
	{
		if (GetClientTeam(client) == teamSurvivor)
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
		else
		{
			InvalidBuyMessage(client, 2)
		}
	}
	else
	{
		InvalidBuyMessage(client, 0)
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
			if (g_bCanBuy && param2 == -6)
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
	if (g_bCanBuy)
	{
		if (GetClientTeam(client) == teamSurvivor)
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
		else
		{
			InvalidBuyMessage(client, 2)
		}
	}
	else
	{
		InvalidBuyMessage(client, 0)
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
			if (g_bCanBuy && param2 == -6)
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
	if (g_bCanBuy)
	{
		if (GetClientTeam(client) == teamSurvivor)
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
			
			//Add options to menu (if valid spawns for this map)
			for(new i = 0; i < g_iValidMeleeCount; i++)
			{
				if (StrEqual(g_sValidMelees[i], "baseball_bat", false) == true)
				{
					menu.AddItem(BUY_BASEBALLBAT, option1)
				}
				else if (StrEqual(g_sValidMelees[i], "cricket_bat", false) == true)
				{
					menu.AddItem(BUY_CRICKETBAT, option2)
				}
				else if (StrEqual(g_sValidMelees[i], "electric_guitar", false) == true)
				{
					menu.AddItem(BUY_GUITAR, option3)
				}
				else if (StrEqual(g_sValidMelees[i], "frying_pan", false) == true)
				{
					menu.AddItem(BUY_FRYINGPAN, option4)
				}
				else if (StrEqual(g_sValidMelees[i], "golfclub", false) == true)
				{
					menu.AddItem(BUY_GOLFCLUB, option5)
				}
				else if (StrEqual(g_sValidMelees[i], "shovel", false) == true)
				{
					menu.AddItem(BUY_SHOVEL, option6)
				}
				else if (StrEqual(g_sValidMelees[i], "tonfa", false) == true)
				{
					menu.AddItem(BUY_TONFA, option7)
				}
			}
			
			menu.ExitButton = true
			menu.ExitBackButton = true
			menu.Display(client, MENU_TIME_FOREVER)
		}
		else
		{
			InvalidBuyMessage(client, 2)
		}
	}
	else
	{
		InvalidBuyMessage(client, 0)
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
			if (g_bCanBuy && param2 == -6)
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
	if (g_bCanBuy)
	{
		if (GetClientTeam(client) == teamSurvivor)
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
					//Add options to menu (if valid spawns for this map)
			for(new i = 0; i < g_iValidMeleeCount; i++)
			{
				if (StrEqual(g_sValidMelees[i], "crowbar", false) == true)
				{
					menu.AddItem(BUY_CROWBAR, option1)
				}
				else if (StrEqual(g_sValidMelees[i], "fireaxe", false) == true)
				{
					menu.AddItem(BUY_FIRAXE, option2)
				}
				else if (StrEqual(g_sValidMelees[i], "katana", false) == true)
				{
					menu.AddItem(BUY_KATANA, option3)
				}
				else if (StrEqual(g_sValidMelees[i], "knife", false) == true)
				{
					menu.AddItem(BUY_KNIFE, option4)
				}
				else if (StrEqual(g_sValidMelees[i], "machete", false) == true)
				{
					menu.AddItem(BUY_MACHETE, option5)
				}
				else if (StrEqual(g_sValidMelees[i], "pitchfork", false) == true)
				{
					menu.AddItem(BUY_PITCHFORK, option6)
				}
			}
			
			menu.ExitButton = true
			menu.ExitBackButton = true
			menu.Display(client, MENU_TIME_FOREVER)
		}
		else
		{
			InvalidBuyMessage(client, 2)
		}
	}
	else
	{
		InvalidBuyMessage(client, 0)
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
			if (g_bCanBuy && param2 == -6)
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
	if (g_bCanBuy)
	{
		if (GetClientTeam(client) == teamSurvivor)
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
		else
		{
			InvalidBuyMessage(client, 2)
		}
	}
	else
	{
		InvalidBuyMessage(client, 0)
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
			if (g_bCanBuy && param2 == -6)
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
	if (g_bCanBuy)
	{
		if (GetClientTeam(client) == teamSurvivor)
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
		else
		{
			InvalidBuyMessage(client, 2)
		}
	}
	else
	{
		InvalidBuyMessage(client, 0)
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
			if (g_bCanBuy && param2 == -6)
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
//Process buy requests and spend money
static MenuBuyItem(client, const char[] item, int itemType = 0)
{
	if (g_bCanBuy)
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
				BuyConfirmationPrint(client, itemPrice, item)
			}
			else
			{
				InvalidBuyMessage(client, 1)
			}
		}
	}
	else
	{
		InvalidBuyMessage(client, 0)
	}
}

//Give requested item to client
static GiveClientItem(client, const char[] item, int itemType = 0)
{
	new flagsGive = GetCommandFlags("give")
	//new flagsUpgradeAdd = GetCommandFlags("upgrade_add")
	SetCommandFlags("give", flagsGive & ~FCVAR_CHEAT)
	//SetCommandFlags("upgrade_add", flagsGive & ~FCVAR_CHEAT)
	
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
		/*case 2:
		{
			Format(buffer, sizeof(buffer), "upgrade_add %s", item)
		}*/
	}
	
	FakeClientCommand(client, buffer)
	SetCommandFlags("give", flagsGive|FCVAR_CHEAT)
	//SetCommandFlags("upgrade_add", flagsUpgradeAdd|FCVAR_CHEAT)
}

//Retrieve price of given item
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

//Print messages when attempting an invalid buy request
static InvalidBuyMessage(client, int reason)
{
	switch(reason)
	{
		//Cannot buy
		case 0:
		{
			CPrintToChat(client, "{olive}[ECO]{default} You cannot buy at this time.")
		}
		//Not enough money
		case 1:
		{
			CPrintToChat(client, "{olive}[ECO]{default} You cannot afford this item.")
		}
		//Not on survivor team
		case 2:
		{
			CPrintToChat(client, "{olive}[ECO]{default} You must be a survivor to buy items.")
		}
	}
}

static BuyConfirmationPrint(client, amount, const char[] item)
{
	CPrintToChat(client, "{olive}[ECO]{default} Bought: {blue}%s{default} for: {green}$%i.", item, amount)
}

/*
	ADMIN COMMANDS
*/
//Gives money to a player
stock Action:GiveMoney_Cmd(int client, int args)
{    
	//Get arguments: Player name, money amount
	char arg1[32]
	char arg2[32]
	GetCmdArg(1, arg1, sizeof(arg1))
	GetCmdArg(2, arg2, sizeof(arg2))
	
	int target = FindTarget(client, arg1)
	
	//Inavlid player
	if (target == -1 || !IsClientInGame(client) || IsClientSourceTV(client) || IsFakeClient(client))
	{
		CPrintToChat(client, "{olive}[ECO]{default} Invalid target.")
		return Plugin_Handled;
	}
	
	//Give money to player
	int amount = StringToInt(arg2)
	GiveMoney(target, amount)
	
	//Announce to server
	char name[MAX_NAME_LENGTH]
	GetClientName(target, name, sizeof(name))
	CPrintToChatAll("{olive}[ECO]{default} {blue}%s{default} was given {green}$%i{default}.", name, amount)
	
	return Plugin_Handled;
}

//Removes money from a player
stock Action:RemoveMoney_Cmd(int client, int args)
{    
	//Get arguments: Player name, money amount
	char arg1[32]
	char arg2[32]
	GetCmdArg(1, arg1, sizeof(arg1))
	GetCmdArg(2, arg2, sizeof(arg2))
	
	int target = FindTarget(client, arg1)
	
	//Inavlid player
	if (target == -1 || !IsClientInGame(client) || IsClientSourceTV(client) || IsFakeClient(client))
	{
		CPrintToChat(client, "{olive}[ECO]{default} Invalid target.")
		return Plugin_Handled;
	}
	
	//Give money to player
	int amount = StringToInt(arg2)
	SpendMoney(target, amount)
	
	//Announce to server
	char name[MAX_NAME_LENGTH]
	GetClientName(target, name, sizeof(name))
	CPrintToChatAll("{olive}[ECO]{default} {green}$%i{default} was removed from {blue}%s{default}.", name, amount)
	
	return Plugin_Handled;
}

//Extends buy time by 30 seconds
stock Action:ExtendBuy_Cmd(int client, int args)
{    
	//Extend buy time, if it has ended
	if (g_bCanBuy == false)
	{
		g_bCanBuy = true
		CreateTimer(30.0, BuyTimeExtendEnd)
		
		//Announce to server
		CPrintToChatAll("{olive}[ECO]{default} {blue}!buy{default} time has been extended by {green}30 seconds{default}!")
	}
	else
	{
		CPrintToChatAll("{olive}[ECO]{default} {blue}!buy{default} time has not ended yet.")
	}
	
	return Plugin_Handled;
}

//Disable buy time after an extension
static Action:BuyTimeExtendEnd(Handle timer)
{
	g_bCanBuy = false
	CPrintToChatAll("{olive}[ECO]{default} Extended {blue}!buy{default} time has ended!")
}

/*
	STOCKS
*/
//Test if client is valid
stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && !IsFakeClient(client));
}

stock bool IsValidClientOrBot(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client));
}

//Test if client is a survivor bot
stock bool IsSurvivorBot(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && IsFakeClient(client) && GetClientTeam(client) == teamSurvivor);
}

//Return index of client within money array
stock int GetClientIndex(int client)
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

//Return if round is first or second half
stock InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound");
}

//Return if teams are flipped
stock AreTeamsFlipped()
{
	return GameRules_GetProp("m_bAreTeamsFlipped");
}

//How many survivors are currently alive
stock GetUprightSurvivors()
{
	new aliveCount;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (GetClientTeam(i) == teamSurvivor)
			{
				if (IsPlayerAlive(i) && !IsPlayerIncap(i) && !IsPlayerLedged(i))
				{
					aliveCount++
				}
			}
		}
	}
	return aliveCount;
}

//Is client incapped
stock bool:IsPlayerIncap(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

//Is client ledge hanging
stock bool:IsPlayerLedged(client)
{
	return bool:(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") | GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

//Returns temporary health value of client
stock GetSurvivorTemporaryHealth(client)
{
	new temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
	return (temphp > 0 ? temphp : 0);
}

//Returns permanent health value of client
stock GetSurvivorPermanentHealth(client)
{
	// Survivors always have minimum 1 permanent hp
	// so that they don't faint in place just like that when all temp hp run out
	// We'll use a workaround for the sake of fair calculations
	// Edit 2: "Incapped HP" are stored in m_iHealth too; we heard you like workarounds, dawg, so we've added a workaround in a workaround
	return GetEntProp(client, Prop_Send, "m_currentReviveCount") > 0 ? 0 : (GetEntProp(client, Prop_Send, "m_iHealth") > 0 ? GetEntProp(client, Prop_Send, "m_iHealth") : 0);
}

//Return how many distance points survivors have earned currently
stock int GetVersusProgressDistance(int teamIndex)
{
	int distance = 0
	for (int i = 0; i < 4; ++i)
	{
		distance += GameRules_GetProp("m_iVersusDistancePerSurvivor", _, i + (4 * teamIndex))
	}
	return distance;
}


/*
NOTES:
Ideas:
money transfer system - send money in fixed amounts to a teammate e.g. $500, $1000
detect campaign length, option to have multiplier for shorter/longer than normal campaigns (maybe bonus applied to start money) - dont think this is really needed
actually if you heal right before end of round u would get extra money - need to fix that - award extra money for having a medkit, but increase medkit price to compensate? or make the hp calculation count unused medkits
using a medkit could forfeit the health bonus completely, or holding one gives you green hp bonus (though you could heal someone else with low hp instead for more money)
fix saferoom door locking to work without issues (doors that use specific spawn flags, also messes up hitbox for some reason)


Todo:
account for round resets (revert money/items back to what it was at start of round), store amount of money at start of round
play sound when round goes live
add confirmation check if you already have an item in a slot you try to buy for
wait for all players to load in before starting the round
extra starting money on 2/3 map campaigns
plugin to make ammo density always at a minimum level/control density
cvars to control fall damage amount for award
cvars to control dp damage amount for award
cvar to control long cap duration for award
optimization pass
	-pass item price handle through buy function directly instead of calling getitemprice
	-initiating variables
	-overuse of loops
	-isvalidclient optimizations
*/
