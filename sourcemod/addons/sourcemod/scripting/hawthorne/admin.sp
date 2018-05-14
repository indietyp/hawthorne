public Action OnClientPreAdminCheck(int client) {
  if (!MODULE_ADMIN_MERGE.BoolValue && AdminCheck(client)) {
    NotifyPostAdminCheck(client);
    return Plugin_Handled;
  } else
    return Plugin_Continue;
}

public void OnClientPostAdminFilter(int client) {
  if (!MODULE_ADMIN_MERGE.BoolValue) return;

  AdminCheck(client);
}

public Action OnClientReloadAdmins(int client, int args) {
  for (int i = 1; i < MaxClients; i++) {
    AdminCheck(i);
  }

  return Plugin_Handled;
}

bool AdminCheck(int client) {
  if (!MODULE_ADMIN.BoolValue || IsFakeClient(client) || StrEqual(SERVER, "")) return false;

  char url[512] = "users/";
  StrCat(url, sizeof(url), CLIENTS[client]);
  StrCat(url, sizeof(url), "?server=");
  StrCat(url, sizeof(url), SERVER);

  httpClient.Get(url, APIAdminCheck, client);
  return true;
}

void APIAdminCheck(HTTPResponse response, any value) {
  int client = value;

  if (!APIValidator(response)) return;

  JSONObject output = view_as<JSONObject>(response.Data);
  JSONObject result = view_as<JSONObject>(output.Get("result"));
  JSONArray roles = view_as<JSONArray>(result.Get("roles"));

  if (roles.Length < 1) return;

  char flags[25];

  JSONObject role = view_as<JSONObject>(roles.Get(0));
  role.GetString("flags", flags, sizeof(flags));

  int immunity = role.GetInt("immunity");
  int timeleft = role.GetInt("timeleft");
  if (timeleft == 0) timeleft = 604800;

  delete output;
  delete result;
  delete roles;
  delete role;

  if (MODULE_ADMIN_MERGE.BoolValue) {
    SetUserFlagBits(client, GetUserFlagBits(client) | ReadFlagString(flags));
  } else {
    AdminId admin = CreateAdmin();
    for (int i = 0; i < strlen(flags); i++) {
      AdminFlag flag;
      if (FindFlagByChar(flags[i], flag))
        admin.SetFlag(flag, true);
    }

    admin.ImmunityLevel = immunity;
    SetUserAdmin(client, admin, true);
  }

  if(admin_timer[client] != null) return;
  admin_timeleft[client] = timeleft;
  admin_timer[client] = CreateTimer(60.0, AdminVerificationTimer, client, TIMER_REPEAT);
}

public Action AdminVerificationTimer(Handle timer, int client) {
  if (client < 1) return Plugin_Stop;

  admin_timeleft[client] -= 60;
  if (admin_timeleft[client] <= 0) {
    OnClientPreAdminCheck(client);

    CloseHandle(admin_timer[client]);
    admin_timer[client] = null;
    PrintToChat(client, "[HT] Hey! Your role just got updated!");

    return Plugin_Stop;
  }
  return Plugin_Continue;
}

void Admins_OnClientDisconnect(int client) {
  // reset the timer
  CloseHandle(admin_timer[client]);
  admin_timer[client] = null;
}
