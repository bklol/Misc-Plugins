#include <ripext>
#include <sdktools>

public void OnPluginStart() 
{
	CreateTimer(1.0, FixName, _, TIMER_REPEAT);
}

public Action FixName(Handle timer) 
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			char Name[MAX_NAME_LENGTH + 32];
			GetClientName(i, Name, MAX_NAME_LENGTH)
			Format(Name,sizeof(Name),"{\"buffer\":\"%s\"}",Name);
			JSONObject hJSONObject = JSONObject.FromString(Name);
			hJSONObject.GetString("buffer", Name,sizeof(Name));	
			SetClientName(i, Name);		
		}
	}
}

stock bool IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( IsFakeClient(client)) return false;
	return true;
}

