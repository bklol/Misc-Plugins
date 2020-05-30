//感谢Kxnrl ranbow color 算法
#include <sourcemod>
#include <chat-processor>
#include <cstrike>

char g_szAuth[MAXPLAYERS + 1][32];
char mesg[MAXPLAYERS + 1][1024];
bool IsChange[MAXPLAYERS + 1];

Database g_dDatabase = null;


public Plugin:myinfo = {
	name = "NEKO connect message",
	author = "NEKO",
	description = "lol",
	version = "0",
	url = "http://www.nicotine.vip"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_cm",Command_Lb);
	SQL_MakeConnection();
}

void SQL_MakeConnection()
{
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
	IsChange[client] = false;
	
	if(CheckCommandAccess(client, "", ADMFLAG_RESERVATION))
		SQL_FetchUser(client);
}

void SQL_FetchUser(int client)
{
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "SELECT * FROM `msg` WHERE `authid` = '%s'",g_szAuth[client]);
	g_dDatabase.Query(SQL_FetchUser_CB, szQuery, GetClientSerial(client));
}

public void SQL_FetchUser_CB(Database db, DBResultSet results, const char[] error, any data)
{
	
	int iClient = GetClientFromSerial(data);
	if (results.FetchRow())
	{
		char name[128];
		GetClientName(iClient, name, sizeof(name));
		
		if(StrContains(mesg[iClient],"{RANDOM}")!=-1)
		{
			results.FetchString(1,mesg[iClient] ,sizeof(mesg));
			ReplaceString(mesg[iClient], sizeof(mesg), "\x01", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "\x02", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "\x03", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "\x04", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "\x05", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "\x06", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "\x07", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "\x08", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "\x09", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "\x10", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "\x0A", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "\x0B", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "\x0C", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "\x0D", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "\x0E", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "\x0F", 		"");
			ReplaceString(mesg[iClient], sizeof(mesg), "{RANDOM}", 	"");
			char newmesssage[256],newname[128];
			String_Rainbow(mesg[iClient],newmesssage, 256);
			String_Rainbow(name,newname, 256);
			strcopy(mesg[iClient], 256, newmesssage);
			strcopy(name, 256, newname);
		}
		PrintToChatAll("玩家\x01%s\x01%s \x02已连接: \x01%s\x01",name,mesg[iClient]);
	}
	else
		SQL_RegisterPerks(iClient);
}

void SQL_RegisterPerks(int client)
{
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `msg` (`authid`,`msg`,`clantag`) VALUES ('%s','')",g_szAuth[client]);

	g_dDatabase.Query(SQL_CheckForErrors, szQuery);
}

public Action Command_Lb(client, args)
{
	if(!CheckCommandAccess(client,"",ADMFLAG_RESERVATION))
	{
		PrintToChat(client,"需要VIP");
		return Plugin_Handled;
	}
	PrintToChat(client,"请在聊天栏输入新的連接提示,输入-1取消");
	IsChange[client]=!IsChange[client];
	return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] szArgs)
{
	if (IsChange[client])
	{
		if(!StrEqual(szArgs,"-1"))
		{
			char szQuery[512], MessageFromClient[512];
			strcopy(MessageFromClient, sizeof(MessageFromClient), szArgs);
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{WHITE}", 		"\x01");
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{DARKRED}", 	"\x02");
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{TEAM}", 		"\x03");
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{GREEN}", 		"\x04");
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{OLIVE}",	 	"\x05");
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{LIME}", 		"\x06");
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{RED}", 		"\x07");
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{GRAY}", 		"\x08");
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{YELLOW}", 	"\x09");
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{GOLD}", 		"\x10");
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{SILVER}", 	"\x0A");
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{BLUE}", 		"\x0B");
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{DARKBLUE}", 	"\x0C");
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{BULEGREY}", 	"\x0D");
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{MAGENTA}", 	"\x0E");
			ReplaceString(MessageFromClient, sizeof(MessageFromClient), "{LIGHTRED}", 	"\x0F");
			FormatEx(szQuery, sizeof(szQuery), "UPDATE `msg` SET `msg`= '%s' WHERE `authid` = '%s'",MessageFromClient,g_szAuth[client]);
			g_dDatabase.Query(SQL_CheckForErrors, szQuery);
			return Plugin_Handled;
			
		}
		else
		{
			PrintToChat(client, "取消了改名");
		}
		IsChange[client]=!IsChange[client];
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void SQL_CheckForErrors(Database db, DBResultSet results, const char[] error, any data)
{	

	if (!StrEqual(error, ""))
	{
		LogError("Databse error, %s", error);
		return;
	}
}


//ranbow color
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
	switch(GetRandomInt(1, 16))
	{
		case  1: return '\x01';
		case  2: return '\x02';
		case  3: return '\x03';
		case  4: return '\x03';
		case  5: return '\x04';
		case  6: return '\x05';
		case  7: return '\x06';
		case  8: return '\x07';
		case  9: return '\x08';
		case 10: return '\x09';
		case 11: return '\x10';
		case 12: return '\x0A';
		case 13: return '\x0B';
		case 14: return '\x0C';
		case 15: return '\x0E';
		case 16: return '\x0F';
		default: return '\x01';
	}
}
