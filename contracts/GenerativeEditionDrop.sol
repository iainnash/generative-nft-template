// SPDX-License-Identifier: GPL-3.0

/**
  Generative Edition Drop
 */

pragma solidity 0.8.9;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IBaseERC721Interface, ConfigSettings} from "gwei-slim-nft-contracts/contracts/base/ERC721Base.sol";
import {ERC721Delegated} from "gwei-slim-nft-contracts/contracts/base/ERC721Delegated.sol";

import {SharedNFTLogic} from "@zoralabs/nft-editions-contracts/contracts/SharedNFTLogic.sol";
import {IEditionSingleMintable} from "@zoralabs/nft-editions-contracts/contracts/IEditionSingleMintable.sol";

/**
*/
contract OnChainGenerativeEditionDrop is
    ERC721Delegated, IEditionSingleMintable
{
    using Counters for Counters.Counter;
    event PriceChanged(uint256 amount);
    event EditionSold(uint256 price, address owner);

    string private constant name = "";
    string private constant symbol = "";
    string private constant description = "";
    uint16 private constant royaltyBPS = 1000;
    string private constant imageRendererBase = "https://gendrop0.iain.in/preview/";

    // Media Urls
    // animation_url field in the metadata
    string private animationUrl;

    // Image in the metadata

    // Total size of edition that can be minted
    uint256 public dropSize;

    // Current token id minted
    Counters.Counter private atEditionId;

    // Addresses allowed to mint edition
    mapping(address => bool) allowedMinters;

    // Price for sale
    uint256 public salePrice;

    // NFT rendering logic contract
    SharedNFTLogic private immutable sharedNFTLogic;

    // Global constructor for factory
    constructor(address baseNFTContract, SharedNFTLogic _sharedNFTLogic, uint256 _dropSize) ERC721Delegated(
        baseNFTContract,
        name,
        symbol,
        ConfigSettings({
            royaltyBps: royaltyBPS,
            // this is only for the preview image renderign
            uriBase: imageRendererBase,
            uriExtension: "",
            hasTransferHook: false
        })
    ) {
        sharedNFTLogic = _sharedNFTLogic;
        dropSize = _dropSize;
    }

    /// @dev returns the number of minted tokens within the edition
    function totalSupply() public view returns (uint256) {
        return atEditionId.current() - 1;
    }
    /**
        Simple eth-based sales function
        More complex sales functions can be implemented through ISingleEditionMintable interface
     */

    /**
      @dev This allows the user to purchase a edition edition
           at the given price in the contract.
     */
    function purchase() external payable returns (uint256) {
        require(salePrice > 0, "Not for sale");
        require(msg.value == salePrice, "Wrong price");
        address[] memory toMint = new address[](1);
        toMint[0] = msg.sender;
        emit EditionSold(salePrice, msg.sender);
        return _mintEditions(toMint);
    }

    /**
      @param _salePrice if sale price is 0 sale is stopped, otherwise that amount 
                       of ETH is needed to start the sale.
      @dev This sets a simple ETH sales price
           Setting a sales price allows users to mint the edition until it sells out.
           For more granular sales, use an external sales contract.
     */
    function setSalePrice(uint256 _salePrice) external onlyOwner {
        salePrice = _salePrice;
        emit PriceChanged(salePrice);
    }

    /**
      @dev This withdraws ETH from the contract to the contract owner.
     */
    function withdraw() external onlyOwner {
        // No need for gas limit to trusted address.
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /**
      @dev This helper function checks if the msg.sender is allowed to mint the
            given edition id.
     */
    function _isAllowedToMint() internal view returns (bool) {
        // If the owner attempts to mint
        if (owner() == msg.sender) {
            return true;
        }
        // Anyone is allowed to mint
        if (allowedMinters[address(0x0)]) {
            return true;
        }
        // Otherwise use the allowed minter check
        return allowedMinters[msg.sender];
    }

    /**
      @param to address to send the newly minted edition to
      @dev This mints one edition to the given address by an allowed minter on the edition instance.
     */
    function mintEdition(address to) external override returns (uint256) {
        require(_isAllowedToMint(), "Needs to be an allowed minter");
        address[] memory toMint = new address[](1);
        toMint[0] = to;
        return _mintEditions(toMint);
    }

    /**
      @param recipients list of addresses to send the newly minted editions to
      @dev This mints multiple editions to the given list of addresses.
     */
    function mintEditions(address[] memory recipients)
        external
        override
        returns (uint256)
    {
        require(_isAllowedToMint(), "Needs to be an allowed minter");
        return _mintEditions(recipients);
    }

    /**
        Simple override for owner interface.
     */
    function owner()
        public
        view
        override(IEditionSingleMintable)
        returns (address)
    {
        return ERC721Delegated._owner();
    }

    /**
      @param minter address to set approved minting status for
      @param allowed boolean if that address is allowed to mint
      @dev Sets the approved minting status of the given address.
           This requires that msg.sender is the owner of the given edition id.
           If the ZeroAddress (address(0x0)) is set as a minter,
             anyone will be allowed to mint.
           This setup is similar to setApprovalForAll in the ERC721 spec.
     */
    function setApprovedMinter(address minter, bool allowed) public onlyOwner {
        allowedMinters[minter] = allowed;
    }

    /**
      @dev Allows for updates of edition urls by the owner of the edition.
           Only URLs can be updated (data-uris are supported), hashes cannot be updated.
     */
    function updateBasePreviewURL(
        string memory _basePreviewUrl
    ) public onlyOwner {
        _setBaseURI(_basePreviewUrl, "");
    }

    /// Returns the number of editions allowed to mint (max_uint256 when open edition)
    function numberCanMint() public view override returns (uint256) {
        // Return max int if open edition
        if (dropSize == 0) {
            return type(uint256).max;
        }
        // atEditionId is one-indexed hence the need to remove one here
        return dropSize + 1 - atEditionId.current();
    }

    /**
        @param tokenId Token ID to burn
        User burn function for token id 
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");
        _burn(tokenId);
    }

    /**
      @dev Private function to mint als without any access checks.
           Called by the public edition minting functions.
     */
    function _mintEditions(address[] memory recipients)
        internal
        returns (uint256)
    {
        uint256 startAt = atEditionId.current();
        uint256 endAt = startAt + recipients.length - 1;
        require(dropSize == 0 || endAt <= dropSize, "Sold out");
        while (atEditionId.current() <= endAt) {
            _mint(
                recipients[atEditionId.current() - startAt],
                atEditionId.current()
            );
            atEditionId.increment();
        }
        return atEditionId.current();
    }

    /**
        @dev Get URI for given token id
        @param tokenId token id to get uri for
        @return base64-encoded json metadata object
    */
    function tokenURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(_exists(tokenId), "No token");

        return
            sharedNFTLogic.createMetadataEdition(
                name,
                description,
                _tokenURI(tokenId),
                animationUrl,
                tokenId,
               dropSize 
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        returns (bool)
    {
        return
            type(IERC2981).interfaceId == interfaceId ||
            type(IERC721).interfaceId == interfaceId ||
            type(IEditionSingleMintable).interfaceId == interfaceId;
    }
}
