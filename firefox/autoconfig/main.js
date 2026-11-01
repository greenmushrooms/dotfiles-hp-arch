// Loaded by mozilla.cfg with full chrome privileges. Edit freely — no root
// needed, but Firefox must be restarted to pick up changes.

const HOME_URL = "file:///home/slava/dotfiles/firefox/home/index.html";
const DEBUG_LOG = "/tmp/ff-navbar-debug.log";
const DEBUG = false;

function debug(label, data) {
  if (!DEBUG) {
    return;
  }
  try {
    // IOUtils is not exposed in the autoconfig sandbox, so append the old way.
    let file = Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile);
    file.initWithPath(DEBUG_LOG);
    let stream = Cc[
      "@mozilla.org/network/file-output-stream;1"
    ].createInstance(Ci.nsIFileOutputStream);
    // PR_WRONLY | PR_CREATE_FILE | PR_APPEND
    stream.init(file, 0x02 | 0x08 | 0x10, 0o644, 0);
    let converter = Cc[
      "@mozilla.org/intl/converter-output-stream;1"
    ].createInstance(Ci.nsIConverterOutputStream);
    converter.init(stream, "UTF-8");
    converter.writeString(
      `${new Date().toISOString()} ${label} ${JSON.stringify(data)}\n`
    );
    converter.close();
  } catch (e) {
    Cu.reportError(e);
  }
}

function rect(el) {
  if (!el) {
    return null;
  }
  let r = el.getBoundingClientRect();
  return { top: r.top, height: r.height, width: r.width };
}

debug("main.js loaded", {});

let { BrowserWindowTracker } = ChromeUtils.importESModule(
  "resource:///modules/BrowserWindowTracker.sys.mjs"
);

// New tab page
ChromeUtils.importESModule("resource:///modules/AboutNewTab.sys.mjs")
  .AboutNewTab.newTabURL = HOME_URL;

// Focus page content, not the address bar. Deferred by a tick so it lands after
// Firefox's own startup focus handling (BrowserInit._setInitialFocus).
let focusContent = () => {
  let win = BrowserWindowTracker.getTopWindow();
  if (!win || !win.gBrowser) {
    return;
  }
  win.setTimeout(() => {
    if (win.gURLBar) {
      win.gURLBar.blur();
    }
    win.gBrowser.selectedBrowser.focus();
  }, 0);
};

Services.obs.addObserver(focusContent, "browser-open-newtab-start");
Services.obs.addObserver(focusContent, "sessionstore-windows-restored");

// userChrome.css hides #nav-bar unless <html> carries navbar-visible. A
// display:none element cannot be focused, so the bar has to be revealed before
// Firefox acts on Ctrl+L / F6. Both keys route through the Browser:OpenLocation
// command, and a capturing listener on the document runs before that command's
// own handler.
Services.obs.addObserver(win => {
  let doc = win.document;
  let root = doc.documentElement;
  let navBar = doc.getElementById("nav-bar");

  let hideNavBar = () => root.removeAttribute("navbar-visible");

  // The urlbar is a popover positioned via style.top, measured with
  // getBoxQuads({ flush: false }). Revealing the toolbar in the same tick that
  // Firefox focuses the bar leaves that measurement stale, so the bar draws
  // over the tab strip. Re-apply the correct offset once layout has settled.
  let repositionUrlbar = () => {
    let urlbar = doc.getElementById("urlbar");
    if (!urlbar || !urlbar.parentNode) {
      return;
    }
    let want = urlbar.parentNode.getBoundingClientRect().top;
    debug("before", {
      styleTop: urlbar.style.top,
      want,
      urlbar: rect(urlbar),
      container: rect(urlbar.parentNode),
      navBar: rect(navBar),
      toolbox: rect(doc.getElementById("navigator-toolbox")),
      tabs: rect(doc.getElementById("TabsToolbar")),
      attrs: {
        breakout: urlbar.hasAttribute("breakout"),
        breakoutExtend: urlbar.hasAttribute("breakout-extend"),
        popoverOpen: urlbar.matches(":popover-open"),
      },
    });

    // Ask Firefox to redo its own breakout measurement now that the toolbar is
    // laid out. Blocking then unblocking runs #stopBreakout followed by
    // #updateLayoutBreakout, which is exactly the "the toolbar moved" path.
    try {
      win.gURLBar.incrementBreakoutBlockerCount();
      win.gURLBar.decrementBreakoutBlockerCount();
    } catch (e) {
      Cu.reportError(e);
    }

    win.setTimeout(() => {
      debug("after", {
        styleTop: urlbar.style.top,
        urlbar: rect(urlbar),
        container: rect(urlbar.parentNode),
      });
    }, 60);
  };

  doc.addEventListener(
    "command",
    event => {
      if (event.target.id !== "Browser:OpenLocation") {
        return;
      }
      root.setAttribute("navbar-visible", "true");
      // Force a synchronous reflow so the toolbar has real geometry before
      // Firefox measures it.
      navBar.getBoundingClientRect();
      debug("openLocation", { navBar: rect(navBar) });
      win.requestAnimationFrame(() =>
        win.requestAnimationFrame(repositionUrlbar)
      );
      win.setTimeout(repositionUrlbar, 120);
    },
    true
  );

  let input = win.gURLBar && win.gURLBar.inputField;
  if (input) {
    input.addEventListener("blur", hideNavBar);
    input.addEventListener("keydown", event => {
      if (event.key === "Escape") {
        hideNavBar();
        win.gBrowser.selectedBrowser.focus();
      }
    });
  }
}, "browser-delayed-startup-finished");
