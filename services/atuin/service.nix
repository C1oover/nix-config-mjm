{
  ingress.virtualHosts.atuin = {
    upstream.service.name = "atuin";
    enableAuthProxy = false;
  };
}
