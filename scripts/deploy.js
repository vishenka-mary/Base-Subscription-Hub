const hre = require("hardhat");
async function main() {
  const SubFactory = await hre.ethers.getContractFactory("ZenithSubscriptionHub");
  const hub = await SubFactory.deploy();
  await hub.deployed();
  console.log("Subscription Engine live at:", hub.address);
}
main().catch((error) => console.error(error));
