#include <md5>
#include <ripext>


int fTimes;
static Handle g_h_Timer = null;

public Plugin myinfo = {
    name = "dump map md5",
    author = "neko aka bklol",
    description = "呐呐 喜欢二次元的 一定不是坏人吧？",
    version = "0.1",
    url = "https://github.com/bklol"
};

public void OnPluginStart()
{
	char szLocalFileFolder[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szLocalFileFolder, sizeof(szLocalFileFolder), "data/neko/md5");
	if(!DirExists(szLocalFileFolder))
	{
		CreateDirectory(szLocalFileFolder, 511);
	}
	
	RegConsoleCmd("sm_md5",Dump_MD5File);
}

public Action Dump_MD5File(int client, int arg)
{
	Dump();
	fTimes = 0;
}

stock void Dump()
{
	char FileName[64];
	Handle Dir = OpenDirectory("maps");
	FileType Type;
	JSONArray Md5_Array = new JSONArray();
	while(ReadDirEntry(Dir, FileName,PLATFORM_MAX_PATH, Type))
	{
		if(Type == FileType_File)
		{
			if(StrContains(FileName,".bsp") != -1)
			{
				Format(FileName, sizeof(FileName), "maps/%s",FileName);
				Md5_Array.PushString(FileName);
				//MD5_File(FileName, buffer, sizeof(buffer));
			}
			continue;
		}
	}
	PrintToServer("DUMP %i MapFile",Md5_Array.Length);
	g_h_Timer = CreateTimer(1.5, CreatMd5, Md5_Array, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action CreatMd5(Handle timer,JSONArray Md5_Array)
{
	char buffer[128],FileName[128];
	Md5_Array.GetString(fTimes,  FileName,  sizeof(FileName));
	MD5_File(FileName, buffer, sizeof(buffer));
	PrintToServer("FileName:%s MD5:%s", FileName, buffer);
	fTimes += 1;
	if(fTimes > Md5_Array.Length)
	{
		KillTimer(g_h_Timer);
		delete Md5_Array;
	}
}











