# Solidity API

## Directory

_Protocol directory_

### service

```solidity
address service
```

_Service address_

### ContractInfo

```solidity
struct ContractInfo {
  address addr;
  enum IDirectory.ContractType contractType;
  string description;
}
```

### contractRecordAt

```solidity
mapping(uint256 => struct Directory.ContractInfo) contractRecordAt
```

### lastContractRecordIndex

```solidity
uint256 lastContractRecordIndex
```

_Index of last contract record_

### indexOfContract

```solidity
mapping(address => uint256) indexOfContract
```

### ProposalInfo

```solidity
struct ProposalInfo {
  address pool;
  uint256 proposalId;
  string description;
}
```

### proposalRecordAt

```solidity
mapping(uint256 => struct Directory.ProposalInfo) proposalRecordAt
```

### lastProposalRecordIndex

```solidity
uint256 lastProposalRecordIndex
```

_Index of last proposal record_

### Event

```solidity
struct Event {
  enum IDirectory.EventType eventType;
  address pool;
  uint256 proposalId;
  string description;
  string metaHash;
}
```

### events

```solidity
mapping(uint256 => struct Directory.Event) events
```

### lastEventIndex

```solidity
uint256 lastEventIndex
```

_Index of last event record_

### ContractRecordAdded

```solidity
event ContractRecordAdded(uint256 index, address addr, enum IDirectory.ContractType contractType)
```

_Event emitted on creation of contract record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Record index |
| addr | address | Contract address |
| contractType | enum IDirectory.ContractType | Contract type |

### ProposalRecordAdded

```solidity
event ProposalRecordAdded(uint256 index, address pool, uint256 proposalId)
```

_Event emitted on creation of proposal record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Record index |
| pool | address | Pool address |
| proposalId | uint256 | Proposal ID |

### ServiceSet

```solidity
event ServiceSet(address service)
```

_Event emitted on service change_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| service | address | Service address |

### ContractDescriptionSet

```solidity
event ContractDescriptionSet(uint256 index, string description)
```

_Event emitted on change of contract description_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Record index |
| description | string | Description |

### ProposalDescriptionSet

```solidity
event ProposalDescriptionSet(uint256 index, string description)
```

_Event emitted on change of proposal description_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Record index |
| description | string | Description |

### EventSet

```solidity
event EventSet(enum IDirectory.EventType eventType, address pool, uint256 proposalId)
```

_Event emitted on creation of event_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| eventType | enum IDirectory.EventType | Event type |
| pool | address | Pool address |
| proposalId | uint256 | Proposal ID |

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize() public
```

_Constructor function, can only be called once_

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeTo} and {upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

```solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```_

### addContractRecord

```solidity
function addContractRecord(address addr, enum IDirectory.ContractType contractType) external returns (uint256 index)
```

_Add contract record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | Contract address |
| contractType | enum IDirectory.ContractType | Contract type |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Record index |

### addProposalRecord

```solidity
function addProposalRecord(address pool, uint256 proposalId) external returns (uint256 index)
```

_Add proposal record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Record index |

### addEventRecord

```solidity
function addEventRecord(address pool, enum IDirectory.EventType eventType, uint256 proposalId, string description, string metaHash) external returns (uint256 index)
```

_Add event record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| eventType | enum IDirectory.EventType | Event type |
| proposalId | uint256 | Proposal ID |
| description | string | Description |
| metaHash | string | Hash value of event metadata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Record index |

### setService

```solidity
function setService(address service_) external
```

_Set Service in Directory_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| service_ | address | Service address |

### setContractDescription

```solidity
function setContractDescription(uint256 index, string description) external
```

_Set contract description at directory index_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Directory index |
| description | string | Description |

### setProposalDescription

```solidity
function setProposalDescription(uint256 index, string description) external
```

_Set proposal description at directory index_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Directory index |
| description | string | Description |

### typeOf

```solidity
function typeOf(address addr) external view returns (enum IDirectory.ContractType)
```

_Return type of contract for a given address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | Contract index |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | enum IDirectory.ContractType | ContractType |

### getGlobalProposalId

```solidity
function getGlobalProposalId(address pool, uint256 proposalId) public view returns (uint256)
```

_Return global proposal ID_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Global proposal ID |

### onlyService

```solidity
modifier onlyService()
```

### test83122

```solidity
function test83122() external pure returns (uint256)
```

## GovernanceToken

_Company (Pool) Governance Token_

### service

```solidity
contract IService service
```

_Service address_

### pool

```solidity
address pool
```

_Pool address_

### LockedBalance

```solidity
struct LockedBalance {
  uint256 amount;
  uint256 deadline;
  uint256 forVotes;
  uint256 againstVotes;
}
```

### _lockedInProposal

```solidity
mapping(address => mapping(uint256 => struct GovernanceToken.LockedBalance)) _lockedInProposal
```

_Votes lockup for address_

### totalTGELockedTokens

```solidity
uint256 totalTGELockedTokens
```

_Amount of tokens that were minted but currently locked in TGE vesting contract(s)_

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(address pool_, struct IGovernanceToken.TokenInfo info) public
```

_Constructor function, can only be called once_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool_ | address | Pool |
| info | struct IGovernanceToken.TokenInfo | Token info |

### mint

```solidity
function mint(address to, uint256 amount) external
```

_Mint token_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | Recipient |
| amount | uint256 | Amount of tokens |

### burn

```solidity
function burn(address from, uint256 amount) external
```

_Burn token_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | Target |
| amount | uint256 | Amount of tokens |

### lock

```solidity
function lock(address account, uint256 amount, bool support, uint256 deadline, uint256 proposalId) external
```

_Lock votes (tokens) as a result of voting for a proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Token holder |
| amount | uint256 | Amount of tokens |
| support | bool | Vote against or for proposal |
| deadline | uint256 | Lockup deadline |
| proposalId | uint256 | Proposal ID |

### increaseTotalTGELockedTokens

```solidity
function increaseTotalTGELockedTokens(uint256 _amount) external
```

_Increases amount of tokens locked in TGE vesting contract(s)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _amount | uint256 | amount of tokens |

### decreaseTotalTGELockedTokens

```solidity
function decreaseTotalTGELockedTokens(uint256 _amount) external
```

_Decreases amount of tokens locked in TGE vesting contract(s)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _amount | uint256 | amount of tokens |

### unlockedBalanceOf

```solidity
function unlockedBalanceOf(address account, uint256 proposalId) public view returns (uint256)
```

_Return amount of tokens that account owns, excluding tokens locked up as a result of voting for a proposalId_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Token holder |
| proposalId | uint256 | Proposal ID |

### lockedBalanceOf

```solidity
function lockedBalanceOf(address account, uint256 proposalId) public view returns (uint256)
```

_Return amount of locked up tokens for a given account and proposal ID_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Token holder |
| proposalId | uint256 | Proposal ID |

### getLockedInPrposal

```solidity
function getLockedInPrposal(address account, uint256 proposalId) public view returns (struct GovernanceToken.LockedBalance)
```

_Return LockedBalance structure for a given proposal ID and account_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Token holder |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct GovernanceToken.LockedBalance | LockedBalance |

### decimals

```solidity
function decimals() public pure returns (uint8)
```

_Return decimals_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint8 | Decimals |

### cap

```solidity
function cap() public view returns (uint256)
```

_Return cap_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Cap |

### minUnlockedBalanceOf

```solidity
function minUnlockedBalanceOf(address user) public view returns (uint256)
```

_Return least amount of unlocked tokens for any proposal that user might have voted for_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | User address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Minimum unlocked balance |

### _transfer

```solidity
function _transfer(address from, address to, uint256 amount) internal
```

_Transfer tokens from a given user.
Check to make sure that transfer amount is less or equal
to least amount of unlocked tokens for any proposal that user might have voted for._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | User address |
| to | address | Recipient address |
| amount | uint256 | Amount of tokens |

### _burn

```solidity
function _burn(address account, uint256 amount) internal
```

_Burn tokens_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Token holder address |
| amount | uint256 | Amount of tokens |

### _mint

```solidity
function _mint(address account, uint256 amount) internal
```

_Mint tokens_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Token holder address |
| amount | uint256 | Amount of tokens |

### _afterTokenTransfer

```solidity
function _afterTokenTransfer(address from, address to, uint256 amount) internal
```

### onlyPool

```solidity
modifier onlyPool()
```

### onlyTGE

```solidity
modifier onlyTGE()
```

### whenServiceNotPaused

```solidity
modifier whenServiceNotPaused()
```

### test83122

```solidity
function test83122() external pure returns (uint256)
```

## Metadata

_Protocol Metadata_

### service

```solidity
contract IService service
```

_Service address_

### currentId

```solidity
uint256 currentId
```

_Last metadata ID_

### queueInfo

```solidity
mapping(uint256 => struct IMetadata.QueueInfo) queueInfo
```

_Metadata queue_

### ServiceSet

```solidity
event ServiceSet(address service)
```

_Event emitted on service change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| service | address | Service address |

### RecordCreated

```solidity
event RecordCreated(uint256 id, uint256 jurisdiction, string EIN, string date, uint256 entityType)
```

_Event emitted on record creation._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| id | uint256 | Record ID |
| jurisdiction | uint256 | Jurisdiction |
| EIN | string | EIN |
| date | string | Date |
| entityType | uint256 | Entity type |

### RecordDeleted

```solidity
event RecordDeleted(uint256 id)
```

_Event emitted on record removal._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| id | uint256 | Record ID |

### initialize

```solidity
function initialize() public
```

### constructor

```solidity
constructor() public
```

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeTo} and {upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

```solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```_

### setService

```solidity
function setService(address service_) external
```

_Set Service in Metadata_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| service_ | address | Service address |

### createRecord

```solidity
function createRecord(uint256 jurisdiction, string EIN, string dateOfIncorporation, uint256 entityType) external
```

_Create metadata record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | Jurisdiction |
| EIN | string | EIN |
| dateOfIncorporation | string | Date of incorporation |
| entityType | uint256 | Entity type |

### lockRecord

```solidity
function lockRecord(uint256 jurisdiction) external returns (uint256)
```

_Lock metadata record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | Jurisdiction |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Record ID |

### setOwner

```solidity
function setOwner(uint256 id, address owner) external
```

_Set queue item owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| id | uint256 | Queue index |
| owner | address | Owner address |

### deleteRecord

```solidity
function deleteRecord(uint256 id) external
```

_Delete queue record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| id | uint256 | Queue index |

### getQueueInfo

```solidity
function getQueueInfo(uint256 id) external view returns (struct IMetadata.QueueInfo)
```

_Get queue item_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| id | uint256 | Queue index |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct IMetadata.QueueInfo | Queue item |

### jurisdictionAvailable

```solidity
function jurisdictionAvailable(uint256 jurisdiction) external view returns (uint256)
```

_Check if jurisdiction available_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | Jurisdiction |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | 0 if there are no available companies 1 if there are no available companies in current jurisdiction, but exists in other jurisdiction 2 if there are available companies in current jurisdiction |

### onlyService

```solidity
modifier onlyService()
```

### onlyManager

```solidity
modifier onlyManager()
```

### test82312

```solidity
function test82312() external pure returns (uint256)
```

## Pool

_Company Entry Point_

### service

```solidity
contract IService service
```

_Service address_

### token

```solidity
contract IGovernanceToken token
```

_Pool token address_

### tge

```solidity
contract ITGE tge
```

_Last TGE address_

### _ballotQuorumThreshold

```solidity
uint256 _ballotQuorumThreshold
```

_Minimum amount of votes that ballot must receive_

### _ballotDecisionThreshold

```solidity
uint256 _ballotDecisionThreshold
```

_Minimum amount of votes that ballot's choice must receive in order to pass_

### _ballotLifespan

```solidity
uint256 _ballotLifespan
```

_Ballot voting duration, blocks_

### _poolRegisteredName

```solidity
string _poolRegisteredName
```

_Pool name_

### _poolTrademark

```solidity
string _poolTrademark
```

_Pool trademark_

### _poolJurisdiction

```solidity
uint256 _poolJurisdiction
```

_Pool jurisdiction_

### _poolEIN

```solidity
string _poolEIN
```

_Pool EIN_

### _poolMetadataIndex

```solidity
uint256 _poolMetadataIndex
```

_Metadata pool record index_

### _poolEntityType

```solidity
uint256 _poolEntityType
```

_Pool entity type_

### _poolDateOfIncorporation

```solidity
string _poolDateOfIncorporation
```

_Pool date of incorporatio_

### primaryTGE

```solidity
address primaryTGE
```

_Pool's first TGE_

### _tgeList

```solidity
address[] _tgeList
```

_List of all pool's TGEs_

### ballotExecDelay

```solidity
uint256[10] ballotExecDelay
```

_block delay for executeBallot
[0] - ballot value in USDT after which delay kicks in
[1] - base delay applied to all ballots to mitigate FlashLoan attacks.
[2] - delay for TransferETH proposals
[3] - delay for TransferERC20 proposals
[4] - delay for TGE proposals
[5] - delay for GovernanceSettings proposals_

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(address poolCreator_, uint256 jurisdiction_, string poolEIN_, string dateOfIncorporation, uint256 poolEntityType_, uint256 ballotQuorumThreshold_, uint256 ballotDecisionThreshold_, uint256 ballotLifespan_, uint256[10] ballotExecDelay_, uint256 metadataIndex, string trademark) public
```

_Create TransferETH proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolCreator_ | address | Pool owner |
| jurisdiction_ | uint256 | Jurisdiction |
| poolEIN_ | string | EIN |
| dateOfIncorporation | string | Date of incorporation |
| poolEntityType_ | uint256 | Entity type |
| ballotQuorumThreshold_ | uint256 | Ballot quorum threshold |
| ballotDecisionThreshold_ | uint256 | Ballot decision threshold |
| ballotLifespan_ | uint256 | Ballot lifespan |
| ballotExecDelay_ | uint256[10] | Ballot execution delay parameters |
| metadataIndex | uint256 | Metadata index |
| trademark | string | Trademark |

### setToken

```solidity
function setToken(address token_) external
```

_Set pool governance token_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token_ | address | Token address |

### setTGE

```solidity
function setTGE(address tge_) external
```

_Set pool TGE_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge_ | address | TGE address |

### setPrimaryTGE

```solidity
function setPrimaryTGE(address tge_) external
```

_Set pool primary TGE_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge_ | address | TGE address |

### setRegisteredName

```solidity
function setRegisteredName(string registeredName) external
```

_Set pool registered name_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| registeredName | string | Registered name |

### setGovernanceSettings

```solidity
function setGovernanceSettings(uint256 ballotQuorumThreshold_, uint256 ballotDecisionThreshold_, uint256 ballotLifespan_, uint256[10] ballotExecDelay_) external
```

_Set Service governance settings_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| ballotQuorumThreshold_ | uint256 | Ballot quorum theshold |
| ballotDecisionThreshold_ | uint256 | Ballot decision threshold |
| ballotLifespan_ | uint256 | Ballot lifespan |
| ballotExecDelay_ | uint256[10] | Ballot execution delay parameters |

### castVote

```solidity
function castVote(uint256 proposalId, uint256 votes, bool support) external
```

_Cast ballot vote_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Pool proposal ID |
| votes | uint256 | Amount of tokens |
| support | bool | Against or for |

### proposeSingleAction

```solidity
function proposeSingleAction(address target, uint256 value, bytes cd, string description, enum IProposalGateway.ProposalType proposalType, uint256 amountERC20, string metaHash) external returns (uint256 proposalId)
```

_Create pool propsal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| target | address | Proposal transaction recipient |
| value | uint256 | Amount of ETH token |
| cd | bytes | Calldata to pass on in .call() to transaction recipient |
| description | string | Proposal description |
| proposalType | enum IProposalGateway.ProposalType | Type |
| amountERC20 | uint256 | Amount of ERC20 token |
| metaHash | string | Hash value of proposal metadata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Created proposal ID |

### addTGE

```solidity
function addTGE(address tge_) external
```

_Add TGE to TGE archive list_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge_ | address | TGE address |

### getTVL

```solidity
function getTVL() public returns (uint256)
```

_Calculate pool TVL_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Pool TVL |

### executeBallot

```solidity
function executeBallot(uint256 proposalId) external
```

_Execute proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### serviceCancelBallot

```solidity
function serviceCancelBallot(uint256 proposalId) external
```

_Cancel proposal, callable only by Service_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### receive

```solidity
receive() external payable
```

### getPoolTrademark

```solidity
function getPoolTrademark() external view returns (string)
```

_Return pool trademark_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | Trademark |

### getPoolRegisteredName

```solidity
function getPoolRegisteredName() public view returns (string)
```

_Return pool registered name_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | Registered name |

### getBallotQuorumThreshold

```solidity
function getBallotQuorumThreshold() public view returns (uint256)
```

_Return pool proposal quorum threshold_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Ballot quorum threshold |

### getBallotDecisionThreshold

```solidity
function getBallotDecisionThreshold() public view returns (uint256)
```

_Return proposal decision threshold_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Ballot decision threshold |

### getBallotLifespan

```solidity
function getBallotLifespan() public view returns (uint256)
```

_Return proposal lifespan_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Proposal lifespan |

### getPoolJurisdiction

```solidity
function getPoolJurisdiction() public view returns (uint256)
```

_Return pool jurisdiction_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Jurisdiction |

### getPoolEIN

```solidity
function getPoolEIN() public view returns (string)
```

_Return pool EIN_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | EIN |

### getPoolDateOfIncorporation

```solidity
function getPoolDateOfIncorporation() public view returns (string)
```

_Return pool data of incorporation_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | Date of incorporation |

### getPoolEntityType

```solidity
function getPoolEntityType() public view returns (uint256)
```

_Return pool entity type_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Entity type |

### getPoolMetadataIndex

```solidity
function getPoolMetadataIndex() public view returns (uint256)
```

_Return pool metadata index_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Metadata index |

### maxProposalId

```solidity
function maxProposalId() public view returns (uint256)
```

_Return maximum proposal ID_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Maximum proposal ID |

### isDAO

```solidity
function isDAO() public view returns (bool)
```

_Return if pool had a successful TGE_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Is any TGE successful |

### getTGEList

```solidity
function getTGEList() public view returns (address[])
```

_Return list of pool's TGEs_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | TGE list |

### owner

```solidity
function owner() public view returns (address)
```

_Return pool owner_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | Owner address |

### getProposalType

```solidity
function getProposalType(uint256 proposalId) public view returns (enum IProposalGateway.ProposalType)
```

_Return type of proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | enum IProposalGateway.ProposalType | Proposal type |

### _afterProposalCreated

```solidity
function _afterProposalCreated(uint256 proposalId) internal
```

### _getTotalSupply

```solidity
function _getTotalSupply() internal view returns (uint256)
```

_Return token total supply_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total pool token supply |

### _getTotalTGELockedTokens

```solidity
function _getTotalTGELockedTokens() internal view returns (uint256)
```

_Return amount of tokens currently locked in TGE vesting contract(s)_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total pool vesting tokens |

### onlyService

```solidity
modifier onlyService()
```

### onlyServiceOwner

```solidity
modifier onlyServiceOwner()
```

### onlyProposalGateway

```solidity
modifier onlyProposalGateway()
```

### onlyPool

```solidity
modifier onlyPool()
```

### whenServiceNotPaused

```solidity
modifier whenServiceNotPaused()
```

### test83212

```solidity
function test83212() external pure returns (uint256)
```

## ProposalGateway

_Protocol entry point to create any proposal_

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize() public
```

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeTo} and {upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

```solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```_

### createTransferETHProposal

```solidity
function createTransferETHProposal(contract IPool pool, address to, uint256 value, string description, string metaHash) external returns (uint256 proposalId)
```

_Create TransferETH proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | Pool address |
| to | address | Transfer recipient |
| value | uint256 | Token amount |
| description | string | Proposal description |
| metaHash | string | Hash value of proposal metadata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Created proposal's ID |

### createTransferERC20Proposal

```solidity
function createTransferERC20Proposal(contract IPool pool, address token, address to, uint256 value, string description, string metaHash) external returns (uint256 proposalId)
```

_Create TransferERC20 proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | Pool address |
| token | address | Token to be transfered |
| to | address | Transfer recipient |
| value | uint256 | Token amount |
| description | string | Proposal description |
| metaHash | string | Hash value of proposal metadata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Created proposal's ID |

### createTGEProposal

```solidity
function createTGEProposal(contract IPool pool, struct ITGE.TGEInfo info, string description, string metaHash) external returns (uint256 proposalId)
```

_Create TGE proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | Pool address |
| info | struct ITGE.TGEInfo | TGE parameters |
| description | string | Proposal description |
| metaHash | string | Hash value of proposal metadata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Created proposal's ID |

### createGovernanceSettingsProposal

```solidity
function createGovernanceSettingsProposal(contract IPool pool, uint256 ballotQuorumThreshold, uint256 ballotDecisionThreshold, uint256 ballotLifespan, string description, uint256[10] ballotExecDelay_, string metaHash) external returns (uint256 proposalId)
```

_Create GovernanceSettings proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | Pool address |
| ballotQuorumThreshold | uint256 | Ballot quorum threshold |
| ballotDecisionThreshold | uint256 | Ballot decision threshold |
| ballotLifespan | uint256 | Ballot lifespan |
| description | string | Proposal description |
| ballotExecDelay_ | uint256[10] | Ballot execution delay parameters |
| metaHash | string | Hash value of proposal metadata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Created proposal's ID |

### onlyPoolShareholder

```solidity
modifier onlyPoolShareholder(contract IPool pool)
```

### test82312

```solidity
function test82312() external pure returns (uint256)
```

## Service

_Protocol entry point_

### metadata

```solidity
contract IMetadata metadata
```

_Metadata address_

### directory

```solidity
contract IDirectory directory
```

_Directory address_

### whitelistedTokens

```solidity
contract IWhitelistedTokens whitelistedTokens
```

_WhitelistedTokens address_

### proposalGateway

```solidity
address proposalGateway
```

_ProposalGateway address_

### poolBeacon

```solidity
address poolBeacon
```

_Pool beacon_

### tokenBeacon

```solidity
address tokenBeacon
```

_Token beacon_

### tgeBeacon

```solidity
address tgeBeacon
```

_TGE beacon_

### fee

```solidity
uint256 fee
```

_Protocol createPool fee_

### _ballotQuorumThreshold

```solidity
uint256 _ballotQuorumThreshold
```

_Minimum amount of votes that ballot must receive_

### _ballotDecisionThreshold

```solidity
uint256 _ballotDecisionThreshold
```

_Minimum amount of votes that ballot's choice must receive in order to pass_

### _ballotLifespan

```solidity
uint256 _ballotLifespan
```

_Ballot voting duration, blocks_

### uniswapRouter

```solidity
contract ISwapRouter uniswapRouter
```

_UniswapRouter contract address_

### uniswapQuoter

```solidity
contract IQuoter uniswapQuoter
```

_UniswapQuoter contract address_

### _userWhitelist

```solidity
struct EnumerableSetUpgradeable.AddressSet _userWhitelist
```

_Addresses that are allowed to participate in TGE.
If list is empty, anyone can participate._

### protocolTreasury

```solidity
address protocolTreasury
```

_address that collects protocol token fees_

### protocolTokenFee

```solidity
uint256 protocolTokenFee
```

_protocol token fee percentage value with 4 decimals. Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000_

### ballotExecDelay

```solidity
uint256[10] ballotExecDelay
```

_block delay for executeBallot
[0] - ballot value in USDT after which delay kicks in
[1] - base delay applied to all ballots to mitigate FlashLoan attacks.
[2] - delay for TransferETH proposals
[3] - delay for TransferERC20 proposals
[4] - delay for TGE proposals
[5] - delay for GovernanceSettings proposals_

### usdt

```solidity
address usdt
```

_USDT contract address. Used to estimate proposal value._

### weth

```solidity
address weth
```

_WETH contract address. Used to estimate proposal value._

### _managerWhitelist

```solidity
struct EnumerableSetUpgradeable.AddressSet _managerWhitelist
```

_List of managers_

### UserWhitelistedSet

```solidity
event UserWhitelistedSet(address account, bool whitelisted)
```

_Event emitted on change in user's whitelist status._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | User's account |
| whitelisted | bool | Is whitelisted |

### TokenWhitelistedSet

```solidity
event TokenWhitelistedSet(address token, bool whitelisted)
```

_Event emitted on change in tokens's whitelist status._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | Token address |
| whitelisted | bool | Is whitelisted |

### FeeSet

```solidity
event FeeSet(uint256 fee)
```

_Event emitted on fee change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| fee | uint256 | Fee |

### PoolCreated

```solidity
event PoolCreated(address pool, address token, address tge)
```

_Event emitted on pool creation._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| token | address | Pool token address |
| tge | address | Pool primary TGE address |

### SecondaryTGECreated

```solidity
event SecondaryTGECreated(address pool, address tge)
```

_Event emitted on creation of secondary TGE._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| tge | address | Secondary TGE address |

### GovernanceSettingsSet

```solidity
event GovernanceSettingsSet(uint256 quorumThreshold, uint256 decisionThreshold, uint256 lifespan, uint256[10] ballotExecDelay)
```

_Event emitted on change in Service governance settings._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| quorumThreshold | uint256 | quorumThreshold |
| decisionThreshold | uint256 | decisionThreshold |
| lifespan | uint256 | lifespan |
| ballotExecDelay | uint256[10] | ballotExecDelay |

### ProtocolTreasuryChanged

```solidity
event ProtocolTreasuryChanged(address protocolTreasury)
```

_Event emitted on protocol treasury change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| protocolTreasury | address | Proocol treasury address |

### ProtocolTokenFeeChanged

```solidity
event ProtocolTokenFeeChanged(uint256 protocolTokenFee)
```

_Event emitted on protocol token fee change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| protocolTokenFee | uint256 | Protocol token fee |

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(contract IDirectory directory_, address poolBeacon_, address proposalGateway_, address tokenBeacon_, address tgeBeacon_, contract IMetadata metadata_, uint256 fee_, uint256[13] ballotParams, contract ISwapRouter uniswapRouter_, contract IQuoter uniswapQuoter_, contract IWhitelistedTokens whitelistedTokens_, uint256 _protocolTokenFee) public
```

_Constructor function, can only be called once_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| directory_ | contract IDirectory | Directory address |
| poolBeacon_ | address | Pool beacon |
| proposalGateway_ | address | ProposalGateway address |
| tokenBeacon_ | address | Governance token beacon |
| tgeBeacon_ | address | TGE beacon |
| metadata_ | contract IMetadata | Metadata address |
| fee_ | uint256 | createPool protocol fee |
| ballotParams | uint256[13] | [ballotQuorumThreshold, ballotLifespan, ballotDecisionThreshold, ...ballotExecDelay] |
| uniswapRouter_ | contract ISwapRouter | UniswapRouter address |
| uniswapQuoter_ | contract IQuoter | UniswapQuoter address |
| whitelistedTokens_ | contract IWhitelistedTokens | WhitelistedTokens address |
| _protocolTokenFee | uint256 | Protocol token fee |

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeTo} and {upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

```solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```_

### createPool

```solidity
function createPool(contract IPool pool, struct IGovernanceToken.TokenInfo tokenInfo, struct ITGE.TGEInfo tgeInfo, uint256 ballotQuorumThreshold_, uint256 ballotDecisionThreshold_, uint256 ballotLifespan_, uint256 jurisdiction, uint256[10] ballotExecDelay_, string trademark) external payable
```

_Create pool_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | Pool address. If not address(0) - creates new token and new primary TGE for an existing pool. |
| tokenInfo | struct IGovernanceToken.TokenInfo | Pool token parameters |
| tgeInfo | struct ITGE.TGEInfo | Pool TGE parameters |
| ballotQuorumThreshold_ | uint256 | Ballot quorum threshold |
| ballotDecisionThreshold_ | uint256 | Ballot decision threshold |
| ballotLifespan_ | uint256 | Ballot lifespan, blocks. |
| jurisdiction | uint256 | Pool jurisdiction |
| ballotExecDelay_ | uint256[10] | Ballot execution delay parameters |
| trademark | string | Pool trademark |

### createSecondaryTGE

```solidity
function createSecondaryTGE(struct ITGE.TGEInfo tgeInfo) external
```

_Create secondary TGE_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tgeInfo | struct ITGE.TGEInfo | TGE parameters |

### addProposal

```solidity
function addProposal(uint256 proposalId) external
```

_Add proposal to directory_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### addEvent

```solidity
function addEvent(enum IDirectory.EventType eventType, uint256 proposalId, string description, string metaHash) external
```

_Add event to directory_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| eventType | enum IDirectory.EventType | Event type |
| proposalId | uint256 | Proposal ID |
| description | string | Description |
| metaHash | string | Hash value of event metadata |

### addUserToWhitelist

```solidity
function addUserToWhitelist(address account) external
```

_Add user to whitelist_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | User address |

### removeUserFromWhitelist

```solidity
function removeUserFromWhitelist(address account) external
```

_Remove user from whitelist_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | User address |

### addManagerToWhitelist

```solidity
function addManagerToWhitelist(address account) external
```

_Add manager to whitelist_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Manager address |

### removeManagerFromWhitelist

```solidity
function removeManagerFromWhitelist(address account) external
```

_Remove manager from whitelist_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Manager address |

### setFee

```solidity
function setFee(uint256 fee_) external
```

_Set createPool protocol fee_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| fee_ | uint256 | Fee |

### transferCollectedFees

```solidity
function transferCollectedFees(address to) external
```

_Transfer collected createPool protocol fees_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | Transfer recipient |

### setGovernanceSettings

```solidity
function setGovernanceSettings(uint256 ballotQuorumThreshold_, uint256 ballotDecisionThreshold_, uint256 ballotLifespan_, uint256[10] ballotExecDelay_) external
```

_Set Service governance settings_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| ballotQuorumThreshold_ | uint256 | Ballot quorum theshold |
| ballotDecisionThreshold_ | uint256 | Ballot decision threshold |
| ballotLifespan_ | uint256 | Ballot lifespan |
| ballotExecDelay_ | uint256[10] | Ballot execution delay parameters |

### setProtocolTreasury

```solidity
function setProtocolTreasury(address _protocolTreasury) public
```

_Set protocol treasury address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _protocolTreasury | address | Protocol treasury address |

### setProtocolTokenFee

```solidity
function setProtocolTokenFee(uint256 _protocolTokenFee) public
```

_Set protocol token fee_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _protocolTokenFee | uint256 | protocol token fee percentage value with 4 decimals. Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000. |

### cancelBallot

```solidity
function cancelBallot(address _pool, uint256 proposalId) public
```

_Cancel pool's ballot_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pool | address | pool |
| proposalId | uint256 | proposalId |

### pause

```solidity
function pause() public
```

_Pause entire protocol_

### unpause

```solidity
function unpause() public
```

_Unpause entire protocol_

### setUsdt

```solidity
function setUsdt(address usdt_) external
```

_Set USDT token address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| usdt_ | address | Token address |

### setWeth

```solidity
function setWeth(address weth_) external
```

_Set WETH token address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| weth_ | address | Token address |

### isManagerWhitelisted

```solidity
function isManagerWhitelisted(address account) public view returns (bool)
```

_Return manager's whitelist status_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Manager's address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Whitelist status |

### isUserWhitelisted

```solidity
function isUserWhitelisted(address account) public view returns (bool)
```

_Return user's whitelist status_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | User's address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Whitelist status |

### userWhitelist

```solidity
function userWhitelist() external view returns (address[])
```

_Return all whitelisted users_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | Whitelisted addresses |

### userWhitelistLength

```solidity
function userWhitelistLength() external view returns (uint256)
```

_Return number of whitelisted users_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Number of whitelisted users |

### userWhitelistAt

```solidity
function userWhitelistAt(uint256 index) external view returns (address)
```

_Return whitelisted user at particular index_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Whitelist index |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | Whitelisted user's address |

### tokenWhitelist

```solidity
function tokenWhitelist() external view returns (address[])
```

_Return all whitelisted tokens_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | Whitelisted tokens |

### owner

```solidity
function owner() public view returns (address)
```

_Return Service owner_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | Service owner's address |

### paused

```solidity
function paused() public view returns (bool)
```

_Return protocol paused status_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Is protocol paused |

### getBallotQuorumThreshold

```solidity
function getBallotQuorumThreshold() public view returns (uint256)
```

_Return Service ballot quorum threshold_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Ballot quorum threshold |

### getBallotDecisionThreshold

```solidity
function getBallotDecisionThreshold() public view returns (uint256)
```

_Return Service ballot decision threshold_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Ballot decision threshold |

### getBallotLifespan

```solidity
function getBallotLifespan() public view returns (uint256)
```

_Return Service ballot lifespan_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Ballot lifespan |

### getMinSoftCap

```solidity
function getMinSoftCap() public view returns (uint256)
```

_Calculate minimum soft cap for token fee mechanism to work_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | softCap minimum soft cap |

### getProtocolTokenFee

```solidity
function getProtocolTokenFee(uint256 amount) public view returns (uint256)
```

_calculates protocol token fee for given token amount_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | Token amount |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | tokenFee |

### getMaxHardCap

```solidity
function getMaxHardCap(address _pool) public view returns (uint256)
```

_Return max hard cap accounting for protocol token fee_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pool | address | pool to calculate hard cap against |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Maximum hard cap |

### onlyWhitelisted

```solidity
modifier onlyWhitelisted()
```

### onlyManager

```solidity
modifier onlyManager()
```

### onlyPool

```solidity
modifier onlyPool()
```

### test83122

```solidity
function test83122() external pure returns (uint256)
```

## TGE

### token

```solidity
contract IGovernanceToken token
```

_Pool's ERC20 token_

### metadataURI

```solidity
string metadataURI
```

_TGE metadata_

### price

```solidity
uint256 price
```

_TGE token price_

### hardcap

```solidity
uint256 hardcap
```

_TGE hardcap_

### softcap

```solidity
uint256 softcap
```

_TGE softcap_

### minPurchase

```solidity
uint256 minPurchase
```

_Minimal amount of tokens an address can purchase_

### maxPurchase

```solidity
uint256 maxPurchase
```

_Maximum amount of tokens an address can purchase_

### lockupPercent

```solidity
uint256 lockupPercent
```

_Percentage of tokens from each purchase that goes to vesting_

### lockupTVL

```solidity
uint256 lockupTVL
```

_lockup TVL value, if this value reached (via getTVL) users can claim their tokens_

### lockupDuration

```solidity
uint256 lockupDuration
```

_Vesting duration, blocks._

### duration

```solidity
uint256 duration
```

_TGE duration, blocks._

### userWhitelist

```solidity
address[] userWhitelist
```

_Addresses that are allowed to participate in TGE.
If list is empty, anyone can participate._

### _unitOfAccount

```solidity
address _unitOfAccount
```

_Token used as currency to purchase pool's tokens during TGE_

### isUserWhitelisted

```solidity
mapping(address => bool) isUserWhitelisted
```

_Mapping of user's address to whitelist status_

### createdAt

```solidity
uint256 createdAt
```

_Block of TGE's creation_

### purchaseOf

```solidity
mapping(address => uint256) purchaseOf
```

_Mapping of an address to total amount of tokens purchased during TGE_

### lockupTVLReached

```solidity
bool lockupTVLReached
```

_Is lockup TVL reached. Users can claim their tokens only if lockup TVL was reached._

### lockedBalanceOf

```solidity
mapping(address => uint256) lockedBalanceOf
```

_Mapping of an address to total amount of tokens vesting_

### _totalPurchased

```solidity
uint256 _totalPurchased
```

_Total amount of tokens purchased during TGE_

### _totalLocked

```solidity
uint256 _totalLocked
```

_Total amount of tokens vesting_

### isProtocolTokenFeeClaimed

```solidity
bool isProtocolTokenFeeClaimed
```

_Protocol token fee is a percentage of tokens sold during TGE. Returns true if fee was claimed by the governing DAO._

### Purchased

```solidity
event Purchased(address buyer, uint256 amount)
```

_Event emitted on token puchase._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| buyer | address | buyer |
| amount | uint256 | amount of tokens |

### ProtocolTokenFeeClaimed

```solidity
event ProtocolTokenFeeClaimed(address token, uint256 tokenFee)
```

_Event emitted on claim of protocol token fee._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | token |
| tokenFee | uint256 | amount of tokens |

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(address owner_, address token_, struct ITGE.TGEInfo info) public
```

_Constructor function, can only be called once_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner_ | address | TGE's ower |
| token_ | address | pool's token |
| info | struct ITGE.TGEInfo | TGE parameters |

### purchase

```solidity
function purchase(uint256 amount) external payable
```

_Purchase pool's tokens during TGE_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | amount of tokens in wei (10**18 = 1 token) |

### redeem

```solidity
function redeem() external
```

_Return purchased tokens and get back tokens paid_

### claim

```solidity
function claim() external
```

_Claim vested tokens_

### setLockupTVLReached

```solidity
function setLockupTVLReached() external
```

### transferFunds

```solidity
function transferFunds() external
```

_Transfer proceeds from TGE to pool's treasury. Claim protocol fee._

### claimProtocolTokenFee

```solidity
function claimProtocolTokenFee() private
```

_Transfers protocol token fee in form of pool's governance tokens to protocol treasury_

### maxPurchaseOf

```solidity
function maxPurchaseOf(address account) public view returns (uint256)
```

_How many tokens an address can purchase._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Amount of tokens |

### state

```solidity
function state() public view returns (enum ITGE.State)
```

_Returns TGE's state._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | enum ITGE.State | State |

### claimAvailable

```solidity
function claimAvailable() public view returns (bool)
```

_Is claim avilable for vested tokens._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Is claim available |

### getUnitOfAccount

```solidity
function getUnitOfAccount() public view returns (address)
```

_Get token used to purchase pool's tokens in TGE_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | Token address |

### getTotalPurchased

```solidity
function getTotalPurchased() public view returns (uint256)
```

_Get total amount of tokens purchased during TGE._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total amount of tokens. |

### getTotalLocked

```solidity
function getTotalLocked() public view returns (uint256)
```

_Get total amount of tokens that are vesting._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total vesting tokens. |

### getTotalPurchasedValue

```solidity
function getTotalPurchasedValue() public view returns (uint256)
```

_Get total value of all purchased tokens_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total value |

### getTotalLockedValue

```solidity
function getTotalLockedValue() public view returns (uint256)
```

_Get total value of all vesting tokens_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total value |

### onlyState

```solidity
modifier onlyState(enum ITGE.State state_)
```

### onlyWhitelistedUser

```solidity
modifier onlyWhitelistedUser()
```

### onlyManager

```solidity
modifier onlyManager()
```

### whenServiceNotPaused

```solidity
modifier whenServiceNotPaused()
```

### test83212

```solidity
function test83212() external pure returns (uint256)
```

## WhitelistedTokens

### _tokenWhitelist

```solidity
struct EnumerableSetUpgradeable.AddressSet _tokenWhitelist
```

_Token whitelist_

### tokenSwapPath

```solidity
mapping(address => bytes) tokenSwapPath
```

_Uniswap token swap path_

### tokenSwapReversePath

```solidity
mapping(address => bytes) tokenSwapReversePath
```

_Uniswap reverse swap path_

### TokenWhitelistedSet

```solidity
event TokenWhitelistedSet(address token, bool whitelisted)
```

_Event emitted on change in token's whitelist status_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | Token |
| whitelisted | bool | Is whitelisted |

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize() public
```

_Constructor function, can only be called once_

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeTo} and {upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

```solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```_

### addTokensToWhitelist

```solidity
function addTokensToWhitelist(address[] tokens, bytes[] swapPaths, bytes[] swapReversePaths) external
```

_Add tokens to whitelist_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokens | address[] | Tokens |
| swapPaths | bytes[] | Token swap paths |
| swapReversePaths | bytes[] | Reverse swap paths |

### removeTokensFromWhitelist

```solidity
function removeTokensFromWhitelist(address[] tokens) external
```

_Remove tokens from whitelist_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokens | address[] | Tokens |

### tokenWhitelist

```solidity
function tokenWhitelist() external view returns (address[])
```

_Return whitelisted tokens_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | Addresses of whitelisted tokens |

### isTokenWhitelisted

```solidity
function isTokenWhitelisted(address token) external view returns (bool)
```

_Check if token is whitelisted_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | Token |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Is token whitelisted |

### test83212

```solidity
function test83212() external pure returns (uint256)
```

## Governor

_Proposal module for Pool's Governance Token_

### Proposal

```solidity
struct Proposal {
  uint256 ballotQuorumThreshold;
  uint256 ballotDecisionThreshold;
  address target;
  uint256 value;
  bytes callData;
  uint256 startBlock;
  uint256 endBlock;
  uint256 forVotes;
  uint256 againstVotes;
  bool executed;
  enum Governor.ProposalExecutionState state;
  string description;
  uint256 totalSupply;
  uint256 lastVoteBlock;
  enum IProposalGateway.ProposalType proposalType;
  uint256 execDelay;
  uint256 amountERC20;
  string metaHash;
}
```

### _proposals

```solidity
mapping(uint256 => struct Governor.Proposal) _proposals
```

_Proposals_

### _forVotes

```solidity
mapping(address => mapping(uint256 => uint256)) _forVotes
```

_For votes_

### _againstVotes

```solidity
mapping(address => mapping(uint256 => uint256)) _againstVotes
```

_Against votes_

### lastProposalId

```solidity
uint256 lastProposalId
```

_Last proposal ID_

### ProposalState

```solidity
enum ProposalState {
  None,
  Active,
  Failed,
  Successful,
  Executed,
  Cancelled
}
```

### ProposalExecutionState

```solidity
enum ProposalExecutionState {
  Initialized,
  Rejected,
  Accomplished,
  Cancelled
}
```

### ProposalCreated

```solidity
event ProposalCreated(uint256 proposalId, uint256 quorum, address targets, uint256 values, bytes calldatas, string description)
```

_Event emitted on proposal creation_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |
| quorum | uint256 | Quorum |
| targets | address | Targets |
| values | uint256 | Values |
| calldatas | bytes | Calldata |
| description | string | Description |

### VoteCast

```solidity
event VoteCast(address voter, uint256 proposalId, uint256 votes, bool support)
```

_Event emitted on proposal vote cast_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| voter | address | Voter address |
| proposalId | uint256 | Proposal ID |
| votes | uint256 | Amount of votes |
| support | bool | Against or for |

### ProposalExecuted

```solidity
event ProposalExecuted(uint256 proposalId)
```

_Event emitted on proposal execution_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### ProposalCancelled

```solidity
event ProposalCancelled(uint256 proposalId)
```

_Event emitted on proposal cancellation_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### proposalState

```solidity
function proposalState(uint256 proposalId) public view returns (enum Governor.ProposalState)
```

_Return proposal state_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | enum Governor.ProposalState | ProposalState |

### getProposalBallotQuorumThreshold

```solidity
function getProposalBallotQuorumThreshold(uint256 proposalId) public view returns (uint256)
```

_Return proposal quorum threshold_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Quorum threshold |

### getProposalBallotDecisionThreshold

```solidity
function getProposalBallotDecisionThreshold(uint256 proposalId) public view returns (uint256)
```

_Return proposal decsision threshold_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Decision threshold |

### getProposalBallotLifespan

```solidity
function getProposalBallotLifespan(uint256 proposalId) public view returns (uint256)
```

_Return proposal lifespan_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Lifespan |

### getProposal

```solidity
function getProposal(uint256 proposalId) public view returns (struct Governor.Proposal)
```

_Return proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct Governor.Proposal | Proposal |

### getForVotes

```solidity
function getForVotes(address user, uint256 proposalId) public view returns (uint256)
```

_Return proposal for votes for a given user_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | User address |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | For votes |

### getAgainstVotes

```solidity
function getAgainstVotes(address user, uint256 proposalId) public view returns (uint256)
```

_Return proposal against votes for a given user_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | User address |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Against votes |

### _getProposalType

```solidity
function _getProposalType(uint256 proposalId) internal view returns (enum IProposalGateway.ProposalType)
```

_Return proposal type_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | enum IProposalGateway.ProposalType | Proposal type |

### _propose

```solidity
function _propose(uint256 ballotLifespan, uint256 ballotQuorumThreshold, uint256 ballotDecisionThreshold, address target, uint256 value, bytes callData, string description, uint256 totalSupply, uint256 execDelay, enum IProposalGateway.ProposalType proposalType, uint256 amountERC20, string metaHash) internal returns (uint256 proposalId)
```

_Create proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| ballotLifespan | uint256 | Ballot lifespan |
| ballotQuorumThreshold | uint256 | Ballot quorum threshold |
| ballotDecisionThreshold | uint256 | Ballot decision threshold |
| target | address | Target |
| value | uint256 | Value |
| callData | bytes | Calldata |
| description | string | Description |
| totalSupply | uint256 | Total supply |
| execDelay | uint256 | Execution delay |
| proposalType | enum IProposalGateway.ProposalType | Proposal type |
| amountERC20 | uint256 | Amount ERC20 |
| metaHash | string |  |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### _castVote

```solidity
function _castVote(uint256 proposalId, uint256 votes, bool support) internal
```

_Cast vote for a proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |
| votes | uint256 | Amount of votes |
| support | bool | Against or for |

### _executeBallot

```solidity
function _executeBallot(uint256 proposalId, contract IService service, contract IPool pool) internal
```

_Execute proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |
| service | contract IService | Service address |
| pool | contract IPool | Pool address |

### isDelayCleared

```solidity
function isDelayCleared(contract IPool pool, uint256 proposalId) public returns (bool)
```

_Return: is proposal block delay cleared. Block delay is applied based on proposal type and pool governance settings._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | Pool address |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Is delay cleared |

### _cancelBallot

```solidity
function _cancelBallot(uint256 proposalId) internal
```

_Cancel proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### _afterProposalCreated

```solidity
function _afterProposalCreated(uint256 proposalId) internal virtual
```

### _getTotalSupply

```solidity
function _getTotalSupply() internal view virtual returns (uint256)
```

### _getTotalTGELockedTokens

```solidity
function _getTotalTGELockedTokens() internal view virtual returns (uint256)
```

## IDirectory

### ContractType

```solidity
enum ContractType {
  None,
  Pool,
  GovernanceToken,
  TGE
}
```

### EventType

```solidity
enum EventType {
  None,
  TransferETH,
  TransferERC20,
  TGE,
  GovernanceSettings
}
```

### addContractRecord

```solidity
function addContractRecord(address addr, enum IDirectory.ContractType contractType) external returns (uint256 index)
```

### addProposalRecord

```solidity
function addProposalRecord(address pool, uint256 proposalId) external returns (uint256 index)
```

### addEventRecord

```solidity
function addEventRecord(address pool, enum IDirectory.EventType eventType, uint256 proposalId, string description, string metaHash) external returns (uint256 index)
```

### typeOf

```solidity
function typeOf(address addr) external view returns (enum IDirectory.ContractType)
```

## IGovernanceToken

### TokenInfo

```solidity
struct TokenInfo {
  string name;
  string symbol;
  uint256 cap;
}
```

### initialize

```solidity
function initialize(address pool_, struct IGovernanceToken.TokenInfo info) external
```

### mint

```solidity
function mint(address to, uint256 amount) external
```

### burn

```solidity
function burn(address from, uint256 amount) external
```

### lock

```solidity
function lock(address account, uint256 amount, bool support, uint256 deadline, uint256 proposalId) external
```

### cap

```solidity
function cap() external view returns (uint256)
```

### minUnlockedBalanceOf

```solidity
function minUnlockedBalanceOf(address from) external view returns (uint256)
```

### unlockedBalanceOf

```solidity
function unlockedBalanceOf(address account, uint256 proposalId) external view returns (uint256)
```

### pool

```solidity
function pool() external view returns (address)
```

### service

```solidity
function service() external view returns (contract IService)
```

### decimals

```solidity
function decimals() external view returns (uint8)
```

### increaseTotalTGELockedTokens

```solidity
function increaseTotalTGELockedTokens(uint256 _amount) external
```

### decreaseTotalTGELockedTokens

```solidity
function decreaseTotalTGELockedTokens(uint256 _amount) external
```

### totalTGELockedTokens

```solidity
function totalTGELockedTokens() external view returns (uint256)
```

## IMetadata

### Status

```solidity
enum Status {
  NotUsed,
  Used
}
```

### QueueInfo

```solidity
struct QueueInfo {
  uint256 jurisdiction;
  string EIN;
  string dateOfIncorporation;
  uint256 entityType;
  enum IMetadata.Status status;
  address owner;
}
```

### initialize

```solidity
function initialize() external
```

### lockRecord

```solidity
function lockRecord(uint256 jurisdiction) external returns (uint256)
```

### getQueueInfo

```solidity
function getQueueInfo(uint256 id) external view returns (struct IMetadata.QueueInfo)
```

### setOwner

```solidity
function setOwner(uint256 id, address owner) external
```

## IPool

### initialize

```solidity
function initialize(address poolCreator_, uint256 jurisdiction_, string poolEIN_, string dateOfIncorporation, uint256 entityType, uint256 ballotQuorumThreshold_, uint256 ballotDecisionThreshold_, uint256 ballotLifespan_, uint256[10] ballotExecDelay_, uint256 metadataIndex, string trademark) external
```

### setToken

```solidity
function setToken(address token_) external
```

### setTGE

```solidity
function setTGE(address tge_) external
```

### setPrimaryTGE

```solidity
function setPrimaryTGE(address tge_) external
```

### setGovernanceSettings

```solidity
function setGovernanceSettings(uint256 ballotQuorumThreshold_, uint256 ballotDecisionThreshold_, uint256 ballotLifespan_, uint256[10] ballotExecDelay) external
```

### proposeSingleAction

```solidity
function proposeSingleAction(address target, uint256 value, bytes cd, string description, enum IProposalGateway.ProposalType proposalType, uint256 amountERC20, string metaHash) external returns (uint256 proposalId)
```

### serviceCancelBallot

```solidity
function serviceCancelBallot(uint256 proposalId) external
```

### getTVL

```solidity
function getTVL() external returns (uint256)
```

### owner

```solidity
function owner() external view returns (address)
```

### service

```solidity
function service() external view returns (contract IService)
```

### token

```solidity
function token() external view returns (contract IGovernanceToken)
```

### tge

```solidity
function tge() external view returns (contract ITGE)
```

### maxProposalId

```solidity
function maxProposalId() external view returns (uint256)
```

### isDAO

```solidity
function isDAO() external view returns (bool)
```

### getPoolTrademark

```solidity
function getPoolTrademark() external view returns (string)
```

### addTGE

```solidity
function addTGE(address tge_) external
```

### getProposalType

```solidity
function getProposalType(uint256 proposalId) external view returns (enum IProposalGateway.ProposalType)
```

### ballotExecDelay

```solidity
function ballotExecDelay(uint256 _index) external view returns (uint256)
```

## IProposalGateway

### ProposalType

```solidity
enum ProposalType {
  None,
  TransferETH,
  TransferERC20,
  TGE,
  GovernanceSettings
}
```

## IService

### initialize

```solidity
function initialize(contract IDirectory directory_, address poolBeacon_, address proposalGateway_, address tokenBeacon_, address tgeBeacon_, contract IMetadata metadata_, uint256 fee_, uint256[13] ballotParams, contract ISwapRouter uniswapRouter_, contract IQuoter uniswapQuoter_, contract IWhitelistedTokens whitelistedTokens_, uint256 _protocolTokenFee) external
```

### createSecondaryTGE

```solidity
function createSecondaryTGE(struct ITGE.TGEInfo tgeInfo) external
```

### addProposal

```solidity
function addProposal(uint256 proposalId) external
```

### addEvent

```solidity
function addEvent(enum IDirectory.EventType eventType, uint256 proposalId, string description, string metaHash) external
```

### directory

```solidity
function directory() external view returns (contract IDirectory)
```

### isManagerWhitelisted

```solidity
function isManagerWhitelisted(address account) external view returns (bool)
```

### tokenWhitelist

```solidity
function tokenWhitelist() external view returns (address[])
```

### owner

```solidity
function owner() external view returns (address)
```

### proposalGateway

```solidity
function proposalGateway() external view returns (address)
```

### uniswapRouter

```solidity
function uniswapRouter() external view returns (contract ISwapRouter)
```

### uniswapQuoter

```solidity
function uniswapQuoter() external view returns (contract IQuoter)
```

### whitelistedTokens

```solidity
function whitelistedTokens() external view returns (contract IWhitelistedTokens)
```

### metadata

```solidity
function metadata() external view returns (contract IMetadata)
```

### protocolTreasury

```solidity
function protocolTreasury() external view returns (address)
```

### protocolTokenFee

```solidity
function protocolTokenFee() external view returns (uint256)
```

### getMinSoftCap

```solidity
function getMinSoftCap() external view returns (uint256)
```

### getProtocolTokenFee

```solidity
function getProtocolTokenFee(uint256 amount) external view returns (uint256)
```

### ballotExecDelay

```solidity
function ballotExecDelay(uint256 _index) external view returns (uint256)
```

### paused

```solidity
function paused() external view returns (bool)
```

### usdt

```solidity
function usdt() external view returns (address)
```

### weth

```solidity
function weth() external view returns (address)
```

## ITGE

### TGEInfo

```solidity
struct TGEInfo {
  string metadataURI;
  uint256 price;
  uint256 hardcap;
  uint256 softcap;
  uint256 minPurchase;
  uint256 maxPurchase;
  uint256 lockupPercent;
  uint256 lockupDuration;
  uint256 lockupTVL;
  uint256 duration;
  address[] userWhitelist;
  address unitOfAccount;
}
```

### initialize

```solidity
function initialize(address owner_, address token_, struct ITGE.TGEInfo info) external
```

### redeem

```solidity
function redeem() external
```

### maxPurchaseOf

```solidity
function maxPurchaseOf(address account) external view returns (uint256)
```

### State

```solidity
enum State {
  Active,
  Failed,
  Successful
}
```

### state

```solidity
function state() external view returns (enum ITGE.State)
```

## IWhitelistedTokens

### tokenWhitelist

```solidity
function tokenWhitelist() external view returns (address[])
```

### isTokenWhitelisted

```solidity
function isTokenWhitelisted(address token) external view returns (bool)
```

### tokenSwapPath

```solidity
function tokenSwapPath(address) external view returns (bytes)
```

### tokenSwapReversePath

```solidity
function tokenSwapReversePath(address) external view returns (bytes)
```

## ExceptionsLibrary

### ADDRESS_ZERO

```solidity
string ADDRESS_ZERO
```

### INCORRECT_ETH_PASSED

```solidity
string INCORRECT_ETH_PASSED
```

### NO_COMPANY

```solidity
string NO_COMPANY
```

### INVALID_TOKEN

```solidity
string INVALID_TOKEN
```

### NOT_POOL

```solidity
string NOT_POOL
```

### NOT_TGE

```solidity
string NOT_TGE
```

### NOT_PROPOSAL_GATEWAY

```solidity
string NOT_PROPOSAL_GATEWAY
```

### NOT_POOL_OWNER

```solidity
string NOT_POOL_OWNER
```

### NOT_SERVICE_OWNER

```solidity
string NOT_SERVICE_OWNER
```

### IS_DAO

```solidity
string IS_DAO
```

### NOT_DAO

```solidity
string NOT_DAO
```

### NOT_SHAREHOLDER

```solidity
string NOT_SHAREHOLDER
```

### NOT_WHITELISTED

```solidity
string NOT_WHITELISTED
```

### ALREADY_WHITELISTED

```solidity
string ALREADY_WHITELISTED
```

### ALREADY_NOT_WHITELISTED

```solidity
string ALREADY_NOT_WHITELISTED
```

### NOT_SERVICE

```solidity
string NOT_SERVICE
```

### WRONG_STATE

```solidity
string WRONG_STATE
```

### TRANSFER_FAILED

```solidity
string TRANSFER_FAILED
```

### CLAIM_NOT_AVAILABLE

```solidity
string CLAIM_NOT_AVAILABLE
```

### NO_LOCKED_BALANCE

```solidity
string NO_LOCKED_BALANCE
```

### LOCKUP_TVL_REACHED

```solidity
string LOCKUP_TVL_REACHED
```

### HARDCAP_OVERFLOW

```solidity
string HARDCAP_OVERFLOW
```

### MAX_PURCHASE_OVERFLOW

```solidity
string MAX_PURCHASE_OVERFLOW
```

### HARDCAP_OVERFLOW_REMAINING_SUPPLY

```solidity
string HARDCAP_OVERFLOW_REMAINING_SUPPLY
```

### HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY

```solidity
string HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY
```

### MIN_PURCHASE_UNDERFLOW

```solidity
string MIN_PURCHASE_UNDERFLOW
```

### LOW_UNLOCKED_BALANCE

```solidity
string LOW_UNLOCKED_BALANCE
```

### ZERO_PURCHASE_AMOUNT

```solidity
string ZERO_PURCHASE_AMOUNT
```

### NOTHING_TO_REDEEM

```solidity
string NOTHING_TO_REDEEM
```

### RECORD_IN_USE

```solidity
string RECORD_IN_USE
```

### INVALID_EIN

```solidity
string INVALID_EIN
```

### VALUE_ZERO

```solidity
string VALUE_ZERO
```

### ALREADY_SET

```solidity
string ALREADY_SET
```

### VOTING_FINISHED

```solidity
string VOTING_FINISHED
```

### ALREADY_EXECUTED

```solidity
string ALREADY_EXECUTED
```

### ACTIVE_TGE_EXISTS

```solidity
string ACTIVE_TGE_EXISTS
```

### INVALID_VALUE

```solidity
string INVALID_VALUE
```

### INVALID_CAP

```solidity
string INVALID_CAP
```

### INVALID_HARDCAP

```solidity
string INVALID_HARDCAP
```

### ONLY_POOL

```solidity
string ONLY_POOL
```

### ETH_TRANSFER_FAIL

```solidity
string ETH_TRANSFER_FAIL
```

### TOKEN_TRANSFER_FAIL

```solidity
string TOKEN_TRANSFER_FAIL
```

### BLOCK_DELAY

```solidity
string BLOCK_DELAY
```

### SERVICE_PAUSED

```solidity
string SERVICE_PAUSED
```

### INVALID_PROPOSAL_TYPE

```solidity
string INVALID_PROPOSAL_TYPE
```

## ERC20Mock

### constructor

```solidity
constructor(string name_, string symbol_) public
```

## IWETH

### deposit

```solidity
function deposit() external payable
```

Deposit ether to get wrapped ether

### withdraw

```solidity
function withdraw(uint256) external
```

Withdraw wrapped ether to get ether

## IUniswapPositionManager

### createAndInitializePoolIfNecessary

```solidity
function createAndInitializePoolIfNecessary(address token0, address token1, uint24 fee, uint160 sqrtPriceX96) external payable returns (address pool)
```

Creates a new pool if it does not exist, then initializes if not initialized

_This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token0 | address | The contract address of token0 of the pool |
| token1 | address | The contract address of token1 of the pool |
| fee | uint24 | The fee amount of the v3 pool for the specified token pair |
| sqrtPriceX96 | uint160 | The initial square root price of the pool as a Q64.96 value |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary |

### multicall

```solidity
function multicall(bytes[] data) external payable returns (bytes[] results)
```

Call multiple functions in the current contract and return the data from all of them if they all succeed

_The `msg.value` should not be trusted for any method callable from multicall._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| data | bytes[] | The encoded function data for each of the calls to make to this contract |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| results | bytes[] | The results from each of the calls passed in via data |

### MintParams

```solidity
struct MintParams {
  address token0;
  address token1;
  uint24 fee;
  int24 tickLower;
  int24 tickUpper;
  uint256 amount0Desired;
  uint256 amount1Desired;
  uint256 amount0Min;
  uint256 amount1Min;
  address recipient;
  uint256 deadline;
}
```

### mint

```solidity
function mint(struct IUniswapPositionManager.MintParams params) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
```

Creates a new position wrapped in a NFT

_Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
a method does not exist, i.e. the pool is assumed to be initialized._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IUniswapPositionManager.MintParams | The params necessary to mint a position, encoded as `MintParams` in calldata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the token that represents the minted position |
| liquidity | uint128 | The amount of liquidity for this position |
| amount0 | uint256 | The amount of token0 |
| amount1 | uint256 | The amount of token1 |

## IUniswapFactory

