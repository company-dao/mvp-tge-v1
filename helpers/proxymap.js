const fs = require("fs");

const filename = "./contract_proxy_address_map.json";

const getProxyAddress = (contractName) => {
  const addresses = JSON.parse(fs.readFileSync(filename));
  return addresses[contractName] ? addresses[contractName] : "";
};

const setProxyAddress = (contractName, proxyAddress) => {
  let addresses = JSON.parse(fs.readFileSync(filename));

  addresses[contractName] = proxyAddress;

  fs.writeFileSync(filename, JSON.stringify(addresses), function (err) {
    if (err) throw err;
  });
};

module.exports = {
  getProxyAddress,
  setProxyAddress,
};
