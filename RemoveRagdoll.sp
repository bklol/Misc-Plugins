#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "[NEKO] RemoveRagdoll",
	author = "NEKO",
	description = "RemoveRagdoll",
	version = "1.0"
};

public void OnPluginStart()
{
	HookEvent("player_team", Player_Notifications, EventHookMode_Pre);
	HookEvent("player_death", Player_Notifications, EventHookMode_Pre);
}

public Action Player_Notifications(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	RemoveRagdoll(client);
	return Plugin_Continue;
}

void RemoveRagdoll(int client)
{
	int iEntity = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");

	if(iEntity != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iEntity, "Kill");
	}
}