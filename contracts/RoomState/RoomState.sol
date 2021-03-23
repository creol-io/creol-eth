
pragma solidity ^0.5.0;
/**
 *
 *
 *
 *   @title RoomState v0.0.2
 ________  ________  _______   ________  ___
|\   ____\|\   __  \|\  ___ \ |\   __  \|\  \
\ \  \___|\ \  \|\  \ \   __/|\ \  \|\  \ \  \
 \ \  \    \ \   _  _\ \  \_|/_\ \  \\\  \ \  \
  \ \  \____\ \  \\  \\ \  \_|\ \ \  \\\  \ \  \____
   \ \_______\ \__\\ _\\ \_______\ \_______\ \_______\
    \|_______|\|__|\|__|\|_______|\|_______|\|_______|



 *
 *
  _____                        _____ _        _
 |  __ \                      / ____| |      | |
 | |__) |___   ___  _ __ ___ | (___ | |_ __ _| |_ ___
 |  _  // _ \ / _ \| '_ ` _ \ \___ \| __/ _` | __/ _ \
 | | \ \ (_) | (_) | | | | | |____) | || (_| | ||  __/
 |_|  \_\___/ \___/|_| |_| |_|_____/ \__\__,_|\__\___|


* Author: Joshua Bijak
* Desc: Contract designed to hold the state of a Room containing LED contracts
*
*
*
*/

import   '../LEDState/LEDFactoryInterface.sol';

import   '../LEDState/LEDStateInterface.sol';

import   './RoomStateInterface.sol';

import  '../AccessHub/AccessHubInterface.sol';

//import  '../LEDState/LEDFactory.sol';

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/GSN/GSNRecipient.sol";


contract RoomState is RoomStateInterface, Initializable, Ownable, GSNRecipient {


    LEDFactoryInterface private genericLEDFactoryInterface;

    LEDStateInterface private genericLEDStateInterface;

    AccessHubInterface public credentials;

    address public proxyAdmin;

    address private allowedGSNAddress;

    struct Group {
        uint256 count;
        address[] LEDs;
        bool isActive;
        string groupName;
    }

    //Struct To Hold Creezies

    struct CreezyPi {
        string coapAddress;
        string creezyID;
        uint256 numLEDs;
        uint256 numUniverses;
        bool isActive;

    }


    address[] public roomLEDs;

    Group[] public roomGroups;

    Group[] public roomUniverses;

    //Creezies in this Room
    CreezyPi[] public creezyPis;

    // Identify each creezy in the room by its index number
    // These are considered unique and unrevocable

    mapping( uint256 => CreezyPi ) public creezyIndextoCreezyData;

    mapping ( string => uint256 ) public creezyIdtoCreezyIndex;

    mapping( uint256 => Group ) public groupIndextoGroupData;

    mapping ( string => uint256 ) public groupNametoGroupIndex;

    mapping ( string => CreezyPi ) public groupNametoParentCreezyPi;

    // Look up group by its coap address (aka all lights connected to a creezy), currently only for 1 universe
    // Packed as bytes from string
    //Look up group by its "Group Designation" aka (Office Lights)
    // Packed as bytes from string



    // TODO: Rework this mapping to actually group by Creezy for Grouped Piping


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

    modifier onlyAccessHub(){
        require(credentials.checkHasAccess(_msgSender(), AccessHubInterface.ContractTypes.RoomState) || _msgSender() == owner(), "Caller, not registered in access hub");
        _;
    }
    // Requires LEDFactory to be deployed
    constructor() public {

    }


    function initialize (address LEDFactory, address _accessHub, address _allowedGSNAddress) public initializer {
        genericLEDFactoryInterface =  LEDFactoryInterface(LEDFactory);
        Ownable.initialize(_accessHub);
        allowedGSNAddress = _allowedGSNAddress;
        GSNRecipient.initialize();

        credentials = AccessHubInterface(_accessHub);

        emit newRoom(address(this));

    }
    function addLED (bool _defaultState, address _roomContract, address _accessHub, uint256 _daliAddress, uint256 _ledDim, uint256 _ledWattage) public onlyAccessHub returns (address newLEDAddress){

        bytes memory payLoadData = abi.encodeWithSignature("initialize(bool,address,address,address,uint256,uint256,uint256)",_defaultState,_roomContract,_accessHub,allowedGSNAddress,_daliAddress,_ledDim,_ledWattage);

        emit payloadDataPacked(payLoadData);
        address _newLED = genericLEDFactoryInterface.createLEDStateUpgradeable(proxyAdmin, payLoadData);

        roomLEDs.push(_newLED);
        emit newLED(_newLED);

        return _newLED;
    }


    // Creezies are added to the room with this function
    // Deploys the LED Contracts for its new Universe and registers them as group
    /**

    */
    function addCreezy(string memory _coapAddr,string memory _creezyId, uint256 _numLEDs,address _accessHub, uint256 _numUniverses, uint256 _ledWattage) public onlyAccessHub {


        require(creezyIndextoCreezyData[creezyIdtoCreezyIndex[_creezyId]].isActive == false, "CreezyID Already Exists, use updateCreezy");
        require(_numLEDs < 64, "Too many LEDs for a single universe, maximum is 64");
        require(_numUniverses < 4, "Too many Universes, maximum is 4");
        // Allocate temporary memory for the array
        address[] memory newLEDs = new address[](_numLEDs);

        for (uint256 i=0; i<_numLEDs;i++){

            //Instantiate new contract and assign address with params (off, with 50% dim, 30W Wattage)
            newLEDs[i] = addLED(false, address(this),_accessHub, i, 123,_ledWattage);

        }
        CreezyPi memory newCreezyPi = CreezyPi(_coapAddr, _creezyId,_numLEDs, _numUniverses,true);

        // Make indexable getter for this Creezy
        creezyIndextoCreezyData[creezyPis.length] = newCreezyPi;
        // Allow index to be found for the getter
        creezyIdtoCreezyIndex[_creezyId] = creezyPis.length;
        // Add creezyPis to global array
        creezyPis.push(newCreezyPi);
        // Create a roomGroup out of the newly deployed LEDs (aka Room-Creezy-Group-XX)
        addCreezyGroup(_creezyId, newLEDs);

        // Assign groupName to be able to lookup the Creezy itself
        groupNametoParentCreezyPi[_creezyId] = newCreezyPi;

        emit newCreezy(_creezyId, newLEDs );
    }
    // Create group based on Designator "string"
    // This will allow for overwriting of groups that were previously removed
    //
    function addCreezyGroup(string memory _groupString, address[] memory LEDs) public onlyAccessHub {

        require(groupIndextoGroupData[groupNametoGroupIndex[_groupString]].isActive == false, "Group already active");
        Group memory newGroupToAdd = Group(LEDs.length, LEDs, true, _groupString);

        groupIndextoGroupData[roomGroups.length] = newGroupToAdd;
        groupNametoGroupIndex[_groupString] = roomGroups.length;

        roomGroups.push(newGroupToAdd);

        emit newGroup(_groupString, groupNametoGroupIndex[_groupString]);

    }
    // Remove
    function removeGroup(string memory _groupString) public onlyAccessHub {
        require(groupIndextoGroupData[groupNametoGroupIndex[_groupString]].isActive == true, "Group already removed");

        groupIndextoGroupData[groupNametoGroupIndex[_groupString]].isActive = false;

        emit groupDeleted(_groupString, groupNametoGroupIndex[_groupString]);
    }
    /**
     *  Removes Creezy from Room by marking Active flag as inactive, data remains for later inspection to not lose LED addresses
     *  Removes associated groups
     */
    function removeCreezy(string memory _creezyId) public onlyAccessHub {

        require(creezyIndextoCreezyData[creezyIdtoCreezyIndex[_creezyId]].isActive == true, "CreezyID does not exist, cannot remove");
        // Remove the CreezyID encompassing group as well
        removeGroup(_creezyId);

        creezyIndextoCreezyData[creezyIdtoCreezyIndex[_creezyId]].isActive = false;

        emit delCreezy(_creezyId);
    }
    /**
     * Updates a  Creezy COAP Address, number of crezy must be known
     */
    function updateCreezyCoap(string memory _creezyId, string memory _coapAddr) public onlyAccessHub {

        require(creezyIndextoCreezyData[creezyIdtoCreezyIndex[_creezyId]].isActive == true, "CreezyID does not exist, cannot update coap");

        creezyIndextoCreezyData[creezyIdtoCreezyIndex[_creezyId]].coapAddress = _coapAddr;

        emit newCreezyCoapAddr(_creezyId, creezyIndextoCreezyData[creezyIdtoCreezyIndex[_creezyId]].coapAddress);
    }
    /**
     * @dev Adds LEDs to an existing Creezy
     */

     // TODO: Add a remove or add flag for adding OR removing LEDs
    function addAndUpdateCreezyLEDs(string memory _creezyId, uint256 _new_numLEDs, address contractOwner, uint256 _ledWattage) public onlyAccessHub {

        require(creezyIndextoCreezyData[creezyIdtoCreezyIndex[_creezyId]].isActive == true, "CreezyID does not exist, cannot update LEDs");

        // Get old LED array
        address[] memory oldLEDs = getGroupAddresses(_creezyId);
        // Build new array in memory
        address[] memory newLEDsArray = new address[](oldLEDs.length+_new_numLEDs);
        uint256 i=0;
        // Clone oldLEDs into new array: SOLIDITY does not allow storage and memory mixing and matching
        for (i; i<oldLEDs.length; i++){
            //Instantiate new contract and assign address with params (off, with 50% dim)
            newLEDsArray[i] = oldLEDs[i];
        }
        // Add remaining LEDs by deploying them
        for (i; i<oldLEDs.length+_new_numLEDs; i++){
            newLEDsArray[i] = addLED(false, address(this),contractOwner, i, 123,_ledWattage);
        }

        //Overwrite the existing whole groups
        removeGroup(_creezyId);
        addCreezyGroup(_creezyId, newLEDsArray);


        creezyIndextoCreezyData[creezyIdtoCreezyIndex[_creezyId]].numLEDs = newLEDsArray.length;

        emit newCreezyNumLEDs(_creezyId, creezyIndextoCreezyData[creezyIdtoCreezyIndex[_creezyId]].numLEDs);

    }
    function updateCreezyUniverses(string memory _creezyId, uint256 _new_numUniverses) internal {

        require(creezyIndextoCreezyData[creezyIdtoCreezyIndex[_creezyId]].isActive == true, "CreezyID does not exist, cannot update universes");

        creezyIndextoCreezyData[creezyIdtoCreezyIndex[_creezyId]].numUniverses = _new_numUniverses;

        emit newCreezyNumUniverses(_creezyId, creezyIndextoCreezyData[creezyIdtoCreezyIndex[_creezyId]].numUniverses);
    }


    function getGroupAddresses(string memory _groupId) public view returns(address[] memory) {

        return groupIndextoGroupData[groupNametoGroupIndex[_groupId]].LEDs;

    }
    function getLEDCount() public view returns(uint LEDCount){
        return roomLEDs.length;
    }
    function getGroupCount() public view returns(uint groupCount) {
        return roomGroups.length;
    }
    function getCreezyCount() public view returns(uint creezyCount) {
        return creezyPis.length;
    }

    function groupSwitchPlate (bool _newState, address[] memory LEDAddresses) public onlyAccessHub{
        for (uint256 i=0; i< LEDAddresses.length;i++){
            genericLEDStateInterface = LEDStateInterface(LEDAddresses[i]);
            genericLEDStateInterface.updateState(_newState);
        }
    }
    function groupDimPlate (uint256 _newDim, address[] memory LEDAddresses) public onlyAccessHub{
        for (uint256 i=0; i< LEDAddresses.length;i++){
            genericLEDStateInterface = LEDStateInterface(LEDAddresses[i]);
            genericLEDStateInterface.updateDim(_newDim);
        }
    }
    /**
   * @dev Meant to update the proxyAdmin address, that was added in new version.
   * @notice Meant to update the proxyAdmin address, that was added in new version.
   * @param _proxyAdmin new address of the proxyAdmin contract for the openzeppelin app entry
   */
    function setProxyAdmin( address _proxyAdmin) public onlyAccessHub {
        proxyAdmin = _proxyAdmin;
        emit newProxyAdmin(_proxyAdmin);

    }
    function setGSNAllowed(address _newGSNAddress) public onlyAccessHub {
        allowedGSNAddress = _newGSNAddress;
    }
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    ) external view returns (uint256, bytes memory)  {

        //emit emittedMsgSender(_msgSender());
        //emit emittedAllowedAddress(allowedAddress);
        if(from == allowedGSNAddress){
            return _approveRelayedCall();

        }
        else {
            return _rejectRelayedCall(uint256(0));
        }
    }

    function _preRelayedCall(bytes memory context) internal returns (bytes32) {

    }

    function _postRelayedCall(bytes memory context, bool, uint256 actualCharge, bytes32) internal {

    }

    function setRelayHubAddress() public {
        if(getHubAddr() == address(0)) {
            _upgradeRelayHub(0xD216153c06E857cD7f72665E0aF1d7D82172F494);
        }
    }

    function getRecipientBalance() public view returns (uint) {
        return IRelayHub(getHubAddr()).balanceOf(address(this));
    }

}
