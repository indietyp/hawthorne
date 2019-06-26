// add custom tag & formatting
public void AdminOnClientAuthorized(int client) {
  if (!MODULE_ADMIN.BoolValue || IsFakeClient(client)) return;

  ApplyCachedAdminRole(client);
}

//public void OnClientPostAdminFilter(int client) {
//	AdminCheck(client);
//}

public void OnRebuildAdminCache(AdminCachePart part) {
  OnClientReloadAdmins(0, 0);
}

public Action OnClientReloadAdmins(int client, int args) {
  for (int i = 1; i < MaxClients; i++) {
    if (IsClientInGame(i)) ApplyCachedAdminRole(i);
  }

  return Plugin_Handled;
}

void ApplyCachedAdminRole(int client) {
	if (client < 1) return;
  int uuid = UUIDToInt(CLIENTS[client]);
  
  int duration, role[4], flags, immunity;
	int reference[3] = {0, 0, 0};
	bool found = false;

  for (int i = 0; i < ADMINS.Length; i++) {
    ADMINS.GetArray(i, reference, sizeof(reference));

    LogMessage("[ADMIN SEARCH] %i: %i", reference[0], uuid);
    if (reference[0] == uuid) {
    	found = true;
      break;
    }
  }

  if (!found)
    return;
  
  duration = reference[1];
  ROLES.GetArray(reference[2], role, sizeof(role));
  flags = role[2];
  immunity = role[3];
  

  ROLE_NAMES.GetString(role[1], ht_tag[client], sizeof(ht_tag[]));
  LogMessage("%s: %i %i %i", ht_tag[client], role[2], role[3], role[0]);
  
  AdminId admin;
  if (MODULE_ADMIN_MERGE.BoolValue) {
    SetUserFlagBits(client, GetUserFlagBits(client) | flags);
    admin = GetUserAdmin(client);
    if (admin != INVALID_ADMIN_ID) {
      admin.ImmunityLevel = immunity;
    }

  } else {
    admin = CreateAdmin();
    admin.ImmunityLevel = immunity;
    SetUserAdmin(client, admin, true);
    SetUserFlagBits(client, flags);
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
  admin_timeleft[client] = duration;

  if (duration == 0) return;
  admin_timer[client] = CreateTimer(60.0, AdminVerificationTimer, GetClientUserId(client), TIMER_REPEAT);

  LogMessage("Done Chief!");
  // NotifyPostAdminCheck(client);
}

public Action AdminVerificationTimer(Handle timer, any userid) {
  int client = GetClientOfUserId(userid);
  if (!client)
    return Plugin_Stop;

  admin_timeleft[client] -= 60;
  if (admin_timeleft[client] <= 0) {
    ApplyCachedAdminRole(client);

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

  // TODO:
  // superuser role

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
}

void AdminPopulateCacheRoles(HTTPResponse response, any value) {
  JSONObject output = view_as<JSONObject>(response.Data);
  JSONObject result = view_as<JSONObject>(output.Get("result"));
  JSONArray members = view_as<JSONArray>(result.Get("members"));
  JSONArray roles = value;
  char role[40];

  roles.GetString(0, role, sizeof(role));
  roles.Remove(0);

  char flags[62], name[512];
  result.GetString("flags", flags, sizeof(flags));
  result.GetString("name", name, sizeof(name));
  
  for (int i = 0; i < strlen(flags); i++) {
  	flags[i] = CharToLower(flags[i]);
 }
  
  int flagbits = ReadFlagString(flags);
  int immunity = result.GetInt("immunity");
  int uuid = UUIDToInt(role);
  int nameid = ROLE_NAMES.Length;
  
  LogMessage("%s: %s %i %i %i", name, flags, flagbits, immunity, nameid);

  int encoded[4];
  encoded[0] = uuid;
  encoded[1] = nameid;
  encoded[2] = flagbits;
  encoded[3] = immunity;

  ROLE_NAMES.PushString(name);
  ROLES.PushArray(encoded, sizeof(encoded));

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

    if (!present)
      ADMINS_CLEAR.PushString(tmp);
  }

  if (roles.Length == 0) {
    char url[512], admin[40];
    ADMINS_CLEAR.GetString(0, admin, sizeof(admin));
    
    Format(url, sizeof(url), "users/%s?server=%s", admin, SERVER);
    httpClient.Get(url, AdminPopulateCacheAdmins);

    delete roles;
    return;
  }

  char url[512], target[40];
  roles.GetString(0, target, sizeof(target));
  Format(url, sizeof(url), "roles/%s", target);

  httpClient.Get(url, AdminPopulateCacheRoles, roles);

  delete result;
  delete output;
  delete members;
}

void AdminPopulateCacheAdmins(HTTPResponse response, any value) {
	if (!APIValidator(response)) return;
	
  JSONObject output = view_as<JSONObject>(response.Data);
  JSONObject result = view_as<JSONObject>(output.Get("result"));
  JSONArray admin_roles = view_as<JSONArray>(result.Get("roles"));

  char id[40], roleraw[40];
  result.GetString("id", id, sizeof(id));
  
  JSONObject role = view_as<JSONObject>(admin_roles.Get(0));
  role.GetString("id", roleraw, sizeof(roleraw));
  int timeleft = role.GetInt("timeleft");
  int uuid = UUIDToInt(id);
  int roleuuid = UUIDToInt(roleraw);
  int roleid;

  for (int i = 0; i < ROLES.Length; i++) {
    int comparison[4];
    ROLES.GetArray(i, comparison, sizeof(comparison));
    
    if (roleuuid == comparison[0]) {
      roleid = i;
      break;
    }
  }

  int encoded[3];
  encoded[0] = uuid;
  encoded[1] = timeleft;
  encoded[2] = roleid;
  ADMINS.PushArray(encoded);

  ADMINS_CLEAR.Erase(0);
  if (ADMINS_CLEAR.Length == 0) {
    OnClientReloadAdmins(0, 0);
    return;
  }
  // when done apply on all users

  char url[512], admin[40];
  ADMINS_CLEAR.GetString(0, admin, sizeof(admin));
  Format(url, sizeof(url), "users/%s?server=%s", admin, SERVER);
  
  httpClient.Get(url, AdminPopulateCacheAdmins);

  delete output;
  delete result;
  delete role;
  delete admin_roles;
}
