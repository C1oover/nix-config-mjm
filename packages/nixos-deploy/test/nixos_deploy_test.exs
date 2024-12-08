defmodule NixosDeployTest do
  use ExUnit.Case
  doctest NixosDeploy

  test "greets the world" do
    assert NixosDeploy.hello() == :world
  end
end
