#include <sdktools>
#include <sourcemod>
#include <chat-processor>

#pragma newdecls required

bool g_bUse4Name[MAXPLAYERS+1];
bool g_bUse4Message[MAXPLAYERS+1];
char g_szAuth[MAXPLAYERS + 1][128];

public Plugin myinfo = 
{
	name		= "Simple Rainbow Chat",
	author		= "Kyle & edit by neko",
	description	= "Rainbow chat",
	version		= "1.1",
	url			= "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	
	RegConsoleCmd("sm_rn", Command_Name);
	RegConsoleCmd("sm_rm", Command_Message);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
			OnClientPostAdminCheck(i);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (!GetClientAuthId(client, AuthId_Steam2, g_szAuth[client], sizeof(g_szAuth)))
	{
		KickClient(client, "Verification problem, Please reconnect");
		return;
	}
	
	g_bUse4Name[client] = false;
	g_bUse4Message[client] = false;
	
	if(CheckClient(client) >= 1)
	{
		SetHudTextParams(-1.0, 0.1, 7.0, 255, 255, 150, 255, 2, 6.0, 0.1, 0.2);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				ShowHudText(i, 0, "[捐赠天使] %N 已连接 ", client);
			}
		}
	}
	
	if(CheckClient(client) >= 2)
	{
		g_bUse4Name[client] = true;
	}
	
	if(CheckClient(client) >= 3)
	{
		g_bUse4Message[client] = true;
	}
	
}


int CheckClient(int client)
{
	char lineBuffer[128],sBuffer[2][32];
	Handle fileHandle = OpenFile("addons/sourcemod/configs/donate.txt","r");
	while(!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, lineBuffer, sizeof(lineBuffer)))
	{
		ExplodeString(lineBuffer, "#", sBuffer,sizeof(sBuffer),sizeof(sBuffer[]));

		if(StrEqual(g_szAuth[client],sBuffer[0]))
		{
			int bz = StringToInt(sBuffer[1]);
			return bz;
		}
	}
	return -1;
}

public Action Command_Name(int client, int args)
{
	if(CheckClient(client) >= 2)
	{
		g_bUse4Name[client] = !g_bUse4Name[client];
		PrintToChat(client, "[SM] rainbow name is %s", g_bUse4Name[client] ? "开启" : "关闭");
		return Plugin_Handled;
	}
	PrintToChat(client, "[SM]  只限当前赛季捐赠者使用");
	return Plugin_Handled;
	
}

public Action Command_Message(int client, int args)
{
	if(CheckClient(client) >= 3)
	{
		g_bUse4Message[client] = !g_bUse4Message[client];
		PrintToChat(client, "[SM] rainbow message is %s", g_bUse4Message[client] ? "开启" : "关闭");
		return Plugin_Handled;
	}
	PrintToChat(client, "[SM]  只限当前赛季捐赠者使用");
	return Plugin_Handled;
	
}

public Action CP_OnChatMessage(int& client, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool &processcolors, bool &removecolors)
{
	Action result = Plugin_Continue;

	if(g_bUse4Name[client])
	{
		char tag[32];
		String_Rainbow("[捐赠天使]", tag, 32);
		Format(name, 128,"%s%s",tag,name);
		result = Plugin_Changed;
	}
	
	if(g_bUse4Message[client])
	{
		char newmsg[256];
		String_Rainbow(message, newmsg, 256);
		strcopy(message, 256, newmsg);
		result = Plugin_Changed;
	}

	return result;
}

void String_Rainbow(const char[] input, char[] output, int maxLen)
{
	int bytes, buffs;
	int size = strlen(input)+1;
	char[] copy = new char [size];

	for(int x = 0; x < size; ++x)
	{
		if(input[x] == '\0')
			break;
		
		if(buffs == 2)
		{
			strcopy(copy, size, input);
			copy[x+1] = '\0';
			output[bytes] = RandomColor();
			bytes++;
			bytes += StrCat(output, maxLen, copy[x-buffs]);
			buffs = 0;
			continue;
		}

		if(!IsChar(input[x]))
		{
			buffs++;
			continue;
		}

		strcopy(copy, size, input);
		copy[x+1] = '\0';
		output[bytes] = RandomColor();
		bytes++;
		bytes += StrCat(output, maxLen, copy[x]);
	}

	output[++bytes] = '\0';
}

bool IsChar(char c)
{
	if(0 <= c <= 126)
		return true;
	
	return false;
}

int RandomColor()
{
	switch(GetRandomInt(5, 16))
	{
		case  1: return '\x01';
		case  2: return '\x02';
		case  3: return '\x03';
		case  4: return '\x04';
		case  5: return '\x05';
		case  6: return '\x06';
		case  7: return '\x07';
		case  8: return '\x08';
		case 9: return '\x09';
		case 10: return '\x10';
		case 11: return '\x0A';
		case 12: return '\x0B';
		case 13: return '\x0C';
		case 14: return '\x0E';
		case 15: return '\x0F';
		default: return '\x01';
	}
}

stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client))
	{
		return false;
	}
	return IsClientInGame(client);
}