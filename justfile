clean-ids:
  Rscript clean-ricochet-toml-ids.R

deploy-all server='':
  #!/usr/bin/env bash
  for toml in $(find . -name '_ricochet.toml' -not -path './.git/*'); do
    dir="$(dirname "$toml")"
    dir="${dir#./}"
    if [[ -n '{{server}}' ]]; then
      ricochet deploy "$dir" -S '{{server}}'
    else
      ricochet deploy "$dir"
    fi
  done

deploy-all-dev server='':
  #!/usr/bin/env bash
  for toml in $(find . -name '_ricochet.toml' -not -path './.git/*'); do
    dir="$(dirname "$toml")"
    dir="${dir#./}"
    if [[ -n '{{server}}' ]]; then
      ricochet-dev deploy "$dir" -S '{{server}}'
    else
      ricochet-dev deploy "$dir"
    fi
  done

delete-all server='':
  #!/usr/bin/env bash
  for toml in $(find . -name '_ricochet.toml' -not -path './.git/*'); do
    id=$(grep '^id' "$toml" | sed 's/.*= *"//' | sed 's/"//')
    if [[ -z "$id" ]]; then
      echo "No id found in $toml, skipping"
      continue
    fi
    echo "Deleting $id (from $toml)"
    if [[ -n '{{server}}' ]]; then
      ricochet delete -f "$id" -S '{{server}}'
    else
      ricochet delete -f "$id"
    fi
  done

delete-all-dev server='':
  #!/usr/bin/env bash
  for toml in $(find . -name '_ricochet.toml' -not -path './.git/*'); do
    id=$(grep '^id' "$toml" | sed 's/.*= *"//' | sed 's/"//')
    if [[ -z "$id" ]]; then
      echo "No id found in $toml, skipping"
      continue
    fi
    echo "Deleting $id (from $toml)"
    if [[ -n '{{server}}' ]]; then
      ricochet-dev delete -f "$id" -S '{{server}}'
    else
      ricochet-dev delete -f "$id"
    fi
  done
