// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IBankroll {
    function transferTokenPayout(
        address tokenAddress,
        address player,
        uint256 payout
    ) external;
}

    struct Bet {
        address player;
        uint256 wager;
        uint256 multipleBets;
        uint8 rows;
        uint8 risk;
    }

contract Plinko is ReentrancyGuard, VRFConsumerBaseV2, Ownable {
    using SafeERC20 for IERC20;
    IERC20 public token;
    IBankroll public bankroll;
    //properties for VRF
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 keyHash = "";
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    mapping(uint8 => mapping(uint8 => uint256[])) public plinkoMultipliers;
    mapping(uint256 => Bet) private games;

    error WagerAboveLimit(uint256 wager, uint256 maxWager);
    event Plinko_Play_Event(
        address indexed playerAddress,
        uint256 wager,
        uint256 totalWager,
        uint8 numRows,
        uint8 risk
    );

    event Ball_Landed_Event(
        address indexed playerAddress,
        uint256 ballNumber,
        uint256 landingPosition,
        uint256 multiplier
    );

    event Plinko_Payout_Event(
        address indexed playerAddress,
        uint256 wager,
        uint256 payout
    );


    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        IERC20 _token) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        token = _token;
    }
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        Bet memory game = games[requestId];
        uint256 payout = calculatePayout(game, randomWords[0]);
        makePayout(game, payout);
        delete games[requestId];
    }


    function getMultipliers(uint8 risk, uint8 numRows)
    external
    view
    returns (uint256[] memory multipliers)
    {
        return plinkoMultipliers[risk][numRows];
    }

    function setMultipliers(uint8 risk, uint8 numRows, uint256[] memory multipliers) external onlyOwner {
        plinkoMultipliers[risk][numRows] = multipliers;
    }

    function getBankroll() external view returns (address) {
        return address(bankroll);
    }

    function setBankroll(address _bankroll) external onlyOwner {
        bankroll = IBankroll(_bankroll);
    }

    function play(
        uint256 wager,
        uint8 risk,
        uint8 numRows,
        uint256 multipleBets
    ) external payable nonReentrant {
        address player = msg.sender;
        uint256 totalWager = wager * multipleBets;
        _kellyWager(totalWager, address(token));
        token.safeTransferFrom(player, address(bankroll), totalWager);
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        games[requestId] = Bet(player, wager, multipleBets, numRows, risk);
    }

    function calculatePayout(
        Bet memory game,
        uint256 randomNumber
    ) internal
    returns (uint256) {
        emit Plinko_Play_Event(game.player, game.wager, game.wager * game.multipleBets, game.rows, game.risk);
        uint256 payout = 0;
        uint256 position = 0;
        for (uint256 ballNumber = 0; ballNumber < game.multipleBets; ballNumber++) {
            position = 0;
            for (uint8 i = 0; i < game.rows; i++) {
                if (randomNumber & 1 != 0) {
                    position++;
                }
                randomNumber >> 1;
            }
            emit Ball_Landed_Event(game.player, ballNumber, position, plinkoMultipliers[game.risk][game.rows][position]);
            //multipliers are multiplied by 100 to avoid floating point numbers
            payout += game.wager * plinkoMultipliers[game.risk][game.rows][position] / 100;
        }

        return payout;
    }

    function makePayout(
        Bet memory game,
        uint256 payout
    ) internal {
        if (payout > 0) {
            bankroll.transferTokenPayout(address(token), game.player, payout);
        }
        emit Plinko_Payout_Event(game.player, game.wager, payout);
    }

    function _kellyWager(uint256 bet, address tokenAddress) internal view {
        uint256 balance;
        /// @dev check if the token is native or not
        if (tokenAddress == address(0)) {
            balance = address(bankroll).balance;
        } else {
            balance = token.balanceOf(address(bankroll));
        }
        uint256 maxBet = (balance * 1100000) / 100000000;
        if (bet > maxBet) {
            revert WagerAboveLimit(bet, maxBet);
        }
    }

}