#define PREFIX          "\x3 \x4[Bellwether] \x1"
#define PREFIX_BAD      "\x3 \x7[Bellwether] \x1"
#define TYPE_MUTE       0
#define TYPE_GAG        1
#define TYPE_SILENCE    2
#define TYPE_UNMUTE     3
#define TYPE_UNGAG      4
#define TYPE_UNSILENCE  5

#define MAX_REASONS   8
char cMuteGagName[][] =  {"mute", "gag", "silence", "unmute", "ungag", "unsilence"};


HTTPClient httpClient;

char server[37] = "",
     clients[MAXPLAYERS + 1][37],
     last_target[MAXPLAYERS + 1][37];

int iLastMuteGagTime[MAXPLAYERS + 1],
    iLastCommandType[MAXPLAYERS + 1],
    iClientOnlineID[MAXPLAYERS + 1],
    iMuteGagTimeleft[MAXPLAYERS + 1][3],
    iAdminUpdateTimeleft[MAXPLAYERS + 1];

Handle hMuteGagTimer[MAXPLAYERS + 1],
       forward_client,
       hAdminTimer[MAXPLAYERS + 1];

ConVar manager_ip,
       manager_port,
       manager_protocol,
       api_token,
       bans_enabled,
       admins_enabled,
       mutegags_enabled,
       logs_enabled,
       mutegags_global,
       bans_global;

char endpoint[512];

char cServerHostName[100],
     cMuteReasonsFile[PLATFORM_MAX_PATH],
     cGagReasonsFile[PLATFORM_MAX_PATH],
     cSilenceReasonsFile[PLATFORM_MAX_PATH],
     cPunishmentTimeFile[PLATFORM_MAX_PATH],
     cMuteGagReason[MAXPLAYERS + 1][3][150],
     cLastCmd[MAXPLAYERS + 1][50];

char g_MuteReasons[500],
     g_GagReasons[500],
     g_SilenceReasons[500],
     g_PunishmentTimes[500];

bool b_WaitingChatMessage[MAXPLAYERS + 1],
     bShowMuteGagOnce[MAXPLAYERS + 1],
     bMuteGagPermanent[MAXPLAYERS + 1][3];

ArrayList g_ConnectionTime;
