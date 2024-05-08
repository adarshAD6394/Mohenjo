const fs = require("fs")
const storeData = artifacts.require("storeData");

module.exports = async function (deployer) {
 await deployer.deploy(storeData, {gas : 4000000});
 const instance = await storeData.deployed();
 let storeDataAddress = await instance.address;
 let config = "export const storeData" + storeDataAddress;
 console.log("storeDataAddress = " + storeDataAddress);
 let data = JSON.stringify(config);
 fs.writeFileSync("config.js", JSON.parse(data));
};
