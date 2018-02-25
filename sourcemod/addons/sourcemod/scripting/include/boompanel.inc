#if defined _boompanel_included
 #endinput
#endif
#define _boompanel_included

/**
* Returns current server ID from API
*
* @return char				server ID
*/
native void BoomPanel_GetServerID(char[] buffer, int maxlength);

/**
* Returns clients ID from API
*
* @return char				clients ID
*/
native void BoomPanel_GetClientID(char[] buffer, int maxlength, int client);


/**
* Called when clientID is received
*
*/
forward void BoomPanel_OnClientIDReceived(int client, int clientID);


public void __pl_boompanel__SetNTVOptional() {
	MarkNativeAsOptional("BoomPanel_GetServerID");
	MarkNativeAsOptional("BoomPanel_GetClientID");
}
