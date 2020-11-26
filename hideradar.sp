#pragma semicolon 1
#include <sdktools>

Address g_aCanBeSpotted = view_as<Address>(892);

public void OnPluginStart()
{
    RegConsoleCmd("hide", hide);
    RegConsoleCmd("uhide", uhide);
}

public Action hide(int iClient, int args)
{
    SetEntProp(iClient, Prop_Send, "m_bSpotted", false);
    SetEntProp(iClient, Prop_Send, "m_bSpottedByMask", 0, 4, 0);
    SetEntProp(iClient, Prop_Send, "m_bSpottedByMask", 0, 4, 1);
    StoreToAddress(GetEntityAddress(iClient)+g_aCanBeSpotted, 0, NumberType_Int32);
}

public Action uhide(int iClient, int args)
{
    StoreToAddress(GetEntityAddress(iClient)+g_aCanBeSpotted, 9, NumberType_Int32);
}