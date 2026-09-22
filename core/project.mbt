///|
pub struct ProjectFile {
  filename : String
  content : String
}

///|
pub fn module_name_from_project_dir(
  project_dir : String,
) -> String raise CliError {
  let module_name = @path.Path::basename(project_dir).to_owned()
  guard !module_name.is_empty() else {
    raise CliError("cannot derive a module name from directory: \{project_dir}")
  }
  module_name
}

///|
pub fn render_project_files(
  project_dir : String,
  username : String,
  settings : ProjectSettings,
) -> Array[ProjectFile] raise CliError {
  let module_name = module_name_from_project_dir(project_dir)
  [
    {
      filename: "moon.mod",
      content: moon_mod_content(
        username~,
        module_name~,
        settings.license,
        settings.host,
        settings.preferred_target,
      ),
    },
    { filename: "moon.pkg", content: moon_pkg_content(), },
    { filename: ".gitignore", content: gitignore_content(), },
    { filename: ".moonignore", content: gitignore_content(), },
    { filename: ".gitattributes", content: gitattributes_content(), },
  ]
}
