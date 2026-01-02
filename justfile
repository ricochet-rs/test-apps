clean:
  R --slave -f clean-ricochet-toml-ids.R

deploy-all:
  #!/usr/bin/env bash
  for dir in */; do \
    name="${dir%/}"; \
    ricochet deploy "$name"; \
  done
