void BP_InitConVars() {
	// Create tons of cvars
	g_cvServerIP				= CreateConVar("bp_server_ip", 						"127.0.0.1", 	"Panel server domain or IP");
	g_cvServerPORT			= CreateConVar("bp_server_port", 					"80", 				"Panel server accessed port");
	g_cvServerTOKEN			= CreateConVar("bp_server_token", 				"", 					"Panel server issued authentication token - REQUIRED");
	g_cvServerPROTOCOL	= CreateConVar("bp_server_protocol", 			"1", 					"Panel server HTTPS usage - highly recommended be enabled", 0, true, 0.0, true, 1.0);
	g_cvBansEnabled 		= CreateConVar("bp_bans_enabled", 				"1", 					"Toggle the internal ban module", 0, true, 0.0, true, 1.0);
	g_cvAdminsEnabled 	= CreateConVar("bp_admins_enabled", 			"1", 					"Toggle the internal admin module", 0, true, 0.0, true, 1.0);
	g_cvMuteGagEnabled 	= CreateConVar("bp_mutegag_enabled",			"1", 					"Toggle the internal mute and gag module", 0, true, 0.0, true, 1.0);
	g_cvChatLogEnabled 	= CreateConVar("bp_chatlog_enabled", 			"1", 					"Toggle the internal chatlog module", 0, true, 0.0, true, 1.0);
	g_cvMuteGagAllSrvs	= CreateConVar("bp_mutegag_all_servers", 	"0", 					"Toggle of serverwide mute & gags", 0, true, 0.0, true, 1.0);
	g_cvBansAllSrvs			= CreateConVar("bp_bans_all_servers", 		"0", 					"Toggle of serverwide bans", 0, true, 0.0, true, 1.0);


	AutoExecConfig(true, "Bellwether");
}
