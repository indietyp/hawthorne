#define PREFIX          "\x3 \x4[hawthorne] \x1"
#define PREFIX_BAD      "\x3 \x7[hawthorne] \x1"

#define ACTION_UNSILENCE  -3
#define ACTION_UNGAG      -2
#define ACTION_UNMUTE     -1
#define ACTION_MUTE        1
#define ACTION_GAG         2
#define ACTION_SILENCE     3

#define CONFLICT_OVERWRITE 1
#define CONFLICT_EXTEND    2
#define CONFLICT_CONVERT   3
#define CONFLICT_ABORT     4

#define MAX_REASONS   8
char cMuteGagName[][] =  {"mute", "gag", "silence", "unmute", "ungag", "unsilence"};


HTTPClient httpClient;

char SERVER[37] = "",
     CLIENTS[MAXPLAYERS + 1][37],
     last_target[MAXPLAYERS + 1][37];

int iLastMuteGagTime[MAXPLAYERS + 1],
    iLastCommandType[MAXPLAYERS + 1],
    iMuteGagTimeleft[MAXPLAYERS + 1][3],
    admin_timeleft[MAXPLAYERS + 1];

int punish_selected_action[MAXPLAYERS + 1],
    punish_selected_player[MAXPLAYERS + 1],
    punish_selected_conflict[MAXPLAYERS + 1],
    punish_selected_duration[MAXPLAYERS + 1];

char punish_selected_reason[MAXPLAYERS + 1][128];

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

char SERVER_HOSTNAME[512],
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

//ArrayList g_ConnectionTime;
