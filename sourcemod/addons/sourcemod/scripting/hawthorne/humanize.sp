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
