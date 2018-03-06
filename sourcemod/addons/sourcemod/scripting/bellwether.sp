#pragma semicolon 1
#define DEBUG
#pragma newdecls required

#include <sourcemod>
#include <geoip>
#include <basecomm>
#include <sdktools>
#include <ripext>


#include "modules/globals.sp"
#include "modules/convars.sp"
#include "modules/server.sp"
#include "modules/players.sp"
#include "modules/chat.sp"
#include "modules/bans.sp"
#include "modules/admins.sp"
#include "modules/mutegag.sp"
#include "modules/rcon.sp"
#include "modules/natives.sp"
#include "modules/functions.sp"

#pragma newdecls required

//Credits
// asherkin - help admin commands logging
// Credits to `11530` https://forums.alliedmods.net/showthread.php?t=183443
// Credits to boomix and the boompanel - this is an adaptation


public Plugin myinfo = {
  name = "Bellwether",
  author = "indietyp & boomix",
  description = "Bellwether Admin Panel",
  version = "2.00",
  url = "bellwether.com"
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

  //RegConsoleCmd("sm_online", CMD_Online);

  BW_OnPluginStart();
}

public void OnConfigsExecuted() {
  char protocol[6], ip[12], port[6], token[37];
  if (GetConVarInt(manager_protocol) == 1) {
    protocol = "https";
  } else {
    protocol = "http";
  }

  GetConVarString(manager_ip, ip, sizeof(ip));
  GetConVarString(manager_port, port, sizeof(port));
  GetConVarString(api_token, token, sizeof(token));

  endpoint = protocol;
  StrCat(endpoint, sizeof(endpoint), "://");
  StrCat(endpoint, sizeof(endpoint), ip);
  StrCat(endpoint, sizeof(endpoint), ":");
  StrCat(endpoint, sizeof(endpoint), port);
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
    LogError("[Bellwether] API ERROR (request did not return 200 OK)");
    return false;
  }

  if (response.Data == null) {
    LogError("[Bellwether] API ERROR (no response data received)");
    return false;
  }

  JSONObject data = view_as<JSONObject>(response.Data);
  if (data.GetBool("success") == false) {
    LogError("[Bellwether] API ERROR (api call failed)");
    return false;
  }

  delete data;
  return true;
}
