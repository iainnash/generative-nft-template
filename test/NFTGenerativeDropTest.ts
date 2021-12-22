import { expect } from "chai";
import "@nomiclabs/hardhat-ethers";
import { ethers, deployments } from "hardhat";
import parseDataURI from "data-urls";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { OnChainGenerativeEditionDrop, OnChainGenerativeEditionDrop__factory } from "../typechain";

describe("SingleEditionMintable", () => {
  let signer: SignerWithAddress;
  let signerAddress: string;
  let dynamicSketch: OnChainGenerativeEditionDrop;

  beforeEach(async () => {
    const { OnChainGenerativeEditionDrop } = await deployments.fixture([
      "OnChainGenerativeEditionDrop",
    ]);

    dynamicSketch = OnChainGenerativeEditionDrop__factory.connect(
      OnChainGenerativeEditionDrop.address,
      (await ethers.getSigners())[0]
    );
    signer = (await ethers.getSigners())[0];
    signerAddress = await signer.getAddress();
  });

  it("makes a new edition", async () => {
    await dynamicSketch.mintEdition(signerAddress);
  });
});
