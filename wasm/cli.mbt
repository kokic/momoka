///|
priv struct CliConfig {
  location : @core.ProjectLocation
  overrides : @core.ProjectOverrides
}

///|
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
fn CliRequest::parse(
  args : ArrayView[String],
) -> CliRequest raise @core.CliError {
  let command = @argparse.Command(
    "momoka",
    version=@core.VERSION,
    about="Create a minimal MoonBit module from the command line (WASI).",
    subcommands=[@core.new_command(), @core.init_command()],
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
    _ => raise @core.cli_error("unknown command: \{name}")
  }
}
