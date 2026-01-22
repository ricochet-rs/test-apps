clear:
  R --slave -f clean-ricochet-toml-ids.R

deploy-all server='':
  #!/usr/bin/env bash
  for dir in */; do \
    name="${dir%/}"; \
    if [[ -n '{{server}}' ]]; then \
      ricochet deploy "$name" -S '{{server}}'; \
    else \
      ricochet deploy "$name"; \
    fi \
  done
