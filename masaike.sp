#include <sourcemod>
#include <sdktools>

Database g_dDatabase = null;

bool painter[MAXPLAYERS+1];

char szMap[128];

int decals;

Handle adt_decal_position	= INVALID_HANDLE;

public OnPluginStart()
{	
	adt_decal_position = CreateArray(3);
	RegAdminCmd("sm_cc",Command_RemoveDecal,ADMFLAG_KICK,"debug");
	RegAdminCmd("sm_oo", Command_Decal, ADMFLAG_KICK, "Vote extend command");
	RegAdminCmd("sm_oodel", Command_DecalDel, ADMFLAG_KICK, "Del map decals");
    //HookEvent("bullet_impact",Decal_BulletImpact);
	SQL_MakeConnection();
	
}
public Action Command_Decal(int client,int args)
{
	painter[client]=true;
	PrintToChat(client,"瞄准后按E贴图");
}
public Action Command_DecalDel(int client,int args)
{
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "DELETE FROM `decals` WHERE `map` = '%s'",szMap);
	g_dDatabase.Query(SQL_CheckForErrors, szQuery);
	PrintToChat(client,"已从数据库中删除所有当前地图Decals落点");
}
public Action Command_RemoveDecal(int client,int args)
{
	PrintToChatAll("%i",decals);
	decl Float:position[3];
	for (new i=0; i<decals; ++i) {
		GetArrayArray(adt_decal_position, i, _:position);
		PrintToChatAll("%f,%f,%f",position[0],position[1],position[2]);
	}
}
public void OnMapStart()
{
	ClearArray(adt_decal_position);
	GetCurrentMap(szMap, 128);
	GetDecal();
}
public OnMapEnd() {
	ClearArray(adt_decal_position);
}
/**
public Action Decal_BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(painter[client])
	{
		decl Float:m_fImpact[3];
		char posx[32],posy[32],posz[32];

		m_fImpact[0] = GetEventFloat(event, "x");
		FloatToString(m_fImpact[0],posx,sizeof(posx));
		
		m_fImpact[1] = GetEventFloat(event, "y");
		FloatToString(m_fImpact[1],posy,sizeof(posy));
		
		m_fImpact[2] = GetEventFloat(event, "z");
		FloatToString(m_fImpact[2],posz,sizeof(posz));
		
		TE_Start("BSP Decal");
		TE_WriteVector("m_vecOrigin", pos);
		TE_WriteNum("m_nEntity",0);
		TE_WriteNum("m_nIndex",PrecacheDecal("decals/custom/example/neko.vmt", true));
		TE_SendToAll();
		char szQuery[512];
		FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `decals` (`map`,`x`,`y`,`z`) VALUES ('%s','%s','%s','%s')",szMap,posx,posy,posz);
		g_dDatabase.Query(SQL_CheckForErrors, szQuery);
		UpdateRow();
		painter[client]=false;
		PrintToChat(client,"贴图落点已上传");
	}
}
**/
public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon) 
{
	if (iButtons & IN_USE && painter[client])
	{
		paint(client);
	}
}
void paint(int client)
{
	float vAngles[3], vOrigin[3],pos[3];
	char posx[32],posy[32],posz[32];
	GetClientEyePosition( client, vOrigin );
	GetClientEyeAngles( client, vAngles );
	TR_TraceRayFilter( vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer );
	if( TR_DidHit() )
		TR_GetEndPosition( pos );
	FloatToString(pos[0],posx,sizeof(posx));	
	FloatToString(pos[1],posy,sizeof(posy));
	FloatToString(pos[2],posz,sizeof(posz));
	
	TE_Start("BSP Decal");
	TE_WriteVector("m_vecOrigin", pos);
	TE_WriteNum("m_nEntity",0);
	TE_WriteNum("m_nIndex",PrecacheDecal("decals/custom/example/neko.vmt", true));
	TE_SendToAll();
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `decals` (`map`,`x`,`y`,`z`) VALUES ('%s','%s','%s','%s')",szMap,posx,posy,posz);
	g_dDatabase.Query(SQL_CheckForErrors, szQuery);
	UpdateRow();
	painter[client]=false;
	PrintToChat(client,"贴图落点已上传");
	
}
void SQL_MakeConnection()
{
	if (g_dDatabase != null)
		delete g_dDatabase;
	char szError[512];
	g_dDatabase = SQL_Connect("shavit", true, szError, sizeof(szError));
	if (g_dDatabase == null)
	{
		SetFailState("Cannot connect to datbase error: %s", szError);
	}
	
}
void UpdateRow()
{
	char buffer[128];
	FormatEx(buffer, sizeof(buffer), "SELECT COUNT(*) count FROM decals WHERE `map` = '%s'",szMap);
	g_dDatabase.Query(HowManyRow, buffer, 0, DBPrio_High);
}
void GetDecal()
{
	char buffer[128];
	Format( buffer, sizeof(buffer), "SELECT * FROM `decals` WHERE `map` = '%s'",szMap);
	g_dDatabase.Query( LoadDecalsCallback, buffer, _, DBPrio_High );
	UpdateRow();
}

public void LoadDecalsCallback( Database db, DBResultSet results, const char[] error, any data )
{
	decl Float:position[3];
	char pos[12];
	while(results.FetchRow())
	{
		results.FetchString(1, pos, sizeof(pos));
		position[0]=StringToFloat(pos);
		results.FetchString(2, pos, sizeof(pos));
		position[1]=StringToFloat(pos);
		results.FetchString(3, pos, sizeof(pos));
		position[2]=StringToFloat(pos);
		PushArrayArray(adt_decal_position,_:position);
	}
}
public void HowManyRow(Database db, DBResultSet results, const char[] error, any data)
{
	if(results.FetchRow())
	{
		decals = results.FetchInt(0);
	}
}
public OnClientPostAdminCheck(client) {
	painter[client]=false;
	decl Float:position[3];
	for (new i=0; i<decals; ++i) {
		GetArrayArray(adt_decal_position, i, _:position);
		TE_Start("BSP Decal");
		TE_WriteVector("m_vecOrigin", position);
		TE_WriteNum("m_nEntity",0);
		TE_WriteNum("m_nIndex",PrecacheDecal("decals/custom/example/neko.vmt", true));
		TE_SendToClient(client);
	}
}
public void SQL_CheckForErrors(Database db, DBResultSet results, const char[] error, any data)
{	
	
	if (!StrEqual(error, ""))
	{
		LogError("Databse error, %s", error);
		return;
	}
}
public bool TraceEntityFilterPlayer( int entity, int contentsMask )
{
	return ( entity > MaxClients || !entity );
}