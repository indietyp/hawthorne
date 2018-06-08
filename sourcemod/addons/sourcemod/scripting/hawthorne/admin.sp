// add custom tag & formatting
public void OnClientPostAdminFilter(int client) {
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
  role.GetString("name", ht_tag[client], sizeof(ht_tag[]));

  int immunity = role.GetInt("immunity");
  int timeleft = role.GetInt("timeleft");

  delete output;
  delete result;
  delete roles;
  delete role;

  AdminId admin;
  if (MODULE_ADMIN_MERGE.BoolValue) {
    SetUserFlagBits(client, GetUserFlagBits(client) | ReadFlagString(flags));
    admin = GetUserAdmin(client);
    if (admin != INVALID_ADMIN_ID) {
      admin.ImmunityLevel = immunity;
    }
  } else {
    admin = CreateAdmin();
    for (int i = 0; i < strlen(flags); i++) {
      AdminFlag flag;
      if (FindFlagByChar(flags[i], flag))
        admin.SetFlag(flag, true);
    }

    admin.ImmunityLevel = immunity;
    SetUserAdmin(client, admin, true);
  }

  if (MODULE_HEXTAGS.BoolValue && hextags) {
    char formatting[128];
    MODULE_HEXTAGS_FORMAT.GetString(formatting, sizeof(formatting));

    if (StrContains(formatting, "{R}"))
      ReplaceString(formatting, sizeof(formatting), "{R}", ht_tag[client]);

    if (StrContains(formatting, "{L}")) {
      for (int n = 0; n < strlen(endpoint); n++) {
        formatting[n] = CharToLower(formatting[n]);
      }
      ReplaceString(formatting, sizeof(formatting), "{L}", ht_tag[client]);
    }

    if (StrContains(formatting, "{U}")) {
      for (int n = 0; n < strlen(endpoint); n++) {
        formatting[n] = CharToUpper(formatting[n]);
      }
      ReplaceString(formatting, sizeof(formatting), "{U}", ht_tag[client]);
    }

    strcopy(ht_tag[client], sizeof(ht_tag[]), formatting);
    HexTags_SetClientTag(client, ScoreTag, ht_tag[client]);
    HexTags_SetClientTag(client, ChatTag, ht_tag[client]);
  }

  if (admin_timer[client] != null) return;
  admin_timeleft[client] = timeleft;

  if (timeleft == 0) return;
  admin_timer[client] = CreateTimer(60.0, AdminVerificationTimer, GetClientUserId(client), TIMER_REPEAT);
}

public Action AdminVerificationTimer(Handle timer, any userid) {
  int client = GetClientOfUserId(userid);
  if (!client)
    return Plugin_Stop;

  admin_timeleft[client] -= 60;
  if (admin_timeleft[client] <= 0) {
    AdminCheck(client);

    admin_timer[client].Close();
    admin_timer[client] = null;
    CPrintToChat(client, "%s Hey! Your role just got updated!", PREFIX);

    return Plugin_Stop;
  }
  return Plugin_Continue;
}

void Admins_OnClientDisconnect(int client) {
  admin_timer[client].Close();
  admin_timer[client] = null;
  ht_tag[client] = "";
}

public void HexTags_OnTagsUpdated(int client) {
  HexTags_SetClientTag(client, ScoreTag, ht_tag[client]);
  HexTags_SetClientTag(client, ChatTag, ht_tag[client]);
}
