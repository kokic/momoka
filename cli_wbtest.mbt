///|
fn expect_project_request(args : ArrayView[String]) -> CliConfig {
  guard parse_cli_args(args) is Ok(Project(config)) else {
    abort("expected project request")
  }
  config
}

///|
test "parse_cli_args defaults" {
  let config = expect_project_request(["demo"])
  assert_eq(config.path, "demo")
  assert_eq(config.initialize_existing, false)
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
  assert_eq(config.initialize_existing, false)
  @test.assert_eq(config.license, Some("MIT"))
  @test.assert_eq(config.repository_hosting, Some("gitlab.com"))
  @test.assert_eq(config.preferred_target, Some("js"))
}

///|
test "parse_cli_args init flag long" {
  let config = expect_project_request(["--init", "demo"])
  assert_eq(config.path, "demo")
  assert_eq(config.initialize_existing, true)
}

///|
test "parse_cli_args init flag short" {
  let config = expect_project_request(["demo", "-i"])
  assert_eq(config.path, "demo")
  assert_eq(config.initialize_existing, true)
}

///|
test "parse_cli_args init without path uses current dir" {
  let config = expect_project_request(["--init"])
  assert_eq(config.path, ".")
  assert_eq(config.initialize_existing, true)
}

///|
test "parse_cli_args invalid option" {
  guard parse_cli_args(["demo", "--oops"]) is Err(_) else {
    fail("expected parse failure")
  }
}

///|
test "parse_cli_args help is success" {
  guard parse_cli_args(["--help"]) is Ok(Help) else {
    fail("expected help request")
  }
}

///|
test "parse_cli_args preferences configure" {
  guard parse_cli_args(["cfg"]) is Ok(Preferences(Configure)) else {
    fail("expected preferences configure request")
  }
}

///|
test "parse_cli_args preferences show" {
  guard parse_cli_args(["cfg", "--show"]) is Ok(Preferences(Show)) else {
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
    Ok(true) => ()
    Ok(false) => fail("expected path to exist: \{path}")
    Err(err) => fail(err)
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
      initialize_existing: false,
    }
    match create_project(config, "tester", empty_preferred_config()) {
      Ok(project_dir) => {
        expect_directory(project_dir)
        expect_existing_path(
          @path.Path::join(project_dir, "moon.mod").to_string(),
        )
        expect_existing_path(
          @path.Path::join(project_dir, "moon.pkg").to_string(),
        )
        expect_existing_path(
          @path.Path::join(project_dir, ".gitignore").to_string(),
        )
      }
      Err(err) => fail(err)
    }
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
    guard ensure_existing_dir(path) is Err(_) else {
      fail("expected file path to be rejected")
    }
  }
}
