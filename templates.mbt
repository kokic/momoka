///|
fn moon_mod_content(
  username~ : String,
  module_name~ : String,
  license : String,
  host : String,
  preferred_target : String,
) -> String {
  (
    $|name = "\{username}/\{module_name}"
    $|
    $|version = "0.1.0"
    $|
    $|import {}
    $|
    $|readme = "README.md"
    $|
    $|repository = "https://\{host}/\{username}/\{module_name}"
    $|
    $|license = "\{license}"
    $|
    $|keywords = []
    $|
    $|description = ""
    $|
    $|preferred_target = "\{preferred_target}"
  )
}

///|
test "moon_mod_content uses suffixless moon.mod format" {
  @test.assert_eq(
    moon_mod_content(
      username="kokic",
      module_name="demo",
      "MIT",
      "gitlab.com",
      "js",
    ),
    (
      #|name = "kokic/demo"
      #|
      #|version = "0.1.0"
      #|
      #|import {}
      #|
      #|readme = "README.md"
      #|
      #|repository = "https://gitlab.com/kokic/demo"
      #|
      #|license = "MIT"
      #|
      #|keywords = []
      #|
      #|description = ""
      #|
      #|preferred_target = "js"
    ),
  )
}

///|
fn moon_pkg_content() -> String {
  "import {}"
}

///|
fn gitignore_content() -> String {
  (
    #|.DS_Store
    #|_build/
    #|target/
    #|.mooncakes/
    #|.moonagent/
    #|.local/
    #|*.mbti
  )
}
