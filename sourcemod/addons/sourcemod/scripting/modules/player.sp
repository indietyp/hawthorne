void Players_OnClientAuthorized(int client) {
  CLIENTS[client] = "";

  if (StrEqual(SERVER, "") || IsFakeClient(client)) return;

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
  payload.SetString("server", SERVER);
  payload.SetBool("connected", true);

  httpClient.Put("users", payload, OnClientIsInAPI, client);
  delete payload;
}

void Players_OnClientDisconnect(int client) {
  if (IsFakeClient(client))return;

  JSONObject payload = new JSONObject();
  payload.SetString("id", CLIENTS[client]);

  payload.SetString("server", SERVER);
  payload.SetBool("connected", false);

  httpClient.Put("users", payload, APINoResponseCall);

  CLIENTS[client] = "";
  delete payload;
}

public void OnClientIsInAPI(HTTPResponse response, any value) {
  int client = value;

  if (!APIValidator(response) || StrEqual(SERVER, "")) return;

  JSONObject output = view_as<JSONObject>(response.Data);
  JSONObject result = view_as<JSONObject>(output.Get("result"));
  result.GetString("id", CLIENTS[client], 37);

  OnClientIDReceived(client);

  delete result;
  delete output;
}
