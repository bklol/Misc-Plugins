#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
bool g_bAimbot=false;

public void OnPluginStart() 
{
   RegConsoleCmd("sm_sb", Music, "Set Music in Game"); 
}
public Action:Music(client, args)
{
	g_bAimbot=!g_bAimbot;
	if(g_bAimbot)
	{
		for(int a = 1; a <= MaxClients; ++a)
		{
			if(IsValidClient(a)) 
				SetEntPropFloat(a, Prop_Send, "m_flDetectedByEnemySensorTime", GetGameTime() + 9999.0);
		}
	}
	if(!g_bAimbot)
	{
		for(int n = 1; n <= MaxClients; ++n)
		{
			if(IsValidClient(n))
				SetEntPropFloat(n, Prop_Send, "m_flDetectedByEnemySensorTime", 0.0);
		}
	}
}

stock bool IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( IsFakeClient(client)) return false;
	return true;
}