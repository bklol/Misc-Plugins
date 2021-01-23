#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

int iLowFpsJumps[MAXPLAYERS + 1];
#define INJUMP_ONGROUND_MAXSPEED 250.0
#define MIN_FPS 59.0 // 59 hz monitors, why not.

public Plugin myinfo = 
{
	name = "[Bhop] FPS tick pass fix",
	author = "null138",
	description = "Fixes fps manipulating to pass basetick",
	version = "1.00",
}

public void OnClientPutInServer(int client)
{
	iLowFpsJumps[client] = 0;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(IsPlayerAlive(client) && buttons & IN_JUMP && GetEntityFlags(client) & FL_ONGROUND)
	{
		static float inPackets; inPackets = GetClientAvgPackets(client, NetFlow_Incoming);
		static float vVel[3]; GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
		static float vScale; vScale = FloatDiv(INJUMP_ONGROUND_MAXSPEED, SquareRoot(FloatAdd(Pow(vVel[0], 2.0), Pow(vVel[1], 2.0))));
		
		if(inPackets < MIN_FPS)
		{
			if(iLowFpsJumps[client] > 1 && vScale < 1.0)
			{
				vVel[0] = FloatMul(vVel[0], vScale);
				vVel[1] = FloatMul(vVel[1], vScale);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
				iLowFpsJumps[client] = 0;
				
				return Plugin_Continue;
			}
			++iLowFpsJumps[client];
		}
		// PrintToChat(client, "Incoming packets: %.3f", inPackets);
	}
	return Plugin_Continue;
}