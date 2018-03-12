#define PREFIX          "\x3 \x4[hawthorne] \x1"
#define PREFIX_BAD      "\x3 \x7[hawthorne] \x1"

#define TYPE_MUTE       0
#define TYPE_GAG        1
#define TYPE_SILENCE    2
#define TYPE_UNMUTE     3
#define TYPE_UNGAG      4
#define TYPE_UNSILENCE  5

#define MAX_REASONS   8
char cMuteGagName[][] =  {"mute", "gag", "silence", "unmute", "ungag", "unsilence"};


HTTPClient httpClient;

char SERVER[37] = "",
     CLIENTS[MAXPLAYERS + 1][37],
     last_target[MAXPLAYERS + 1][37];

int iLastMuteGagTime[MAXPLAYERS + 1],
    iLastCommandType[MAXPLAYERS + 1],
    iClientOnlineID[MAXPLAYERS + 1],
    iMuteGagTimeleft[MAXPLAYERS + 1][3],
    admin_timeleft[MAXPLAYERS + 1];

Handle hMuteGagTimer[MAXPLAYERS + 1],
       forward_client,
       admin_timer[MAXPLAYERS + 1];

ConVar MANAGER,
       APITOKEN,
       MODULE_BAN,
       MODULE_ADMIN,
       MODULE_MUTEGAG,
       MODULE_LOG,
       MODULE_MUTEGAG_GLOBAL,
       MODULE_BAN_GLOBAL;

char endpoint[512];

char SERVER_HOSTNAME[100],
     GAG_REASONS[PLATFORM_MAX_PATH],
     MUTE_REASONS[PLATFORM_MAX_PATH],
     MUTEGAG_REASONS[MAXPLAYERS + 1][3][150],

     SILENCE_REASONS[PLATFORM_MAX_PATH],
     PUNISHMENT_TIMES[PLATFORM_MAX_PATH],
     LAST_COMMAND[MAXPLAYERS + 1][50];

char g_MuteReasons[500],
     g_GagReasons[500],
     g_SilenceReasons[500],
     g_PunishmentTimes[500];

bool b_WaitingChatMessage[MAXPLAYERS + 1],
     bShowMuteGagOnce[MAXPLAYERS + 1],
     bMuteGagPermanent[MAXPLAYERS + 1][3];

ArrayList g_ConnectionTime;
