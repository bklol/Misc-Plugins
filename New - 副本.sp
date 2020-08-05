#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int g_iPreviewModel[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
int g_iPreviewTimes[MAXPLAYERS+1];
Handle g_tKillPreview[MAXPLAYERS+1];
public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon) 
{
	if (iButtons & IN_USE)
	{
		On_PreviewSkin(client);
	}
	
}

public void OnPluginStart()
{
	PrecacheModel("models/weapons/stickers/v_models/pist_deagle_decal_a.mdl");
}

void paint(int client)
{
	float vAngles[3], vOrigin[3],pos[3];
	GetClientEyePosition( client, vOrigin );
	GetClientEyeAngles( client, vAngles );
	TR_TraceRayFilter( vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer );
	if( TR_DidHit() )
		TR_GetEndPosition( pos );
	
}

public bool TraceEntityFilterPlayer( int entity, int contentsMask )
{
	return ( entity > MaxClients || !entity );
}

void On_PreviewSkin(int client)
{

	if(g_tKillPreview[client] != null)
		TriggerTimer(g_tKillPreview[client], false);
	
	int m_iViewModel = CreateEntityByName("prop_dynamic_override"); //prop_physics_multiplayer
	
	DispatchKeyValue(m_iViewModel, "targetname","1");
	DispatchKeyValue(m_iViewModel, "spawnflags", "64");
	DispatchKeyValue(m_iViewModel, "model", "models/weapons/stickers/v_models/pist_deagle_decal_a.mdl");
	DispatchKeyValue(m_iViewModel, "rendermode", "0");
	DispatchKeyValue(m_iViewModel, "renderfx", "0");
	DispatchKeyValue(m_iViewModel, "rendercolor", "255 255 255");
	DispatchKeyValue(m_iViewModel, "renderamt", "255");
	DispatchKeyValue(m_iViewModel, "solid", "0");
    
	DispatchSpawn(m_iViewModel);
	
	SetEntProp(m_iViewModel, Prop_Send, "m_CollisionGroup", 11);
		
	AcceptEntityInput(m_iViewModel, "Enable");
	
	int offset = GetEntSendPropOffs(m_iViewModel, "m_clrGlow");
	SetEntProp(m_iViewModel, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(m_iViewModel, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(m_iViewModel, Prop_Send, "m_flGlowMaxDist", 2000.0);

    //Miku Green
	SetEntData(m_iViewModel, offset    ,  57, _, true);
	SetEntData(m_iViewModel, offset + 1, 100, _, true);
	SetEntData(m_iViewModel, offset + 2, 200, _, true);
	SetEntData(m_iViewModel, offset + 3, 10, _, true);

	float m_fOrigin[3], m_fAngles[3], m_fRadians[2], m_fPosition[3];

	GetClientAbsOrigin(client, m_fOrigin);
	GetClientAbsAngles(client, m_fAngles);

	m_fRadians[0] = DegToRad(m_fAngles[0]);
	m_fRadians[1] = DegToRad(m_fAngles[1]);

	m_fPosition[0] = m_fOrigin[0] + 64 * Cosine(m_fRadians[0]) * Cosine(m_fRadians[1]);
	m_fPosition[1] = m_fOrigin[1] + 64 * Cosine(m_fRadians[0]) * Sine(m_fRadians[1]);
	m_fPosition[2] = m_fOrigin[2] + 4 * Sine(m_fRadians[0]);
    
	m_fAngles[0] *= -1.0;
	m_fAngles[1] *= -1.0;

	
	TeleportEntity(m_iViewModel, m_fPosition, m_fAngles, NULL_VECTOR);
	int charm_view = CreateEntityByName("env_sprite_oriented");
	DispatchKeyValue(charm_view, "model", "models/weapons/customization/stickers/emskatowice2014/titan_holo.vmt");
	DispatchKeyValue(charm_view, "classname", "env_sprite_oriented");
	DispatchKeyValue(charm_view, "spawnflags", "1");
	DispatchKeyValueFloat(charm_view, "scale", 0.1);
	DispatchKeyValue(charm_view, "rendermode", "1");
	DispatchKeyValue(charm_view, "rendercolor", "255 255 255");
	DispatchKeyValue(charm_view, "framerate","1");
    DispatchKeyValueVector(charm_view, "Angles", m_fAngles);
	DispatchSpawn(charm_view);
	
	/**
	offset = GetEntSendPropOffs(charm_view, "m_clrGlow");
	SetEntProp(charm_view, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(charm_view, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(charm_view, Prop_Send, "m_flGlowMaxDist", 2000.0);

    //Miku Green
	SetEntData(charm_view, offset    ,  57, _, true);
	SetEntData(charm_view, offset + 1, 100, _, true);
	SetEntData(charm_view, offset + 2, 200, _, true);
	SetEntData(charm_view, offset + 3, 10, _, true);
	**/
	
	//SetEntPropFloat(charm_view, Prop_Send, "m_flModelScale", 0.01);
	
	
	TeleportEntity(charm_view, m_fPosition, m_fAngles, NULL_VECTOR);
	
	parentEntity(charm_view, m_iViewModel);
	
	
	g_iPreviewTimes[client] = GetTime()+45;
	g_iPreviewModel[client] = EntIndexToEntRef(m_iViewModel);

	SDKHook(m_iViewModel, SDKHook_SetTransmit, Hook_SetTransmit_Preview);
	SDKHook(charm_view, SDKHook_SetTransmit, Hook_SetTransmit_Preview);
	
	g_tKillPreview[client] = CreateTimer(45.0, Timer_KillPreview, client);
	
}

public void parentEntity(int child, int parent) {
    AcceptEntityInput(child, "SetParent", parent);
}

public Action Hook_SetTransmit_Preview(int ent, int client)
{
    if(g_iPreviewModel[client] == INVALID_ENT_REFERENCE)
        return Plugin_Handled;
    
    if(ent == EntRefToEntIndex(g_iPreviewModel[client]))
        return Plugin_Continue;

    return Plugin_Handled;
}

public Action Timer_KillPreview(Handle timer, int client)
{
    g_tKillPreview[client] = null;

    if(g_iPreviewModel[client] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iPreviewModel[client]);

        if(IsValidEdict(entity))
        {
            SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit_Preview);
            AcceptEntityInput(entity, "Kill");
        }
    }
    g_iPreviewModel[client] = INVALID_ENT_REFERENCE;

    return Plugin_Stop;
}