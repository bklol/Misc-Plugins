#include <sourcemod>
#include <sdktools>
float fpos[3];
float spos[3];
int Isfrist = 0;
new LaserSprite;
new LaserHalo;
new const g_DefaultColors_c[7][4] = { {255,255,255,255}, {255,0,0,255}, {0,255,0,255}, {0,0,255,255}, {255,255,0,255}, {0,255,255,255}, {255,0,255,255} };
public OnPluginStart()
{  
    LaserSprite = PrecacheModel("materials/sprites/laserbeam.vmt"); 
    LaserHalo = PrecacheModel("materials/sprites/light_glow02.vmt"); 
}
public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon) 
{
	if (iButtons & IN_USE)
	{
		new Color = GetRandomInt(0,6);
		paint(client,g_DefaultColors_c[Color]);
	}
}
void paint(int client,int color[4])
{
	
	float vAngles[3], vOrigin[3],pos[3];
	GetClientEyePosition( client, vOrigin );
	GetClientEyeAngles( client, vAngles );
	TR_TraceRayFilter( vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer );
	if( TR_DidHit() )
		TR_GetEndPosition( pos );
	if(Isfrist<1)
		TR_GetEndPosition( fpos );
	else
		TR_GetEndPosition( spos );
	//TE_Start("World Decal");
	//TE_WriteVector("m_vecOrigin", pos);
	//TE_WriteNum("m_nIndex",PrecacheDecal("paintball/pb_pink.vmt",true));
	if(Isfrist>=1)
	{
		TE_SetupBeamPoints(fpos, spos, LaserSprite, LaserHalo, 0, 5, 0.0, 1.0, 1.0, 0, 0.0, color, 200);
		TR_GetEndPosition( fpos );
	}
	Isfrist=Isfrist+1;
	TE_SendToAll();
}
public bool TraceEntityFilterPlayer( int entity, int contentsMask )
{
	return ( entity > GetMaxClients() || !entity );
}