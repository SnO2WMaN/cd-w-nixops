{nixpkgs, ...}: let
  region = "us-west-1";
in {
  inherit nixpkgs;

  network = {
    description = "aws-test";

    storage.hercules-ci.stateName = "nixops-default.json";
    lock.hercules-ci.stateName = "nixops-default.json";
  };

  defaults = {...}: {
    documentation.enable = false;
    deployment.ec2.region = region;
  };

  resources.ec2KeyPairs.keypair = {
    inherit region;
  };

  resources.ec2SecurityGroups.ssh = {resources, ...}: {
    inherit region;
    rules = [
      {
        fromPort = 22;
        toPort = 22;
        sourceIp = "0.0.0.0/0";
      }
    ];
  };

  resources.ec2SecurityGroups.http = {resources, ...}: {
    inherit region;
    rules = [
      {
        fromPort = 80;
        toPort = 80;
        sourceIp = "0.0.0.0/0";
      }
      {
        fromPort = 443;
        toPort = 443;
        sourceIp = "0.0.0.0/0";
      }
    ];
  };

  webserver = {
    config,
    resources,
    pkgs,
    ...
  }: {
    deployment.targetEnv = "ec2";
    deployment.ec2 = {
      instanceType = "t3.micro";
      region = "us-west-1";
      keyPair = resources.ec2KeyPairs.keypair;
      securityGroups = [
        resources.ec2SecurityGroups.ssh
        resources.ec2SecurityGroups.http
      ];
    };

    networking.firewall.allowedTCPPorts = [80 443];

    services.nginx = {
      enable = true;
    };
  };
}
