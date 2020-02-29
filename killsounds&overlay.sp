#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <overlays>

#define Killone "overlays/kill/kill_1"
#define Killtwo "overlays/kill/kill_2"
#define Killthree "overlays/kill/kill_3"
#define Killfour "overlays/kill/kill_4"
#define Killfive "overlays/kill/kill_5"

int TotKills =0;
int g_Kills[MAXPLAYERS + 1];

int g_szAboutStrat = 0;
int g_szStrat = 0;
int g_szFristBlood = 0;
int g_szDoubleKill = 0;
int g_szTripleKill = 0;
int g_szUltraKill = 0;
int g_szRampage = 0;
int g_szKillingSpree = 0;
int g_szDominating = 0;
int g_szMegaKill = 0;
int g_szUnstoppable = 0;
int g_szWickedSick = 0;


char g_szAboutStratSounds[10][PLATFORM_MAX_PATH + 1];

char g_szStratSounds[10][PLATFORM_MAX_PATH + 1];

char g_szFristBloodSounds[10][PLATFORM_MAX_PATH + 1];

char g_szDoubleKillSounds[10][PLATFORM_MAX_PATH + 1];

char g_szTripleKillSounds[10][PLATFORM_MAX_PATH + 1];

char g_szUltraKillSounds[10][PLATFORM_MAX_PATH + 1];

char g_szRampageSounds[10][PLATFORM_MAX_PATH + 1];

char g_szKillingSpreeSounds[10][PLATFORM_MAX_PATH + 1];

char g_szDominatingSounds[10][PLATFORM_MAX_PATH + 1];

char g_szMegaKillSounds[10][PLATFORM_MAX_PATH + 1];

char g_szUnstoppableSounds[10][PLATFORM_MAX_PATH + 1];

char g_szWickedSickSounds[10][PLATFORM_MAX_PATH + 1];

ConVar IsEnemies;


public OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart)
    HookEvent("player_death", Event_PlayerDeath)
}

public void OnMapStart()
{
	LoadSounds();
	PrecacheDecalAnyDownload(Killone);
	PrecacheDecalAnyDownload(Killtwo);
	PrecacheDecalAnyDownload(Killthree);
	PrecacheDecalAnyDownload(Killfour);
	PrecacheDecalAnyDownload(Killfive);
	IsEnemies = FindConVar("mp_teammates_are_enemies");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
			g_Kills[i] = 0;
        }
    }
	CreateTimer(0.1,Ssound);
	TotKills=0;
}
public Action Ssound(Handle timer)
{
	int i=GetRandomInt(0,g_szStrat-1);
	for(new a = 1; a <= MaxClients; a++)
    {
        if(IsClientInGame(a))
        {
			EmitSoundToClient(a,g_szStratSounds[i]);
        }
    }
	
	
}

LoadSounds()
{
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath,PLATFORM_MAX_PATH, "configs/killsounds.txt");
	if (!FileExists(szPath))
		SetFailState("Couldn't find file: %s", szPath);
	
	KeyValues kConfig = new KeyValues("");
	kConfig.ImportFromFile(szPath);
	kConfig.JumpToKey("Sounds");
	kConfig.GotoFirstSubKey();
	
	
	do {
		char buffer[255];
		char Sbuffer[PLATFORM_MAX_PATH];
		kConfig.GetString("kind",buffer,255);
		kConfig.GetString("voice", Sbuffer, PLATFORM_MAX_PATH);
		if(StrEqual(buffer,"aboutstart"))
		{
			strcopy(g_szAboutStratSounds[g_szAboutStrat],PLATFORM_MAX_PATH, Sbuffer);
			PrecacheSound(g_szAboutStratSounds[g_szAboutStrat]);
			g_szAboutStrat++;
		}
		else if(StrEqual(buffer,"Strat"))
		{
			strcopy(g_szStratSounds[g_szStrat],PLATFORM_MAX_PATH, Sbuffer);
			PrecacheSound(g_szStratSounds[g_szStrat]);
			g_szStrat++;
		}
		else if(StrEqual(buffer,"FristBlood"))
		{
			strcopy(g_szFristBloodSounds[g_szFristBlood],PLATFORM_MAX_PATH, Sbuffer);
			PrecacheSound(g_szFristBloodSounds[g_szFristBlood]);
			g_szFristBlood++;
		}
		else if(StrEqual(buffer,"DoubleKill"))
		{
			strcopy(g_szDoubleKillSounds[g_szDoubleKill],PLATFORM_MAX_PATH, Sbuffer);
			PrecacheSound(g_szDoubleKillSounds[g_szDoubleKill]);
			g_szDoubleKill++;
		}
		else if(StrEqual(buffer,"TripleKill"))
		{
			strcopy(g_szTripleKillSounds[g_szTripleKill],PLATFORM_MAX_PATH, Sbuffer);
			PrecacheSound(g_szTripleKillSounds[g_szTripleKill]);
			g_szTripleKill++;
		}
		else if(StrEqual(buffer,"UltraKill"))
		{
			strcopy(g_szUltraKillSounds[g_szUltraKill],PLATFORM_MAX_PATH, Sbuffer);
			PrecacheSound(g_szUltraKillSounds[g_szUltraKill]);
			g_szUltraKill++;
		}
		else if(StrEqual(buffer,"Rampage"))
		{
			strcopy(g_szRampageSounds[g_szRampage],PLATFORM_MAX_PATH, Sbuffer);
			PrecacheSound(g_szRampageSounds[g_szRampage]);
			g_szRampage++;
		}
		else if(StrEqual(buffer,"KillingSpree"))
		{
			strcopy(g_szKillingSpreeSounds[g_szKillingSpree],PLATFORM_MAX_PATH, Sbuffer);
			PrecacheSound(g_szKillingSpreeSounds[g_szKillingSpree]);
			g_szKillingSpree++;
		}
		else if(StrEqual(buffer,"Dominating"))
		{
			strcopy(g_szDominatingSounds[g_szDominating],PLATFORM_MAX_PATH, Sbuffer);
			PrecacheSound(g_szDominatingSounds[g_szDominating]);
			g_szDominating++;
		}
		else if(StrEqual(buffer,"MegaKill"))
		{
			strcopy(g_szMegaKillSounds[g_szMegaKill],PLATFORM_MAX_PATH, Sbuffer);
			PrecacheSound(g_szMegaKillSounds[g_szMegaKill]);
			g_szMegaKill++;
		}
		else if(StrEqual(buffer,"Unstoppable"))
		{
			strcopy(g_szUnstoppableSounds[g_szUnstoppable],PLATFORM_MAX_PATH, Sbuffer);
			PrecacheSound(g_szUnstoppableSounds[g_szUnstoppable]);
			g_szUnstoppable++;
		}
		else if(StrEqual(buffer,"WickedSick"))
		{
			strcopy(g_szWickedSickSounds[g_szWickedSick],PLATFORM_MAX_PATH, Sbuffer);
			PrecacheSound(g_szWickedSickSounds[g_szWickedSick]);
			g_szWickedSick++;
		}

	} while (kConfig.GotoNextKey())
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
    g_Kills[victim] = 0;
    if(attacker > 0 && IsClientInGame(attacker) && attacker != victim)
	{
	if(GetClientTeam(victim) == GetClientTeam(attacker) && IsEnemies.IntValue == 0)
		return;
	else
		g_Kills[attacker]++;
	}
	TotKills++;
	PlaySounds(attacker);
}

PlaySounds(int entity)
{
	
	CreateTimer(0.0, DeleteOverlay, entity);
	switch (g_Kills[entity])
	{
		case 1:
		{
			int i=GetRandomInt(0,g_szFristBlood-1);
			if(TotKills == 1)
			{
				
				for(new a = 1; a <= MaxClients; a++)
				{
					if(IsClientInGame(a))
        				EmitSoundToClient(a,g_szFristBloodSounds[i]);
				}
			}
			ShowOverlay(entity, Killone, 2.5);
		}
		case 2:
		{
			int i=GetRandomInt(0,g_szDoubleKill-1);
			EmitSoundToClient(entity,g_szDoubleKillSounds[i]);
			ShowOverlay(entity, Killtwo, 2.5);
		}
		case 3:
		{
			int i=GetRandomInt(0,g_szTripleKill-1);
			EmitSoundToClient(entity,g_szTripleKillSounds[i]);
			ShowOverlay(entity, Killthree, 2.5);
		}
		case 4:
		{
			int i=GetRandomInt(0,g_szUltraKill-1);
			EmitSoundToClient(entity,g_szUltraKillSounds[i]);
			ShowOverlay(entity, Killfour, 2.5);
		}
		case 5:
		{
			int i=GetRandomInt(0,g_szRampage-1);
			EmitSoundToClient(entity,g_szRampageSounds[i]);
			ShowOverlay(entity, Killfive, 2.5);
		}
		case 6:
		{
			int i=GetRandomInt(0,g_szKillingSpree-1);
			EmitSoundToClient(entity,g_szKillingSpreeSounds[i]);
			
		}
		case 7:
		{
			int i=GetRandomInt(0,g_szDominating-1);
			EmitSoundToClient(entity,g_szDominatingSounds[i]);
			
		}
		case 8:
		{
			int i=GetRandomInt(0,g_szMegaKill-1);
			EmitSoundToClient(entity,g_szMegaKillSounds[i]);
			
		}
		case 9:
		{
			int i=GetRandomInt(0,g_szUnstoppable-1);
			EmitSoundToClient(entity,g_szUnstoppableSounds[i]);
			
		}
		
	}
	if(g_Kills[entity]>9)
	{
		int i=GetRandomInt(0,g_szWickedSick-1);
		EmitSoundToClient(entity,g_szWickedSickSounds[i]);
		
	}
	
}

