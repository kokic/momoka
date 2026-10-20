///|
priv struct Dependency {
  name : String
  version : String
}

///|
priv struct MoonMod {
  content : String
  version : String?
  dependencies : Array[Dependency]
}

///|
fn MoonMod::parse(content : String) -> MoonMod {
  {
    content,
    version: parse_version(content),
    dependencies: parse_import_dependencies(content),
  }
}

///|
async fn read_moon_mod(moon_mod_path : String) -> MoonMod raise @core.CliError {
  guard path_exists(moon_mod_path) else {
    raise @core.cli_error("moon.mod not found: \{moon_mod_path}")
  }
  MoonMod::parse(read_string_file(moon_mod_path))
}

///|
fn parse_version(content : String) -> String? {
  let prefix = "version = \""
  for raw_line in content.split("\n") {
    let line = raw_line.trim()
    guard line.has_prefix(prefix) else { continue }
    guard line[prefix.length():].split_once("\"") is Some((version, _)) else {
      return None
    }
    return Some(version.to_owned())
  }
  None
}

///|
fn MoonMod::dependency_version(self : MoonMod, name : String) -> String? {
  for dependency in self.dependencies {
    guard dependency.name == name else { continue }
    return Some(dependency.version)
  }
  None
}

///|
fn parse_import_dependencies(content : String) -> Array[Dependency] {
  let dependencies : Array[Dependency] = []
  let mut in_import = false
  for raw_line in content.split("\n") {
    let line = raw_line.trim()
    if line.has_prefix("import") {
      in_import = true
    } else if line.has_prefix("}") {
      in_import = false
    } else if in_import {
      if dependency_from_import(line) is Some(dependency) {
        dependencies.push(dependency)
      }
    }
  }
  dependencies
}

///|
fn dependency_from_import(line : StringView) -> Dependency? {
  guard line.split_once("\"") is Some((_, rest)) else { return None }
  guard rest.split_once("\"") is Some((entry, _)) else { return None }
  guard !entry.is_empty() &&
    !entry.has_prefix(".") &&
    !entry.has_prefix("/") &&
    !entry.contains("://") else {
    None
  }
  match entry.split_once("@") {
    Some((name, version)) if !name.is_empty() && !version.is_empty() =>
      Some({ name: name.to_owned(), version: version.to_owned(), })
    None => Some({ name: entry.to_owned(), version: "unknown", })
    _ => None
  }
}
