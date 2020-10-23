#include <sourcemod>
#include <PTaH>
#include <ripext>
#include <sdktools>
#include <eItems>


public Plugin myinfo = {
    name = "buff viewer|大致框架",
    author = "neko aka bklol",
    description = "呐呐 喜欢二次元的 一定不是坏人吧？",
    version = "0.1",
    url = "https://github.com/bklol"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_buff",test);
	
	PTaH(PTaH_GiveNamedItemPre,  Hook, OnGiveNamedItemPre);		
	PTaH(PTaH_GiveNamedItemPost, Hook, OnGiveNamedItemPost);
	PTaH(PTaH_WeaponCanUsePre,	 Hook, PTaH_OnWeaponCanUsePre);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPostAdminCheck(i);
	}
}

public Action PTaH_OnWeaponCanUsePre(int client, int iEnt, bool& CanUse)
{
	//强制装备刀具
	if(!IsValidClient(client) && !IsFakeClient(client))
		return Plugin_Continue;	
	int iDefIndex = eItems_GetWeaponDefIndexByWeapon(iEnt);
	if(eItems_IsDefIndexKnife(iDefIndex))
	{
		CanUse = true;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action test(int client,int a)
{
	char Buffer[1280]; 
	GetCmdArgString(Buffer, sizeof(Buffer));
	//发送http 请求
	HTTPClient httpClient = new HTTPClient("这里写api");
	Format(Buffer,1280,"https://buff.163.com/market/m/item_detail?%s",Buffer);
	JSONObject hJSONObject = new JSONObject();
	hJSONObject.SetString("ip",Buffer);
	httpClient.Post("get", hJSONObject, ItemCheckCallBack, client);
	delete hJSONObject;
	return Plugin_Handled;
}


public void OnClientPostAdminCheck(int client)
{
	//玩家判断。。。。
}

public void ItemCheckCallBack(HTTPResponse response, any client)
{
	if (response.Status != HTTPStatus_OK) 
	{
		LogError("Http Get error error, %d", response.Status);
		PrintToChat(client, "API 访问失败");
		return;
	}
	if (response.Data == null) 
	{
		LogError("Http Get No response");
		PrintToChat(client, "物品 解析失败");
		return;
	}
	//接收json 开始解析。。。
	
	//重构武器皮肤。。。。
	//判断是否是手套。。。否：
	int weapon = eItems_GetActiveWeapon(client);
	eItems_RespawnWeapon(client, weapon, true);
	//是：重构手套
	
}

public Action OnGiveNamedItemPre(int client, char classname[64], CEconItemView &item, bool &ignoredCEconItemView, bool &isOriginNULL, float origin[3])
{
	//这里移除武器原有皮肤
}

public void OnGiveNamedItemPost(int client, const char[] classname, const CEconItemView item, int entity, bool isOriginNULL, const float origin[3])
{
	//再这里重构武器皮肤|Attach 贴纸等等
	PTaH_ForceFullUpdate(client);
	//如果有贴纸 打开贴纸修改菜单。。。。
}

void OPP(int client)
{
	Menu menu = new Menu(Handler_MainMenu);
	menu.SetTitle("贴纸矫正[槽位选择]");
	int weapon = eItems_GetActiveWeapon(client);
	int slots = eItems_GetWeaponStickersSlotsByWeapon(weapon);
	char buffer[1024];	
	for (int i = 0; i < slots; i++)
	{
		//这里添加槽位
		menu.AddItem("0", buffer);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_MainMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		//这里打开贴纸下级菜单
		StickerMenu(client);
	}
}

void StickerMenu(int client)
{
	Menu menu = new Menu(Handler_SMenu);
	//显示槽位和应用的贴纸。

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);	
}

public int Handler_SMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	
	
	if (action == MenuAction_Select)
	{
		//替换贴纸，重新打开菜单
		OPP(client);

		int weapon = eItems_GetActiveWeapon(client);
		eItems_RespawnWeapon(client, weapon, true);
		
	}
	if (action == MenuAction_Cancel)
	{
		OPP(client);
	}
}


stock bool IsValidClient( int client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	//if ( IsFakeClient(client)) return false;
	return true;
}