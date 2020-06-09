#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <shavit>
#include <cstrike>

#undef REQUIRE_PLUGIN
// for MapChange type
#include <mapchooser>

#define PLUGIN_VERSION "1.0.4"

Database g_hDatabase;
char g_cSQLPrefix[32];

bool g_bLate;

#if defined DEBUG
bool g_bDebug;
#endif

/* ConVars */
ConVar g_cvRTVRequiredPercentage;
ConVar g_cvRTVAllowSpectators;
ConVar g_cvRTVMinimumPoints;
ConVar g_cvRTVDelayTime;
ConVar g_HostnameCvar;

ConVar g_cvMapVoteDuration;
ConVar g_cvMapVoteBlockMapInterval;
ConVar g_cvMapVoteExtendLimit;
ConVar g_cvMapVoteEnableNoVote;



/* Map arrays */
ArrayList g_aMapList;

ArrayList g_aMapTiers;
ArrayList g_aNominateList;
ArrayList g_aOldMaps;

/* Map Data */
char g_cMapName[PLATFORM_MAX_PATH];

MapChange g_ChangeTime;

bool g_bMapVoteStarted;
bool g_bMapVoteFinished;
float g_fMapStartTime;

int g_iExtendCount;

int mintier = 1,maxtier = 9;

Menu g_hNominateMenu;

/* Player Data */
bool	g_bRockTheVote[MAXPLAYERS + 1];
char g_cNominatedMap[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

enum MapListType
{
	MapListZoned,
	MapListFile,
	MapListFolder
}

public Plugin myinfo =
{
	name = "shavit - MapChooser",
	author = "SlidyBat",
	description = "Automated Map Voting and nominating with Shavit timer integration",
	version = PLUGIN_VERSION,
	url = ""
}

public APLRes AskPluginLoad2( Handle myself, bool late, char[] error, int err_max )
{
	g_bLate = late;
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent( "round_start", OnRoundStartPost );

	g_aMapList = new ArrayList( ByteCountToCells(PLATFORM_MAX_PATH) );
	
	g_aMapTiers = new ArrayList();
	g_aNominateList = new ArrayList( ByteCountToCells(PLATFORM_MAX_PATH) );
	g_aOldMaps = new ArrayList( ByteCountToCells(PLATFORM_MAX_PATH) );
	

	
	g_cvMapVoteBlockMapInterval = CreateConVar( "smc_mapvote_blockmap_interval", "40", "How many maps should be played before a map can be nominated again", _, true, 0.0, false );
	g_cvMapVoteEnableNoVote = CreateConVar( "smc_mapvote_enable_novote", "1", "Whether players are able to choose 'No Vote' in map vote", _, true, 0.0, true, 1.0 );
	g_cvMapVoteExtendLimit = CreateConVar( "smc_mapvote_extend_limit", "3", "How many times players can choose to extend a single map (0 = block extending)", _, true, 0.0, false );
	
	g_cvMapVoteDuration = CreateConVar( "smc_mapvote_duration", "1", "Duration of time in minutes that map vote menu should be displayed for", _, true, 0.1, false );
	
	g_cvRTVAllowSpectators = CreateConVar( "smc_rtv_allow_spectators", "1", "Whether spectators should be allowed to RTV", _, true, 0.0, true, 1.0 );
	g_cvRTVMinimumPoints = CreateConVar( "smc_rtv_minimum_points", "-1", "Minimum number of points a player must have before being able to RTV, or -1 to allow everyone", _, true, -1.0, false );
	g_cvRTVDelayTime = CreateConVar( "smc_rtv_delay", "5", "Time in minutes after map start before players should be allowed to RTV", _, true, 0.0, false );
	g_cvRTVRequiredPercentage = CreateConVar( "smc_rtv_required_percentage", "50", "Percentage of players who have RTVed before a map vote is initiated", _, true, 1.0, true, 100.0 );
	g_HostnameCvar = FindConVar("hostname");
	
	AutoExecConfig();
	
	RegAdminCmd( "sm_yanchang", Command_Extend, ADMFLAG_CHANGEMAP, "Admin command for extending map" );
	RegAdminCmd( "sm_forcemapvote", Command_ForceMapVote, ADMFLAG_RCON, "Admin command for forcing the end of map vote" );
	RegAdminCmd( "sm_reloadmaplist", Command_ReloadMaplist, ADMFLAG_CHANGEMAP, "Admin command for forcing maplist to be reloaded" );
	
	RegConsoleCmd( "sm_nominate", Command_Nominate, "Lets players nominate maps to be on the end of map vote" );
	RegConsoleCmd( "sm_yd", Command_Nominate, "Lets players nominate maps to be on the end of map vote" );
	
	RegConsoleCmd( "sm_rtv", Command_RockTheVote, "Lets players Rock The Vote" );
	
	
	if( g_bLate )
	{
		OnMapStart();
	}
	
	#if defined DEBUG
	RegConsoleCmd( "sm_smcdebug", Command_Debug );
	#endif
}

public void OnMapStart()
{
	
	GetCurrentMap( g_cMapName, sizeof(g_cMapName) );
	char buffer[128];
	
	g_HostnameCvar.GetString(buffer, sizeof(buffer));
	
	if(StrContains(buffer,"竞速")!= -1)
	{
		maxtier = 2;
		mintier = 1;
	}
	
	if(StrContains(buffer,"综合")!= -1)
	{
		maxtier = 4;
		mintier = 3;
	}
	
	if(StrContains(buffer,"技巧")!= -1)
	{
		maxtier = 10;
		mintier = 5;
	}
	// disable rtv if delay time is > 0
	g_fMapStartTime = GetGameTime();
	
	g_iExtendCount = 0;
	
	g_bMapVoteFinished = false;
	g_bMapVoteStarted = false;
	
	g_aNominateList.Clear();
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_cNominatedMap[i][0] = '\0';
	}
	ClearRTV();
	
	// reload maplist array
	LoadMapList();
	// cache the nominate menu so that it isn't being built every time player opens it
	CreateNominateMenu();
	
	CreateTimer( 1.0, Timer_OnSecond, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
}

public Action OnRoundStartPost( Event event, const char[] name, bool dontBroadcast )
{
	// disable rtv if delay time is > 0
	g_fMapStartTime = GetGameTime();
	
	g_iExtendCount = 0;
	
	g_bMapVoteFinished = false;
	g_bMapVoteStarted = false;
	
	g_aNominateList.Clear();
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_cNominatedMap[i][0] = '\0';
	}
	ClearRTV();
}

public void OnMapEnd()
{
	if( g_cvMapVoteBlockMapInterval.IntValue > 0 )
	{
		g_aOldMaps.PushString( g_cMapName );
		if( g_aOldMaps.Length > g_cvMapVoteBlockMapInterval.IntValue )
		{
			g_aOldMaps.Erase( 0 );
		}
	}
}

public Action Timer_OnSecond( Handle timer )
{
	#if defined DEBUG
	if( g_bDebug )
	{
		DebugPrint( " OnMapTimeLeftChanged: maplist_length=%i mapvote_started=%s mapvotefinished=%s", g_aMapList.Length, g_bMapVoteStarted ? "true" : "false", g_bMapVoteFinished ? "true" : "false" );
	}
	#endif
	
	int timeleft;
	if( GetMapTimeLeft( timeleft ) )
	{
		if( !g_bMapVoteStarted && !g_bMapVoteFinished )
		{
			int mapvoteTime = timeleft - RoundFloat( 5.0 * 60.0 );
			switch( mapvoteTime )
			{
				case (10 * 60) - 3:
				{
					PrintToChatAll( " 10 分钟 开始 地图投票" );
				}
				case (5 * 60) - 3:
				{
					PrintToChatAll( " 5 分钟 开始 地图投票" );
				}
				case 60 - 3:
				{
					PrintToChatAll( " 1 分钟 开始 地图投票" );
				}
				case 30 - 3:
				{
					PrintToChatAll( " 30 秒 开始 地图投票" );
				}
				case 5 - 3:
				{
					PrintToChatAll( " 5 秒 开始 地图投票" );
				}
			}
		}
		else if( g_bMapVoteFinished )
		{
			switch( timeleft )
			{
				case (30 * 60) - 3:
				{
					PrintToChatAll( " 30 分钟 剩余" );
				}
				case (20 * 60) - 3:
				{
					PrintToChatAll( " 20 分钟 剩余" );
				}
				case (10 * 60) - 3:
				{
					PrintToChatAll( " 10 分钟 剩余" );
				}
				case (5 * 60) - 3:
				{
					PrintToChatAll( " 5 分钟 剩余" );
				}
				case 60 - 3:
				{
					PrintToChatAll( " 1 分钟 剩余" );
				}
				case 10 - 3:
				{
					PrintToChatAll( " 10 秒 剩余" );
				}
				case 5 - 3:
				{
					PrintToChatAll( " 5 秒 剩余" );
				}
				case 3 - 3:
				{
					PrintToChatAll( " 3 秒 剩余" );
				}
				case 2 - 3:
				{
					PrintToChatAll( " 2 秒 剩余" );
				}
				case 1 - 3:
				{
					PrintToChatAll( " 1 秒 剩余" );
				}
			}
		}
	}
	
	if( g_aMapList.Length && !g_bMapVoteStarted && !g_bMapVoteFinished )
	{
		CheckTimeLeft();
	}
}

void CheckTimeLeft()
{
	int timeleft;
	if( GetMapTimeLeft( timeleft ) && timeleft > 0 )
	{
		int startTime = RoundFloat( 5.0 * 60.0 );
		#if defined DEBUG
		if( g_bDebug )
		{
			DebugPrint( " CheckTimeLeft: timeleft=%i startTime=%i", timeleft, startTime );
		}
		#endif
		
		if( timeleft - startTime <= 0 )
		{
			#if defined DEBUG
			if( g_bDebug )
			{
				DebugPrint( " CheckTimeLeft: Initiating map vote ...", timeleft, startTime );
			}
			#endif
		
			InitiateMapVote( MapChange_MapEnd );
		}
	}
	#if defined DEBUG
	else
	{
		if( g_bDebug )
		{
			DebugPrint( " CheckTimeLeft: GetMapTimeLeft=%s timeleft=%i", GetMapTimeLeft(timeleft) ? "true" : "false", timeleft );
		}
	}
	#endif
}

public void OnClientDisconnect( int client )
{
	// clear player data
	g_bRockTheVote[client] = false;
	g_cNominatedMap[client][0] = '\0';
	
	CheckRTV();
}

public void OnClientSayCommand_Post( int client, const char[] command, const char[] sArgs )
{
	if( StrEqual( sArgs, "rtv", false ) || StrEqual( sArgs, "rockthevote", false ) )
	{
		ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
		
		Command_RockTheVote( client, 0 );
		
		SetCmdReplySource(old);
	}
	else if( StrEqual( sArgs, "nominate", false ) )
	{
		ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
		
		Command_Nominate( client, 0 );
		
		SetCmdReplySource(old);
	}
}

void InitiateMapVote( MapChange when )
{
	g_ChangeTime = when;
	g_bMapVoteStarted = true;
	
	// create menu
	Menu menu = new Menu( Handler_MapVoteMenu, MENU_ACTIONS_ALL );
	menu.VoteResultCallback = Handler_MapVoteFinished;
	menu.Pagination = MENU_NO_PAGINATION;
	menu.SetTitle( "Vote for next map:\nPlease choose carefully ... \n \n" );
	
	int mapsToAdd = 8;
	if( g_cvMapVoteExtendLimit.IntValue > 0 && g_iExtendCount < g_cvMapVoteExtendLimit.IntValue )
	{
		mapsToAdd--;
	}
	
	if( g_cvMapVoteEnableNoVote.BoolValue )
	{
		mapsToAdd--;
	}
	
	char map[PLATFORM_MAX_PATH];
	char mapdisplay[PLATFORM_MAX_PATH + 32];
	
	int nominateMapsToAdd = ( mapsToAdd > g_aNominateList.Length ) ? g_aNominateList.Length : mapsToAdd;
	for( int i = 0; i < nominateMapsToAdd; i++ )
	{
		g_aNominateList.GetString( i, map, sizeof(map) );
		
		
		int tier = 1;
		int idx = g_aMapList.FindString( map );
		if( idx != -1 )
		{
			tier = g_aMapTiers.Get( idx );
		}
			
		Format( mapdisplay, sizeof(mapdisplay), "[难度 T%i] %s", tier, map );
		
		
		menu.AddItem( map, mapdisplay );
		
		mapsToAdd--;
	}
	
	for( int i = 0; i < mapsToAdd; i++ )
	{
		int rand = GetRandomInt( 0, g_aMapList.Length - 1 );
		g_aMapList.GetString( rand, map, sizeof(map) );
		int tier = g_aMapTiers.Get( rand );
		
		if( StrEqual( map, g_cMapName ) )
		{
			// don't add current map to vote
			i--;
			continue;
		}
		
		if(tier < mintier || tier > maxtier)
		{
			i--;
			continue;
		}
		
		int idx = g_aOldMaps.FindString( map );
		if( idx != -1 )
		{
			// map already played recently, get another map
			i--;
			continue;
		}
		
		
		
		Format( mapdisplay, sizeof(mapdisplay), "[难度 T%i] %s", tier, map );
		
		strcopy( mapdisplay, sizeof(mapdisplay), map );

		menu.AddItem( map, mapdisplay );
	}
	
	if( when == MapChange_MapEnd && g_cvMapVoteExtendLimit.IntValue > 0 && g_iExtendCount < g_cvMapVoteExtendLimit.IntValue )
	{
		menu.AddItem( "extend", "延长当前地图" );
	}
	else if( when == MapChange_Instant )
	{
		menu.AddItem( "dontchange", "Don't Change" );
	}
	
	menu.NoVoteButton = g_cvMapVoteEnableNoVote.BoolValue;
	menu.ExitButton = false;
	menu.DisplayVoteToAll( RoundFloat( g_cvMapVoteDuration.FloatValue * 60.0 ) );
	
	PrintToChatAll( " Next map vote has started" );
}

public void Handler_MapVoteFinished(Menu menu,
						   int num_votes,
						   int num_clients,
						   const int[][] client_info,
						   int num_items,
						   const int[][] item_info)
{
	char map[PLATFORM_MAX_PATH];
	char displayName[PLATFORM_MAX_PATH];
	
	if( num_votes == 0 )
	{
		menu.GetItem( GetRandomInt( 0, num_votes - 1 ), map, sizeof(map) ); // if no votes, pick a random selection from the vote options
	}
	else
	{
		menu.GetItem(item_info[0][VOTEINFO_ITEM_INDEX], map, sizeof(map), _, displayName, sizeof(displayName));
	}
	
	//PrintToChatAll( "投票结束 地图(%s)", map, (g_ChangeTime == MapChange_Instant) ? "instant" : "map end" );
	
	if( StrEqual( map, "extend" ) )
	{
		g_iExtendCount++;
		
		int time;
		if( GetMapTimeLimit( time ) )
		{
			if( time > 0 )
			{
				ExtendMapTimeLimit( 30 * 60 );						
			}
		}

		PrintToChatAll( " 投票结束. 当前地图被延长." );
		
		// We extended, so we'll have to vote again.
		g_bMapVoteStarted = false;
		
		ClearRTV();
	}
	else if( StrEqual( map, "dontchange" ) )
	{
		g_bMapVoteFinished = false;
		g_bMapVoteStarted = false;
		
		PrintToChatAll( " 地图继续了" );
		
		ClearRTV();
	}
	else
	{	
		if( g_ChangeTime == MapChange_MapEnd )
		{
			SetNextMap(map);
		}
		else if( g_ChangeTime == MapChange_Instant )
		{
			DataPack data;
			CreateDataTimer(2.0, Timer_ChangeMap, data);
			data.WriteString(map);
		}
		
		g_bMapVoteStarted = false;
		g_bMapVoteFinished = true;
		
		PrintToChatAll( " 投票结束 Next map: %s.", map );
	}	
}

public int Handler_MapVoteMenu( Menu menu, MenuAction action, int param1, int param2 )
{
	switch( action )
	{
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_Display:
		{
			Panel panel = view_as<Panel>(param2);
			panel.SetTitle( "下一地图投票" );
		}		
		
		case MenuAction_DisplayItem:
		{
			if (menu.ItemCount - 1 == param2)
			{
				char map[PLATFORM_MAX_PATH], buffer[255];
				menu.GetItem(param2, map, sizeof(map));
				if (strcmp(map, "extend", false) == 0)
				{
					Format( buffer, sizeof(buffer), "延长" );
					return RedrawMenuItem(buffer);
				}
				else if (strcmp(map, "novote", false) == 0)
				{
					Format( buffer, sizeof(buffer), "无投票" );
					return RedrawMenuItem(buffer);					
				}
			}
		}		
	
		case MenuAction_VoteCancel:
		{
			// If we receive 0 votes, pick at random.
			if( param1 == VoteCancel_NoVotes )
			{
				int count = menu.ItemCount;
				char map[PLATFORM_MAX_PATH];
				menu.GetItem(0, map, sizeof(map));
				
				// Make sure the first map in the menu isn't one of the special items.
				// This would mean there are no real maps in the menu, because the special items are added after all maps. Don't do anything if that's the case.
				if( strcmp( map, "extend", false ) != 0 )
				{
					// Get a random map from the list.
					
					// Make sure it's not one of the special items.
					do
					{
						int item = GetRandomInt(0, count - 1);
						menu.GetItem(item, map, sizeof(map));
					}
					while( strcmp( map, "extend", false ) == 0 );
					
					SetNextMap( map );
					g_bMapVoteFinished = true;
				}
			}
			else
			{
				// We were actually cancelled. I guess we do nothing.
			}
			
			g_bMapVoteStarted = false;
		}
	}
	
	return 0;
}

// extends map while also notifying players and setting plugin data
void ExtendMap( int time = 0 )
{
	if( time == 0 )
	{
		time = RoundFloat( 30.0 * 60 );
	}

	ExtendMapTimeLimit( time );
	PrintToChatAll( " 地图被延长了 %.1f 分钟", time / 60.0 );
	
	g_bMapVoteStarted = false;
	g_bMapVoteFinished = false;
}

void LoadMapList()
{
	g_aMapList.Clear();
	g_aMapTiers.Clear();

	delete g_hDatabase;
	SQL_SetPrefix();
			
	char buffer[512];
	g_hDatabase = SQL_Connect( "shavit", true, buffer, sizeof(buffer) );
	
	Format( buffer, sizeof(buffer), "SELECT * FROM `maptiers` ORDER BY `map`");
	g_hDatabase.Query( LoadZonedMapsCallback, buffer, _, DBPrio_High );
	

}

public void LoadZonedMapsCallback( Database db, DBResultSet results, const char[] error, any data )
{
	if( results == null )
	{
		LogError( " - (LoadMapZonesCallback) - %s", error );
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
	
	CreateNominateMenu();
}

bool SMC_FindMap( const char[] mapname, char[] output, int maxlen )
{
	int length = g_aMapList.Length;	
	for( int i = 0; i < length; i++ )
	{
		char entry[PLATFORM_MAX_PATH];
		g_aMapList.GetString( i, entry, sizeof(entry) );
		
		if( StrContains( entry, mapname ) != -1 )
		{
			strcopy( output, maxlen, entry );
			return true;
		}
	}
	
	return false;
}

bool IsRTVEnabled()
{
	float time = GetGameTime();
	return ( time - g_fMapStartTime > g_cvRTVDelayTime.FloatValue * 60 );
}

void ClearRTV()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_bRockTheVote[i] = false;
	}
}

/* Timers */
public Action Timer_ChangeMap( Handle timer, DataPack data )
{
	char map[PLATFORM_MAX_PATH];
	data.Reset();
	data.ReadString( map, sizeof(map) );
	
	SetNextMap( map );
	ForceChangeLevel( map, "RTV Mapvote" );
}

/* Commands */
public Action Command_Extend( int client, int args )
{
	int extendtime;
	if( args > 0 )
	{
		char sArg[8];
		GetCmdArg( 1, sArg, sizeof(sArg) );
		extendtime = RoundFloat( StringToFloat( sArg ) * 60 );
	}
	else
	{
		extendtime = RoundFloat( 30.0 * 60.0 );
	}
	
	ExtendMap( extendtime );
	
	return Plugin_Handled;
}

public Action Command_ForceMapVote( int client, int args )
{
	if( g_bMapVoteStarted || g_bMapVoteFinished )
	{
		ReplyToCommand( client, " 地图投票已经 %s", ( g_bMapVoteStarted ) ? "开始" : "结束" );
	}
	else
	{
		InitiateMapVote( MapChange_Instant );
	}
	
	return Plugin_Handled;
}

public Action Command_ReloadMaplist( int client, int args )
{
	LoadMapList();
	
	return Plugin_Handled;
}

public Action Command_Nominate( int client, int args )
{
	if( args < 1 )
	{
		OpenNominateMenu( client );
		return Plugin_Handled;
	}
	
	char mapname[PLATFORM_MAX_PATH];
	GetCmdArg( 1, mapname, sizeof(mapname) );
	if( SMC_FindMap( mapname, mapname, sizeof(mapname) ) )
	{
		if( StrEqual( mapname, g_cMapName ) )
		{
			ReplyToCommand( client, " 无法预定当前地图" );
			return Plugin_Handled;
		}
		
		int idx = g_aOldMaps.FindString( mapname );
		if( idx != -1 )
		{
			ReplyToCommand( client, " %s 已经在最近玩过", mapname );
			return Plugin_Handled;
		}
	
		ReplySource old = SetCmdReplySource( SM_REPLY_TO_CHAT );
		Nominate( client, mapname );
		SetCmdReplySource( old );
	}
	else
	{
		PrintToChatAll( " 找不到 '%s'", mapname );
	}
	
	return Plugin_Handled;
}



void CreateNominateMenu()
{
	delete g_hNominateMenu;
	g_hNominateMenu = new Menu( NominateMenuHandler );
	
	g_hNominateMenu.SetTitle( "预定菜单" );
	
	int length = g_aMapList.Length;
	for( int i = 0; i < length; i++ )
	{
		int tier = g_aMapTiers.Get( i );
		
		char mapname[PLATFORM_MAX_PATH];
		g_aMapList.GetString( i, mapname, sizeof(mapname) );
		
		if( StrEqual( mapname, g_cMapName ) )
		{
			continue;
		}
		
		int idx = g_aOldMaps.FindString( mapname );
		if( idx != -1 )
		{
			continue;
		}
		
		if(tier < mintier || tier > maxtier)
		{
			continue;
		}
		
		char mapdisplay[PLATFORM_MAX_PATH + 32];
		Format( mapdisplay, sizeof(mapdisplay), "%s (难度 T%i)", mapname, tier );
		
		g_hNominateMenu.AddItem( mapname, mapdisplay );
	}
}

void OpenNominateMenu( int client )
{
	g_hNominateMenu.Display( client, MENU_TIME_FOREVER );
}

public int NominateMenuHandler( Menu menu, MenuAction action, int param1, int param2 )
{
	if( action == MenuAction_Select )
	{
		char mapname[PLATFORM_MAX_PATH];
		menu.GetItem( param2, mapname, sizeof(mapname) );
		
		Nominate( param1, mapname );
	}
}

void Nominate( int client, const char mapname[PLATFORM_MAX_PATH] )
{
	int idx = g_aNominateList.FindString( mapname );
	if( idx != -1 )
	{
		ReplyToCommand( client, " %s 已经被预定了", mapname );
		return;
	}
	
	if( g_cNominatedMap[client][0] != '\0' )
	{
		RemoveString( g_aNominateList, g_cNominatedMap[client] );
	}
	
	g_aNominateList.PushString( mapname );
	g_cNominatedMap[client] = mapname;
	
	PrintToChatAll( " %N 预定了 %s", client, mapname );
}

public Action Command_RockTheVote( int client, int args )
{
	if( !IsRTVEnabled() )
	{
		ReplyToCommand( client, " RTV has not been enabled yet." );
	}
	else if( g_bMapVoteStarted )
	{
		ReplyToCommand( client, " Map vote in progress" );
	}
	else if( g_bRockTheVote[client] )
	{
		int needed = GetRTVVotesNeeded();
		ReplyToCommand( client, " 你已经rtv过了(需要 %i票)", needed);
	}
	else if( g_cvRTVMinimumPoints.IntValue != -1 && Shavit_GetPoints( client ) <= g_cvRTVMinimumPoints.FloatValue )
	{
		ReplyToCommand( client, " You must be a higher rank to RTV!" );
	}
	else if( GetClientTeam( client ) == CS_TEAM_SPECTATOR && !g_cvRTVAllowSpectators.BoolValue )
	{
		ReplyToCommand( client, " Spectators have been blocked from RTVing" );
	}
	else
	{
		g_bRockTheVote[client] = true;
		CheckRTV( client );
	}
	
	return Plugin_Handled;
}

void CheckRTV( int client = 0 )
{
	int needed = GetRTVVotesNeeded();
	
	if( needed > 0 )
	{
		if( client != 0 )
		{
			PrintToChatAll( " %N 想要rtv! (需要 %i票)", client, needed);
		}
	}
	else
	{
		if( g_bMapVoteFinished )
		{
			char map[PLATFORM_MAX_PATH];
			GetNextMap( map, sizeof(map) );
		
			if( client != 0 )
			{
				PrintToChatAll( " %N 想要rtv! 地图修改为 %s ...", client, map );
			}
			else
			{
				PrintToChatAll( " 地图修改为 %s ...", map );
			}
			
			ChangeMapDelayed( map );
		}
		else
		{
			if( client != 0 )
			{
				PrintToChatAll( " %N 想要换图! 地图投票开始 ...", client );
			}
			else
			{
				PrintToChatAll( " 地图投票开始 ..." );
			}
			
			InitiateMapVote( MapChange_Instant );
		}
	}
}



#if defined DEBUG
public Action Command_Debug( int client, int args )
{
	if( IsSlidy( client ) )
	{
		g_bDebug = !g_bDebug;
		ReplyToCommand( client, " Debug mode: %s", g_bDebug ? "ENABLED" : "DISABLED" );
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
#endif

/* Stocks */
stock void SQL_SetPrefix()
{
	char sFile[PLATFORM_MAX_PATH];
	BuildPath( Path_SM, sFile, sizeof(sFile), "configs/shavit-prefix.txt" );

	File fFile = OpenFile( sFile, "r" );
	if( fFile == null )
	{
		SetFailState("Cannot open \"configs/shavit-prefix.txt\". Make sure this file exists and that the server has read permissions to it.");
	}

	char sLine[PLATFORM_MAX_PATH*2];
	while( fFile.ReadLine( sLine, sizeof(sLine) ) )
	{
		TrimString( sLine );
		strcopy( g_cSQLPrefix, sizeof(g_cSQLPrefix), sLine );

		break;
	}

	delete fFile;	
}

stock void RemoveString( ArrayList array, const char[] target )
{
	int idx = array.FindString( target );
	if( idx != -1 )
	{
		array.Erase( idx );
	}
}

stock bool LoadFromMapsFolder( ArrayList list )
{
	//from yakmans maplister plugin
	DirectoryListing mapdir = OpenDirectory("maps/");
	if( mapdir == null )
		return false;
	
	char name[PLATFORM_MAX_PATH];
	FileType filetype;
	int namelen;
	
	while( mapdir.GetNext( name, sizeof(name), filetype ) )
	{
		if( filetype != FileType_File )
			continue;
				
		namelen = strlen( name ) - 4;
		if( StrContains( name, ".bsp", false ) != namelen )
			continue;
				
		name[namelen] = '\0';
			
		list.PushString( name );
	}

	delete mapdir;

	return true;
}

stock void ChangeMapDelayed( const char[] map, float delay = 2.0 )
{
	DataPack data;
	CreateDataTimer( delay, Timer_ChangeMap, data );
	data.WriteString( map );
}

stock int GetRTVVotesNeeded()
{
	int total = 0;
	int rtvcount = 0;
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame( i ) )
		{
			// dont count players that can't vote
			if( !g_cvRTVAllowSpectators.BoolValue && IsClientObserver( i ) )
			{
				continue;
			}
			
			if( g_cvRTVMinimumPoints.IntValue != -1 && Shavit_GetPoints( i ) <= g_cvRTVMinimumPoints.FloatValue )
			{
				continue;
			}
		
			total++;
			if( g_bRockTheVote[i] )
			{
				rtvcount++;
			}
		}
	}
	
	int  totalNeeded = RoundToCeil( total * (g_cvRTVRequiredPercentage.FloatValue / 100) );
	
	// always clamp to 1, so if rtvcount is 0 it never initiates RTV
	if( totalNeeded < 1 )
	{
		totalNeeded = 1;
	}
	
	return totalNeeded - rtvcount;
}

stock void DebugPrint( const char[] message, any ... )
{		
	char buffer[256];
	VFormat( buffer, sizeof( buffer ), message, 2 );
	
	for( int i = 1; i <= MaxClients; i++ )
	{
		// STEAM_1:1:159678344 (SlidyBat)
		if( GetSteamAccountID( i ) == 319356689 )
		{
			PrintToChat( i, buffer );
			return;
		}
	}
}