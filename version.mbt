///|
/// Also see: moon.mod - `version`
pub const VERSION = "0.6.1"

///|
async test {
  let moon_mod = @fs.read_file("./moon.mod").text()
  let version_line = "version = \"\{VERSION}\""
  guard moon_mod.contains(version_line) else {
    fail("version \{VERSION} was not found in the moon.mod file")
  }
}
