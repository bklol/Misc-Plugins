#include <cstrike>
#include <sourcemod>
#include <ripext>
#include <json>

public void OnPluginStart() {
	RegConsoleCmd("sm_t",test);
}

public Action test(int client,int ag)
{
	HTTPClient hHTTPClient = new HTTPClient("http://open.iciba.com/dsapi/");
    hHTTPClient.Get("get", OnHTTPResponse, client);
}

void OnHTTPResponse(HTTPResponse response, any value)
{
	int client = value;
    if (response.Status != HTTPStatus_OK) {
        PrintToServer("[ERR]  Status: %d",response.Status);
        return;
    }
    if (response.Data == null) {
        PrintToServer("[OK] No response");
        return;
    }

    char sData[2048];
    response.Data.ToString(sData, sizeof(sData), JSON_INDENT(3));

    PrintToConsole(client,"[OK] Response:\n%s", sData);
	JSON_Object obj = json_decode(sData);
	char arg1[128],arg2[128];
	obj.GetString("note", arg1, sizeof(arg1));
	obj.GetString("content", arg2, sizeof(arg2));
	obj.Cleanup();
	delete obj;
	PrintToChat(client,"%s\n%s",arg1,arg2);
}

