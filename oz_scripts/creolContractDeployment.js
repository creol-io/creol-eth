const Web3 = require('web3')
const { setupLoader } = require('@openzeppelin/contract-loader')
const HDWalletProvider = require('@truffle/hdwallet-provider')
const readline = require('readline')
const fs = require('fs')
const util = require('util')
const { execSync } = require('child_process')
const exec = util.promisify(require('child_process').exec)

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
})


const AccountRegistryJSON = require('../build/contracts/AccountRegistry')



// CONSTANTS AND GLOBAL VARS
// TODO: Convert this into options in a CLI context
const { projectId, mnemonic, mnemonicGanache } = require('../secrets.json')

const deployTestSiteFlag = true
const deployFactories = true
const redeploy = true

const creolControlName = 'CreolDevelopment80001'
const networkName = 'maticMumbai'
const devNetworkName = 'dev-80001'
const localProvider = 'https://localhost:7545'
const networkOZDetails = '../.openzeppelin/'
const globalGasLimit = 10000000
const globalGasPrice = 1e9
let accounts = null
let ownerAccount = null
let creolSuper = null
let GSNAddress = null

let deployedLEDFactory = null
let deployedRoomStateFactory = null
let deployedSiteStateFactory = null
let deployedAccessHub = null
let deployedControlState = null

const RinkebyInfuraNode = new HDWalletProvider(
  mnemonicGanache, `https://rinkeby.infura.io/v3/${projectId}`
  , 0, 10)

const MaticNode = new HDWalletProvider(
  mnemonicGanache, 'https://rpc-mumbai.matic.today'
  , 0, 10)

const web3 = new Web3(MaticNode)
let loader = null
let devJSON = null
let creolAppAddress = null
let creolProxyAddress = null


// TODO: FIND A WAY TO LOAD THIS DYNAMICALLY, THIS WILL FAIL ON A FIRST LOAD
console.log(networkOZDetails)
if (fs.existsSync(networkOZDetails)) {
  // console.log('Network File Found')
  // devJSON = require(`${networkOZDetails}${devNetworkName}`)
  // creolAppAddress = devJSON.app.address

}

/** Sets up the OZ contracts by pushing and publishing and ensuring deployment is possible.
 *
 *
 */

async function deployUpgradeableContract(contractName, contractABI) {
  console.log('      ')
  console.log(`---Deploying New ${contractName} for Client.---`)
  console.log('      ')

  const contractOutput = await exec(`oz deploy ${contractName} -n ${networkName} -k upgradeable`)
  const contractAddress = contractOutput.stdout.toString().replace(/\r?\n|\r/g, '')
  console.log(`            new ${contractName} Address:  ${contractAddress}`)
  const contractObject = new web3.eth.Contract(contractABI, contractAddress, { from: creolSuper,
    gas: globalGasLimit,
    gasPrice: globalGasPrice })
  console.log(`            Initializing ${contractName} for Client...`)
  console.log('            Fetching Owner...')
  const contractInit = await contractObject.methods.owner().call()
  console.log('            Owner set to: ', contractInit)

  return contractObject
}



async function main() {
  accounts = await web3.eth.getAccounts()
  loader = setupLoader({ provider: web3 })

  creolSuper = accounts[0]
  console.log('Creol Super Account: ', creolSuper)
  ownerAccount = accounts[1]
  console.log('Owner Account: ', ownerAccount)
  GSNAddress = accounts[2]
  console.log('GSN Account: ', GSNAddress)

  const accountOutput = await exec(`oz accounts -n ${networkName}`)
  console.log('OZ Accounts Loaded')
  console.log(accountOutput.stdout)
  // console.log(accountOutput.stderr)
  const contractReturn = await deployUpgradeableContract('AccountRegistry', AccountRegistryJSON.abi)

  process.exit(0)
}

main()
