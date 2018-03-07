#if defined _bellwether_included
 #endinput
#endif
#define _bellwether_included

/**
* Returns current server ID from API
*
* @return char				server ID
*/
native void Bellwether_GetServerID(char[] buffer, int maxlength);

/**
* Returns clients ID from API
*
* @return char				clients ID
*/
native void Bellwether_GetClientID(char[] buffer, int maxlength, int client);


/**
* Called when clientID is received
*
*/
forward void Bellwether_OnClientIDReceived(int client, int clientID);


public void __pl_bellwether__SetNTVOptional() {
	MarkNativeAsOptional("Bellwether_GetServerID");
	MarkNativeAsOptional("Bellwether_GetClientID");
}
