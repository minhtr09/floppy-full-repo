// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleContract {
  string public message;

  constructor(
    string memory initialMessage
  ) {
    message = initialMessage;
  }

  function setMessage(
    string memory newMessage
  ) public {
    message = newMessage;
  }
}

import { Script } from "forge-std/Script.sol";

contract DeploySimpleContract is Script {
  function run() external {
    vm.startBroadcast();

    // Deploy the SimpleContract with an initial message
    SimpleContract simpleContract = new SimpleContract("Hello, World!");

    vm.stopBroadcast();
  }
}
