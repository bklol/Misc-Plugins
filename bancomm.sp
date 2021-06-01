#include <PTaH>
#include <nekocore>
int g_playerReuseTime[MAXPLAYERS + 1];

public void OnPluginStart()
{
	PTaH(PTaH_ExecuteStringCommandPre, Hook, ExecuteStringCommand);//钩住玩家在服务器输入指令的动作 Pre表示指令被服务器解析前
}

public void OnClientPostAdminCheck(int client)
{
	g_playerReuseTime[client] = GetTime();//初始化玩家数据
}

//------------------------------当玩家输入指令----------------

Action ExecuteStringCommand(int client, char sCommand[512])
{
	if(!client)//判断是否是玩家
		return Plugin_Continue;
	
	char message[512];
	strcopy(message, sizeof(message), sCommand);//获得玩家输入的指令字符
	TrimString(message);//去除字符两边的空格
	
	if(StrContains(message,"kill") != -1) //如果字符包涵kill
	{
		FakeClientCommand(client,"kill"); //强制对服务器解析一个玩家的假指令；防止玩家使用kill id处死别的玩家
		return Plugin_Handled;
	}
	
	if(StrContains(message, "sv_rethrow_last_grenade") != -1) //如果使用sv_rethrow_last_grenade的玩家
	{
		PrintToChat(client,"请使用插件指令:.throw"); //提醒该玩家使用跑图指令
		return Plugin_Handled;//强制结束，阻止服务器收到改指令
	}
	
	if(StrContains(message, "ent_create") != -1 || StrContains(message, "ent_fire") != -1 || StrContains(message, "modelscale") != -1)
	{
		PrintToChat(client,"请不要使用与跑图无关的指令");
		return Plugin_Handled;
	}//同上	
	
	if(StrEqual(message, "sm_throw"))
	{
		if(g_playerReuseTime[client] > GetTime()) //玩家使用时间间隔小于3秒
		{
			PrintToChat(client,"请不要频繁使用该指令! 每次使用间隔为3秒");//提醒玩家
			return Plugin_Handled; //强制结束
		}
		else
		{
			g_playerReuseTime[client] = GetTime() + 3;//下次使用间隔
		}
		return Plugin_Continue;
	}
	
	if(StrEqual(message,"sm_replay"))
	{
		if(!NEKO_IsVIP(client))
		{
			PrintToChat(client,"该指令为VIP预留");//VIP预留指令
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;//其他继续执行
}