# Creol-Eth
[![All Contributors](https://img.shields.io/badge/all_contributors-1-orange.svg?style=flat-square)](#contributors)

These contracts are designed to be integrated in DABEs (Decentralized Autonomous Built Environments) and used to monitor the LED states of a Creol Capable DALI controlled system. Combined with creol-carbon-eth and GridMix, these repositories can then be used to carbon offset the DABEs in real-time using real metrics and VCS style carbon credits that can be purchased from the CreolDAO or CreolMarketplace.

 ** This project is pre-alpha and as a result this repository is a work in progress

## Quick Start 

1. `npm install` will install all the required packages to run these smart contracts. 

2. Run `truffle compile`  to compile the contracts with the dependencies such as openzeppelin/oraclize (now provable) etc. 

3. Contracts can then be deployed with [Remix IDE](https://remix.ethereum.org/)
## Background

## Documentation
The Creol-eth documentation can be found here at [Creol - Read the Docs](https://creol.readthedocs.io) 
### Contract Structure
Folder structure is as follows and is subject to change.
```
creol-eth
|	package.json
|	README.md
└───contracts
|	|truffle-config.js
|	└───contracts
|		|Migrations.sol
|		└───GridMix
|			|GridMix.sol
|		└───LEDState
|			|LEDFactory.sol
|			|LEDFactoryInterface.sol
|			|LEDLibrary.sol
|			|LEDState.sol
|			|LEDStateInterface.sol
|		└───RoomState
|			|RoomState.sol

```
## GridMix
This is an oracle implementation using the provableAPI to pull the current electrical grix mid for carbon offsetting against the LED usage.

## LEDState
Series of contracts and contract factories to track LED usage and operate the DALI controlled luminaires remotely. 

## RoomState
Contract based on DALI-like grouping for LEDState contracts. Allows for group management and control.

## Development
Creol-Eth is constantly under development. Contributions are always welcome. 

Please follow the guide at [Developer's Guide](https://creol.readthedocs.io/contributing.html) if you want to contribute!
## License
Creol-Eth is licensed under [Apache 2.0](LICENSE.txt)