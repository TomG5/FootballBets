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
    }
    
    Bet[] public bets;
    uint prizeAmount;
    
    mapping(address => bool) checkWinner;
    address[] public betWinners;
    
    uint individualPrize;
    mapping(address => bool) paidWinner;

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
            winner: false
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
        
        if(betWinners.length > 0) {
            individualPrize = prizeAmount / betWinners.length;
            prizeAmount = 0;
        }

        emit publishWinners(betWinners);
    }

    function withdrawPrize() public Halted {
        //  Allow the winners to withdraw their prize in case there are any
        require(betWinners.length > 0);
        require(checkWinner[msg.sender] == true, "This account didn't win.");
        require(paidWinner[msg.sender] == false, "You already collected your prize.");
        
        paidWinner[msg.sender] = true;
        payable(msg.sender).transfer(individualPrize);
    }
    
    function receiveContractProfit() public OnlyOwner Halted {
        //   Allow the contract owner to collect its profits from the match
    require(betWinners.length == 0, "There are winners in this bet.");
    
    manager.transfer(prizeAmount);

    betState = State.Closed;
    }
}