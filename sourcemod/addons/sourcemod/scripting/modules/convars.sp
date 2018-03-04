void BW_InitConVars() {
  manager_ip        = CreateConVar("bw_server_ip",            "127.0.0.1",  "Panel server domain or IP");
  manager_port      = CreateConVar("bw_server_port",          "80",         "Panel server accessed port");
  api_token         = CreateConVar("bw_server_token",         "",           "Panel server issued authentication token - REQUIRED");
  manager_protocol  = CreateConVar("bw_server_protocol",      "1",          "Panel server HTTPS usage - highly recommended be enabled", 0, true, 0.0, true, 1.0);
  bans_enabled      = CreateConVar("bw_bans_enabled",         "1",          "Toggle the internal ban module", 0, true, 0.0, true, 1.0);
  admins_enabled    = CreateConVar("bw_admins_enabled",       "1",          "Toggle the internal admin module", 0, true, 0.0, true, 1.0);
  mutegags_enabled  = CreateConVar("bw_mutegag_enabled",      "1",          "Toggle the internal mute and gag module", 0, true, 0.0, true, 1.0);
  logs_enabled      = CreateConVar("bw_chatlog_enabled",      "1",          "Toggle the internal chatlog module", 0, true, 0.0, true, 1.0);
  mutegags_global   = CreateConVar("bw_mutegag_all_servers",  "0",          "Toggle of serverwide mute & gags", 0, true, 0.0, true, 1.0);
  bans_global       = CreateConVar("bw_bans_all_servers",     "0",          "Toggle of serverwide bans", 0, true, 0.0, true, 1.0);

  AutoExecConfig(true, "Bellwether");
}
