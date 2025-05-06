{
  microvm.vms.venusaur = {
    config = {
      mjm.vault.enable = true;
      mjm.vault.encryptedUnsealTokens = [
        ''
          Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAABlmC6N7BbfY/6HakUAAAAALphHtTYDU/P/SaO
          1g8iSozYqzzYhbu1GIOfxd++iwi+gEskuY4dY6p7jPLeJXWpUyQu9Cnm/bq+GT5SLNyO1+rJRt7OwiI
          UXSxR8YiR/eB9fej4Dt9ywSPkZ2tw=
        ''
        ''
          Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAABaf7tgqJuITSXQHl8AAAAAVSS9kfSgejsq2ad
          Fkd/s4j8K0Q6rgRlQGq7QmiPwpmmKLP6HU8F2mPuTeojTvusQo4dA92HvAXInQniXOd0bc0WB0kBhyN
          DyNnhnrR0wExYUJqNxz77+UWzNh1Y=
        ''
      ];

      mjm.profiles.microvm = {
        enable = true;
        macAddress = "02:7C:56:59:0D:BE";
        machineId = "b64e256cfe63b5cb7647b557681970ae";
      };
      microvm.mem = 1024;
      system.stateVersion = "25.05";
    };
  };
}
