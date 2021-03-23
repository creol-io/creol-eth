pragma solidity ^0.5.17;

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/GSN/GSNRecipient.sol";

import "../RoomState/RoomStateInterface.sol";
import "../RoomState/RoomStateFactoryInterface.sol";

import "../LEDState/LEDFactoryInterface.sol";
import './SiteStateInterface.sol';


import  '../AccessHub/AccessHubInterface.sol';



contract SiteState is SiteStateInterface, Initializable, Ownable, GSNRecipient {

    //Events
    event RoomAdded(address RoomAddress, string RoomName);
    event RoomDeleted(address RoomAddress);
    event newProxyAdmin(address _newProxyAdmin);

    RoomStateInterface private genericRoomStateInterface;
    RoomStateFactoryInterface public genericRoomStateFactoryInterface;
    LEDFactoryInterface public LEDFactoryInterfaceCreol;

    struct Room {
        bool IsRegistered;
        bool IsActive;
        string RoomName;
    }

    address ControlAddress;

    bool public SiteIsRegistered;
    bool public SiteIsActive;
    string public SiteName;
    address[] public RoomAddresses;

    address public proxyAdmin;

    address private allowedGSNAddress;

    AccessHubInterface public credentials;

    //Room state address
    mapping (address => Room) public RoomIDtoRoomData;

    modifier onlyAccessHub(){
        require(credentials.checkHasAccess(_msgSender(), AccessHubInterface.ContractTypes.SiteState) || _msgSender() == owner(), "Caller, not registered in access hub ");
        _;
    }

    //Functions
    constructor() public {
    }

    function initialize(address _owner, address _accessHub,address _allowedGSNAddress, string memory _SiteName, address _RoomStateFactory, address _LEDFactory) public initializer {

        genericRoomStateFactoryInterface = RoomStateFactoryInterface(_RoomStateFactory);

        LEDFactoryInterfaceCreol = LEDFactoryInterface(_LEDFactory);

        credentials = AccessHubInterface(_accessHub);

        ControlAddress = _accessHub;
        SiteIsRegistered = true;
        SiteIsActive  = true;
        SiteName = _SiteName;
        allowedGSNAddress = _allowedGSNAddress;

        if (_owner == address(0)) {
            Ownable.initialize(_msgSender());
        }
        else {
            Ownable.initialize(_owner);
        }
        GSNRecipient.initialize();

    }

    function IsRegistered (address _RoomID) public view returns(bool RoomStatus) {
        return (RoomIDtoRoomData[_RoomID].IsRegistered);
    }

    function IsActive (address _RoomID) public view returns(bool RoomStatus) {
        return (RoomIDtoRoomData[_RoomID].IsActive);
    }
    function GetRoomName(address _RoomID) public view returns (string memory RoomName){
        return (RoomIDtoRoomData[_RoomID].RoomName);
    }

    function AddRoom (address _RoomID, string memory _RoomName) onlyAccessHub public {
        if(SiteIsRegistered == true) {
            if (RoomIDtoRoomData[_RoomID].IsActive == false) {
                RoomIDtoRoomData[_RoomID].IsRegistered = true;
                RoomIDtoRoomData[_RoomID].IsActive = true;
                RoomIDtoRoomData[_RoomID].RoomName = _RoomName;
                RoomAddresses.push(_RoomID);
                emit RoomAdded(_RoomID, _RoomName);
            }
            else {
                revert("Room is already active");
            }
        }
        else {
            revert("Site is not active");
        }
    }

    function RemoveRoom (address _RoomID) onlyAccessHub public {
        if(SiteIsRegistered == true) {
            if (RoomIDtoRoomData[_RoomID].IsActive == true) {
                RoomIDtoRoomData[_RoomID].IsActive = false;
                emit RoomDeleted(_RoomID);
            }
            else {
                revert("Room is not active");
            }
        }
        else {
            revert("Site is not active");
        }
    }

    function CreateRoom (address _accessHub , address _GSNAddress, string memory _roomName) public onlyAccessHub {

        bytes memory payLoadData = abi.encodeWithSignature("initialize(address,address,address)",LEDFactoryInterfaceCreol,_accessHub, _GSNAddress);

        address _newRoom = genericRoomStateFactoryInterface.createRoomStateUpgradeable(proxyAdmin, payLoadData);

        LEDFactoryInterfaceCreol.addApprovedRoomState(_newRoom);

        AddRoom(_newRoom,_roomName);


    }
    function getRoomCount() public view returns(uint roomCount){
        return RoomAddresses.length;
    }
    /**
 * @dev Meant to update the proxyAdmin address, that was added in new version.
 * @notice Meant to update the proxyAdmin address, that was added in new version.
 * @param _proxyAdmin new address of the proxyAdmin contract for the openzeppelin app entry
 */
    function setProxyAdmin( address _proxyAdmin) public onlyOwner {
        proxyAdmin = _proxyAdmin;
        emit newProxyAdmin(_proxyAdmin);

    }
    function setGSNAllowed(address _newGSNAddress) public onlyOwner {
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
