#include <sourcemod>
#include <sdktools>

public void OnPluginStart()
{
	Handle hGameConf = LoadGameConfigFile("steamserver.games");
	Address Steam3Server = GameConfGetAddress(hGameConf, "Steam3Server");
	
	if (!Steam3Server) 
		SetFailState("Failed to get address: Steam3Server");
		
	Address GetPublicIP = Dereference(Dereference(Steam3Server, 0x4), 0x84);
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetAddress(GetPublicIP);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	Handle hGetPublicIP = EndPrepSDKCall();
	
	if(!hGetPublicIP) 
		SetFailState("Could not initialize call to hGetPublicIP");

	int ip = SDKCall(hGetPublicIP, Steam3Server + view_as<Address>(0x4));
	PrintToServer("Public IP is %d.%d.%d.%d\n", (ip >> 24) & 0x000000FF, (ip >> 16) & 0x000000FF, (ip >> 8) & 0x000000FF, ip & 0x000000FF );
}

stock any Dereference( Address ptr, int offset = 0, NumberType type = NumberType_Int32 )
{
    return view_as<Address>(LoadFromAddress(ptr + view_as<Address>(offset), type));
}
