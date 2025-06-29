ricos <- list.files(
  recursive = TRUE,
  pattern = "_ricochet.toml",
  full.names = TRUE
)

# remove ID from _ricochet.toml files
for (fp in ricos) {
  cli::cli_alert_info("Removing {.col id} from {.file {fp}}")
  rico_toml <- tomledit::read_toml(fp)
  content <- tomledit::get_item(rico_toml, "content")
  content[["id"]] <- NULL
  tomledit::write_toml(
    tomledit::insert_items(rico_toml, content = content),
    fp
  )
}
