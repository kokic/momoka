///|
fn file_content_moon_mod(
  username~ : String,
  module_name~ : String,
  license : String,
  repository_hosting : String,
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
    $|repository = "https://\{repository_hosting}/\{username}/\{module_name}"
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
test "file_content_moon_mod uses suffixless moon.mod format" {
  assert_eq(
    file_content_moon_mod(
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
fn file_content_moon_pkg() -> String {
  "import {}"
}

///|
fn file_content_gitignore() -> String {
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
