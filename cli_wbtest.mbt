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
  assert_eq(config.path, "demo")
  guard config.mode is Create else { fail("expected create mode") }
  @test.assert_eq(config.license, None)
  @test.assert_eq(config.repository_hosting, None)
  @test.assert_eq(config.preferred_target, None)
}

///|
test "parse_cli_args optional flags" {
  let config = expect_project_request([
    "demo", "-l", "MIT", "--host", "gitlab.com", "-t", "js",
  ])
  assert_eq(config.path, "demo")
  guard config.mode is Create else { fail("expected create mode") }
  @test.assert_eq(config.license, Some("MIT"))
  @test.assert_eq(config.repository_hosting, Some("gitlab.com"))
  @test.assert_eq(config.preferred_target, Some("js"))
}

///|
test "parse_cli_args init flag long" {
  let config = expect_project_request(["--init", "demo"])
  assert_eq(config.path, "demo")
  guard config.mode is Init else { fail("expected init mode") }
}

///|
test "parse_cli_args init flag short" {
  let config = expect_project_request(["demo", "-i"])
  assert_eq(config.path, "demo")
  guard config.mode is Init else { fail("expected init mode") }
}

///|
test "parse_cli_args init without path uses current dir" {
  let config = expect_project_request(["--init"])
  assert_eq(config.path, ".")
  guard config.mode is Init else { fail("expected init mode") }
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
  let text = help_text(TopLevelHelp)
  guard text.contains("Usage: momoka") else {
    fail("expected top-level help text")
  }
}

///|
test "parse_cli_args preferences help is scoped to subcommand" {
  guard parse_cli_args(["cfg", "--help"]) is Help(PreferencesHelp) else {
    fail("expected preferences help request")
  }
  let text = help_text(PreferencesHelp)
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
test "parse_preferred_config key-values" {
  let preferred = parse_preferred_config(
    (
      #|username kokic
      #|license MIT
      #|host gitlab.com
      #|target js
    ),
  )
  @test.assert_eq(preferred.username, Some("kokic"))
  @test.assert_eq(preferred.license, Some("MIT"))
  @test.assert_eq(preferred.repository_hosting, Some("gitlab.com"))
  @test.assert_eq(preferred.preferred_target, Some("js"))
}

///|
test "parse_preferred_config username compatibility" {
  @test.assert_eq(
    parse_preferred_config("username kokic").username,
    Some("kokic"),
  )
  @test.assert_eq(
    parse_preferred_config("username   mooner  ").username,
    Some("mooner"),
  )
  @test.assert_eq(parse_preferred_config("user kokic").username, None)
}

///|
test "preferred_config_to_content" {
  let preferred : PreferredConfig = {
    username: Some("kokic"),
    license: Some("MIT"),
    repository_hosting: Some("gitlab.com"),
    preferred_target: Some("js"),
  }
  assert_eq(
    preferred_config_to_content(preferred),
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
  match path_exists(path) {
    true => ()
    false => fail("expected path to exist: \{path}")
  }
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
      path: project_path,
      license: None,
      repository_hosting: None,
      preferred_target: None,
      mode: Create,
    }
    let target = validate_project_target(config)
    let project_dir = write_project_to_target(
      target,
      config,
      "tester",
      empty_preferred_config(),
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
      path: base_path,
      license: None,
      repository_hosting: None,
      preferred_target: None,
      mode: Create,
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
      path: base_path,
      license: None,
      repository_hosting: None,
      preferred_target: None,
      mode: Init,
    }
    let target = validate_project_target(config)
    try
      write_project_to_target(
        target,
        config,
        "tester",
        empty_preferred_config(),
      )
    catch {
      err => expect_cli_error_message(err, "file already exists")
    } noraise {
      _ => fail("expected existing project file to be rejected")
    }
    assert_eq(@fs.read_file(moon_mod_path).text(), "keep")
  }
}
