public Action OnPlayerChatMessage(int client, const char[] command, int argc) {
  // check if the client is an actual person
  if (client < 1) return Plugin_Continue;

  char message[256];
  GetCmdArgString(message, sizeof(message));

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

  // formatting the command to include the argument used
  char arguments[512];
  GetCmdArgString(arguments, sizeof(arguments));

  Format(command, sizeof(command), "%s %s", command, arguments);
  SendChatMessage(client, command, 1);

  return Plugin_Continue;
}
