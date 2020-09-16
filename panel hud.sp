#include <cstrike>
#include <sourcemod>

public void OnPluginStart()
{
	RegConsoleCmd("sm_t",      Command_FakePanel);
}

public Action Command_FakePanel(int client ,int ages)
{
	Event newevent_message = CreateEvent("cs_win_panel_round");
	newevent_message.SetString("funfact_token", "中文消息测试\n消息测试");
	newevent_message.FireToClient(client);
	newevent_message.Cancel();
}






