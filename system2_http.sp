#include <sourcemod>
#include <ripext>

public Plugin myinfo =
{
    name        = "REST in Pawn - Tests",
    author      = "Tsunami",
    description = "Test HTTP and JSON natives",
    version     = "1.0.0",
    url         = "http://www.tsunami-productions.nl"
};


char sHTTPTags[][] = {
    "GET",
    "POST",
    "PUT",
    "PATCH",
    "DELETE",
    "GZIP",
};


public void OnPluginStart()
{
	RegAdminCmd("sm_t", Bash_Stats, ADMFLAG_KICK, "Check a player's strafe stats");
	
    
}

public Action Bash_Stats(int client, int args)
{
	HTTPClient hHTTPClient = new HTTPClient("http://120.92.132.81:5700/send_msg?");
	hHTTPClient.SetHeader("Authorization", "Bearer xshequwocaonima");
    JSONObject hJSONObject = CreateJSONObject();
    hHTTPClient.Post("post", hJSONObject, OnHTTPResponse, 1);
  
    delete hJSONObject;
}

public void OnHTTPResponse(HTTPResponse response, any value)
{
    if (response.Status != HTTPStatus_OK) {
        PrintToServer("[ERR] %s Status: %d", sHTTPTags[value], response.Status);
        return;
    }
    if (response.Data == null) {
        PrintToServer("[OK] %s No response", sHTTPTags[value]);
        return;
    }

    char sData[1024];
    response.Data.ToString(sData, sizeof(sData), JSON_INDENT(4));

    PrintToServer("[OK] %s Response:\n%s", sHTTPTags[value], sData);
}

JSONObject CreateJSONObject()
{
    JSONObject hJSONObject = new JSONObject();
	char buffer[256];
	buffer = "|||||||||||&^%$&^%$*&^%(*&^)(*^&*^$&^%@%^$oakjs+++++nhkjfosidahf.poasidhoasihndoashda";
    hJSONObject.SetString("user_id", "1308734055");
	hJSONObject.SetString("message", buffer);
	
    return hJSONObject;
}