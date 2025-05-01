{
  microvm.vms.blastoise = {
    config = {
      mjm.vault.enable = true;
      mjm.vault.encryptedUnsealTokens = [
        ''
          Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAA6dZSyXU0iaDcTaCAAAAAA/tucfRUPULh2vni
          kDKXjxR9vbE7SRHo5Z0rCgy1X3bdB6lnyGygkguTfKd8xXF1Zj0XJxFhaDpJp8kdmms/Q+aUNQBzse7
          2nVEyY3sLUN9gzBDtPAWmYR8iW68Q=
        ''
        ''
          Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAAMfaZEUqNlOB491p8AAAAAPWsyGXSW1VXtZ6Q
          YNbM6tBWeUrV1Tm21H0JJBg1/51n8w7Po6/A0d5Y9aZ/J5y0bdZQ6B7SRj1KirR24sfpSrNCMhF7pSN
          0p+NRau4j9suTSeu4UTCz/gcUgXF0=
        ''
      ];

      mjm.profiles.microvm = {
        enable = true;
        macAddress = "02:69:F6:0B:23:DF";
        machineId = "0e56639a3fa56ec53823463268140748";
      };
      microvm.mem = 1024;
      system.stateVersion = "25.05";
    };
  };
}
