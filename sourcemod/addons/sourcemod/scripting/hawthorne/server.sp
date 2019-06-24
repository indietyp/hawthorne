void GetServerUUID() {
	char domain[] = "https://api.ipify.org";
	
	HTTPClient ipify = new HTTPClient(domain);
	
	ipify.Get("/?format=json", GetServerPublicIP);
}

void GetServerPublicIP(HTTPResponse response, any value) {
  if (!StrEqual(SERVER, "")) return;

  JSONObject data = view_as<JSONObject>(response.Data);
  Handle host_port = FindConVar("hostport");

  if (host_port == INVALID_HANDLE) {
    LogError("[HT] Failed to get the ip or port of the server, please fix the convars hostip and hostport");
    return;
  }

  char ip[32], url[512];
  int port = GetConVarInt(host_port);
  
  data.GetString("ip", ip, sizeof(ip));
  Format(url, sizeof(url), "servers?ip=%s&port=%i", ip, port);
  
  httpClient.Get(url, APIGetServerUUID);
  delete data;
}

void APIGetServerUUID(HTTPResponse response, any value) {
  if (!APIValidator(response)) return;
  
  JSONObject output = view_as<JSONObject>(response.Data);
  JSONArray results = view_as<JSONArray>(output.Get("result"));

  if (results.Length == 0) {
    LogError("[HT] Failed to find the server. It seems not to exist. Please check the webpage.");
    return;
  }

  JSONObject result = view_as<JSONObject>(results.Get(0));
  result.GetString("id", SERVER, sizeof(SERVER));
  
  AdminPopulateCache();

  delete output;
  delete result;
  delete results;
}
