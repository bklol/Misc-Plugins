#include <sourcemod>
#include <SteamWorks>
#include <store>

#define iGroupID 36176394

ConVar	PlayerCredits,
		SpecCredits,
		CreditsTime;
		
Handle	TimeAuto = null;
bool	b_IsMember[MAXPLAYERS+1],
		i_advert[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "neko Steam Group Credits",
	author = "neko"
};

public void OnPluginStart()
{
	//Configs
	PlayerCredits = CreateConVar("sm_group_credits", "60", "Credits to give per X time, if player is in group.", FCVAR_NOTIFY);
	SpecCredits = CreateConVar("sm_group_spec_credits", "10", "Spectate Credits to give per X time, if player is in group and spectate.", FCVAR_NOTIFY);
	CreditsTime = CreateConVar("sm_group_credits_time", "600", "Time in seconds to deal credits.", FCVAR_NOTIFY);
	
	//Don't Touch
	HookConVarChange(CreditsTime, Change_CreditsTime);
	AutoExecConfig(true, "nekosteamgroupcredits");
}

public void OnMapStart()
{
	TimeAuto = CreateTimer(CreditsTime.FloatValue, CheckPlayers, _, TIMER_REPEAT);
}

public Action CheckPlayers(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		addcredits(i);
	}
	return Plugin_Continue;
}

void addcredits(int client)
{
	if(IsClientInGame(client) && b_IsMember[client]) 
	{
		//Get Player Credit Buffer!
		int pcredits = PlayerCredits.IntValue;
		
		//If spectate set new value of credits
		if(GetClientTeam(client) == 1) pcredits = SpecCredits.IntValue;
		
		//Give Credits
		Store_SetClientCredits(client, Store_GetClientCredits(client) + pcredits);
		//Print to client
		if(i_advert[client])
		{
			PrintToChat(client, "\x06你由于成为\x08社区组\x06一员而获得了额外 \x04%i\x01 积分 !", pcredits);
		}
	}
	else if(!b_IsMember[client])
	{
		PrintToChat(client,"​\x06通过加入\x04社区官方组\x06来获得在服务器\x08额外的\x06游玩积分!");
		PrintToChat(client,"\x06社区官方组链接:\x04https://steamcommunity.com/groups/nekoservers");
	}
}

public void OnClientPostAdminCheck(int client)
{
	i_advert[client] = true;
	b_IsMember[client] = false;
	SteamWorks_GetUserGroupStatus(client,iGroupID);
}

public int SteamWorks_OnClientGroupStatus(int authid, int groupAccountID, bool isMember, bool isOfficer)
{
	int client = UserAuthGrab(authid);
	if (client != -1 && isMember)
	{
		b_IsMember[client] = true;
	}
	return;
}

int UserAuthGrab(int authid)
{
	char charauth[64], authchar[64];
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientAuthId(i, AuthId_Steam3, charauth, sizeof(charauth)))
		{
			IntToString(authid, authchar, sizeof(authchar));
			if(StrContains(charauth, authchar) != -1)
			{
				return i;
			}
		}
	}
	
	return -1;
}

public void Change_CreditsTime(Handle cvar, const char[] oldVal, const char[] newVal)
{
	delete TimeAuto;
	TimeAuto = CreateTimer(CreditsTime.FloatValue, CheckPlayers, _, TIMER_REPEAT);
}
