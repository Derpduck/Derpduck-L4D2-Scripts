#include <sourcemod>
//#include <sdktools>
#include <sdkhooks>
#include <colors>

public Plugin:myinfo = 
{
	name = "Witch Panic",
	author = "Derpduck",
	description = "The witch no longer attacks the survivors, startling the witch without crowning her will cause a horde to spawn",
	version = "0.1",
	url = "https://github.com/"
}

static i_Witch

public OnPluginStart()
{
	HookEvent("witch_spawn", Event_WitchSpawned, EventHookMode_Post)
	HookEvent("witch_killed", Event_WitchKilled, EventHookMode_Post)
	HookEvent("witch_harasser_set", Event_WitchHarasserSet, EventHookMode_Post)
	//HookEvent("player_entered_checkpoint", Event_PlayerEnteredCheckpoint, EventHookMode_Post)
}

//z_witch_allow_change_victim
//z_witch_burn_time


public Action:Event_WitchSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	CPrintToChatAll("Witch Spawned")
	
	/*
	Hook witch_harasser_set
	*/
	
	
	char rage[100]
	i_Witch = GetEventInt(event, "witchid")
	
	if (IsValidEdict(i_Witch))
	{
		FloatToString(GetEntPropFloat(i_Witch, Prop_Send, "m_rage"),rage,100)
		CPrintToChatAll("rage %s",rage)
	}
	
	//new witch = GetEventInt(event, "witchid");
	//CPrintToChatAll(witchid)
	//new witchclass = GetEntProp(witch, Prop_Send, "m_zombieClass")
	//CPrintToChatAll(GetEntPropFloat(IntToFloat(GetEventInt(event, "witchid")), Prop_Send, "m_zombieClass"))
	//i_Sequence = GetEntProp(i_Witch, Prop_Data, "m_nSequence")
	//f_Rage = GetEntPropFloat(i_Witch, Prop_Send, "m_rage")
	//SetEntProp(i_Witch, Prop_Send, "m_mobRush", 1)
}

public Action:Event_WitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	CPrintToChatAll("Witch Killed")
	
	new witchid = GetEventInt(event, "witchid")
	CPrintToChatAll("witchid %i",witchid)
	
	char rage[100]
	
	FloatToString(GetEntPropFloat(witchid, Prop_Send, "m_rage"),rage,100)
	CPrintToChatAll("rage %s",rage)
	
	/*
	Unhook all
	*/
}

public Action:Event_WitchHarasserSet(Handle:event, const String:name[], bool:dontBroadcast)
{
	//return Plugin_Handled;
	CPrintToChatAll("Witch Aggro")
	
	/*
	Check how witch was aggro'd - was it by valid survivor target
	Force witch to run away (remove target?)
	Spawn horde, play a sound - witch scream too
	Print to chat	
	Unhook all
	*/
	new witchid = GetEventInt(event, "witchid")
	//SetEventFloat(event, "userid", witchid)
	new target = GetEventFloat(event, "userid")
	SetEventFloat(event, "userid", target)
	new bool:isFirstAggro = GetEventBool(event, "first")
	
	CPrintToChatAll("target %f",target)
	CPrintToChatAll("isFirstAggro %b",isFirstAggro)
	CPrintToChatAll("witchid %i",witchid)
	char rage[100]
	
	FloatToString(GetEntPropFloat(witchid, Prop_Send, "m_rage"),rage,100)
	CPrintToChatAll("rage %s",rage)
	
	
	//FireEvent("player_entered_checkpoint",bool:dontBroadcast)
	
	SetEntProp(witchid, Prop_Send, "m_nSequence", 8)
	
	//new sequence = GetEntProp(entity, Prop_Send, "m_nSequence")
	
}

public OnGameFrame()
{
	if (IsValidEdict(i_Witch))
	{
		//new sequence = GetEntProp(i_Witch, Prop_Send, "m_nSequence")
		//new sequence2 = GetEntProp(i_Witch, Prop_Send, "m_MoveType")
		//new flags = GetEntProp(i_Witch, Prop_Send, "m_nFallenFlags")
		//new rages = GetEntPropFloat(i_Witch, Prop_Send, "m_rage")
		//SetEntPropFloat(i_Witch, Prop_Send, "m_rage", 0)
		//CPrintToChatAll("%i",sequence2)
		//CPrintToChatAll("flags %i",flags)
		//CPrintToChatAll("floats %f",GetEntPropFloat(i_Witch, Prop_Send, "m_flCycle"))
		
		//if (sequence == 6)
		//{
			//SetEntProp(i_Witch, Prop_Send, "m_nSequence", 8)
		//}
		
	}
}


/*stock bool:IsWitch(entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		decl String: classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "witch", false))
			return true;
	}
	return false;
}*/
