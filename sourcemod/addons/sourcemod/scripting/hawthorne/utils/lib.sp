public int HexToInt(const char[] hex) {
  int result, character;
  int length = strlen(hex);
  int exponent = length - 1;

  for (int i = 0; i < length; i++) {
    character = hex[i];
    character -= 48;
    
    if (character > 9)
      character -= 7;

    result += (character * RoundFloat(Pow(16.0, float(exponent))));
    exponent--;
  }

  return result;
}

public int UUIDToInt(const char[] uuid) {
  char hex[64];
  strcopy(hex, sizeof(hex), uuid);
  TrimString(hex);
  ReplaceString(hex, sizeof(hex), "-", "");

  for (int i = 0; i < strlen(hex); i++) {
    hex[i] = CharToUpper(hex[i]);
  }

  return HexToInt(hex);
}
