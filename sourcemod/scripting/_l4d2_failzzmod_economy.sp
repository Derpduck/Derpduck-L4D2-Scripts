#include <sourcemod>
//#include <sdktools>
#include <sdkhooks>
#include <colors>

public Plugin:myinfo = 
{
	name = "FailzzMod Economy",
	author = "Derpduck",
	description = "Prototype for FailzzMod economy system",
	version = "0.1",
	url = "https://github.com/Derpduck/Derpduck-L4D2-Scripts"
}

ConVar startingMoney;

//AWARD CONDITIONS
ConVar conAllowPerRoundAwards, conPersonalSurvivorIncap, conPersonalAbility, conPersonalHealth, conPersonalDistance, conPersonalPenaltyIncap, conPersonalPenaltyDeath;

//AWARD AMOUNTS
ConVar awardRoundEnd, awardMapEnd, awardWonMap, awardLostMap, awardConsecutiveLoss, awardExtraConsecutiveLoss, awardKilledTank, awardKilledWitch, awardWipedSurvivors, awardSurvivorIncapped, awardLandedAbility, awardHealthGreen, awardHealthYellow, awardHealthRed, awardHealthTempOnly, awardDistanceBonus;

//PENALTY AMOUNTS
ConVar penaltyIncapped, penaltyDeath;

//ITEM PRICES
ConVar priceShotgunPump, priceShotgunChrome, priceUziStandard, priceUziSilenced, priceUziMP5, priceRifleM16, priceRifleAK47, priceRifleDesert, priceRifleSG552, priceShotgunAuto, priceShotgunSpas, priceSniperHunting, priceSniperMilitary, priceSniperScout, priceSniperAWP;
ConVar priceM60, priceGrenadeLauncher, priceChainsaw;
ConVar pricePistol, priceMagnum, priceMeleeBlunt, priceMeleeSharp;
ConVar priceMolotov, pricePipebomb, priceBilebomb;
ConVar pricePainPills, priceAdrenaline, priceMedkit, priceDefibrillator;
ConVar priceLaser, priceFireAmmo, priceExplosiveAmmo;
ConVar priceGnome, priceCola;


public OnPluginStart()
{
	//CreateConVar(const char[] name, const char[] defaultValue, const char[] description, int flags, bool hasMin, float min, bool hasMax, float max)
	
	startingMoney				= CreateConVar("starting_money",				"0",	"Amount of money players start out with")
	
	//AWARD CONDITIONS
	conAllowPerRoundAwards		= CreateConVar("condition_allow_per_round_awards",	"0",	"Can applicable awards be given at the end of a round (0 = Only Map End, 1 = Each Round [where applicable])")
	conPersonalSurvivorIncap	= CreateConVar("condition_personal_survivor_incap",	"0",	"Is survivor incapped bonus money awarded to the entire team or individually (0 = Entire Team, 1 = Individually)")
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
	awardSurvivorIncapped		= CreateConVar("award_survivor_incapped",		"10",	"Money awarded each time an infected ability lands (0 = No Award)")
	awardHealthGreen			= CreateConVar("award_health_green",			"100",	"Money awarded for each survivor that completes the map with green health (0 = No Award)")
	awardHealthYellow			= CreateConVar("award_health_yellow",			"60",	"Money awarded for each survivor that completes the map with yellow health (0 = No Award)")
	awardHealthRed				= CreateConVar("award_health_red",				"30",	"Money awarded for each survivor that completes the map with red health (0 = No Award)")
	awardHealthTempOnly			= CreateConVar("award_health_temp_only",		"20",	"Money awarded for each survivor that completes the map with only temporary health (0 = No Award)")
	awardDistanceBonus			= CreateConVar("award_distance_bonus",			"1",	"Money awarded for distance points gained by survivors (multiplier of distance value) (0 = No Award)")
	
	//PENALTY AMOUNTS
	penaltyIncapped				= CreateConVar("penalty_incapped",				"0",	"Money lost for being incapped (0 = No Penalty)")
	penaltyDeath				= CreateConVar("penalty_death",					"0",	"Money lost for being killed as a survivor (0 = No Penalty)")
	
	//ITEM PRICES
	//T1s
	priceShotgunPump			= CreateConVar("price_shotgun_pump",			"500",	"Cost of weapon: pumpshotgun")
	priceShotgunChrome			= CreateConVar("price_shotgun_chrome",			"500",	"Cost of weapon: shotgun_chrome")
	priceUziStandard			= CreateConVar("price_uzi_standard",			"500",	"Cost of weapon: smg")
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
	priceMeleeSharp				= CreateConVar("price_melee_sharp",				"500",	"Cost of weapon(s): crowbar, fireaxe, katana, knife, machete, pitchfork")
	//Throwables
	priceMolotov				= CreateConVar("price_molotov",					"700",	"Cost of weapon: molotov")
	pricePipebomb				= CreateConVar("price_pipe_bomb",				"700",	"Cost of weapon: pipe_bomb")
	priceBilebomb				= CreateConVar("price_bile_bomb",				"800",	"Cost of weapon: vomitjar")
	//Healing Items
	pricePainPills				= CreateConVar("price_pain_pills",				"400",	"Cost of weapon: pain_pills")
	priceAdrenaline				= CreateConVar("price_adrenaline",				"600",	"Cost of weapon: adrenaline")
	priceMedkit					= CreateConVar("price_medkit",					"1200",	"Cost of weapon: first_aid_kit")
	priceDefibrillator			= CreateConVar("price_defibrillator",			"3000",	"Cost of weapon: defibrillator")
	//Upgrades
	priceLaser					= CreateConVar("price_laser",					"1500",	"Cost of upgrade: laser sights")
	priceFireAmmo				= CreateConVar("price_fire_ammo",				"2000",	"Cost of upgrade: upgradepack_incendiary")
	priceExplosiveAmmo			= CreateConVar("price_explosive_ammo",			"5000",	"Cost of upgrade: upgradepack_explosive")
	//Fun
	priceGnome					= CreateConVar("price_gnome",					"50",	"Cost of item: gnome")
	priceCola					= CreateConVar("price_cola",					"50",	"Cost of item: cola_bottles")
}

/*
NOTES:


buy menu:
T1s
T2s
T3s
Secondaries
Throwables
Healing Items
Upgrades (could be permanent, e.g. buying upgrade gives permanent fire ammo, but with some kind of nerf like reducing damage dealt, increasing reload etc)
Fun (Gnome, Cola)


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


Todo:
steam id is assigned default starting money on joining, track money between map changes
display amount of money everyone on your team has


Other Notes:
health bonuses will ignore any healing items in the player's inventory
penalties/rewards for incaps vs deaths could have issues, e.g. cases where a player dies instantly without incapping, or incaps then instantly dies from hurt trigger, and timing for when players die if a wipe happens (e.g. before or after round is "over")


not sure how to handle abuses of the system:
player joins and buys a bunch of stuff for their team then leaves
player switches teams between rounds
what to do when someone leaves (if they dont come back money is wasted and team is at a disadvantage)


*/