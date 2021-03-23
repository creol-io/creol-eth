pragma solidity ^0.5.17;

interface SiteStateFactoryInterface {
    function createSiteStateUpgradeable(address _creolAdmin, bytes calldata _encodedData) external returns (address);
    function addApprovedControlState(address _newControlStateAddress) external;
    function removeApprovedControlState(address _oldControlStateAddress) external;
    
    event LogNewSiteState(address SiteState);

    
}