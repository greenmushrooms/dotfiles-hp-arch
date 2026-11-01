user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.bookmarks.addedImportButton", true);
user_pref("browser.startup.page", 1);
user_pref("browser.startup.homepage", "file:///home/slava/dotfiles/firefox/home/index.html");

// Firefox 153 stopped granting extensions file:// access via <all_urls>; it now
// requires a per-extension "internal:fileSchemeAllowed" opt-in. That broke
// Tridactyl on the file:// start page. Setting this to false restores the
// pre-153 behaviour for all extensions.
// Narrower alternative if Mozilla ever drops this pref: about:addons ->
// Tridactyl -> Permissions -> enable file access (that toggle only appears
// while this pref is true).
user_pref("extensions.webextensions.fileSchemeAccess.requireOptIn", false);

// The Firefox 153 startup profile selector cannot be turned off from here.
// browser.profiles.enabled is ignored once a profile group exists (the profile
// carries a StoreID, and SelectableProfileService forces itself on in that
// case), and the selector window is launched from the ShowSelector flag in
// profiles.ini before any profile pref is read. Untick "Show this when Firefox
// opens" on the selector window itself, or run setup.sh with Firefox closed.
