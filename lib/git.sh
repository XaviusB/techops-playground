#!/usr/bin/env bash

function git_init() {
  local folder
  local repo_name
  local org_name
  local "${@}"
  org_name=${org_name:?need value org_name}
  folder=${folder:?need value folder}
  repo_name=${repo_name:?need value repo_name}

  pushd "${folder}" > /dev/null
  log WARN "Git init ${folder}"
  rm -rf .git
  git init
  git add .
  git commit -m "Initial commit"
  git remote add origin "ssh://git@gitea.localhost:30022/${org_name}/${repo_name}"
  git push -f origin master
  popd > /dev/null
}
