#include <sourcemod>
#pragma newdecls required

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	char sWeapon[128];
	event.GetString("weapon", sWeapon, 128);
	bool headshot = event.GetBool("headshot");
	CreateDeathEvent(victim, attacker, sWeapon, headshot);
	SetEventBroadcast(event, true);
}

public void CreateDeathEvent(int victim, int attacker, char[] sWeapon, bool headshot)
{
	Event event = CreateEvent("player_death");
	event.SetInt("userid", GetClientUserId(victim));
	event.SetInt("attacker", GetClientUserId(attacker)); 
	event.SetString("weapon", sWeapon);
	event.SetBool("headshot", headshot);
	
	if(IsValidClient(victim))
		event.FireToClient(victim);
	if(IsValidClient(attacker) && victim != attacker)
		event.FireToClient(attacker);
	delete event; //cause memory leak ？
}

stock bool IsValidClient(int client)
{
	if(client <= 0 || client > MaxClients)
		return false;
		
	if(!IsClientInGame(client) || !IsClientConnected(client) || IsFakeClient(client))
		return false;
		
	return true;
} 