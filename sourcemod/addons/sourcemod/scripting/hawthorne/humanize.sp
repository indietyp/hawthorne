stock void HumanizeTime(int seconds, char time[200], bool short=true) {
  int days = (seconds / (3600*24));
  if (days > 0) {
    char s_days[20];
    IntToString(days, s_days, sizeof(s_days));
    StrCat(time, sizeof(time), s_days);
  }

  if(days == 1)
    StrCat(time, sizeof(time), " day ");
  else if (days > 0)
    StrCat(time, sizeof(time), " days ");

  if (short && days > 0)
    return;

  if (short)
    time = "";

  int hours = (seconds / 3600) % 24;
  if(hours > 0) {
    char s_hours[20];
    IntToString(hours, s_hours, sizeof(s_hours));
    StrCat(time, sizeof(time), s_hours);
  }

  if(hours == 1)
    StrCat(time, sizeof(time), " hour ");
  else if(hours > 0)
    StrCat(time, sizeof(time), " hours ");

  if (short && hours > 0)
    return;


  if (short)
    time = "";

  int minutes = (seconds / 60) % 60;
  if (minutes > 0) {
    char s_minutes[20];
    IntToString(minutes, s_minutes, sizeof(s_minutes));
    StrCat(time, sizeof(time), s_minutes);
  }

  if (minutes == 1)
    StrCat(time, sizeof(time), " minute ");
  else if (minutes > 0)
    StrCat(time, sizeof(time), " minutes ");

  if (short && minutes > 0)
    return;

}

stock int DehumanizeTime(char[] time, int size) {
  // If just casual date is entered
  if(StrContains(time, "d") == -1 && StrContains(time, "h") == -1 && StrContains(time, "m") == -1)
    return StringToInt(time);

  int idays, ihours, iminutes;
  char replacement[10], days[10], hours[10], minutes[10];
  if(StrContains(time, "d") != -1) {
    SplitString(time, "d", days, sizeof(days));
    idays = StringToInt(days) * 86400;
    Format(replacement, sizeof(replacement), "%id", StringToInt(days));
    ReplaceString(time, size, replacement, "", true);
  }

  if(StrContains(time, "h") != -1) {
    SplitString(time, "h", hours, sizeof(hours));
    ihours = StringToInt(hours) * 3600;
    Format(replacement, sizeof(replacement), "%id", StringToInt(hours));
    ReplaceString(time, size, replacement, "", true);

  }
  if(StrContains(time, "m") != -1) {
    SplitString(time, "m", minutes, sizeof(minutes));
    iminutes = (StringToInt(minutes)) * 60;
  }
  return RoundToFloor(idays + ihours + iminutes);
}
