#pragma semicolon 1 
#include <sdktools>
Handle hRestartServer;
char sig[] = "\x55\xC7\x05\x2A\x2A\x2A\x2A\x07\x00\x00\x00";

public void OnMapStart()  
{
	StartPrepSDKCall(SDKCall_Server);
	PrepSDKCall_SetSignature(SDKLibrary_Engine, sig, sizeof(sig) - 1);
	hRestartServer = EndPrepSDKCall();
	SDKCall(hRestartServer);
}