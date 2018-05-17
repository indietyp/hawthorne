#include <advanced_motd>

void AutoBan_OnMapStart() {
  if(MODULE_AUTOBAN_DISABLE.BoolValue) return;
  CreateTimer(10.0, AutoBan_Timer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void AutoBan_OnPlayerSpawn(client) {
  if(MODULE_AUTOBAN_DISABLE.BoolValue) return;

  char AutoBan_URL[255];
  Format(AutoBan_URL, sizeof(AutoBan_URL), "API_URL"); // The steamid of the client has to the API here.
  AdvMOTD_ShowMOTDPanel(client, "Hawthorne", AutoBan_URL, MOTDPANEL_TYPE_URL, true, false, true, OnMOTDFailure);

  MOTD_SEEN[client] = true;
}

void OnMOTDFailure(int client, MOTDFailureReason reason) {
  LogError("[HT] Failed to launch MOTD to verify authentication of alternate account for STEAM_ID");
}

void AutoBan_OnClientDisconnect(client) {
  MOTD_SEEN[client] = false;
}


/*
	This is from my old plugin, but it's an excellent template to work on.
	Notice the notes I left.
*/

public Action AutoBan_Timer(Handle timer)
{
	if(GetClientCount() > 0)
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(client > 0 && client < MaxClients+1)
			{
				char s_URL[] = "API_URL_STEP_TWO"; // this is step 2 of the check and should not be the same url for the motd check.

				Handle handle = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, s_URL);

				SteamWorks_SetHTTPRequestGetOrPostParameter(handle, "steam", ClientSteam[client]);
				SteamWorks_SetHTTPRequestRawPostBody(handle, "text/html", s_URL, sizeof(s_URL));
				if (!handle || !SteamWorks_SetHTTPCallbacks(handle, HTTP_AltRequestComplete) || !SteamWorks_SendHTTPRequest(handle))
				{
					CloseHandle(handle);
				}
			}
		}
	}
}

public int HTTP_AltRequestComplete(Handle HTTPRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
    if(!bRequestSuccessful) {
        LogError("[HT] An error occured while requesting the alt API.");
    } else {
		SteamWorks_GetHTTPResponseBodyCallback(HTTPRequest, AltResponse);

		CloseHandle(HTTPRequest);
    }
}

public int AltResponse(const char[] sData)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(client > 0 && client < MaxClients+1)
		{
			if(StrEqual(sData, ClientSteam[client], false))
			{
				// USER IS BANNED. KICK THEM HERE.
				CreateTimer(0.1, BAN_TIMER, client); // I recommend using a short timer to kick them. We do not actually want to ban the alt. Just kick them.
				break;
			}
		}
	}
}
