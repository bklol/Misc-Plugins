#include <sourcemod>
#include <sdktools>
bool ispressbotton ;
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
		//new Color = GetRandomInt(0,6);
		//paint(client,g_DefaultColors_c[Color],fAngles,fVelocity);
		
	}
	else
		PrintToChatAll("1");
	
}
void paint(int client,int color[4],float vAngles[3], vOrigin[3])
{
	
	float pos[3];
	TR_TraceRayFilter( vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer );
	if( TR_DidHit() )
		TR_GetEndPosition( pos );
	if(Isfrist<1)
		TR_GetEndPosition( fpos );
	else
		TR_GetEndPosition( spos );
	if(Isfrist>=1)
	{
		TE_SetupBeamPoints(fpos, spos, LaserSprite, LaserHalo, 0, 5, 0.0, 1.0, 1.0, 0, 0.0, color, 200);
		//DrawLaser(fpos, spos);
		TR_GetEndPosition( fpos );
	}
	Isfrist=Isfrist+1;
	TE_SendToAll();
}
public bool TraceEntityFilterPlayer( int entity, int contentsMask )
{
	return ( entity > GetMaxClients() || !entity );
}
stock DrawLaser(Float:start[3], Float:end[3])
{
    new ent = CreateEntityByName("env_beam");
    if (ent != -1)
    {
        TeleportEntity(ent, start, NULL_VECTOR, NULL_VECTOR);
        SetEntityModel(ent, "sprites/laserbeam.vmt"); // This is where you would put the texture, ie "sprites/laser.vmt" or whatever.
        SetEntPropVector(ent, Prop_Data, "m_vecEndPos", end);
        DispatchKeyValue(ent, "targetname", "beam");
        DispatchKeyValue(ent, "rendercolor", "255 0 255");
        DispatchKeyValue(ent, "renderamt", "100");
        DispatchSpawn(ent);
        SetEntPropFloat(ent, Prop_Data, "m_fWidth", 4.0); // how big the beam will be, i.e "4.0"
        SetEntPropFloat(ent, Prop_Data, "m_fEndWidth", 4.0); // same as above
        ActivateEntity(ent);
        AcceptEntityInput(ent, "TurnOn");
    }
} 
