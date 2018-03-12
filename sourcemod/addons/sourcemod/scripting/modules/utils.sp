void Hawthorne_OnPluginStart() {
  Hawthorne_InitConVars();
  MuteGag_OnPluginStart();
  RConCommands_OnPluginStart();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
  Hawthorne_InitConVars();
  RegPluginLibrary("hawthorne");
  CreateNatives();
  return APLRes_Success;
}

void OnServerIDUpdated() {
  for (int i = 1; i <= MaxClients; i++)
    if(IsClientInGame(i) && !IsFakeClient(i) && CLIENTS[i] < 1) {

      MuteGag_OnClientDisconnect(i);

      OnClientPutInServer(i);
      char steamid[20];
      GetClientAuthId(i, AuthId_Steam2, steamid, sizeof(steamid));
      OnClientAuthorized(i, steamid);

    }
  Call_Finish();
}

void OnClientIDReceived(int client) {
  //Push event
  Call_StartForward(forward_client);
  Call_PushCell(client);
  Call_Finish();

  Bans_OnClientIDReceived(client);
  MuteGag_OnClientIDReceived(client);
}

public void OnMapStart() {
  Bans_OnMapStart();
  MuteGag_OnMapStart();
}

public void OnClientPutInServer(int client) {
  if(!IsFakeClient(client)) {
    MuteGag_OnClientPutInServer(client);
    //PlayersOnline2_OnClientPutInServer(client);
    //Players_OnClientPutInServer(client);
  }
}

public Action Event_Disconnect(Event event, const char[] name, bool dontBroadcast) {
  //char reason[255];
  //GetEventString(event, "reason", reason, sizeof(reason));
  int client = GetClientOfUserId(event.GetInt("userid"));
  if(client > 0 && !IsFakeClient(client)) {
    //PlayersOnline2_OnClientFullDisconnect(client);
    Admins_OnClientDisconnect(client);
  }

  return Plugin_Continue;
}

public void OnClientDisconnect(int client) {
  MuteGag_OnClientDisconnect(client);
  //PlayersOnline2_OnClientDisconnect(client);
  Players_OnClientDisconnect(client);
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast) {
  int client = GetClientOfUserId(GetEventInt(event, "userid"));
  int team = GetEventInt(event, "team");
  if(!IsFakeClient(client) && team != 0) {
    MuteGag_PlayerTeam(client);
  }
}

//public void OnClientPostAdminCheck(int client)
public void OnClientAuthorized(int client, const char[] auth) {
  if(!IsFakeClient(client)) {
    Players_OnClientAuthorized(client);
  }
}
