#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike> 

public Plugin myinfo = 
{
	name = "NEKO HUD",
	author = "NEKO",
	description = "HUD",
	version = "1.0"
};

public void OnPluginStart()
{
	CreateTimer(1.0, TIMER, _, TIMER_REPEAT);
}

public Action TIMER(Handle timer, any client)
{
	int iTimeleft;
	char sTime[64], szTime[30], MapTimeLeft[128];
	GetMapTimeLeft(iTimeleft);
	FormatTime(szTime, sizeof(szTime), "%H:%M:%S", GetTime());
	FormatTime(sTime, sizeof(sTime), "%M:%S", iTimeleft);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			char iBuffer[1024];
			if(!(iTimeleft > 0))
				Format(MapTimeLeft,sizeof(MapTimeLeft), "最后一局");
			else
				Format(MapTimeLeft,sizeof(MapTimeLeft), "%s", sTime);
			Format(iBuffer, sizeof(iBuffer),"地图剩余 [%s]\n当前时间 [%s]",MapTimeLeft, szTime);
			SetHudTextParams(0.0, 0.38, 1.0, 200,57,0, 255, 0, 0.0, 0.0, 0.0);  
			ShowHudText(i, -1, iBuffer);  
		}
	}
}

bool IsClientValid(int client)
{
    return (0 < client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client);
}

