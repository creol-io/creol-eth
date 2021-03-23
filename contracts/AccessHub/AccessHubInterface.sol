pragma solidity ^0.5.17;

import "./AccessHub.sol";

interface AccessHubInterface {
    enum ContractTypes { ControlState, SiteState, RoomState, LEDState }
    
    function checkAndSendFunction( bytes calldata packedMethodCall, address destination, ContractTypes destinationType) external;
    function addAccess(address userAddress, ContractTypes destinationType) external;
    function removeAccess(address userAddress, ContractTypes destinationType) external;
    function checkHasAccess(address _accountToCheck, ContractTypes destinationType) external view returns (bool hasAccess);
}
