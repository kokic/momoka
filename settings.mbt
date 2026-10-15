///|
async fn resolve_project_options(
  overrides : @core.ProjectOverrides,
) -> (String, @core.ProjectSettings) raise @core.CliError {
  let user = ensure_username_with_preferred(overrides.username)
  (user.username, resolve_settings(overrides, user.preferred))
}
