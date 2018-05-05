void MuteGag_OnPluginStart() {
  BuildPath(Path_SM, PUNISHMENT_TIMES,  sizeof(PUNISHMENT_TIMES),  "configs/hawthorne/punishment.txt");
  BuildPath(Path_SM, GAG_REASONS,       sizeof(GAG_REASONS),       "configs/hawthorne/reasons/gag.txt");
  BuildPath(Path_SM, MUTE_REASONS,      sizeof(MUTE_REASONS),      "configs/hawthorne/reasons/mute.txt");
  BuildPath(Path_SM, SILENCE_REASONS,   sizeof(SILENCE_REASONS),   "configs/hawthorne/reasons/silence.txt");
}

public Action PunishCommandExecuted(int client, int args) {
  if (MODULE_PUNISH.IntValue == 0 || StrEqual(SERVER, "")) return Plugin_Continue;

  punish_selected_action[client] = 0;
  punish_selected_player[client] = -1;
  punish_selected_conflict[client] = -1;
  punish_selected_duration[client] = -1;
  punish_selected_reason[client] = "";

  char command[64];
  GetCmdArg(0, command, sizeof(command));

  int action = 0;
  int target = -1;
  char reason[256];
  char username[256];
  char duration[256];

  if (StrContains("unmute") != -1) action = ACTION_UNMUTE
  else if (StrContains("ungag") != -1) action = ACTION_UNGAG
  else if (StrContains("unsilence") != -1) action = ACTION_UNSILENCE
  else if (StrContains("mute") != -1) action = ACTION_MUTE
  else if (StrContains("gag") != -1) action = ACTION_GAG
  else if (StrContains("silence") != -1) action = ACTION_SILENCE

  punish_selected_action[client] = action;

  Menu players = new Menu(MenuHandlerPlayer);
  if (args >= 1) {
    GetCmdArg(1, username, sizeof(username));
  }

  if (args >= 2) {
    char tmp[128], error[128];
    GetCmdArg(2, tmp, sizeof(tmp));

    if (SimpleRegexMatch(tmp, "^(\d+\w{1})+$", 0, error, sizeof(error)) != -1) {
      duration = tmp;
    }
  }

  if (args >= 3) {
    int start = 2;

    if (!StrEqual(duration, "")) start = 3

    for (int i = start, i <= args; i++) {
      char tmp[128];
      GetCmdArg(i, tmp, sizeof(tmp));

      StrCat(reason, sizeof(reason), " ");
      StrCat(reason, sizeof(reason), tmp);
    }
  }

  if (!StrEqual(duration, ""))
    punish_selected_duration[client] = DehumanizeTime(duration, sizeof(duraction))

  if (!StrEqual(username, "")) {
    for (int i = 1; i < MaxClients; i++) {
      char name[256];
      char steam2[128];
      char steam64[128];
      if (!IsClientInGame(i) || IsFakeClient(i)) continue;

      GetClientName(i, name, sizeof(name));
      GetClientAuthId(i, AuthId_Steam2, steam2, sizeof(steam2));
      GetClientAuthId(i, AuthId_SteamID64, steam64, sizeof(steam64));

      if (StrContains(username, name) != -1 || StrEqual(steam2, username) || StrEqual(steam64, username)) {
        target = i;
        break;
      }
    }

    if (target == -1) {
      ReplyToCommand(client, "Could not find the user requested.")
      return Plugin_Handeled;
    }

    punish_selected_player[client] = target
    MenuHandlerPlayer(players, MenuAction_Select, client, -1)
  } else {
    PopulateMenuWithPeople(players, action);
    players.ExitButton = true;
    players.Display(client, 20);
  }
}

public int MenuHandlerPlayer(Menu menu, MenuAction action, int client, int param) {
  if (action != MenuAction_Select) return -1;

  Menu conflict = new Menu(MenuHandlerConflict);
  if (punish_selected_player[client] == -1) {
    char selected[16];
    menu.GetItem(param, selected, sizeof(selected));

    punish_selected_player[client] = StringToInt(selected)
  }

  int mode = punish_selected_action[client];
  bool muted = BaseComm_IsClientMuted(punish_selected_player[client])
  bool gagged = BaseComm_IsClientGagged(punish_selected_player[client])

  if (mode == ACTION_UNMUTE && !muted) {
    ReplyToCommand(client, "The client is not even muted.")
    return -1;
  }

  if (mode == ACTION_UNGAG && !gagged) {
    ReplyToCommand(client, "The client is not even gagged.")
    return -1;
  }

  if (mode == ACTION_UNSILENCE && !gagged && !muted) {
    ReplyToCommand(client, "The client is not even silenced.")
    return -1;
  }

  mode = 0;
  if (mode == ACTION_MUTE && gagged && muted) {
    mode = CONFLICT_ABORT
  } else if (mode == ACTION_MUTE && muted) {
    mode = CONFLICT_OVERWRITE
  } else if (mode == ACTION_MUTE && gagged) {
    mode = CONFLICT_CONVERT
  }

  if (mode == ACTION_GAG && gagged && muted) {
    mode = CONFLICT_ABORT
  } else if (mode == ACTION_GAG && muted) {
    mode = CONFLICT_CONVERT
  } else if (mode == ACTION_GAG && gagged) {
    mode = CONFLICT_OVERWRITE
  }

  if (mode == ACTION_SILENCE && gagged && muted) {
    mode = CONFLICT_OVERWRITE
  } else if (mode == ACTION_SILENCE && muted || mode == ACTION_SILENCE && gagged) {
    mode = CONFLICT_ABORT
  }

  if (client < 0 && mode != 0) {
    ReplyToCommand("Aborting command on RCON interfaces when conflict happened.")
    return -1;
  }

  if (mode != 0) {
    menu.SetTitle(overwrite, "A conflict was detected. What should happen with the currently active mode.");
    char abort[3];
    if (mode == CONFLICT_OVERWRITE || mode == CONFLICT_EXTEND) {
      char overwrite[3], extend[3];
      IntToStr(CONFLICT_OVERWRITE, overwrite, sizeof(overwrite))
      IntToStr(CONFLICT_EXTEND, extend, sizeof(extend))

      conflict.AddItem(overwrite, "Overwrite");
      conflict.AddItem(extend, "Extend");
    }

    if (mode == CONFLICT_CONVERT) {
      char convert[3];
      IntToStr(CONFLICT_CONVERT, convert, sizeof(convert))

      conflict.AddItem(convert, "Convert");
    }

    conflict.ExitButton = true;
    conflict.Display(client, 20);
  } else {
    MenuHandlerConflict(conflict, MenuAction_Select, client, -1)
  }
}

public int MenuHandlerConflict(Menu menu, MenuAction action, int client, int param) {
  if (action != MenuAction_Select) return -1;

  Menu duration = new Menu(MenuHandlerDuration);

  if (param != -1) {
    char selected[16];
    menu.GetItem(param, selected, sizeof(selected));

    punish_selected_conflict[client] = StringToInt(selected)
  }

  if (punish_selected_duration[client] == -1) {
    PopulateMenuWithConfig(duration, PUNISHMENT_TIMES)
    duration.ExitButton = true;
    duration.Display(client, 20);
  } else {
    MenuHandlerDuration(duration, MenuAction_Select, client, -1)
    // duration is already set, proceed with simulated menu
  }
}

public int MenuHandlerDuration(Menu menu, MenuAction action, int client, int param) {
  if (action != MenuAction_Select) return -1;
  Menu reason = new Menu(MenuHandlerReason);

  if (param != -1) {
    char selected[16];
    menu.GetItem(param, selected, sizeof(selected));

    punish_selected_duration[client] = StringToInt(selected)
  }

  if (StrEqual(punish_selected_reason[client], "")) {
    int mode = punish_selected_action[client];

    if (mode == ACTION_UNSILENCE || mode == ACTION_SILENCE) PopulateMenuWithConfig(duration, SILENCE_REASONS)
    if (mode == ACTION_UNMUTE || mode == ACTION_MUTE) PopulateMenuWithConfig(duration, MUTE_REASONS)
    if (mode == ACTION_UNGAG || mode == ACTION_GAG) PopulateMenuWithConfig(duration, GAG_REASONS)

    reason.ExitButton = true;
    reason.Display(client, 20);
  } else {
    MenuHandlerReason(reason, MenuAction_Select, client, -1)
  }
}

public int MenuHandlerReason(Menu menu, MenuAction action, int client, int param) {
  if (action != MenuAction_Select) return -1;

  if (param != -1) {
    char selected[256];
    menu.GetItem(param, selected, sizeof(selected));

    punish_selected_reason[client] = selected
  }

  PunishExecution(client)
}

public int PunishExecution(int client) {
  // check if gagged or muted - check API for more information on how long
  // update or overwrite accordingly.

  // EDGE CASES:
  // M,S,G already exists: consider the action that was selected
  // M exists and G selected: S will be enabled if asked
  // S - disable G - ask if converted to M
}

void PopulateMenuWithConfig(Menu menu, char[] path) {
  char content[512];
  File file = OpenFile(filepath, "r", false, NULL_STRING);
  file.ReadString(content, sizeof(content), -1);
  file.Close();

  char values[MAX_REASONS][256];
  int size = ExplodeString(content, "\n", values, sizeof(values), sizeof(values[]))

  for (int i = 0; int < size; i++) {
    if (StrContains(values[i], " | ") != -1) {
      char sub[2][256];
      ExplodeString(values[i], " | ", sub, sizeof(sub), sizeof(sub[]));

      menu.AddItem(sub[0], sub[1]);
    } else {
      menu.AddItem(values[i], values[i]);
    }
  }
}

void PopulateMenuWithPeople(Menu menu, int action) {
  for (int i = 1; i < MaxClients; i++) {
    if (!IsClientInGame(i) || IsFakeClient(i)) continue;
    bool muted = BaseComm_IsClientMuted(param)
    bool gagged = BaseComm_IsClientGagged(param)

    switch (action) {
      case ACTION_UNSILENCE: if (!muted || !gagged) continue;
      case ACTION_UNGAG:     if (muted || !gagged) continue;
      case ACTION_UNMUTE:    if (!muted || gagged) continue;
      case ACTION_MUTE:      if (!muted || gagged) continue;
      case ACTION_GAG:       if (muted || !gagged) continue;
      case ACTION_SILENCE:   if (!muted && !gagged) continue;
    }

    char username[128], id[5];
    GetClientName(i, username, sizeof(username));

    IntToStr(i, id, sizeof(id));
    menu.AddItem(id, username);
  }
}
