var FundRaising = artifacts.require("./fundraising.sol");

module.exports = function(deployer) {
  deployer.deploy(FundRaising);
};
