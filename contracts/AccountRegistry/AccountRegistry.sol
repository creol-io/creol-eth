pragma solidity ^0.5.17;


import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol";

import "./AccountRegistryInterface.sol";

contract AccountRegistry is AccountRegistryInterface, Initializable, Ownable {

    event AccountRegistryInitialized(address creolSuper);
    event AccessHubAdded(address AccessHubAddress, string AccessHubName);
    event AccessHubDeleted(address AccessHubAddress);
    event AccessHubNameChange(address _AccessHubID, string _newAccessHubName);

    struct AccessHub {
        bool IsRegistered;
        bool IsActive;
        string AccessHubName;
    }
    
    struct User {
        bool IsActive;
        address[] userAccessHubs;
    }

    bool public CreolSuperIsRegistered;
    bool public CreolSuperIsActive;

    address[] public AccessHubAddresses;

    mapping (address => AccessHub) public AccessHubIDtoAccessHubData;
    
    mapping (address => User ) public userAddresstoAccessHubData;
    

    modifier onlyCreolSuper(){
        require(_msgSender() == owner(), "Caller, not CreolSuper");
        _;
    }
    constructor() public {
    }

    function initialize(address _creolSuper) public initializer {
        CreolSuperIsActive = true;
        CreolSuperIsRegistered = true;

        if (_creolSuper == address(0)) {
            Ownable.initialize(_msgSender());

        }
        else {
            Ownable.initialize(_creolSuper);
        }
        emit AccountRegistryInitialized(_creolSuper);
    }

    function IsRegistered (address _AccessHubID) public view returns(bool AccessHubStatus) {
        return (AccessHubIDtoAccessHubData[_AccessHubID].IsRegistered);
    }

    function IsActive (address _AccessHubID) public view returns(bool AccessHubStatus) {
        return (AccessHubIDtoAccessHubData[_AccessHubID].IsActive);
    }

    function AddAccessHub (address _AccessHubID, string memory _AccessHubName) onlyCreolSuper public {
        if(CreolSuperIsRegistered == true) {
            if (AccessHubIDtoAccessHubData[_AccessHubID].IsRegistered == false) {
                AccessHubIDtoAccessHubData[_AccessHubID].IsRegistered = true;
                AccessHubIDtoAccessHubData[_AccessHubID].IsActive = true;
                AccessHubIDtoAccessHubData[_AccessHubID].AccessHubName = _AccessHubName;
                AccessHubAddresses.push(_AccessHubID);
                emit AccessHubAdded(_AccessHubID, _AccessHubName);
            }
            else {
                revert("AccessHub is already active");
            }
        }
        else {
            revert("CreolSuper is not active");
        }
    }

    function RemoveAccessHub (address _AccessHubID) onlyCreolSuper public {
        if(CreolSuperIsRegistered == true) {
            if (AccessHubIDtoAccessHubData[_AccessHubID].IsActive == true) {
                AccessHubIDtoAccessHubData[_AccessHubID].IsActive = false;
                emit AccessHubDeleted(_AccessHubID);
            }
            else {
                revert("AccessHub is not active");
            }
        }
        else {
            revert("CreolSuper is not active");
        }
    }

    function EditAccessHubName (address _AccessHubID, string memory _newAccessHubName) onlyCreolSuper public {
        if (CreolSuperIsRegistered) {
            if (AccessHubIDtoAccessHubData[_AccessHubID].IsRegistered){
                AccessHubIDtoAccessHubData[_AccessHubID].AccessHubName = _newAccessHubName;
                emit AccessHubNameChange(_AccessHubID, _newAccessHubName);
            }
            else {
                revert("AccessHub is not registered");
            }
        }
        else {
            revert("CreolSuper is not registered");
        }
    }
    function setUserRegistration(address _user, address[] memory _AccessHubs) public onlyCreolSuper {
        
        userAddresstoAccessHubData[_user].userAccessHubs = _AccessHubs;
        userAddresstoAccessHubData[_user].IsActive = true;
    }
    
    function getUserHubs(address _user) public view returns (address[] memory _AccessHubs){
        return userAddresstoAccessHubData[_user].userAccessHubs;
    }
    
    function getAccessHubCount() public view returns(uint AccessHubCount){
        return AccessHubAddresses.length;
    }

}
