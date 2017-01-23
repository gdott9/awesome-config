local capi      = {root=root,client=client,tag=tag,mouse=mouse}
local aw_util   = require("awful.util")
local aw_tag    = require("awful.tag")
local aw_client = require("awful.client")
local aw_layout = require("awful.layout")
local aw_key    = require("awful.key")
local aw_prompt = require("awful.prompt")
local aw_screen = require("awful.screen")
local tyrannical = require("tyrannical")

local util = {}

function util.add_tag()
  aw_prompt.run({ prompt = "New tag name: " },
    aw_screen.focused().mypromptbox.widget,
    function(new_name)
      if not new_name or #new_name == 0 then
        return
      else
        props = {selected = true}
        if tyrannical.tags_by_name[new_name] then
          props = tyrannical.tags_by_name[new_name]
        end
        t = aw_tag.add(new_name, props)
        aw_tag.viewonly(t)
      end
    end)
end

function util.delete_tag()
  aw_tag.delete(capi.client.focus and aw_tag.selected(capi.client.focus.screen) or aw_tag.selected(capi.mouse.screen) )
end

function util.term_in_current_tag()
  aw_util.spawn(terminal,{intrusive=true,floating=true})
end

function util.new_tag_with_term()
  aw_util.spawn(terminal,{new_tag={volatile = true}})
end

function util.rename_tag()
  aw_prompt.run({ prompt = "New tag name: " },
  mypromptbox[capi.mouse.screen].widget,
  function(new_name)
    if not new_name or #new_name == 0 then
      return
    else
      local screen = capi.mouse.screen
      local t = aw_tag.selected(screen)
      if t then
        t.name = new_name
      end
    end
  end)
end

return util
