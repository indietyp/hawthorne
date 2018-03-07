void Players_OnClientAuthorized(int client) {
  ht_clients[client] = "";

  if (StrEqual(server, "")) {
    GetServerUUID();
  }

  char steamid[20];
  GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

  char username[64];
  GetClientName(client, username, sizeof(username));

  char ip[20], country[3];
  GetClientIP(client, ip, sizeof(ip));
  GeoipCode2(ip, country);

  JSONObject payload = new JSONObject();
  payload.SetString("steamid", steamid);
  payload.SetString("username", username);
  payload.SetString("ip", ip);
  payload.SetString("country", country);
  payload.SetString("server", server);
  payload.SetBool("connected", true);

  httpClient.Put("users", payload, OnClientIsInAPI, client);
  delete payload;
}

void Players_OnClientDisconnect(int client) {
  JSONObject payload = new JSONObject();
  payload.SetString("id", ht_clients[client]);
  payload.SetString("server", server);
  payload.SetBool("connected", false);

  httpClient.Put("users", payload, APINoResponseCall);

  ht_clients[client] = "";
  delete payload;
}

public void OnClientIsInAPI(HTTPResponse response, any value) {
  int client = value;

  if (response.Status != HTTPStatus_OK) {
    LogError("[hawthorne] API ERROR (request failed)");
    return;
  }

  if (response.Data == null) {
    LogError("[hawthorne] API ERROR (no response data)");
    return;
  }

  if (StrEqual(server, ""))
    return;

  JSONObject output = view_as<JSONObject>(response.Data);
  int success = output.GetBool("success");

  if (success == false) {
    LogError("[hawthorne] API ERROR (api call failed)");
    return;
  } else {
    JSONObject result = view_as<JSONObject>(output.Get("result"));
    result.GetString("id", ht_clients[client], 37);
    delete result;
    OnClientIDReceived(client);
  }

  delete output;
}

void PlayersOnline_OnClientDisconnect(int client) {
  char steamid[20];
  char username[64];

  GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
  GetClientName(client, username, sizeof(username));

  JSONObject payload = new JSONObject();
  payload.SetString("steamid", steamid);
  payload.SetString("username", username);
  payload.SetBool("connected", false);
  payload.SetString("server", server);

  httpClient.Put("users", payload, OnClientDisconnectAPI);
  delete payload;

  ht_clients[client] = "";
}

public void OnClientDisconnectAPI(HTTPResponse response, any value) {
  return;
}
