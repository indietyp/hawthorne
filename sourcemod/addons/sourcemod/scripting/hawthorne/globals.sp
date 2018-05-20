#define PREFIX "[{green}HT{default}]"

#define ACTION_UNSILENCE  -3
#define ACTION_UNGAG      -2
#define ACTION_UNMUTE     -1
#define ACTION_MUTE        1
#define ACTION_GAG         2
#define ACTION_SILENCE     3

#define CONFLICT_NONE     -1
#define CONFLICT_OVERWRITE 1
#define CONFLICT_EXTEND    2
#define CONFLICT_CONVERT   3
#define CONFLICT_ABORT     4

#define MAX_REASONS   8


HTTPClient httpClient;

char SERVER[37] = "",
     CLIENTS[MAXPLAYERS + 1][37];

int mutegag_timeleft[MAXPLAYERS + 1],
    admin_timeleft[MAXPLAYERS + 1];

int punish_selected_action[MAXPLAYERS + 1],
    punish_selected_player[MAXPLAYERS + 1],
    punish_selected_conflict[MAXPLAYERS + 1],
    punish_selected_duration[MAXPLAYERS + 1];

char punish_selected_reason[MAXPLAYERS + 1][128];

Handle forward_client,
       admin_timer[MAXPLAYERS + 1],
       mutegag_timer[MAXPLAYERS + 1];

ConVar MANAGER,
       APITOKEN,
       MODULE_BAN,
       MODULE_ADMIN,
       MODULE_ADMIN_MERGE,
       MODULE_PUNISH,
       MODULE_LOG,
       MODULE_MUTEGAG_GLOBAL,
       MODULE_AUTOBAN,
       MODULE_BAN_GLOBAL,
       MODULE_HEXTAGS,
       MODULE_HEXTAGS_FORMAT;

char endpoint[512];

char SERVER_HOSTNAME[512],
     GAG_REASONS[PLATFORM_MAX_PATH],
     MUTE_REASONS[PLATFORM_MAX_PATH],

     SILENCE_REASONS[PLATFORM_MAX_PATH],
     PUNISHMENT_TIMES[PLATFORM_MAX_PATH];

bool hextags;

char ht_tag[MAXPLAYERS + 1][128];

bool MOTD_SEEN[MAXPLAYERS + 1] = false;
