cutils = require("common-utils")

function get_product_name(route_info)
  local size = route_info[1]
  for i = 2, size * 2, 2 do
    key = route_info[i]
    if key == "device.product.name" then
      return route_info[i+1]
    end
  end

  return nil
end

function is_main_monitor(route)
  if route == nil then
    return false
  end

  return get_product_name(route["info"]) == "DELL U2723QE"
end

SimpleEventHook {
  name = "mjm/choose-profile",
  before = "device/find-stored-profile",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "select-profile" },
    },
  },
  execute = function (event)
    local selected_profile = event:get_data("selected_profile")
    if selected_profile then
      return
    end

    local device = event:get_subject()
    if device.properties["alsa.id"] ~= "HDMI" then
      return
    end

    print("selecting correct profile for device: " .. device.properties["device.description"])
    local current_route = nil
    for r in device:iterate_params("Route") do
      current_route = cutils.parseParam(r, "Route")
    end

    if is_main_monitor(current_route) then
      print("already routed to correct monitor")
      return
    end

    for r in device:iterate_params("EnumRoute") do
      local enum_route = cutils.parseParam(r, "EnumRoute")

      if is_main_monitor(enum_route) then
        print("found desired route: " .. enum_route["description"])
        local profile_index = enum_route["profiles"][1]
        print("will switch to profile with index " .. profile_index)

        local selected_profile = nil
        for p in device:iterate_params("EnumProfile") do
          local profile = cutils.parseParam(p, "EnumProfile")
          if profile.index == profile_index then
            print("found profile: " .. profile.name)
            selected_profile = profile
            break
          end
        end

        if selected_profile then
          event:set_data("selected-profile", selected_profile)
        end
      end
    end
  end
}:register()
