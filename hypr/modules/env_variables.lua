-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Toolkit Backend Variables --

-- GTK: Use Wayland if available; if not, try X11 and then any other GDK backend.
hl.env("GDK_BACKEND", "wayland,x11,*")
-- Qt: Use Wayland if available, fall back to X11 if not.
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

-- XDG Specifications --
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Qt Variables --
-- (From the Qt documentation) enables automatic scaling, based on the monitor’s pixel density
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
-- Tell Qt applications to use the Wayland backend, and fall back to X11 if Wayland is unavailable
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
-- Disables window decorations on Qt applications
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
-- Tells Qt based applications to pick your theme from qt5ct, use with Kvantum.
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
