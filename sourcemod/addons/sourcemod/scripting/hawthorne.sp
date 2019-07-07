/*
Credits to ...
  ... asherkin - help admin commands logging
  ... `11530` https://forums.alliedmods.net/showthread.php?t=183443
  ... boomix and boompanel - this is an adaptation
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <string>
#include <sdktools>
#include <basecomm>
#include <ripext>
#include <regex>
#include <geoip>
#include <multicolors>
#include <advanced_motd>

#undef REQUIRE_PLUGIN
#include <hextags>
#include <smac>
#include <adminmenu>
#define REQUIRE_PLUGIN


#include "hawthorne/utils/globals.sp"
#include "hawthorne/utils/convars.sp"
#include "hawthorne/utils/lib.sp"
#include "hawthorne/server.sp"
#include "hawthorne/player.sp"
#include "hawthorne/chat.sp"
#include "hawthorne/ban.sp"
#include "hawthorne/admin.sp"
#include "hawthorne/punish.sp"
#include "hawthorne/rcon.sp"
#include "hawthorne/misc.sp"

#include "hawthorne/utils/natives.sp"
#include "hawthorne/utils/adminmenu.sp"
#include "hawthorne/utils/events.sp"
#include "hawthorne/utils/humanize.sp"
#include "hawthorne/utils/steam.sp"

#pragma newdecls required

public Plugin myinfo = {
  name = "hawthorne",
  author = "indietyp",
  description = "SourceMod Hawthorne integration.",
  version = "0.9.1-alpha.3",
  url = "hawthornepanel.org"
};


public void OnPluginStart() {
  HookEvent("player_disconnect",  Event_Disconnect, EventHookMode_Pre);

  AddCommandListener(OnPlayerChatMessage, "say");
  AddCommandListener(OnPlayerChatMessage, "say_team");


  RegConsoleCmd("sm_reloadadmins", OnClientReloadAdmins, "", ADMFLAG_CONFIG);
  RegAdminCmd("sm_status", StatusCommand, 0);

  AddCommandListener(PunishCommandExecuted, "sm_ban");

  AddCommandListener(PunishCommandExecuted, "sm_mute");
  AddCommandListener(PunishCommandExecuted, "sm_unmute");

  AddCommandListener(PunishCommandExecuted, "sm_gag");
  AddCommandListener(PunishCommandExecuted, "sm_ungag");

  CSetPrefix("%s ", PREFIX);

  TopMenu admin_menu;
  if (LibraryExists("adminmenu") && ((admin_menu = GetAdminTopMenu()) != null)) {
    OnAdminMenuReady(admin_menu);
  }

  ROLES = CreateArray(4);
  ADMINS = CreateArray(3);
  ROLE_NAMES = CreateArray(64);
  ADMINS_CLEAR = CreateArray(37);

  InitConVars();
  InitRcon();
  InitPunishments();
}

public void OnConfigsExecuted() {
  char token[37];
  GetConVarString(MANAGER, endpoint, sizeof(endpoint));

  if (StrContains(endpoint, "http", false) == -1)
    Format(endpoint, sizeof(endpoint), "http://%s", endpoint);

  int n = 0;
  while (endpoint[n] != '\0') {
    endpoint[n] = CharToLower(endpoint[n]);
    n++;
  }

  for (n = strlen(endpoint) - 1; n >= 0; n--) {
    if (endpoint[n] == '/') {
      endpoint[n] = '\0';
    } else {
      break;
    }
  }
  TrimString(endpoint);

  GetConVarString(APITOKEN, token, sizeof(token));
  StrCat(endpoint, sizeof(endpoint), "/api/v1");

  LogMessage("Endpoint: %s", endpoint);

  httpClient = new HTTPClient(endpoint);
  httpClient.SetHeader("X-TOKEN", token);
  httpClient.SetHeader("Transfer-Encoding", "identity");
  httpClient.FollowLocation = true;

  message_queue = new JSONArray();
  GetServerUUID();
}

bool IsSpectator(int client) {
  if (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)
    return false;
  else
    return true;
}

public void APINoResponseCall(HTTPResponse response, any value) {
  return;
}

bool APIValidator(HTTPResponse response) {
  if (response == INVALID_HANDLE) {
    LogError("[API] response handle invalid");
    return false;
  }

  JSONObject data = view_as<JSONObject>(response.Data);
  bool failed = false;
  char json[12288];

  if (response.Status != HTTPStatus_OK) {
    data.ToString(json, sizeof(json));
    failed = true;

    LogError("[API] request did not return 200 OK, but %d", response.Status);
    LogError("[API] call returned: %s", json);
  }

  if (response.Data == null) {
    failed = true;

    LogError("[API] no response data received");
  }

  if (data.GetBool("success") == false) {
    data.ToString(json, sizeof(json));
    failed = true;

    LogError("[API] call failed");
    LogError("[API] call returned: %s", json);
  }

  //delete data;
  return !failed;
}

Action CLINoActionCommand(int client, int args) {
  return Plugin_Continue;
}
