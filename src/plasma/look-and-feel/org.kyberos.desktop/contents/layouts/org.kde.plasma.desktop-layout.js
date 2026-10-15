// KyberOS layout: a thin 'bridge status strip' on top and a floating dock below.

// ---- top status strip ----
var strip = new Panel;
strip.location = "top";
strip.height = Math.round(gridUnit * 1.9);
strip.hiding = "none";

var kickoff = strip.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "start-here-kyberos");

strip.addWidget("org.kde.plasma.pager");
strip.addWidget("org.kde.plasma.panelspacer");

var clock = strip.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("autoFontAndSize", "false");
clock.writeConfig("fontFamily", "Michroma");
clock.writeConfig("fontSize", "10");
clock.writeConfig("use24hFormat", "2");
clock.writeConfig("showDate", "true");
clock.writeConfig("dateFormat", "isoDate");
clock.writeConfig("dateDisplayFormat", "BesideTime");
clock.writeConfig("showSeconds", "Always");

strip.addWidget("org.kde.plasma.panelspacer");

if (knownWidgetTypes.indexOf("org.kyberos.diagnostics") !== -1) {
    strip.addWidget("org.kyberos.diagnostics");
}
strip.addWidget("org.kde.plasma.systemtray");

// ---- floating dock ----
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.2);
dock.floating = true;
dock.lengthMode = "fit";
dock.alignment = "center";
dock.hiding = "dodgewindows";

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
// first installed browser wins; skip launchers whose app is missing
var browsers = ["org.mozilla.firefox.desktop", "firefox.desktop", "app.zen_browser.zen.desktop", "zen.desktop", "chromium-browser.desktop"];
var browser = browsers.filter(function (b) { return applicationExists(b); })[0];
var launchers = ["org.kde.dolphin.desktop", "org.kde.konsole.desktop", browser,
                 "systemsettings.desktop", "org.kde.discover.desktop"];
tasks.writeConfig("launchers", launchers.filter(function (l) { return l && applicationExists(l); })
    .map(function (l) { return "applications:" + l; }).join(","));
tasks.writeConfig("indicateAudioStreams", "true");

dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.trash");

// ---- wallpaper ----
var allDesktops = desktops();
for (var i = 0; i < allDesktops.length; i++) {
    var d = allDesktops[i];
    d.wallpaperPlugin = "org.kyberos.tactical";
    d.currentConfigGroup = ["Wallpaper", "org.kyberos.tactical", "General"];
    d.writeConfig("Crystal", "blue");
    d.writeConfig("Animate", "true");
}
