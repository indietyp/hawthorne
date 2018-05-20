#pragma dynamic 524288

void RConCommands_OnPluginStart() {
  RegAdminCmd("json_status",        RConStatus,       ADMFLAG_RCON);

  RegAdminCmd("rcon_ban",           RConBanKick,      ADMFLAG_RCON);
  RegAdminCmd("rcon_mutegag",       RConMuteGag,      ADMFLAG_RCON);
  RegAdminCmd("rcon_init",          RConInit,         ADMFLAG_RCON);
  RegAdminCmd("rcon_sdonate",       RConInit,         ADMFLAG_RCON);
}

public Action RConMuteGag(int client, int args) {
  if(client != 0)
    return Plugin_Handled;

  char steamid[20];
  GetCmdArg(1, steamid, sizeof(steamid));
  int target = GetClientFromSteamID(steamid);

  if(target != -1) {
    char command[16], raw_timeleft[32], reason[128];
    GetCmdArg(2, command, sizeof(command));
    GetCmdArg(3, raw_timeleft, sizeof(raw_timeleft));
    GetCmdArg(4, reason, sizeof(reason));

    int timeleft  = StringToInt(raw_timeleft);
    int action;

    if (StrContains(command, "unmute") != -1) action = ACTION_UNMUTE;
    else if (StrContains(command, "ungag") != -1) action = ACTION_UNGAG;
    else if (StrContains(command, "unsilence") != -1) action = ACTION_UNSILENCE;
    else if (StrContains(command, "mute") != -1) action = ACTION_MUTE;
    else if (StrContains(command, "gag") != -1) action = ACTION_GAG;
    else if (StrContains(command, "silence") != -1) action = ACTION_SILENCE;

    InitiatePunishment(target, action, reason, timeleft);
  }

  return Plugin_Handled;
}

public Action RConBanKick(int client, int args) {
  if (client != 0) return Plugin_Handled;

  char steamid[20];
  GetCmdArg(1, steamid, sizeof(steamid));
  int target = GetClientFromSteamID(steamid);

  if (target != -1) {
    char cAdminUsername[128], cReason[150], cLength[50], cTime[200];
    GetCmdArg(2, cAdminUsername, sizeof(cAdminUsername));
    GetCmdArg(3, cReason, sizeof(cReason));
    GetCmdArg(4, cLength, sizeof(cLength));
    int iLength = StringToInt(cLength);
    if(iLength > 0) HumanizeTime(iLength, cTime); else cTime = "permanent";
    ClientBanKick(target, cAdminUsername, cReason, cTime, cTime);
    ReplyToCommand(client, "[hawthorne] Player ban kicked!");
  }

  return Plugin_Handled;

}

int GetClientFromSteamID(char steamid[20]) {
  for (int i = 1; i < MaxClients; i++) {
    if (IsClientInGame(i) && !IsFakeClient(i)) {
      char steamid2[20];
      GetClientAuthId(i, AuthId_SteamID64, steamid2, sizeof(steamid2));
      if (StrEqual(steamid, steamid2))
        return i;
    }
  }

  return -1;
}

public Action RConInit(int client, int args) {
  char token[37], url[512];

  GetCmdArg(1, url, sizeof(url));
  GetCmdArg(2, token, sizeof(token));

  APITOKEN.SetString(token);
  MANAGER.SetString(url);
}

public Action RConStatus(int client, int args) {
  if (client != 0)
    return Plugin_Handled;

  int online = 0;
  for (int i = 1; i <= MaxClients; i++)
    if(IsClientInGame(i) && !IsFakeClient(i))
      online++;

  char map[64];
  GetCurrentMap(map, sizeof(map));

  JSONObject scores = new JSONObject();
  int teams = GetTeamCount();
  for (int i = 0; i < teams; i++) {
    char name[256];
    GetTeamName(i, name, sizeof(name));
    scores.SetInt(name, GetTeamScore(i));
  }

  JSONObject output = new JSONObject();
  JSONObject stats = new JSONObject();

  int timeleft;
  GetMapTimeLeft(timeleft);

  stats.SetString("id", SERVER);
  stats.SetString("map", map);
  stats.SetInt("online", online);
  stats.SetInt("timeleft", timeleft);
  stats.SetFloat("uptime", GetGameTime());
  stats.Set("scores", scores);

  output.Set("stats", stats);
  output.Set("players", AddToList());

  char json[12288];
  output.ToString(json, sizeof(json));

  char reply[513];
  for (int i = 0; i <= sizeof(json); i++) {
    if (i % 512 == 0 && i != 0) {
      PrintToServer(reply);
      reply = "";
    }
    reply[i % 512] = json[i];
    if (json[i] == 0) {
      if (i % 512 != 0) PrintToServer(reply);
      break;
    }
  }

  delete stats;
  delete scores;
  delete output;

  return Plugin_Handled;
}

JSONArray AddToList() {
  JSONArray output = new JSONArray();

  for (int i = 1; i <= MaxClients; i++) {
    if (IsClientInGame(i) && !IsFakeClient(i)) {
      char username[MAX_NAME_LENGTH], steamid[20], cIP[20], cCountry[50];

      GetClientName(i, username, sizeof(username));
      ReplaceString(username, sizeof(username), "\\", "");
      ReplaceString(username, sizeof(username), "\"", "''");

      GetClientAuthId(i, AuthId_SteamID64, steamid, sizeof(steamid));
      GetClientIP(i, cIP, sizeof(cIP));
      GeoipCountry(cIP, cCountry, sizeof(cCountry));

      int kills   = (!IsSpectator(i)) ? GetClientFrags(i) : 0;
      int deaths  = (!IsSpectator(i)) ? GetClientDeaths(i) : 0;
      float online = GetClientTime(i);

      JSONObject player = new JSONObject();

      player.SetString("id", CLIENTS[i]);
      player.SetString("username", username);
      // player.SetString("steamid", steamid);

      // player.SetInt("team", GetClientTeam(i));
      player.SetInt("kills", kills);
      player.SetInt("deaths", deaths);
      player.SetInt("online", RoundFloat(online));

      output.Push(player);
    }
  }

  return output;
}
