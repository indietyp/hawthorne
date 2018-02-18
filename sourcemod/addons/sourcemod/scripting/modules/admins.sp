// TODO: TESTING
void Admins_OnClientIDReceived(int client) {
	if(g_cvAdminsEnabled.IntValue == 1 && iServerID != '') {
		//JSONObject payload = new JSONObject();
		//payload.SetInt("server", iServerID);

		httpClient.GET("/users/" + iClientID[client] + "?server=" + iServerID, payload, GetClientAdmin);
		//delete payload;
	}
}

public void GetClientAdmin(HTTPResponse response, any value) {
	if(response.status != 200 && response.status != 403) {
		LogError("[BOOMPANEL] API ERROR (no response data)");
		return;
	}

	if(response.status == 403)
		return;

	JSONObject output = view_as<JSONObject>(response.Data);
	int success = output.GetInt("success");

	if (success == 0) {
		LogError("[BOOMPANEL] API ERROR (api call failed)");
		return;
		} else {
			JSONObject result = view_as<JSONObject>(output.Get("result"));
    	int immunity = result.getInt("immunity");
    	int usetime = result.getInt("usetime") / 60;   // API outputs seconds, but we need minutes!

			char flags[25];
    	flags = result.getString("flags");

			AdminId admin = CreateAdmin();
			SetAdminImmunityLevel(admin, immunity);
			for(int i = 0; i < strlen(flags); i++) {
				AdminFlag flag;
				if(FindFlagByChar(flags[i], flag))
					if(!admin.HasFlag(flag, Access_Effective))
						admin.SetFlag(flag, true);
			}
			SetUserAdmin(client, admin, true);

			// Next admin update time
			iAdminUpdateTimeleft[client] = timeleft;

			if(hAdminTimer[client] == null)
				hAdminTimer[client] = CreateTimer(60.0, TakeAwayMinute2, GetClientUserId(client), TIMER_REPEAT);
		}

}

public Action TakeAwayMinute2(Handle tmr, any userID) {
	int client = GetClientOfUserId(userID);
	if(client > 0) {
		iAdminUpdateTimeleft[client] -= 1;
		if(iAdminUpdateTimeleft[client] == 0)
		{
			//Reload admin flags
			Admins_OnClientIDReceived(client);
			if(hAdminTimer[client] != null)
				hAdminTimer[client] = null;
			PrintToChat(client, "%sYour admin/vip group just got updated!", PREFIX);
		}
	}
}

void Admins_OnClientDisconnect(int client) {
	if(hAdminTimer[client] != null)
		hAdminTimer[client] = null;
}
