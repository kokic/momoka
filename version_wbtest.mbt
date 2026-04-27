///|
async test {
  let moon_mod_json = @fs.read_file("./moon.mod.json").json()
  if moon_mod_json is { "version": String(version), .. } {
    assert_eq(version, VERSION)
  }
}
