{ databases }:
let
  mkDbConfig = db: ''
    {{ with secret "database/creds/${db.name}" }}
    '${db.name}' => array(
      'driver' => 'pgsql',
      'server' => 'postgresql.service.consul',
      'username' => {{ .Data.username | toJSON }},
      'password' => {{ .Data.password | toJSON }},
      'db' => '${db.name}',
    ),
    {{ end }}
  '';

  configs = builtins.concatStringsSep "\n" (map mkDbConfig (builtins.attrValues databases));
in
''
  <?php

  class AdminerCustom {
      var $servers;

      function __construct($servers) {
          $this->servers = $servers;
          if ($_POST["auth"]) {
              $key = $_POST["auth"]["server"];
              $_POST["auth"]["driver"] = $this->servers[$key]["driver"];
              $_POST["auth"]["db"] = $this->servers[$key]["db"];
          }
      }

      function credentials() {
          $config = $this->servers[SERVER];
          return array($config["server"], $config["username"], $config["password"]);
      }

      function login($login, $password) {
          return true;
      }

  	function loginFormField($name, $heading, $value) {
  		if ($name == 'driver' || $name == 'username' || $name == 'password' || $name == 'db') {
  			return "";
  		} elseif ($name == 'server') {
  			return $heading . "<select name='auth[server]'>" . optionlist(array_keys($this->servers), SERVER) . "</select>\n";
  		}
  	}
  }

  return new AdminerCustom(array(
  ${configs}
  ));
''
