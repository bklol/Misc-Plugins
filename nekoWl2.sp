#include <sourcemod>
Database g_dDatabase = null;

char g_szAuth[MAXPLAYERS + 1][32];

public void OnPluginStart()
{
	SQL_MakeConnection();
}

int checkPlayerlive()
{
	int num = 0;
	char playerName[64];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			GetClientName(i, playerName, 64);
			if(StrEqual(playerName,"GOTV"))
				num--;
			num++;
		}
	}
	return num;
}

public void OnClientPostAdminCheck(int client)
{
	
	if (!GetClientAuthId(client, AuthId_Steam2, g_szAuth[client], sizeof(g_szAuth)))
	{
		KickClient(client, "Verification problem, Please reconnect");
		return;
	}
	
	if(!IsValidClient(client))
		return;
	
	if( CheckCommandAccess(client, "", ADMFLAG_KICK) ) return;
	
	if( checkPlayerlive() > 10 )
	{
		char szQuery[512];
		FormatEx(szQuery, sizeof(szQuery), "SELECT `authId` FROM `vipUsers` WHERE auth = '%s'",g_szAuth[client]);
		g_dDatabase.Query(SQL_FetchVIPUser_CB, szQuery, GetClientSerial(client));
		return;
	}
	
	if( checkPlayerlive() > 11 )
		KickClient(client, "很抱歉,服务器已满");
	
}

public void SQL_FetchVIPUser_CB(Database db, DBResultSet results, const char[] error, any data)
{
	int iClient = GetClientFromSerial(data);
	if (results.FetchRow())
	{
		return;
		
	}
	else
	{
		KickClient(iClient, "很抱歉,服务器已满，请购买vip来获得专属通道");
	}
}

void SQL_MakeConnection()
{
	if (g_dDatabase != null)
		delete g_dDatabase;
	char szError[512];
	g_dDatabase = SQL_Connect("vip", true, szError, sizeof(szError));
	if (g_dDatabase == null)
	{
		SetFailState("Cannot connect to datbase error: %s", szError);
	}
}

stock bool IsValidClient( client )
{
	
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( IsFakeClient( client )) return false;
	return true;
}
