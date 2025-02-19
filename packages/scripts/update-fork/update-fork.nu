
def jj-transaction [block: closure] {
  let current_op = jj op log --no-graph -T id --limit 1

  try {
    do $block
  } catch {|e|
    print $'(ansi rb)restoring jj repo state(ansi reset)'
    jj op restore --what repo $current_op
    error make $e.raw
  }
}

def main [--upstream: string] {
  let branch = $env.CI_COMMIT_BRANCH
  let upstream_branch = $branch | str replace 'deploy/' ''

  if (not (".jj" | path exists)) {
    print $'(ansi gb)initializing jj repo(ansi reset)'
    jj git init --git-repo .
  }

  print $'(ansi gb)setting jj repo config(ansi reset)'
  jj config set --repo git.subprocess true
  jj config set --repo user.name $env.GITLAB_USER_NAME
  jj config set --repo user.email $env.GITLAB_USER_EMAIL

  print $'(ansi gb)configuring git remotes(ansi reset)'
  jj git remote set-url origin $'https://ci:($env.GITLAB_TOKEN)@($env.CI_SERVER_HOST)/($env.CI_PROJECT_PATH).git'
  try {
    jj git remote set-url upstream $upstream 
  } catch {
    jj git remote add upstream $upstream
  }

  print $'(ansi gb)tracking ($branch) branch(ansi reset)'
  jj bookmark track $'($branch)@origin'

  print $'(ansi gb)fetching origin changes from ($branch) branch(ansi reset)'
  jj git fetch --remote origin --branch $branch

  print $'(ansi gb)fetching upstream changes from ($upstream_branch)(ansi reset)'
  jj git fetch --remote upstream --branch $upstream_branch

  jj-transaction {
    print $'(ansi gb)rebasing ($branch) branch(ansi reset)'
    jj rebase -s $branch -d $'($upstream_branch)@upstream' -d $'all:($branch)- ~ ::($upstream_branch)@upstream'

    print $'(ansi gb)pushing ($branch) branch(ansi reset)'
    jj git push --bookmark $branch
  }
}
