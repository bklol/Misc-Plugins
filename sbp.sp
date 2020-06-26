  
#include <sourcemod>
#include <PTaH>
#include <httppost>
#include <pugsetup>

char g_szAuth[MAXPLAYERS + 1][32];
char demo[128];

int report[MAXPLAYERS + 1];

bool Isreport[MAXPLAYERS + 1];
bool Bereport[MAXPLAYERS + 1];

public void OnPluginStart()
{
    PTaH(PTaH_ExecuteStringCommandPre, Hook, ExecuteStringCommand);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPostAdminCheck(i);
	}
	RegConsoleCmd("sm_report",command_report);
}

public void OnClientPostAdminCheck(int client)
{
	if (!GetClientAuthId(client, AuthId_Steam2, g_szAuth[client], sizeof(g_szAuth)))
	{
		KickClient(client, "Verification problem, Please reconnect");
		return;
	}
	Isreport[client] = false;
}

public Action ExecuteStringCommand(int client, char sCommandString[512]) 
{
    if (IsValidClient(client))
    {
        char message[512];
        strcopy(message, sizeof(message), sCommandString);
        TrimString(message);
        if(StrContains(message, "sm ") == 0 || StrEqual(message, "sm", false))
        {
			PrintToConsole(client,"bbs.nc0.top\n");
            return Plugin_Handled;
        }
        
        if(StrContains(message, "meta ") == 0 || StrEqual(message, "meta", false))
        {
			PrintToConsole(client,"bbs.nc0.top\n");
            return Plugin_Handled;
        }
		
		if(StrContains(message, "status") == 0 || StrEqual(message, "status", false))
        {
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					char buffer[128];
					Format(buffer,sizeof(buffer), "32ID:%s		玩家ID:%N",g_szAuth[i],i); 
					PrintToConsole(client,buffer); 
				}
			}
            return Plugin_Handled;
        }
		
    }
    return Plugin_Continue; 
}

public Action command_report(int client,int args)
{
	if(!PugSetup_IsMatchLive())
	{
		PrintToChat(client,"只有在比赛过程中才能举报");
		return;
	}
	Menu menu = new Menu(MenuHandler_Player);
	SetMenuTitle(menu, "选择举报对象\n善用功能,滥用或瞎几把用将导致自己被封禁");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i)&&i != client)
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
public OnClientDisconnect(int client)
{
	Isreport[client] = false;
	Bereport[client] = false;
	report[client] = -1;
}
public int MenuHandler_Player(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, item, info, sizeof(info));
			int customclient = StringToInt(info);
			if(Bereport[customclient])
			{
				PrintToChat(client,"该玩家在本场比赛中已经被举报过了！");
				return;
			}
			Isreport[client] = true;
			report[client] = customclient;
			PrintToChat(client,"请在聊天栏输入举报理由(请仔细并完整的填写),回车确认，或者输入-1取消举报");
		}
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] szArgs)
{
	if (Isreport[client])
	{
		if(!StrEqual(szArgs,"-1"))
		{
			Bereport[report[client]] = true;
			char buffer[1024],hostname[128];
			GetConVarString(FindConVar("hostname"), hostname,sizeof(hostname));
			Format(buffer,sizeof(buffer),"玩家<%i>%N,举报了玩家<%i>%N,原因:%s,服务器%s,当场比赛demo:%s",
			g_szAuth[client],client,g_szAuth[report[client]],report[client],szArgs,hostname,demo);
			HTTP_PostMsg("1107984504",buffer,1);
		}
		else
		{
			PrintToChat(client, "取消了举报");
		}
		
		Isreport[client]=!Isreport[client];
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void PugSetup_OnStartRecording(char[] demoName)
{
	strcopy(demo,sizeof(demo),demoName);
}

stock bool IsValidClient( int client )
{
	
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( IsFakeClient( client )) return false;
	return true;
}