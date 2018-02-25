// TODO: TESTING
void ClientBanKick(int client, char[] cAdminName, char[] cReason, char[] cTotalTime, char[] cTime) {
	KickClient(client,
	"You have been banned from the server\n "...
	"\nSERVER: 		%s"...
	"\nADMIN:		%s"...
	"\nREASON:		%s"...
	"\nTOTAL:		%s"...
	"\nTIME LEFT: 	%s"...
	"\n", cServerHostName, cAdminName, cReason, cTotalTime, cTime);
}

stock bool GetCommunityID(char[] AuthID, char[] FriendID, int size) {
	if(strlen(AuthID) < 11 || AuthID[0]!='S' || AuthID[6]=='I')
	{
		FriendID[0] = 0;
		return false;
	}

	int iUpper = 765611979;
	int iFriendID = StringToInt(AuthID[10])*2 + 60265728 + AuthID[8]-48;

	int iDiv = iFriendID/100000000;
	int iIdx = 9-(iDiv?iDiv/10+1:0);
	iUpper += iDiv;

	IntToString(iFriendID, FriendID[iIdx], size-iIdx);
	iIdx = FriendID[9];
	IntToString(iUpper, FriendID, size);
	FriendID[9] = iIdx;

	return true;
}

stock void SecondsToTime(int seconds, char time[200], bool ShortDate = true) {

	//DAYS
	int days = (seconds / (3600*24));
	if(days > 0) {
		char s_days[20];
		IntToString(days, s_days, sizeof(s_days));
		StrCat(time, sizeof(time), s_days);
	}

	if(days == 1)
		StrCat(time, sizeof(time), " day ");
	else if(days > 0)
		StrCat(time, sizeof(time), " days ");

	if(ShortDate && days > 0)
		return;


	//HOURS
	if(ShortDate)
		time = "";
	int hours = (seconds / 3600) % 24;
	if(hours > 0) {
		char s_hours[20];
		IntToString(hours, s_hours, sizeof(s_hours));
		StrCat(time, sizeof(time), s_hours);
	}

	if(hours == 1)
		StrCat(time, sizeof(time), " hour ");
	else if(hours > 0)
		StrCat(time, sizeof(time), " hours ");

	if(ShortDate && hours > 0)
		return;


	//MINUTES
	if(ShortDate)
		time = "";
	int minutes = (seconds / 60) % 60;
	if(minutes > 0) {
		char s_minutes[20];
		IntToString(minutes, s_minutes, sizeof(s_minutes));
		StrCat(time, sizeof(time), s_minutes);
	}

	if(minutes == 1)
		StrCat(time, sizeof(time), " minute ");
	else if(minutes > 0)
		StrCat(time, sizeof(time), " minutes ");

	if(ShortDate && minutes > 0)
		return;

}

void Bans_OnClientIDReceived(int client) {
	if(g_cvBansEnabled.IntValue == 1 && !StrEqual(iServerID, "")) {
		char url[512] = "users/";
		StrCat(url, sizeof(url), iClientID[client]);
		StrCat(url, sizeof(url), "/ban?resolved=false&server=");
		StrCat(url, sizeof(url), iServerID);

		httpClient.Get(url, OnBanCheck, client);
	}
}

void Bans_OnMapStart() {
	//Update hostname on each map start
	ConVar hostname = FindConVar("hostname");
	hostname.GetString(cServerHostName, sizeof(cServerHostName));
}

//On add ban command
public Action OnAddBanCommand(int client, const char[] command, int args) {
	if(g_cvBansEnabled.IntValue == 1 && !StrEqual(iServerID, "")) {

		// Manually send this command to bp_chat, so it gets logged (because such command already exists in sourcemod)
		char cMessage[256];
		GetCmdArgString(cMessage, sizeof(cMessage));
		Format(cMessage, sizeof(cMessage), "%s %s", command, cMessage);
		LogChatMessage(client, cMessage, 1);

		// Replace original add ban command
		if(args < 2) {
			ReplyToCommand(client, "%s!addban <steamid> <time> [reason]", PREFIX);
			return Plugin_Stop;
		}

		// Convert steamid32 to steamid64
		char steamid[20], steamid64[20];
		GetCmdArg(1, steamid, sizeof(steamid));
		GetCommunityID(steamid, steamid64, sizeof(steamid64));
		if (StrEqual(steamid64, "")) {
			ReplyToCommand(client, "%sWrong steamID format", PREFIX);
			return Plugin_Stop;
		}

		char cReason[100], cLenght[10];
		GetCmdArg(2, cLenght, sizeof(cLenght));
		GetCmdArg(3, cReason, sizeof(cReason));
		int length = StringToInt(cLenght);

		// Kick player if he is ingamae
		for (int i = 1; i < MaxClients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				char steamid2[20];
				GetClientAuthId(i, AuthId_SteamID64, steamid2, sizeof(steamid2));
				if(StrEqual(steamid2, steamid64)) {

					//Get data for kick message
					char cAdminUsername[128], cTime[200];
					if(length > 0) SecondsToTime((length * 60), cTime); else cTime = "permanent";
					GetClientName(client, cAdminUsername, sizeof(cAdminUsername));
					ClientBanKick(i, cAdminUsername, cReason, cTime, cTime);

				}
			}
		}

		char adminID[37], serverToBan[37];

		StrCat(adminID, sizeof(adminID),  (client == 0) ? "" : iClientID[client]);
		StrCat(serverToBan, sizeof(serverToBan), (g_cvBansAllSrvs.IntValue == 0) ? iServerID : "");

		JSONObject payload = new JSONObject();

		if (!StrEqual(serverToBan, "")) {
			payload.SetString("server", iServerID);
		}
		payload.SetString("reason", cReason);
		payload.SetString("issuer", adminID);
		payload.SetInt("length", length * 60);

		char url[512] = "users/";
		StrCat(url, sizeof(url), steamid64);
		StrCat(url, sizeof(url), "/ban");

		httpClient.Put(url, payload, APINoResponseCall);
		delete payload;

		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public void OnBanCheck(HTTPResponse response, any value) {
	int client = value;
  if (response.Status != 200) {
  	LogError("[BOOMPANEL] API ERROR (request failed)");
    return;
  }

  if (response.Data == null) {
  	LogError("[BOOMPANEL] API ERROR (no response data)");
    return;
  }

	JSONObject output = view_as<JSONObject>(response.Data);
	int success = output.GetBool("success");

	if (success == false) {
	  LogError("[BOOMPANEL] API ERROR (api call failed)");
	  return;
	} else {
		JSONArray results = view_as<JSONArray>(output.Get("result"));

		if (results.Length == 0) {
			return;
		}

	  JSONObject result = view_as<JSONObject>(results.Get(0));

	  char passed[200], total[200];
	  char id[37];
	  result.GetString("id", id, sizeof(id));

	  // maybe get the username?
	  char issuer[37], reason[100];
	  result.GetString("issuer", issuer, sizeof(issuer));
	  result.GetString("reason", reason, sizeof(reason));

	  int creation = result.GetInt("created_at");
	  int length;
	  length = -1;

	  length = result.GetInt("length");
	  int now;
	  now = GetTime();

    if (client < 1) {
    	return;
    }


	  if (length != -1) {
	  	SecondsToTime(creation + length, total);
	  	SecondsToTime(creation + length - now, passed);
	  } else {
	  	total = "permanent";
	  	passed = "permanent";
	  }

	  ClientBanKick(client, issuer, reason, total, passed);
	  delete result;
	  delete results;
	}
}


public Action OnBanClient(int client, int time, int flags, const char[] reason, const char[] kick_message, const char[] command, any admin) {
	if(StrEqual(iServerID, "")) {
		ReplyToCommand(admin, "API connection not successful, cannot ban players right now!", PREFIX);
		return Plugin_Stop;
	}

	// insert data into the API
	char adminID[37], serverToBan[37];
	StrCat(adminID, sizeof(adminID), (admin == 0) ? "" : iClientID[admin]);
	StrCat(serverToBan, sizeof(serverToBan), (g_cvBansAllSrvs.IntValue == 0) ? iServerID : "");

	JSONObject payload = new JSONObject();

	if (!StrEqual(serverToBan, "")) {
		payload.SetString("server", iServerID);
	}

	payload.SetString("reason", reason);
	payload.SetString("issuer", adminID);
	payload.SetInt("length", time * 60);


	char url[512] = "users/";
	StrCat(url, sizeof(url), iClientID[client]);
	StrCat(url, sizeof(url), "/ban");

	httpClient.Put(url, payload, APINoResponseCall);
	delete payload;

	//Get kick message data
	char cAdminName[MAX_NAME_LENGTH], cTime[200];
	GetClientName(admin, cAdminName, sizeof(cAdminName));
	if(time > 0) SecondsToTime(time * 60, cTime); else cTime = "permanent";

	char cReason[128];
	StrCat(cReason, sizeof(cReason), reason);

	ReplyToCommand(admin, "%sPlayer successfully banned!", PREFIX);
	ClientBanKick(client, cAdminName, cReason, cTime, cTime);

	return Plugin_Stop;
}
