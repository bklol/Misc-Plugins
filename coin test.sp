#include <cstrike>
#include <sdkhooks>
#include <sdktools>

int Offset = -1;
public void OnMapStart()
{
	SDKHook(GetPlayerResourceEntity(), SDKHook_ThinkPost, OnThinkPost);
	Offset = FindSendPropInfo("CCSPlayerResource", "m_nActiveCoinRank");
}

public void OnThinkPost(int iEnt)
{
	
	for(int i = 1; i <= MaxClients; i++)
	{
		SetEntData(iEnt, Offset + ( i * 4 ), 6050 );
	}
		
}
