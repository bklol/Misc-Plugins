#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <adminmenu>

public void OnPluginStart()
{

}

public void OnMapStart()
{
	
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);
	TopMenu hTopMenu;
	if (topmenu == hTopMenu)
	{
		return;
	}
	hTopMenu = topmenu;
	TopMenuObject sb_commands = hTopMenu.FindCategory(ADMINMENU_SERVERCOMMANDS);

	if (sb_commands != INVALID_TOPMENUOBJECT)
	{
		hTopMenu.AddItem("sm_nekoadmin", AdminMenu_Neko, sb_commands, "sm_nekoadmin", ADMFLAG_GENERIC);
	}
}

public void AdminMenu_Neko(TopMenu topmenu, 
					  TopMenuAction action,
					  TopMenuObject object_id,
					  int param,
					  char[] buffer,
					  int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer,128,"服务器管理菜单[NEKO.VIP]");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Menus_ShowNeko(param);
	}
}

void Menus_ShowNeko(int client)
{
	Menu menu = new Menu(Handler_MainOPMenu);
	menu.SetTitle("[Neko]OP权限菜单");
	menu.AddItem("0", "添加一个管理员");
	menu.AddItem("1", "删除一个管理员");
	menu.AddItem("2", "修改服务器名字");
	menu.AddItem("3", "修改服务器密码");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_MainOPMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0:Menus_Addadmin(client);
			case 1:Menus_Deladmin(client);
			case 2:Menus_CsName(client);
			case 3:Menus_CsPass(client);
		}
	}
}

void Menus_AddAdmin(int client)
{
	Menu menu = new Menu(Handler_AddadminMenu);
	menu.SetTitle("添加一个管理");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			char username[MAX_NAME_LENGTH];
			char userid[32];
			GetClientName(i, username, sizeof(username));
			IntToString(i, userid, sizeof(userid));
			menu.AddItem(userid, username);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_AddadminMenu(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[64];
			GetMenuItem(menu, item, info, sizeof(info));
			int customclient = StringToInt(info);
			if(!IsValidClient(customclient))
			{
				PrintToChat(client,"当前玩家已不在服务器,请重试");
				return;
			}
			AddToAdmin(customclient);
		}
	}
}

void Menus_Deladmin(int client)
{
	Menu menu = new Menu(Handler_AddadminMenu);
	menu.SetTitle("删除一个管理");
	for(int i = 0; i < InListAdmin; i++)
	{
		if(IsValidClient(i))
		{
			menu.AddItem(userid, username);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

stock bool IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( IsFakeClient(client)) return false;
	return true;
}