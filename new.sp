#include <cstrike>
#include <sourcemod>
ArrayList g_aMapList;
ArrayList g_aMapTiers;
Database g_hDatabase;
public void OnPluginStart()
{
	g_aMapList = new ArrayList( ByteCountToCells(PLATFORM_MAX_PATH) );
	g_aMapTiers = new ArrayList();
	OnMapStart();
	RegConsoleCmd( "sm_lol", Command_lol, "Lets players Rock The Vote" );
}
public Action Command_lol( int client, int args )
{
	char map[PLATFORM_MAX_PATH];
	PrintToChatAll( "maplist_length=%i", g_aMapList.Length);
	int length = g_aMapList.Length;	
	for( int i = 0; i < length; i++ )
	{
		g_aMapList.GetString( i, map, sizeof(map) );
		PrintToChatAll( "%s",map );
	}
	
}
public void OnMapStart()
{
	LoadMapList();
}
void LoadMapList()
{
	g_aMapList.Clear();
	g_aMapTiers.Clear();
	char buffer[512];
	g_hDatabase = SQL_Connect( "shavit", true, buffer, sizeof(buffer) );
	Format( buffer, sizeof(buffer), "SELECT * FROM `maptiers` ORDER BY `map`");
	g_hDatabase.Query( LoadZonedMapsCallback, buffer, _, DBPrio_High );
}
public void LoadZonedMapsCallback( Database db, DBResultSet results, const char[] error, any data )
{
	if( results == null )
	{
		LogError( "[SMC] - (LoadMapZonesCallback) - %s", error );
		return;	
	}

	char map[PLATFORM_MAX_PATH];
	while( results.FetchRow() )
	{	
		results.FetchString( 0, map, sizeof(map) );
		
		// TODO: can this cause duplicate entries?
		if( FindMap( map, map, sizeof(map) ) != FindMap_NotFound )
		{
			GetMapDisplayName( map, map, sizeof(map) );
			g_aMapList.PushString( map );
			g_aMapTiers.Push( results.FetchInt( 1 ) );
		}
	}
}