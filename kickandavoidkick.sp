#include <sourcemod>
#include <cstrike>
#include <sdktools>

bool IsBlocker[MAXPLAYERS+1];
bool IsBlocker2[MAXPLAYERS+1];
char g_sLogs[PLATFORM_MAX_PATH + 1];
char g_szAuth[MAXPLAYERS + 1][128];

public void OnPluginStart() 
{
   RegConsoleCmd("sm_votekick", Command_Kick);
   RegConsoleCmd("sm_vk", Command_Kick);
   RegConsoleCmd("sm_k", Command_Kick);
   //AddCommandListener(CheckVote, "callvote");
}

public void OnClientPostAdminCheck(int client)
{
	IsBlocker[client]=false;
	IsBlocker2[client]=false;
	
	if (!GetClientAuthId(client, AuthId_Steam2, g_szAuth[client], sizeof(g_szAuth)))
	{
		KickClient(client, "Verification problem, Please reconnect");
		return;
	}
	CheckBlockerClient(client);
}

CheckBlockerClient(int client)
{
	char lineBuffer[128];
	Handle fileHandle = OpenFile("addons/sourcemod/configs/vkblock.txt","r");
	while(!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, lineBuffer, sizeof(lineBuffer)))
	{
		if(StrEqual(g_szAuth[client],lineBuffer))
			IsBlocker[client]=true;
	}
}

public Action Command_Kick(int client,int args)
{
	
	if(!IsBlocker[client] && !IsBlocker2[client])
		kickMenu(client);
	
	if(IsBlocker[client])
		PrintToChat(client,"宁由于滥用该功能而被阻止");
	
	if(IsBlocker2[client])
		PrintToChat(client,"发起投票之后有5分钟冷却哦");

}


/**MAY NOT WARK IN CSGO
public Action CheckVote(int client, char[] command, int args)
{
    char s[MAX_NAME_LENGTH];
    if (args >= 2) 
	{
        GetCmdArg(1, s, sizeof(s));
        if (StrContains(s, "ban")!= -1 || StrContains(s, "kick") != -1) 
		{
            GetCmdArg(2, s, sizeof(s));
            int UserId = StringToInt(s);
            if (UserId != 0)
			{
                int target = GetClientOfUserId(UserId);
				if (CheckCommandAccess(target, "", ADMFLAG_GENERIC))
					return Plugin_Stop;
            }
        }
    }
	return Plugin_Continue;
}
**/


void kickMenu(int client)
{

	Menu menu = new Menu(MenuHandler_PlayerEdit);
	SetMenuTitle(menu, "Select player");
	menu.AddItem("1",	"踢出挂机玩家");
	menu.AddItem("2",	"踢出疑似作弊玩家");
	menu.Display(client, 0);

}

public int MenuHandler_PlayerEdit(Menu menu, MenuAction action, int client,int itemNum)
{
	if (action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0:
			{
				kickMenu2(client);
			}
			case 1:
			{
				kickMenu3(client);
			}
		}
	}
}

void kickMenu2(int client)
{

	Menu menu = new Menu(MenuHandler_Playerkick);
	SetMenuTitle(menu, "Select player");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			char username[MAX_NAME_LENGTH];
			char userid[4];
			GetClientName(i, username, sizeof(username));
			IntToString(i, userid, sizeof(userid));
			menu.AddItem(userid, username);
		}
	}
	
	menu.Display(client, 0);

}

void kickMenu3(int client)
{

	Menu menu = new Menu(MenuHandler_Playerban);
	SetMenuTitle(menu, "Select player");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			char username[MAX_NAME_LENGTH];
			char userid[4];
			GetClientName(i, username, sizeof(username));
			IntToString(i, userid, sizeof(userid));
			menu.AddItem(userid, username);
		}
	}
	menu.Display(client, 0);
}

public int MenuHandler_Playerkick(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			char username[MAX_NAME_LENGTH];
			GetMenuItem(menu, item, info, sizeof(info));
			int customclient = StringToInt(info);
			GetClientName(customclient, username, sizeof(username));
			if(!CheckCommandAccess(customclient, "", ADMFLAG_GENERIC))
				ServerCommand("sm_votekick %s",username);
			else
			{
				ServerCommand("sm_votekick %s",client);
				PrintToChatAll("( ^ω^)")
			}	
			char sDate[18];
			FormatTime(sDate, sizeof(sDate), "%y-%m-%d");
			BuildPath(Path_SM, g_sLogs, sizeof(g_sLogs), "logs/VK-%s.log", sDate);
			LogToFile(g_sLogs, "%N<%s> 投票踢出[AFK] %N<%s>", client,g_szAuth[client],customclient,g_szAuth[customclient]);
			IsBlocker2[client]=true;
			CreateTimer(300.0,ResetClient,client);
		}
	}
}

public int MenuHandler_Playerban(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			char username[MAX_NAME_LENGTH];
			GetMenuItem(menu, item, info, sizeof(info));
			int customclient = StringToInt(info);
			GetClientName(customclient, username, sizeof(username));
			if(!CheckCommandAccess(customclient, "", ADMFLAG_GENERIC))
				ServerCommand("sm_voteban %s 10",username);
			else
			{
				ServerCommand("sm_voteban %s 10",client);
				PrintToChatAll("( ^ω^)")
			}
			char sDate[18];
			FormatTime(sDate, sizeof(sDate), "%y-%m-%d");
			BuildPath(Path_SM, g_sLogs, sizeof(g_sLogs), "logs/VK-%s.log", sDate);
			LogToFile(g_sLogs, "%N<%s> 投票踢出[Hack] %N<%s>", client,g_szAuth[client],customclient,g_szAuth[customclient]);
			IsBlocker2[client]=true;
			CreateTimer(300.0,ResetClient,client);
		}
	}
}

public Action ResetClient(Handle timer,int client)
{
	IsBlocker2[client]=false;
}

stock bool IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	//if ( IsFakeClient(client)) return false;
	return true;
}