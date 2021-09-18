#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <colors>

public Plugin:myinfo = 
{
	name = "Measure Jumps",
	author = "Derpduck",
	description = "Measure jump heights",
	version = "1",
	url = "https://github.com/Derpduck/Derpduck-L4D2-Scripts"
}

float timeStart = 0.0
float timeApex = 0.0
float timeEnd = 0.0
float lastVel = 0.0
float posStart = 0.0

#define DMG_FALL (1 << 5)

ConVar g_hCvarGravity

public OnPluginStart()
{
	HookEvent("player_jump", EventHook:JumpStartEvent, EventHookMode_Post)
	HookEvent("player_jump_apex", EventHook:JumpApexEvent, EventHookMode_Post)
	HookEvent("player_falldamage", EventHook:FallEvent, EventHookMode_Pre)
	//HookEvent("player_hurt", EventHook:HurtEvent, EventHookMode_Pre)
	
	for(new cl=1; cl <= MaxClients; cl++)
	{
		if(IsClientInGame(cl))
		{
			//SDKHook(cl, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public Action:JumpStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"))
	float time = GetTickedTime()
	timeStart = time
	float vOrigin[3]
	GetEntPropVector(userid, Prop_Send, "m_vecOrigin", vOrigin)
	posStart = vOrigin[2]
}

public Action:JumpApexEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"))
	float time = GetTickedTime()
	timeApex = time
	float vOrigin[3]
	GetEntPropVector(userid, Prop_Send, "m_vecOrigin", vOrigin)
	float timeDiff = timeApex - timeStart
	float posDiff = vOrigin[2] - posStart
	PrintToChatAll("T: %i / G: %i [APEX] J-HEIGHT: %f / TIME: %f", GetTickrate(), GetGravity(), posDiff, timeDiff)
}

public OnGameFrame()
{
	float time = GetTickedTime()
	float vOrigin[3]
	GetEntPropVector(1, Prop_Send, "m_vecOrigin", vOrigin)
	float vVel[3]
	GetEntPropVector(1, Prop_Data, "m_vecAbsVelocity", vVel)
	if (vVel[2]!=0)
	{
		lastVel = vVel[2]
		timeEnd = time
	}
	else
	{
		if (timeStart!=0)
		{
			float timeDiff = timeEnd - timeStart
			PrintToChatAll("T: %i / G: %i [LAND] Z-VEL: %f / TIME: %f", GetTickrate(), GetGravity(), lastVel, timeDiff)
			timeStart = 0.0
		}
	}
}

public Action:FallEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"))
	float damage = GetEventFloat(event, "damage")
	float vVel[3]
	GetEntPropVector(userid, Prop_Data, "m_vecAbsVelocity", vVel)
	PrintToChatAll("T: %i / G: %i [FALL] DMG: %f / Z-VEL: %f", GetTickrate(), GetGravity(), damage, vVel[2])
	SetEventFloat(event, "damage", 1.0)
}

/*public Action:HurtEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"))
	float damage = GetEventFloat(event, "dmg_health")
	int dmgtype = GetEventInt(event, "type")
	PrintToChatAll("%i", dmgtype)
	float vVel[3]
	GetEntPropVector(userid, Prop_Data, "m_vecAbsVelocity", vVel)
	if (dmgtype & DMG_FALL)
	{
		SetEventFloat(event, "dmg_health", 1.0)
	}
	//PrintToChatAll("T: %i / G: %i [FALL] DMG: %f / Z-VEL: %f", GetTickrate(), GetGravity(), damage, vVel[2])
	//SetEventFloat(event, "damage", 1.0)
}*/

public OnClientPutInServer(client)
{
    //SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

/*public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (damagetype & DMG_FALL)
	{
		float newDamage = 2.0
		PrintToChatAll("Old: %f / New: %f", damage, newDamage)
		damage = newDamage
		return Plugin_Changed
	}
	return Plugin_Continue
}*/

public int GetTickrate()
{
	int tickrate = RoundFloat(1.0 / GetTickInterval())
	return tickrate
}

public int GetGravity()
{
	g_hCvarGravity = FindConVar("sv_gravity");
	int gravity = g_hCvarGravity.IntValue
	return gravity
}