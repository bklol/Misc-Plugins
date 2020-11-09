#include <PTaH>

#define MAXWEAPONS 99;

CEconItemView View[MAXPLAYERS +	1][2][999];

/*
public void OnClientPostAdminCheck(int client) //不要写在PostAdminCheck 无法获取数据
{
	if(GetWeaponCEconItemView(client,2,"weapon_awp"))
	{
		//do some stuff here
	}
}
*/

stock bool GetWeaponCEconItemView(int client,int iTeam, char[] weaponclassname)
{
	CEconItemDefinition pDefinition = PTaH_GetItemDefinitionByName(weaponclassname);
	if(pDefinition)
	{
		CCSPlayerInventory pInventory = PTaH_GetPlayerInventory(client);
		int iLoadout = pDefinition.GetLoadoutSlot();
		View[client][iTeam][iLoadout] = pInventory.GetItemInLoadout(iTeam, iLoadout);
		return true;
	}
	return false;
}
