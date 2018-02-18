// TODO: TESTING
void Players_OnClientAuthorized(int client) {
	iClientID[client] = "";

	char steamid[20];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

	char username[64];
	GetClientName(client, username, sizeof(username));

	char ip[20], country[3];
	GetClientIP(client, ip, sizeof(ip));
	GeoipCode2(ip, country);

	JSONObject payload = new JSONObject();
	payload.SetInt("steamid", StringToInt(steamid));
	payload.SetString("username", username);
	payload.SetString("ip", ip);
	payload.SetString("counrty", counrty);
	payload.SetBool("connect", true);

	delete username, steamid, ip, counrty;

	httpClient.PUT("/users", payload, OnClientIsInAPI);
	delete payload;
}

void Players_OnClientDisconnect(int client) {
	iClientID[client] = "";
}

public void OnClientIsInAPI(HTTPResponse response, any value) {
    if (response.Status != 200) {
    	LogError("[BOOMPANEL] API ERROR (request failed)");
      return;
    }

    if (response.Data == null) {
    	LogError("[BOOMPANEL] API ERROR (no response data)");
      return;
    }

    if(iServerID == "")
    	return;

    int client = GetClientOfUserId(userID);
    if(client < 1)
    	return;

    JSONObject output = view_as<JSONObject>(response.Data);
    int success = output.GetInt("success");

    if (success == 0) {
      LogError("[BOOMPANEL] API ERROR (api call failed)");
      return;
    } else {
      JSONObject result = view_as<JSONObject>(output.Get("result"));
    	iClientID[client] = result.getString("id");
			OnClientIDReceived(client);
    }

    delete output;
    delete result;
}

void PlayersOnline_OnClientDisconnect(int client) {
	char steamid[20];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

	JSONObject payload = new JSONObject();
	payload.SetInt("steamid", StringToInt(steamid));
	payload.SetBool("connect", false);
	delete steamid;

	httpClient.PUT("/users", payload, OnClientDisconnectAPI);
	delete payload;
}

public void OnClientDisconnectAPI(HTTPResponse response, any value) {
	return;
}
