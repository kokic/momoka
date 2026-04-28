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
async test "module_name from resolved path basename" {
  let project_dir = @fs.realpath("example_project").to_string()
  assert_eq(module_name_from_project_dir(project_dir), "example_project")
}
