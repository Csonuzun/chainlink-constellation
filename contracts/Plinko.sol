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