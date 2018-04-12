// TODO: TESTING
void ClientBanKick(int client, char[] cAdminName, char[] cReason, char[] cTotalTime, char[] cTime) {
  KickClient(client,
  "You have been banned from this server %s\n "...
  "\nThis was caused by %s with the reason: '%s'"...
  "\n\nOf your total time of %s, %s are left."...
  "\n", SERVER_HOSTNAME, cAdminName, cReason, cTotalTime, cTime);
}

void Bans_OnClientIDReceived(int client) {
  if (!MODULE_BAN.BoolValue || StrEqual(SERVER, "") || IsFakeClient(client)) return;

  char url[512] = "users/";
  StrCat(url, sizeof(url), CLIENTS[client]);
  StrCat(url, sizeof(url), "/ban?resolved=false&server=");
  StrCat(url, sizeof(url), SERVER);

  httpClient.Get(url, OnBanCheck, client);
}


public void OnBanCheck(HTTPResponse response, any value) {
  int client = value;

  if (client < 1) return;
  if (!APIValidator(response)) return;

  JSONObject output = view_as<JSONObject>(response.Data);
  JSONArray results = view_as<JSONArray>(output.Get("result"));

  if (results.Length < 1) return;
  JSONObject result = view_as<JSONObject>(results.Get(0));

  char passed[200], total[200];
  char issuer[128], reason[128];
  result.GetString("admin", issuer, sizeof(issuer));
  result.GetString("reason", reason, sizeof(reason));

  int creation = RoundFloat(result.GetFloat("created_at"));
  int length = RoundFloat(result.GetFloat("length"));
  int now = GetTime();

  LogMessage("Length: %i", length);
  LogMessage("Created: %i", creation);
  LogMessage("Now: %i", now);

  if (length != -1 && length != 2147483647) {
    HumanizeTime(length, total);
    HumanizeTime((creation + length) - now, passed);
  } else {
    total = "permanent";
    passed = "permanent";
  }

  ClientBanKick(client, issuer, reason, total, passed);

  delete results;
  delete result;
  delete output;
}


public Action OnAddBanCommand(int client, const char[] command, int args) {
  if (MODULE_BAN.IntValue == 0 || StrEqual(SERVER, "")) return Plugin_Continue;

  char cMessage[256];
  GetCmdArgString(cMessage, sizeof(cMessage));

  Format(cMessage, sizeof(cMessage), "%s %s", command, cMessage);
  SendChatMessage(client, cMessage, 1);

  if (args < 2) {
    ReplyToCommand(client, "\nUsage:\n%s!addban <steamid> <time> [reason]", PREFIX);
    return Plugin_Stop;
  }

  char steamid32[20], steamid64[20];
  GetCmdArg(1, steamid32, sizeof(steamid32));

  ConvertSteamID32ToSteamID64(steamid32, steamid64, sizeof(steamid64));
  if (StrEqual(steamid64, "")) {
    ReplyToCommand(client, "%sWrong SteamID format", PREFIX);
    return Plugin_Stop;
  }

  char reason[100], raw_length[10];
  GetCmdArg(2, raw_length, sizeof(raw_length));
  GetCmdArg(3, reason, sizeof(reason));
  int length = StringToInt(raw_length);

  // Kick player if he is ingamae
  for (int i = 1; i < MaxClients; i++) {
    if (!IsClientInGame(i) || IsFakeClient(i)) continue;

    char steamid_target[20];
    GetClientAuthId(i, AuthId_SteamID64, steamid_target, sizeof(steamid_target));

    if (!StrEqual(steamid_target, steamid64)) continue;

    char admin_username[128], formatted_time[200];
    if (length > 0) HumanizeTime((length * 60), formatted_time); else formatted_time = "permanent";

    GetClientName(client, admin_username, sizeof(admin_username));
    ClientBanKick(i, admin_username, reason, formatted_time, formatted_time);
  }

  char adminID[37], global_ban[37];

  StrCat(adminID, sizeof(adminID),  (client == 0) ? "" : CLIENTS[client]);
  StrCat(global_ban, sizeof(global_ban), (MODULE_BAN_GLOBAL.IntValue == 0) ? SERVER : "");

  JSONObject payload = new JSONObject();

  if (!StrEqual(global_ban, ""))
    payload.SetString("server", SERVER);

  payload.SetString("reason", reason);
  payload.SetString("issuer", adminID);
  payload.SetInt("length", length * 60);

  char url[512] = "users/";
  StrCat(url, sizeof(url), steamid64);
  StrCat(url, sizeof(url), "/ban");

  httpClient.Put(url, payload, APINoResponseCall);
  delete payload;

  return Plugin_Stop;
}

public Action OnBanClient(int client, int time, int flags, const char[] reason, const char[] kick_message, const char[] command, any admin) {
  if (StrEqual(SERVER, "")) {
    ReplyToCommand(admin, "Connection to API was not successfull. Cannot ban right now.", PREFIX);
    return Plugin_Stop;
  }

  char adminID[37], global_ban[37];
  StrCat(adminID, sizeof(adminID), (admin == 0) ? "" : CLIENTS[admin]);
  StrCat(global_ban, sizeof(global_ban), (MODULE_BAN_GLOBAL.IntValue == 0) ? SERVER : "");

  JSONObject payload = new JSONObject();

  if (!StrEqual(global_ban, "")) {
    payload.SetString("server", SERVER);
  }

  payload.SetString("reason", reason);
  payload.SetString("issuer", adminID);
  payload.SetInt("length", time * 60);


  char url[512] = "users/";
  StrCat(url, sizeof(url), CLIENTS[client]);
  StrCat(url, sizeof(url), "/ban");

  httpClient.Put(url, payload, APINoResponseCall);
  delete payload;

  char cAdminName[MAX_NAME_LENGTH], cTime[200];
  GetClientName(admin, cAdminName, sizeof(cAdminName));
  if(time > 0) HumanizeTime(time * 60, cTime); else cTime = "permanent";

  char cReason[128];
  StrCat(cReason, sizeof(cReason), reason);

  ReplyToCommand(admin, "%sPlayer successfully banned!", PREFIX);
  ClientBanKick(client, cAdminName, cReason, cTime, cTime);

  return Plugin_Stop;
}
