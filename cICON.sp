#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int m_iOffset = -1;
int C_level[MAXPLAYERS + 1];

public void OnPluginStart()
{
	m_iOffset = FindSendPropInfo("CCSPlayerResource", "m_nPersonaDataPublicLevel");
}

public void OnMapStart()
{
	SDKHook(GetPlayerResourceEntity(), SDKHook_ThinkPost, OnThinkPost);
}

public void OnThinkPost(int m_iEntity)
{
	
	for(int i = 1; i <= MaxClients; i++)
	{
		C_level[i]=ANYTHING YOU WANT;
		SetEntData(m_iEntity, m_iOffset + (i * 4),C_level[i]);		
	}
}