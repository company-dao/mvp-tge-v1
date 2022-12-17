# Solidity API

## Dispatcher

_Protocol dispatcher (unification of Directory, Metadata, WhitelistedTokens, ProposalGateway)_

### service

```solidity
address service
```

_Service address_

### ContractInfo

```solidity
struct ContractInfo {
  address addr;
  enum IDispatcher.ContractType contractType;
  string description;
}
```

### contractRecordAt

```solidity
mapping(uint256 => struct Dispatcher.ContractInfo) contractRecordAt
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
mapping(uint256 => struct Dispatcher.ProposalInfo) proposalRecordAt
```

### lastProposalRecordIndex

```solidity
uint256 lastProposalRecordIndex
```

_Index of last proposal record_

### Event

```solidity
struct Event {
  enum IDispatcher.EventType eventType;
  address pool;
  uint256 proposalId;
  string metaHash;
}
```

### events

```solidity
mapping(uint256 => struct Dispatcher.Event) events
```

### lastEventIndex

```solidity
uint256 lastEventIndex
```

_Index of last event record_

### currentId

```solidity
uint256 currentId
```

_Last metadata ID_

### queueInfo

```solidity
mapping(uint256 => struct IDispatcher.QueueInfo) queueInfo
```

_Metadata queue_

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

### ContractRecordAdded

```solidity
event ContractRecordAdded(uint256 index, address addr, enum IDispatcher.ContractType contractType)
```

_Event emitted on creation of contract record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Record index |
| addr | address | Contract address |
| contractType | enum IDispatcher.ContractType | Contract type |

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

### EventRecordAdded

```solidity
event EventRecordAdded(enum IDispatcher.EventType eventType, address pool, uint256 proposalId)
```

_Event emitted on creation of event_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| eventType | enum IDispatcher.EventType | Event type |
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
function addContractRecord(address addr, enum IDispatcher.ContractType contractType, string description) external returns (uint256 index)
```

_Add contract record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | Contract address |
| contractType | enum IDispatcher.ContractType | Contract type |
| description | string |  |

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
function addEventRecord(address pool, enum IDispatcher.EventType eventType, uint256 proposalId, string metaHash) external returns (uint256 index)
```

_Add event record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| eventType | enum IDispatcher.EventType | Event type |
| proposalId | uint256 | Proposal ID |
| metaHash | string | Hash value of event metadata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Record index |

### setService

```solidity
function setService(address service_) external
```

_Set Service in Dispatcher_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| service_ | address | Service address |

### createRecord

```solidity
function createRecord(uint256 jurisdiction, string EIN, string dateOfIncorporation, uint256 entityType, uint256 fee) public
```

_Create metadata record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | Jurisdiction |
| EIN | string | EIN |
| dateOfIncorporation | string | Date of incorporation |
| entityType | uint256 | Entity type |
| fee | uint256 | Fee for create pool |

### lockRecord

```solidity
function lockRecord(uint256 jurisdiction, uint256 entityType) external returns (address, uint256)
```

_Lock metadata record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | Jurisdiction |
| entityType | uint256 | Entity type |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | Record ID |
| [1] | uint256 |  |

### deleteRecord

```solidity
function deleteRecord(uint256 id) external
```

_Delete queue record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| id | uint256 | Queue index |

### updateFeeByIndex

```solidity
function updateFeeByIndex(uint256 id, uint256 fee) external
```

_Update pool fee by metadata index_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| id | uint256 | Queue index |
| fee | uint256 | Fee to update |

### updateFeeByPool

```solidity
function updateFeeByPool(address poolToUpdate, uint256 fee) external
```

_Update pool fee by pool contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolToUpdate | address | Pool address |
| fee | uint256 | Fee to update |

### updateFeeByJE

```solidity
function updateFeeByJE(address jurisdiction, string EIN, uint256 fee) external
```

_Update pool fee by pool contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | address | company's jurisdiction |
| EIN | string | company's EIN |
| fee | uint256 | Fee to update |

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

### typeOf

```solidity
function typeOf(address addr) external view returns (enum IDispatcher.ContractType)
```

_Return type of contract for a given address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | Contract index |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | enum IDispatcher.ContractType | ContractType |

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

### getContractDescription

```solidity
function getContractDescription(address tge) external view returns (string)
```

_Return contract description_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | address | TGE address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | Metadata uri |

### poolAvailable

```solidity
function poolAvailable(uint256 jurisdiction, uint256 entityType) external view returns (uint256, uint256)
```

_Check if pool available_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | Jurisdiction |
| entityType | uint256 | Entity type |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | (0, 0) if there are no available companies (1, 0) if there are no available companies in current jurisdiction, but exists in other jurisdiction (2, fee) if there are available companies in current jurisdiction |
| [1] | uint256 |  |

### availableCompaniesCount

```solidity
function availableCompaniesCount(uint256 jurisdiction) external view returns (uint256)
```

### availableJurisdictions

```solidity
function availableJurisdictions() external view returns (uint256[])
```

### allJursdictions

```solidity
function allJursdictions() external view returns (uint256[])
```

### existingCompanies

```solidity
function existingCompanies(uint256 jurisdiction) external view returns (uint256[])
```

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

### validateTGEInfo

```solidity
function validateTGEInfo(struct ITGE.TGEInfo info, contract IToken token_) public view returns (bool)
```

### validateBallotParams

```solidity
function validateBallotParams(uint256 ballotQuorumThreshold, uint256 ballotDecisionThreshold, uint256 ballotLifespan, uint256[10] ballotExecDelay) public pure returns (bool)
```

### onlyService

```solidity
modifier onlyService()
```

### onlyServiceOwner

```solidity
modifier onlyServiceOwner()
```

## IDispatcher

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
function addContractRecord(address addr, enum IDispatcher.ContractType contractType, string description) external returns (uint256 index)
```

### addProposalRecord

```solidity
function addProposalRecord(address pool, uint256 proposalId) external returns (uint256 index)
```

### addEventRecord

```solidity
function addEventRecord(address pool, enum IDispatcher.EventType eventType, uint256 proposalId, string metaHash) external returns (uint256 index)
```

### typeOf

```solidity
function typeOf(address addr) external view returns (enum IDispatcher.ContractType)
```

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
  enum IDispatcher.Status status;
  address pool;
  uint256 fee;
}
```

### initialize

```solidity
function initialize() external
```

### service

```solidity
function service() external view returns (address)
```

### lockRecord

```solidity
function lockRecord(uint256 jurisdiction, uint256 entityType) external returns (address, uint256)
```

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

### validateTGEInfo

```solidity
function validateTGEInfo(struct ITGE.TGEInfo info, contract IToken token_) external view returns (bool)
```

### validateBallotParams

```solidity
function validateBallotParams(uint256 ballotQuorumThreshold, uint256 ballotDecisionThreshold, uint256 ballotLifespan, uint256[10] ballotExecDelay) external pure returns (bool)
```

## IPool

### initialize

```solidity
function initialize(uint256 jurisdiction_, string EIN_, string dateOfIncorporation, uint256 entityType, uint256 metadataIndex) external
```

### setToken

```solidity
function setToken(address token_) external
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
function proposeSingleAction(address target, uint256 value, bytes cd, string description, enum IDispatcher.ProposalType proposalType, string metaHash) external returns (uint256 proposalId)
```

### proposeTransfer

```solidity
function proposeTransfer(address[] targets, uint256[] values, string description, enum IDispatcher.ProposalType proposalType, string metaHash, address token_) external returns (uint256 proposalId)
```

### setLastProposalIdForAccount

```solidity
function setLastProposalIdForAccount(address creator, uint256 proposalId) external
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
function token() external view returns (contract IToken)
```

### lastTGE

```solidity
function lastTGE() external view returns (address)
```

### getGovernanceTGEList

```solidity
function getGovernanceTGEList() external view returns (address[])
```

### primaryTGE

```solidity
function primaryTGE() external view returns (address)
```

### maxProposalId

```solidity
function maxProposalId() external view returns (uint256)
```

### isDAO

```solidity
function isDAO() external view returns (bool)
```

### trademark

```solidity
function trademark() external view returns (string)
```

### addTGE

```solidity
function addTGE(address tge_) external
```

### ballotExecDelay

```solidity
function ballotExecDelay(uint256 _index) external view returns (uint256)
```

### paused

```solidity
function paused() external view returns (bool)
```

### launch

```solidity
function launch(address owner_, uint256 ballotQuorumThreshold_, uint256 ballotDecisionThreshold_, uint256 ballotLifespan_, uint256[10] ballotExecDelay_, string trademark) external
```

### addPreferenceToken

```solidity
function addPreferenceToken(address token_) external
```

## IService

### initialize

```solidity
function initialize(contract IDispatcher dispatcher_, address poolBeacon_, address tokenBeacon_, address tgeBeacon_, address proposalGateway_, uint256[13] ballotParams, contract ISwapRouter uniswapRouter_, contract IQuoter uniswapQuoter_, uint256 protocolTokenFee_) external
```

### createSecondaryTGE

```solidity
function createSecondaryTGE(struct ITGE.TGEInfo tgeInfo, string metadataURI, enum IToken.TokenType tokenType, string tokenDescription) external
```

### addProposal

```solidity
function addProposal(uint256 proposalId) external
```

### addEvent

```solidity
function addEvent(enum IDispatcher.EventType eventType, uint256 proposalId, string metaHash) external
```

### isManagerWhitelisted

```solidity
function isManagerWhitelisted(address account) external view returns (bool)
```

### owner

```solidity
function owner() external view returns (address)
```

### uniswapRouter

```solidity
function uniswapRouter() external view returns (contract ISwapRouter)
```

### uniswapQuoter

```solidity
function uniswapQuoter() external view returns (contract IQuoter)
```

### dispatcher

```solidity
function dispatcher() external view returns (contract IDispatcher)
```

### proposalGateway

```solidity
function proposalGateway() external view returns (address)
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

### primaryAsset

```solidity
function primaryAsset() external view returns (address)
```

### secondaryAsset

```solidity
function secondaryAsset() external view returns (address)
```

### poolBeacon

```solidity
function poolBeacon() external view returns (address)
```

### tgeBeacon

```solidity
function tgeBeacon() external view returns (address)
```

## ITGE

### TGEInfo

```solidity
struct TGEInfo {
  uint256 price;
  uint256 hardcap;
  uint256 softcap;
  uint256 minPurchase;
  uint256 maxPurchase;
  uint256 vestingPercent;
  uint256 vestingDuration;
  uint256 vestingTVL;
  uint256 duration;
  address[] userWhitelist;
  address unitOfAccount;
  uint256 lockupDuration;
  uint256 lockupTVL;
}
```

### initialize

```solidity
function initialize(contract IToken token_, struct ITGE.TGEInfo info) external
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

### transferUnlocked

```solidity
function transferUnlocked() external view returns (bool)
```

### getTotalVested

```solidity
function getTotalVested() external view returns (uint256)
```

## IToken

### TokenInfo

```solidity
struct TokenInfo {
  string symbol;
  uint256 cap;
}
```

### TokenType

```solidity
enum TokenType {
  None,
  Governance,
  Preference
}
```

### initialize

```solidity
function initialize(address pool_, string symbol_, uint256 cap_, enum IToken.TokenType tokenType_, address preferenceTGE_, string description_) external
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
function lock(address account, uint256 amount, uint256 deadline, uint256 proposalId) external
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

### symbol

```solidity
function symbol() external view returns (string)
```

### tokenType

```solidity
function tokenType() external view returns (enum IToken.TokenType)
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

### NOT_DISPATCHER

```solidity
string NOT_DISPATCHER
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

### EXECUTION_FAILED

```solidity
string EXECUTION_FAILED
```

### INVALID_USER

```solidity
string INVALID_USER
```

### NOT_LAUNCHED

```solidity
string NOT_LAUNCHED
```

### LAUNCHED

```solidity
string LAUNCHED
```

### VESTING_TVL_REACHED

```solidity
string VESTING_TVL_REACHED
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
contract IToken token
```

_Pool token address_

### ballotQuorumThreshold

```solidity
uint256 ballotQuorumThreshold
```

_Minimum amount of votes that ballot must receive_

### ballotDecisionThreshold

```solidity
uint256 ballotDecisionThreshold
```

_Minimum amount of votes that ballot's choice must receive in order to pass_

### ballotLifespan

```solidity
uint256 ballotLifespan
```

_Ballot voting duration, blocks_

### trademark

```solidity
string trademark
```

_Pool trademark_

### jurisdiction

```solidity
uint256 jurisdiction
```

_Pool jurisdiction_

### EIN

```solidity
string EIN
```

_Pool EIN_

### metadataIndex

```solidity
uint256 metadataIndex
```

_Metadata pool record index_

### entityType

```solidity
uint256 entityType
```

_Pool entity type_

### dateOfIncorporation

```solidity
string dateOfIncorporation
```

_Pool date of incorporatio_

### primaryTGE

```solidity
address primaryTGE
```

_Pool's first TGE_

### _governanceTGEList

```solidity
address[] _governanceTGEList
```

_List of all governance pool's TGEs_

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

### lastProposalIdForAccount

```solidity
mapping(address => uint256) lastProposalIdForAccount
```

_last proposal id created by account_

### poolLaunched

```solidity
bool poolLaunched
```

_Is pool launched or not_

### _preferenceTokenList

```solidity
address[] _preferenceTokenList
```

_List of all pool's preference tokens_

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(uint256 jurisdiction_, string EIN_, string dateOfIncorporation_, uint256 entityType_, uint256 metadataIndex_) external
```

_Create TransferETH proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction_ | uint256 | Jurisdiction |
| EIN_ | string | EIN |
| dateOfIncorporation_ | string | Date of incorporation |
| entityType_ | uint256 | Entity type |
| metadataIndex_ | uint256 | Metadata index |

### launch

```solidity
function launch(address owner_, uint256 ballotQuorumThreshold_, uint256 ballotDecisionThreshold_, uint256 ballotLifespan_, uint256[10] ballotExecDelay_, string trademark_) external
```

_Create TransferETH proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner_ | address | Pool owner |
| ballotQuorumThreshold_ | uint256 | Ballot quorum threshold |
| ballotDecisionThreshold_ | uint256 | Ballot decision threshold |
| ballotLifespan_ | uint256 | Ballot lifespan |
| ballotExecDelay_ | uint256[10] | Ballot execution delay parameters |
| trademark_ | string | Trademark |

### setToken

```solidity
function setToken(address token_) external
```

_Set pool governance token_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token_ | address | Token address |

### setPrimaryTGE

```solidity
function setPrimaryTGE(address tge_) external
```

_Set pool primary TGE_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge_ | address | TGE address |

### setGovernanceSettings

```solidity
function setGovernanceSettings(uint256 ballotQuorumThreshold_, uint256 ballotDecisionThreshold_, uint256 ballotLifespan_, uint256[10] ballotExecDelay_) external
```

_Set Service governance settings_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| ballotQuorumThreshold_ | uint256 | Ballot quorum threshold |
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
function proposeSingleAction(address target, uint256 value, bytes cd, string description, enum IDispatcher.ProposalType proposalType, string metaHash) external returns (uint256 proposalId)
```

_Create pool proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| target | address | Proposal transaction recipient |
| value | uint256 | Amount of ETH token |
| cd | bytes | Calldata to pass on in .call() to transaction recipient |
| description | string | Proposal description |
| proposalType | enum IDispatcher.ProposalType | Type |
| metaHash | string | Hash value of proposal metadata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Created proposal ID |

### proposeTransfer

```solidity
function proposeTransfer(address[] targets, uint256[] values, string description, enum IDispatcher.ProposalType proposalType, string metaHash, address token_) external returns (uint256 proposalId)
```

_Create pool proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| targets | address[] | Proposal transaction recipients |
| values | uint256[] | Amounts of ETH token |
| description | string | Proposal description |
| proposalType | enum IDispatcher.ProposalType | Type |
| metaHash | string | Hash value of proposal metadata |
| token_ | address | token for payment proposal |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Created proposal ID |

### setLastProposalIdForAccount

```solidity
function setLastProposalIdForAccount(address creator, uint256 proposalId) external
```

### addTGE

```solidity
function addTGE(address tge_) external
```

_Add TGE to TGE archive list_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge_ | address | TGE address |

### addPreferenceToken

```solidity
function addPreferenceToken(address token_) external
```

_Add TGE to TGE archive list_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token_ | address | Preference token address |

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

### pause

```solidity
function pause() public
```

_Pause pool and corresponding TGEs and GovernanceToken_

### unpause

```solidity
function unpause() public
```

_Pause pool and corresponding TGEs and GovernanceToken_

### receive

```solidity
receive() external payable
```

### maxProposalId

```solidity
function maxProposalId() external view returns (uint256)
```

_Return maximum proposal ID_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Maximum proposal ID |

### isDAO

```solidity
function isDAO() external view returns (bool)
```

_Return if pool had a successful TGE_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Is any TGE successful |

### getGovernanceTGEList

```solidity
function getGovernanceTGEList() external view returns (address[])
```

_Return list of pool's TGEs_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | TGE list |

### lastTGE

```solidity
function lastTGE() external view returns (address)
```

_Return list of pool's TGEs_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | TGE list |

### owner

```solidity
function owner() public view returns (address)
```

_Return pool owner_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | Owner address |

### getBallotExecDelay

```solidity
function getBallotExecDelay() external view returns (uint256[10])
```

### getPreferenceTokenList

```solidity
function getPreferenceTokenList() external view returns (address[])
```

_Return list of pool's preference tokens_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | TGE list |

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

### _getTotalTGEVestedTokens

```solidity
function _getTotalTGEVestedTokens() internal view returns (uint256)
```

_Return amount of tokens currently vested in TGE vesting contract(s)_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total pool vesting tokens |

### paused

```solidity
function paused() public view returns (bool)
```

_Return pool paused status_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Is pool paused |

### getTotalTGEVestedTokens

```solidity
function getTotalTGEVestedTokens() public view returns (uint256)
```

_Return amount of tokens currently vested in TGE vesting contract(s)_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total pool vesting tokens |

### onlyService

```solidity
modifier onlyService()
```

### launched

```solidity
modifier launched()
```

### unlaunched

```solidity
modifier unlaunched()
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

### test83212

```solidity
function test83212() external pure returns (uint256)
```

## ProposalGateway

_Protocol entry point to create any proposal_

### dispatcher

```solidity
address dispatcher
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(address dispatcher_) external
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
function createTransferETHProposal(contract IPool pool, address[] recipients, uint256[] values, string description, string metaHash) external returns (uint256 proposalId)
```

_Create TransferETH proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | Pool address |
| recipients | address[] | Transfer recipients |
| values | uint256[] | Token amounts |
| description | string | Proposal description |
| metaHash | string | Hash value of proposal metadata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Created proposal's ID |

### createTransferERC20Proposal

```solidity
function createTransferERC20Proposal(contract IPool pool, address token, address[] recipients, uint256[] values, string description, string metaHash) external returns (uint256 proposalId)
```

_Create TransferERC20 proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | Pool address |
| token | address | Token to transfer |
| recipients | address[] | Transfer recipients |
| values | uint256[] | Token amounts |
| description | string | Proposal description |
| metaHash | string | Hash value of proposal metadata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Created proposal's ID |

### createTGEProposal

```solidity
function createTGEProposal(contract IPool pool, struct ITGE.TGEInfo info, string description, string metaHash, string metadataURI, enum IToken.TokenType tokenType, string tokenDescription) external returns (uint256 proposalId)
```

_Create TGE proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | Pool address |
| info | struct ITGE.TGEInfo | TGE parameters |
| description | string | Proposal description |
| metaHash | string | Hash value of proposal metadata |
| metadataURI | string |  |
| tokenType | enum IToken.TokenType |  |
| tokenDescription | string |  |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Created proposal's ID |

### createGovernanceSettingsProposal

```solidity
function createGovernanceSettingsProposal(contract IPool pool, uint256 ballotQuorumThreshold, uint256 ballotDecisionThreshold, uint256 ballotLifespan, uint256[10] ballotExecDelay, string description, string metaHash) external returns (uint256 proposalId)
```

_Create GovernanceSettings proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | Pool address |
| ballotQuorumThreshold | uint256 | Ballot quorum threshold |
| ballotDecisionThreshold | uint256 | Ballot decision threshold |
| ballotLifespan | uint256 | Ballot lifespan |
| ballotExecDelay | uint256[10] | Ballot execution delay parameters |
| description | string | Proposal description |
| metaHash | string | Hash value of proposal metadata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Created proposal's ID |

### onlyPoolShareholder

```solidity
modifier onlyPoolShareholder(contract IPool pool)
```

## Service

_Protocol entry point_

### dispatcher

```solidity
contract IDispatcher dispatcher
```

_Dispatcher address_

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

### proposalGateway

```solidity
address proposalGateway
```

_ProposalGteway address_

### ballotQuorumThreshold

```solidity
uint256 ballotQuorumThreshold
```

_Minimum amount of votes that ballot must receive_

### ballotDecisionThreshold

```solidity
uint256 ballotDecisionThreshold
```

_Minimum amount of votes that ballot's choice must receive in order to pass_

### ballotLifespan

```solidity
uint256 ballotLifespan
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

### primaryAsset

```solidity
address primaryAsset
```

_Primary contract address. Used to estimate proposal value._

### secondaryAsset

```solidity
address secondaryAsset
```

_Secondary contract address. Used to estimate proposal value._

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
event SecondaryTGECreated(address pool, address tge, address token)
```

_Event emitted on creation of secondary TGE._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| tge | address | Secondary TGE address |
| token | address | Preference token address |

### ProtocolTreasuryChanged

```solidity
event ProtocolTreasuryChanged(address protocolTreasury)
```

_Event emitted on protocol treasury change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| protocolTreasury | address | Protocol treasury address |

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
function initialize(contract IDispatcher dispatcher_, address poolBeacon_, address tokenBeacon_, address tgeBeacon_, address proposalGateway_, uint256[13] ballotParams, contract ISwapRouter uniswapRouter_, contract IQuoter uniswapQuoter_, uint256 protocolTokenFee_) external
```

_Constructor function, can only be called once_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| dispatcher_ | contract IDispatcher | Dispatcher address |
| poolBeacon_ | address | Pool beacon |
| tokenBeacon_ | address | Governance token beacon |
| tgeBeacon_ | address | TGE beacon |
| proposalGateway_ | address |  |
| ballotParams | uint256[13] | [ballotQuorumThreshold, ballotLifespan, ballotDecisionThreshold, ...ballotExecDelay] |
| uniswapRouter_ | contract ISwapRouter | UniswapRouter address |
| uniswapQuoter_ | contract IQuoter | UniswapQuoter address |
| protocolTokenFee_ | uint256 | Protocol token fee |

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
function createPool(contract IPool pool, struct IToken.TokenInfo tokenInfo, struct ITGE.TGEInfo tgeInfo, uint256[3] ballotSettings, uint256 jurisdiction, uint256[10] ballotExecDelay_, string trademark, uint256 entityType, string metadataURI) external payable
```

_Create pool_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | Pool address. If not address(0) - creates new token and new primary TGE for an existing pool. |
| tokenInfo | struct IToken.TokenInfo | Pool token parameters |
| tgeInfo | struct ITGE.TGEInfo | Pool TGE parameters |
| ballotSettings | uint256[3] | Ballot setting parameters |
| jurisdiction | uint256 | Pool jurisdiction |
| ballotExecDelay_ | uint256[10] | Ballot execution delay parameters |
| trademark | string | Pool trademark |
| entityType | uint256 | Company entity type |
| metadataURI | string |  |

### createSecondaryTGE

```solidity
function createSecondaryTGE(struct ITGE.TGEInfo tgeInfo, string metadataURI, enum IToken.TokenType tokenType, string tokenDescription) external
```

_Create secondary TGE_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tgeInfo | struct ITGE.TGEInfo | TGE parameters |
| metadataURI | string |  |
| tokenType | enum IToken.TokenType |  |
| tokenDescription | string |  |

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
function addEvent(enum IDispatcher.EventType eventType, uint256 proposalId, string metaHash) external
```

_Add event to directory_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| eventType | enum IDispatcher.EventType | Event type |
| proposalId | uint256 | Proposal ID |
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
| ballotQuorumThreshold_ | uint256 | Ballot quorum threshold |
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

_Pause service_

### unpause

```solidity
function unpause() public
```

_Unpause service_

### setPrimaryAsset

```solidity
function setPrimaryAsset(address primaryAsset_) external
```

_Set primary token address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| primaryAsset_ | address | Token address |

### setSecondaryAsset

```solidity
function setSecondaryAsset(address secondaryAsset_) external
```

_Set secondary token address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| secondaryAsset_ | address | Token address |

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

### getBallotExecDelay

```solidity
function getBallotExecDelay() public view returns (uint256[10])
```

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
contract IToken token
```

_Pool's ERC20 token_

### info

```solidity
struct ITGE.TGEInfo info
```

_TGE info struct_

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

### vestingTVLReached

```solidity
bool vestingTVLReached
```

_Is vesting TVL reached. Users can claim their tokens only if vesting TVL was reached._

### vestedBalanceOf

```solidity
mapping(address => uint256) vestedBalanceOf
```

_Mapping of an address to total amount of tokens vesting_

### _totalPurchased

```solidity
uint256 _totalPurchased
```

_Total amount of tokens purchased during TGE_

### _totalVested

```solidity
uint256 _totalVested
```

_Total amount of tokens vesting_

### isProtocolTokenFeeClaimed

```solidity
bool isProtocolTokenFeeClaimed
```

_Protocol token fee is a percentage of tokens sold during TGE. Returns true if fee was claimed by the governing DAO._

### lockupTVLReached

```solidity
bool lockupTVLReached
```

_Is lockup TVL reached. Users can claim their tokens only if lockup TVL was reached._

### Purchased

```solidity
event Purchased(address buyer, uint256 amount)
```

_Event emitted on token purchase._

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
function initialize(contract IToken token_, struct ITGE.TGEInfo info_) external
```

_Constructor function, can only be called once_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token_ | contract IToken | pool's token |
| info_ | struct ITGE.TGEInfo | TGE parameters |

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

### setVestingTVLReached

```solidity
function setVestingTVLReached() external
```

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

_Is claim available for vested tokens._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Is claim available |

### transferUnlocked

```solidity
function transferUnlocked() public view returns (bool)
```

_Is transfer available for lockup preference tokens._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Is transfer available |

### getTotalPurchased

```solidity
function getTotalPurchased() public view returns (uint256)
```

_Get total amount of tokens purchased during TGE._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total amount of tokens. |

### getTotalVested

```solidity
function getTotalVested() public view returns (uint256)
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

### getUserWhitelist

```solidity
function getUserWhitelist() external view returns (address[])
```

_Get userwhitelist info_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | User whitelist |

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

### whenPoolNotPaused

```solidity
modifier whenPoolNotPaused()
```

### test83212

```solidity
function test83212() external pure returns (uint256)
```

## Token

_Company (Pool) Token_

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

### tokenType

```solidity
enum IToken.TokenType tokenType
```

_Token type_

### preferenceTGE

```solidity
address preferenceTGE
```

_Preference TGE for preference token, for Governance token - address(0)_

### description

```solidity
string description
```

_Preference token description, allows up to 5000 characters, for others - ""_

### LockedBalance

```solidity
struct LockedBalance {
  uint256 amount;
  uint256 deadline;
}
```

### _lockedInProposal

```solidity
mapping(address => mapping(uint256 => struct Token.LockedBalance)) _lockedInProposal
```

_Votes lockup for address_

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(address pool_, string symbol_, uint256 cap_, enum IToken.TokenType tokenType_, address preferenceTGE_, string description_) external
```

_Constructor function, can only be called once_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool_ | address | Pool |
| symbol_ | string | Token symbol for GovernanceToken |
| cap_ | uint256 | Token cap |
| tokenType_ | enum IToken.TokenType | Token type |
| preferenceTGE_ | address | Preference tge address for Preference token |
| description_ | string | Token description for Preference token |

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
function lock(address account, uint256 amount, uint256 deadline, uint256 proposalId) external
```

_Lock votes (tokens) as a result of voting for a proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Token holder |
| amount | uint256 | Amount of tokens |
| deadline | uint256 | Lockup deadline |
| proposalId | uint256 | Proposal ID |

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

### getLockedInProposal

```solidity
function getLockedInProposal(address account, uint256 proposalId) public view returns (struct Token.LockedBalance)
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
| [0] | struct Token.LockedBalance | LockedBalance |

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

### symbol

```solidity
function symbol() public view returns (string)
```

_Return cap_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | Cap |

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

### containsTGE

```solidity
function containsTGE(address wallet) public view returns (bool)
```

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

### onlyPool

```solidity
modifier onlyPool()
```

### onlyTGE

```solidity
modifier onlyTGE()
```

### whenPoolNotPaused

```solidity
modifier whenPoolNotPaused()
```

### test83122

```solidity
function test83122() external pure returns (uint256)
```

## Governor

_Proposal module for Pool's Governance Token_

### Proposal

```solidity
struct Proposal {
  uint256 ballotQuorumThreshold;
  uint256 ballotDecisionThreshold;
  address[] targets;
  uint256[] values;
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
  enum IDispatcher.ProposalType proposalType;
  uint256 execDelay;
  string metaHash;
  address token;
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
event ProposalCreated(uint256 proposalId, uint256 quorum, address[] targets, uint256[] values, bytes calldatas, string description)
```

_Event emitted on proposal creation_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |
| quorum | uint256 | Quorum |
| targets | address[] | Targets |
| values | uint256[] | Values |
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

### ErrorCaugth

```solidity
event ErrorCaugth(bytes data)
```

_Event emitted on error in try/catch block_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| data | bytes | Error data |

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

### aheadOfTimeBallot

```solidity
function aheadOfTimeBallot(uint256 totalCastVotes, uint256 quorumVotes, struct Governor.Proposal proposal, uint256 totalAvailableVotes) public pure returns (enum Governor.ProposalState)
```

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

### _propose

```solidity
function _propose(uint256 ballotLifespan, uint256 ballotQuorumThreshold, uint256 ballotDecisionThreshold, address[] targets, uint256[] values, bytes callData, string description, uint256 totalSupply, uint256 execDelay, enum IDispatcher.ProposalType proposalType, string metaHash, address token_) internal returns (uint256 proposalId)
```

_Create proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| ballotLifespan | uint256 | Ballot lifespan |
| ballotQuorumThreshold | uint256 | Ballot quorum threshold |
| ballotDecisionThreshold | uint256 | Ballot decision threshold |
| targets | address[] | Targets |
| values | uint256[] | Values |
| callData | bytes | Calldata |
| description | string | Description |
| totalSupply | uint256 | Total supply |
| execDelay | uint256 | Execution delay |
| proposalType | enum IDispatcher.ProposalType | Proposal type |
| metaHash | string | Hash value of proposal metadata |
| token_ | address | token for payment proposal |

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
function _executeBallot(uint256 proposalId, contract IService service) internal
```

_Execute proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |
| service | contract IService | Service address |

### isDelayCleared

```solidity
function isDelayCleared(contract IPool pool, uint256 proposalId, uint256 index) public returns (bool)
```

_Return: is proposal block delay cleared. Block delay is applied based on proposal type and pool governance settings._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | Pool address |
| proposalId | uint256 | Proposal ID |
| index | uint256 |  |

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

### _getTotalTGEVestedTokens

```solidity
function _getTotalTGEVestedTokens() internal view virtual returns (uint256)
```

## ERC20Mock

### constructor

```solidity
constructor(string name_, string symbol_) public
```

## IUniswapFactory

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

