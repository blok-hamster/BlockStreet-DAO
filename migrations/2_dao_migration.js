const BlockStreetToken = artifacts.require("BlockStreetToken");
const GovernanceTimeLock = artifacts.require("GovernanceTimeLock");
const BlockStreetGovonor = artifacts.require("BlockStreetGovonor");
const NewSchool = artifacts.require("NewSchool");

module.exports = async function (deployer, network, accounts) {
  //first deploy the voting token contract and gelegate to myself
  await deployer.deploy(BlockStreetToken);
  //let BST = await BlockStreetToken.deployed();
  //await BST.delegate(accounts[0]);
  //let checkPoint = await BST.numCheckpoints(accounts[0]);
  //let BSTaddress = await BST.address
  //console.log(checkPoint.toNumber(), BSTaddress);

  //here we deploy the timeLock contract
  await deployer.deploy(GovernanceTimeLock, 1, [], []);
  //let TimeLock = await GovernanceTimeLock.deployed();
  
  //here we deploy the Govonor contract
  await deployer.deploy(BlockStreetGovonor, BST.address, TimeLock.address);
  let BSG = await BlockStreetGovonor.deployed();

  //let proposerRole = await TimeLock.PROPOSER_ROLE();
  //let executorRole = await TimeLock.EXECUTOR_ROLE();
  //let timeLockAdminRole = await TimeLock.TIMELOCK_ADMIN_ROLE();

  await TimeLock.grantRole(proposerRole, BSG.address);

  //this sets the executor role to everyone
  await TimeLock.grantRole(executorRole, '0x0000000000000000000000000000000000000000');
  
  //here we just revocked the role and the DAO is now fully decentralized
  //await TimeLock.revokeRole(timeLockAdminRole, accounts[0]);
  
  // lets deploy the school contract and simulate a proposal.
  await deployer.deploy(NewSchool);
  let school = await NewSchool.deployed();

  //here i added a new course to the school.
  //await school.addCourse("Bitcoin 101", "Here you'll learn how the blockchain and bitcoin works", accounts[4]);
  //here i join the school as a student and started a course
  //await school.joinSchool({from: accounts[2]});
  //await school.startCourse("Bitcoin 101", {from: accounts[2]});
  //await school.takeTest("Bitcoin 101", {from: accounts[2]});
  //await school.submitTest("Bitcoin 101", 0, {from: accounts[2]});
  //await school.complete("Bitcoin 101", {from: accounts[2]});
  //await school.claimCertificate("Bitcoin 101", {from: accounts[2]});
  //let certHash = await school.getCertHash("Bitcoin 101", {from: accounts[2]});

  //console.log("certHash: " + certHash);

  //Here i transfer ownership to the dao making it fully decentralized 
  await school.transferOwnership(TimeLock.address);
  //This gives us an encodedVersion Of our function Call
  //let encodedFunctionCall = school.contract.methods.addCourse("blockChain 101", "Learn about blockchain", accounts[3]).encodeABI();
  //console.log("Encoded Function: " + encodedFunctionCall);

  //here we make the proposal. thus will return a proposal id which would be used for voting.
  //await BSG.propose(
    //[school.address],
    //[0],
    //[encodedFunctionCall],
    //"Add blockchain 101 as to the course offered.follow the link to learn about the tutor(http://example.xyz)", {from: accounts[5]}
  //);

  //console.log(proposeTx);

   //let proposalId = await proposeTx.results;

   //let tx = await BSG.castVoteWithReason(proposalId, 1, "I loke the course", {from: accounts[0]});
   //console.log(tx.events["VoteCast"]);

};



