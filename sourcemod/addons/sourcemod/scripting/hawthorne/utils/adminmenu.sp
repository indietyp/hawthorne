public void OnLibraryRemoved(const char[] name) {
  if (StrEqual(name, "adminmenu", false)) {
    ADMIN_MENU = null;
  }
}

public void CategoryHandler(TopMenu menu, TopMenuAction action, TopMenuObject id, int params, char[] buffer, int maxlength) {
  if (action == TopMenuAction_DisplayTitle) Format(buffer, maxlength, "Hawthorne:");
  else if (action == TopMenuAction_DisplayOption) Format(buffer, maxlength, "Hawthorne");
}

public void OnAdminMenuCreated(Handle menu) {
  if (menu == ADMIN_MENU && ADMIN_CATEGORY != INVALID_TOPMENUOBJECT) return;

  ADMIN_CATEGORY = AddToTopMenu(menu,
    "Hawthorne",
    TopMenuObject_Category,
    CategoryHandler,
    INVALID_TOPMENUOBJECT);
}

public void OnAdminMenuReady(Handle menu_handle) {
  TopMenu menu = TopMenu.FromHandle(menu_handle);

  if (ADMIN_CATEGORY == INVALID_TOPMENUOBJECT) OnAdminMenuCreated(menu);
  if (menu == ADMIN_MENU) return;

  ADMIN_MENU = menu;

  AddToTopMenu(ADMIN_MENU,
      "ht_ban",
      TopMenuObject_Item,
      AdminMenu_Action,
      ADMIN_CATEGORY,
      "sm_ban",
      ADMFLAG_BAN);

  AddToTopMenu(ADMIN_MENU,
      "ht_mute",
      TopMenuObject_Item,
      AdminMenu_Action,
      ADMIN_CATEGORY,
      "sm_mute",
      ADMFLAG_CHAT);

  AddToTopMenu(ADMIN_MENU,
      "ht_gag",
      TopMenuObject_Item,
      AdminMenu_Action,
      ADMIN_CATEGORY,
      "sm_gag",
      ADMFLAG_CHAT);

  AddToTopMenu(ADMIN_MENU,
      "ht_unban",
      TopMenuObject_Item,
      AdminMenu_Action,
      ADMIN_CATEGORY,
      "sm_unban",
      ADMFLAG_UNBAN);

  AddToTopMenu(ADMIN_MENU,
      "ht_unmute",
      TopMenuObject_Item,
      AdminMenu_Action,
      ADMIN_CATEGORY,
      "sm_unmute",
      ADMFLAG_CHAT);

  AddToTopMenu(ADMIN_MENU,
      "ht_ungag",
      TopMenuObject_Item,
      AdminMenu_Action,
      ADMIN_CATEGORY,
      "sm_ungag",
      ADMFLAG_CHAT);
}


public void AdminMenu_Action(TopMenu menu, TopMenuAction action, TopMenuObject id, int param, char[] buffer, int maxlength) {
  char command[128];
  GetTopMenuObjName(ADMIN_MENU, id, command, sizeof(command));

  if (action == TopMenuAction_DisplayOption) {
    char name[64];

    if (StrEqual(command, "ht_ban"))
      name = "Ban";
    else if (StrEqual(command, "ht_unban"))
      name = "Unban";
    else if (StrEqual(command, "ht_gag"))
      name = "Gag";
    else if (StrEqual(command, "ht_ungag"))
      name = "Ungag";
    else if (StrEqual(command, "ht_mute"))
      name = "Mute";
    else if (StrEqual(command, "ht_unmute"))
      name = "Unmute";

    Format(buffer, maxlength, "%s", name);
  }

  else if (action == TopMenuAction_SelectOption) {
    ReplaceString(command, sizeof(command), "ht_", "sm_");
    PunishCommandExecuted(0, command, 0);
  }
}
