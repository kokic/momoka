///|
async test {
  let moon_mod = @fs.read_file("./moon.mod").text()
  let version_line = "version = \"\{VERSION}\""
  for raw_line in moon_mod.split("\n") {
    guard raw_line.trim().to_owned() == version_line else { continue }
    return
  }
  fail("version line not found in moon.mod")
}
