///|
fn expect_project_request(args : ArrayView[String]) -> CliConfig raise CliError {
  guard parse_cli_args(args) is Project(config) else {
    abort("expected project request")
  }
  config
}

///|
test "parse_cli_args defaults" {
  let config = expect_project_request(["demo"])
  @test.assert_eq(config.location.path, "demo")
  guard config.location.mode is Create else { fail("expected create mode") }
  @test.assert_eq(config.overrides.license, None)
  @test.assert_eq(config.overrides.host, None)
  @test.assert_eq(config.overrides.preferred_target, None)
}

///|
test "parse_cli_args optional flags" {
  let config = expect_project_request([
    "demo", "-l", "MIT", "--host", "gitlab.com", "-t", "js",
  ])
  @test.assert_eq(config.location.path, "demo")
  guard config.location.mode is Create else { fail("expected create mode") }
  @test.assert_eq(config.overrides.license, Some("MIT"))
  @test.assert_eq(config.overrides.host, Some("gitlab.com"))
  @test.assert_eq(config.overrides.preferred_target, Some("js"))
}

///|
test "parse_cli_args init flag long" {
  let config = expect_project_request(["--init", "demo"])
  @test.assert_eq(config.location.path, "demo")
  guard config.location.mode is Init else { fail("expected init mode") }
}

///|
test "parse_cli_args init flag short" {
  let config = expect_project_request(["demo", "-i"])
  @test.assert_eq(config.location.path, "demo")
  guard config.location.mode is Init else { fail("expected init mode") }
}

///|
test "parse_cli_args init without path uses current dir" {
  let config = expect_project_request(["--init"])
  @test.assert_eq(config.location.path, ".")
  guard config.location.mode is Init else { fail("expected init mode") }
}

///|
test "parse_cli_args invalid option" {
  try parse_cli_args(["demo", "--oops"]) catch {
    CliError(_) => ()
  } noraise {
    _ => fail("expected parse failure")
  }
}

///|
test "parse_cli_args help is success" {
  guard parse_cli_args(["--help"]) is Help(TopLevelHelp) else {
    fail("expected help request")
  }
  let text = TopLevelHelp.text()
  guard text.contains("Usage: momoka") else {
    fail("expected top-level help text")
  }
}

///|
test "parse_cli_args preferences help is scoped to subcommand" {
  guard parse_cli_args(["cfg", "--help"]) is Help(PreferencesHelp) else {
    fail("expected preferences help request")
  }
  let text = PreferencesHelp.text()
  guard text.contains("Usage: momoka cfg") else {
    fail("expected preferences help text")
  }
  guard !text.contains("Arguments:\n  path") else {
    fail("preferences help should not show project positional arguments")
  }
}

///|
test "parse_cli_args preferences configure" {
  guard parse_cli_args(["cfg"]) is Preferences(Configure) else {
    fail("expected preferences configure request")
  }
}

///|
test "parse_cli_args preferences show" {
  guard parse_cli_args(["cfg", "--show"]) is Preferences(Show) else {
    fail("expected preferences show request")
  }
}

///|
test "PreferredConfig::parse key-values" {
  let preferred = PreferredConfig::parse(
    (
      #|username kokic
      #|license MIT
      #|host gitlab.com
      #|target js
    ),
  )
  @test.assert_eq(preferred.username, Some("kokic"))
  @test.assert_eq(preferred.license, Some("MIT"))
  @test.assert_eq(preferred.host, Some("gitlab.com"))
  @test.assert_eq(preferred.preferred_target, Some("js"))
}

///|
test "PreferredConfig::parse username compatibility" {
  @test.assert_eq(
    PreferredConfig::parse("username kokic").username,
    Some("kokic"),
  )
  @test.assert_eq(
    PreferredConfig::parse("username   mooner  ").username,
    Some("mooner"),
  )
  @test.assert_eq(PreferredConfig::parse("user kokic").username, None)
}

///|
test "preferred_config_to_content" {
  let preferred : PreferredConfig = {
    username: Some("kokic"),
    license: Some("MIT"),
    host: Some("gitlab.com"),
    preferred_target: Some("js"),
  }
  @test.assert_eq(
    preferred.to_content(),
    (
      #|username kokic
      #|license MIT
      #|host gitlab.com
      #|target js
    ),
  )
}

///|
async fn expect_directory(path : String) -> Unit {
  try @fs.kind(path) catch {
    err => fail("failed to inspect directory \{path}: \{@debug.to_repr(err)}")
  } noraise {
    Directory => ()
    _ => fail("expected directory: \{path}")
  }
}

///|
async fn expect_existing_path(path : String) -> Unit {
  guard path_exists(path) else { fail("expected path to exist: \{path}") }
}

///|
fn expect_cli_error_message(err : Error, expected : String) -> Unit raise Error {
  match err {
    CliError(message) =>
      if !message.contains(expected) {
        fail("expected error containing \{expected}, got: \{message}")
      }
    _ => raise err
  }
}

///|
async test "create_project creates missing project directory" {
  @async.with_task_group() <| group => {
    let base_path = @fs.tmpdir(prefix="momoka_create_project_test")
    group.add_defer(() => {
      try @fs.rmdir(base_path, recursive=true) catch {
        _ => ()
      } noraise {
        _ => ()
      }
    })
    let project_path = @path.Path::join(base_path, "demo").to_string()
    let config : CliConfig = {
      location: { path: project_path, mode: Create },
      overrides: { license: None, host: None, preferred_target: None },
    }
    let target = validate_project_target(config)
    let project_dir = bootstrap_project(
      target,
      config,
      "tester",
      PreferredConfig::empty(),
    )
    expect_directory(project_dir)
    expect_existing_path(@path.Path::join(project_dir, "moon.mod").to_string())
    expect_existing_path(@path.Path::join(project_dir, "moon.pkg").to_string())
    expect_existing_path(
      @path.Path::join(project_dir, ".gitignore").to_string(),
    )
  }
}

///|
async test "ensure_existing_dir rejects files" {
  @async.with_task_group() <| group => {
    let base_path = @fs.tmpdir(prefix="momoka_existing_file_test")
    let path = @path.Path::join(base_path, "file").to_string()
    group.add_defer(() => {
      try @fs.rmdir(base_path, recursive=true) catch {
        _ => ()
      } noraise {
        _ => ()
      }
    })
    @fs.write_file(path, "", create_mode=CreateOrTruncate)
    try ensure_existing_dir(path) catch {
      err => expect_cli_error_message(err, "path exists but is not a directory")
    } noraise {
      _ => fail("expected file path to be rejected")
    }
  }
}

///|
async test "run_project_request validates target before user preferences" {
  @async.with_task_group() <| group => {
    let base_path = @fs.tmpdir(prefix="momoka_existing_project_test")
    group.add_defer(() => {
      try @fs.rmdir(base_path, recursive=true) catch {
        _ => ()
      } noraise {
        _ => ()
      }
    })
    let config : CliConfig = {
      location: { path: base_path, mode: Create },
      overrides: { license: None, host: None, preferred_target: None },
    }
    try run_project_request(config) catch {
      err => expect_cli_error_message(err, "path already exists")
    } noraise {
      _ => fail("expected existing path to be rejected")
    }
  }
}

///|
async test "init_project does not overwrite existing project files" {
  @async.with_task_group() <| group => {
    let base_path = @fs.tmpdir(prefix="momoka_init_no_overwrite_test")
    group.add_defer(() => {
      try @fs.rmdir(base_path, recursive=true) catch {
        _ => ()
      } noraise {
        _ => ()
      }
    })
    let moon_mod_path = @path.Path::join(base_path, "moon.mod").to_string()
    @fs.write_file(moon_mod_path, "keep", create_mode=CreateOrTruncate)
    let config : CliConfig = {
      location: { path: base_path, mode: Init },
      overrides: { license: None, host: None, preferred_target: None },
    }
    let target = validate_project_target(config)
    try
      bootstrap_project(target, config, "tester", PreferredConfig::empty())
    catch {
      err => expect_cli_error_message(err, "file already exists")
    } noraise {
      _ => fail("expected existing project file to be rejected")
    }
    @test.assert_eq(@fs.read_file(moon_mod_path).text(), "keep")
  }
}
