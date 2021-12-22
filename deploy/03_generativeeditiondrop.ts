module.exports = async ({ getNamedAccounts, deployments }: any) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const testBaseAddress = (await deployments.get("TestBase")).address;
  const sharedNFTLogicAddress = (await deployments.get("SharedNFTLogic"))
    .address;

  await deploy("OnChainGenerativeEditionDrop", {
    from: deployer,
    args: [testBaseAddress, sharedNFTLogicAddress, 100],
    log: true,
  });
};
module.exports.tags = ["OnChainGenerativeEditionDrop"];
module.exports.dependencies = ["SharedNFTLogic", "TestBase"];
