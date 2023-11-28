// SPDX-License-Identifier: GPL-3.0
/// @author Candas Sonuzun
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Bankroll is Ownable {
    using SafeERC20 for IERC20;

    // Stores whether a game contract is allowed to access the bankroll
    mapping(address => bool) public isGame;

    // Stores whether a token is allowed to be wagered
    mapping(address => bool) public isTokenAllowed;

    // Event emitted when game state is changed
    event GameStateChanged(address game, bool isActive);

    // Event emitted when token state is changed
    event TokenStateChanged(address token, bool isAllowed);

    function setGame(address game, bool isActive) external onlyOwner {
        isGame[game] = isActive;
        emit GameStateChanged(game, isActive);
    }

    function setToken(address token, bool isAllowed) external onlyOwner {
        isTokenAllowed[token] = isAllowed;
        emit TokenStateChanged(token, isAllowed);
    }

    //getter function for token
    function isToken(address token) external view returns (bool) {
        return isTokenAllowed[token];
    }

    receive() external payable {}

    function withdrawFunds(
        address payable to,
        uint256 amount
    ) external onlyOwner {
        require(address(this).balance >= amount, "Not enough balance.");
        to.transfer(amount);
    }

    function withdrawTokens(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Not enough balance.");
        token.safeTransfer(to, amount);
    }

    function transferTokenPayout(
        address tokenAddress,
        address player,
        uint256 payout
    ) external {
        require(isGame[msg.sender], "Not authorized.");
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= payout, "Not enough balance.");
        token.safeTransfer(player, payout);
    }
}