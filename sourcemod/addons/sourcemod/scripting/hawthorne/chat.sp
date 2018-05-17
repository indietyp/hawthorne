public Action OnPlayerChatMessage(int client, const char[] command, int argc) {
  // check if the client is an actual person
  if (client < 1) return Plugin_Continue;

  char message[256];
  GetCmdArgString(message, sizeof(message));

  // cleanup quotes
  strcopy(message, sizeof(message), message[1]);
  message[strlen(message) - 1] = 0;

  if (!MODULE_LOG.BoolValue || StrEqual(SERVER, "")) return Plugin_Continue;
  if (StrEqual(CLIENTS[client], "")) {
    LogError("[HT] Failed to send message to the API of the MANAGER, the client UUID was not fetched.");
    return Plugin_Continue;
  }

  SendChatMessage(client, message);
  return Plugin_Continue;
}

stock void SendChatMessage(int client, char[] message, int type = 0) {
  char ip[128];

  GetClientIP(client, ip, sizeof(ip));

  JSONObject payload = new JSONObject();
  payload.SetString("user", CLIENTS[client]);
  payload.SetString("server", SERVER);
  payload.SetString("ip", ip);
  payload.SetString("message", message);
  httpClient.Put("system/chat", payload, APINoResponseCall);

  delete payload;
}


public Action OnClientCommand(int client, int args) {
  // get the command used
  char command[512];
  GetCmdArg(0, command, sizeof(command));

  // check if the client is an actual person and online
  if (!IsClientInGame(client) || IsFakeClient(client)) return Plugin_Continue;
  if (client < 1) return Plugin_Continue;
  if (!MODULE_LOG.BoolValue || StrEqual(SERVER, "")) return Plugin_Continue;
  if (StrContains(command, "sm_") == -1 || !IsAdminCMD(command)) return Plugin_Continue;

  // formatting the command to include the argument used
  char arguments[512];
  GetCmdArgString(arguments, sizeof(arguments));

  Format(command, sizeof(command), "%s %s", command, arguments);
  SendChatMessage(client, command, 1);

  return Plugin_Continue;
}

bool IsAdminCMD(char[] command) {
  // we are excluding VIP privileges
  AdminId admin = CreateAdmin();
  admin.SetFlag(Admin_Custom1, true);
  admin.SetFlag(Admin_Custom2, true);
  admin.SetFlag(Admin_Custom3, true);
  admin.SetFlag(Admin_Custom4, true);
  admin.SetFlag(Admin_Custom5, true);
  admin.SetFlag(Admin_Custom6, true);
  admin.SetFlag(Admin_Reservation, true);
  RemoveAdmin(admin);

  if (CheckAccess(admin, command, 0, false)) return false;
  return true;
}
