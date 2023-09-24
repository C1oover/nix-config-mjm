get_last_id() {
  task +LATEST ids
}

task add "wash hot clothes" project:home.laundry +next
wash_hot_id="$(get_last_id)"

task add "dry hot clothes" project:home.laundry depends:"$wash_hot_id"
task add "put away hot clothes" project:home.laundry depends:"$(get_last_id)"

task add "wash cold clothes" project:home.laundry depends:"$wash_hot_id"
task add "dry cold clothes" project:home.laundry depends:"$(get_last_id)"
task add "put away cold clothes" project:home.laundry depends:"$(get_last_id)"
