///|
fn new_command() -> @argparse.Command {
  @argparse.Command(
    "new",
    about="Create a new MoonBit module in a new directory.",
    options=project_options,
    positionals=[
      @argparse.PositionArg(
        "path",
        about="Project directory path to create.",
        num_args=@argparse.ValueRange::single(),
      ),
    ],
  )
}

///|
fn init_command() -> @argparse.Command {
  @argparse.Command(
    "init",
    about="Initialize a MoonBit module in an existing directory.",
    options=project_options,
    positionals=[
      @argparse.PositionArg(
        "path",
        about="Project directory path [default: current directory].",
      ),
    ],
  )
}

///|
fn upgrade_command() -> @argparse.Command {
  @argparse.Command(
    "upgrade",
    about="Upgrade all dependencies of the project to their latest versions.",
    positionals=[
      @argparse.PositionArg(
        "path",
        about="Project directory path [default: current directory].",
      ),
    ],
  )
}

///|
fn preferences_command() -> @argparse.Command {
  @argparse.Command(
    "cfg",
    about="Configure default license / host / target, or print them.",
    flags=[
      @argparse.FlagArg("show", long="show", about="Print current preferences."),
    ],
  )
}
