pragma solidity ^0.5.17;

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/GSN/GSNRecipient.sol";

import "../SiteState/SiteStateInterface.sol";
import "../SiteState/SiteStateFactoryInterface.sol";

import "../LEDState/LEDFactoryInterface.sol";
import "../RoomState/RoomStateFactoryInterface.sol";

import "./ControlStateInterface.sol";

import  '../AccessHub/AccessHubInterface.sol';


contract ControlState is ControlStateInterface, Initializable, Ownable, GSNRecipient {

    //Events
    event SiteAdded(address SiteAddress, string SiteName);
    event SiteDeleted(address SiteAddress);
    event newProxyAdmin(address _newProxyAdmin);
    event SiteNameChange(address _SiteID, string _newSiteName);

    SiteStateInterface private genericSiteStateInterface;
    SiteStateFactoryInterface public genericSiteStateFactoryInterface;

    RoomStateFactoryInterface public RoomStateFactoryInterfaceCreol;

    LEDFactoryInterface public LEDFactoryInterfaceCreol;

    AccessHubInterface public credentials;



    struct Site {
        bool IsRegistered;
        bool IsActive;
        string SiteName;
    }

    address ControlAddress;

    bool public ControlIsRegistered;
    bool public ControlIsActive;
    string public ControlName;
    address[] public SiteAddresses;

    address public proxyAdmin;

    address private allowedGSNAddress;
    //Site state address
    mapping (address => Site) public SiteIDtoSiteData;


    modifier onlyAccessHub(){
        require(credentials.checkHasAccess(_msgSender(), AccessHubInterface.ContractTypes.ControlState) || _msgSender() == owner(), "Caller, not registered in access hub");
        _;
    }

    //Functions
    constructor() public {
    }

    function initialize(address owner, address _accessHub, address _allowedGSNAddress, string memory _ControlName, address _SiteStateFactory, address _LEDFactory, address _RoomStateFactory) public initializer {

        RoomStateFactoryInterfaceCreol = RoomStateFactoryInterface(_RoomStateFactory);

        LEDFactoryInterfaceCreol = LEDFactoryInterface(_LEDFactory);

        genericSiteStateFactoryInterface = SiteStateFactoryInterface(_SiteStateFactory);

        credentials = AccessHubInterface(_accessHub);

        ControlAddress = _accessHub;
        ControlIsRegistered = true;
        ControlIsActive  = true;
        ControlName = _ControlName;
        allowedGSNAddress = _allowedGSNAddress;

        if (owner == address(0)) {
            Ownable.initialize(_msgSender());
        }
        else {
            Ownable.initialize(owner);
        }
        GSNRecipient.initialize();

    }

    function IsRegistered (address _SiteID) public view returns(bool SiteStatus) {
        return (SiteIDtoSiteData[_SiteID].IsRegistered);
    }

    function IsActive (address _SiteID) public view returns(bool SiteStatus) {
        return (SiteIDtoSiteData[_SiteID].IsActive);
    }

    function AddSite (address _SiteID, string memory _SiteName) onlyAccessHub public {
        if(ControlIsRegistered == true) {
            if (SiteIDtoSiteData[_SiteID].IsRegistered == false) {
                SiteIDtoSiteData[_SiteID].IsRegistered = true;
                SiteIDtoSiteData[_SiteID].IsActive = true;
                SiteIDtoSiteData[_SiteID].SiteName = _SiteName;
                SiteAddresses.push(_SiteID);
                emit SiteAdded(_SiteID, _SiteName);
            }
            else {
                revert("Site is already active");
            }
        }
        else {
            revert("Control is not active");
        }
    }

    function RemoveSite (address _SiteID) onlyAccessHub public {
        if(ControlIsRegistered == true) {
            if (SiteIDtoSiteData[_SiteID].IsActive == true) {
                SiteIDtoSiteData[_SiteID].IsActive = false;
                emit SiteDeleted(_SiteID);
            }
            else {
                revert("Site is not active");
            }
        }
        else {
            revert("Control is not active");
        }
    }
    function EditSiteName (address _SiteID, string memory _newSiteName) onlyAccessHub public {
        if (ControlIsRegistered) {
            if (SiteIDtoSiteData[_SiteID].IsRegistered){
                SiteIDtoSiteData[_SiteID].SiteName = _newSiteName;
                emit SiteNameChange(_SiteID, _newSiteName);
            }
            else {
                revert("Site is not registered");
            }
        }
        else {
            revert("Control is not registered");
        }

    }


    function CreateSite (address _owner, address _accessHub, address _GSNAddress, string memory _siteName, address _RoomStateFactory, address _LEDFactory) public onlyAccessHub {

        bytes memory payLoadData = abi.encodeWithSignature("initialize(address,address,address,string,address,address)",_owner, _accessHub,_GSNAddress, _siteName, _RoomStateFactory, _LEDFactory);

        address _newSite = genericSiteStateFactoryInterface.createSiteStateUpgradeable(proxyAdmin, payLoadData);

        RoomStateFactoryInterfaceCreol.addApprovedSiteState(_newSite);

        LEDFactoryInterfaceCreol.addApprovedRoomState(_newSite);

        AddSite(_newSite,_siteName);
    }
    function getSiteCount() public view returns(uint siteCount){
        return SiteAddresses.length;
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
