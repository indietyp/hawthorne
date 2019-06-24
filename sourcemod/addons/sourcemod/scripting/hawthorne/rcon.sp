#pragma dynamic 524288

void InitRcon() {
  RegAdminCmd("rcon_status",        RconStatus,       ADMFLAG_RCON);
  RegAdminCmd("rcon_message",       RConMessage,      ADMFLAG_RCON);
  RegAdminCmd("rcon_ban",           RConBanKick,      ADMFLAG_RCON);
  RegAdminCmd("rcon_mutegag",       RConPunishment,   ADMFLAG_RCON);
  RegAdminCmd("rcon_init",          RConInit,         ADMFLAG_RCON);
  RegAdminCmd("rcon_sdonate",       RConInit,         ADMFLAG_RCON);
}

public Action RConPunishment(int client, int args) {
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

    int timeleft = StringToInt(raw_timeleft);
    int action;

    if (StrContains(command, "unmute") != -1) action = ACTION_UNMUTE;
    else if (StrContains(command, "ungag") != -1) action = ACTION_UNGAG;
    else if (StrContains(command, "unsilence") != -1) action = ACTION_UNSILENCE;
    else if (StrContains(command, "mute") != -1) action = ACTION_MUTE;
    else if (StrContains(command, "gag") != -1) action = ACTION_GAG;

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

public Action RConMessage(int client, int args) {
  // ARGS:
  // player (regex)
  // kick
  // message
  if (client != 0) return Plugin_Handled;
  char selector[64], raw_kick[8], raw_console[8], message[512];
  bool kick, console;

  GetCmdArg(1, selector, sizeof(selector));
  GetCmdArg(2, raw_kick, sizeof(raw_kick));
  GetCmdArg(3, raw_console, sizeof(raw_console));
  kick = StrEqual(raw_kick, "1");
  console = StrEqual(raw_console, "1");

  for (int i = 4; i <= args; i++) {
    char component[128];
    GetCmdArg(i, component, sizeof(component));

    StrCat(message, sizeof(message), component);
    StrCat(message, sizeof(message), "");
  }

  Regex regex = CompileRegex(selector);
  for (int i = 1; i <= MaxClients; i++) {
    if (!IsClientInGame(client) || IsFakeClient(client)) continue;

    char tmp[128];
    GetClientAuthId(i, AuthId_SteamID64, tmp, sizeof(tmp));
    if (MatchRegex(regex, tmp) > -1) {
      if (kick) KickClient(i, message);
      else CPrintToChat(i, message);
    }
  }

  if (console) PrintToServer(message);

  return Plugin_Handled;
}

public Action RconStatus(int client, int args) {
  char json[12288], reply[513], map[64], password[128];
  ConVar cv_password = FindConVar("sv_password");
  int timeleft;

  if (client != 0) return Plugin_Handled;
  JSONObject output = new JSONObject();
  JSONObject limits = new JSONObject();
  JSONObject teams = new JSONObject();
  JSONObject time = new JSONObject();

  // -- get data --
  GetCurrentMap(map, sizeof(map));
  GetMapTimeLeft(timeleft);
  GetConVarString(cv_password, password, sizeof(password));

  // -- insert misc --
  output.SetString("id", SERVER);
  output.SetString("map", map);
  output.SetBool("password", !StrEqual(password, ""));

  // -- insert clients --
  JSONArray players = AddToList();
  output.Set("clients", players);

  // -- insert time  --
  time.SetInt("left", timeleft);
  time.SetFloat("up", GetGameTime());
  output.Set("time", time);

  // -- insert limitations --
  limits.SetInt("clients", GetMaxHumanPlayers());
  output.Set("limitations", limits);

  // -- insert teams --
  for (int i = 0; i < GetTeamCount(); i++) {
    JSONObject team = new JSONObject();
    team.SetInt("id", i);
    team.SetInt("score", GetTeamScore(i));

    char name[256];
    GetTeamName(i, name, sizeof(name));
    teams.Set(name, team);
    delete team;
  }
  output.Set("teams", teams);

  // -- render output --
  output.ToString(json, sizeof(json));
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

  delete output;
  delete time;
  delete players;
  delete teams;
  delete limits;

  return Plugin_Handled;
}

JSONArray AddToList() {
  JSONArray output = new JSONArray();

  for (int i = 1; i <= MaxClients; i++) {
    if (IsClientInGame(i) && !IsFakeClient(i)) {
      char username[MAX_NAME_LENGTH], steamid[20];

      GetClientName(i, username, sizeof(username));
      GetClientAuthId(i, AuthId_SteamID64, steamid, sizeof(steamid));

      int kills = (!IsSpectator(i)) ? GetClientFrags(i) : 0;
      int deaths = (!IsSpectator(i)) ? GetClientDeaths(i) : 0;

      JSONObject client = new JSONObject();

      client.SetString("id", CLIENTS[i]);
      client.SetString("username", username);
      client.SetString("steamid", steamid);

      client.SetInt("team", GetClientTeam(i));
      client.SetInt("kills", kills);
      client.SetInt("deaths", deaths);
      client.SetFloat("connected", GetClientTime(i));

      output.Push(client);
      delete client;
    }
  }

  return output;
}
