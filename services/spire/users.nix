{ lib, config, ... }:
{
  mjm.authelia.oidcClients = {
    spiffe-users = {
      name = "SPIFFE Users";
      clientId = "m4RNNya9wJOCANGmxhQdA43EhjyZhwpXdQTo4SiBib7lXiaRrPgaJlvwo75vbhDG";
      clientSecret = "$argon2id$v=19$m=65536,t=3,p=4$kL20/7gxED5DAY/C4BQoLQ$Nkuwy9RefKkbK8nDzTljr46RXUHXw8Ltn7AX+TrKDjE";
      redirectUris = [ "https://spiffe-users.midna.dev/callback" ];
    };
    spiffe-users-dev = {
      name = "SPIFFE Users (Dev)";
      clientId = "KgTTscl9NQvJwVms9Kaa0QTVGs3OwPM0zAdCjUMtB84jQo1U31uN1a2oab84W3u7";
      clientSecret = "$argon2id$v=19$m=65536,t=3,p=4$RGuPV5gAOG/zvkpcwqzQ3w$i9qPVGuf3SQ3VAhZx8eg3RbuUPZg6dkcIoXuvbGzuY0";
      redirectUris = [ "http://localhost:8080/callback" ];
    };
  };
}
