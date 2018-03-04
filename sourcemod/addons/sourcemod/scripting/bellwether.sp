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
#include "modules/serverid.sp"
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
  HookEvent("player_team",    Event_PlayerTeam);

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
  if (GetConVarInt(g_cvServerPROTOCOL) == 1) {
    protocol = "https";
  } else {
    protocol = "http";
  }

  GetConVarString(g_cvServerIP, ip, sizeof(ip));
  GetConVarString(g_cvServerPORT, port, sizeof(port));
  GetConVarString(g_cvServerTOKEN, token, sizeof(token));

  g_endpoint = protocol;
  StrCat(g_endpoint, sizeof(g_endpoint), "://");
  StrCat(g_endpoint, sizeof(g_endpoint), ip);
  StrCat(g_endpoint, sizeof(g_endpoint), ":");
  StrCat(g_endpoint, sizeof(g_endpoint), port);
  StrCat(g_endpoint, sizeof(g_endpoint), "/api/v1");

  LogMessage("Configured Endpoint:");
  LogMessage(g_endpoint);

  httpClient = new HTTPClient(g_endpoint);
  httpClient.SetHeader("X-TOKEN", token);

  GetServerID();
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
