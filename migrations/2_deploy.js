const path = require('path');
const fs = require('fs-extra');

const buildPath = path.resolve(__dirname, 'build');
fs.removeSync(buildPath);

const BetGenerator = artifacts.require("BetGenerator");
const FootballBets = artifacts.require("FootballBets");

module.exports = async function(deployer) {
	// Deploy the contracts
	await deployer.deploy(BetGenerator);

	await BetGenerator.deployed().then(function(instance) {
		return instance.generator("BPL","MANUTD x CHELSEA")
	});
	
	const contractAddress = await BetGenerator.deployed().then(function(instance) {
		return instance.lastContract.call()
	});
	
	await FootballBets.at(contractAddress);

	/*let owner = await BetGenerator.deployed().then(function(instance) {
		return instance.owner.call()});

	await deployer.deploy(FootballBets, owner, "BPL","MANUTD x CHELSEA");
	await FootballBets.deployed();*/
};