///|
async fn run_install_request(
  process~ : async () -> Int raise Error,
) -> Unit raise CliError {
  let status = process() catch {
    err => raise CliError("failed to run the MoonBit installer: \{err}")
  }
  guard status == 0 else {
    raise CliError("MoonBit installation failed with exit code \{status}")
  }
}

///|
async fn install_stable() -> Int raise Error {
  // curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash
  @process.run("bash", [
    "-o", "pipefail", "-c", "curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash",
  ])
}

///|
#cfg(platform="windows")
async fn install_stable() -> Int raise Error {
  // Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm https://cli.moonbitlang.cn/install/powershell.ps1 | iex
  @process.run("powershell", [
    "-NoProfile", "-Command", "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm https://cli.moonbitlang.cn/install/powershell.ps1 | iex",
  ])
}

///|
async fn install_nightly() -> Int raise Error {
  // curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash -s nightly
  @process.run("bash", [
    "-o", "pipefail", "-c", "curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash -s nightly",
  ])
}

///|
#cfg(platform="windows")
async fn install_nightly() -> Int raise Error {
  // Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; $env:MOONBIT_INSTALL_VERSION="nightly"; irm https://cli.moonbitlang.cn/install/powershell.ps1 | iex
  @process.run("powershell", [
    "-NoProfile",
    "-Command",
    (
      #|Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; $env:MOONBIT_INSTALL_VERSION="nightly"; irm https://cli.moonbitlang.cn/install/powershell.ps1 | iex
    ),
  ])
}
