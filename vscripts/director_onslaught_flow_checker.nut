Msg("Initiating Onslaught Flow Checker\n");

g_TankSpawned <- false
g_StartingFlow <- 0
g_MaxTravelDistance <- Convars.GetFloat("director_tank_bypass_max_flow_travel")
g_WarnedOnce <- false
g_BypassNavs <- array(1, null)
g_KillNavs <- array(1, null)

// Precache warning sound
PrecacheSound("Hint.Critical")

function OnslaughtGetStartingFlow()
{
	g_TankSpawned = true
	g_StartingFlow = Director.GetFurthestSurvivorFlow()
	
	// Find which nav areas will cause the horde to trigger and visually highlight them
	OnslaughtFindBypassNav()
	if (g_BypassNavs.len() > 0)
	{
		SpawnBypassMarkers()
	}
	
	if (developer() > 0)
	{
		printl("Starting Flow: " + g_StartingFlow.tostring() + "\n")
	}
}

function OnslaughtCheckFlow()
{
	if (g_TankSpawned == true)
	{
		local CurrentMaxFlow = Director.GetFurthestSurvivorFlow()
		
		// Check furthest survivor flow
		if (CurrentMaxFlow > g_StartingFlow + (g_MaxTravelDistance * 0.7))
		{
			// Survivors have travelled past the relax threshold, horde will now spawn regardless of tank state, inform players
			if (CurrentMaxFlow > g_StartingFlow + g_MaxTravelDistance)
			{
				ClientPrint(null, 3, "\x05Horde has resumed due to progression!")
				EntFire("OnslaughtFlowChecker", "Disable")
				KillBypassMarkers()
				
				// Play sound cue to warn players
				local players = null;
				while (players = Entities.FindByClassname(players, "player"))
				{
					EmitSoundOnClient("Hint.Critical", players)
				}
			}
			else
			{
				// Warn survivors getting close to the bypass point
				if (g_WarnedOnce == false)
				{
					ClientPrint(null, 3, "\x05Survivors are nearing the allowed travel distance...")
					g_WarnedOnce = true
				}
			}
		}
		
		if (developer() > 0)
		{
			printl("Current Flow: " + CurrentMaxFlow.tostring() + "\n")
		}
	}
}

function OnslaughtFindBypassNav()
{
	local areaTestFlow = null
	local flowTable = {}
	
	// Get all nav areas
	NavMesh.GetAllAreas(flowTable)
	foreach(area in flowTable)
	{
		areaTestFlow = GetFlowDistanceForPosition(area.GetCenter())
		// Find all areas with flow starting at tank spawn point, up to bypass flow amount + 2%
		if (areaTestFlow >= g_StartingFlow && areaTestFlow <= (g_StartingFlow + g_MaxTravelDistance)*1.02)
		{
			if (developer() > 0)
			{
				area.DebugDrawFilled(255, 255, 255, 50, 9000, true)
			}
			
			// Test from areas with flow less than bypass amount
			if (areaTestFlow < g_StartingFlow + g_MaxTravelDistance)
			{
				if (developer() > 0)
				{
					area.DebugDrawFilled(0, 255, 0, 100, 9000, true)
				}
				
				// Check all connection directions
				for (local i = 0; i < 4; i++)
				{
					// Make sure we don't look at sides without a connection
					if (area.IsEdge(i) == false)
					{
						// Find connections to areas with a flow greater than the bypass flow
						if (GetFlowDistanceForPosition(area.GetAdjacentArea(i, 0).GetCenter()) >= g_StartingFlow + g_MaxTravelDistance)
						{
							// Check if area is already tracked
							local areaID = area.GetID()
							if (g_BypassNavs.find(areaID) == null)
							{
								g_BypassNavs.append(areaID)
								if (developer() > 0)
								{
									printl(areaID)
									area.DebugDrawFilled(0, 0, 255, 200, 9000, true)
								}
							}
						}
					}
				}
			}
		}
	}
}

//TODO: Remove markers on the following: Navs that are edges (no connections), nav edges connected to navs with flow greater than bypass amount

// Iterate through each found nav area and highlight it
function SpawnBypassMarkers()
{
	local length = g_BypassNavs.len() - 1
	for (local i = 0; i < length; i++)
	{
		local nav = NavMesh.GetNavAreaByID(g_BypassNavs.pop())
		local navID = nav.GetID()
		navID = navID.tostring()
		local navOrigin = nav.GetCenter()
		
		// Get corners of the area and spawn entities
		for (local corner = 0; corner < 5; corner++)
		{
			local cornerVal = corner
			// Cheat and spawn another one at corner 0, the original 0 didnt connect to anything due to being the first one to spawn
			if (corner == 4)
			{
				cornerVal = 0
			}
			
			local cornerOrigin = nav.GetCorner(cornerVal)
			cornerOrigin = Vector(cornerOrigin.x, cornerOrigin.y, cornerOrigin.z + 32)
			
			SpawnEntityFromTable("keyframe_rope",
			{
				targetname		=	"_" + navID + "_onslaught_flow_nav_warning_c" + cornerVal,
				NextKey			=	"_" + navID + "_onslaught_flow_nav_warning_c" + GetLastCorner(cornerVal),
				origin			=	cornerOrigin,
				//Slack			=	10,
				Type			=	0,
				Collide			=	0,
				Breakable		=	0,
				Subdiv			=	2,
				TextureScale	=	1,
				Width			=	2,
				RopeMaterial	=	"cable/caution",
				spawnflags		=	1,
				solid			=	0
			})
			
			// Store names of entities we just spawned to remove later
			g_KillNavs.append("_" + navID + "_onslaught_flow_nav_warning_c" + cornerVal)
			
			/*SpawnEntityFromTable("prop_dynamic",
			{
				targetname	=	"_onslaught_flow_checker_nav_warning" + corner.tostring(),
				origin		=	navOrigin,
				angles		= 	Vector(0, 0, 0),
				model		=	"models/props_fortifications/concrete_post001_48.mdl",
				solid		=	0
			})*/
		}
	}
}

function KillBypassMarkers()
{
	local length = g_KillNavs.len() - 1
	for (local i = 0; i < length; i++)
	{
		EntFire(g_KillNavs.pop(), "Kill")
	}
	
	if (developer() > 0)
	{
		DebugDrawClear()
	}
}

// Get previous corner to connect a keyframe_rope to
function GetLastCorner(corner)
{
	switch(corner)
	{
		case 0:
			return 3;
			break;
		case 1:
			return 0;
			break;
		case 2:
			return 1;
			break;
		case 3:
			return 2;
			break;
		default:
			return corner;
			break;
	}
}

// We already find the survivor flow when a tank spawns, so we don't need this. Could be useful for other use cases
/*
	local furthestFlow = 0
	local testFlow = null
	local furthestOrigin = null
	
	local players = null;
	while (players = Entities.FindByClassname(players, "player"))
	{
		if (players.IsSurvivor())
		{
			testFlow = GetFlowDistanceForPosition(players.GetOrigin())
			//printl(testFlow)
			if (testFlow > furthestFlow)
			{
				furthestFlow = testFlow
				furthestOrigin = players.GetOrigin()
			}
		}
	}
	
	local startNav = NavMesh.GetNavArea(furthestOrigin, 1)
	local lastNav = startNav
*/