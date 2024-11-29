// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// Pose as existing contracts and make them do unexpected things.
contract FunctionMocker {
    address public transient initiator;
    address public transient currentModule;

    function setInitiator(address newInitiator) external {
        initiator = newInitiator;
    }

    function setCurrentModule(address newCurrentModule) external {
        currentModule = newCurrentModule;
    }
}
