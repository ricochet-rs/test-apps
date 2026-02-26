clear:
  R --slave -f clean-ricochet-toml-ids.R

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

