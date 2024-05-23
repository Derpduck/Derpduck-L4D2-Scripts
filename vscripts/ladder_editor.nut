//A re-write of devilesk's l4d2_ladder_editor plugin in vscript
//https://github.com/devilesk/rl4d2l-plugins/blob/master/l4d2_ladder_editor.sp

//TODO: Allow tab to actually enable edit mode when not in edit mode

printl("LADDER_EDITOR ENABLED\n");
printl("_____________________\n");
printl("COMMANDS:");
printl("\t!edit          \t\tToggles edit mode");
printl("\t!step <size>   \t\tChange edit mode step size");
printl("\t!select        \t\tSelects the ladder you are currently aiming at");
printl("\t!clone         \t\tCreates a copy of the selected ladder");
printl("\t!move <x y z>  \t\tTeleports the selected ladder to the given coordinates");
printl("\t!nudge <x y z> \t\tMoves the selected ladder from its current position by the given coordinates");
printl("\t!rotate <x y z>\t\tRotates the selected ladder to the given angles");
printl("\t!kill          \t\tDeletes the selected ladder");
printl("\t!info          \t\tPrints info for the ladder you are currently aiming at in chat and console (including Stripper:Source code)");
printl("\t!hud           \t\tToggles the info display / highlight on the currently selected ladder");
printl("\t!precision <decimals>\t\tChanges the number of decimal places shown on the chat / HUD (console output will always have maximum precision)");
printl("_____________________\n");
printl("EDIT MODE CONTROLS:");
printl("\tTAB (SCOREBOARD)      \t\tToggles edit mode");
printl("\tMOUSE1 (PRIMARY ATK)  \t\tSelects the ladder you are currently aiming at");
printl("\tMOUSE2 (SECONDARY ATK)\t\tTeleports the selected ladder to the position you are currently aiming at");
printl("\tSHIFT (WALK)          \t\tRotate the selected ladder by 90 degrees on the Y-axis");
printl("\tA (LEFT)              \t\tNudge the selected ladder left on the X-axis by the step size");
printl("\tD (RIGHT)             \t\tNudge the selected ladder right on the X-axis by the step size");
printl("\tW (FORWARD)           \t\tNudge the selected ladder forward on the Y-axis by the step size");
printl("\tS (BACK)              \t\tNudge the selected ladder back on the Y-axis by the step size");
printl("\tE (USE)               \t\tNudge the selected ladder up on the Z-axis by the step size");
printl("\tR (RELOAD)            \t\tNudge the selected ladder down on the Z-axis by the step size");

MAXPLAYERS <- 32;
ladderTable <- {};
iFloatPrecision <- array(MAXPLAYERS + 1, 2);
bEditMode <- array(MAXPLAYERS + 1, false);
fStepSize <- array(MAXPLAYERS + 1, 1.0);
iSelectedLadder <- array(MAXPLAYERS + 1, -1);
bHud <- array(MAXPLAYERS + 1, true);

//Commands
function OnGameEvent_player_say(params)
{
    local clientIndex = params.userid;
    local client = GetPlayerFromUserID(params.userid);
    local text = params.text;
    local argument = [];
    argument = split(text, " ");
    if (argument.len() == 0)
    {
        return;
    }
    local command = argument[0].tolower().slice(1);
    local commandPrefix = argument[0].slice(0, 1);
    argument.remove(0);

    if (commandPrefix == "!" || commandPrefix == "/")
    {
        switch(command)
        {
            case "edit":
                CommandEdit(client, clientIndex);
                break;
            case "step":
                CommandStep(client, clientIndex, argument);
                break;
            case "select":
                CommandSelect(client, clientIndex);
                break;
            case "clone":
                CommandClone(client, clientIndex);
                break;
            case "move":
                CommandMove(client, clientIndex, argument);
                break;
            case "nudge":
                CommandNudge(client, clientIndex, argument);
                break;
            case "rotate":
                CommandRotate(client, clientIndex, argument);
                break;
            case "kill":
                CommandKill(client, clientIndex);
                break;
            case "info":
                CommandInfo(client, clientIndex);
                break;
            case "hud":
                CommandHud(client, clientIndex);
                break;
            case "precision":
                CommandPrecision(client, clientIndex, argument);
                break;
        }
        return false;
    }
}

function CommandEdit(client, clientIndex)
{
    if (client.IsSurvivor())
    {
        ClientPrint(client, 3, "Must be on infected team to enter edit mode.");
        return;
    }

    if (bEditMode[clientIndex])
    {
        bEditMode[clientIndex] = false;
        SetClientFrozen(client, 2);
        //AddThinkToEnt(client, null);
        ClientPrint(client, 3, "Exiting edit mode.");
    }
    else
    {
        bEditMode[clientIndex] = true;
        SetClientFrozen(client, 0);
        RunEditMode(client, clientIndex);
        ClientPrint(client, 3, "Entering edit mode.");
    }
}

function CommandStep(client, clientIndex, argument)
{
    if (argument.len() != 1)
    {
        ClientPrint(client, 3, "Usage: !step <size>");
        return;
    }

    local size = StringToFloat(argument[0]);

    if (size == false)
    {
        ClientPrint(client, 3, "Invalid step size: " + argument[0]);
        return;
    }

    if (size > 0)
    {
        fStepSize[clientIndex] = size;
        ClientPrint(client, 3, "Step size set to: " + size);
    }
    else
    {
        ClientPrint(client, 3, "Step size must be greater than 0.");
    }
}

function CommandSelect(client, clientIndex)
{
    local entity = TraceView(client);
    
    if (!entity.IsValid())
    {
        iSelectedLadder[clientIndex] = -1;
        ClientPrint(client, 3, "Looking at invalid entity: " + entity);
        return;
    }

    local classname = entity.GetClassname();
    if (classname != "func_simpleladder")
    {
        iSelectedLadder[clientIndex] = -1;
        ClientPrint(client, 3, "Not looking at a ladder. Entity: " + entity + ", classname: " + classname);
        return;
    }

    iSelectedLadder[clientIndex] = entity;
    local ladderInfo = GetLadderEntityInfo(entity);
    PrintLadderInfo(client, entity, ladderInfo);
}

function CommandClone(client, clientIndex)
{
    local sourceEntity = iSelectedLadder[clientIndex];

    if (!ValidLadder(client, clientIndex, sourceEntity))
    {
        return;
    }

    local sourceLadderInfo = GetLadderEntityInfo(sourceEntity);
    PrecacheModel(sourceLadderInfo[0]);

    local entity = SpawnEntityFromTable("func_simpleladder",
    {
        model = sourceLadderInfo[0],
        origin = Vector(50, 0, 0),
        team = 2
    });

    if (!entity.IsValid())
    {
        ClientPrint(client, 3, "Failed to create ladder.");
        return;
    }

    NetProps.SetPropVector(entity, "m_climbableNormal", sourceLadderInfo[3]);
    local ladderInfo = GetLadderEntityInfo(entity);

    iSelectedLadder[clientIndex] = entity;
    ladderTable[entity] <- sourceEntity;
    ClientPrint(client, 3, "Cloned ladder entity: " + sourceEntity + ". New entity: " + entity);
    PrintLadderInfo(client, entity, ladderInfo);
}

function CommandMove(client, clientIndex, argument)
{
    //TODO: Allow for missing arguments, e.g. !move x 50 = move x to 50, or !move y 10 = move y to 10
    if (argument.len() != 3)
    {
        ClientPrint(client, 3, "Usage: !move <x> <y> <z>");
        return;
    }

    local x = StringToFloat(argument[0]);
    local y = StringToFloat(argument[1]);
    local z = StringToFloat(argument[2]);

    if (x == false || y == false || z == false)
    {
        ClientPrint(client, 3, "Invalid vector passed: " + argument[0]);
        return;
    }

    MoveLadder(client, x, y, z, true);
}

function CommandNudge(client, clientIndex, argument)
{
    //TODO: Allow for missing arguments, e.g. !nudge x 50 = nudge x by 50, or !nudge y 10 = nudge y by 10
    if (argument.len() != 3)
    {
        ClientPrint(client, 3, "Usage: !nudge <x> <y> <z>");
        return;
    }

    local x = StringToFloat(argument[0]);
    local y = StringToFloat(argument[1]);
    local z = StringToFloat(argument[2]);

    if (x == false || y == false || z == false)
    {
        ClientPrint(client, 3, "Invalid vector passed: " + argument[0]);
        return;
    }

    NudgeLadder(client, x, y, z, true);
}

function CommandRotate(client, clientIndex, argument)
{
    //TODO: Allow for missing arguments, e.g. !rotate x 50 = rotate x to 50, or !rotate y 10 = rotate y to 10
    if (argument.len() != 3)
    {
        ClientPrint(client, 3, "Usage: !rotate <x> <y> <z>");
        return;
    }

    local x = StringToFloat(argument[0]);
    local y = StringToFloat(argument[1]);
    local z = StringToFloat(argument[2]);

    if (x == false || y == false || z == false)
    {
        ClientPrint(client, 3, "Invalid vector passed: " + argument[0]);
        return;
    }

    RotateLadder(client, x, y, z, true);
}

function CommandKill(client, clientIndex)
{
    local entity = iSelectedLadder[clientIndex];

    if (!ValidLadder(client, clientIndex, entity))
    {
        return;
    }

    local ladderInfo = GetLadderEntityInfo(entity);
    PrintLadderInfo(client, entity, ladderInfo, "Killed ladder entity");

    if (entity in ladderTable)
    {
        ladderTable.rawdelete(entity);
    }

    entity.Kill();
    iSelectedLadder[clientIndex] = -1;
}

function CommandInfo(client, clientIndex)
{
    local entity = TraceView(client);

    if (!entity.IsValid())
    {
        iSelectedLadder[clientIndex] = -1;
        ClientPrint(client, 3, "Looking at invalid entity: " + entity);
        return;
    }

    local classname = entity.GetClassname();
    if (classname != "func_simpleladder")
    {
        iSelectedLadder[clientIndex] = -1;
        ClientPrint(client, 3, "Not looking at a ladder. Entity: " + entity + ", classname: " + classname);
        return;
    }

    local ladderInfo = GetLadderEntityInfo(entity);
    PrintLadderInfo(client, entity, ladderInfo, "Ladder entity", true);
}

function CommandHud(client, clientIndex)
{
    if (bHud[clientIndex])
    {
        bHud[clientIndex] = false;
        DebugDrawClear();
        ClientPrint(client, 3, "Disabled HUD.");
    }
    else
    {
        bHud[clientIndex] = true;
        ClientPrint(client, 3, "Enabled HUD.");
    }
}

function CommandPrecision(client, clientIndex, argument)
{
    if (argument.len() != 1)
    {
        ClientPrint(client, 3, "Usage: !precision <decimals>");
        return;
    }

    local precision = StringToInteger(argument[0]);

    if (precision == false)
    {
        ClientPrint(client, 3, "Invalid precision value: " + argument[0]);
        return;
    }

    if (precision >= 0)
    {
        iFloatPrecision[clientIndex] = precision;
        ClientPrint(client, 3, "Precision set to: " + precision);
    }
    else
    {
        ClientPrint(client, 3, "Precision size must be positive.");
    }
}

//Edit Mode
if (Entities.FindByName(null, "ladder_editor_edit_mode" ) == null)
{
    editModeThink <- SpawnEntityFromTable("info_target",
    {
        targetname = "ladder_editor_edit_mode"
    });
}

function RunEditMode(client, clientIndex)
{
    if (client.ValidateScriptScope())
    {
        local think = client.GetScriptScope();
        think["client"] <- client;
        think["clientIndex"] <- clientIndex;
        think["editMode"] <- bEditMode[clientIndex];
        think["buttonMask"] <- 0;
        think["in_attack"] <- false;
        think["in_attack2"] <- false;
        think["in_speed"] <- false;
        think["in_score"] <- false;
        think["trace"] <- -1;

        think["editModeThink"] <- function()
        {
            think["editMode"] <- bEditMode[think["clientIndex"]];

            if (!think["editMode"])
            {
                return;
            }

            if (think["client"].IsValid())
            {
                think["buttonMask"] = think["client"].GetButtonMask();
            }
            else
            {
                return;
            }

            /*IN_ATTACK = 1
            IN_JUMP = 2
            IN_DUCK = 4
            IN_FORWARD = 8
            IN_BACK = 16
            IN_USE = 32
            IN_CANCEL = 64 (Not in L4D2?)
            IN_MOVELEFT = 512
            IN_MOVERIGHT = 1024
            IN_ATTACK2 = 2048
            IN_RELOAD = 8192
            IN_SCORE = 65536
            IN_SPEED = 131072
            IN_ZOOM = 524288*/
            printl(think["buttonMask"])

            //Attack1 (Released)
            if (!(think["buttonMask"] & 1) && think["in_attack"])
            {
                think["in_attack"] = false;
                CommandSelect(think["client"], think["clientIndex"]);
            }
            //Attack1 (Pressed)
            if (think["buttonMask"] & 1 && !think["in_attack"])
            {
                think["in_attack"] = true;
            }

            //Attack2 (Released)
            if (!(think["buttonMask"] & 2048) && think["in_attack2"])
            {
                think["in_attack2"] = false;
                think["trace"] = TraceView(think["client"], false);
                if (think["trace"] != -1)
                {
                    MoveLadder(think["client"], think["trace"].x, think["trace"].y, think["trace"].z, false);
                }
            }
            //Attack2 (Pressed)
            if (think["buttonMask"] & 2048 && !think["in_attack2"])
            {
                think["in_attack2"] = true;
            }

            //Speed (Released)
            if (!(think["buttonMask"] & 131072) && think["in_speed"])
            {
                think["in_speed"] = false;
                RotateStep(think["client"]);
            }
            //Speed (Pressed)
            if (think["buttonMask"] & 131072 && !think["in_speed"])
            {
                think["in_speed"] = true;
            }

            //Tab (Released)
            if (!(think["buttonMask"] & 65536) && think["in_score"])
            {
                think["in_score"] = false;
                CommandEdit(think["client"], think["clientIndex"]);
            }
            //Tab (Pressed)
            if (think["buttonMask"] & 65536 && !think["in_score"])
            {
                think["in_score"] = true;
            }

            //Left
            if (think["buttonMask"] & 512)
            {
                NudgeLadder(think["client"], -fStepSize[think["clientIndex"]], 0, 0, false)
            }
            //Right
            if (think["buttonMask"] & 1024)
            {
                NudgeLadder(think["client"], fStepSize[think["clientIndex"]], 0, 0, false)
            }
            //Forward
            if (think["buttonMask"] & 8)
            {
                NudgeLadder(think["client"], 0, fStepSize[think["clientIndex"]], 0, false)
            }
            //Back
            if (think["buttonMask"] & 16)
            {
                NudgeLadder(think["client"], 0, -fStepSize[think["clientIndex"]], 0, false)
            }
            //Up
            if (think["buttonMask"] & 32)
            {
                NudgeLadder(think["client"], 0, 0, fStepSize[think["clientIndex"]], false)
            }
            //Down
            if (think["buttonMask"] & 8192)
            {
                NudgeLadder(think["client"], 0, 0, -fStepSize[think["clientIndex"]], false)
            }

            return 0.01;
        }

        AddThinkToEnt(client, "editModeThink");
    }
}

function RotateStep(client)
{
    local clientIndex = client.GetPlayerUserId();
    local entity = iSelectedLadder[clientIndex];

    if (!ValidLadder(client, clientIndex, entity))
    {
        return;
    }

    local ladderInfo = GetLadderEntityInfo(entity);
    RotateLadder(client, 0, ladderInfo[4].y + 90, 0, true);
}

//HUD
function DrawLadderInfo()
{
    if (Entities.FindByName(null, "ladder_editor_redraw_timer" ) == null)
    {
        SpawnEntityFromTable("logic_timer",
        {
            targetname  =   "ladder_editor_redraw_timer",
            RefireTime  =   1,
            connections =
            {
                OnTimer =
                {
                    cmd1 = "worldspawnCallScriptFunctionLadderEditorRedraw0-1"
                }
            }
        });
    }

    LadderEditorRedraw();
}

function LadderEditorRedraw()
{

    local client = GetListenServerHost();
    if (!client.IsValid())
    {
        return;
    }

    local clientIndex = client.GetPlayerUserId();
    local entity = iSelectedLadder[clientIndex];

    if (entity == -1)
    {
        return;
    }

    if (!entity.IsValid())
    {
        return;
    }

    local classname = entity.GetClassname();
    if (classname != "func_simpleladder")
    {
        return;
    }

    if (!bHud[clientIndex])
    {
        return;
    }

    DebugDrawClear();

    local ladderInfo = GetLadderEntityInfo(entity);
    local mins = NetProps.GetPropVector(entity, "m_Collision.m_vecMins");
    local maxs = NetProps.GetPropVector(entity, "m_Collision.m_vecMaxs");
    local precision = iFloatPrecision[clientIndex];
    local worldPosition = "(" + format("%." + precision + "f", ladderInfo[2].x) + ", " + format("%." + precision + "f", ladderInfo[2].y) + ", " + format("%." + precision + "f", ladderInfo[2].z) + ")";
    local origin = "(" + format("%." + precision + "f", ladderInfo[1].x) + ", " + format("%." + precision + "f", ladderInfo[1].y) + ", " + format("%." + precision + "f", ladderInfo[1].z) + ")";
    local normal = "(" + format("%." + precision + "f", ladderInfo[3].x) + ", " + format("%." + precision + "f", ladderInfo[3].y) + ", " + format("%." + precision + "f", ladderInfo[3].z) + ")";
    local angles = "(" + format("%." + precision + "f", ladderInfo[4].x) + ", " + format("%." + precision + "f", ladderInfo[4].y) + ", " + format("%." + precision + "f", ladderInfo[4].z) + ")";
    local drawText = "entity: " + entity + "\nmodel: " + ladderInfo[0] + "\nworld position: " + worldPosition + "\norigin: " + origin + "\nangles: " + angles + "\nnormals: " + normal

    DebugDrawBoxAngles(ladderInfo[1], mins, maxs, QAngle(ladderInfo[4].x, ladderInfo[4].y, ladderInfo[4].z), Vector(0, 128, 255), 40, 99999999);
    DebugDrawText(ladderInfo[1] + MathLadderOrigin(mins, maxs, ladderInfo[4]), drawText, false, 10);
}
DrawLadderInfo();

//Functions
function SetClientFrozen(client, moveType)
{
    NetProps.SetPropInt(client, "m_MoveType", moveType);
}

function TraceView(client, returnEntity = true)
{
    local eyeAngles = client.EyeAngles();
    local eyePosition = client.EyePosition();
    local traceStart = eyePosition;
    local traceEnd = eyePosition + (eyeAngles.Forward() * 2000);

    local traceTable =
    {
        start = traceStart
        end = traceEnd
        ignore = client
        mask = 33636363 //TRACE_MASK_PLAYER_SOLID
    };

    if(TraceLine(traceTable))
    {
        if(traceTable.hit)
        {
            //Uncomment to see trace position
            /*SpawnEntityFromTable("prop_dynamic_override",
            {
                origin = traceTable.pos,
                model = "models/w_models/weapons/w_eq_painpills.mdl",
                solid = 0,
            });*/
            if (returnEntity)
            {
                return traceTable.enthit;
            }
            else
            {
                return traceTable.pos;
            }
        }
        else
        {
            return -1;
        }
    }
}

//[modelName, origin, position, normal, angles]
function GetLadderEntityInfo(entity)
{
    local modelName = entity.GetModelName();
    local origin = entity.GetOrigin();
    local mins = NetProps.GetPropVector(entity, "m_Collision.m_vecMins");
    local maxs = NetProps.GetPropVector(entity, "m_Collision.m_vecMaxs");
    local normal = NetProps.GetPropVector(entity, "m_climbableNormal");
    local angles = entity.GetAngles();
    mins = Math_RotateVector(mins, angles);
    maxs = Math_RotateVector(maxs, angles);
    local worldPosition = Vector(origin.x + ((mins.x + maxs.x) * 0.5), origin.y + ((mins.y + maxs.y) * 0.5), origin.z + ((mins.z + maxs.z) * 0.5));

    return [modelName, origin, worldPosition, normal, angles];
}

function PrintLadderInfo(client, entity, ladderInfo, printString = "", printStripper = false)
{
    local clientIndex = client.GetPlayerUserId();
    local precision = iFloatPrecision[clientIndex];

    local worldPosition = "(" + format("%." + precision + "f", ladderInfo[2].x) + ", " + format("%." + precision + "f", ladderInfo[2].y) + ", " + format("%." + precision + "f", ladderInfo[2].z) + ")";
    local origin = "(" + format("%." + precision + "f", ladderInfo[1].x) + ", " + format("%." + precision + "f", ladderInfo[1].y) + ", " + format("%." + precision + "f", ladderInfo[1].z) + ")";
    local normal = "(" + format("%." + precision + "f", ladderInfo[3].x) + ", " + format("%." + precision + "f", ladderInfo[3].y) + ", " + format("%." + precision + "f", ladderInfo[3].z) + ")";
    local angles = "(" + format("%." + precision + "f", ladderInfo[4].x) + ", " + format("%." + precision + "f", ladderInfo[4].y) + ", " + format("%." + precision + "f", ladderInfo[4].z) + ")";

    if (printString == "")
    {
        printString = "Selected ladder entity";
    }

    ClientPrint(client, 3, printString + ": " + entity + ", " + ladderInfo[0] + " at World Position: " + worldPosition + ". Origin: " + origin + ". Normal: " + normal + ". Angles: " + angles);

    //Print all values to console in stripper format with full precision
    if (!printStripper)
    {
        printl("\"world position\" \"" + ladderInfo[2] + "\"");
        printl("\"model\" \"" + ladderInfo[0] + "\"");
        printl("\"origin\" \"" + ladderInfo[1] + "\"");
        printl("\"angles\" \"" + ladderInfo[4] + "\"");
        printl("\"normal\" \"" + ladderInfo[3] + "\"");
    }
    else
    {
        printl("add:");
        printl("{");
        printl("    \"classname\" \"func_simpleladder\"")
        printl("    \"origin\" \"" + ladderInfo[1].x + " " + ladderInfo[1].y + " " + ladderInfo[1].z + "\"")
        printl("    \"angles\" \"" + ladderInfo[4].x + " " + ladderInfo[4].y + " " + ladderInfo[4].z + "\"")
        printl("    \"model\" \"" + ladderInfo[0] + "\"")
        printl("    \"normal.x\" \"" + ladderInfo[3].x + "\"")
        printl("    \"normal.y\" \"" + ladderInfo[3].y + "\"")
        printl("    \"normal.z\" \"" + ladderInfo[3].z + "\"")
        printl("    \"team\" \"2\"")
        printl("}");
    }
}

function DegToRad(angle)
{
    return angle * (PI / 180);
}

function Math_RotateVector(vec, angles)
{
    // angles.z = xAxis
    // angles.x = yAxis
    // angles.y = zAxis
    local rad = [DegToRad(angles.z), DegToRad(angles.x), DegToRad(angles.y)];

    local cosAlpha = cos(rad[0]);
    local sinAlpha = sin(rad[0]);
    local cosBeta = cos(rad[1]);
    local sinBeta = sin(rad[1]);
    local cosGamma = cos(rad[2]);
    local sinGamma = sin(rad[2]);

    local x = vec.x;
    local y = vec.y;
    local z = vec.z;
    local newX;
    local newY;
    local newZ;

    newY = (cosAlpha*y) - (sinAlpha*z);
    newZ = (cosAlpha*z) + (sinAlpha*y);
    y = newY;
    z = newZ;

    newX = (cosBeta*x) + (sinBeta*z);
    newZ = (cosBeta*z) - (sinBeta*x);
    x = newX;
    z = newZ;

    newX = (cosGamma*x) - (sinGamma*y);
    newY = (cosGamma*y) + (sinGamma*x);
    x = newX;
    y = newY;

    return Vector(x, y, z);
}

function StringToFloat(string)
{
    try
    {
        string = string.tofloat();
    }
    catch(exception)
    {
        ClientPrint(null, 3, "Invalid number passed: " + string);
        return false;
    }

    return string;
}

function StringToInteger(string)
{
    try
    {
        string = string.tointeger();
    }
    catch(exception)
    {
        ClientPrint(null, 3, "Invalid number passed: " + string);
        return false;
    }

    return string;
}

function ValidLadder(client, clientIndex, entity)
{
    if (entity == -1)
    {
        ClientPrint(client, 3, "No valid ladder selected.");
        return false;
    }

    if (!entity.IsValid())
    {
        iSelectedLadder[clientIndex] = -1;
        ClientPrint(client, 3, "No valid ladder selected.");
        return false;
    }

    local classname = entity.GetClassname();
    if (classname != "func_simpleladder")
    {
        iSelectedLadder[clientIndex] = -1;
        ClientPrint(client, 3, "No valid ladder selected.");
        return false;
    }

    return true;
}

function MoveLadder(client, x, y, z, printInfo)
{
    local clientIndex = client.GetPlayerUserId();
    local entity = iSelectedLadder[clientIndex];

    if (!ValidLadder(client, clientIndex, entity))
    {
        return;
    }

    if (!(entity in ladderTable))
    {
        ClientPrint(client, 3, "Original ladder not found.");
        return;
    }

    if (!ValidLadder(client, clientIndex, ladderTable[entity]))
    {
        return;
    }

    local ladderInfo = GetLadderEntityInfo(entity);
    local sourceLadderInfo = GetLadderEntityInfo(ladderTable[entity]);

    if (printInfo)
    {
        PrintLadderInfo(client, ladderTable[entity], sourceLadderInfo, "Original ladder entity");
    }

    entity.SetOrigin(Vector(x - sourceLadderInfo[2].x, y - sourceLadderInfo[2].y, z - sourceLadderInfo[2].z));

    if (printInfo)
    {
        ladderInfo = GetLadderEntityInfo(entity);
        PrintLadderInfo(client, entity, ladderInfo, "Moved ladder entity");
    }
}

function NudgeLadder(client, x, y, z, printInfo)
{
    local clientIndex = client.GetPlayerUserId();
    local entity = iSelectedLadder[clientIndex];

    if (!ValidLadder(client, clientIndex, entity))
    {
        return;
    }

    local ladderInfo = GetLadderEntityInfo(entity);

    entity.SetOrigin(Vector(x + ladderInfo[1].x, y + ladderInfo[1].y, z + ladderInfo[1].z));

    if (printInfo)
    {
        ladderInfo = GetLadderEntityInfo(entity);
        PrintLadderInfo(client, entity, ladderInfo, "Moved ladder entity");
    }
}

function RotateLadder(client, x, y, z, printInfo)
{
    local clientIndex = client.GetPlayerUserId();
    local entity = iSelectedLadder[clientIndex];

    if (!ValidLadder(client, clientIndex, entity))
    {
        return;
    }

    if (!(entity in ladderTable))
    {
        ClientPrint(client, 3, "Original ladder not found.");
        return;
    }

    if (!ValidLadder(client, clientIndex, ladderTable[entity]))
    {
        return;
    }

    local ladderInfo = GetLadderEntityInfo(entity);
    local sourceLadderInfo = GetLadderEntityInfo(ladderTable[entity]);

    if (printInfo)
    {
        PrintLadderInfo(client, ladderTable[entity], sourceLadderInfo, "Original ladder entity");
    }

    local newAngles = Vector(x, y, z);
    local rotatedPosition = Math_RotateVector(sourceLadderInfo[2], newAngles);
    local rotatedOrigin = Vector(-rotatedPosition.x + ladderInfo[2].x, -rotatedPosition.y + ladderInfo[2].y, -rotatedPosition.z + ladderInfo[2].z);
    
    entity.SetOrigin(rotatedOrigin);
    entity.SetAngles(QAngle(newAngles.x, newAngles.y, newAngles.z));

    NetProps.SetPropVector(entity, "m_climbableNormal", Math_RotateVector(sourceLadderInfo[3], newAngles));

    if (printInfo)
    {
        ladderInfo = GetLadderEntityInfo(entity);
        PrintLadderInfo(client, entity, ladderInfo, "Rotated ladder entity");
    }
}

function MathLadderOrigin(vecMins, vecMaxs, vecAngles)
{
    // Position of ladder mins and maxs to transform.

    local vectorX = ( vecMins.x + vecMaxs.x ) / 2;
    local vectorY = ( vecMins.y + vecMaxs.y ) / 2;
    local vectorZ = ( vecMins.z + vecMaxs.z ) / 2;

    // Angle ladder is rotated by, in radians.

    local angleX = DegToRad(vecAngles.z);
    local angleY = DegToRad(vecAngles.x);
    local angleZ = DegToRad(vecAngles.y);

    // Store trig calculations.

    local cosX = cos( angleX );
    local cosY = cos( angleY );
    local cosZ = cos( angleZ );
    local sinX = sin( angleX );
    local sinY = sin( angleY );
    local sinZ = sin( angleZ );

    // Mid-calculation variables.

    local transformedX = 0;
    local transformedY = 0;
    local transformedZ = 0;

    // 3D rotation matrix.

    transformedY = ( cosX * vectorY ) - ( sinX * vectorZ );
    transformedZ = ( cosX * vectorZ ) + ( sinX * vectorY );
    vectorY = transformedY;
    vectorZ = transformedZ;

    transformedX = ( cosY * vectorX ) + ( sinY * vectorZ );
    transformedZ = ( cosY * vectorZ ) - ( sinY * vectorX );
    vectorX = transformedX;
    vectorZ = transformedZ;

    transformedX = ( cosZ * vectorX ) - ( sinZ * vectorY );
    transformedY = ( cosZ * vectorY ) + ( sinZ * vectorX );
    vectorX = transformedX;
    vectorY = transformedY;

    // Final result is the offset of the ladder from the world's origin (0,0,0), but corrected for rotation.
    // GetOrigin gives us the offset of the ladder from its cloned model.
    // Adding them together produces the actual position of the ladder in the world.

    return Vector( vectorX, vectorY, vectorZ );
}


__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener)