# https://gist.github.com/JosiahParry/55a2029cb81f0f9a2349cdc061d8dd71
library(dplyr)
library(tidyr)
library(ggplot2)

# read in the raw json path
polls_raw <- RcppSimdJson::fload("polls.json")

# filter to the IDs that contain Harris
has_harris <- polls_raw |>
  unnest(answers) |>
  filter(choice == "Harris") |>
  distinct(id)


# clean up the data and filter to only harris and trump
polls_clean <- polls_raw |>
  semi_join(has_harris) |>
  unnest(answers) |>
  as_tibble() |>
  mutate(
    across(c(sampleSize, pct), as.numeric),
    across(c(created_at, ends_with("Date")), anytime::anydate)
  ) |>
  filter(choice %in% c("Harris", "Trump")) |>
  rename_with(heck::to_snek_case)


# make a plot
gg <- polls_clean |>
  filter(end_date >= "2024-07-20") |>
  ggplot(aes(end_date, pct, color = choice)) +
  geom_smooth() +
  scale_color_viridis_d(direction = -1) +
  theme_minimal()

fname <- sprintf(
  "persistent/%s.png",
  format(Sys.time(), "%Y-%m-%d-%H-%M-%S", tz = "UTC")
)

ggsave(fname, gg)
