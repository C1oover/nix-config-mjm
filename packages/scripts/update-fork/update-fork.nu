
def main [--upstream: string] {
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

  print $'(ansi gb)tracking ($env.CI_COMMIT_BRANCH) branch(ansi reset)'
  jj bookmark track $'($env.CI_COMMIT_BRANCH)@origin'

  print $'(ansi gb)fetching origin changes from ($env.CI_COMMIT_BRANCH) branch(ansi reset)'
  jj git fetch --remote origin --branch $env.CI_COMMIT_BRANCH

  let upstream_branch = $env.CI_COMMIT_BRANCH | str replace 'deploy/' ''
  print $'(ansi gb)fetching upstream changes from ($upstream_branch)(ansi reset)'
  jj git fetch --remote upstream --branch $upstream_branch

  print $'(ansi gb)rebasing ($env.CI_COMMIT_BRANCH) branch(ansi reset)'
  jj rebase -s $env.CI_COMMIT_BRANCH -d $'($upstream_branch)@upstream' -d $'all:($env.CI_COMMIT_BRANCH)- ~ ::($upstream_branch)@upstream'

  print $'(ansi gb)pushing ($env.CI_COMMIT_BRANCH) branch(ansi reset)'
  jj git push --bookmark $env.CI_COMMIT_BRANCH
}
