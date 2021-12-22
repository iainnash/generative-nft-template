# on-chain generative nft edition drop

### What are these contracts?
1. `OnChainGenerativeEditionDrop`
This contract allows creating gas-optimized generative projects.
A data-uri can be encoded for svg or html projects if desired, or linked to IPFS or a centralized server.

Base NFT contract information is and metadata rendering methods are already deployed on ethereum mainnet as standardized Zora libraries

### How do I create a new contract?

### Directly on the blockchain:
1. Update all constants within the `GenerativeEditionDrop` contract
2. Set contracts for `SharedNFTLogic` and `ERC721Base` to your desired network from the respective readmes in `hardhat.config.js`
3. Deploy on rinkeby with hardhat `hardhat deploy --network rinkeby`
3. Deploy on mainnet with hardhat `hardhat deploy --network mainnet`

### Manage or mint these contracts through a GUI:

Rinkeby: https://edition-drop.vercel.app/manage/{CONTRACT_ADDRESS}/manage/?network=1

Mainnet: https://edition-drop.vercel.app/manage/{CONTRACT_ADDRESS}?network=4

Polygon: https://edition-drop.vercel.app/manage/{CONTRACT_ADDRESS}?network=137

Mumbai: https://edition-drop.vercel.app/manage/{CONTRACT_ADDRESS}?network=80001

### How do I sell/distribute editions?

Now that you have a edition, there are multiple options for lazy-minting and sales:

1. To sell editions for ETH you can call `setSalePrice`
2. To allow certain accounts to mint `setApprovedMinter(address, approved)`.
3. To mint yourself to a list of addresses you can call `mintEditions(addresses[])` to mint an edition to each address in the list.

### Benefits of these contracts:

* Full ownership of your own created minting contract
* Each serial gets its own minting contract
* Gas-optimized over creating individual NFTs
* Fully compatible with ERC721 marketplaces / auction houses / tools
* Supports tracking unique parts (edition 1 vs 24 may have different pricing implications) of editions
* Supports free public minting (by approving the 0x0 (zeroaddress) to mint)
* Supports smart-contract based minting (by approving the custom minting smart contract) using an interface.
* All metadata is stored/generated on-chain
* Permissionless and open-source
* Simple integrated ethereum-based sales, can be easily extended with custom interface code


### Verifying:

`hardhat sourcify --network rinkeby && hardhat etherscan-verify --network rinkeby`

