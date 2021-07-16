//Spitter Fix Death Spit
//Version: 1
//https://github.com/Derpduck/Derpduck-L4D2-Scripts

//Changing m_fireCount causes the death spit to "respread", while this may look incorrect this is effectly the invisible spit would look like if it was visible
//TODO: Find a way to change m_maxFlames, see: https://github.com/ConfoglTeam/l4d2_direct/blob/master/scripting/include/l4d2_direct.inc#L633

printl("\nSpitter: Fix Death Spit\n")

function OnGameEvent_spitter_killed(params)
{
	printl("Spitter Killed")
	
	
	StartTimer(0.5)
}

function StartTimer(time)
{
	local timer = SpawnEntityFromTable("logic_timer",
	{
		targetname		=	"timer_fix_deathspit",
		RefireTime		=	time
	})
	EntityOutputs.AddOutput(timer, "OnTimer", "timer_fix_deathspit", "RunScriptCode", "FixDeathSpit()", 0, -1)
	EntityOutputs.AddOutput(timer, "OnTimer", "timer_fix_deathspit", "Kill", "", 0.1, -1)
}

function FixDeathSpit()
{
	local deathSpit = null;
	while (deathSpit = Entities.FindByClassname(deathSpit, "insect_swarm"))
	{
		local fireCount = NetProps.GetPropInt(deathSpit, "m_fireCount")
		printl("test " + fireCount)
		if (fireCount>1)
		{
			NetProps.SetPropInt(deathSpit, "m_fireCount", 1)
			fireCount = NetProps.GetPropInt(deathSpit, "m_fireCount")
			printl("test after " + fireCount)
		}
	}
}

function TestDeathSpit()
{
	local fireCount = null;
	local deathSpit = null;
	while (deathSpit = Entities.FindByClassname(deathSpit, "insect_swarm"))
	{
		fireCount = NetProps.GetPropInt(deathSpit, "m_fireCount")
		printl("test later " + fireCount)
	}
}


__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener)
