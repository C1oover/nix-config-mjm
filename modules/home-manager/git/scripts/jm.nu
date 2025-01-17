
def get-parents [
  --mega (-m): string = "mega" # the revision of the megamerge
]: nothing -> list {
  jj log --no-graph -r $'($mega)-' -T 'change_id ++ "\n"' | split row "\n"
}

# List the changes that make up the mega merge (the direct children of the merge)
def "main list" [
  --mega (-m): string = "mega" # the revision of the megamerge
] {
  jj log --no-graph -r $'($mega)-'
}

# Logs the changes between trunk and the mega merge
def "main log" [
  --mega (-m): string = "mega" # the revision of the megamerge
] {
  jj log -r $"fork_point\(trunk\() | ($mega))::($mega)"
}

# Rebase each change in the megamerge on top of trunk
def "main rebase" [
  --mega (-m): string = "mega" # the revision of the megamerge
] {
  jj rebase -b $mega -d 'trunk()'
}

# Update the changes in the megamerge to be on top of the latest trunk
#
# Fetches remote git changes and then rebases.
def "main up" [
  --mega (-m): string = "mega" # the revision of the megamerge
] {
  jj git fetch
  main rebase -m $mega
}

# Advance the branches in the megamerge to the latest change
def "main advance" [
  --mega (-m): string = "mega" # the revision of the megamerge
] {
  get-parents -m $mega | each {|change_id|
    jj bookmark move --from $"heads\(trunk\()..($change_id) & bookmarks\())" --to $change_id
  } | ignore
}

# Add a revision to the megamerge
#
# The revision will keep its existing parents but will be made a child
# of the megamerge.
def "main add" [
  revision: string             # the revision to add to the megamerge
  --mega (-m): string = "mega" # the revision of the megamerge
] {
  jj rebase -s $mega -d $'all:($mega)-' -d $revision
}

# Insert a revision to the megamerge
#
# Inserts the revision between trunk and the megamerge. Don't use this
# if you need to preserve the parents of the revision.
def "main insert" [
  revision: string             # the revision to add to the megamerge
  --mega (-m): string = "mega" # the revision of the megamerge
] {
  jj rebase -r $revision --after 'trunk()' --before $mega
}

# Remove a revision from the megamerge
def "main remove" [
  revision: string             # the revision to remove from the megamerge
  --mega (-m): string = "mega" # the revision of the megamerge
] {
  jj rebase -s $mega -d $'all:($mega)- ~ ($revision)'
}

def main [] {}
