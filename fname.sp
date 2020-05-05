#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>

Database g_dDatabase = null;

char g_szAuth[MAXPLAYERS + 1][32];
char FakeName[MAXPLAYERS + 1][128];
bool IsChangeName[MAXPLAYERS + 1];

public void OnPluginStart() 
{
   RegConsoleCmd("sm_gn", ChangeName);
   SQL_MakeConnection();
}

public void OnClientPostAdminCheck(int client)
{
	if (!GetClientAuthId(client, AuthId_Steam2, g_szAuth[client], sizeof(g_szAuth)))
	{
		KickClient(client, "Verification problem, Please reconnect");
		return;
	}
	
	SQL_FetchUser(client);
	
}

void SQL_FetchUser(int client)
{
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "SELECT `name` FROM `name` WHERE `authId` = '%s'", g_szAuth[client]);
	g_dDatabase.Query(SQL_FetchUser_CB, szQuery, GetClientSerial(client));
}

public void SQL_FetchUser_CB(Database db, DBResultSet results, const char[] error, any data)
{
	int iClient = GetClientFromSerial(data);
	
	if(results.FetchRow())
		results.FetchString(0, FakeName[iClient], sizeof(FakeName));
	else
		SQL_RegisterPerks(iClient);
	
}

void SQL_RegisterPerks(int client)
{
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `name` (`authId`,`name`) VALUES ('%s','用户名审核中')",g_szAuth[client]);
	FakeName[client]="用户名审核中";
	g_dDatabase.Query(SQL_CheckForErrors, szQuery);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] szArgs)
{
	if (IsChangeName[client])
	{
		if(!StrEqual(szArgs,"-1"))
		{
			strcopy(FakeName[client], sizeof(FakeName), szArgs);
			char szQuery[512];
			FormatEx(szQuery, sizeof(szQuery), "UPDATE `name` SET `name` = '%s' WHERE `authId` = '%s'", szArgs, g_szAuth[client]);
			g_dDatabase.Query(SQL_CheckForErrors, szQuery);
			PrintToChat(client, "成功改名为 \x02%s\x01.", szArgs);
		}
		else
		{
			PrintToChat(client, "取消了改名");
		}
		
		IsChangeName[client]=!IsChangeName[client];
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void SQL_MakeConnection()
{
	if (g_dDatabase != null)
		delete g_dDatabase;
	
	char szError[512];
	g_dDatabase = SQL_Connect("fname", true, szError, sizeof(szError));
	if (g_dDatabase == null)
	{
		SetFailState("Cannot connect to datbase error: %s", szError);
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPostAdminCheck(i);
	}
}

public Action ChangeName(client, args)
{
	PrintToChat(client,"请在聊天栏输入新名字,输入-1取消改名");
	IsChangeName[client]=!IsChangeName[client];
}

public OnGameFrame()
{
    for (new i = MaxClients; i > 0; --i)
    {
        if(IsValidClient(i))
			SetClientName(i, FakeName[i]);       
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

public void SQL_CheckForErrors(Database db, DBResultSet results, const char[] error, any data)
{	
	
	if (!StrEqual(error, ""))
	{
		LogError("Databse error, %s", error);
		return;
	}
}