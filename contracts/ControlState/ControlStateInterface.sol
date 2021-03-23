pragma solidity ^0.5.17;

interface ControlStateInterface {
    function initialize(address _owner, address _ControlAddress,address _GSNAddress, string calldata _ControlName,address _SiteStateFactory, address _LEDFactory, address _RoomStateFactory) external;
    function IsRegistered(address _SiteID) external view returns (bool SiteRegistry);
    function IsActive(address _SiteID) external view returns(bool SiteActivity);
    function AddSite(address _SiteID, string calldata _SiteName) external ;
    function RemoveSite(address _SiteID) external ;
    function getSiteCount() external view returns (uint siteCount);

}
