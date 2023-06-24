
|Standard key combination| Meaning|
|------------------------|---------|
|Ctrl+C| The interrupt signal, sends SIGINT to the job running in the foreground.
|Ctrl+Y| The delayed suspend character. Causes a running process to be stopped when it attempts to read input from the terminal. Control is returned to the shell, the user can foreground, background or kill the process. Delayed suspend is only available on operating systems supporting this feature.
|Ctrl+Z| The suspend signal, sends a SIGTSTP to a running program, thus stopping it and returning control to the shell.