#include <sourcemod>
#include <sdktools>

Handle GetStatsString;

char sig[] = "\x55\x66\x0F\xEF\xC0\x89\xE5\x57\x56\x8D\x45\x2A\x53\x83\xEC\x40";//ghidra
//char sig[] = "\x55\x66\x0F\xEF\xC0\x89\xE5\x57\x56\x8D\x45\xE4";//ida
/**

fVar7 = DAT_02fc5be0 * 1000.0; ~tick
fVar6 = DAT_02fc5be4 * 1000.0; ms
fVar5 = DAT_02fc5bdc * 1000.0; sv

__snprintf_chk(param_2,param_3 + -1,1,0xffffffff,
			 "%6.1f %8.1f %8.1f %7i %5i %7.2f %7i %7.2f %7.2f %7.2f",
			 (double)(_DAT_006fbbe0 * 100.0),(double)local_24,(double)local_20[0],
			 (int)fVar4 / 0x3c,iVar1,1.0 / dVar8,iVar2 - iVar3,(double)fVar5,(double)fVar6,
			 (double)fVar7);
			 
001cffd0
001d002b sv
		 
001d000b f3 0f 10        MOVSS      XMM3,dword ptr [DAT_02fc5be0]                    = ??
		 1d e0 5b 
		 fc 02
		 
001d0013 f3 0f 10        MOVSS      XMM2,dword ptr [DAT_02fc5be4]                    = ??
		 15 e4 5b 
		 fc 02
		 
001d001b f3 0f 59 d8     MULSS      XMM3,XMM0

001d001f f3 0f 59 d0     MULSS      XMM2,XMM0

001d0023 f3 0f 59        MULSS      XMM0,dword ptr [DAT_02fc5bdc]                    = ??
		 05 dc 5b 
		 fc 02
				 

**/

public void OnPluginStart()  
{
	StartPrepSDKCall(SDKCall_Server);
	PrepSDKCall_SetSignature(SDKLibrary_Engine, sig, sizeof(sig) -1);
	PrepSDKCall_AddParameter(SDKType_String,  SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	GetStatsString = EndPrepSDKCall();
	if(!GetStatsString) 
		SetFailState("Could not initialize call to CServerRemoteAccess::GetStatsString");
	char buffer[128];
	SDKCall(GetStatsString, buffer, sizeof(buffer));
	PrintToServer("CPU   NetIn   NetOut    Uptime  Maps   FPS   Players  Svms    +-ms   ~tick\n%s", buffer);
}