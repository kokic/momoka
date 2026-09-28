///|
#cfg(target="native")
async fn resolve_project_options(
  overrides : @core.ProjectOverrides,
) -> (String, @core.ProjectSettings) raise @core.CliError {
  let user = ensure_username_with_preferred(overrides.username)
  (user.username, resolve_settings(overrides, user.preferred))
}

///|
#cfg(target="wasm")
fn resolve_project_options(
  overrides : @core.ProjectOverrides,
) -> (String, @core.ProjectSettings) raise @core.CliError {
  let username = ensure_username(overrides.username)
  let settings = @core.ProjectSettings::new(
    @core.configured_value(overrides.license, None, @core.DEFAULT_LICENSE),
    @core.configured_value(overrides.host, None, @core.DEFAULT_HOST),
    @core.configured_value(
      overrides.preferred_target,
      None,
      @core.DEFAULT_TARGET,
    ),
  )
  (username, settings)
}
