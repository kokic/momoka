///|
fn file_content_moon_mod_json(
  username~ : String,
  module_name~ : String,
  license : String,
  repository_hosting : String,
  preferred_target : String,
) -> String {
  (
    #|{
    $|  "name": "\{username}/\{module_name}",
    #|  "version": "0.1.0",
    #|  "deps": {},
    $|  "repository": "https://\{repository_hosting}/\{username}/\{module_name}",
    $|  "license": "\{license}",
    #|  "keywords": [],
    #|  "readme": "README.md",
    #|  "description": "",
    $|  "preferred-target": "\{preferred_target}"
    #|}
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
  )
}
