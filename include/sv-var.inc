#include <sourcemod>

static Address ptrFrameTimeStdDev = Address_Null;
static Address ptrFrameTimeStartStdDev = Address_Null;
static Address ptrFrameComputationTime = Address_Null;

float GetFrameTimeStdDev()
{
	if (ptrFrameTimeStdDev == Address_Null)
	{
		LoadSVVarGameConf();
	}
	
	return view_as<float>(LoadFromAddress(ptrFrameTimeStdDev, NumberType_Int32));
}

float GetFrameStartTimeStdDev()
{
	if (ptrFrameTimeStartStdDev == Address_Null)
	{
		LoadSVVarGameConf();
	}
	
	return view_as<float>(LoadFromAddress(ptrFrameTimeStartStdDev, NumberType_Int32));
}

float GetFrameComputationTime()
{
	if (ptrFrameComputationTime == Address_Null)
	{
		LoadSVVarGameConf();
	}
	
	return view_as<float>(LoadFromAddress(ptrFrameComputationTime, NumberType_Int32));
}

static void LoadSVVarGameConf()
{
	Handle hConfig = LoadGameConfigFile("sv-var.games");
	if (hConfig == null)
		ThrowError("Failed to load sv-var.games");
	
	ptrFrameTimeStdDev = GameConfGetAddress(hConfig, "host_framestarttime_stddeviation");
	if (ptrFrameTimeStdDev == Address_Null)
		ThrowError("Failed to look up host_framestarttime_stddeviation address");
	
	ptrFrameTimeStartStdDev = GameConfGetAddress(hConfig, "host_frametime_stddeviation");
	if (ptrFrameTimeStartStdDev == Address_Null)
		ThrowError("Failed to look up host_frametime_stddeviation address");
	
	ptrFrameComputationTime = GameConfGetAddress(hConfig, "host_frameendtime_computationduration");
	if (ptrFrameComputationTime == Address_Null)
		ThrowError("Failed to look up host_frameendtime_computationduration");
	
	delete hConfig;
}
