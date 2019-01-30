void ClientBanKick(int client, char[] admin, char[] reason, char[] total, char[] current) {
  char time[256];

  if (StrEqual(total, "permanent"))
    Format(time, sizeof(time), "This action is permanent");
  else
    Format(time, sizeof(time), "You have been banned for a total of %s, of those %s are left", total, current);

  KickClient(client,
  "You have been banned from this server %s\n "...
  "\nThis was caused by %s with the reason: '%s'."...
  "\n\n%s", SERVER_HOSTNAME, admin, reason, time);
}

void Bans_OnClientIDReceived(int client) {
  if (!MODULE_BAN.BoolValue || StrEqual(SERVER, "") || IsFakeClient(client)) return;

  char url[512] = "users/";
  StrCat(url, sizeof(url), CLIENTS[client]);
  StrCat(url, sizeof(url), "/punishments?banned=true&muted=false&gagged=false&resolved=false&kicked=false&server=");
  StrCat(url, sizeof(url), SERVER);

  httpClient.Get(url, OnBanCheck, client);
}


public void OnBanCheck(HTTPResponse response, any value) {
  int client = value;

  if (client < 1) return;
  if (!APIValidator(response)) return;

  JSONObject output = view_as<JSONObject>(response.Data);
  JSONArray results = view_as<JSONArray>(output.Get("result"));

  if (results.Length == 0) return;
  JSONObject result = view_as<JSONObject>(results.Get(0));

  char passed[200], total[200];
  char issuer[128], reason[128];
  result.GetString("admin", issuer, sizeof(issuer));
  result.GetString("reason", reason, sizeof(reason));

  int creation = RoundFloat(result.GetFloat("created_at"));
  int length = RoundFloat(result.GetFloat("length"));
  int now = GetTime();

  if (length != 0) {
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
  payload.SetBool("banned", true);

  char url[512] = "users/";
  StrCat(url, sizeof(url), CLIENTS[client]);
  StrCat(url, sizeof(url), "/punishments");

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
