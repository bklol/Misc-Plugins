#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_NORECEIVESHADOW          (1 << 6)
#define EF_PARENT_ANIMATES          (1 << 9)

int icolor[3] = {255,255,255}; //glow color
int ClientGlow[MAXPLAYERS+1];
bool IsSee[MAXPLAYERS+1];

public Plugin myinfo = {
    name = "creat glow",
    author = "neko aka bklol",
    description = "creat glow",
    version = "0.1",
    url = "https://github.com/bklol"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_glow", Command_Glow,ADMFLAG_SLAY);
	HookEvent("player_death", Event_Death);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("round_prestart", DestroyGlow);
}

public void OnMapStart()
{
	ServerCommand("sv_force_transmit_players 1");
}

public void OnClientPutInServer(int client)
{
	IsSee[client] = false;
}

public Action DestroyGlow(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if(IsValidClient(i))
		{
			NEKO_TryDestroyGlow(i);
			if(IsSee[i])
			{
				IsSee[i] = false;
				PrintToChat(i,"透视关闭");
			}
		}
	}
}

public Action Command_Glow(int client,int b)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
		
	int iSpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
	if(iSpecMode != 4 && iSpecMode != 5)
	{
		PrintToChat(client,"只能在观察使用");
		return Plugin_Handled;
	}
	IsSee[client] = !IsSee[client];
	int ObserverTarget = GetEntPropEnt(client , Prop_Send, "m_hObserverTarget");
	if(!IsValidClient(ObserverTarget))
	{
		PrintToChat(client,"无效的目标");
		return Plugin_Handled;	
	}
	if(IsSee[client])
	{
		for (int i = 1; i <= MaxClients; i++) {
			if(IsValidClient(i))
				NEKO_TryDestroyGlow(i);
		}	
		for (int i = 1; i <= MaxClients; i++) {
			if(IsValidClient(i) && GetClientTeam(i) != GetClientTeam(ObserverTarget))
				NEKO_CreateGlow(i, icolor);
		}
		PrintToChat(client,"透视开启");
	}
	else
	{
		for (int i = 1; i <= MaxClients; i++) {
			if(IsValidClient(i))
				NEKO_TryDestroyGlow(i);
		}
		PrintToChat(client,"透视关闭");
	}
	return Plugin_Handled;
}

public Action Event_PlayerTeam(Handle hEvent, const char[] szEventName, bool bDontBroadcast) {
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (IsSee[iClient]) 
	{
		if (GetEventInt(hEvent, "team") == CS_TEAM_SPECTATOR) 
		{
			return Plugin_Handled;
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++) 
			{
				if(IsValidClient(i))
					NEKO_TryDestroyGlow(i);
			}
			IsSee[iClient] = false;
			PrintToChat(iClient,"透视关闭");
		}
	}
	return Plugin_Continue;
}

public Action Event_Death(Event event, char[] name, bool dontBroadcast) 
{
	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client))
	{
		NEKO_TryDestroyGlow(client);
	}
}

stock bool NEKO_CreateGlow(int client, int Color[3])
{
	NEKO_TryDestroyGlow(client);
	
	ClientGlow[client] = 0;
	char Model[PLATFORM_MAX_PATH];

	// Get the original model path
	GetEntPropString(client, Prop_Data, "m_ModelName", Model, sizeof(Model));
	
	int GlowEnt = CreateEntityByName("prop_dynamic");
		
	if(GlowEnt == -1)
		return false;
		
	//创建外发光模型
	DispatchKeyValue(GlowEnt, "model", Model);
	DispatchKeyValue(GlowEnt, "disablereceiveshadows", "1");
	DispatchKeyValue(GlowEnt, "disableshadows", "1");
	DispatchKeyValue(GlowEnt, "solid", "0");
	DispatchKeyValue(GlowEnt, "spawnflags", "256");
	DispatchKeyValue(GlowEnt, "renderamt", "0");
	SetEntProp(GlowEnt, Prop_Send, "m_CollisionGroup", 11);	
	SetEntProp(GlowEnt, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(GlowEnt, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(GlowEnt, Prop_Send, "m_flGlowMaxDist", 2000.0);

	int VariantColor[4];
		
	for(int i=0;i < 3;i++)
		VariantColor[i] = Color[i];
		
	VariantColor[3] = 76
	
	SetVariantColor(VariantColor);
	AcceptEntityInput(GlowEnt, "SetGlowColor");
	DispatchSpawn(GlowEnt);
	
	//并与父模型绑定
	int fEffects = GetEntProp(GlowEnt, Prop_Send, "m_fEffects");
	SetEntProp(GlowEnt, Prop_Send, "m_fEffects", fEffects|EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW|EF_PARENT_ANIMATES);
	SetVariantString("!activator");
	AcceptEntityInput(GlowEnt, "SetParent", client);
	SetVariantString("primary");
	AcceptEntityInput(GlowEnt, "SetParentAttachment", GlowEnt, GlowEnt, 0);
	AcceptEntityInput(GlowEnt, "TurnOn");
	SetEntPropEnt(GlowEnt, Prop_Send, "m_hOwnerEntity", client);	
	SDKHook(GlowEnt, SDKHook_SetTransmit, Hook_ShouldSeeGlow);
	ClientGlow[client] = GlowEnt;
	return true;

}

public Action Hook_ShouldSeeGlow(int glow, int viewer)
{
	if(!IsValidEntity(glow))
	{
		SDKUnhook(glow, SDKHook_SetTransmit, Hook_ShouldSeeGlow);
		return Plugin_Continue;
	}
	
	int client = GetEntPropEnt(glow, Prop_Send, "m_hOwnerEntity");

	if(client == 0)
	{
		AcceptEntityInput(glow, "Kill");
		SDKUnhook(glow, SDKHook_SetTransmit, Hook_ShouldSeeGlow);	
		return Plugin_Handled;
	}
	
	int ObserverTarget = GetEntPropEnt(viewer , Prop_Send, "m_hObserverTarget");
	if(IsValidClient(client) &&IsValidClient(ObserverTarget)&&(GetClientTeam(client) == GetClientTeam(ObserverTarget)))
		return Plugin_Handled;
	
	if(IsSee[viewer])
		return Plugin_Continue;
	else
		return Plugin_Handled;
}

stock bool NEKO_TryDestroyGlow(int client)
{
	if(ClientGlow[client] != 0 && IsValidEntity(ClientGlow[client]))
	{
		AcceptEntityInput(ClientGlow[client], "TurnOff");
		AcceptEntityInput(ClientGlow[client], "Kill");
		ClientGlow[client] = 0;
		return true;
	}
	return false;
}

stock bool IsValidClient( int client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	//if ( IsFakeClient( client )) return false;
	return true;
}
