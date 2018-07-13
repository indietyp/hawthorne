public void OnClientAuthorized(int client) {
  CLIENTS[client] = "";

  if (StrEqual(SERVER, "") || IsFakeClient(client) || client < 1) return;

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

public void OnClientDisconnect(int client) {
  if (IsFakeClient(client)) return;

  JSONObject payload = new JSONObject();
  payload.SetString("id", CLIENTS[client]);

  payload.SetString("server", SERVER);
  payload.SetBool("connected", false);

  httpClient.Put("users", payload, APINoResponseCall);

  CLIENTS[client] = "";
  delete payload;
}

void OnClientIsInAPI(HTTPResponse response, any value) {
  int client = value;
  char url[512];

  if (!APIValidator(response) || StrEqual(SERVER, "")) return;

  JSONObject output = view_as<JSONObject>(response.Data);
  JSONObject result = view_as<JSONObject>(output.Get("result"));
  result.GetString("id", CLIENTS[client], sizeof(CLIENTS[]));

  OnClientIDReceived(client);

  Format(url, sizeof(url), "users/%s/punishments?resolved=true", CLIENTS[client]);
  httpClient.Get(url, AdminPunishmentNotify, client);

  delete result;
  delete output;
}

void AdminPunishmentNotify(HTTPResponse response, any value) {
  int client = value;

  if (!APIValidator(response) || StrEqual(SERVER, "")) return;

  JSONObject output = view_as<JSONObject>(response.Data);
  JSONArray result = view_as<JSONArray>(output.Get("result"));

  if (result.Length == 0) return;

  int ban = 0;
  int mute = 0;
  int gag = 0;
  int silence = 0;

  for (int i = 0; i < result.Length; i++) {
    JSONObject punishment = view_as<JSONObject>(result.Get(i));
    if (punishment.GetBool("is_banned")) ban += 1;
    else if (punishment.GetBool("is_muted") && punishment.GetBool("is_gagged")) silence += 1;
    else if (punishment.GetBool("is_muted")) mute += 1;
    else if (punishment.GetBool("is_gagged")) gag += 1;
    delete punishment;
  }

  char name[512];
  GetClientName(client, name, sizeof(name));
  for (int i = 0; i <= MaxClients; i++) {
    if (GetUserFlagBits(i) & ADMFLAG_GENERIC) {
      CPrintToChat(i, "{red}%s{default} just connected.");
      if (ban != 0) CPrintToChat(i, "This user was previously banned {blue}%i{default} times.", ban);
      if (mute != 0) CPrintToChat(i, "This user was previously muted {blue}%i{default} times.", mute);
      if (gag != 0) CPrintToChat(i, "This user was previously gagged {blue}%i{default} times.", gag);
      if (silence != 0) CPrintToChat(i, "This user was previously silenced {blue}%i{default} times.", silence);
    }
  }

  delete output;
  delete result;
}
