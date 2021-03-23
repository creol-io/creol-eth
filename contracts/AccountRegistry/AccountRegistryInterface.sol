pragma solidity ^0.5.17;

import "./AccountRegistry.sol";

interface AccountRegistryInterface {
    function initialize(address _creolSuper) external;
    function IsRegistered(address _AccessHubID) external view returns (bool AccessHubRegistry);
    function IsActive(address _AccessHubID) external view returns(bool AccessHubActivity);
    function AddAccessHub(address _AccessHubID, string calldata _AccessHubName) external ;
    function RemoveAccessHub(address _AccessHubID) external ;
    function getAccessHubCount() external view returns (uint AccessHubCount);
}
