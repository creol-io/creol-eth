const {
  deployRelayHub,
  runRelayer,
  fundRecipient,
} = require('@openzeppelin/gsn-helpers');
const Web3 = require('web3')
const { setupLoader } = require('@openzeppelin/contract-loader')
const HDWalletProvider = require('@truffle/hdwallet-provider')

const { projectId, mnemonic, mnemonicGanache } = require('../secrets.json');


const MaticNode = new HDWalletProvider(
  mnemonic, 'https://rpc-mainnet.matic.network/'
  , 0, 10)

const web3 = new Web3(MaticNode);


async function main(){
	console.log("deploying relay hub");
	accounts = await web3.eth.getAccounts();
	console.log("Default account: ", accounts[0]);
	balance = await web3.eth.getBalance(accounts[0]);
	console.log("Account Balance: ", balance);
	await deployRelayHub(web3);
}

main();