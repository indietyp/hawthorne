public Action StatusCommand(int client, int args) {
  CPrintToChat(client, "-----------------------");

  if (!StrEqual(ht_tag[client], "")) {
    CPrintToChat(client, "Your current rank is %s", ht_tag[client]);

    char time[200];
    if (admin_timeleft[client] > 0) HumanizeTime(admin_timeleft[client], time);
    else time = "eternity";

    CPrintToChat(client, "This ranks lasts you for %s", time);
  }

  if (BaseComm_IsClientMuted(client) && BaseComm_IsClientGagged(client)) {
    char time[200];
    if (mutegag_timeleft[client] > 0) HumanizeTime(mutegag_timeleft[client], time);
    else time = "eternity";

    CPrintToChat(client, "You are {red}gagged{default} for %s", time);

  } else if (BaseComm_IsClientMuted(client)) {
    char time[200];
    if (mutegag_timeleft[client] > 0) HumanizeTime(mutegag_timeleft[client], time);
    else time = "eternity";

    CPrintToChat(client, "You are {red}muted{default} for %s", time);

  } else if (BaseComm_IsClientGagged(client)) {
    char time[200];
    if (mutegag_timeleft[client] > 0) HumanizeTime(mutegag_timeleft[client], time);
    else time = "eternity";

    CPrintToChat(client, "You are {red}gagged{default} for %s", time);

  }
  CPrintToChat(client, "-----------------------");

  return Plugin_Continue;
}

void TagCommand() {

}
