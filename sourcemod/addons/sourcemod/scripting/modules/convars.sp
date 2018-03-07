void Hawthorne_InitConVars() {
  manager_ip        = CreateConVar("ht_server_ip",            "127.0.0.1",  "Panel server domain or IP");
  manager_port      = CreateConVar("ht_server_port",          "80",         "Panel server accessed port");
  api_token         = CreateConVar("ht_server_token",         "",           "Panel server issued authentication token - REQUIRED");
  manager_protocol  = CreateConVar("ht_server_protocol",      "1",          "Panel server HTTPS usage - highly recommended be enabled", 0, true, 0.0, true, 1.0);
  bans_enabled      = CreateConVar("ht_bans_enabled",         "1",          "Toggle the internal ban module", 0, true, 0.0, true, 1.0);
  admins_enabled    = CreateConVar("ht_admins_enabled",       "1",          "Toggle the internal admin module", 0, true, 0.0, true, 1.0);
  mutegags_enabled  = CreateConVar("ht_mutegag_enabled",      "1",          "Toggle the internal mute and gag module", 0, true, 0.0, true, 1.0);
  logs_enabled      = CreateConVar("ht_chatlog_enabled",      "1",          "Toggle the internal chatlog module", 0, true, 0.0, true, 1.0);
  mutegags_global   = CreateConVar("ht_mutegag_all_servers",  "0",          "Toggle of serverwide mute & gags", 0, true, 0.0, true, 1.0);
  bans_global       = CreateConVar("ht_bans_all_servers",     "0",          "Toggle of serverwide bans", 0, true, 0.0, true, 1.0);

  AutoExecConfig(true, "hawthorne");
}
