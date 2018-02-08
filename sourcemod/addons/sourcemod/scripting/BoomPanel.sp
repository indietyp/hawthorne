#pragma semicolon 1
#define DEBUG
#pragma newdecls required

#include <sourcemod>
#include <geoip>
#include <basecomm>
#include <sdktools>
#include <ripext>


#include "modules/globals.sp"
#include "modules/functions.sp"
#include "modules/convars.sp"
#include "modules/serverid.sp"
#include "modules/players.sp"
#include "modules/chat.sp"
#include "modules/bans.sp"
#include "modules/admins.sp"
#include "modules/mutegag.sp"
#include "modules/rcon.sp"
#include "modules/natives.sp"

#pragma newdecls required

//DB DEFINITIONS
/*
	pid = player ID
	sid = server ID
	aid = admin ID
*/

//Credits
//asherkin - help admin commands logging
//Credits to `11530` https://forums.alliedmods.net/showthread.php?t=183443


public Plugin myinfo = {
	name = "BoomPanel",
	author = "indietyp & boomix",
	description = "BoomPanel Admin Panel",
	version = "2.00",
	url = "http://steamcommunity.com/id/boomix69/"
};


public void OnPluginStart() {
	//Database.Connect(SQLConnect, "BoomPanel");

	// Events
	HookEvent("player_disconnect", 	Event_Disconnect, EventHookMode_Pre);
	HookEvent("player_team",		Event_PlayerTeam);

	// Listeners
	AddCommandListener(OnPlayerChatMessage, 		"say");
	AddCommandListener(OnPlayerChatMessage, 		"say_team");
	AddCommandListener(OnAddBanCommand, 				"sm_addban");

	AddCommandListener(OnPlayerMuteGag, 				"sm_mute");
	AddCommandListener(OnPlayerMuteGag, 				"sm_unmute");
	AddCommandListener(OnPlayerMuteGag, 				"sm_gag");
	AddCommandListener(OnPlayerMuteGag, 				"sm_ungag");
	AddCommandListener(OnPlayerMuteGag, 				"sm_silence");
	AddCommandListener(OnPlayerMuteGag,					"sm_unsilence");

	// Shortcuts
	RegAdminCmd("sm_pmute", 		CMD_PermaMuteGag, 	ADMFLAG_CHAT);
	RegAdminCmd("sm_pgag", 			CMD_PermaMuteGag, 	ADMFLAG_CHAT);
	RegAdminCmd("sm_psilence", 	CMD_PermaMuteGag, 	ADMFLAG_CHAT);

	//RegConsoleCmd("sm_online", CMD_Online);

	BP_OnPluginStart();
}

bool IsSpectator(int client) {
	if(GetClientTeam(client) == 2 || GetClientTeam(client) == 3)
		return false;
	else
		return true;
}

// SQL GOT REPLACED WITH AN REST API APPROACH
//void Main_OnMapStart() {
//	if(DB == null) {

//		if (SQL_CheckConfig("BoomPanel"))
//			Database.Connect(SQLConnect, "BoomPanel");
//		else
//			Database.Connect(SQLConnect, "default");

//	}
//}

//***************
//--------------
//DATABASE CONNECT
//--------------
//***************

//public void SQLConnect(Database db, const char[] error, any data) {
//	if (db == null)
//	{
//		delete db;
//		LogError("Database failure: %s", error);
//		return;
//	}

//	else
//	{
//		DB = db;
//		DB.Query(OnRowInserted, "SET NAMES \"UTF8\"");
//		DB.SetCharset("utf8");
//		OnDBConnected();
//	}
//}

//public void OnRowInserted(Database db, DBResultSet results, const char[] error, any data) {
//	if(results == null)
//	{
//		LogError("[BOOMPANEL] MYSQL ERROR: %s", error);
//		return;
//	}
//}
