#include <sourcemod>
#include <sdktools>
#include <cstrike>

ConVar g_healthshot;
ConVar g_shield;
ConVar g_bumpmine;
ConVar g_breachcharge;
ConVar g_tagrenade;
	
public Plugin myinfo =
{
	name = "neko weaon menu",
	author = "neko",
	description = "simple plugin, give equipments",
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_buy"     , Command_Buy);
	RegConsoleCmd("sm_buymenu" , Command_Buy);
	g_healthshot = CreateConVar("weapon_healthshot","100");
	g_shield = CreateConVar("weapon_shield","100");
	g_bumpmine = CreateConVar("weapon_bumpmine","100");
	g_breachcharge = CreateConVar("weapon_breachcharge","100");
	g_tagrenade = CreateConVar("weapon_tagrenade","100");
	AutoExecConfig();
}

public Action Command_Buy(int client , int ages)
{
	if(IsPlayerAlive(client))
		Menus_ShowMain(client);
	else
		PrintToChat(client,"只有在存活时可以使用");
}

void Menus_ShowMain(int client)
{
	Menu menu = new Menu(Handler_MainMenu);
	char buffer[32];
	int wallet = GetEntProp(client, Prop_Send, "m_iAccount");
	Format(buffer,sizeof(buffer),"道具购买 钱包%i",wallet);
	menu.SetTitle(buffer);
	Format(buffer,sizeof(buffer),"医疗针 %i￥",g_healthshot.IntValue);
	menu.AddItem("0", buffer);
	Format(buffer,sizeof(buffer),"盾牌 %i￥",g_shield.IntValue);
	menu.AddItem("1", buffer);
	Format(buffer,sizeof(buffer),"冲击地雷 %i￥",g_bumpmine.IntValue);
	menu.AddItem("2", buffer);
	Format(buffer,sizeof(buffer),"遥控c4 %i￥",g_breachcharge.IntValue);
	menu.AddItem("3", buffer);
	Format(buffer,sizeof(buffer),"战术探测手雷 %i￥",g_tagrenade.IntValue);
	menu.AddItem("4", buffer);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_MainMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0: 
			{
				GivePlayerItem(client, "weapon_healthshot");
				PrintToChat(client,"你购买了医疗针 x 1");
				SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount") - g_healthshot.IntValue);
				Menus_ShowMain(client);
			}
			case 1:
			{
				GivePlayerItem(client, "weapon_shield");
				PrintToChat(client,"你购买了盾牌 x 1");
				SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount") - g_shield.IntValue);
				Menus_ShowMain(client);
			}
			case 2:
			{
				GivePlayerItem(client, "weapon_bumpmine");
				PrintToChat(client,"你购买了冲击地雷 x 3");
				SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount") - g_bumpmine.IntValue);
				Menus_ShowMain(client);
			}
			case 3:
			{
				GivePlayerItem(client, "weapon_breachcharge");
				PrintToChat(client,"你购买了遥控c4 x 3");
				SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount") - g_breachcharge.IntValue);
				Menus_ShowMain(client);
			}
			case 4:
			{
				GivePlayerItem(client, "weapon_tagrenade");
				PrintToChat(client,"你购买了战术探测手雷 x 1");
				SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount") - g_tagrenade.IntValue);
				Menus_ShowMain(client);
			}
		}
	}
}
