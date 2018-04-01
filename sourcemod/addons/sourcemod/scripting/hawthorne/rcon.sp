// TODO: TESTING
void RConCommands_OnPluginStart() {
  RegAdminCmd("json_status",        RConStatus,       ADMFLAG_RCON);
  RegAdminCmd("rcon_init",          RConInit,         ADMFLAG_RCON);

  RegAdminCmd("rcon_ban",           RConBanKick,      ADMFLAG_RCON);
  RegAdminCmd("rcon_mutegag__add",  RConMuteGagAdd,   ADMFLAG_RCON);
  RegAdminCmd("rcon_mutegag__rem",  RConMuteGagRem,   ADMFLAG_RCON);
  RegAdminCmd("rcon_mutegag__res",  RConMuteGagRes,   ADMFLAG_RCON);
  RegAdminCmd("rcon_reload",        RConReload,       ADMFLAG_RCON);
}

public Action RConReload(int client, int args) {
  if(client != 0)
    return Plugin_Handled;

  char steamid[20];
  GetCmdArg(1, steamid, sizeof(steamid));
  int target = GetClientFromSteamID(steamid);

  if (target != -1) OnClientPreAdminCheck(target);

  return Plugin_Handled;
}

public Action RConMuteGagRes(int client, int args) {
  if(client != 0)
    return Plugin_Handled;

  char steamid[20];
  GetCmdArg(1, steamid, sizeof(steamid));
  int target = GetClientFromSteamID(steamid);

  if(target != -1) {

    char cType[2], cTimeLeft[20], cLength[20];
    GetCmdArg(2, cType, sizeof(cType));
    GetCmdArg(3, cLength, sizeof(cLength));
    GetCmdArg(4, cTimeLeft, sizeof(cTimeLeft));
    int iType     = StringToInt(cType);
    int iLength   = StringToInt(cLength);
    int iTimeleft   = StringToInt(cTimeLeft);

    RestoreMuteGag(target, iType, iLength, iTimeleft);
  }

  return Plugin_Handled;
}


public Action RConMuteGagRem(int client, int args) {
  if(client != 0)
    return Plugin_Handled;

  char steamid[20];
  GetCmdArg(1, steamid, sizeof(steamid));
  int target = GetClientFromSteamID(steamid);

  if(target != -1) {

    char cType[2];
    GetCmdArg(2, cType, sizeof(cType));
    int iType   = StringToInt(cType);

    RemoveMuteGag(target, iType);
  }

  return Plugin_Handled;
}


public Action RConMuteGagAdd(int client, int args) {
  if(client != 0)
    return Plugin_Handled;

  char steamid[20];
  GetCmdArg(1, steamid, sizeof(steamid));
  int target = GetClientFromSteamID(steamid);

  if(target != -1) {

    char cType[2], cReason[150], cLength[20];
    GetCmdArg(2, cType, sizeof(cType));
    GetCmdArg(3, cReason, sizeof(cReason));
    GetCmdArg(4, cLength, sizeof(cLength));

    int iType   = StringToInt(cType);
    int iLength = StringToInt(cLength);

    AddMuteGag(target, iType, iLength, iLength, cReason);

  }

  return Plugin_Handled;
}

public Action RConBanKick(int client, int args) {
  if(client != 0)
    return Plugin_Handled;


  char steamid[20];
  GetCmdArg(1, steamid, sizeof(steamid));
  int target = GetClientFromSteamID(steamid);

  if(target != -1) {
    char cAdminUsername[128], cReason[150], cLength[50], cTime[200];
    GetCmdArg(2, cAdminUsername, sizeof(cAdminUsername));
    GetCmdArg(3, cReason, sizeof(cReason));
    GetCmdArg(4, cLength, sizeof(cLength));
    int iLength = StringToInt(cLength);
    if(iLength > 0) SecondsToTime(iLength * 60, cTime); else cTime = "permanent";
    ClientBanKick(target, cAdminUsername, cReason, cTime, cTime);
    ReplyToCommand(client, "[hawthorne] Player ban kicked!");
  }

  return Plugin_Handled;

}

int GetClientFromSteamID(char steamid[20]) {
  for (int i = 1; i < MaxClients; i++) {
    if(IsClientInGame(i) && !IsFakeClient(i)) {
      char steamid2[20];
      GetClientAuthId(i, AuthId_Steam2, steamid2, sizeof(steamid2));
      if(StrEqual(steamid, steamid2))
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

  char reply[1024];
  output.ToString(reply, sizeof(reply));
  ReplyToCommand(client, reply);

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
      player.SetString("steamid", steamid);

      player.SetInt("team", GetClientTeam(i));
      player.SetInt("kills", kills);
      player.SetInt("deaths", deaths);
      player.SetFloat("online", online);

      output.Push(player);
    }
  }

  return output;
}
