
const sqlite3 = '@sqlite3@'
const snappy_decompress = '@snappy-decompress@'

# Open a shell in the slab container
def --wrapped "main ssh" [...rest] {
  npm run docker:ssh ...$rest
}

# Start the main slab containers and watch the logs
def "main start" [] {
  docker compose up --no-log-prefix
}

# Restart one of the containers
def "main restart" [name: string = "slab_1"] {
  docker compose down $name
  docker compose up -d $name
}

# Rebuild one of the containers and start it
def "main rebuild" [name: string = "slab_1"] {
  docker compose build $name
  docker compose up -d $name
}

# Start one of the containers
def --wrapped "main up" [...rest] {
  docker compose up -d ...$rest
}

# Open an IEx session in the slab container
def "main iex" [] {
  docker compose exec slab_1 iex --sname iex --cookie dev-cookie --remsh slab@slab_1
}

# Print the auth token for Slab dev stored in Firefox's local storage
def "main token" [] {
  cd (mktemp -d)
  cp `~/Library/Application Support/Firefox/Profiles/matt/storage/default/https+++matt.slabdev.com/ls/data.sqlite` data.sqlite
  run-external $sqlite3 data.sqlite "select value from data where key = 'CapacitorStorage.authToken'" | run-external $snappy_decompress
}

# Convenient commands for doing things with Slab
def main [] {
  help main
}
