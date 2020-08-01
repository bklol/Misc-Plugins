#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <smlib>

#define PLUGIN_VERSION "1.0"

#define PREFIX "\x04Snake \x01> \x03"

#define FIELD_X 14
#define FIELD_Y 11

#define COORD_X 0
#define COORD_Y 1

#define CHAR_WORM "█"
#define CHAR_FOOD "▒"
#define CHAR_AWESOMEFOOD "▒"
#define CHAR_SPACE "░"

#define AWESOME_NOMNOM_LIFETIME 50
#define WORM_MIN_LENGTH 3
#define FOOD_SCORE 100

enum WormDirection
{
	Direction_Right = 0,
	Direction_Down,
	Direction_Left,
	Direction_Up
}

enum struct WormMode
{
	int Mode_Snake1; // walls are solid
	int Mode_Snake2; // walls are walkable
}

int g_iWormPositions[MAXPLAYERS+1][FIELD_X*FIELD_Y][2];
WormDirection g_iWormCurrentDirection[MAXPLAYERS+1];
WormDirection g_iWormNextDirection[MAXPLAYERS+1];
int g_iWormLength[MAXPLAYERS+1];
int g_iNomNomPosition[MAXPLAYERS+1][2];
int g_iAwesomeNomNomPosition[MAXPLAYERS+1][2];
Handle g_hGameThink[MAXPLAYERS+1] = {INVALID_HANDLE,...};
int g_iNextAwesomeNomNom[MAXPLAYERS+1] = 0;
int g_iAwesomeNomNomLifetime[MAXPLAYERS+1] = 0;
WormMode g_iSnakeMode[MAXPLAYERS+1];

int g_iScore[MAXPLAYERS+1];
WormMode g_iHighScore[MAXPLAYERS+1];
Handle g_hDatabase;

int g_iButtons[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Snake",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Snake minigame",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public void OnPluginStart()
{
	Handle hVersion = CreateConVar("sm_snake_version", PLUGIN_VERSION, "", 0|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	RegConsoleCmd("sm_snake", Cmd_StartSnake, "Start a snake minigame session.");
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	
	SQL_TConnect(SQL_OnDatabaseConnected, (SQL_CheckConfig("snake")?"snake":"storage-local"));
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if(g_hDatabase != INVALID_HANDLE)
		SQL_TQueryF(view_as<Database>(g_hDatabase), SQL_GetClientHighscores, GetClientUserId(client), DBPrio_Normal, "SELECT score1, score2 FROM snake_players WHERE steamid = \"%s\";", auth);
}

public void OnClientDisconnect(int client)
{
	ClearTimer(g_hGameThink[client]);
	ResetSnakeGame(client);
	g_iButtons[client] = 0;
	g_iHighScore[client].Mode_Snake1 = 0;
	g_iHighScore[client].Mode_Snake2 = 0;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	// move up
	if( (buttons & IN_FORWARD) && !(g_iButtons[client] & IN_FORWARD) )
	{
		if(GetOppositeDirection(g_iWormCurrentDirection[client]) != Direction_Up)
			g_iWormNextDirection[client] = Direction_Up;
	}
	else if( (buttons & IN_MOVERIGHT) && !(g_iButtons[client] & IN_MOVERIGHT) )
	{
		if(GetOppositeDirection(g_iWormCurrentDirection[client]) != Direction_Right)
			g_iWormNextDirection[client] = Direction_Right;
	}
	else if( (buttons & IN_BACK) && !(g_iButtons[client] & IN_BACK) )
	{
		if(GetOppositeDirection(g_iWormCurrentDirection[client]) != Direction_Down)
			g_iWormNextDirection[client] = Direction_Down;
	}
	else if( (buttons & IN_MOVELEFT) && !(g_iButtons[client] & IN_MOVELEFT) )
	{
		if(GetOppositeDirection(g_iWormCurrentDirection[client]) != Direction_Left)
			g_iWormNextDirection[client] = Direction_Left;
	}
	
	g_iButtons[client] = buttons;
}

public void Event_OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_hGameThink[client] != INVALID_HANDLE)
	{
		// Disable any movement
		SetEntProp(client, Prop_Send, "m_fFlags", FL_CLIENT|FL_ATCONTROLS);
	}
}

public Action Cmd_StartSnake(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "Snake: This command is ingame only.");
		return Plugin_Handled;
	}
	
	if(g_hGameThink[client] != INVALID_HANDLE)
	{
		ClearTimer(g_hGameThink[client]);
		PrintToChat(client, "%sGame paused.", PREFIX);
		SetEntProp(client, Prop_Send, "m_fFlags", FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND);
	}
	
	Handle hMenu = CreateMenu(Menu_HandleMainMenu);
	SetMenuTitle(hMenu, "Snake: Mainmenu");
	SetMenuExitButton(hMenu, true);
	
	AddMenuItem(hMenu, "resume", "Resume game", (g_iWormLength[client]>0?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
	AddMenuItem(hMenu, "newgame", "Start Snake with solid walls");
	AddMenuItem(hMenu, "newgame2", "Start Snake2 with non-blocking walls");
	
	AddMenuItem(hMenu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(hMenu, "top10", "Show Snake top 10");
	AddMenuItem(hMenu, "top10_2", "Show Snake2 top 10");
	
	char sMenu[64];
	Format(sMenu, sizeof(sMenu), "Your best Snake score: %d", g_iHighScore[client].Mode_Snake1);
	AddMenuItem(hMenu, "", sMenu, ITEMDRAW_DISABLED);
	Format(sMenu, sizeof(sMenu), "Your best Snake2 score: %d", g_iHighScore[client].Mode_Snake2);
	AddMenuItem(hMenu, "", sMenu, ITEMDRAW_DISABLED);
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int Menu_HandleMainMenu(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		// Start a int game with solid walls
		if(StrEqual(info, "newgame"))
		{
			SetupSnakeGame(param1);
			
			g_iSnakeMode[param1] = Mode_Snake1;
			
			g_hGameThink[param1] = CreateTimer(0.1, Timer_OnGameThink, GetClientUserId(param1), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			TriggerTimer(g_hGameThink[param1]);
			
			// Disable any movement
			SetEntProp(param1, Prop_Send, "m_fFlags", FL_CLIENT|FL_ATCONTROLS);
		}
		else if(StrEqual(info, "newgame2"))
		{
			SetupSnakeGame(param1);
			
			g_iSnakeMode[param1] = Mode_Snake2;
			
			g_hGameThink[param1] = CreateTimer(0.1, Timer_OnGameThink, GetClientUserId(param1), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			TriggerTimer(g_hGameThink[param1]);
			
			// Disable any movement
			SetEntProp(param1, Prop_Send, "m_fFlags", FL_CLIENT|FL_ATCONTROLS);
		}
		else if(StrEqual(info, "resume"))
		{
			g_hGameThink[param1] = CreateTimer(0.1, Timer_OnGameThink, GetClientUserId(param1), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			TriggerTimer(g_hGameThink[param1]);
			
			// Disable any movement
			SetEntProp(param1, Prop_Send, "m_fFlags", FL_CLIENT|FL_ATCONTROLS);
		}
		else if(StrEqual(info, "top10"))
		{
			SQL_TQueryF(view_as<Database>(g_hDatabase), SQL_FetchTop10, GetClientUserId(param1), DBPrio_Normal, "SELECT name, score1 FROM snake_players WHERE score1 > 0 ORDER BY score1 DESC LIMIT 10;");
		}
		else if(StrEqual(info, "top10_2"))
		{
			SQL_TQueryF(view_as<Database>(g_hDatabase), SQL_FetchTop10, GetClientUserId(param1), DBPrio_Normal, "SELECT name, score2 FROM snake_players WHERE score2 > 0 ORDER BY score2 DESC LIMIT 10;");
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int Menu_HandleTop10(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		Cmd_StartSnake(param1, 0);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int Panel_GameHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 10)
		{
			ClearTimer(g_hGameThink[param1]);
			PrintToChat(param1, "%sGame paused. Type !snake to resume.", PREFIX);
			SetEntProp(param1, Prop_Send, "m_fFlags", FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND);
		}
		else if(param2 == 1)
		{
			SetupSnakeGame(param1);
			
			g_hGameThink[param1] = CreateTimer(0.1, Timer_OnGameThink, GetClientUserId(param1), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			TriggerTimer(g_hGameThink[param1]);
			
			// Disable any movement
			SetEntProp(param1, Prop_Send, "m_fFlags", FL_CLIENT|FL_ATCONTROLS);
		}
	}
}

public Action Timer_OnGameThink(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
	
	// Apply the int direction
	g_iWormCurrentDirection[client] = g_iWormNextDirection[client];
	
	// Time for a int awesome one?
	g_iNextAwesomeNomNom[client]--;
	if(g_iNextAwesomeNomNom[client] == 0)
	{
		PutNewNomNomOnField(client, true);
		g_iAwesomeNomNomLifetime[client] = AWESOME_NOMNOM_LIFETIME;
	}
	
	// Too late. This totally awesome food is gone..
	if(g_iAwesomeNomNomLifetime[client] >= 0)
		g_iAwesomeNomNomLifetime[client]--;
	if(g_iAwesomeNomNomLifetime[client] == 0)
	{
		g_iNextAwesomeNomNom[client] = Math_GetRandomInt(100, 300);
		g_iAwesomeNomNomPosition[client][COORD_X] = -1;
		g_iAwesomeNomNomPosition[client][COORD_Y] = -1;
	}
	
	// GAME OVER
	if(!MoveSnake(client))
	{
		PrintToChat(client, "%sGAME OVER! Your score: %d. Don't eat bad food!", PREFIX, g_iScore[client]);
		DrawSnakePanel(client, true);
		
		if(g_iHighScore[client][g_iSnakeMode[client]] < g_iScore[client])
		{
			if(g_hDatabase != INVALID_HANDLE)
			{
				// int iHighscore[WormMode];
				int[] iHighscore = new int[WormMode];
				iHighscore[Mode_Snake1] = g_iHighScore[client].Mode_Snake1;
				iHighscore[Mode_Snake2] = g_iHighScore[client].Mode_Snake2;
				g_iHighScore[client][g_iSnakeMode[client]] = g_iScore[client];
				
				char sName[MAX_NAME_LENGTH];
				char sEscapedName[MAX_NAME_LENGTH*2+1];
				char sAuth[32];
				GetClientName(client, sName, sizeof(sName));
				GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth));
				SQL_EscapeString(g_hDatabase, sName, sEscapedName, sizeof(sEscapedName));
				
				if(iHighscore[Mode_Snake1] > 0 || iHighscore[Mode_Snake2] > 0)
					SQL_TQueryF(view_as<Database>(g_hDatabase), SQL_DoNothing, 0, DBPrio_Normal, "UPDATE snake_players SET name = \"%s\", score1 = %d, score2 = %d WHERE steamid = \"%s\";", sEscapedName, g_iHighScore[client].Mode_Snake1, g_iHighScore[client].Mode_Snake2, sAuth);
				else
					SQL_TQueryF(view_as<Database>(g_hDatabase), SQL_DoNothing, 0, DBPrio_Normal, "INSERT INTO snake_players (name, steamid, score1, score2) VALUES(\"%s\", \"%s\", %d, %d);", sEscapedName, sAuth, g_iHighScore[client].Mode_Snake1, g_iHighScore[client].Mode_Snake2);
			}
			
			g_iHighScore[client][g_iSnakeMode[client]] = g_iScore[client];
			PrintToChat(client, "%sNew personal high score!", PREFIX, g_iScore[client]);
		}
		
		ResetSnakeGame(client);
		SetEntProp(client, Prop_Send, "m_fFlags", FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND);
		g_hGameThink[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	DrawSnakePanel(client, false);
	
	return Plugin_Continue;
}

public void SQL_OnDatabaseConnected(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("Error connecting to database: %s", error);
		return;
	}
	
	g_hDatabase = hndl;
	
	char sDriver[16];
	SQL_ReadDriver(hndl, sDriver, sizeof(sDriver));
	if(StrEqual(sDriver, "sqlite", false))
	{
		SQL_TQuery(hndl, SQL_DoNothing, "CREATE TABLE IF NOT EXISTS snake_players (steamid VARCHAR(64) PRIMARY KEY, name VARCHAR(64) NOT NULL, score1 INTEGER DEFAULT '0', score2 INTEGER DEFAULT '0');");
	}
	else
	{
		SQL_TQuery(hndl, SQL_DoNothing, "SET NAMES 'utf8';");
	}
	
	char sAuth[32];
	for(int i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsClientAuthorized(i))
		{
			GetClientAuthId(i, AuthId_Steam2, sAuth, sizeof(sAuth));
			OnClientAuthorized(i, sAuth);
		}
	}
}

public void SQL_GetClientHighscores(Handle owner, Handle hndl, const char[] error, any userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
	
	int client = GetClientOfUserId(userid);
	if(!client)
		return;
	
	while(SQL_MoreRows(hndl))
	{
		if(!SQL_FetchRow(hndl))
			continue;
		
		g_iHighScore[client].Mode_Snake1 = SQL_FetchInt(hndl, 0);
		g_iHighScore[client].Mode_Snake2 = SQL_FetchInt(hndl, 1);
	}
}

public void SQL_FetchTop10(Handle owner, Handle hndl, const char[] error, any userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
	
	int client = GetClientOfUserId(userid);
	if(!client)
		return;
	
	Handle hMenu = CreateMenu(Menu_HandleTop10);
	SetMenuTitle(hMenu, "Snake: Top 10");
	SetMenuExitBackButton(hMenu, true);
	
	char sMenu[128];
	int iPlace = 1;
	while(SQL_MoreRows(hndl))
	{
		if(!SQL_FetchRow(hndl))
			continue;
		
		SQL_FetchString(hndl, 0, sMenu, sizeof(sMenu));
		Format(sMenu, sizeof(sMenu), "%d. %s: %d", iPlace, sMenu, SQL_FetchInt(hndl, 1));
		AddMenuItem(hMenu, "", sMenu, ITEMDRAW_DISABLED);
		iPlace++;
	}
	
	for(int i=iPlace;i<=10;i++)
	{
		Format(sMenu, sizeof(sMenu), "%d. ", i);
		AddMenuItem(hMenu, "", sMenu, ITEMDRAW_DISABLED);
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public void SQL_DoNothing(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
}

void DrawSnakePanel(int client, bool bGameOver)
{
	Handle hPanel = CreatePanel();
	
	char sGameField[512];
	int iCoords[2];
	for(int y=FIELD_Y-1;y>=0;y--)
	{
		for(int x=0;x<FIELD_X;x++)
		{
			// Put the snake on the field
			iCoords[COORD_X] = x;
			iCoords[COORD_Y] = y;
			if(IsWormThere(client, iCoords))
				Format(sGameField, sizeof(sGameField), "%s%s", sGameField, CHAR_WORM);
			else if(g_iNomNomPosition[client][COORD_X] == x && g_iNomNomPosition[client][COORD_Y] == y)
				Format(sGameField, sizeof(sGameField), "%s%s", sGameField, CHAR_FOOD);
			else if(g_iAwesomeNomNomPosition[client][COORD_X] == x && g_iAwesomeNomNomPosition[client][COORD_Y] == y)
				Format(sGameField, sizeof(sGameField), "%s%s", sGameField, CHAR_AWESOMEFOOD);
			else
				Format(sGameField, sizeof(sGameField), "%s%s", sGameField, CHAR_SPACE);
		}
		DrawPanelText(hPanel, sGameField);
		Format(sGameField, sizeof(sGameField), "");
	}
	
	Format(sGameField, sizeof(sGameField), "Score: %d", g_iScore[client]);
	DrawPanelText(hPanel, sGameField);
	
	if(bGameOver)
	{
		DrawPanelItem(hPanel, "Game over. Restart?");
	}
	else
		SetPanelKeys(hPanel, (1<<9));
	SendPanelToClient(hPanel, client, Panel_GameHandler, (bGameOver?10:1));
	CloseHandle(hPanel);
}

void SetupSnakeGame(int client)
{
	ClearTimer(g_hGameThink[client]);
	ResetSnakeGame(client);
	g_iWormLength[client] = WORM_MIN_LENGTH;
	for(int i=0;i<WORM_MIN_LENGTH;i++)
	{
		g_iWormPositions[client][i][COORD_X] = (FIELD_X/2)-i+1-WORM_MIN_LENGTH;
		g_iWormPositions[client][i][COORD_Y] = FIELD_Y/2;
	}
	
	PutNewNomNomOnField(client);
	
	g_iNextAwesomeNomNom[client] = Math_GetRandomInt(100, 200);
}

void ResetSnakeGame(int client)
{
	for(int i=0;i<FIELD_X*FIELD_Y;i++)
	{
		g_iWormPositions[client][i][COORD_X] = -1;
		g_iWormPositions[client][i][COORD_Y] = -1;
	}
	g_iNomNomPosition[client][COORD_X] = -1;
	g_iNomNomPosition[client][COORD_Y] = -1;
	g_iAwesomeNomNomPosition[client][COORD_X] = -1;
	g_iAwesomeNomNomPosition[client][COORD_Y] = -1;
	g_iWormCurrentDirection[client] = Direction_Right;
	g_iWormNextDirection[client] = Direction_Right;
	g_iWormLength[client] = 0;
	g_iScore[client] = 0;
	g_iNextAwesomeNomNom[client] = 0;
	g_iAwesomeNomNomLifetime[client] = -1;
}

void PutNewNomNomOnField(int client, bool bAwesome=false)
{
	// The gamefield is full..
	if(g_iWormLength[client] == FIELD_X*FIELD_Y)
		return;
	
	// Can't spawn that extra food, since it's only one square in choice and that's filled with the normal food....
	if(bAwesome
	&& g_iWormLength[client] == FIELD_X*FIELD_Y-1)
		return;
	
	int iCoords[2];
	for(;;)
	{
		// Hope it won't take too long to find a free field.. PSEUDO RANDOMNESS!!
		iCoords[COORD_X] = Math_GetRandomInt(0, FIELD_X-1);
		iCoords[COORD_Y] = Math_GetRandomInt(0, FIELD_Y-1);
		if(((bAwesome && (g_iNomNomPosition[client][COORD_X] != iCoords[COORD_X] || g_iNomNomPosition[client][COORD_Y] != iCoords[COORD_Y]))
		|| (!bAwesome && (g_iAwesomeNomNomPosition[client][COORD_X] != iCoords[COORD_X] || g_iAwesomeNomNomPosition[client][COORD_Y] != iCoords[COORD_Y])))
		&& !IsWormThere(client, iCoords))
			break;
	}
	if(bAwesome)
	{
		g_iAwesomeNomNomPosition[client][COORD_X] = iCoords[COORD_X];
		g_iAwesomeNomNomPosition[client][COORD_Y] = iCoords[COORD_Y];
	}
	else
	{
		g_iNomNomPosition[client][COORD_X] = iCoords[COORD_X];
		g_iNomNomPosition[client][COORD_Y] = iCoords[COORD_Y];
	}
}

int IsWormThere(int client, const int iCoords[2])
{
	for(int i=0;i<g_iWormLength[client];i++)
	{
		if(g_iWormPositions[client][i][COORD_X] == iCoords[COORD_X] && g_iWormPositions[client][i][COORD_Y] == iCoords[COORD_Y])
		{
			return true;
		}
	}
	return false;
}

bool MoveSnake(int client)
{
	int iTempPositions[2];
	iTempPositions[COORD_X] = g_iWormPositions[client][0][COORD_X];
	iTempPositions[COORD_Y] = g_iWormPositions[client][0][COORD_Y];
	
	switch(g_iWormCurrentDirection[client])
	{
		case Direction_Right:
		{
			// Hit the wall on the right!!!
			if(g_iWormPositions[client][0][COORD_X] == FIELD_X-1)
			{
				if(g_iSnakeMode[client] == Mode_Snake1)
					return false;
				else
				{
					iTempPositions[COORD_X] = 0;
				}
			}
			else
				iTempPositions[COORD_X]++;
			
			// Is the food there?
			if(iTempPositions[COORD_X] == g_iNomNomPosition[client][COORD_X]
			&& iTempPositions[COORD_Y] == g_iNomNomPosition[client][COORD_Y])
			{
				// shift it all one up. Don't cut of the last one, since it's getting longer!
				PushWormArrayOneUp(client, false);
				
				g_iWormPositions[client][0][COORD_X] = iTempPositions[COORD_X];
				
				g_iWormLength[client]++;
				g_iScore[client] += FOOD_SCORE;
				
				PutNewNomNomOnField(client);
				
				return true;
			}
			
			// Is the awesome food there?
			if(iTempPositions[COORD_X] == g_iAwesomeNomNomPosition[client][COORD_X]
			&& iTempPositions[COORD_Y] == g_iAwesomeNomNomPosition[client][COORD_Y])
			{
				PushWormArrayOneUp(client, false);
				g_iWormPositions[client][0][COORD_X] = iTempPositions[COORD_X];
				
				g_iWormLength[client] -= 3;
				if(g_iWormLength[client] < WORM_MIN_LENGTH)
					g_iWormLength[client] = WORM_MIN_LENGTH;
				
				RemoveAllCoordsAfterLength(client);
				
				g_iScore[client] += FOOD_SCORE;
				
				g_iAwesomeNomNomPosition[client][COORD_X] = -1;
				g_iAwesomeNomNomPosition[client][COORD_Y] = -1;
				g_iAwesomeNomNomLifetime[client] = -1;
				g_iNextAwesomeNomNom[client] = Math_GetRandomInt(100, 200);
				
				return true;
			}
			
			// Eat yaself!!
			if(IsWormThere(client, iTempPositions))
				return false;
			
			PushWormArrayOneUp(client, true);
			
			g_iWormPositions[client][0][COORD_X] = iTempPositions[COORD_X];
			return true;
		}
		case Direction_Down:
		{
			// Hit the wall at the bottom!!!
			if(g_iWormPositions[client][0][COORD_Y] == 0)
			{
				if(g_iSnakeMode[client] == Mode_Snake1)
					return false;
				else
				{
					iTempPositions[COORD_Y] = FIELD_Y-1;
				}
			}
			else
				iTempPositions[COORD_Y]--;

			
			// Is the food there?
			if(iTempPositions[COORD_X] == g_iNomNomPosition[client][COORD_X]
			&& iTempPositions[COORD_Y] == g_iNomNomPosition[client][COORD_Y])
			{
				// shift it all one up. Don't cut of the last one, since it's getting longer!
				PushWormArrayOneUp(client, false);
				
				g_iWormPositions[client][0][COORD_Y] = iTempPositions[COORD_Y];
				
				g_iWormLength[client]++;
				g_iScore[client] += FOOD_SCORE;
				
				PutNewNomNomOnField(client);
				
				return true;
			}
			
			if(iTempPositions[COORD_X] == g_iAwesomeNomNomPosition[client][COORD_X]
			&& iTempPositions[COORD_Y] == g_iAwesomeNomNomPosition[client][COORD_Y])
			{
				PushWormArrayOneUp(client, false);
				g_iWormPositions[client][0][COORD_Y] = iTempPositions[COORD_Y];
				
				g_iWormLength[client] -= 3;
				if(g_iWormLength[client] < WORM_MIN_LENGTH)
					g_iWormLength[client] = WORM_MIN_LENGTH;
				
				RemoveAllCoordsAfterLength(client);
				
				g_iScore[client] += FOOD_SCORE;
				
				g_iAwesomeNomNomPosition[client][COORD_X] = -1;
				g_iAwesomeNomNomPosition[client][COORD_Y] = -1;
				g_iAwesomeNomNomLifetime[client] = -1;
				g_iNextAwesomeNomNom[client] = Math_GetRandomInt(100, 200);
				
				return true;
			}
			
			// Eat yaself!!
			if(IsWormThere(client, iTempPositions))
				return false;
			
			PushWormArrayOneUp(client, true);
			
			g_iWormPositions[client][0][COORD_Y] = iTempPositions[COORD_Y];
			return true;
		}
		case Direction_Left:
		{
			// Hit the wall on the left!!!
			if(g_iWormPositions[client][0][COORD_X] == 0)
			{
				if(g_iSnakeMode[client] == Mode_Snake1)
					return false;
				else
				{
					iTempPositions[COORD_X] = FIELD_X-1;
				}
			}
			else
				iTempPositions[COORD_X]--;
			
			// Is the food there?
			if(iTempPositions[COORD_X] == g_iNomNomPosition[client][COORD_X]
			&& iTempPositions[COORD_Y] == g_iNomNomPosition[client][COORD_Y])
			{
				// shift it all one up. Don't cut of the last one, since it's getting longer!
				PushWormArrayOneUp(client, false);
				
				g_iWormPositions[client][0][COORD_X] = iTempPositions[COORD_X];
				
				g_iWormLength[client]++;
				g_iScore[client] += FOOD_SCORE;
				
				PutNewNomNomOnField(client);
				
				return true;
			}
			
			if(iTempPositions[COORD_X] == g_iAwesomeNomNomPosition[client][COORD_X]
			&& iTempPositions[COORD_Y] == g_iAwesomeNomNomPosition[client][COORD_Y])
			{
				PushWormArrayOneUp(client, false);
				g_iWormPositions[client][0][COORD_X] = iTempPositions[COORD_X];
				
				g_iWormLength[client] -= 3;
				if(g_iWormLength[client] < WORM_MIN_LENGTH)
					g_iWormLength[client] = WORM_MIN_LENGTH;
				
				RemoveAllCoordsAfterLength(client);
				
				g_iScore[client] += FOOD_SCORE;
				
				g_iAwesomeNomNomPosition[client][COORD_X] = -1;
				g_iAwesomeNomNomPosition[client][COORD_Y] = -1;
				g_iAwesomeNomNomLifetime[client] = -1;
				g_iNextAwesomeNomNom[client] = Math_GetRandomInt(100, 200);
				
				return true;
			}
			
			// Eat yaself!!
			if(IsWormThere(client, iTempPositions))
				return false;
			
			PushWormArrayOneUp(client, true);
			
			g_iWormPositions[client][0][COORD_X] = iTempPositions[COORD_X];
			return true;
		}
		case Direction_Up:
		{
			// Hit the wall at the top!!!
			if(g_iWormPositions[client][0][COORD_Y] == FIELD_Y-1)
			{
				if(g_iSnakeMode[client] == Mode_Snake1)
					return false;
				else
				{
					iTempPositions[COORD_Y] = 0;
				}
			}
			else
				iTempPositions[COORD_Y]++;
			
			// Is the food there?
			if(iTempPositions[COORD_X] == g_iNomNomPosition[client][COORD_X]
			&& iTempPositions[COORD_Y] == g_iNomNomPosition[client][COORD_Y])
			{
				// shift it all one up. Don't cut of the last one, since it's getting longer!
				PushWormArrayOneUp(client, false);
				
				g_iWormPositions[client][0][COORD_Y] = iTempPositions[COORD_Y];
				
				g_iWormLength[client]++;
				g_iScore[client] += FOOD_SCORE;
				
				PutNewNomNomOnField(client);
				
				return true;
			}
			
			if(iTempPositions[COORD_X] == g_iAwesomeNomNomPosition[client][COORD_X]
			&& iTempPositions[COORD_Y] == g_iAwesomeNomNomPosition[client][COORD_Y])
			{
				PushWormArrayOneUp(client, false);
				g_iWormPositions[client][0][COORD_Y] = iTempPositions[COORD_Y];
				
				g_iWormLength[client] -= 3;
				if(g_iWormLength[client] < WORM_MIN_LENGTH)
					g_iWormLength[client] = WORM_MIN_LENGTH;
				
				RemoveAllCoordsAfterLength(client);
				
				g_iScore[client] += FOOD_SCORE;
				
				g_iAwesomeNomNomPosition[client][COORD_X] = -1;
				g_iAwesomeNomNomPosition[client][COORD_Y] = -1;
				g_iAwesomeNomNomLifetime[client] = -1;
				g_iNextAwesomeNomNom[client] = Math_GetRandomInt(100, 200);
				
				return true;
			}
			
			// Eat yaself!!
			if(IsWormThere(client, iTempPositions))
				return false;
			
			PushWormArrayOneUp(client, true);
			
			g_iWormPositions[client][0][COORD_Y] = iTempPositions[COORD_Y];
			return true;
		}
	}
	
	return false;
}

void PushWormArrayOneUp(int client, bool bRemoveLast)
{
	int iLimit = g_iWormLength[client];
	if(bRemoveLast)
		iLimit--;
	
	for(int i=iLimit-1;i>=0;i--)
	{
		if(i < FIELD_X*FIELD_Y)
		{
			g_iWormPositions[client][i+1][COORD_X] = g_iWormPositions[client][i][COORD_X];
			g_iWormPositions[client][i+1][COORD_Y] = g_iWormPositions[client][i][COORD_Y];
		}
	}
	
	if(bRemoveLast)
	{
		g_iWormPositions[client][g_iWormLength[client]][COORD_X] = -1;
		g_iWormPositions[client][g_iWormLength[client]][COORD_Y] = -1;
	}
}

void RemoveAllCoordsAfterLength(int client)
{
	for(int i=g_iWormLength[client]-1;i<FIELD_X*FIELD_Y;i++)
	{
		g_iWormPositions[client][i][COORD_X] = -1;
		g_iWormPositions[client][i][COORD_Y] = -1;
	}
}

WormDirection GetOppositeDirection(WormDirection iDirection)
{
	switch(iDirection)
	{
		case Direction_Right:
			return Direction_Left;
		case Direction_Down:
			return Direction_Up;
		case Direction_Left:
			return Direction_Right;
		case Direction_Up:
			return Direction_Down;
	}
	
	// COMPILER!!! GRRR
	return view_as<WormDirection>(1337);
}

stock void ClearTimer(Handle &timer, bool autoClose=false)
{
	if(timer != INVALID_HANDLE)
		KillTimer(timer, autoClose);
	timer = INVALID_HANDLE;
}