#include <sourcemod>
#include <ripext>

HTTPClient httpClient;

public void OnPluginStart()
{
	RegConsoleCmd("sm_t", test);
    
}

public Action test (int client ,int arges)
{
	httpClient = new HTTPClient("http://down.nicotine.vip/maps");
    char sImagePath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sImagePath, sizeof(sImagePath), "plugins/35hp_$2000$_v3.bsp.bz2");
    httpClient.DownloadFile("35hp_$2000$_v3.bsp.bz2", sImagePath, OnImageDownloaded);
}

void OnImageDownloaded(HTTPStatus status, any value)
{
    if (status != HTTPStatus_OK) {
        PrintToChatAll("Download Error");
        return;
    }

    PrintToChatAll("Download complete");
} 