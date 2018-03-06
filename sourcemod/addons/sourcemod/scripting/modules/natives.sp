void CreateNatives() {
  CreateNative("Bellwether_GetServerUUID",  Native_GetServerUUID);
  CreateNative("Bellwether_GetClientID",  Native_GetClientID);

  forward_client = CreateGlobalForward("Bellwether_OnClientIDReceived", ET_Ignore, Param_Cell, Param_Cell);
}

public int Native_GetServerUUID(Handle plugin, int numParams) {
  int maxlength = GetNativeCell(2);

  SetNativeString(1, server, maxlength);
}

public int Native_GetClientID(Handle plugin, int numParams) {
  int client = GetNativeCell(3);
  int maxlength = GetNativeCell(2);

  SetNativeString(1, (!IsFakeClient(client)) ? bw_clients[client] : "", maxlength);
}
