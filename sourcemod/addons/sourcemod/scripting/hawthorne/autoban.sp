// implement
void DuplicateCheck_OnClientAuthorized(client) {
    char url[512], ip[24];

    GetClientIP(client, ip, sizeof(ip));
    Format(url, sizeof(url), "users?banned=true&ip=%s", ip);

    httpClient.Get(url, DuplicateCheck_OnClientAPI, client)
}

void DuplicateCheck_OnClientAPI(HTTPResponse response, int value) {
    if (!APIValidator(response)) return;

    JSONObject output = view_as<JSONObject>(response.Data);
    JSONObject result = view_as<JSONObject>(output.Get("result"));

    if (result.Length == 0) return;

    selected_duration[client] = 0;
    selected_player[client] = GetClientOfUserId(client);
    selected_action[client] = ACTION_BAN;
    selected_reason[client] = "[HT] Ban Evasion Detected";

    PunishExecution(client);
}