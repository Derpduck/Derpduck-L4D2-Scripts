printl("\nGas Cant\n")

function KillOOBCans()
{
	local gascan = null;
	while (gascan = Entities.FindByClassname(gascan, "weapon_gascan"))
	{
		local canZ = gascan.GetOrigin().z;
		if (canZ < -200)
		{
			gascan.TakeDamage(100, 2, -1)
		}
	}
}

KillOOBCans()