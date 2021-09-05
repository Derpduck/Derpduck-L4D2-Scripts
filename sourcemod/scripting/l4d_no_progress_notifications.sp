#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "No Progress Notifications",
	author = "Derpduck",
	description = "Block notifications for survivor progress through a map",
	version = "1",
	url = "https://github.com/Derpduck/Derpduck-L4D2-Scripts"
}

public OnPluginStart()
{
	HookEvent("versus_marker_reached", EventHook:VersusMarkerReached, EventHookMode_Pre)
}

public Action VersusMarkerReached(Handle:event, const String:name[], bool:dontBroadcast)
{
	return Plugin_Handled;
}