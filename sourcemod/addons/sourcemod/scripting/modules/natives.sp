void CreateNatives() {
  CreateNative("hawthorne_GetServerUUID",  Native_GetServerUUID);
  CreateNative("hawthorne_GetClientID",  Native_GetClientID);

  forward_client = CreateGlobalForward("hawthorne_OnClientIDReceived", ET_Ignore, Param_Cell, Param_Cell);
}

public int Native_GetServerUUID(Handle plugin, int numParams) {
  int maxlength = GetNativeCell(2);

  SetNativeString(1, server, maxlength);
}

public int Native_GetClientID(Handle plugin, int numParams) {
  int client = GetNativeCell(3);
  int maxlength = GetNativeCell(2);

  SetNativeString(1, (!IsFakeClient(client)) ? ht_clients[client] : "", maxlength);
}
