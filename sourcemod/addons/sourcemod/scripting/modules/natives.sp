void CreateNatives() {
  CreateNative("Bellwether_GetServerID",  Native_GetServerID);
  CreateNative("Bellwether_GetClientID",  Native_GetClientID);

  g_OnClientIDReceived = CreateGlobalForward("Bellwether_OnClientIDReceived", ET_Ignore, Param_Cell, Param_Cell);
  //g_OnDatabaseReady   = CreateGlobalForward("Bellwether_DatabaseReady", ET_Ignore);
}

public int Native_GetServerID(Handle plugin, int numParams) {
  int maxlength = GetNativeCell(2);

  SetNativeString(1, iServerID, maxlength);
}

public int Native_GetClientID(Handle plugin, int numParams) {
  int client = GetNativeCell(3);
  int maxlength = GetNativeCell(2);

  SetNativeString(1, (!IsFakeClient(client)) ? iClientID[client] : "", maxlength);
}
