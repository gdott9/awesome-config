-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local tyrannical = require("tyrannical")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget

local util = require("util")
local config = {}
config_loaded = pcall(function() config = require("config") end)

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
debug_mode = debug_mode or false
wifi = wifi or false
network = network or false
sound = sound or "alsa"
channel = channel or "Master"

mytheme = mytheme or "dark"
-- Themes define colours, icons, font and wallpapers.
local mythemepath = awful.util.get_configuration_dir() .. "themes/" .. mytheme .. "/theme.lua"
beautiful.init(mythemepath)

-- This is used later as the default terminal and editor to run.
terminal = terminal or "xterm"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    --awful.layout.suit.spiral,
    --awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    --awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}

-- {{{ Loading of additionnal libraries
-- Widgets library
local iniquitous = {}
iniquitous_loaded = pcall(function() iniquitous = require("iniquitous") end)
if not iniquitous_loaded then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, Iniquitous is not available!",
                     text = "Install Iniquitous library to use more widgets." })
    io.stderr:write("needs iniquitous for more advanced widgets\n")
end
local vicious = {}
vicious_loaded = pcall(function() vicious = require("vicious") end)
if not vicious_loaded then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, Vicious is not available!",
                     text = "Install Vicious library to use more widgets." })
    io.stderr:write("needs vicious for more advanced widgets\n")
end
-- }}}

-- {{{ Tyrannical Tags
tyrannical.settings.default_layout = awful.layout.suit.fair
tyrannical.settings.mwfact = 0.66

tyrannical.tags = {
    {
        name        = "ア",
        init        = true,
        exclusive   = false,
        screen      = {1,2},
        layout      = awful.layout.suit.fair,
        selected    = true,
    },
    {
        name        = "イ",
        init        = true,
        exclusive   = true,
        screen      = {1,2},
        layout      = awful.layout.suit.max,
        no_focus_stealing_in = true,
        class = {"Navigator", "Firefox", "Iceweasel", "Chromium"},
        exec_once   = {"firefox -P default"}
    },
    {
        name = "ウ",
        init        = true,
        exclusive   = false,
        screen      = {1,2},
        layout      = awful.layout.suit.fair,
    },
    {
        name = "エ",
        init        = true,
        exclusive   = false,
        screen      = {1,2},
        layout      = awful.layout.suit.fair,
    },
    {
        name = "オ",
        init = true,
        exclusive = true,
        screen = screen.count()>1 and 2 or 1,
        layout = awful.layout.suit.max,
        no_focus_stealing_in = true,
        class = {"Mail", "Thunderbird", "Icedove"},
        exec_once   = {"thunderbird"},
    },
}

-- Ignore the tag "exclusive" property for the following clients (matched by classes)
tyrannical.properties.intrusive = {
  "gcolor2", "Xephyr", "feh",
}

-- Ignore the tiled layout for the matching clients
tyrannical.properties.floating = {
  "mpv", "Xephyr", "feh", "gcolor2",
}

-- Make the matching clients (by classes) on top of the default layout
tyrannical.properties.ontop = {
    "Xephyr",
}

-- Force the matching clients (by classes) to be centered on the screen on init
tyrannical.properties.centered = {
}

tyrannical.properties.size_hints_honor = { xterm = false, URxvt = false }
tyrannical.settings.group_children = true
-- }}}

-- {{{ Wibar

-- Reusable separators
local spacer    = wibox.widget.textbox(" ")
local separator = wibox.widget.textbox("     ")

-- Create a textclock widget
mytextclock = wibox.widget.textclock(" %a %b %d, %H:%M:%S ", 1)

-- Create a wibox for each screen and add it
local taglist_buttons = awful.util.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewprev(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewnext(t.screen) end)
                )

local tasklist_buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(-1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(1)
                                          end))

-- MPD widget
if iniquitous_loaded then
end

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
--screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    --set_wallpaper(s)

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end)))

    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s, height = 15 })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
            s.mylayoutbox,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        mytextclock,
    }
end)

-- {{{ Bottom Wibox
do
    local mybottomwibox = awful.wibar({ position = "bottom", screen = 1, height = 14 })

    local w_kernel_img = wibox.widget.imagebox(beautiful.widget_pacman)
    local w_kernel_tb = wibox.widget.textbox(io.popen("uname -r"):read())

    local left = {
        layout = wibox.layout.fixed.horizontal,
        w_kernel_img,
        spacer,
        w_kernel_tb,
    }
    local right = {
        layout = wibox.layout.fixed.horizontal,
    }

    if vicious_loaded then
        -- CPU widget
        local w_cpu_img = wibox.widget.imagebox(beautiful.widget_cpu)
        local w_cpu_g = wibox.widget {
          widget = wibox.widget.graph,
          forced_width = 50,
          color = beautiful.fg_widget,
          background_color = beautiful.fg_off_widget,
          border_color = beautiful.border_color,
        }

        vicious.register(w_cpu_g, vicious.widgets.cpu, "$1", 3)
        table.insert(left, separator)
        table.insert(left, w_cpu_img)
        table.insert(left, spacer)
        table.insert(left, w_cpu_g)

        -- Memory usage
        local w_mem_img = wibox.widget.imagebox(beautiful.widget_mem)
        local w_mem_tb = wibox.widget.textbox()

        vicious.register(w_mem_tb, vicious.widgets.mem, "$1%", 13)
        table.insert(left, separator)
        table.insert(left, w_mem_img)
        table.insert(left, spacer)
        table.insert(left, w_mem_tb)
        -- }}}

        -- File system usage
        local w_fs_img = wibox.widget.imagebox(beautiful.widget_fs)
        w_fs_tb = {
            r = wibox.widget.textbox(),
            h = wibox.widget.textbox()
        }

        vicious.register(w_fs_tb.r, vicious.widgets.fs, "${/ used_p}%", 599)
        vicious.register(w_fs_tb.h, vicious.widgets.fs, "${/home used_p}%", 599)

        table.insert(left, separator)
        table.insert(left, w_fs_img)
        table.insert(left, spacer)
        table.insert(left, w_fs_tb.r)
        table.insert(left, spacer)
        table.insert(left, w_fs_tb.h)

        if network then
            -- Wifi Infos
            if wifi then
                w_wifi_img = wibox.widget.imagebox(beautiful.widget_wifi)

                w_wifi_tb = wibox.widget.textbox()
                vicious.register(w_wifi_tb, vicious.widgets.wifi, '${link}% [${ssid}]', 23, network)
                table.insert(left, separator)
                table.insert(left, w_wifi_img)
                table.insert(left, spacer)
                table.insert(left, w_wifi_tb)
            end
            -- Network usage
            w_netdown_img = wibox.widget.imagebox(beautiful.widget_down)
            w_netup_img = wibox.widget.imagebox(beautiful.widget_up)

            w_net_tb = wibox.widget.textbox()
            vicious.register(w_net_tb, vicious.widgets.net, '${'..network..' down_kb}  ${'..network..' up_kb}', 5)

            table.insert(left, separator)
            table.insert(left, w_netdown_img)
            table.insert(left, spacer)
            table.insert(left, w_net_tb)
            table.insert(left, spacer)
            table.insert(left, w_netup_img)
            -- }}}
        end
    end

    if iniquitous_loaded then
        -- MPD widget
        local w_music_img = wibox.widget.imagebox(beautiful.widget_music)
        local w_music_tb = iniquitous.mpc.init()

        table.insert(right, w_music_img)
        table.insert(right, spacer)
        table.insert(right, w_music_tb)

        -- Volume widget
        iniquitous.volume.init(sound, channel)
        local w_vol_tb = iniquitous.volume.textbox()
        local w_vol_img = iniquitous.volume.imagebox()

        table.insert(right, separator)
        table.insert(right, w_vol_img)
        table.insert(right, spacer)
        table.insert(right, w_vol_tb)
    end

    table.insert(right, separator)
    table.insert(right, mytextclock)

    mybottomwibox:setup {
        layout = wibox.layout.align.horizontal,
        left,
        nil,
        right,
    }
end
-- }}}

-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Shift" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"}),

    awful.key({ modkey }, "a", util.add_tag),
    awful.key({ modkey, "Control" }, "r", util.rename_tag),
    awful.key({ modkey }, "d", util.delete_tag),

    awful.key({modkey, "Shift"}, "Return", util.term_in_current_tag),
    awful.key({modkey, "Control"}, "Return", util.new_tag_with_term)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "s",      function (c) c.sticky = not c.sticky  end),
    awful.key({ modkey, "Control" }, "m",
        function (c) c.minimized = true end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "maximize", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

globalkeys = awful.util.table.join(
    globalkeys,

    awful.key({ modkey,           }, "i", function () awful.util.spawn("slock") end),

    awful.key({ }, "XF86AudioPlay", function () io.popen("mpc toggle") end),
    awful.key({ }, "XF86AudioPrev", function () io.popen("mpc prev") end),
    awful.key({ }, "XF86AudioNext", function () io.popen("mpc next") end),

    awful.key({ }, "XF86AudioMute", function () iniquitous.volume.volume("mute") end),
    awful.key({ }, "XF86AudioLowerVolume", function () iniquitous.volume.volume("down") end),
    awful.key({ }, "XF86AudioRaiseVolume", function () iniquitous.volume.volume("up") end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = awful.util.table.join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
