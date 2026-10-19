///|
pub fn moon_mod_content(
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
    $|
  )
}

///|
pub fn moon_pkg_content() -> String {
  (
    #|import {
    #|}
  )
}

///|
pub fn gitignore_content() -> String {
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

///|
pub fn gitattributes_content() -> String {
  "* text=auto eol=lf"
}
