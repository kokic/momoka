///|
async test {
  let moon_mod = @fs.read_file("./moon.mod").text() catch {
    err => fail("failed to read ./moon.mod: \{Repr(err)}")
  }
  let version_line = "version = \"\{@core.VERSION}\""
  guard moon_mod.contains(version_line) else {
    fail("version \{@core.VERSION} was not found in the moon.mod file")
  }
}
