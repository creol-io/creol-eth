
pragma solidity ^0.5.0;
/**
 *
 *
 *
 *   @title RoomStateInterface v0.0.1
 ________  ________  _______   ________  ___
|\   ____\|\   __  \|\  ___ \ |\   __  \|\  \
\ \  \___|\ \  \|\  \ \   __/|\ \  \|\  \ \  \
 \ \  \    \ \   _  _\ \  \_|/_\ \  \\\  \ \  \
  \ \  \____\ \  \\  \\ \  \_|\ \ \  \\\  \ \  \____
   \ \_______\ \__\\ _\\ \_______\ \_______\ \_______\
    \|_______|\|__|\|__|\|_______|\|_______|\|_______|



 *
 *


  _____                        _____ _        _       _____       _             __
 |  __ \                      / ____| |      | |     |_   _|     | |           / _|
 | |__) |___   ___  _ __ ___ | (___ | |_ __ _| |_ ___  | |  _ __ | |_ ___ _ __| |_ __ _  ___ ___
 |  _  // _ \ / _ \| '_ ` _ \ \___ \| __/ _` | __/ _ \ | | | '_ \| __/ _ \ '__|  _/ _` |/ __/ _ \
 | | \ \ (_) | (_) | | | | | |____) | || (_| | ||  __/_| |_| | | | ||  __/ |  | || (_| | (_|  __/
 |_|  \_\___/ \___/|_| |_| |_|_____/ \__\__,_|\__\___|_____|_| |_|\__\___|_|  |_| \__,_|\___\___|




* @author Joshua Bijak
* Date:       February 18,2020
* @notice RoomState Pulling Contract Interface
* @dev RoomState interface to get room information

*
*
*
*
*/


interface RoomStateInterface {
    event newRoom ( address roomAddr);
    event newCreezy( string creezyID, address[] newCreezyLEDs);
    event newLED(address _newLED);
    event delCreezy( string creezyID);
    event newCreezyCoapAddr( string creezyID, string coapAddress);
    event newCreezyNumLEDs ( string creezyID, uint256 numLEDs);
    event newCreezyNumUniverses( string creezyID, uint256 numUniverses);
    event newGroup(string groupID, uint256 groupIndex);
    event groupDeleted( string groupID, uint256 groupIndex);
    event newProxyAdmin(address _newProxyAdmin);
    event payloadDataPacked(bytes _payLoadData);

    function addCreezy(string calldata _coapAddr, string calldata _creezyID, uint256 _numLEDs,address contractOwner, uint256 _numUniverses, uint256 _ledWattage) external;
    function removeCreezy(string calldata _creezyID) external;
    function updateCreezyCoap(string calldata _creezyID, string calldata _coapAddr) external;
    function addAndUpdateCreezyLEDs(string calldata _creezyID, uint256 _new_numLEDs, address contractOwner, uint256 _ledWattage) external ;
    function addCreezyGroup(string calldata _groupString, address[] calldata LEDs) external ;
    function removeGroup(string calldata _groupString) external ;
    function getGroupAddresses(string calldata _groupID) external view returns(address[] memory);
    function groupSwitchPlate (bool _newState, address[] calldata LEDAddresses) external ;
    function groupDimPlate (uint256 _newDim, address[] calldata LEDAddresses) external ;
    function getLEDCount() external view returns(uint LEDCount);
    function getGroupCount() external view returns(uint groupCount);
    function getCreezyCount() external view returns(uint creezyCount);

}
