import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Address, Chain, rpcSchema } from "viem"
import { base, baseSepolia, optimism, optimismSepolia, sepolia } from "viem/chains";
import { NULL_ADDRESS } from "./constants";

type Connector = {
  chain: Chain;
  rpcUrl: string;
  // See https://docs.attest.org/docs/quick--start/contracts for full list
  easContract: Address;
  luckyStarCoinContract: Address;
  stargateProtocolContract: Address;
  builderNFTContract: Address;
  usdcContract?: Address;
  seasonOneProxy?: Address;
  seasonOneImplementation?: Address;
}
/**
 * 
 * USDC Mainnet https://developers.circle.com/stablecoins/docs/usdc-on-main-networks
 * USDC Testnet https://developers.circle.com/stablecoins/docs/usdc-on-test-networks
 */

export const connectors = {
  opsepolia: {
    rpcUrl: 'https://sepolia.optimism.io',
    chain: optimismSepolia,
    easContract: '0x4200000000000000000000000000000000000021',
    luckyStarCoinContract: '0x2b02514966803597b8d29D885cBef46e31a85EE5',
    stargateProtocolContract: '0x2aec1dedd9a63173d673bcaa60564a4bae38bc38',
    builderNFTContract: '0xbd7b21e803147e0dcb698f6f76ce6dd530a545dd',
    usdcContract: '0x101e1C9757C99867a39Ceb41117B44F2292cB253',
    seasonOneImplementation: '0x92bbf17fcedee104bc6ae5d10b99eacf2fc2d3b6',
    seasonOneProxy: '0xff9731e06f009800cb23ac6eddc2903d801fa890'
  } as Connector,
  sepolia: {
    rpcUrl: 'https://ethereum-sepolia.blockpi.network/v1/rpc/public',
    chain: sepolia,
    easContract: '0xC2679fBD37d54388Ce493F1DB75320D236e1815e',
    luckyStarCoinContract: NULL_ADDRESS,
    stargateProtocolContract: NULL_ADDRESS,
    builderNFTContract: NULL_ADDRESS,
    usdcContract: '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238'
  } as Connector,
  basesepolia: {
    rpcUrl: 'https://sepolia.base.org',
    chain: baseSepolia,
    easContract: NULL_ADDRESS,
    luckyStarCoinContract: NULL_ADDRESS,
    stargateProtocolContract: NULL_ADDRESS,
    // This is the new version of the contract with a sudo-type mint
    builderNFTContract: '0xec66b6a6c2ce744543517776ff9906cd41c50a63',
    usdcContract: '0x036CbD53842c5426634e7929541eC2318f3dCF7e'
  } as Connector,
  base: {
    rpcUrl: 'https://mainnet.base.org',
    chain: base,
    easContract: NULL_ADDRESS,
    luckyStarCoinContract: NULL_ADDRESS,
    stargateProtocolContract: NULL_ADDRESS,
    builderNFTContract: '0x278cc8861cfc93ea47c9e89b1876d0def2037c27',
    usdcContract: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913'
  } as Connector,
  optimism: {
    rpcUrl: 'https://opt-mainnet.g.alchemy.com/v2/vTjY0u9L7uoxZQ5GtOw4yKwn7WJelMXp',
    chain: optimism,
    easContract: NULL_ADDRESS,
    luckyStarCoinContract: NULL_ADDRESS,
    stargateProtocolContract: NULL_ADDRESS,
    builderNFTContract: '0x7df4d9f54a5cddfef50a032451f694d6345c60af',
    usdcContract: '0x0b2c639c533813f4aa9d7837caf62653d097ff85'
  }
} as const;

export type SupportedChains = keyof typeof connectors;

export function getConnectorFromHardhatRuntimeEnvironment(hre: HardhatRuntimeEnvironment): Connector {

  const chainName = hre.hardhatArguments.network;

  if (!chainName) {
    throw new Error('No network specified')
  }

  const connector = connectors[chainName as SupportedChains];

  if (!connector) {
    throw new Error(`Unsupported chain: ${chainName}`)
  }

  return connector;
}