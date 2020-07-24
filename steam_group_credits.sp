#include <sourcemod>
#include <SteamWorks>
#include <store>

#define iGroupID 36176394

bool	b_IsMember[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "neko Steam Group Credits",
	author = "neko"
};

public void OnMapStart()
{
	CreateTimer( 300.0 , CheckPlayers, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE); //地图给积分的时间
}

public Action CheckPlayers(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
			addcredits(i);
	}
}

void addcredits(int client)
{
	if(IsValidClient(client) && b_IsMember[client]) 
	{
		int pcredits = 3; //在玩的加分
		
		if(GetClientTeam(client) == 1) 
			pcredits = 1; //观察的加分
		

		Store_SetClientCredits(client, Store_GetClientCredits(client) + pcredits);
		PrintToChat(client, "\x06您由于\x08是我们社区组的\x06一员而获得了额外的 \x04%i\x01 积分 !", pcredits);
	}
	else if(!b_IsMember[client])
	{
		PrintToChat(client,"​\x06通过加入\x04我们社区官方组\x06来获得在服务器\x08额外的\x06游玩积分!");
		PrintToChat(client,"\x06社区官方组链接:\x04\n https://steamcommunity.com/groups/nekoservers");
	}
}

public void OnClientPostAdminCheck(int client)
{
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

stock bool IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( IsFakeClient(client)) return false;
	return true;
}
