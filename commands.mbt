///|
enum Subcommand {
  Create
  Initialization
  Upgrade
  Config
}

///|
fn Subcommand::name(command : Subcommand) -> String {
  match command {
    Create => "new"
    Initialization => "init"
    Upgrade => "upgrade"
    Config => "cfg"
  }
}

///|
fn Subcommand::all() -> Array[Subcommand] {
  [Create, Initialization, Upgrade, Config]
}

///|
fn Subcommand::command(self : Subcommand) -> @argparse.Command {
  match self {
    Create => new_command()
    Initialization => init_command()
    Upgrade => upgrade_command()
    Config => preferences_command()
  }
}

///|
fn new_command() -> @argparse.Command {
  @argparse.Command(
    Subcommand::Create.name(),
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
    Subcommand::Initialization.name(),
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
    Subcommand::Upgrade.name(),
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
    Subcommand::Config.name(),
    about="Configure default license / host / target, or print them.",
    flags=[
      @argparse.FlagArg("show", long="show", about="Print current preferences."),
    ],
  )
}

///|
fn Subcommand::from_name(name : String) -> Subcommand? {
  let subcommands = Subcommand::all()
  subcommands
  .search_by(command => command.name() == name)
  .bind(index => subcommands.get(index))
}
