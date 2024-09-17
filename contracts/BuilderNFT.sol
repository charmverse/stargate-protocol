// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BuilderNFT is ERC1155, Ownable {

    uint256 public nextTokenId;
    address payable public proceedsReceiver;  // Global proceeds receiver
    uint256 public priceIncrement;            // Global price increment for all tokens - linear curve

    event BuilderTokenRegistered(uint256 tokenId);

    // Constructor accepts proceedsReceiver and priceIncrement
    constructor(string memory uri_, address payable _proceedsReceiver, uint256 _priceIncrement) ERC1155(uri_) Ownable(msg.sender) {
        require(_proceedsReceiver != address(0), "Invalid receiver address");
        require(_priceIncrement > 0, "Price increment must be greater than zero");

        proceedsReceiver = _proceedsReceiver;
        priceIncrement = _priceIncrement;
    }

    // Register a new builder token with an automatically assigned tokenId
    function registerBuilderToken() external onlyOwner {
        emit BuilderTokenRegistered(nextTokenId);
        nextTokenId++;
    }

    // Buy a specific builder's token based on bonding curve
    function buyToken(uint256 tokenId, uint256 amount) external payable {
        require(amount > 0, "Must buy at least one token");

        uint256 cost = getTokenPurchasePrice(tokenId, amount);

        require(msg.value == cost, "Incorrect ETH sent");

        // Mint the token to the buyer
        _mint(msg.sender, tokenId, amount, "");

        // Transfer the funds to the global proceeds receiver
        proceedsReceiver.transfer(msg.value);
    }

    // Update the global proceeds receiver address
    function updateProceedsReceiver(address payable newReceiver) external onlyOwner {
        require(newReceiver != address(0), "Invalid address");
        proceedsReceiver = newReceiver;
    }

    // Calculate the cost of the tokens using a simple linear bonding curve
    function getNextPrice(uint256 currentSupply) public view returns (uint256) {
        uint256 totalCost = (currentSupply + 1) * priceIncrement; // Linear bonding curve
        return totalCost;
    }

    // Calculate the total price for a batch of tokens based on bonding curve pricing
    function getTokenPurchasePrice(uint256 tokenId, uint256 amount) public view returns (uint256) {
        uint256 currentSupply = totalSupply(tokenId);  // Use totalSupply from ERC1155
        uint256 totalCost = 0;
        for (uint256 i = 0; i < amount; i++) {
            totalCost += getNextPrice(currentSupply + i);
        }
        return totalCost;
    }

    // Use totalSupply from ERC1155 to track how many tokens exist for a specific tokenId
    function totalSupply(uint256 tokenId) public view returns (uint256) {
        return balanceOf(address(this), tokenId);  // This checks how many tokens exist (minted)
    }
}