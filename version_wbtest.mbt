///|
async test {
  let moon_mod = @fs.read_file("./moon.mod").text()
  let version_line = "version = \"\{VERSION}\""
  let mut found = false
  for raw_line in moon_mod.split("\n") {
    if raw_line.trim().to_owned() == version_line {
      found = true
    }
  }
  assert_eq(found, true)
}
