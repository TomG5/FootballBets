const BetGenerator = artifacts.require("BetGenerator");
const FootballBets = artifacts.require("FootballBets");

contract('BetGenerator', () => {  
    it('Generates a new instance of the Betting contract', async () => {    
        const generatorInstance = await BetGenerator.deployed();
            
        let contractGenerated = await generatorInstance.lastContract.call();
        console.log('\n', contractGenerated);
        
        assert(toString(contractGenerated) != "");
    });
});

contract('FootballBets', (accounts) => {
    it('Registers the match generated', async () => {
        const generatorInstance = await FootballBets.deployed();
        
        let myMatch = await generatorInstance.matchDispute.call();
        console.log('\n', myMatch);

        assert(myMatch != "");
    });

    it('Validates sender and value of a new bet before accepting it', async () => {
        const generatorInstance = await FootballBets.deployed();

        try {
            let newBet = await generatorInstance.newBets.sendTransaction('1:1', {
                from: accounts[1], value: '100'
            });
        } catch(err) {
            assert(err);
            //console.log(err); Checks if the right error is called
        }
    });

    it('Finalizes the bet with winners and allows them to collect their prize', async () => {
        const generatorInstance = await FootballBets.deployed();

        await generatorInstance.newBets.sendTransaction('1:1', {
            from: accounts[1], value: '1000000000000000'
        });

        await generatorInstance.newBets.sendTransaction('2:1', {
            from: accounts[2], value: '1000000000000000'
        });
        let winnerInitialBalance = await web3.eth.getBalance(accounts[2]);

        await generatorInstance.newBets.sendTransaction('3:1', {
            from: accounts[3], value: '1000000000000000'
        });

        await generatorInstance.haltBets.sendTransaction({
            from: accounts[0]
        });
        
        await generatorInstance.finalizeBetOption.sendTransaction('2:1', {
            from: accounts[0]
        });

        await generatorInstance.withdrawPrize.sendTransaction({
            from: accounts[2]
        });

        let winnerFinalBalance = await web3.eth.getBalance(accounts[2]);

        assert(winnerFinalBalance = (winnerInitialBalance + 3000000000000000), "Winner didn't receive the prize");
    });
});

contract('FootballBets - Part2', (accounts) => {
    it('Finalizes the bet without winners and allows the manager to collect its profits', async () => {    
        const generatorInstance = await FootballBets.deployed();

        let managerInitialBalance = await web3.eth.getBalance(accounts[0]);

        await generatorInstance.newBets.sendTransaction('1:1', {
            from: accounts[4], value: '1000000000000000'
        });
        
        await generatorInstance.newBets.sendTransaction('2:1', {
            from: accounts[5], value: '1000000000000000'
        });

        await generatorInstance.haltBets.sendTransaction({
            from: accounts[0]
        });
        
        await generatorInstance.finalizeBetOption.sendTransaction('4:1', {
            from: accounts[0]
        });

        await generatorInstance.receiveContractProfit.sendTransaction({
            from: accounts[0]
        });

        let managerFinalBalance = await web3.eth.getBalance(accounts[0]);

        assert(managerFinalBalance > managerInitialBalance, "Manager didn't receive the prize");
    });
});