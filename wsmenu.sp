#include <sourcemod>  

public void OnPluginStart()
{
	RegConsoleCmd("buyammo1",Command_Main);
	RegConsoleCmd("sm_ws",Command_Main);
}	

public Action Command_Main(int client,int b)
{
	Menus_ShowMain(client);
}

void Menus_ShowMain(int client)
{
	Menu menu = new Menu(Handler_MainMenu);
	menu.SetTitle(" - NEKO WS - \n ");
	menu.AddItem("#0", "修改武器贴纸[!tz]");
	menu.AddItem("#1", "修改武器|刀具皮肤[!was]");	
	menu.AddItem("#2", "修改刀具模型[!knife]");
	menu.AddItem("#3", "修改手套模型|皮肤[!glove]");
	menu.AddItem("#4", "修改武器检视|切换动作[!rare]");
	menu.AddItem("#5", "修改等级图标[!hz]");
	menu.AddItem("#6", "修改音乐盒[!music]");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_MainMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0:FakeClientCommand(client, "sm_sticker");
			case 1:FakeClientCommand(client, "sm_was");
			case 2:FakeClientCommand(client, "sm_knife");
			case 3:FakeClientCommand(client, "sm_glove");
			case 4:FakeClientCommand(client, "sm_rare");
			case 5:FakeClientCommand(client, "sm_hz");
			case 6:FakeClientCommand(client, "sm_muisc");
		}
	}
}
