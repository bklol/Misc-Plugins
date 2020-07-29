#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

static Handle RoundTimer = null;
int count;

public void OnPluginStart()
{
	HookEvent("round_prestart", round_prestart);
	HookEvent("player_death", Event_Death);
	HookEvent("player_spawn", PlayerSpawn);
}

public void OnMapStart()
{
	CloseEsp();
	count = -1;
}

public void OnMapEnd()
{
	CloseEsp();
}

public Action round_prestart(Event event, const char[] name, bool dontBroadcast)
{
	CloseEsp();
}

public Action Event_Death(Event event, char[] name, bool dontBroadcast) 
{ 
	CheckAlive();
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
			SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 0.0);
	}
}

void CheckAlive()
{
	if (GameRules_GetProp("m_bWarmupPeriod"))
		return;
	int g_iTeamCT, g_iTeamT;
	for (int i = 1; i <= MaxClients; i++) 
	{
		if(IsValidClient(i) && IsPlayerAlive(i)) 
		{
			if(GetClientTeam(i) == CS_TEAM_CT) 
				g_iTeamCT++; 
			else if(GetClientTeam(i) == CS_TEAM_T)
				g_iTeamT++; 
		} 
	}
	if( g_iTeamCT==1 && g_iTeamT == 1 )
		TriggerEsp();
}

void TriggerEsp()
{
	PrintToChatAll("Trigger");
	if (RoundTimer != null)
        KillTimer(RoundTimer);
	RoundTimer = CreateTimer(1.0, ESP, _, TIMER_REPEAT);
}

public Action ESP(Handle timer)
{
	if (count == 3)
    {
		for(int client = 1; client <= MaxClients; ++client)
			{
			if (IsValidClient(client) && IsPlayerAlive(client))
				SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 9999999.0);
		}
	}
	if(count > 4)
		count = 1;
	else
		count++;

	if(count < 3)
	{
		for(int client = 1; client <= MaxClients; ++client)
		{
			if (IsValidClient(client) && IsPlayerAlive(client))
				SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 0.0);
		}
	}
}

void CloseEsp()
{
	if (RoundTimer != null)
        KillTimer(RoundTimer);
	RoundTimer = null;
}

stock bool IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	return true;
}
