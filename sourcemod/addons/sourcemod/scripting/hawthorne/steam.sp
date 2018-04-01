stock bool ConvertSteamID32ToSteamID64(char[] AuthID, char[] FriendID, int size) {
  if(strlen(AuthID) < 11 || AuthID[0]!='S' || AuthID[6]=='I')
  {
    FriendID[0] = 0;
    return false;
  }

  int iUpper = 765611979;
  int iFriendID = StringToInt(AuthID[10])*2 + 60265728 + AuthID[8]-48;

  int iDiv = iFriendID/100000000;
  int iIdx = 9-(iDiv?iDiv/10+1:0);
  iUpper += iDiv;

  IntToString(iFriendID, FriendID[iIdx], size-iIdx);
  iIdx = FriendID[9];
  IntToString(iUpper, FriendID, size);
  FriendID[9] = iIdx;

  return true;
}
