#include <sourcemod>
#include <sdktools>

bool cooldown[MAXPLAYERS+1];

int g_idecals = 0;

Handle adt_decal_position	= INVALID_HANDLE;

enum decalSettings
{
	decalName = 0, 
	decalModel,
	decalFlag,
	decalOnwer,
}

public Plugin myinfo =
{
	name = "decal",
	author = "neko",
	description = "decal plugin",
	version = "0.1"
};

char szMap[128];

char g_szSkins[137][decalSettings][PLATFORM_MAX_PATH + 1];
char DecalInUse[MAXPLAYERS+1][PLATFORM_MAX_PATH];


public OnPluginStart()
{	
	adt_decal_position = CreateArray(3);
	RegConsoleCmd("sm_decal", Command_Decal);
}

public Action Command_Decal(int client,int args)
{
	if(cooldown[client])
	{
		PrintToChat(client,"请在喷漆结束之后等待3分钟冷却");
		return Plugin_Handled;
	}
	
	Menus_SkinsMain(client);
	return Plugin_Handled;
}

public void OnMapStart()
{
	ClearArray(adt_decal_position);
	GetCurrentMap(szMap, 128);
	LoadDecal();
}

LoadDecal()
{
	g_idecals = 0;
	char Buffer[PLATFORM_MAX_PATH];
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath,PLATFORM_MAX_PATH, "configs/decal.cfg");
	if (!FileExists(szPath))
		SetFailState("Couldn't find file: %s", szPath);
	
	KeyValues kConfig = new KeyValues("");
	kConfig.ImportFromFile(szPath);
	kConfig.JumpToKey("decal");
	kConfig.GotoFirstSubKey();
	
	do {
		kConfig.GetString("name", g_szSkins[g_idecals][decalName], 64);
		kConfig.GetString("index", g_szSkins[g_idecals][decalModel], PLATFORM_MAX_PATH);
		kConfig.GetString("flag", g_szSkins[g_idecals][decalFlag], 64);
		kConfig.GetString("steamid", g_szSkins[g_idecals][decalOnwer], 64);
		
		Format(Buffer,sizeof(Buffer),"materials/%s.vmt",g_szSkins[g_idecals][decalModel]);
		AddFileToDownloadsTable(Buffer);
		Format(Buffer,sizeof(Buffer),"materials/%s.vtf",g_szSkins[g_idecals][decalModel]);
		AddFileToDownloadsTable(Buffer);
		g_idecals++;
	} while (kConfig.GotoNextKey())
}

public OnMapEnd() {
	ClearArray(adt_decal_position);
}



public Action CoolDown(Handle timer,int client)
{
	cooldown[client] = false;
}

void Menus_SkinsMain(int client)
{
	
	Menu menu = new Menu(Handler_SkinsSelection);
	menu.SetTitle("选择一个自定义贴图\n");
	char szBuffer[128];
	for (int i = 0; i < g_idecals; i++)
	{
		Format(szBuffer, sizeof(szBuffer), g_szSkins[i][decalName]);
		menu.AddItem(g_szSkins[i][decalModel], szBuffer,CheckAcess(client,g_szSkins[i][decalFlag],g_szSkins[i][decalOnwer])?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_SkinsSelection(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select) {
	char szInfo[PLATFORM_MAX_PATH], szName[64];
	menu.GetItem(itemNum, szInfo, PLATFORM_MAX_PATH, _, szName, sizeof(szName));
	DecalInUse[client] = szInfo;
	PrintToChat(client,"对墙壁按E喷涂");
	Menus_SkinsMain(client);
	}
}
public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon) 
{
	if (iButtons & IN_USE && !cooldown[client])
	{
		MakeSpray(client,DecalInUse[client]);
	}
}

void MakeSpray(int client, char[] Decalpath)
{    
	float fClientEyePosition[3];
	GetClientEyePosition(client, fClientEyePosition);

	float fClientEyeViewPoint[3];
	GetPlayerEyeViewPoint(client, fClientEyeViewPoint);

	float fVector[3];
	MakeVectorFromPoints(fClientEyeViewPoint, fClientEyePosition, fVector);
    
	float vecAng[3];
	GetClientAbsAngles(client, vecAng);
	Format(Decalpath,256,"%s.vmt",Decalpath);
	CreateSprite(client, Decalpath , fClientEyeViewPoint, vecAng, 0.5, "0", 150.0);
}

stock GetPlayerEyeViewPoint(int iClient, float fPosition[3])
{
    float fAngles[3];
    GetClientEyeAngles(iClient, fAngles);

    float fOrigin[3];
    GetClientEyePosition(iClient, fOrigin);

    Handle hTrace = TR_TraceRayFilterEx(fOrigin, fAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	
    if(TR_DidHit(hTrace))
    {
        TR_GetEndPosition(fPosition, hTrace);
        CloseHandle(hTrace);
        return true;
    }
    CloseHandle(hTrace);
    return false;
}

public bool TraceEntityFilterPlayer(iEntity, iContentsMask)
{
    return iEntity > MaxClients;
}

stock CreateSprite(iClient, char[] sprite, float vOrigin[3], float fAng[3], float Scale, char[] fps, float fLifetime) 
{ 
    new String:szTemp[64];  
    Format(szTemp, sizeof(szTemp), "client%i", iClient); 
    DispatchKeyValue(iClient, "targetname", szTemp); 
    
    new ent = CreateEntityByName("env_sprite_oriented"); 
    if (IsValidEdict(ent)) 
    { 
        new String:StrEntityName[64]; Format(StrEntityName, sizeof(StrEntityName), "ent_sprite_oriented_%i", ent); 
        DispatchKeyValue(ent, "model", sprite); 
        DispatchKeyValue(ent, "classname", "env_sprite_oriented");
        DispatchKeyValue(ent, "spawnflags", "1");
        DispatchKeyValueFloat(ent, "scale", Scale);
        DispatchKeyValue(ent, "rendermode", "1");
        DispatchKeyValue(ent, "rendercolor", "255 255 255");
        DispatchKeyValue(ent, "framerate", fps);
        DispatchKeyValueVector(ent, "Angles", fAng);
        DispatchSpawn(ent);
        
        TeleportEntity(ent, vOrigin, fAng, NULL_VECTOR); 
        
        CreateTimer(fLifetime, RemoveParticle, ent);
    }
}

public Action RemoveParticle(Handle timer, any particle)
{
    if(IsValidEdict(particle))
    {
        AcceptEntityInput(particle, "Deactivate");
        AcceptEntityInput(particle, "Kill");
    }
} 

public OnClientPostAdminCheck(client) {

	cooldown[client] = false;
}

bool CheckAcess(int client,char[] Flag,char[] steamid)
{
	char g_szAuth[32];
	GetClientAuthId(client, AuthId_Steam2, g_szAuth, sizeof(g_szAuth));
	if(StrEqual("",steamid) && StrEqual("",Flag)) return true;
	if(StrEqual(g_szAuth,steamid)) return true;
	if(!StrEqual("",Flag))
	{
		bool bFlags[AdminFlags_TOTAL];
		bool bPlayerFlags[AdminFlags_TOTAL];
	
		int iFlags = ReadFlagString(Flag);
		int iPlayerFlags = GetUserFlagBits(client);
	
		FlagBitsToBitArray(iFlags, bFlags, AdminFlags_TOTAL);
		FlagBitsToBitArray(iPlayerFlags, bPlayerFlags, AdminFlags_TOTAL);
	
		for (int i = 0; i < AdminFlags_TOTAL; i++)
		{
			if (bPlayerFlags[i] && bFlags[i])
				return true;
		}
	}
	return false;
}