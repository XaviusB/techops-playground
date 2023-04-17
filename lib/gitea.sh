#!/bin/bash

function create_gitea_repo() {
  local repo_name
  local repo_description
  local read_only
  local org_name
  local "${@}"
  repo_name=${repo_name:?need value repo_name}
  repo_description=${repo_description:?need value repo_description}
  read_only=${read_only:-false}
  org_name=${org_name:?need value org_name}

  repos=$(curl -sSL -X GET \
    --url "http://${GITEA_USERNAME}:${PASSWORD}@gitea.localhost/api/v1/orgs/${org_name}/repos" \
    | jq -r '.[].name')
  if [[ "${repos}" =~ ${repo_name} ]]; then
    log INFO "Repo ${repo_name} already exists"
  else
    log WARN "Creating gitea repo ${repo_name}"
    curl -sSL -X POST \
      --url "http://${GITEA_USERNAME}:${PASSWORD}@gitea.localhost/api/v1/orgs/${org_name}/repos" \
      -H 'accept: application/json' \
      -H 'content-type: application/json' \
      -d '{
        "auto_init": true,
        "description": "'"${repo_description}"'"
        ,"gitignores": "Go",
        "name": "'"${repo_name}"'",
        "private": '"${read_only}"',
        "readme": "Default",
        "default_branch": "master"
      }' > /dev/null
  fi
}

function add_repo_key() {
  local repo_name
  local key_title
  local key_path
  local read_only
  local org_name
  local "${@}"
  repo_name=${repo_name:?need value repo_name}
  key_title=${key_title:?need value key_title}
  key_path=${key_path:?need value key_path}
  org_name=${org_name:?need value org}
  read_only=${read_only:-false}

  key_list=$(curl -sSL -X GET \
    --url http://${GITEA_USERNAME}:${PASSWORD}@gitea.localhost/api/v1/repos/${org_name}/${repo_name}/keys \
    | jq -r '.[].title')
  if [[ "${key_list}" =~ "my_precious" ]]; then
    log INFO "SSH key already exists"
  else
    log WARN "Adding ${key_title} ssh key to gitea"
    curl -sSL -X POST --url "http://${GITEA_USERNAME}:${PASSWORD}@gitea.localhost/api/v1/repos/${org_name}/${repo_name}/keys" \
      -H 'accept: application/json' \
      -H 'content-type: application/json' \
      -d '{
        "key": "'"$(cat "${key_path}")"'",
        "read_only": '"${read_only}"',
        "title": "'"${key_title}"'"
      }' > /dev/null
  fi
}

function add_repo_webhook() {
  local repo_name
  local url
  local "${@}"
  local org_name
  local events
  repo_name=${repo_name:?need value repo_name}
  url=${url:?need value url}
  org_name=${org_name:?need value org}
  IFS=" " read -r -a events <<< "$events"
  events_json_array=$(jq --compact-output --null-input '$ARGS.positional' --args -- "${events[@]}")

  webhooks=$(curl \
    -sSL -X GET \
    --url "http://${GITEA_USERNAME}:${PASSWORD}@gitea.localhost/api/v1/repos/${org_name}/${repo_name}/hooks" \
    | jq -r '.[].config.url')

  if [[ "${webhooks}" =~ ${url} ]]; then
    log INFO "Webhook ${url} already exists for ${repo_name}"
  else
    log WARN "Adding webhook ${url} to gitea"
    curl -sSL -X POST --url "http://${GITEA_USERNAME}:${PASSWORD}@gitea.localhost/api/v1/repos/${org_name}/${repo_name}/hooks" \
      -H 'accept: application/json' \
      -H 'content-type: application/json' \
      -d '{
        "config": {
          "content_type": "json",
          "url": "'"${url}"'"
        },
        "http_method": "POST",
        "active": true,
        "branch_filter": "*",
        "events": '"${events_json_array}"',
        "type": "gitea"
      }'
  fi
}


function create_gitea_org() {
  local org_name
  local website
  local "${@}"
  org_name=${org_name:?need value org_name}
  website=${website:-http://localhost/}

  current_orgs=$(curl \
      -sSL -X GET \
      --url "http://${GITEA_USERNAME}:${PASSWORD}@gitea.localhost/api/v1/orgs" \
      | jq -r '.[].name')

  if [[ "${current_orgs}" =~ ${org_name} ]]; then
      log INFO "Org ${org_name} already exists"
  else
      log WARN "Creating org ${org_name}"
      curl -sSL -X POST --url "http://${GITEA_USERNAME}:${PASSWORD}@gitea.localhost/api/v1/orgs" \
        -H 'accept: application/json' \
        -H 'content-type: application/json' \
        -d '{
          "username": "'"${org_name}"'",
          "full_name": "'"${org_name}"'",
          "visibility": "private",
          "repo_admin_change_team_access": true,
          "website": "'"${website}"'"
        }'
  fi
}

function create_gitea_org_label() {
  local org_name
  local label_name
  local label_color
  local label_description
  local exclusive
  local "${@}"
  org_name=${org_name:?need value org_name}
  label_name=${label_name:?need value label_name}
  label_color=${label_color:-#00aabb}
  label_description=${label_description:-}
  exclusive=${exclusive:-false}

  current_labels=$(curl \
    -sSL -X GET \
    --url "http://${GITEA_USERNAME}:${PASSWORD}@gitea.localhost/api/v1/orgs/${org_name}/labels" \
    | jq -r '.[].name')

  if [[ "${current_labels}" =~ ${label_name} ]]; then
    log INFO "Label ${label_name} already exists"
  else
    log WARN "Creating label ${label_name}"
    curl -sSL -X POST --url "http://${GITEA_USERNAME}:${PASSWORD}@gitea.localhost/api/v1/orgs/${org_name}/labels" \
      -H 'accept: application/json' \
      -H 'content-type: application/json' \
      -d '{
        "color": "'"${label_color}"'",
        "description": "'"${label_description}"'",
        "exclusive": '"${exclusive}"',
        "name": "'"${label_name}"'"
      }'
  fi
}

export -f create_gitea_org create_gitea_org_label create_gitea_repo add_repo_key add_repo_webhook
