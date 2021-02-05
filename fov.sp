#pragma semicolon 1

#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

int playerfov = 90;

public void OnPluginStart() 
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	RegConsoleCmd("sm_fov", FovMenu);
}

public Action FovMenu(int client, int args) 
{
	iFovMenu(client);
}

void iFovMenu(int client)
{
	Menu menu = new Menu(m_ShowWeaponStickersCWearMenu);
	menu.SetTitle("Fov");
	menu.AddItem("increase", "+10");
	menu.AddItem("decrease", "-10");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int m_ShowWeaponStickersCWearMenu(Menu menu, MenuAction action, int client, int option)
{
	if (action == MenuAction_Select)
	{
		char buffer[30];
		menu.GetItem(option, buffer, sizeof(buffer));
		if(StrEqual(buffer, "increase"))
		{
			playerfov+=30;
			SetClientFOV(client);
		}
		else if(StrEqual(buffer, "decrease"))
		{
			playerfov-=30;
			SetClientFOV(client);
		}
		iFovMenu(client);
	}
}

void SetClientFOV(int iClient)
{
	SetEntProp(iClient, Prop_Send, "m_iFOV", playerfov);
	SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", playerfov);
}

public void Event_PlayerSpawn(Event hEvent, const char[] weaponName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	if(iClient && IsPlayerAlive(iClient))
	{
		SetEntProp(iClient, Prop_Send, "m_iFOV", 120);
		SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", 120);
	}
}
