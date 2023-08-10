use map_light_client::proof::ReceiptProof;
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::collections::{UnorderedMap, UnorderedSet};
use near_sdk::env::panic_str;
use near_sdk::json_types::{U128, U64};
use near_sdk::serde::{Deserialize, Serialize};
use near_sdk::{
    env, log, near_bindgen, AccountId, Balance, BorshStorageKey, CryptoHash, Gas,
    PanicOnDefault, Promise, PromiseOrValue, PromiseResult,
};
use std::collections::HashSet;
use std::fmt;
use map_light_client::header::Address;
use crate::errors::*;
use crate::evm::validate_eth_address;
use crate::traits::*;
use crate::event::*;
use crate::utils::*;

mod event;
mod management;
mod traits;
mod utils;
mod errors;

/// Gas to call callback_process_proof_hash method.
const CALLBACK_PROCESS_PROOF_HASH: Gas = Gas(60_000_000_000_000);

/// Gas to call report_failure method.
const REPORT_FAILURE_GAS: Gas = Gas(4_000_000_000_000);

/// Gas to call verify_log_entry on prover.
const VERIFY_LOG_ENTRY_GAS: Gas = Gas(100_000_000_000_000);

const CALLBACK_MAPO_EXECUTE_GAS: Gas = Gas(10_000_000_000_000);

#[derive(BorshStorageKey, BorshSerialize)]
pub(crate) enum StorageKey {
    RegisterChains,
    UsedEvents,
    ProofHashes,
    RegisterCallers,
}

#[derive(BorshDeserialize, BorshSerialize, Serialize, Deserialize, Eq, PartialEq, Clone)]
#[serde(crate = "near_sdk::serde")]
#[cfg_attr(not(target_arch = "wasm32"), derive(Debug))]
pub enum RunningState {
    Running,
    Paused,
}

impl fmt::Display for RunningState {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            RunningState::Running => write!(f, "Running"),
            RunningState::Paused => write!(f, "Paused"),
        }
    }
}

#[derive(BorshDeserialize, BorshSerialize, Serialize, Deserialize, Clone, Debug)]
#[serde(crate = "near_sdk::serde")]
pub struct RegisterCallerInfo {
    pub chain_ids: HashSet<u128>,
}

#[derive(BorshDeserialize, BorshSerialize, Serialize, Deserialize, Clone, Debug)]
#[serde(crate = "near_sdk::serde")]
pub struct ChainGasPriceInfo {
    pub base_gas: U64,
    pub gas_price_in_near: U128,
}

impl Default for ChainGasPriceInfo {
    fn default() -> Self {
        Self {
            base_gas: U64::from(0),
            gas_price_in_near: U128::from(0),
        }
    }
}

#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize, PanicOnDefault)]
pub struct MAPOServiceV3 {
    /// The account of the map light client that we can use to prove
    map_client_account: AccountId,
    /// Address of the MAP bridge contract.
    map_bridge_address: Address,
    /// Map of chain id to chain info
    registered_chains: UnorderedMap<u128, ChainGasPriceInfo>,
    /// Hashes of the events that were already used.
    used_events: UnorderedSet<CryptoHash>,
    /// Hashes of the verified proof.
    proof_hashes: UnorderedSet<CryptoHash>,
    /// Account of the owner
    owner: AccountId,
    // Wrap token for near
    wrapped_token: AccountId,
    // Near chain id
    near_chain_id: u128,
    // MAP chain id
    map_chain_id: u128,
    // Nonce to generate order id
    nonce: u128,
    /// Map of caller contract to caller info
    registered_callers: UnorderedMap<AccountId, RegisterCallerInfo>,

    fee_receiver: AccountId,

    /// Running state
    state: RunningState,
}

#[near_bindgen]
impl MAPOServiceV3 {
    /// Initializes the contract.
    /// `owner`: NEAR account of the owner;
    /// `map_client_account`: NEAR account of the MAP light client contract;
    /// `map_bridge_address`: the address of the MCS contract on MAP blockchain, in hex.
    /// `wrapped_token`: the wrap near contract account id
    /// `near_chain_id`: the chain id of the near blockchain
    /// `map_chain_id`: the chain id of the map blockchain
    #[init]
    pub fn init(
        owner: AccountId,
        map_light_client: AccountId,
        fee_receiver: AccountId,
        map_bridge_address: String,
        wrapped_token: AccountId,
        near_chain_id: U128,
        map_chain_id: U128,
    ) -> Self {
        assert!(!env::state_exists(), "{}", ERR_MOS_ALREADY_INITIALIZED);
        let map_bridge_address = validate_eth_address(map_bridge_address);

        Self {
            map_client_account: map_light_client,
            map_bridge_address,
            registered_chains: UnorderedMap::new(StorageKey::RegisterChains),
            used_events: UnorderedSet::new(StorageKey::UsedEvents),
            proof_hashes: UnorderedSet::new(StorageKey::ProofHashes),
            owner,
            wrapped_token,
            near_chain_id: near_chain_id.into(),
            map_chain_id: map_chain_id.into(),
            nonce: 0,
            registered_callers: UnorderedMap::new(StorageKey::RegisterCallers),
            fee_receiver,
            state: RunningState::Running,
        }
    }

    #[payable]
    pub fn verify_receipt_proof(&mut self, receipt_proof: ReceiptProof) -> PromiseOrValue<()> {
        self.assert_contract_running();
        let hash = receipt_proof.hash();
        if self.proof_hashes.contains(&hash) {
            return Promise::new(env::signer_account_id())
                .transfer(env::attached_deposit())
                .into();
        }

        let initial_storage = env::storage_usage();
        self.proof_hashes.insert(&hash);
        let current_storage = env::storage_usage();
        self.proof_hashes.remove(&hash);

        let required_deposit =
            Balance::from(current_storage - initial_storage) * env::storage_byte_cost();

        assert!(env::attached_deposit() >= required_deposit, "{}", ERR_MOS_NOT_ENOUGH_DEPOSIT);

        ext_map_light_client::ext(self.map_client_account.clone())
            .with_static_gas(VERIFY_LOG_ENTRY_GAS)
            .verify_proof_data(receipt_proof)
            .then(
                Self::ext(env::current_account_id())
                    .with_static_gas(CALLBACK_PROCESS_PROOF_HASH)
                    .with_attached_deposit(env::attached_deposit())
                    .callback_process_proof_hash(&hash, U128(required_deposit)),
            )
            .into()
    }

    #[payable]
    #[private]
    pub fn callback_process_proof_hash(
        &mut self,
        hash: &CryptoHash,
        required_deposit: U128,
    ) -> PromiseOrValue<()> {
        assert_eq!(env::promise_results_count(), 1, "{}", ERR_MOS_TOO_MANY_RESULTS);
        match env::promise_result(0) {
            PromiseResult::NotReady => env::abort(),
            PromiseResult::Failed => self
                .revert_state(
                    env::attached_deposit(),
                    None,
                    ERR_MOS_VERIFY_PROOF_FAILED.to_string(),
                )
                .into(),
            PromiseResult::Successful(_) => {
                self.proof_hashes.insert(hash);
                env::log_str(format!("Record proof hash:{}", hex::encode(hash)).as_str());

                let ret_deposit = env::attached_deposit() - required_deposit.0;
                if ret_deposit > 0 {
                    Promise::new(env::signer_account_id())
                        .transfer(ret_deposit)
                        .into()
                } else {
                    PromiseOrValue::Value(())
                }
            }
        }
    }

    #[payable]
    pub fn message_out(&mut self, to_chain: U128, msg_data: MessageData) -> PromiseOrValue<()> {
        self.assert_contract_running();
        assert_ne!(to_chain.0, self.near_chain_id, "{}", ERR_MOS_INVALID_TARGET_CHAIN);

        let caller_info = self.registered_callers.get(&env::predecessor_account_id())
            .unwrap_or_else(|| panic_str(ERR_MOS_CALLER_NOT_REGISTERED));
        assert!(caller_info.chain_ids.contains(&to_chain.into()), "{}", ERR_MOS_CALLER_NOT_ALLOWED_TO_CHAIN);

        let attached_deposit = env::attached_deposit();
        let amount = self.get_message_fee(to_chain, msg_data.gas_limit);
        assert!(attached_deposit >= amount.0, "{}", ERR_MOS_NOT_ENOUGH_DEPOSIT);

        // TODO: check target address?

        let order_id = self.get_order_id(&env::predecessor_account_id(), &msg_data.target, to_chain.into());
        let event = MapMessageOutEvent {
            from_chain: self.near_chain_id.into(),
            to_chain,
            order_id,
            from: env::signer_account_id().as_bytes().to_vec(),
            call_data: msg_data.abi_encode(),
        };

        event.emit();

        if amount.0 > 0 {
            let promise = Promise::new(self.fee_receiver.clone()).transfer(amount.0);
            let ret_deposit = attached_deposit - amount.0;
            if ret_deposit > 0 {
                promise.and(Promise::new(env::signer_account_id())
                    .transfer(ret_deposit)).into()
            } else {
                promise.into()
            }
        } else if attached_deposit > 0 {
            Promise::new(env::signer_account_id())
                .transfer(env::attached_deposit()).into()
        } else {
            PromiseOrValue::Value(())
        }
    }


    #[payable]
    pub fn message_in(&mut self, receipt_proof: ReceiptProof, index: usize) -> Promise {
        self.assert_contract_running();

        let logs = &receipt_proof.receipt.logs;
        assert!(index < logs.len(), "{}", ERR_MOS_INDEX_EXCEEDS_EVENT_SIZE);

        let hash = receipt_proof.hash();
        assert!(self.proof_hashes.contains(&hash), "{}", ERR_MOS_PROOF_NOT_VERIFIED);

        let (map_bridge_address, event) =
            MapMessageOutEvent::from_log_entry_data(logs.get(index).unwrap())
                .unwrap_or_else(|| panic_str(ERR_MOS_NOT_MOS_EVENT));
        assert_eq!(self.map_bridge_address, map_bridge_address, "{}", ERR_MOS_INVALID_MAP_MOS_ADDRESS);

        let near_call_data = self.check_map_msg_out_event(&event);

        log!(
            "get MOS msg event: {}",
            serde_json::to_string(&event).unwrap()
        );

        let mut ret_deposit = env::attached_deposit();
        let required_deposit = self.record_order_id(&event.order_id);
        assert!(ret_deposit >= required_deposit, "{}", ERR_MOS_NOT_ENOUGH_DEPOSIT);
        ret_deposit -= required_deposit;

        assert!(ret_deposit >= near_call_data.value.0, "{}", ERR_MOS_NOT_ENOUGH_DEPOSIT);

        Promise::new(near_call_data.target)
            .function_call(
                near_call_data.method,
                near_call_data.payload,
                near_call_data.value.0,
                Gas(near_call_data.gas_limit.0),
            ).then(
            Self::ext(env::current_account_id())
                .with_static_gas(CALLBACK_MAPO_EXECUTE_GAS)
                .with_attached_deposit(ret_deposit - near_call_data.value.0)
                .callback_remote_execute(event.order_id, near_call_data.value.0),
        )
    }


    #[private]
    pub fn callback_remote_execute(&mut self, order_id: CryptoHash, call_amount: u128) -> PromiseOrValue<U128> {
        assert_eq!(env::promise_results_count(), 1, "{}", ERR_MOS_TOO_MANY_RESULTS);
        match env::promise_result(0) {
            PromiseResult::NotReady => env::abort(),
            PromiseResult::Failed => self
                .revert_state(
                    env::attached_deposit() + call_amount,
                    Some(order_id),
                    ERR_MOS_REMOTE_EXECUTE_FAILED.to_string(),
                )
                .into(),
            PromiseResult::Successful(_) => {
                let ret_deposit = env::attached_deposit();
                if ret_deposit > 0 {
                    Promise::new(env::signer_account_id())
                        .transfer(ret_deposit)
                        .into()
                } else {
                    PromiseOrValue::Value(U128(0))
                }
            }
        }
    }

    #[private]
    pub fn report_failure(err: String) {
        panic_str(err.as_str())
    }

    /// Checks whether the provided proof is already used
    pub fn is_used_event(&self, order_id: &CryptoHash) -> bool {
        self.used_events.contains(order_id)
    }
}

impl MAPOServiceV3 {
    fn check_map_msg_out_event(&self, event: &MapMessageOutEvent) -> NearCallData {
        assert_eq!(
            self.near_chain_id, event.to_chain.0,
            "{}", ERR_MOS_INVALID_TO_CHAIN,
        );
        assert!(
            !self.is_used_event(&event.order_id),
            "{}", ERR_MOS_EVENT_ORDER_ID_ALREADY_USED,
        );

        let msg_data = MessageData::abi_decode(event.call_data.clone()).unwrap_or_else(|| {
            panic_str(ERR_MOS_INVALID_MSG_DATA)
        });

        let near_call_data = msg_data.to_near_call_data().unwrap_or_else(|| {
            panic_str(ERR_MOS_INVALID_MSG_DATA)
        });

        assert_eq!(near_call_data.msg_type, 1, "{}", ERR_MOS_NEAR_SUPPORT_TYPE_MSG_ONLY);

        near_call_data
    }

    fn get_message_fee(&self, chain_id: U128, gas_limit: U64) -> U128 {
        let chain_info = self.registered_chains.get(&chain_id.into())
            .unwrap_or_else(|| panic_str(ERR_MOS_CHAIN_NOT_REGISTERED));
        let gas_price = chain_info.gas_price_in_near;

        assert!(chain_info.base_gas.gt(&U64(0)), "{}", ERR_MOS_CHAIN_BAS_GAS_NOT_SET);

        U128::from(((chain_info.base_gas.0 + gas_limit.0) as u128) * gas_price.0)
    }

    fn get_order_id(&mut self, from: &AccountId, to: &Vec<u8>, to_chain_id: u128) -> CryptoHash {
        let mut data: Vec<u8> = Vec::new();
        data.extend(env::current_account_id().as_bytes());
        data.extend(self.nonce.try_to_vec().unwrap());
        data.extend(self.near_chain_id.try_to_vec().unwrap());
        data.extend(to_chain_id.try_to_vec().unwrap());
        data.extend(from.as_bytes());
        data.extend(to);
        self.nonce += 1;
        CryptoHash::try_from(env::sha256(&data[..])).unwrap()
    }

    /// Record order id to make sure it is not re-used.
    fn record_order_id(&mut self, order_id: &CryptoHash) -> Balance {
        let initial_storage = env::storage_usage();
        self.used_events.insert(order_id);
        let current_storage = env::storage_usage();
        let required_deposit =
            Balance::from(current_storage - initial_storage) * env::storage_byte_cost();

        env::log_str(format!("record order id:{}", hex::encode(order_id)).as_str());
        required_deposit
    }

    /// Remove order id if message in failed.
    fn remove_order_id(&mut self, order_id: &CryptoHash) -> Balance {
        let initial_storage = env::storage_usage();

        if !self.used_events.contains(order_id) {
            return 0;
        }

        self.used_events.remove_raw(order_id);
        let current_storage = env::storage_usage();
        Balance::from(initial_storage - current_storage) * env::storage_byte_cost()
    }

    fn assert_contract_running(&self) {
        match self.state {
            RunningState::Running => (),
            _ => panic_str(ERR_MOS_CONTRACT_PAUSED),
        };
    }

    fn assert_contract_paused(&self) {
        match self.state {
            RunningState::Paused => (),
            _ => panic_str(ERR_MOS_CONTRACT_NOT_PAUSED),
        };
    }

    fn assert_caller_is_owner(&self) {
        assert_eq!(env::predecessor_account_id(), self.owner,  "{}", ERR_MOS_UNEXPECTED_CALLER);
    }

    fn revert_state(
        &mut self,
        mut ret_deposit: Balance,
        order_id: Option<CryptoHash>,
        err_msg: String,
    ) -> Promise {
        if let Some(id) = order_id {
            ret_deposit += self.remove_order_id(&id);
        }
        Promise::new(env::signer_account_id())
            .transfer(ret_deposit)
            .then(
                Self::ext(env::current_account_id())
                    .with_static_gas(REPORT_FAILURE_GAS)
                    .report_failure(err_msg),
            )
    }
}