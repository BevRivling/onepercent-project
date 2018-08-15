var PaymentPipe = artifacts.require("PaymentPipe");
var ExternalContractExample = artifacts.require('ExternalContractExample');
var ConvertLib = artifacts.require("ConvertLib");
var OPCToken = artifacts.require("OPCToken");
var AccessControl = artifacts.require("AccessControl");
var StandardToken = artifacts.require("StandardToken");

module.exports = function(deployer) {
  deployer.deploy(AccessControl);
  deployer.deploy(StandardToken);

  deployer.deploy(OPCToken).then(function() {
    return deployer.deploy(PaymentPipe, OPCToken.address)
  });

  deployer.deploy(ExternalContractExample);
  deployer.deploy(ConvertLib)
  deployer.link(ConvertLib, [PaymentPipe]);
};
