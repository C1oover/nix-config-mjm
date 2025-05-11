{
  microvm.vms.charizard = {
    config = {
      mjm.vault.enable = true;
      mjm.vault.encryptedUnsealTokens = [
        ''
          Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAAdsLOZ2ZFiYZN0XU8AAAAAEpRFRqw3McTyf7x
          rXPn6Dv4SokbTBWQ3yx02yZXOyArY6653La1YsbTZTa6DT41K+/M28B0uLHUceGAPINmhuoIOvC0pbc
          JAy2Xvq4IYTu9FBtGstJhJ8SjyMdw=
        ''
        ''
          Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAABrzMH4oz+RtQLQbQYAAAAAjLuXezykJgOgNlu
          m/3V/ZCsW3c3w4/zloP4cWYCfn3l5/oFF1aNpH1Rcr4/utNMUjyEfEO9R4P2DNRb4sePxhouc3aL+uP
          BodHa+8YVoA7/JToLYFYZYFWRyuig=
        ''
      ];

      mjm.profiles.microvm = {
        enable = true;
        macAddress = "02:14:FA:BA:5C:EE";
        machineId = "ac0eae02dc9736531b8ab69d6820a942";
      };
      microvm.mem = 1024;
      system.stateVersion = "25.05";
    };
  };
}
