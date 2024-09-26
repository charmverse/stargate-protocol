// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BuilderNFTUtils.sol"; // Import the utility contract

contract BuilderNFT is ERC1155, Ownable {
    using SafeERC20 for IERC20;

    uint256 public nextTokenId;
    address public proceedsReceiver;   // Global proceeds receiver
    uint256 public priceIncrement;     // Global price increment for all tokens - linear curve
    IERC20 public usdcToken;           // ERC20 token (USDC)
    BuilderUtils public utils;         // Utility contract reference

    event BuilderTokenRegistered(uint256 tokenId, string uuid);
    event BuilderScouted(uint256 tokenId, uint256 amount, string scoutId);

    mapping(uint256 => string) private tokenToBuilderRegistry;
    mapping(string => uint256) private builderToTokenRegistry;
    mapping(uint256 => uint256) private _totalSupply;

    string public baseUrl = "cdn.scoutgame.com/nft/";

    // Constructor to initialize proceedsReceiver, priceIncrement, USDC token, and the utility contract
    constructor( address _proceedsReceiver, uint256 _priceIncrement, address _usdcToken, address _utils) ERC1155(baseUrl) Ownable(msg.sender) {
        require(_proceedsReceiver != address(0), "Invalid receiver address");
        require(_priceIncrement > 0, "Price increment must be greater than zero");
        require(_usdcToken != address(0), "Invalid USDC address");
        require(_utils != address(0), "Invalid utility contract address");

        proceedsReceiver = _proceedsReceiver;
        priceIncrement = _priceIncrement;
        usdcToken = IERC20(_usdcToken);
        utils = BuilderUtils(_utils);  // Set the utility contract
        nextTokenId = 1;
    }

    // Buy token using USDC
    function mintBuilderNft(uint256 tokenId, uint256 amount, string calldata scout) external {
        require(utils.isValidUUID(scout), "Invalid scout ID");

        require(bytes(tokenToBuilderRegistry[tokenId]).length > 0, "Token not registered");
        require(builderToTokenRegistry[tokenToBuilderRegistry[tokenId]] == tokenId, "Builder-token mismatch");
       

        uint256 mintCost = getTokenQuote(tokenId, amount);

        uint256 beforeBalance = usdcToken.balanceOf(proceedsReceiver);
        usdcToken.safeTransferFrom(msg.sender, proceedsReceiver, mintCost);
        uint256 afterBalance = usdcToken.balanceOf(proceedsReceiver);

        require((beforeBalance + mintCost) == afterBalance, "ERC20 transfer slippage");

        _mint(msg.sender, tokenId, amount, "");
        _totalSupply[tokenId] += amount;

        emit BuilderScouted(tokenId, amount, scout);
    }
    // -----------------------------------------------------------------------------
    // ----------------- Admin functions -------------------------------------------
    // -----------------------------------------------------------------------------

    function mintTo(address account, uint256 tokenId, uint256 amount, string calldata scout) external onlyOwner {
      require(bytes(tokenToBuilderRegistry[tokenId]).length > 0, "Token not registered");
      require(utils.isValidUUID(scout), "scout must be a valid v4 uuid");
      _mint(account, tokenId, amount, "");
      _totalSupply[tokenId] += amount;

      emit BuilderScouted(tokenId, amount, scout);
    }

    function updateProceedsReceiver(address newReceiver) external onlyOwner {
        require(newReceiver != address(0), "Invalid address");
        proceedsReceiver = newReceiver;
    }


    // Register a new builder token
    function registerBuilderToken(string calldata builderId) external onlyOwner {
        require(utils.isValidUUID(builderId), "Builder ID must be valid v4 uuid");

        uint256 existingBuilderTokenId = builderToTokenRegistry[builderId];
        require(existingBuilderTokenId == 0, "Builder already registered");

        tokenToBuilderRegistry[nextTokenId] = builderId;
        builderToTokenRegistry[builderId] = nextTokenId;

        emit BuilderTokenRegistered(nextTokenId, builderId);
        nextTokenId++;
    }


    function updateTokenBaseUri(string memory newBaseUrl) external onlyOwner {
        require(bytes(newBaseUrl).length > 0, "Empty base url not allowed");
        baseUrl = newBaseUrl;
    }



  

    // -----------------------------------------------------------------------------
    // ---------------- Getters for Token Info --------------------
    // -----------------------------------------------------------------------------

    function getTokenQuote(uint256 tokenId, uint256 amount) public view returns (uint256) {
        require(amount > 0, "Must buy at least one token");

        uint256 currentSupply = totalSupply(tokenId);
        
        uint256 totalCost = 0;

        for (uint256 i = 0; i < amount; i++) {
            totalCost += (currentSupply + i + 1) * priceIncrement;
        }
        return totalCost;
    }
       // Getter to concatenate base URL, tokenId, and image path
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
       return string(abi.encodePacked(baseUrl, utils.uintToString(tokenId), "/image.jpeg"));
    }

      // Get total supply of a specific token
    function totalSupply(uint256 tokenId) public view returns (uint256) {
        return _totalSupply[tokenId];
    }

}