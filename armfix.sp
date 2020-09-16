#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <dhooks>
Handle Dhook_PrecacheModel = INVALID_HANDLE;

public void OnPluginStart()
{
	GameData gameData = LoadGameConfigFile("gloves.games");
	if(gameData == INVALID_HANDLE)
		SetFailState("Gamedata file gloves.games.txt is missing.");

	int offset = gameData.GetOffset("CBaseEntity::PrecacheModel");

	if(offset == -1)
	{
		SetFailState("Failed to find offset for Precache");
		delete gameData;
	}
	Address addr = fnCreateEngineInterface(gameData, "EngineInterface");
	if (addr == Address_Null) {
		SetFailState("Failed to get interface for \"VEngineServer023\"");
	}

	Dhook_PrecacheModel = DHookCreate(offset, HookType_Raw, ReturnType_Int, ThisPointer_Ignore, WeaponDHookOnPrecacheModel);
	if (!Dhook_PrecacheModel) {
		SetFailState("Failed to setup hook for \"PrecacheModel\"");
	}
	DHookAddParam(Dhook_PrecacheModel, HookParamType_CharPtr);
	DHookAddParam(Dhook_PrecacheModel, HookParamType_Bool);
	DHookRaw(Dhook_PrecacheModel, false, addr);
	
}

stock Address fnCreateEngineInterface(GameData gameConf, char[] sKey, Address pAddress = Address_Null) 
{
    // Initialize intercace call
    static Handle hInterface = null;
    if (hInterface == null) 
    {
        // Starts the preparation of an SDK call
        StartPrepSDKCall(SDKCall_Static);
        PrepSDKCall_SetFromConf(gameConf, SDKConf_Signature, "CreateInterface");

        // Adds a parameter to the calling convention. This should be called in normal ascending order
        PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain, VDECODE_FLAG_ALLOWNULL);
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

        // Validate call
        if ((hInterface = EndPrepSDKCall()) == null)
        {
            return Address_Null;
        }
    }

    // Gets the value of a key from a config
    static char sInterface[128];
    fnInitGameConfKey(gameConf, sKey, sInterface, sizeof(sInterface));

    // Gets the address of a given interface and key
    Address pInterface = SDKCall(hInterface, sInterface, pAddress);
    if (pInterface == Address_Null) 
    {
        return Address_Null;
    }

    // Return on the success
    return pInterface;
}

stock void fnInitGameConfKey(GameData gameConf, char[] sKey, char[] sIdentifier, int iMaxLen)
{
    // Validate key
    if (!gameConf.GetKeyValue(sKey, sIdentifier, iMaxLen)) 
    {
    }
}

public MRESReturn DHook_PrecacheModelCallback(int entity, Handle hReturn, Handle hParams)
{
	char buffer[128];
	DHookGetParamString(hParams, 1, buffer, 128);
	
	if(StrContains(buffer, "models/weapons/v_models/arms/glove_hardknuckle/") != -1)
	{
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public MRESReturn WeaponDHookOnPrecacheModel(Handle hReturn, Handle hParams)
{
    // Gets model from parameters
	char buffer[128];
	DHookGetParamString(hParams, 1, buffer, sizeof(buffer));
	if (!strncmp(buffer, "models/weapons/v_models/arms/glove_hardknuckle/", 47, false))
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	if (!strncmp(buffer, "models/weapons/v_models/arms/glove_fingerless/", 46, false))
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	if (!strncmp(buffer, "models/weapons/v_models/arms/glove_fullfinger/", 46, false))
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	if (!strncmp(buffer, "models/weapons/v_models/arms/anarchist/", 39, false))
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	if(StrContains(buffer, "error") != -1)
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
		// Skip the hook
	return MRES_Ignored;
}

stock bool IsValidClient( int client )
{
	
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( IsFakeClient( client )) return false;
	return true;
}