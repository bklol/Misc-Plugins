#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public void OnPluginStart()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i))
            continue;
        SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (damagetype & DMG_FALL)
		return Plugin_Continue;
		
    if(IsTeamMate(victim,attacker))
    {
		char sWeapon[64];
		GetEdictClassname( inflictor, sWeapon, sizeof( sWeapon ) );

		if( StrEqual( sWeapon, "inferno" ) ) {
        return Plugin_Continue;
		}

		if( StrEqual( sWeapon, "hegrenade_projectile" ) ) {
        return Plugin_Continue;
		}
		
		if( StrEqual( sWeapon, "weapon_knife_t" ) ) {
        return Plugin_Continue;
		}
		
		if( StrEqual( sWeapon, "weapon_knife_ct" ) ) {
        return Plugin_Continue;
		}
		
		if( StrEqual( sWeapon, "decoy_projectile" ) ) {
        return Plugin_Continue;
		}
		
		if( StrEqual( sWeapon, "smokegrenade_projectile" ) ) {
        return Plugin_Continue;
		}
		
		return Plugin_Handled;
    }
	
    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

stock bool IsTeamMate(int client,int client2)
{
    if(GetClientTeam(client) == GetClientTeam(client2))
        return true;
    else
        return false;
}

stock bool IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	return true;
}
