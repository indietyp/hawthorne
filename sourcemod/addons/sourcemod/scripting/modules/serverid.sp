//void ServerID_OnMapStart() {
//  LogMessage(iServerID);
//  if(StrEqual(iServerID, ""))
//    GetServerID();
//  LogMessage(iServerID);
//}

void GetServerID() {
  LogMessage("Triggered GetServerID()");
  // Check if the server id is already exists
  if(!StrEqual(iServerID, ""))
    return;

  //Get IP and port from server
  char serverIP[20];
  int port;

  Handle hostIP   = FindConVar("hostip");
  Handle hostPort = FindConVar("hostport");
  if (hostIP == INVALID_HANDLE || hostPort == INVALID_HANDLE) {
    LogError("Failed to get serverIP or port, please set convar for serverIP");
    return;
  }
  int IP = GetConVarInt(hostIP);
  port = GetConVarInt(hostPort);
  Format(serverIP, sizeof(serverIP), "%d.%d.%d.%d", IP >>> 24 & 255, IP >>> 16 & 255, IP >>> 8 & 255, IP & 255);

  char url[512] = "servers?ip=";
  char sport[6];

  LogMessage("ServerID");
  IntToString(port, sport, sizeof(sport));
  StrCat(url, sizeof(url), serverIP);
  StrCat(url, sizeof(url), "&port=");
  StrCat(url, sizeof(url), sport);
  httpClient.Get(url, OnGetServerID);
}

public void OnGetServerID(HTTPResponse response, any value) {
  LogMessage("ServerID");
  if (response.Status != HTTPStatus_OK) {
    LogError("[bellwether] API ERROR (request failed)");
    return;
  }

  if (response.Data == null) {
    LogError("[bellwether] API ERROR (no response data)");
    return;
  }

  JSONObject output = view_as<JSONObject>(response.Data);
  int success = output.GetBool("success");

  if (success == false) {
    LogError("[bellwether] API ERROR (api call failed)");
    return;

  } else {
    JSONArray results = view_as<JSONArray>(output.Get("result"));

    if (results.Length == 0) {
      LogError("[bellwether] Failed to find server IP and PORT in database!");
      return;
    }

    JSONObject result = view_as<JSONObject>(results.Get(0));
    result.GetString("id", iServerID, sizeof(iServerID));

    delete result;
    delete results;
  }
}
