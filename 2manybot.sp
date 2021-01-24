public void OnClientPutInServer(int client)
{
	Count();
}

void Count()
{
	int bot = 0;
	for (int i = 1; i <= MaxClients; i++) 
	{
		if(IsFakeClient(i))
			bot++;
	}
	if(bot > 15)
	{
		ServerCommand("sm_removebot");
		PrintToChatAll("当前bot超出人数上限.");
	}
}