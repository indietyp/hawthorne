public int HexToInt(const char[] hex) {
  int result, character;
  int length = strlen(hex);
  int exponent = length - 1;

  for (int i = 0; i < length; i++) {
    character = hex[i];
    LogMessage("%i", character);

    result = result + (character * Pow(16, exponent));
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
