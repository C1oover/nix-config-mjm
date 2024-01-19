nom build ".#darwinConfigurations.$(scutil --get LocalHostName).system"
nvd diff /run/current-system ./result
