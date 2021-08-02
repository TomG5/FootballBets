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
	let newcontract = await FootballBets.at(contractAddress);

	/* Uncomment following lines to perform the tests (substituting the previous block), 
	since there is a limitation in Truffle for the deployment above not being recognized
	
	const owner = await BetGenerator.deployed().then(function(instance) {
		return instance.owner.call()
	});

	await deployer.deploy(FootballBets, owner, "BPL","MANUTD x CHELSEA");
	await FootballBets.deployed();*/
};