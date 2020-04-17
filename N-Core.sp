#include <sourcemod>
#include <cstrike>

int g_bhops = 0;
int g_kzs = 0;
int g_surfs = 0;
int g_1v1s = 0;
int g_warmods = 0;
int g_practices = 0;

char g_bhoppath[20][PLATFORM_MAX_PATH + 1];
char g_kzpath[20][PLATFORM_MAX_PATH + 1];
char g_1v1path[20][PLATFORM_MAX_PATH + 1];
char g_warmodpath[20][PLATFORM_MAX_PATH + 1];
char g_surfpath[20][PLATFORM_MAX_PATH + 1];
char g_practicpath[20][PLATFORM_MAX_PATH + 1];

char g_szMapPrefix[2][32];
char g_szMapName[128];

bool B_blockround;

bool g_Loaded=false;

public Plugin:myinfo =
{
	name = "[NEKO] Plugin Core",
	author = "NEKO",
	description = "Allows you to enable or disable a plugin by plugins",
	version = "1.0"
};

public void OnPluginStart()
{
	LoadPlugins();
}

public void OnLibraryAdded(const char[] name) {
	g_Loaded = LibraryExists("endisbale");
}

public void OnLibraryRemoved(const char[] name) {
	g_Loaded = LibraryExists("endisbale");
}

public void OnMapStart()
{
	if(!g_Loaded)
		SetFailState("plugin missing");
	DisableAllPlugins();
	
	ExplodeString(g_szMapName, "_", g_szMapPrefix, 2, 32);
	if(StrEqual(g_szMapPrefix[0],"bhop"))
	{
		B_blockround = true;
		for(new a = 0; a <= g_bhops; a++)
		{		
        	ServerCommand("plugins enable %s",g_bhoppath[a]);
		}
	}
	else if(StrEqual(g_szMapPrefix[0],"kz")||StrEqual(g_szMapPrefix[0],"bkz")||StrEqual(g_szMapPrefix[0],"xc"))
	{
		B_blockround = true;
		for(new a = 0; a <= g_kzs; a++)
		{			
        	ServerCommand("plugins enable %s",g_kzpath[a]);
		}
	}
	else if(StrEqual(g_szMapPrefix[0],"surf"))
	{
		B_blockround = true;
		for(new a = 0; a <= g_surfs; a++)
		{			
        	ServerCommand("plugins enable %s",g_surfpath[a]);
		}
	}
	else if(StrEqual(g_szMapPrefix[0],"de"))
	{
		//vote?
		B_blockround = false;
	}
	else
	{
		B_blockround = true;
		for(new a = 0; a <= g_bhops; a++)
		{
        	ServerCommand("plugins enable %s",g_bhoppath[a]);
		}
	}
}

LoadPlugins()
{
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath,PLATFORM_MAX_PATH, "configs/plugins.txt");
	
	if (!FileExists(szPath))
		SetFailState("找不到文件: %s", szPath);
		
	KeyValues kConfig = new KeyValues("");
	
	kConfig.ImportFromFile(szPath);
	kConfig.JumpToKey("Modes");
	kConfig.GotoFirstSubKey();
	
	do {
	
		char buffer[255];
		char Sbuffer[PLATFORM_MAX_PATH];
		
		kConfig.GetString("kind",buffer,255);
		kConfig.GetString("plugin", Sbuffer, PLATFORM_MAX_PATH);
		
		if(StrEqual(buffer,"bhop"))
		{
			strcopy(g_bhoppath[g_bhops],PLATFORM_MAX_PATH, Sbuffer);
			g_bhops++;
		}
		else if(StrEqual(buffer,"kz"))
		{
			strcopy(g_kzpath[g_kzs],PLATFORM_MAX_PATH, Sbuffer);
			g_kzs++;
		}
		else if(StrEqual(buffer,"surf"))
		{
			strcopy(g_surfpath[g_surfs],PLATFORM_MAX_PATH, Sbuffer);
			g_surfs++;
		}
		else if(StrEqual(buffer,"1v1"))
		{
			strcopy(g_1v1path[g_1v1s],PLATFORM_MAX_PATH, Sbuffer);
			g_1v1s++;
		}
		else if(StrEqual(buffer,"warmod"))
		{
			strcopy(g_warmodpath[g_warmods],PLATFORM_MAX_PATH, Sbuffer);
			g_warmods++;
		}
		else if(StrEqual(buffer,"practice"))
		{
			strcopy(g_practicpath[g_practices],PLATFORM_MAX_PATH, Sbuffer);
			g_practices++;
		}
	}while (kConfig.GotoNextKey())
	
}

DisableAllPlugins()
{
	for(new a = 0; a <= g_bhops; a++)
	{
        ServerCommand("plugins disable %s",g_bhoppath[a]);
	}
	for(new a = 0; a <= g_surfs; a++)
	{
        ServerCommand("plugins disable %s",g_surfpath[a]);
	}
	for(new a = 0; a <= g_kzs; a++)
	{
        ServerCommand("plugins disable %s",g_kzpath[a]);
	}
	for(new a = 0; a <= g_1v1s; a++)
	{
        ServerCommand("plugins disable %s",g_1v1path[a]);
	}
	for(new a = 0; a <= g_warmods; a++)
	{
        ServerCommand("plugins disable %s",g_warmodpath[a]);
	}
	for(new a = 0; a <= g_practices; a++)
	{
        ServerCommand("plugins disable %s",g_practicpath[a]);
	}
}

public Action CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason)
{
	if(B_blockround)
		return Plugin_Handled;
	return Plugin_Continue;
}