#include <sourcemod>
#include <PTaH>
#include <ripext>

char g_szAuth2[MAXPLAYERS + 1][32];
char g_szAuth64[MAXPLAYERS + 1][32];
char ConnType[MAXPLAYERS + 1][32];

public Plugin myinfo = {
    name = "another status",
    author = "neko aka bklol",
    description = "change csgo status",
    version = "0.1",
    url = "https://github.com/bklol"
};

public void OnPluginStart()
{
	PTaH(PTaH_ExecuteStringCommandPre, Hook, ExecuteStringCommand);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPostAdminCheck(i);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if(!IsValidClient(client))
		return;

	GetClientAuthId(client, AuthId_Steam2, g_szAuth2[client], sizeof(g_szAuth2));
	GetClientAuthId(client, AuthId_SteamID64, g_szAuth64[client], sizeof(g_szAuth64));
	
	char endpoint[128];
	Format(endpoint,sizeof(endpoint),"isOnline?steamIds=%s",g_szAuth64[client]);
	HTTPClient httpClient = new HTTPClient("http://csgo.wanmei.com/api-user");
	httpClient.Get(endpoint,ConnTypeCallBack,client);
}

public void ConnTypeCallBack(HTTPResponse response, int client)
{
	if (response.Status != HTTPStatus_OK) 
	{
		LogError("Http Get error error, %d", response.Status);
		return;
	}
	if (response.Data == null) 
	{
		LogError("Http Get No response");
		return;
	}
	ParseData (view_as<JSONObject>(response.Data),client);
}

public void ParseData(JSONObject Data,int client)
{
	char status[32];
	Data.GetString("status",status, sizeof(status));
	if(!StrEqual(status,"success"))
	{
		ConnType[client] = "false";
		return;
	}
	JSONObject Datas = view_as<JSONObject>(Data.Get("result"));
	Datas.GetString(g_szAuth64[client], ConnType[client], sizeof(ConnType));
	if(StrEqual(ConnType[client],"online"))
		ConnType[client] = "国服";
	else
		ConnType[client] = "国际";
}

public Action ExecuteStringCommand(int client, char sCommandString[512]) 
{
    if (IsValidClient(client))
    {
		char message[512];
		strcopy(message, sizeof(message), sCommandString);
		TrimString(message);
		if(StrContains(message, "status") == 0 || StrEqual(message, "status", false))
        {
			PrintToConsole(client,"Plugin Auth NEKO, AKA BKlol");
			PrintToConsole(client, "---------------------------------------------------------------------------------------");
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					char buffer[1280];
					Format(buffer,sizeof(buffer), "32ID:%s  64ID:%s  在线模式:%s  玩家ID:%N ",g_szAuth2[i], g_szAuth64[i], ConnType[i], i);
					PrintToConsole(client, buffer); 
				}				
			}
			PrintToConsole(client, "---------------------------------------------------------------------------------------");
			return Plugin_Handled;
        }
		
    }
    return Plugin_Continue; 
}

stock bool IsValidClient( int client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( IsFakeClient( client )) return false;
	return true;
}
