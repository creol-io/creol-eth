pragma solidity ^0.5.17;

interface SiteStateInterface {
    function initialize(address _owner, address _ControlAddress, address _allowedGSNAddress, string calldata _SiteName, address _RoomStateFactory, address _LEDFactory) external;
    function IsRegistered(address _RoomID) external view returns (bool SiteRegistry);
    function IsActive(address _RoomID) external view returns (bool SiteActive);
    function CreateRoom (address _accessHub , address _GSNAddress, string calldata _roomName) external;
    function AddRoom(address _RoomID, string calldata _RoomName) external  ;
    function RemoveRoom(address _RoomID) external ;
    function getRoomCount() external view returns(uint roomCount);

}
