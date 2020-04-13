#include <sourcemod>
#include <cstrike>
#include <sdktools>

char g_szAuth[MAXPLAYERS + 1][32];

public void OnClientAuthorized(int client, const char[] auth)
{
	if (!GetClientAuthId(client, AuthId_Steam2, g_szAuth[client], sizeof(g_szAuth)))
	{
		KickClient(client, "Verification problem, Please reconnect");
		return;
	}
}

public OnGameFrame()
{
    for (new i = MaxClients; i > 0; --i)
    {
        if(IsValidClient(i))
			SetClientName(i, g_szAuth[i]);       
    }
}

stock bool:IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( IsFakeClient(client)) return false;
	return true;
}