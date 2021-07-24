// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract BetGenerator {
    address public owner;
    FootballBets public lastContract;
    
    constructor() {
        owner = msg.sender;
    }

    event newBetOption(FootballBets indexed);

    function generator(string memory _league, string memory _match) public {     
        FootballBets newBetContract = new FootballBets(owner, _league, _match);
        lastContract = newBetContract;
        emit newBetOption(newBetContract);
    }
}

contract FootballBets {
    address payable public manager;
    
    uint constant public betValue = 0.001 ether;

    enum State {Open, Halted, Closed}
    State public betState;
    
    string public matchDispute;
    string public matchResult;
    
    struct Bet {
        string betScore;
        uint betAmount;
        address better;
        bool winner;
        bool paid;
    }
    
    Bet[] public bets;
    uint prizeAmount;
    
    mapping(address => bool) checkWinner;
    uint[] winningBetsIds;
    address[] public betWinners;

    constructor(address _manager, string memory _league, string memory _match) {
        manager = payable(_manager);
        matchDispute = string(abi.encodePacked(_league, " - ", _match));
    }

    modifier OnlyOwner {
        require(msg.sender == manager);
        _;
    }
    
    modifier Open {
        require(betState == State.Open);
        _;
    }

    modifier Halted {
        require(betState == State.Halted);
        _;
    }

    event newBetMade(address indexed sender, string score);

    function newBets(string memory _betScore) public payable Open {
        require(msg.sender != manager, "You are the manager, can't participate.");
        require(msg.value == betValue, "You didn't reach the established bet value.");
        
        Bet memory newBet = Bet({
            betScore: _betScore,
            betAmount: msg.value,
            better: msg.sender,
            winner: false,
            paid: false
        });
        
        bets.push(newBet);
        prizeAmount += newBet.betAmount;

        emit newBetMade(msg.sender, _betScore);
    }
    
    function haltBets() public OnlyOwner Open {
        betState = State.Halted;
    }

    function checkPrizeAmount() public view returns(uint) {
        return prizeAmount;
    }

    event publishWinners(address[] indexed);

    function finalizeBetOption(string memory _matchScore) public OnlyOwner Halted {
        //  Registering the football match result
        
        matchResult = _matchScore;
        
        //  Checking who got the right score and count amount of winners
        
        for (uint i = 0; i < bets.length; i++) {
            if(keccak256(bytes(bets[i].betScore)) == keccak256(bytes(matchResult))) {
                bets[i].winner = true;
                winningBetsIds.push(i);

                if(checkWinner[bets[i].better] == false) { 
                    checkWinner[bets[i].better] = true;
                    betWinners.push(bets[i].better);

                } else {
                    continue;
                }

            } else {
                continue;
            }
        }
        
        emit publishWinners(betWinners);

        //  Paying the winners in case there are any or sending the amount of bets to the contract owner
        
        if(betWinners.length > 0) {

            uint individualPrize;
            individualPrize = prizeAmount / betWinners.length;
            prizeAmount = 0;
                                
            for (uint i = 0; i < winningBetsIds.length; i++) {
                if(bets[winningBetsIds[i]].paid == false) {
                    bets[winningBetsIds[i]].paid = true;
                    payable(betWinners[i]).transfer(individualPrize);
                
                } else {
                    continue;
                }
            }
            
        } else {
            uint earnings = prizeAmount;
            prizeAmount = 0;
            manager.transfer(earnings);
        }
        
        betState = State.Closed;
    }
}