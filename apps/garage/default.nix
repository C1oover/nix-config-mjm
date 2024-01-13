{
  terraform.terraform.required_providers.garage = {
    source = "registry.terraform.io/prologin/garage";
    version = ">= 0.0.1";
  };
  terraform.provider.garage = {
    host = "garage.service.consul:3903";
    scheme = "http";
  };
}
