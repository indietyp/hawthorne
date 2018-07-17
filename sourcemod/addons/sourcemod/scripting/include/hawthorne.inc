#if defined _hawthorne_included
 #endinput
#endif
#define _hawthorne_included

/**
* Returns current server ID from API
*
* @return char				server ID
*/
native void Hawthorne_GetServerID(char[] buffer, int maxlength);

/**
* Returns clients ID from API
*
* @return char				clients ID
*/
native void Hawthorne_GetClientID(char[] buffer, int maxlength, int client);


/**
* Called when clientID is received
*
*/
forward void Hawthorne_OnClientIDReceived(int client, int clientID);


public void __pl_Hawthorne__SetNTVOptional() {
	MarkNativeAsOptional("Hawthorne_GetServerID");
	MarkNativeAsOptional("Hawthorne_GetClientID");
}
