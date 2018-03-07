void GetServerUUID() {
  if (!StrEqual(server, "")) return;

  Handle host_ip = FindConVar("hostip");
  Handle host_port = FindConVar("hostport");

  if (host_ip == INVALID_HANDLE || host_port == INVALID_HANDLE) {
    LogError("[hawthorne] Failed to get the ip or port of the server, please fix the convars hostip and hostport");
    return;
  }

  char ip[20];
  int raw_ip = GetConVarInt(host_ip);
  Format(ip, sizeof(ip), "%d.%d.%d.%d", raw_ip >>> 24 & 255, raw_ip >>> 16 & 255, raw_ip >>> 8 & 255, raw_ip & 255);

  char port[6];
  int raw_port = GetConVarInt(host_port);
  IntToString(raw_port, port, sizeof(port));

  char url[512] = "servers?ip=";
  StrCat(url, sizeof(url), ip);
  StrCat(url, sizeof(url), "&port=");
  StrCat(url, sizeof(url), port);
  httpClient.Get(url, APIGetServerUUID);
}

public void APIGetServerUUID(HTTPResponse response, any value) {
  JSONObject proceed = APIValidator(response);

  if (!proceed.GetBool("success")) return;
  JSONObject output = view_as<JSONObject>(response.Data);
  JSONArray data = view_as<JSONArray>(output.Get("result"));

  if (data.Length == 0) {
    LogError("[hawthorne] Failed to find the server. It seems not to exist. Please check the webpage.");
    return;
  }

  JSONObject result = view_as<JSONObject>(data.Get(0));
  result.GetString("id", server, sizeof(server));

  delete data;
  delete result;
}
