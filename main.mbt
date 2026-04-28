///|
async fn main {
  match @env.args() {
    [_, .. args] =>
      match run(args) {
        Ok(message) => println(message)
        Err(err) => {
          println(err)
          @sys.exit(1)
        }
      }
    [] => {
      println(usage_text())
      @sys.exit(0)
    }
  }
}

///|
async fn run(args : ArrayView[String]) -> Result[String, String] {
  match parse_cli_args(args) {
    Ok(request) => handle_cli_request(request)
    Err(err) => Err(err)
  }
}

///|
async fn handle_cli_request(request : CliRequest) -> Result[String, String] {
  match request {
    Project(config) => run_project_request(config)
    Preferences(Configure) => configure_preferred_defaults()
    Preferences(Show) => show_preferred_defaults()
  }
}

///|
async fn run_project_request(config : CliConfig) -> Result[String, String] {
  match ensure_username() {
    Ok(username) => {
      let preferred = match home_dir() {
        Some(home) => load_preferred_config(preferred_file_path(home))
        None => empty_preferred_config()
      }
      let result = if config.initialize_existing {
        init_project(config, username, preferred)
      } else {
        create_project(config, username, preferred)
      }
      match result {
        Ok(project_dir) => {
          let action = if config.initialize_existing {
            "initialized"
          } else {
            "created and initialized"
          }
          Ok(
            "\{action} moon.mod.json, moon.pkg and .gitignore in \{project_dir}",
          )
        }
        Err(err) => Err(err)
      }
    }
    Err(err) => Err(err)
  }
}
