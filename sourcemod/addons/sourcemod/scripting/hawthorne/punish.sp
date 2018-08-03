void Punishment_OnPluginStart() {
  BuildPath(Path_SM, PUNISHMENT_TIMES,  sizeof(PUNISHMENT_TIMES),  "configs/hawthorne/punishment.txt");
  BuildPath(Path_SM, BAN_REASONS,       sizeof(BAN_REASONS),   "configs/hawthorne/reasons/ban.txt");
  BuildPath(Path_SM, GAG_REASONS,       sizeof(GAG_REASONS),       "configs/hawthorne/reasons/gag.txt");
  BuildPath(Path_SM, MUTE_REASONS,      sizeof(MUTE_REASONS),      "configs/hawthorne/reasons/mute.txt");
  BuildPath(Path_SM, SILENCE_REASONS,   sizeof(SILENCE_REASONS),   "configs/hawthorne/reasons/silence.txt");
}

public void Punishment_OnClientPutInServer(int client) {
  if (!MODULE_PUNISH.BoolValue || StrEqual(SERVER, "") || IsFakeClient(client)) return;

  char url[512] = "users/";
  StrCat(url, sizeof(url), CLIENTS[client]);
  StrCat(url, sizeof(url), "/punishment?banned=false&kicked=false&resolved=false&server=");
  StrCat(url, sizeof(url), SERVER);

  httpClient.Get(url, OnPunishmentCheck, client);
}

public void OnPunishmentCheck(HTTPResponse response, any value) {
  int client = value;

  if (client < 1) return;
  if (!APIValidator(response)) return;

  JSONObject output = view_as<JSONObject>(response.Data);
  JSONArray results = view_as<JSONArray>(output.Get("result"));

  if (results.Length < 1) return;
  JSONObject result = view_as<JSONObject>(results.Get(0));

  char reason[256];
  int action;
  int length = RoundToZero(result.GetFloat("length"));
  int created_at = RoundToZero(result.GetFloat("created_at"));
  int now = GetTime();
  int timeleft = (created_at + length) - now;
  if (timeleft < 0) timeleft = 0;

  result.GetString("reason", reason, sizeof(reason));
  bool muted = result.GetBool("is_muted");
  bool gagged = result.GetBool("is_gagged");

  if (muted && gagged) action = ACTION_SILENCE;
  else if (gagged) action = ACTION_GAG;
  else action = ACTION_MUTE;

  InitiatePunishment(client, action, reason, timeleft);
}

public Action PunishCommandExecuted(int client, const char[] cmd, int args) {
  if (MODULE_PUNISH.IntValue == 0 || StrEqual(SERVER, "")) return Plugin_Continue;
  selected_action[client] = 0;
  selected_player[client] = -1;
  selected_conflict[client] = -1;
  selected_duration[client] = -1;
  selected_reason[client] = "";

  char command[64];
  GetCmdArg(0, command, sizeof(command));

  int action = 0;
  int target = -1;
  char reason[256];
  char username[256] = "";
  char duration[256];

  if (StrContains(command, "unmute") != -1) action = ACTION_UNMUTE;
  else if (StrContains(command, "ungag") != -1) action = ACTION_UNGAG;
  else if (StrContains(command, "unsilence") != -1) action = ACTION_UNSILENCE;
  else if (StrContains(command, "unban") != -1) action = ACTION_UNBAN;
  else if (StrContains(command, "mute") != -1) action = ACTION_MUTE;
  else if (StrContains(command, "gag") != -1) action = ACTION_GAG;
  else if (StrContains(command, "silence") != -1) action = ACTION_SILENCE;
  else if (StrContains(command, "ban") != -1) action = ACTION_BAN;

  if (action == ACTION_BAN && !CheckCommandAccess(client, cmd, ADMFLAG_BAN)) return Plugin_Stop;
  else if (action == ACTION_UNBAN && !CheckCommandAccess(client, cmd, ADMFLAG_UNBAN)) return Plugin_Stop;
  else if (action != ACTION_BAN && action != ACTION_UNBAN && !CheckCommandAccess(client, cmd, ADMFLAG_CHAT)) return Plugin_Stop;

  selected_action[client] = action;

  Menu players = new Menu(MenuHandlerPlayer);
  if (args >= 1) {
    GetCmdArg(1, username, sizeof(username));
  }

  if (args >= 2) {
    char tmp[128], error[128], pattern[128];
    GetCmdArg(2, tmp, sizeof(tmp));

    pattern = "^([0-9]+[a-zA-Z]{1})+$";

    if (SimpleRegexMatch(tmp, pattern, 0, error, sizeof(error)) != -1) duration = tmp;
  }

  if (args >= 3) {
    int start = 2;

    if (!StrEqual(duration, "")) start = 3;

    for (int i = start; i <= args; i++) {
      char tmp[128];
      GetCmdArg(i, tmp, sizeof(tmp));

      StrCat(reason, sizeof(reason), " ");
      StrCat(reason, sizeof(reason), tmp);
    }
  }

  if (!StrEqual(duration, "")) selected_duration[client] = DehumanizeTime(duration, sizeof(duration));

  if (!StrEqual(username, "")) {
    for (int i = 1; i < MaxClients; i++) {
      char name[256];
      char steam2[128];
      char steam64[128];
      if (!IsClientInGame(i) || IsFakeClient(i)) continue;

      GetClientName(i, name, sizeof(name));
      GetClientAuthId(i, AuthId_Steam2, steam2, sizeof(steam2));
      GetClientAuthId(i, AuthId_SteamID64, steam64, sizeof(steam64));

      if (StrContains(name, username, false) != -1 || StrEqual(steam2, username) || StrEqual(steam64, username)) {
        target = GetClientUserId(i);
        break;
      }
    }

    if (target == -1) {
      ReplyToCommand(client, "Could not find the user requested.");
      return Plugin_Stop;
    }

    selected_player[client] = target;
    MenuHandlerPlayer(players, MenuAction_Select, client, -1);
  } else {
    PopulateMenuWithPeople(players, action, client);
    players.ExitButton = true;
    players.Display(client, 20);
  }

  return Plugin_Stop;
}

public int MenuHandlerPlayer(Menu menu, MenuAction action, int client, int param) {
  if (action != MenuAction_Select) return -1;

  Menu conflict = new Menu(MenuHandlerConflict);
  if (selected_player[client] == -1) {
    char selected[16];
    menu.GetItem(param, selected, sizeof(selected));

    selected_player[client] = StringToInt(selected);
  }

  if (!selected_player[client]) {
    PrintToChat(client, "That player isn't online anymore!");
    return -1;
  }

  int mode = selected_action[client];
  int target = GetClientOfUserId(selected_player[client]);
  bool muted = BaseComm_IsClientMuted(target);
  bool gagged = BaseComm_IsClientGagged(target);

  AdminId target_admin = GetUserAdmin(target);
  AdminId client_admin = GetUserAdmin(client);
  if (!CanAdminTarget(client_admin, target_admin)) {
    CReplyToCommand(client, "The target has a higher immunity level than yours.");
    return -1;
  }

  if (mode == ACTION_UNMUTE && !muted) {
    CReplyToCommand(client, "The target is already unmuted.");
    return -1;
  }

  if (mode == ACTION_UNGAG && !gagged) {
    CReplyToCommand(client, "The target is already ungagged.");
    return -1;
  }

  if (mode == ACTION_UNSILENCE && !gagged && !muted) {
    CReplyToCommand(client, "The target is already unsilenced.");
    return -1;
  }

  mode = 0;
  if (mode == ACTION_MUTE && gagged && muted) {
    mode = CONFLICT_ABORT;
  } else if (mode == ACTION_MUTE && muted) {
    mode = CONFLICT_OVERWRITE;
  } else if (mode == ACTION_MUTE && gagged) {
    mode = CONFLICT_CONVERT;
  }

  if (mode == ACTION_GAG && gagged && muted) {
    mode = CONFLICT_ABORT;
  } else if (mode == ACTION_GAG && muted) {
    mode = CONFLICT_CONVERT;
  } else if (mode == ACTION_GAG && gagged) {
    mode = CONFLICT_OVERWRITE;
  }

  if (mode == ACTION_SILENCE && gagged && muted) {
    mode = CONFLICT_OVERWRITE;
  } else if (mode == ACTION_SILENCE && muted || mode == ACTION_SILENCE && gagged) {
    mode = CONFLICT_ABORT;
  }

  if (client < 0 && mode != 0) {
    ReplyToCommand(client, "Aborting command on RCON interfaces when conflict happened.");
    return -1;
  }

  if (mode != 0) {
    menu.SetTitle("A conflict was detected. What should happen with the currently active mode.");
    if (mode == CONFLICT_OVERWRITE || mode == CONFLICT_EXTEND) {
      char overwrite[3], extend[3];
      IntToString(CONFLICT_OVERWRITE, overwrite, sizeof(overwrite));
      IntToString(CONFLICT_EXTEND, extend, sizeof(extend));

      conflict.AddItem(overwrite, "Overwrite");
      conflict.AddItem(extend, "Extend");
    }

    if (mode == CONFLICT_CONVERT) {
      char convert[3];
      IntToString(CONFLICT_CONVERT, convert, sizeof(convert));

      conflict.AddItem(convert, "Convert");
    }

    conflict.ExitButton = true;
    conflict.Display(client, 20);
  } else {
    MenuHandlerConflict(conflict, MenuAction_Select, client, -1);
  }

  return 1;
}

public int MenuHandlerConflict(Menu menu, MenuAction action, int client, int param) {
  if (action != MenuAction_Select) return -1;

  Menu duration = new Menu(MenuHandlerDuration);

  if (param != -1) {
    char selected[16];
    menu.GetItem(param, selected, sizeof(selected));

    selected_conflict[client] = StringToInt(selected);
  }

  if (selected_duration[client] == -1 && selected_action[client] > 0) {
    PopulateMenuWithConfig(duration, PUNISHMENT_TIMES);
    duration.ExitButton = true;
    duration.Display(client, 20);
  } else {
    MenuHandlerDuration(duration, MenuAction_Select, client, -1);
  }

  return 1;
}

public int MenuHandlerDuration(Menu menu, MenuAction action, int client, int param) {
  if (action != MenuAction_Select) return -1;
  Menu reason = new Menu(MenuHandlerReason);

  if (param != -1) {
    char selected[16];
    menu.GetItem(param, selected, sizeof(selected));

    selected_duration[client] = StringToInt(selected);
  }

  if (StrEqual(selected_reason[client], "") && selected_action[client] > 0) {
    int mode = selected_action[client];

    if (mode == ACTION_UNSILENCE || mode == ACTION_SILENCE) PopulateMenuWithConfig(reason, SILENCE_REASONS);
    if (mode == ACTION_UNMUTE || mode == ACTION_MUTE) PopulateMenuWithConfig(reason, MUTE_REASONS);
    if (mode == ACTION_UNGAG || mode == ACTION_GAG) PopulateMenuWithConfig(reason, GAG_REASONS);
    if (mode == ACTION_UNBAN || mode == ACTION_BAN) PopulateMenuWithConfig(reason, BAN_REASONS);

    reason.ExitButton = true;
    reason.Display(client, 20);
  } else {
    MenuHandlerReason(reason, MenuAction_Select, client, -1);
  }

  return 1;
}

public int MenuHandlerReason(Menu menu, MenuAction action, int client, int param) {
  if (action != MenuAction_Select) return -1;

  if (param != -1) {
    char selected[256];
    menu.GetItem(param, selected, sizeof(selected));

    strcopy(selected_reason[client], sizeof(selected_reason[]), selected);
  }

  PunishExecution(client);
  return 1;
}

public int PunishExecution(int client) {
  bool mute = false;
  bool gag = false;
  bool ban = false;

  switch (selected_action[client]) {
    case ACTION_MUTE: mute = true;
    case ACTION_GAG: gag = true;
    case ACTION_SILENCE: {
      mute = true;
      gag = true;
    }
    case ACTION_BAN: ban = true;
  }

  JSONObject payload_del = new JSONObject();
  JSONObject payload_put = new JSONObject();
  payload_del.SetString("server", SERVER);
  payload_put.SetBool("plugin", false);

  char url[512] = "users/";
  StrCat(url, sizeof(url), CLIENTS[GetClientOfUserId(selected_player[client])]);
  StrCat(url, sizeof(url), "/punishment");

  if (selected_conflict[client] == CONFLICT_NONE) {

    if (!MODULE_PUNISHMENT_GLOBAL.BoolValue)
      payload_put.SetString("server", SERVER);

    payload_put.SetString("reason", selected_reason[client]);
    payload_put.SetBool("muted", mute);
    payload_put.SetBool("gagged", gag);
    payload_put.SetBool("banned", ban);
    payload_put.SetInt("length", selected_duration[client]);

    if (selected_action[client] < 0) {
      StrCat(url, sizeof(url), "?server=");
      StrCat(url, sizeof(url), SERVER);
      StrCat(url, sizeof(url), "&plugin=false");
      httpClient.Delete(url, APINoResponseCall);
     } else
      httpClient.Put(url, payload_put, APINoResponseCall);

  } else if (selected_conflict[client] == CONFLICT_OVERWRITE) {
    httpClient.Put(url, payload_put, APINoResponseCall);

    StrCat(url, sizeof(url), "?server=");
    StrCat(url, sizeof(url), SERVER);
    StrCat(url, sizeof(url), "&plugin=false");
    httpClient.Delete(url, APINoResponseCall);
  } else if (selected_conflict[client] == CONFLICT_EXTEND) {
    StrCat(url, sizeof(url), "?resolved=true&server=");
    StrCat(url, sizeof(url), SERVER);

    httpClient.Get(url, APIPunishmentExtendResponseCall, client);
  } else if (selected_conflict[client] == CONFLICT_CONVERT) {
    payload_del.SetBool("muted", true);
    payload_del.SetBool("gagged", true);
    httpClient.Post(url, payload_del, APINoResponseCall);
  }

  InitiatePunishment(GetClientOfUserId(selected_player[client]), selected_action[client], selected_reason[client], selected_duration[client], client);
  delete payload_put;
  delete payload_del;

  return 1;
}

public void APIPunishmentExtendResponseCall(HTTPResponse response, any value) {
  int client = value;
  if (!APIValidator(response)) return;

  JSONObject output = view_as<JSONObject>(response.Data);
  JSONArray results = view_as<JSONArray>(output.Get("result"));

  if (results.Length < 1) return;
  JSONObject result = view_as<JSONObject>(results.Get(0));
  int length = RoundFloat(result.GetFloat("length"));
  length += selected_duration[client];

  JSONObject payload = new JSONObject();
  payload.SetString("server", SERVER);
  payload.SetInt("length", length);

  char url[512] = "users/";
  StrCat(url, sizeof(url), CLIENTS[GetClientOfUserId(selected_player[client])]);
  StrCat(url, sizeof(url), "/punishment");

  httpClient.Post(url, payload, APINoResponseCall);

  delete results;
  delete result;
  delete output;
  delete payload;
}

void PopulateMenuWithConfig(Menu menu, char[] path) {
  char content[512];
  File file = OpenFile(path, "r", false, NULL_STRING);
  file.ReadString(content, sizeof(content), -1);
  file.Close();

  char values[MAX_REASONS][256];
  int size = ExplodeString(content, "\n", values, sizeof(values), sizeof(values[]));

  for (int i = 0; i < size; i++) {
    if (StrContains(values[i], " | ") != -1) {
      char sub[2][256];
      ExplodeString(values[i], " | ", sub, sizeof(sub), sizeof(sub[]));

      menu.AddItem(sub[0], sub[1]);
    } else {
      menu.AddItem(values[i], values[i]);
    }
  }
}

void PopulateMenuWithPeople(Menu menu, int action, int client) {
  for (int i = 1; i <= MaxClients; i++) {
    if (!IsClientInGame(i) || IsFakeClient(i)) continue;
    bool muted = BaseComm_IsClientMuted(i);
    bool gagged = BaseComm_IsClientGagged(i);

    switch (action) {
      case ACTION_UNSILENCE: if (!muted || !gagged) continue;
      case ACTION_UNGAG:     if ( muted || !gagged) continue;
      case ACTION_UNMUTE:    if (!muted ||  gagged) continue;
      case ACTION_MUTE:      if ( muted ||  gagged) continue;
      case ACTION_GAG:       if ( muted ||  gagged) continue;
      case ACTION_SILENCE:   if ( muted ||  gagged) continue;
    }

    AdminId target = GetUserAdmin(i);
    AdminId admin = GetUserAdmin(client);
    if (!CanAdminTarget(admin, target)) continue;

    char username[128], id[8];
    GetClientName(i, username, sizeof(username));

    IntToString(GetClientUserId(i), id, sizeof(id));
    menu.AddItem(id, username);
  }
}

void InitiatePunishment(int client, int action, char[] reason, int timeleft, int admin = 0) {
  char name[256];

  switch (action) {
    case ACTION_UNSILENCE: {
      name = "unsilenced";
      BaseComm_SetClientGag(client, false);
      BaseComm_SetClientMute(client, false);
    }
    case ACTION_UNGAG: {
      name = "ungagged";
      BaseComm_SetClientGag(client, false);
    }
    case ACTION_UNMUTE: {
      name = "unmuted";
      BaseComm_SetClientMute(client, false);
    }
    case ACTION_MUTE: {
      name = "muted";
      BaseComm_SetClientMute(client, true);
    }
    case ACTION_GAG: {
      name = "gagged";
      BaseComm_SetClientGag(client, true);
    }
    case ACTION_SILENCE: {
      name = "silenced";
      BaseComm_SetClientGag(client, true);
      BaseComm_SetClientMute(client, true);
    }
  }

  if (action < 0) {
    mutegag_timer[client].Close();
    mutegag_timer[client] = null;

    CPrintToChat(client, "--------------------------");
    CPrintToChat(client, "Note: You are now {olive}%s{default} again.", name);
    CPrintToChat(client, "--------------------------");
  } else {
    char humanized_time[200];
    HumanizeTime(timeleft, humanized_time);
    if (timeleft <= 0) humanized_time = "eternity";

    if (action == ACTION_BAN) {
      char username[MAX_NAME_LENGTH];

      GetClientName(admin, username, sizeof(username));
      ReplaceString(username, sizeof(username), "\\", "");
      ReplaceString(username, sizeof(username), "\"", "''");

      ClientBanKick(client, username, reason, humanized_time, humanized_time);
      return;
    }

    CPrintToChat(client, "--------------------------");
    CPrintToChat(client, "Note: You are being {red}%s{default}.", name);
    CPrintToChat(client, "Reason: %s", reason);
    CPrintToChat(client, "Time left: %s", humanized_time);
    CPrintToChat(client, "--------------------------");

    if (mutegag_timeleft[client] != -1) return;
    mutegag_timeleft[client] = timeleft;

    if (timeleft <= 0) return;
    mutegag_timer[client] = CreateTimer(60.0, PunishmentTimer, client, TIMER_REPEAT);
  }
}


public Action PunishmentTimer(Handle timer, int client) {
  if (client < 0) return Plugin_Stop;

  mutegag_timeleft[client] -= 60;
  if (mutegag_timeleft[client] > 0) return Plugin_Continue;

  mutegag_timeleft[client] = -1;
  BaseComm_SetClientGag(client, false);
  BaseComm_SetClientMute(client, false);
  return Plugin_Stop;
}
