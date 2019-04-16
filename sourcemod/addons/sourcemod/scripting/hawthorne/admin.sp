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
      for (int n = 0; n < strlen(ht_tag[client]); n++) {
        ht_tag[client][n] = CharToLower(ht_tag[client][n]);
      }
      ReplaceString(formatting, sizeof(formatting), "{L}", ht_tag[client]);
    }

    if (StrContains(formatting, "{U}")) {
      for (int n = 0; n < strlen(ht_tag[client]); n++) {
        ht_tag[client][n] = CharToUpper(ht_tag[client][n]);
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

  NotifyPostAdminCheck(client);
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
    CPrintToChat(client, "Hey! Your role just got updated!");

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


// get all admins from cache (timeleft, roleid, userid [int])
// get all roles from cache (name, immunity, roleid [int])

void AdminPopulateCache() {
  if (!MODULE_ADMIN.BoolValue || StrEqual(SERVER, "")) return;
  // get roles from /servers/
  // save information
  // get members from /roles/ (unique set)
  // query timeleft of members
  // add superuser role

  char url[512];
  Format(url, sizeof(url), "servers/%s", SERVER);

  ROLES.Clear();
  ADMINS.Clear();
  ROLE_NAMES.Clear();

  // superuser role
  // get from api?

  httpClient.Get(url, AdminPopulateCacheDetailed);
}

void AdminPopulateCacheDetailed(HTTPResponse response, any value) {
  if (!APIValidator(response)) return;

  JSONObject output = view_as<JSONObject>(response.Data);
  JSONObject result = view_as<JSONObject>(output.Get("result"));
  JSONArray roles = view_as<JSONArray>(result.Get("roles"));

  char url[512], role[40];
  roles.GetString(0, role, sizeof(role));
  Format(url, sizeof(url), "roles/%s", role);

  httpClient.Get(url, AdminPopulateCacheRoles, roles);

  delete output;
  delete result;
  delete roles;
}

void AdminPopulateCacheRoles(HTTPResponse response, any value) {
  JSONObject output = view_as<JSONObject>(response.Data);
  JSONObject result = view_as<JSONObject>(output.Get("result"));
  JSONArray members = view_as<JSONArray>(result.Get("members"));
  JSONArray roles = value;
  char role[40];

  roles.GetString(0, role, sizeof(role));
  roles.Remove(0);

  char flags[20], name[512];
  result.GetString("flags", flags, sizeof(flags));
  result.GetString("name", name, sizeof(name));
  int flagbits = ReadFlagString(flags);
  int immunity = result.GetInt("immunity");
  int uuid = UUIDToInt(role);
  int nameid = ROLE_NAMES.Length;

  int encoded = uuid;
  encoded = encoded << 16;
  encoded = encoded + nameid;
  encoded = encoded << 32;
  encoded = encoded + flagbits;
  encoded = encoded << 8;
  encoded = encoded + immunity;

  ROLE_NAMES.PushString(name);
  ROLES.Push(encoded);

  for (int i = 0; i < members.Length; i++) {
    char tmp[40];
    members.GetString(i, tmp, sizeof(tmp));

    bool present = false;
    char tmp2[40];
    for (int i; i < ADMINS_CLEAR.Length; i++) {
      ADMINS_CLEAR.GetString(i, tmp2, sizeof(tmp2));

      if (StrEqual(tmp, tmp2)) {
        present = true;
        break;
      }
    }

    if (!present) {
      ADMINS_CLEAR.PushString(tmp);
    }
  }

  if (roles.Length == 0) {
    char url[512], admin[40];
    ADMINS_CLEAR.GetString(0, admin, sizeof(admin));
    Format(url, sizeof(url), "users/%s?server=", admin, SERVER);

    httpClient.Get(url, AdminPopulateCacheAdmins);

    return;
  }

  char url[512], target[40];
  roles.GetString(0, target, sizeof(target));
  Format(url, sizeof(url), "roles/%s", target);

  httpClient.Get(url, AdminPopulateCacheRoles, roles);

  delete roles;
  delete result;
  delete output;
  delete members;
}

void AdminPopulateCacheAdmins(HTTPResponse response, any value) {
  JSONObject output = view_as<JSONObject>(response.Data);
  JSONObject result = view_as<JSONObject>(output.Get("result"));
  JSONArray roles = view_as<JSONArray>(result.Get("roles"));
  JSONObject role = view_as<JSONObject>(roles.Get(0));

  char id[40], roleraw[40];
  result.GetString("id", id, sizeof(id));
  role.GetString("id", roleraw, sizeof(roleraw));
  int timeleft = role.GetInt("timeleft");
  int uuid = UUIDToInt(id);
  int roleuuid = UUIDToInt(roleraw);
  int roleid;

  for (int i = 0; i < ROLES.Length; i++) {
    int comparison = ROLES.Get(i) >> 56;
    if (roleuuid == comparison) {
      roleid = i;
      break;
    }
  }

  int encoded = uuid;
  encoded = encoded << 64;
  encoded = encoded + timeleft;
  encoded = encoded << 16;
  encoded = encoded + roleid;
  ADMINS.Push(encoded);

  ADMINS_CLEAR.Erase(0);
  if (ADMINS_CLEAR.Length == 0) return;
  // when done apply on all users

  char url[512], admin[40];
  ADMINS_CLEAR.GetString(0, admin, sizeof(admin));
  Format(url, sizeof(url), "users/%s?server=", admin, SERVER);

  httpClient.Get(url, AdminPopulateCacheAdmins);

  delete output;
  delete result;
  delete role;
  delete roles;
}
