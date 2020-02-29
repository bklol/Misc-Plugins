#include <sourcemod>

char g_szAuth[MAXPLAYERS + 1][32];
Database g_dDatabase = null;
Handle CVAR_ServerTag;
public OnPluginStart()
{
	CVAR_ServerTag = CreateConVar("sm_server_tag", "xxxxx", "SERVER TAG");
	AutoExecConfig(true, "nekoadmins");
	SQL_MakeConnection();
}
void SQL_MakeConnection()
{
	
	char szError[512];
	g_dDatabase = SQL_Connect("crossserver", true, szError, sizeof(szError));
	if (g_dDatabase == null)
	{
		SetFailState("Cannot connect to datbase error: %s", szError);
	}
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
	FormatEx(szQuery, sizeof(szQuery), "SELECT * FROM `admins` WHERE `authid` = '%s'",g_szAuth[client]);
	g_dDatabase.Query(SQL_FetchUser_CB, szQuery, GetClientSerial(client));
}
public void SQL_FetchUser_CB(Database db, DBResultSet results, const char[] error, any data)
{		
	char szFlags[32],szServers[64],serverTag[32],Exptime[32];
	int iClient = GetClientFromSerial(data);
	GetConVarString(CVAR_ServerTag, serverTag, sizeof(serverTag));
	if (results.FetchRow())
	{
		results.FetchString(1,szFlags,sizeof(szFlags));
		results.FetchString(2,szServers,sizeof(szServers));
		results.FetchString(3,Exptime,sizeof(Exptime));
		int now=GetTime();
		int Expt=StringToInt(Exptime)-now;
		if(StrContains(szServers,serverTag)!=-1&&!StrEqual(szServers, "")||StrEqual(szServers, "all"))
		{
			if(Expt>0||StrEqual(Exptime, ""))
			{
				if (!StrEqual(szFlags, ""))
				{
					int iFlags = ReadFlagString(szFlags);
					int iPlayerFlags = GetUserFlagBits(iClient);
					bool bFlags[AdminFlags_TOTAL];
					bool bPlayerFlags[AdminFlags_TOTAL];
					bool bNewFlags[AdminFlags_TOTAL];				
					FlagBitsToBitArray(iFlags, bFlags, AdminFlags_TOTAL);
					FlagBitsToBitArray(iPlayerFlags, bPlayerFlags, AdminFlags_TOTAL);				
					for (int i = 0; i < AdminFlags_TOTAL; i++)
					{
						if (bPlayerFlags[i] || bFlags[i])
						bNewFlags[i] = true;
					}
					int iNewFlags = FlagBitArrayToBits(bNewFlags, AdminFlags_TOTAL)
					SetUserFlagBits(iClient, iNewFlags);
				}
			}
		}
	}
}


	

