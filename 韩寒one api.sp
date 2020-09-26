#include <sourcemod>
#include <ripext>

public Plugin myinfo = {
    name = "another status",
    author = "neko aka bklol",
    description = "change csgo status",
    version = "0.1",
    url = "https://github.com/bklol"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_t"     , Command_Buy);
}

public Action Command_Buy(int client,int a)
{
	HTTPClient httpClient = new HTTPClient("http://api.youngam.cn/api");
	httpClient.Get("one.php",ConnTypeCallBack,client);
}

public void ConnTypeCallBack(HTTPResponse response, int client)
{
	if (response.Status != HTTPStatus_OK) 
	{
		LogError("Http Get error error, %d", response.Status);
		return;
	}
	if (response.Data == null) 
	{
		LogError("Http Get No response");
		return;
	}
	ParseData (view_as<JSONObject>(response.Data),client);
}

public void ParseData(JSONObject Data,int client)
{
	char status[32];
	Data.GetString("msg",status, sizeof(status));
	if(!StrEqual(status,"成功"))
	{
		PrintToChat(client,"失败");
		return;
	}
	JSONArray   jData   = view_as<JSONArray>(Data.Get("data"));
	char Buffer[1280];
    for(int i = 0; i < jData.Length; i++)
    {
		JSONObject jtext = view_as<JSONObject>(jData.Get(i));
		jtext.GetString("text", Buffer, sizeof(Buffer));
		PrintToChat(client,Buffer);
		delete jtext;
	}
	delete jData;
	delete Data;
}

