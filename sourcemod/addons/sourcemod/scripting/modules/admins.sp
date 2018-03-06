// TODO: TESTING
void Admins_OnClientIDReceived(int client) {
  if(admins_enabled.IntValue == 1 && !StrEqual(server, "")) {
    char url[512] = "users/";
    StrCat(url, sizeof(url), bw_clients[client]);
    StrCat(url, sizeof(url), "?server=");
    StrCat(url, sizeof(url), server);

    httpClient.Get(url, GetClientAdmin, client);
  }
}

public void GetClientAdmin(HTTPResponse response, any value) {
  int client = value;

  if(response.Status != 200 && response.Status != 403) {
    LogError("[bellwether] API ERROR (no response data)");
    return;
  }

  if(response.Status == 403)
    return;

  JSONObject output = view_as<JSONObject>(response.Data);
  int success = output.GetBool("success");

  if (success == false) {
    LogError("[bellwether] API ERROR (api call failed)");
    return;
  } else {
    JSONObject result = view_as<JSONObject>(output.Get("result"));
    int immunity = result.GetInt("immunity");
    int usetime = result.GetInt("usetime") / 60;   // API outputs seconds, but we need minutes!

    char flags[25];
    result.GetString("flags", flags, sizeof(flags));

    AdminId admin = CreateAdmin();
    SetAdminImmunityLevel(admin, immunity);
    for(int i = 0; i < strlen(flags); i++) {
      AdminFlag flag;
      if(FindFlagByChar(flags[i], flag))
        if(!admin.HasFlag(flag, Access_Effective))
          admin.SetFlag(flag, true);
    }
    SetUserAdmin(client, admin, true);

    // Next admin update time
    iAdminUpdateTimeleft[client] = usetime;

    if(hAdminTimer[client] == null)
      hAdminTimer[client] = CreateTimer(60.0, TakeAwayMinute2, GetClientUserId(client), TIMER_REPEAT);
  }
}

public Action TakeAwayMinute2(Handle tmr, any userID) {
  int client = GetClientOfUserId(userID);
  if(client > 0) {
    iAdminUpdateTimeleft[client] -= 1;
    if(iAdminUpdateTimeleft[client] == 0)
    {
      //Reload admin flags
      Admins_OnClientIDReceived(client);
      if(hAdminTimer[client] != null)
        hAdminTimer[client] = null;
      PrintToChat(client, "%sYour admin/vip group just got updated!", PREFIX);
    }
  }
}

void Admins_OnClientDisconnect(int client) {
  if(hAdminTimer[client] != null)
    hAdminTimer[client] = null;
}
