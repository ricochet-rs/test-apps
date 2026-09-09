# Shiny Exit

This Shiny app exits its R process about one second after a session connects.
It calls `quit(save = "no")`, which uses exit status zero by default.

Use it to test that Ricochet handles session disconnection and reaps a process that exits after startup.
