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

const LEDFactoryJSON = require('../build/contracts/LEDFactory')
const RoomFactoryJSON = require('../build/contracts/RoomStateFactory')
const SiteFactoryJSON = require('../build/contracts/SiteStateFactory')
const AccessHubJSON = require('../build/contracts/AccessHub')
const ControlStateJSON = require('../build/contracts/ControlState')
const SiteStateJSON = require('../build/contracts/SiteState')
const RoomStateJSON = require('../build/contracts/RoomState')


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
async function setupOZContracts() {
  console.log('Compiling and then pushing...')
  console.log('Running LEDState Fix')
  const ledStateOutput = await exec(`oz deploy LEDState -n ${networkName} -k regular`)
  console.log(ledStateOutput.stdout)
  // console.log(ledStateOutput.stderr)
  console.log('LEDState Library Fix deployed')
  console.log('Redeploying contracts with library linkage')
  const pushOutput2 = await exec(`oz push -n ${networkName}`)
  console.log(pushOutput2.stdout)
  // console.log(pushOutput2.stderr)
  console.log('Contracts pushed again!')
  console.log('Publishing package...')
  const publishOutput = await exec(`oz publish -n ${networkName}`)
  console.log(publishOutput.stdout)
  // console.log(publishOutput.stderr)
  console.log('Contracts Published!')
  console.log('Setup complete!')
  console.log('Checking network file...')
  if (fs.existsSync(`${networkOZDetails}`)) {
    console.log('devNetwork exists')
    devJSON = require(`${networkOZDetails}${devNetworkName}`)
    creolAppAddress = devJSON.app.address
  } else {
    console.log('File not found exiting')
    process.exit(1)
  }
}

async function deployFactory(factoryName, factoryABI) {
  console.log('      ')
  console.log(`-----------Deploying ${factoryName}----------`)
  console.log('      ')

  const factoryOutput = await exec(`oz deploy ${factoryName} -n ${networkName} -k upgradeable`)
  const factoryAddress = factoryOutput.stdout.toString().replace(/\r?\n|\r/g, '')
  console.log(`            new ${factoryName} Address: ${factoryAddress}`)


  const factoryContract = new web3.eth.Contract(factoryABI, factoryAddress, { from: accounts[0]
})
  console.log(`            Initializing ${factoryName}...`)
  console.log('            Fetching Owner...')
  const Owne1 = await factoryContract.methods.owner().call()
  console.log('            Owner set to: ', Owne1)

  let nonceCount = await web3.eth.getTransactionCount(creolSuper)
  const txReceipt = await factoryContract.methods.initialize(creolSuper).send({
    from: creolSuper,
    gas: globalGasLimit,
    gasPrice: globalGasPrice,
    nonce: nonceCount
  })
  const appReceipt = await factoryContract.methods.setAppPackage(creolAppAddress).send({ from: creolSuper,
    gas: globalGasLimit,
    gasPrice: globalGasPrice,
    nonce: nonceCount+1
  })
  console.log('            Fetching Owner...')
  const Owner = await factoryContract.methods.owner().call()
  console.log('            Owner set to: ', Owner)
  return factoryContract
}

async function deployCreolContracts() {
  console.log('      ')
  console.log('-----------Deploying Contract Factories---------')
  console.log('      ')

  deployedLEDFactory = await deployFactory('LEDFactory', LEDFactoryJSON.abi)

  deployedRoomStateFactory = await deployFactory('RoomStateFactory', RoomFactoryJSON.abi)

  deployedSiteStateFactory = await deployFactory('SiteStateFactory', SiteFactoryJSON.abi)

  console.log('      ')
  console.log('------------INITIAL FACTORY DEPLOYMENT COMPLETE---------')
  console.log('      ')
}
async function deployUpgradeableContract(contractName, contractABI) {
  console.log('      ')
  console.log(`---Deploying New ${contractName} for Client.---`)
  console.log('      ')

  const contractOutput = await exec(`oz deploy ${contractName} -n ${networkName} -k upgradeable`)
  const contractAddress = contractOutput.stdout.toString().replace(/\r?\n|\r/g, '')
  console.log(`            new ${contractName} Address:  ${contractAddress}`)
  let nonceCount = await web3.eth.getTransactionCount(creolSuper)
  const contractObject = new web3.eth.Contract(contractABI, contractAddress, { from: creolSuper,
    gas: globalGasLimit,
    gasPrice: globalGasPrice,
    nonce: nonceCount
  })
  console.log(`            Initializing ${contractName} for Client...`)
  console.log('            Fetching Owner...')
  const contractInit = await contractObject.methods.owner().call()
  console.log('            Owner set to: ', contractInit)

  return contractObject
}
async function initTestSite() {
  console.log('      ')
  console.log('-------------Creating Test Site---------------')
  console.log('      ')

  deployedAccessHub = await deployUpgradeableContract('AccessHub', AccessHubJSON.abi)
  const contractOutput = await exec(`oz send-tx --network ${networkName} --to ${deployedAccessHub.options.address} --method initializeAccessHub --args ${creolSuper},${ownerAccount},${GSNAddress}`)
  console.log('            Fetching Owner to verify initialization...')
  const siteOwner = await deployedAccessHub.methods.owner().call()
  console.log('            Owner set to: ', siteOwner)

  deployedControlState = await deployUpgradeableContract('ControlState', ControlStateJSON.abi)

  // THIS WILL FAIL NO DOUBT
  console.log('          Initializing Control State......')
  const controlOutput = await exec(`oz send-tx --network ${networkName} --to ${deployedControlState.options.address} --method initialize --args ${creolSuper},${deployedAccessHub.options.address},${GSNAddress},"${creolControlName}",${deployedSiteStateFactory.options.address},${deployedLEDFactory.options.address},${deployedRoomStateFactory.options.address}`)
  console.log('            Fetching Owner to verify initialization...')
  const controlOwner = await deployedControlState.methods.owner().call()
  console.log('            Owner set to: ', controlOwner)

  // Reload the JSON here again
  creolProxyAddress = devJSON.proxyAdmin.address
  console.log(`Setting ProxyAdmin to: ${creolProxyAddress}`)
  let nonceCount = await web3.eth.getTransactionCount(creolSuper)
  await deployedControlState.methods.setProxyAdmin(creolProxyAddress).send({
    from: creolSuper,
    gas: globalGasLimit,
    gasPrice: globalGasPrice,
    nonce: nonceCount
  })
  console.log('            Proxy Admin Set')
  console.log('            Adding ControlState to approved lists on the factories')

  await deployedLEDFactory.methods.addApprovedRoomState(deployedControlState.options.address).send({
    from: creolSuper,
    gas: globalGasLimit,
    gasPrice: globalGasPrice,
    nonce: nonceCount + 1
  })
  await deployedRoomStateFactory.methods.addApprovedSiteState(deployedControlState.options.address)
    .send({
      from: creolSuper,
      gas: globalGasLimit,
      gasPrice: globalGasPrice,
      nonce: nonceCount+2
    })
  await deployedSiteStateFactory.methods.addApprovedControlState(deployedControlState.options.address)
    .send({
      from: creolSuper,
      gas: globalGasLimit,
      gasPrice: globalGasPrice,
      nonce: nonceCount+3
    })

  console.log('            Control State added to factories. Setup now complete and ready for Site/Room Creation')
}

async function deployTestSite(siteName) {
  console.log('Deploying test site with name: ', siteName)
  let nonceCount = await web3.eth.getTransactionCount(creolSuper)
  if (deployedControlState !== null) {
    await deployedControlState.methods.CreateSite(
      ownerAccount,
      deployedAccessHub.options.address,
      GSNAddress,
      siteName,
      deployedRoomStateFactory.options.address,
      deployedLEDFactory.options.address).send({
      from: creolSuper,
      gas: globalGasLimit,
      gasPrice: globalGasPrice,
      nonce: nonceCount
    })
    console.log(`Site ${siteName} deployed`)
  } else {
    console.error('NO DEPLOYED CONTROL STATE. ABORTING')
    process.exit(1)
  }
}
async function deployTestRoom(siteAddress, roomName, numLEDs, creezyCOAP, creezyName, ledWattage) {
  console.log(`Deploying ${roomName} with ${numLEDs} LEDs at ${ledWattage} Watts in creezy ${creezyName}`)
  if (deployedRoomStateFactory !== null) {
    const siteStateContract = new web3.eth.Contract(SiteStateJSON.abi, siteAddress, { from: creolSuper })
    let nonceCount = await web3.eth.getTransactionCount(creolSuper)
    await siteStateContract.methods.CreateRoom(deployedAccessHub.options.address, GSNAddress, roomName).send({
      from: creolSuper,
      gas: globalGasLimit,
      gasPrice: globalGasPrice,
      nonce: nonceCount
    })

    const roomCount = await siteStateContract.methods.getRoomCount().call()
    const newRoomAddress = await siteStateContract.methods.RoomAddresses(roomCount - 1).call()
    console.log(`Room Deployed at: ${newRoomAddress}`)
    const roomStateContract = new web3.eth.Contract(RoomStateJSON.abi, newRoomAddress, { from: creolSuper })
    await roomStateContract.methods.addCreezy(creezyCOAP, creezyName, numLEDs, deployedAccessHub.options.address, 1, ledWattage).send({
      from: creolSuper,
      gas: globalGasLimit,
      gasPrice: globalGasPrice,
      nonce: nonceCount+1
    })
    const LEDAddresses = await roomStateContract.methods.getGroupAddresses(creezyName).call()
    console.log(`LEDs Deployed at: ${LEDAddresses}`)
  } else {
    console.error('No deployed room state factory. aborting')
    process.exit(1)
  }
}
async function deploySimulatedSystem() {
  // Create a dummy system with random number of sites (min 2, max 10) and rooms (min 1 max 5)
  const numSites = Math.floor(Math.random() * 10) + 2
  console.log(`Creating ${numSites} sites in test system`)
  for (let i = 0; i < numSites; i++) {
    const SiteCount = await deployedControlState.methods.getSiteCount().call()
    console.log('SiteCount: ', SiteCount)
    await deployTestSite(`Site-${i}`)

    const SiteAddress = await deployedControlState.methods.SiteAddresses(SiteCount).call()
    // Random amounts of rooms 1-5
    const numRooms = Math.floor(Math.random() * 5) + 1
    console.log(`Site ${i} has ${numRooms} Rooms`)
    for (let j = 0; j < numRooms; j++) {
    // Random amounts of LEDs 1-10 (Max is 10 functionally per block (mainnet its larger but)
      const numLEDs = Math.floor(Math.random() * 5) + 1
      // Random LED Wattage
      const numWatts = Math.floor(Math.random() * 12) + 1
      await deployTestRoom(SiteAddress, `Site-${i}-Room-${j}`, numLEDs, 'TestCoapAddress', `Site-${i}-Room-${j}-Creezy-1`, numWatts)
    }
  }
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

  await setupOZContracts()
  if (deployFactories) {
    await deployCreolContracts()
  }
  if (deployTestSiteFlag) {
    console.log('Setup OZ complete, now deploying test site')
    await initTestSite()
    console.log('Creol Control State Initialized')

    await deploySimulatedSystem()


    process.exit(0)
  }
}

main()
