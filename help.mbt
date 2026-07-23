///|
const BANNER_TEXT : String =
  #|  __  __                       _         
  #| |  \/  | ___  _ __ ___   ___ | | ____ _ 
  #| | |\/| |/ _ \| '_ ` _ \ / _ \| |/ / _` |
  #| | |  | | (_) | | | | | | (_) |   < (_| |
  #| |_|  |_|\___/|_| |_| |_|\___/|_|\_\__,_|
  #|

///|
fn ProjectMode::action_text(self : ProjectMode) -> String {
  match self {
    Create => "created and initialized"
    Init => "initialized"
  }
}

///|
fn usage_text() -> String {
  let momoka = @chalk.chalk().color(YellowBright).render("Momoka")

  let version = @chalk.chalk().modifier(Bold).render("\{VERSION}")

  let description = @chalk.chalk()
    .modifier(Bold)
    .render("Create a minimal MoonBit module")

  let banner = @chalk.chalk()
    .color(YellowBright)
    .modifier(Bold)
    .render(BANNER_TEXT)

  let intro = "\{momoka} \{version} - \{description}"
  (
    $|\{intro}
    $|\{cli_command().render_help()}
    $|\{banner}
  )
}

///|
fn preferences_help_text() -> String {
  preferences_command("\{CLI_NAME} \{CFG_COMMAND}").render_help()
}

///|
fn HelpTopic::text(self : HelpTopic) -> String {
  match self {
    TopLevelHelp => usage_text()
    PreferencesHelp => preferences_help_text()
  }
}
