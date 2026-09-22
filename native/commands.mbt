///|
fn preferences_command() -> @argparse.Command {
  @argparse.Command(
    "cfg",
    about="Configure default username / license / host / target, or print them.",
    flags=[
      @argparse.FlagArg("show", long="show", about="Print current preferences."),
    ],
  )
}
