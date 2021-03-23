pragma solidity ^0.5.17;


import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/GSN/GSNRecipient.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol";

import "../ControlState/ControlStateInterface.sol";
import "../LEDState/LEDStateInterface.sol";
import "../RoomState/RoomStateInterface.sol";
import "../SiteState/SiteStateInterface.sol";

import "./AccessHubInterface.sol";






contract AccessHub is AccessHubInterface, Initializable, Ownable, GSNRecipient {


     using Roles for Roles.Role;

    event AccessLevelGranted(address userAddress, ContractTypes AccessLevel);
    event AccessLevelRemoved(address userAddress, ContractTypes AccessLevel);
    event newControlState(address newControlState);
    
     address public creolSuper;
     address public allowedGSNAddress;

     Roles.Role private _buildingManagers;

     Roles.Role private _officeAdmin;

     Roles.Role private _officeUser;

     Roles.Role private _deskUser;

    address public registeredControlState;
    
     modifier onlyCreolSuper(){
        require(_msgSender() == creolSuper, "caller is not creolSuper");
        _;
    }

    constructor() public {

    }

    // Requires 3 seperate address otherwise it fails

    function initializeAccessHub(address _owner, address _creolSuper, address _GSNAddress) public initializer {
        allowedGSNAddress = _GSNAddress;
        creolSuper = _creolSuper;
        GSNRecipient.initialize();
        Ownable.initialize(_owner);

        _buildingManagers.add(_owner);
        emit AccessLevelGranted(_owner, ContractTypes.ControlState);

        _buildingManagers.add(_creolSuper);
        emit AccessLevelGranted(_creolSuper, ContractTypes.ControlState);

        _buildingManagers.add(_GSNAddress);
        emit AccessLevelGranted(_GSNAddress, ContractTypes.ControlState);
    }


    function setGSNAllowed(address _newGSNAddress) public onlyOwner {
        removeAccess(allowedGSNAddress, ContractTypes.ControlState);
        allowedGSNAddress = _newGSNAddress;
        addAccess(allowedGSNAddress, ContractTypes.ControlState);
    }

    function setCreolSuper(address _newCreolSuper) public onlyCreolSuper {
        removeAccess(creolSuper, ContractTypes.ControlState);
        creolSuper = _newCreolSuper;
        addAccess(creolSuper, ContractTypes.ControlState);
    }
    /**
     * This function assumes that the methodID is computed offchain as well as its parameters are packed accordingly
     *
     */

    function checkAndSendFunction( bytes memory packedMethodCall, address destination, ContractTypes destinationType) public {

        address sender = _msgSender();

        if (destinationType == ContractTypes.ControlState) {
            require(_buildingManagers.has(sender), "Not a building manager");

            ControlStateInterface tempInterface = ControlStateInterface(destination);
            address(tempInterface).call(packedMethodCall);

        }
        else if (destinationType == ContractTypes.SiteState) {
            require(_buildingManagers.has(sender) || _officeAdmin.has(sender), "Not a site manager");

            SiteStateInterface tempInterface = SiteStateInterface(destination);
            address(tempInterface).call(packedMethodCall);

        }
        else if(destinationType == ContractTypes.RoomState) {
            require(_buildingManagers.has(sender) || _officeAdmin.has(sender) || _officeUser.has(sender), "Not an office manager");

            RoomStateInterface tempInterface = RoomStateInterface(destination);
            address(tempInterface).call(packedMethodCall);

        }
        else if(destinationType == ContractTypes.LEDState) {
            require(_buildingManagers.has(sender) || _officeAdmin.has(sender) || _officeUser.has(sender) || _deskUser.has(sender), "Not an office user");

            LEDStateInterface tempInterface = LEDStateInterface(destination);
            address(tempInterface).call(packedMethodCall);

        }
        else {
            revert("Invalid destinationType");

        }
    }
    function setRegisteredControlState(address _controlState) onlyCreolSuper public {
        registeredControlState = _controlState;
        emit newControlState(_controlState);
    }
    function acceptRelayedCall(
        address,
        address from,
        bytes calldata,
        uint256,
        uint256,
        uint256,
        uint256,
        bytes calldata,
        uint256
    ) external view returns (uint256, bytes memory)  {

        //emit emittedMsgSender(_msgSender());
        //emit emittedAllowedAddress(allowedAddress);
        if(checkHasAccess(from, ContractTypes.ControlState) || checkHasAccess(from, ContractTypes.SiteState) || checkHasAccess(from, ContractTypes.RoomState) || checkHasAccess(from, ContractTypes.LEDState) ){
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


    function addAccess(address userAddress, ContractTypes destinationType) public {

        address sender = _msgSender();

        if (destinationType == ContractTypes.ControlState) {
            require(_buildingManagers.has(sender), "Not a building manager");

            _buildingManagers.add(userAddress);
            emit AccessLevelGranted(userAddress, destinationType);

        }
        else if (destinationType == ContractTypes.SiteState) {
            require(_buildingManagers.has(sender) || _officeAdmin.has(sender), "Not a site manager");

            _officeAdmin.add(userAddress);
            emit AccessLevelGranted(userAddress, destinationType);


        }
        else if(destinationType == ContractTypes.RoomState) {
            require(_buildingManagers.has(sender) || _officeAdmin.has(sender) || _officeUser.has(sender), "Not an office manager");

            _officeUser.add(userAddress);
            emit AccessLevelGranted(userAddress, destinationType);

        }
        else if(destinationType == ContractTypes.LEDState) {
            require(_buildingManagers.has(sender) || _officeAdmin.has(sender) || _officeUser.has(sender) || _deskUser.has(sender), "Not an office user");

            _deskUser.add(userAddress);
            emit AccessLevelGranted(userAddress, destinationType);



        }
        else {
            revert("Invalid destinationType");

        }
    }

    function removeAccess(address userAddress, ContractTypes destinationType) public {

        address sender = _msgSender();

        if (destinationType == ContractTypes.ControlState) {
            require(_buildingManagers.has(sender), "Not a building manager");

            _buildingManagers.remove(userAddress);
            emit AccessLevelRemoved(userAddress, destinationType);

        }
        else if (destinationType == ContractTypes.SiteState) {
            require(_buildingManagers.has(sender) || _officeAdmin.has(sender), "Not a site manager");

            _officeAdmin.remove(userAddress);
            emit AccessLevelRemoved(userAddress, destinationType);


        }
        else if(destinationType == ContractTypes.RoomState) {
            require(_buildingManagers.has(sender) || _officeAdmin.has(sender) || _officeUser.has(sender), "Not an office manager");

            _officeUser.remove(userAddress);
            emit AccessLevelRemoved(userAddress, destinationType);

        }
        else if(destinationType == ContractTypes.LEDState) {
            require(_buildingManagers.has(sender) || _officeAdmin.has(sender) || _officeUser.has(sender) || _deskUser.has(sender), "Not an office user");

            _deskUser.remove(userAddress);
            emit AccessLevelRemoved(userAddress, destinationType);

        }
        else {
            revert("Invalid destinationType");

        }

    }
    function checkHasAccess(address _accountToCheck, ContractTypes destinationType) public view returns (bool hasAccess) {

        address sender = _accountToCheck;

        if (destinationType == ContractTypes.ControlState) {
            hasAccess = _buildingManagers.has(sender);
            return hasAccess;
        }
        else if (destinationType == ContractTypes.SiteState) {
            hasAccess = _buildingManagers.has(sender);
            if(!hasAccess){
                hasAccess = _officeAdmin.has(sender);
            }

            return hasAccess;

        }
        else if(destinationType == ContractTypes.RoomState) {
            hasAccess = _buildingManagers.has(sender);

            if(!hasAccess){
                hasAccess = _officeAdmin.has(sender);
            }
            if(!hasAccess){
                hasAccess = _officeUser.has(sender);
            }

            return hasAccess;

        }
        else if(destinationType == ContractTypes.LEDState) {

            hasAccess = _buildingManagers.has(sender);
            if(!hasAccess){
                hasAccess = _officeAdmin.has(sender);
            }
             if(!hasAccess){
                hasAccess = _officeUser.has(sender);
            }
             if(!hasAccess){
                hasAccess = _deskUser.has(sender);
            }

            return hasAccess;

        }
        else {
            revert("Invalid destinationType");

        }

    }

}
