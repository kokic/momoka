///|
priv struct CliConfig {
  location : @core.ProjectLocation
  overrides : @core.ProjectOverrides
}

///|
priv struct EvolConfig {
  paths : Array[String]
  create_pr : Bool
}

///|
priv enum PreferencesRequest {
  Configure
  Show
}

///|
priv enum CliRequest {
  Project(CliConfig)
  Upgrade(Array[String])
  Bump(Array[String])
  Evol(EvolConfig)
  Pin(Array[String])
  Stable
  Nightly
  Preferences(PreferencesRequest)
}

///|
fn decode_new_request(
  matches : @argparse.Matches,
) -> CliRequest raise @core.CliError {
  Project({
    location: @core.decode_new_location(matches),
    overrides: @core.ProjectOverrides::from_matches(matches),
  })
}

///|
fn decode_init_request(matches : @argparse.Matches) -> CliRequest {
  Project({
    location: @core.decode_init_location(matches),
    overrides: @core.ProjectOverrides::from_matches(matches),
  })
}

///|
fn decode_preferences_request(matches : @argparse.Matches) -> CliRequest {
  if matches.flags.get("show").unwrap_or(false) {
    Preferences(Show)
  } else {
    Preferences(Configure)
  }
}

///|
fn decode_evol_request(matches : @argparse.Matches) -> CliRequest {
  Evol({
    paths: matches.values.get("path").unwrap_or(["."]),
    create_pr: matches.flags.get("pr").unwrap_or(false),
  })
}

///|
fn CliRequest::parse(
  args : ArrayView[String],
) -> CliRequest raise @core.CliError {
  let command = @argparse.Command(
    "momoka",
    version=@core.VERSION,
    about=CLI_ABOUT,
    subcommands=cli_commands(),
    arg_required_else_help=true,
    subcommand_required=true,
  )

  CliRequest::from_matches(
    @argparse.Command::parse(command, argv=args) catch {
      err => raise @core.cli_error("\{err}")
    },
  )
}

///|
fn CliRequest::from_matches(
  matches : @argparse.Matches,
) -> CliRequest raise @core.CliError {
  guard! matches.subcommand is Some((name, submatches))
  match name {
    "new" => decode_new_request(submatches)
    "init" => decode_init_request(submatches)
    "upgrade" => Upgrade(submatches.values.get("path").unwrap_or(["."]))
    "bump" => Bump(submatches.values.get("path").unwrap_or(["."]))
    "evol" => decode_evol_request(submatches)
    "pin" => Pin(submatches.values.get("path").unwrap_or(["."]))
    "stable" => Stable
    "nightly" => Nightly
    "cfg" => decode_preferences_request(submatches)
    _ => raise @core.cli_error("unknown command: \{name}")
  }
}

///|
const CLI_ABOUT : String = "Create a minimal MoonBit module."

///|
fn cli_commands() -> Array[@argparse.Command] {
  [
    @core.new_command(),
    @core.init_command(),
    @core.upgrade_command(),
    @core.bump_command(),
    @core.evol_command(),
    @core.pin_command(),
    @argparse.Command("stable", about="Install the stable MoonBit toolchain."),
    @argparse.Command("nightly", about="Install the nightly MoonBit toolchain."),
    preferences_command(),
  ]
}
