cutils = require("common-utils")

device_om = ObjectManager {
  Interest {
    type = "device",
    Constraint {
      "media.class", "=", "Audio/Device"
    },
    Constraint {
      "device.name", "=", "alsa_card.pci-0000_0a_00.1"
    },
  },
}

node_om = ObjectManager {
  Interest {
    type = "node",
  },
}

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
  return get_product_name(route["info"]) == "DELL U2723QE"
end

device_om:connect("object-added", function (om, device)
  print("device added: " .. device.properties["device.description"])

  function select_profile()
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
        local profile = enum_route["profiles"][1]
        print("will switch to profile with index " .. profile)

        local param = Pod.Object {
          "Spa:Pod:Object:Param:Profile", "Profile",
          index = profile,
          save = true,
        }
        device:set_param("Profile", param)
      end
    end
  end

  device:connect("params-changed", function(device, param)
    print("device param changed: " .. param)

    if param == "EnumProfile" then
      select_profile()
    end
  end)

  select_profile()
end)

node_om:activate()
device_om:activate()
