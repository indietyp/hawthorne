void GetServerUUID() {
  if (!StrEqual(SERVER, "")) return;

  Handle host_ip = FindConVar("hostip");
  Handle host_port = FindConVar("hostport");
  Handle net_public_address = FindConVar("net_public_adr");

  if (host_ip == INVALID_HANDLE || host_port == INVALID_HANDLE) {
    LogError("[hawthorne] Failed to get the ip or port of the server, please fix the convars hostip and hostport");
    return;
  }

  char public_ip[20];
  char ip[20];
  if (net_public_address != null) {
    GetConVarString(net_public_address, public_ip, sizeof(public_ip));
  }

  if (strlen(public_ip) == 0) {
    int raw_ip = GetConVarInt(host_ip);
    Format(ip, sizeof(ip), "%d.%d.%d.%d", raw_ip >>> 24 & 255, raw_ip >>> 16 & 255, raw_ip >>> 8 & 255, raw_ip & 255);
  }
  else {
    Format(ip, sizeof(ip), public_ip);
  }

  char port[6];
  int raw_port = GetConVarInt(host_port);
  IntToString(raw_port, port, sizeof(port));

  char url[512] = "servers?ip=";
  StrCat(url, sizeof(url), ip);
  StrCat(url, sizeof(url), "&port=");
  StrCat(url, sizeof(url), port);
  httpClient.Get(url, APIGetServerUUID);
}

void APIGetServerUUID(HTTPResponse response, any value) {
  if (!APIValidator(response)) return;

  JSONObject output = view_as<JSONObject>(response.Data);
  JSONArray data = view_as<JSONArray>(output.Get("result"));

  if (data.Length == 0) {
    LogError("[hawthorne] Failed to find the server. It seems not to exist. Please check the webpage.");
    return;
  }

  JSONObject result = view_as<JSONObject>(data.Get(0));
  result.GetString("id", SERVER, sizeof(SERVER));

  delete data;
  delete result;
}
