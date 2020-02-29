#include <sourcemod>
Database g_dDatabase = null;
char g_szAuth[MAXPLAYERS + 1][32];
char g_szMapPrefix[2][32];
char g_szMapName[128];
bool IsKZ;
ConVar g_slots;
public void OnPluginStart()
{
	g_slots = CreateConVar("sm_slots","0","Number of  player slots, if slots feature disabled , input 0");
	AutoExecConfig(true, "NekoWhiteList");
	SQL_MakeConnection();
}
public void OnMapStart()
{
	GetCurrentMap(g_szMapName, 128);
	ExplodeString(g_szMapName, "_", g_szMapPrefix, 2, 32);
	if(StrEqual(g_szMapPrefix[0],"kz")||StrEqual(g_szMapPrefix[0],"bkz")||StrEqual(g_szMapPrefix[0],"xc")||StrEqual(g_szMapPrefix[0],"skz"))
		IsKZ=true;
	else
		IsKZ=false;
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
public void OnClientPostAdminCheck(int client)
{
	if (!GetClientAuthId(client, AuthId_Steam2, g_szAuth[client], sizeof(g_szAuth)))
	{
		KickClient(client, "Verification problem, Please reconnect");
		return;
	}
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "SELECT `authId` FROM `vipUsers` WHERE auth = '%s'",g_szAuth[client]);
	g_dDatabase.Query(SQL_FetchVIPUser_CB, szQuery, GetClientSerial(client));
}
public void SQL_FetchVIPUser_CB(Database db, DBResultSet results, const char[] error, any data)
{
	int iClient = GetClientFromSerial(data);
	if (results.FetchRow())
		return;
	else
	{
		if(IsKZ)
			SQL_FetchKZWhiteListPlayer(iClient);
		else
			ServerIsFullKickSB(iClient);
	}
}
void SQL_FetchKZWhiteListPlayer(int client)
{
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "SELECT `authId` FROM `KZplayerWhiteList` WHERE auth = '%s'",g_szAuth[client]);
	g_dDatabase.Query(SQL_FetchKZWhiteListPlayer_CB, szQuery, GetClientSerial(client));
}
public void SQL_FetchKZWhiteListPlayer_CB(Database db, DBResultSet results, const char[] error, any data)
{
	int iClient = GetClientFromSerial(data);
	if (results.FetchRow())
		return;
	else
		ServerIsFullKickSB(iClient);
}
ServerIsFullKickSB(int client)
{
	int reserved = g_slots.IntValue;
	int InGamePlayers = GetClientCount(false);
	int limit = GetMaxHumanPlayers() - reserved;
	if(limit<InGamePlayers)
		KickClient(client, "很抱歉,服务器已满，请购买vip来获得专属通道");
}
