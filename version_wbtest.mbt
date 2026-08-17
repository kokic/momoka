///|
async test {
  let moon_mod = @fs.read_file("./moon.mod").text()
  let version_line = "version = \"\{VERSION}\""
  guard moon_mod.contains(version_line) else {
    fail("version line not found in moon.mod")
  }
}
