void Duplicate_OnClientPutInServer(client) {
  if (!MODULE_DUPLICATE.BoolValue) return;

  char url[512];
  Format(url, sizeof(url), "system/sourcemod/verification?target=%s", CLIENTS[client]);

  AdvMOTD_ShowMOTDPanel(client, "Hawthorne", url, MOTDPANEL_TYPE_URL, false, false, true, OnMOTDFailure);
}

void OnMOTDFailure(int client, MOTDFailureReason reason) {
  LogError("[HT] Failed to launch MOTD to verify authentication of alternawe account for STEAM_ID");
}
