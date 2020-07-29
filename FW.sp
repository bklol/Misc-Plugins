#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>

Database g_dDatabase = null;

char g_szAuth[MAXPLAYERS + 1][32];
bool IsFW[MAXPLAYERS + 1];

bool IsAddToken[MAXPLAYERS + 1];

int g_iDaysLeft[MAXPLAYERS + 1];


public void OnPluginStart()
{
	RegConsoleCmd("sm_fw", fw);
	SQL_MakeConnection();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPostAdminCheck(i);
	}
	HookEvent("round_end", round_end);
}

public Action round_end(Event event, const char[] name, bool dontBroadcast)
{

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && IsFW[i])
			GiveMoney(i);
	}
}

void GiveMoney(int client)
{
	SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount") + 8888);
	PrintToChat(client,"您由于是富翁，经济 + 8888");
}

public Action fw(client, args)
{
	PrintToChat(client,"输入你的卡密或输入-1取消");
	IsAddToken[client]=!IsAddToken[client];
}

public void OnClientPostAdminCheck(int client)
{
	if (!GetClientAuthId(client, AuthId_Steam2, g_szAuth[client], sizeof(g_szAuth)))
	{
		KickClient(client, "Verification problem, Please reconnect");
		return;
	}
	IsAddToken[client] = false;
	IsFW[client] = false;
	SQL_FetchUser(client);
}

void SQL_FetchUser(int client)
{
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "SELECT `time` FROM `fw_user` WHERE `authid` = '%s'", g_szAuth[client]);
	g_dDatabase.Query(SQL_FetchUser_CB, szQuery, GetClientSerial(client));
}

public void SQL_FetchUser_CB(Database db, DBResultSet results, const char[] error, any data)
{
	int iClient = GetClientFromSerial(data);
	if (results == null)
	{
		if (iClient == 0)
		{
			LogError("Client is not valid. Reason: %s", error);
		}
		else
		{
			LogError("Cant use client data on insert. Reason: %s", error);
		}
		return;
	}
	
	if (results.FetchRow())
	{
		int iStamp = results.FetchInt(0);
		int iDaysLeft = (iStamp - GetTime()) / 86400;
		
		if (iDaysLeft >= 0 || iStamp == -1)
		{
			g_iDaysLeft[iClient] = iDaysLeft;
			IsFW[iClient] = true;
		}
		else
		{
			char szQuery[512];
			FormatEx(szQuery, sizeof(szQuery), "DELETE FROM `fw_user` WHERE `authid` = '%s'",  g_szAuth[iClient]);
			g_dDatabase.Query(SQL_CheckForErrors, szQuery, GetClientSerial(iClient));
			g_iDaysLeft[iClient] = 0;
			PrintToChat(iClient,"您的富翁卡到期了哦");
		}
	}
	g_iDaysLeft[iClient] = 0;

}

public Action OnClientSayCommand(int client, const char[] command, const char[] szArgs)
{
	if(IsAddToken[client])
	{
		if(!StrEqual(szArgs,"-1"))
		{
			char query[512];
			char szQuery[512];
			Format(query, sizeof(query),"SELECT `day` FROM `fw_code` WHERE `code`='%s'",szArgs);
			g_dDatabase.Query(Sql_CallBack,query,client);
			
			FormatEx(szQuery, sizeof(szQuery), "DELETE FROM `fw_code` WHERE `code` = '%s'",szArgs);
			g_dDatabase.Query(SQL_CheckForErrors, szQuery, client);
		}
		else
		{
			PrintToChat(client, "取消了......\n 请登录www.neko.vip购买富翁卡");
		}
		IsAddToken[client] = false;
	}
}

public void Sql_CallBack(Database db, DBResultSet results, const char[] error, any data)
{
	
	int client = data;
	
	if (results.FetchRow())
	{
		int iDays = results.FetchInt(0);
		if(iDays > 0)
		{
			char szStamp[512];
			char szNewStamp[512];
			Format(szStamp, sizeof(szStamp), "%i", GetTime()+ (iDays * 86400));
			Format(szNewStamp, sizeof(szNewStamp), "%i",  GetTime()+ ((iDays + g_iDaysLeft[client]) * 86400));
			PrintToChat(client, "激活 %i 天\x02%N \x01 富翁卡 ...",iDays,client);
			char szQuery[512];
			if (IsFW[client])
			{
				FormatEx(szQuery, sizeof(szQuery), "UPDATE `fw_user` SET `time` = '%s' WHERE `authid` = '%s'", szNewStamp , g_szAuth[client]);
			}
			else
			{
				FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `fw_user` (`authid`, `time`) VALUES ('%s', '%s' )",g_szAuth[client], szStamp);
			}
			g_dDatabase.Query(SQL_CheckForErrors, szQuery, GetClientSerial(client));
			SQL_FetchUser(client);
			PrintToChat(client, "成功激活 %i 天\x02%N \x01 富翁卡 ",iDays,client);
		}
		if(iDays == -1)
		{
			PrintToChat(client, "激活 \x02%N \x01 永久富翁卡 ...",client);
			char szQuery[512];
			if (IsFW[client])
			{
				FormatEx(szQuery, sizeof(szQuery), "UPDATE `fw_user` SET `time` = '%s' WHERE `authid` = '%s'",  iDays, g_szAuth[client]);			
			}
			else
			{
				FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `fw_user` (`authid`, `time`) VALUES ('%s', '%s')",g_szAuth[client],iDays);
			}
			g_dDatabase.Query(SQL_CheckForErrors, szQuery, GetClientSerial(client));
			SQL_FetchUser(client);
			PrintToChat(client, "成功激活 \x02%N \x01 永久富翁卡 ",client);
		}
	}
	else
	{
		PrintToChat(client, "无效的cdkey\n购买富翁卡:www.neko.vip");
	}
}

void SQL_MakeConnection()
{
	if (g_dDatabase != null)
		delete g_dDatabase;
	
	char szError[512];
	
	g_dDatabase = SQL_Connect("neko", true, szError, sizeof(szError));
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

public void SQL_CheckForErrors(Database db, DBResultSet results, const char[] error, any data)
{	
	
	if (!StrEqual(error, ""))
	{
		LogError("Databse error, %s", error);
		return;
	}
}

stock bool IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	return true;
}
