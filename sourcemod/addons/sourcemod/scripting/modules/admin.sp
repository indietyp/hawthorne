// TODO: TESTING
public Action OnClientPreAdminCheck(int client) {
  if (!MODULE_ADMIN.BoolValue) return Plugin_Continue;

  if (!StrEqual(SERVER, "")) {
    char url[512] = "users/";
    StrCat(url, sizeof(url), CLIENTS[client]);
    StrCat(url, sizeof(url), "?server=");
    StrCat(url, sizeof(url), SERVER);

    httpClient.Get(url, APIAdminCheck, client);

    NotifyPostAdminCheck(client);
    return Plugin_Handled;
  }

  return Plugin_Continue;
}

public void APIAdminCheck(HTTPResponse response, any value) {
  int client = value;
  if (!APIValidator(response)) return;

  JSONObject output = view_as<JSONObject>(response.Data);
  JSONObject result = view_as<JSONObject>(output.Get("result"));

  char flags[25];
  result.GetString("flags", flags, sizeof(flags));

  int immunity = result.GetInt("immunity");
  int timeleft = result.GetInt("timeleft");
  if (timeleft == -1) timeleft = 604800;

  AdminId admin = CreateAdmin();
  for (int i = 0; i < strlen(flags); i++) {
    AdminFlag flag;
    if (FindFlagByChar(flags[i], flag) && !admin.HasFlag(flag, Access_Effective))
      admin.SetFlag(flag, true);
  }
  SetAdminImmunityLevel(admin, immunity);
  SetUserAdmin(client, admin, true);

  // update the admin after 60 seconds
  if(admin_timer[client] != null) return;

  admin_timeleft[client] = timeleft;
  admin_timer[client] = CreateTimer(60.0, AdminVerificationTimer, client, TIMER_REPEAT);
}

public Action AdminVerificationTimer(Handle tmr, int client) {
  if (client < 1) return Plugin_Continue;

  admin_timeleft[client] -= 60;
  if (admin_timeleft[client] <= 0) {
    OnClientPreAdminCheck(client);

    admin_timer[client] = null;
    PrintToChat(client, "%sHey! Your role just got updated!", PREFIX);

    return Plugin_Handled;
  }
  return Plugin_Continue;
}

void Admins_OnClientDisconnect(int client) {
  // reset the timer
  admin_timer[client] = null;
}
