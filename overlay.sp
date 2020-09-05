#include <sourcemod>
#include <sdktools>
#include <overlays>

public Plugin myinfo =
{
	name = "Ooverlay",
	author = "www.nicotine.vip[neko]",
	description = "overlay plugin",
	version = "0.1"
};

int Overlays;
int OwnersOverlays;
int num;
int OId[MAXPLAYERS + 1];

bool IsLookingASpecial[MAXPLAYERS + 1];

enum overlaySettings
{
	OverlayOwner = 0,
	OverlayPath,
}



char g_Overlay[137][PLATFORM_MAX_PATH + 1];
char g_OwnerOverlay[137][overlaySettings][PLATFORM_MAX_PATH + 1];

public OnPluginStart()
{
	LoadOverlay();
	AddCommandListener(Command_JoinTeam, "jointeam");
}

public Action Command_JoinTeam(client, char[] command, args)
{    
    if(IsValidClient(client) && GetClientTeam(client) == 1)
	{
		CreateTimer(0.0, DeleteOverlay, client);
		num = GetNum();
		if(IsClientTarget(client))
			ShowOverlay(client,g_Overlay[num],0.0);
	}

} 

public void OnMapStart()
{
	num = 0;
	CreateTimer(10.0, showoverlays,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action showoverlays(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		CreateTimer(0.0, DeleteOverlay, i);
		num = GetNum();
		if(IsClientTarget(i))
			ShowOverlay(i,g_Overlay[num],0.0);
	}
	
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon) 
{
	int ioverlay = FindSpecOverlayOwner(client);
	if(ioverlay == -1 || OId[client] == ioverlay)
		return;

	CreateTimer(0.0, DeleteOverlay, client);
	ShowOverlay(client,g_OwnerOverlay[ioverlay][OverlayPath],0.0);
	OId[client] = ioverlay;
}

LoadOverlay()
{
	Overlays = 0;
	OwnersOverlays = 0;
	
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath,PLATFORM_MAX_PATH, "configs/overlay.cfg");
	if (!FileExists(szPath))
		SetFailState("Couldn't find file: %s", szPath);
	
	KeyValues kConfig = new KeyValues("");
	kConfig.ImportFromFile(szPath);
	kConfig.JumpToKey("overlay");
	kConfig.GotoFirstSubKey();
	
	do {
		char buffer[32];
		kConfig.GetString("owner", buffer, 64);
		if(!StrEqual(buffer,""))
		{
			
			kConfig.GetString("path", g_Overlay[Overlays], PLATFORM_MAX_PATH);
			PrecacheDecalAnyDownload(g_Overlay[Overlays]);
			Overlays++;
		}
		else
		{
			
			strcopy(g_OwnerOverlay[OwnersOverlays][OverlayOwner],PLATFORM_MAX_PATH,buffer);
			kConfig.GetString("path", g_OwnerOverlay[OwnersOverlays][OverlayPath], PLATFORM_MAX_PATH);
			PrecacheDecalAnyDownload(g_OwnerOverlay[OwnersOverlays][OverlayPath]);
			OwnersOverlays++;
		}
		
	} while (kConfig.GotoNextKey())
}

stock int GetNum()
{
	if(num > Overlays)
		num = 1;
	else
		num++;
	return num;
}

stock bool IsValidClient( int client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( IsFakeClient(client)) return false;
	return true;
}

stock bool IsClientTarget( int client )
{
	if(!IsValidClient(client)) return false;
	if(GetClientTeam(client) != 1) return false;
	if(IsLookingASpecial[client]) return false;
	return true;
}

int FindSpecOverlayOwner( int client )
{
	int iTarget = GetEntPropEnt(client, Prop_Data, "m_hObserverTarget");
	if( GetEntProp(client, Prop_Data, "m_iObserverMode") != 7 && GetClientTeam(client) != 1)
	{
		if(iTarget == client && !IsValidClient(iTarget))
		{
			IsLookingASpecial[client] = false;
			return -1;
		}
		
		char g_szAuth[32];
		GetClientAuthId(iTarget, AuthId_Steam2, g_szAuth, sizeof(g_szAuth));
		
		for (int i = 0; i < OwnersOverlays; i++)
		{
	
			if(StrEqual(g_szAuth,g_OwnerOverlay[i][OverlayOwner]))
			{
				IsLookingASpecial[client] = true;
				return i;
			}
		}
	}
	IsLookingASpecial[client] = false;
	return -1;
}