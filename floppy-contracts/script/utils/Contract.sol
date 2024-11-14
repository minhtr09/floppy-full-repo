// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { LibString } from "@solady/utils/LibString.sol";
import { TContract } from "@fdk/types/Types.sol";

enum Contract {
  FloppyVault,
  FLP,
  FloppyGamble
}

using { key, name } for Contract global;

function key(
  Contract contractEnum
) pure returns (TContract) {
  return TContract.wrap(LibString.packOne(name(contractEnum)));
}

function name(
  Contract contractEnum
) pure returns (string memory) {
  if (contractEnum == Contract.FloppyVault) return "FloppyVault";
  if (contractEnum == Contract.FLP) return "FLP";
  if (contractEnum == Contract.FloppyGamble) return "FloppyGamble";
  revert("Contract: Unknown contract");
}
