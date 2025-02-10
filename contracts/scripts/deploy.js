const { ethers, keccak256, toUtf8Bytes } = require("ethers");
require("dotenv").config();

const provider = new ethers.JsonRpcProvider(
  "https://rpc.testnet.lens.dev",
  37111
);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const skyhuntersAccessControlsAddress =
  "0x0512d639c0b32E29a06d95221899288152295aE6";

(async () => {
  const accessContract = new ethers.Contract(
    skyhuntersAccessControlsAddress,
    [{
      type: "function",
      name: "setAcceptedToken",
      inputs: [{ name: "token", type: "address", internalType: "address" }],
      outputs: [],
      stateMutability: "nonpayable",
    }],
    wallet
  );

  const tx = await accessContract.setAcceptedToken(
    "0xeee5a340Cdc9c179Db25dea45AcfD5FE8d4d3eB8"
  );
  await tx.wait();
})();
