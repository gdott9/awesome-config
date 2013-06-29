-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
local tyrannical = require("tyrannical")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

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
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
debug_mode = debug_mode or false
wifi = wifi or false
network = network or false
sound = sound or "alsa"
channel = channel or "pcm"

theme = theme or "dark"
-- Themes define colours, icons, and wallpapers
beautiful.init(os.getenv("HOME") .. "/.config/awesome/themes/"..theme.."/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = terminal or "xterm"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
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
    --awful.layout.suit.magnifier
}
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
tyrannical.tags = {
    {
        name        = "ア",
        init        = true,
        exclusive   = false,
        screen      = {1,2},
        layout      = awful.layout.suit.tile,
        selected    = true,
    },
    {
        name        = "イ",
        init        = true,
        exclusive   = true,
        screen      = {1,2},
        layout      = awful.layout.suit.max,
        class = {"Firefox", "Iceweasel", "Chromium"},
        exec_once   = {"firefox -P default"}
    },
    {
        name = "ウ",
        init        = true,
        exclusive   = false,
        screen      = {1,2},
        layout      = awful.layout.suit.tile,
    },
    {
        name = "エ",
        init        = true,
        exclusive   = false,
        screen      = {1,2},
        layout      = awful.layout.suit.tile,
    },
    {
        name = "オ",
        init = true,
        exclusive = true,
        screen = screen.count()>1 and 2 or 1,
        layout = awful.layout.suit.max,
        class = {"Thunderbird", "Icedove"},
        exec_once   = {"thunderbird"},
    },
}

-- Ignore the tag "exclusive" property for the following clients (matched by classes)
tyrannical.properties.intrusive = {
    "ksnapshot"     , "pinentry"       , "gtksu"     , "kcalc"        , "xcalc"               ,
    "feh"           , "Gradient editor", "About KDE" , "Paste Special", "Background color"    ,
    "kcolorchooser" , "plasmoidviewer" , "Xephyr"    , "kruler"       , "plasmaengineexplorer",
    "gcolor",
}

-- Ignore the tiled layout for the matching clients
tyrannical.properties.floating = {
    "MPlayer"      , "pinentry"        , "ksnapshot"  , "pinentry"     , "gtksu"          ,
    "xine"         , "feh"             , "kmix"       , "kcalc"        , "xcalc"          ,
    "yakuake"      , "Select Color$"   , "kruler"     , "kcolorchooser", "Paste Special"  ,
    "New Form"     , "Insert Picture"  , "kcharselect", "mythfrontend" , "plasmoidviewer" 
}

-- Make the matching clients (by classes) on top of the default layout
tyrannical.properties.ontop = {
    "Xephyr"       , "ksnapshot"       , "kruler"
}

-- Force the matching clients (by classes) to be centered on the screen on init
tyrannical.properties.centered = {
    "kcalc"
}

tyrannical.properties.size_hints_honor = { xterm = false, URxvt = false, aterm = false, sauer_client = false, mythfrontend  = false}
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox

-- {{{ Reusable separators
local spacer    = wibox.widget.textbox(" ")
local separator = wibox.widget.textbox("     ")
-- }}}

-- Create a textclock widget
mytextclock = awful.widget.textclock(" %a %b %d, %H:%M:%S ", 1)

-- Add a calendar on the textclock widget
local calendar = nil
local offset = 0

function remove_calendar()
    if calendar ~= nil then
        naughty.destroy(calendar)
        calendar = nil
        offset = 0
    end
end

function add_calendar(inc_offset)
    local save_offset = offset
    remove_calendar()
    offset = save_offset + inc_offset

    local datespec = os.date("*t")
    datespec = datespec.year * 12 + datespec.month - 1 + offset
    datespec = (datespec % 12 + 1) .. " " .. math.floor(datespec / 12)
    local cal = awful.util.pread("/usr/bin/cal -m " .. datespec .. " | cat")
    cal = string.gsub(cal, "^%s*(.-)%s*$", "%1")

    calendar = naughty.notify({
        text = string.format('<span font_desc="%s">%s</span>', "monospace", cal),
        timeout = 0, hover_timeout = 0.5,
        width = 115,
    })
end

mytextclock:connect_signal("mouse::leave", remove_calendar)

mytextclock:buttons(awful.util.table.join(
    -- Current month on click
    awful.button({ }, 1, function() add_calendar(0) end),
    -- Previous month on mouse wheel up
    awful.button({ }, 4, function() add_calendar(-1) end),
    -- Next month on mouse wheel down
    awful.button({ }, 5, function() add_calendar(1) end)
))

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                       awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()

                                                  -- Print client infos on click on the tasklist
                                                  if debug_mode then
                                                      c_infos = "class:" ..c.class ..
                                                        "\tinstance:" .. c.instance ..
                                                        "\tname:" .. c.name
                                                      io.stderr:write(c_infos .. "\n")
                                                  end
                                                end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

-- {{{ MPD widget
if iniquitous_loaded then
    w_music_img = wibox.widget.imagebox(beautiful.widget_music)
    w_music_tb = iniquitous.mpc.init()
end
-- }}}

for s = 1, screen.count() do
    -- Create a promptbox
    mypromptbox[s] = awful.widget.prompt()
    -- Create a layoubox
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, 1) end)
                           ))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ height = 15, position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    -- Only add menu on first screen
    if s == 1 then left_layout:add(mylauncher) end
    left_layout:add(mytaglist[s])
    left_layout:add(mylayoutbox[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()

    if s == 2 and iniquitous_loaded then
        right_layout:add(w_music_img)
        right_layout:add(spacer)
        right_layout:add(w_music_tb)
        right_layout:add(separator)
    end

    right_layout:add(mytextclock)
    if s == 1 then right_layout:add(wibox.widget.systray()) end

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end

-- {{{ Bottom Wibox
do
    mybottomwibox = awful.wibox({ height = 14, position = "bottom", screen = 1 })

    local left_layout = wibox.layout.fixed.horizontal()
    local right_layout = wibox.layout.fixed.horizontal()

    -- {{{ Kernel version
    local w_kernel_img = wibox.widget.imagebox(beautiful.widget_pacman)
    local w_kernel_tb = wibox.widget.textbox(awful.util.pread("uname -r"))

    left_layout:add(w_kernel_img)
    left_layout:add(spacer)
    left_layout:add(w_kernel_tb)
    -- }}}

    if vicious_loaded then
        -- {{{ CPU
        -- Initialize widget
        local w_cpu_img = wibox.widget.imagebox(beautiful.widget_cpu)
        local w_cpu_g = awful.widget.graph()

        -- options
        w_cpu_g:set_height(14):set_width(50)
        w_cpu_g:set_border_color(beautiful.border_widget)
        w_cpu_g:set_background_color(beautiful.fg_off_widget)
        w_cpu_g:set_color(beautiful.fg_widget)

        -- Register widget
        vicious.register(w_cpu_g, vicious.widgets.cpu, "$1", 3)
        left_layout:add(separator)
        left_layout:add(w_cpu_img)
        left_layout:add(spacer)
        left_layout:add(w_cpu_g)
        -- }}}
        --
        -- {{{ Memory usage
        local w_mem_img = wibox.widget.imagebox(beautiful.widget_mem)

        -- Initialize widget
        w_mem_b = awful.widget.progressbar()
        -- Pogressbar properties
        w_mem_b:set_height(14):set_width(10)
        w_mem_b:set_vertical(true)
        w_mem_b:set_border_color(beautiful.border_widget)
        w_mem_b:set_background_color(beautiful.fg_off_widget)
        w_mem_b:set_color(beautiful.fg_widget)
        -- Register widget
        vicious.register(w_mem_b, vicious.widgets.mem, "$1", 13)
        left_layout:add(separator)
        left_layout:add(w_mem_img)
        left_layout:add(spacer)
        left_layout:add(w_mem_b)
        -- }}}

        -- {{{ File system usage
        local w_fs_img = wibox.widget.imagebox(beautiful.widget_fs)
        -- Initialize widgets
        w_fs_p = {
          r = awful.widget.progressbar(),
          h = awful.widget.progressbar()
        }
        w_fs_tb = {
            r = wibox.widget.textbox(),
            h = wibox.widget.textbox()
        }

        -- Set progressbars properties
        for _, w in pairs(w_fs_p) do
          w:set_vertical(true)
          w:set_height(14):set_width(5)
          w:set_border_color(beautiful.border_widget)
          w:set_background_color(beautiful.fg_off_widget)
          w:set_color(beautiful.fg_widget)
        end

        -- Register widgets
        vicious.register(w_fs_p.r, vicious.widgets.fs, "${/ used_p}", 599)
        vicious.register(w_fs_p.h, vicious.widgets.fs, "${/home used_p}", 599)

        vicious.register(w_fs_tb.r, vicious.widgets.fs, "${/ used_p}%", 599)
        vicious.register(w_fs_tb.h, vicious.widgets.fs, "${/home used_p}%", 599)

        left_layout:add(separator)
        left_layout:add(w_fs_img)
        left_layout:add(spacer)
        left_layout:add(w_fs_tb.r)
        left_layout:add(spacer)
        left_layout:add(w_fs_p.r)
        left_layout:add(spacer)
        left_layout:add(w_fs_tb.h)
        left_layout:add(spacer)
        left_layout:add(w_fs_p.h)
        -- }}}

        if network then
            -- {{{ Wifi Infos
            if wifi then
                w_wifi_img = wibox.widget.imagebox(beautiful.widget_wifi)

                w_wifi_tb = wibox.widget.textbox()
                vicious.register(w_wifi_tb, vicious.widgets.wifi, '${link}% [${ssid}]', 23, network)
                left_layout:add(separator)
                left_layout:add(w_wifi_img)
                left_layout:add(spacer)
                left_layout:add(w_wifi_tb)
            end
            -- }}}
            -- {{{ Network usage
            w_netdown_img = wibox.widget.imagebox(beautiful.widget_down)
            w_netup_img = wibox.widget.imagebox(beautiful.widget_up)

            w_net_tb = wibox.widget.textbox()
            vicious.register(w_net_tb, vicious.widgets.net, '${'..network..' down_kb}  ${'..network..' up_kb}', 5)

            left_layout:add(separator)
            left_layout:add(w_netdown_img)
            left_layout:add(spacer)
            left_layout:add(w_net_tb)
            left_layout:add(spacer)
            left_layout:add(w_netup_img)
            -- }}}
        end
    end

    if iniquitous_loaded then
        -- MPD widget
        right_layout:add(w_music_img)
        right_layout:add(spacer)
        right_layout:add(w_music_tb)

        -- {{{ Volume widget
        iniquitous.volume.init(sound, channel)
        local w_vol_tb = iniquitous.volume.textbox()
        local w_vol_img = iniquitous.volume.imagebox()

        right_layout:add(separator)
        right_layout:add(w_vol_img)
        right_layout:add(spacer)
        right_layout:add(w_vol_tb)
        -- }}}
    end

    right_layout:add(separator)
    right_layout:add(mytextclock)

    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_right(right_layout)

    mybottomwibox:set_widget(layout)
end
-- }}}

-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "p",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "n",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(1)
            if client.focus then client.focus:raise() end
        end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(-1) end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx(1) end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative(1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Shift"   }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- restore minimized windows
    awful.key({ modkey, "Shift" }, "m", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    awful.key({ modkey }, "y", function() menubar.show() end),

    awful.key({ modkey,           }, "a",
        function ()
                  awful.prompt.run({ prompt = "New tag name: " },
                    mypromptbox[mouse.screen].widget,
                    function(new_name)
                        if not new_name or #new_name == 0 then
                            return
                        else
                            props = {selected = true}
                            if tyrannical.tags_by_name[new_name] then
                               props = tyrannical.tags_by_name[new_name]
                            end
                            t = awful.tag.add(new_name, props)
                            awful.tag.viewonly(t)
                        end
                    end
                    )
        end),
    awful.key({ modkey, "Control" }, "r",
              function ()
                awful.prompt.run({ prompt = "New tag name: " },
                                  mypromptbox[mouse.screen].widget,
                                  function(new_name)
                                     if not new_name or #new_name == 0 then
                                        return
                                     else
                                        local screen = mouse.screen
                                        local tag = awful.tag.selected(screen)
                                        if tag then
                                           tag.name = new_name
                                        end
                                     end
                                  end)
              end),
    awful.key({ modkey, }, "d", function () awful.tag.delete() end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey,           }, "s",      function (c) c.sticky = not c.sticky  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey, "Control" }, "m",      function (c) c.minimized = true end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.movetotag(tag)
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.toggletag(tag)
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

globalkeys = awful.util.table.join(
    globalkeys,

    awful.key({ }, "XF86AudioPlay", function () awful.util.pread("mpc toggle") end),
    awful.key({ }, "XF86AudioPrev", function () awful.util.pread("mpc prev") end),
    awful.key({ }, "XF86AudioNext", function () awful.util.pread("mpc next") end),

    awful.key({ }, "XF86AudioMute", function () iniquitous.volume.volume("mute") end),
    awful.key({ }, "XF86AudioLowerVolume", function () iniquitous.volume.volume("down") end),
    awful.key({ }, "XF86AudioRaiseVolume", function () iniquitous.volume.volume("up") end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local title = awful.titlebar.widget.titlewidget(c)
        title:buttons(awful.util.table.join(
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
                ))

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(title)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
