///|
priv struct CliConfig {
  location : @core.ProjectLocation
  overrides : @core.ProjectOverrides
}

///|
#cfg(target="native")
priv enum PreferencesRequest {
  Configure
  Show
}

///|
#cfg(target="native")
priv enum CliRequest {
  Project(CliConfig)
  Upgrade(String)
  Stable
  Nightly
  Preferences(PreferencesRequest)
}

///|
#cfg(target="wasm")
priv enum CliRequest {
  Project(CliConfig)
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
#cfg(target="native")
fn decode_preferences_request(matches : @argparse.Matches) -> CliRequest {
  if matches.flags.get("show").unwrap_or(false) {
    Preferences(Show)
  } else {
    Preferences(Configure)
  }
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
#cfg(target="native")
fn CliRequest::from_matches(
  matches : @argparse.Matches,
) -> CliRequest raise @core.CliError {
  guard! matches.subcommand is Some((name, submatches))
  match name {
    "new" => decode_new_request(submatches)
    "init" => decode_init_request(submatches)
    "upgrade" => Upgrade(@core.matched_value(submatches, "path").unwrap_or("."))
    "stable" => Stable
    "nightly" => Nightly
    "cfg" => decode_preferences_request(submatches)
    _ => raise @core.cli_error("unknown command: \{name}")
  }
}

///|
#cfg(target="wasm")
fn CliRequest::from_matches(
  matches : @argparse.Matches,
) -> CliRequest raise @core.CliError {
  guard! matches.subcommand is Some((name, submatches))
  match name {
    "new" => decode_new_request(submatches)
    "init" => decode_init_request(submatches)
    _ => raise @core.cli_error("unknown command: \{name}")
  }
}

///|
#cfg(target="native")
const CLI_ABOUT : String = "Create a minimal MoonBit module."

///|
#cfg(target="wasm")
const CLI_ABOUT : String = "Create a minimal MoonBit module from the command line (WASI)."

///|
#cfg(target="native")
fn cli_commands() -> Array[@argparse.Command] {
  [
    @core.new_command(),
    @core.init_command(),
    @core.upgrade_command(),
    @argparse.Command("stable", about="Install the stable MoonBit toolchain."),
    @argparse.Command("nightly", about="Install the nightly MoonBit toolchain."),
    preferences_command(),
  ]
}

///|
#cfg(target="wasm")
fn cli_commands() -> Array[@argparse.Command] {
  [@core.new_command(), @core.init_command()]
}
