/*
Credits to ...
  ... asherkin - help admin commands logging
  ... `11530` https://forums.alliedmods.net/showthread.php?t=183443
  ... boomix and boompanel - this is an adaptation
*/

#pragma semicolon 1
#define DEBUG
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <basecomm>
#include <ripext>
#include <regex>
#include <geoip>


#include "hawthorne/globals.sp"
#include "hawthorne/convars.sp"
#include "hawthorne/server.sp"
#include "hawthorne/player.sp"
#include "hawthorne/chat.sp"
#include "hawthorne/ban.sp"
#include "hawthorne/admin.sp"
#include "hawthorne/mutegag.sp"
#include "hawthorne/rcon.sp"

#include "hawthorne/natives.sp"
#include "hawthorne/utils.sp"
#include "hawthorne/humanize.sp"
#include "hawthorne/steam.sp"

#pragma newdecls required

public Plugin myinfo = {
  name = "hawthorne",
  author = "indietyp",
  description = "Admin plugin for the integration into the hawthorne gameserver panel, for managing multiple servers from an web interface.",
  version = "4.00",
  url = "hawthorne.in"
};


public void OnPluginStart() {
  // Events
  HookEvent("player_disconnect",  Event_Disconnect, EventHookMode_Pre);
  HookEvent("player_team",        Event_PlayerTeam);

  // Listeners
  AddCommandListener(OnPlayerChatMessage,     "say");
  AddCommandListener(OnPlayerChatMessage,     "say_team");
  AddCommandListener(OnAddBanCommand,         "sm_addban");

  AddCommandListener(OnPlayerMuteGag,         "sm_mute");
  AddCommandListener(OnPlayerMuteGag,         "sm_unmute");
  AddCommandListener(OnPlayerMuteGag,         "sm_gag");
  AddCommandListener(OnPlayerMuteGag,         "sm_ungag");
  AddCommandListener(OnPlayerMuteGag,         "sm_silence");
  AddCommandListener(OnPlayerMuteGag,         "sm_unsilence");

  // Shortcuts
  RegAdminCmd("sm_pmute",     CMD_PermaMuteGag,   ADMFLAG_CHAT);
  RegAdminCmd("sm_pgag",      CMD_PermaMuteGag,   ADMFLAG_CHAT);
  RegAdminCmd("sm_psilence",  CMD_PermaMuteGag,   ADMFLAG_CHAT);

  Hawthorne_OnPluginStart();
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

  for (n = strlen(endpoint); n >= 0; n--) {
    if (endpoint[n] == '/') {
      endpoint[n] = ' ';
    } else {
      break;
    }
  }
  TrimString(endpoint);

  GetConVarString(APITOKEN, token, sizeof(token));
  StrCat(endpoint, sizeof(endpoint), "/api/v1");

  LogMessage("Configured Endpoint:");
  LogMessage(endpoint);

  httpClient = new HTTPClient(endpoint);
  httpClient.SetHeader("X-TOKEN", token);

  GetServerUUID();
}

bool IsSpectator(int client) {
  if(GetClientTeam(client) == 2 || GetClientTeam(client) == 3)
    return false;
  else
    return true;
}

public void APINoResponseCall(HTTPResponse response, any value) {
  return;
}

bool APIValidator(HTTPResponse response) {
  if (response.Status != HTTPStatus_OK) {
    LogError("[hawthorne] API ERROR (request did not return 200 OK)");
    return false;
  }

  if (response.Data == null) {
    LogError("[hawthorne] API ERROR (no response data received)");
    return false;
  }

  JSONObject data = view_as<JSONObject>(response.Data);
  if (data.GetBool("success") == false) {
    LogError("[hawthorne] API ERROR (api call failed)");
    return false;
  }

  return true;
}
