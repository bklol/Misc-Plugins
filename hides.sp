#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>

bool g_bIsHiding[MAXPLAYERS+1];

public Plugin myinfo = {
    name = "hide me",
    author = "neko aka bklol",
    description = "change csgo status",
    version = "0.1",
    url = "https://github.com/bklol"
};

public OnPluginStart() {

    RegConsoleCmd("sm_hide", Command_HiddenSpectate);
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
}

public OnMapStart() {
	SDKHook(GetPlayerResourceEntity(), SDKHook_ThinkPost, Hook_OnThinkPost);
}

public OnClientPutInServer(iClient) {
	g_bIsHiding[iClient] = false;
}

public OnClientDisconnect(iClient) {
	g_bIsHiding[iClient] = false;
}

public Action Command_HiddenSpectate(iClient, iArgs) {

	
	if (g_bIsHiding[iClient]) {
		ReplyToCommand(iClient, "你已经被隐藏了,加入队伍来解除隐藏.");
		return Plugin_Handled;
	}
    
	g_bIsHiding[iClient] = true;
    
	if (GetClientTeam(iClient) != CS_TEAM_SPECTATOR) {
		ChangeClientTeam(iClient, CS_TEAM_SPECTATOR);
	}
	ForcePlayerSuicide(iClient);
	CreateFakeDisconnectEvent(iClient);
	ReplyToCommand(iClient, "你现在被隐藏了,加入队伍来解除隐藏.");
	return Plugin_Handled;
}

public void CreateFakeDisconnectEvent(int client)
{
	char sName[128];
	GetClientName(client, sName, sizeof(sName));
	Event event = CreateEvent("player_disconnect");
	event.SetInt("userid", GetClientUserId(client));
	event.SetString("reason","Disconnect");
	event.SetString("name",sName);
	for (int i = 1; i <= MaxClients; i++) {
	if(IsValidClient(i))
		event.FireToClient(i);
	}
	delete event; //cause memory leak ？
}

public Action Event_PlayerTeam(Handle hEvent, const char[] szEventName, bool bDontBroadcast) {
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (g_bIsHiding[iClient]) {
		if (GetEventInt(hEvent, "team") == CS_TEAM_SPECTATOR) {
			return Plugin_Handled;
		} else {
			g_bIsHiding[iClient] = false;
			ReplyToCommand(iClient, "解除了隐藏.");
		}
	}
	return Plugin_Continue;
}

public Hook_OnThinkPost(int iEnt) {
	static iConnectedOffset = -1;
	if (iConnectedOffset == -1) {
		iConnectedOffset = FindSendPropInfo("CCSPlayerResource", "m_bConnected");
	}
    
	int iConnected[65];
	GetEntDataArray(iEnt, iConnectedOffset, iConnected, MaxClients + 1);  
	for (int i = 1; i <= MaxClients; i++) {
		if (g_bIsHiding[i]) {
			iConnected[i] = 0;
		}
	}   
	SetEntDataArray(iEnt, iConnectedOffset, iConnected, MaxClients+1);
} 

stock bool IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( IsFakeClient(client)) return false;
	return true;
}