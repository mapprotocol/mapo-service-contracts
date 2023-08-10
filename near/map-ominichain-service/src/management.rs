use near_sdk::json_types::Base64VecU8;
use crate::*;

const NO_DEPOSIT: Balance = 0;
const GAS_FOR_UPGRADE_SELF_DEPLOY: Gas = Gas(15_000_000_000_000);


#[near_bindgen]
impl MAPOServiceV3 {
    #[private]
    #[init(ignore_state)]
    pub fn migrate() -> Self {
        let mos: MAPOServiceV3 = env::state_read().expect("ERR_CONTRACT_IS_NOT_INITIALIZED");
        mos
    }

    pub fn set_owner(&mut self, new_owner: AccountId) {
        self.assert_caller_is_owner();
        self.owner = new_owner;
    }

    pub fn get_owner(&self) -> AccountId {
        self.owner.clone()
    }

    pub fn set_map_light_client(&mut self, map_client_account: AccountId) {
        self.assert_caller_is_owner();
        self.assert_contract_paused();

        self.map_client_account = map_client_account;
    }

    pub fn get_map_light_client(&self) -> AccountId {
        self.map_client_account.clone()
    }

    pub fn set_near_chain_id(&mut self, near_chain_id: U128) {
        self.assert_caller_is_owner();
        self.assert_contract_paused();

        self.near_chain_id = near_chain_id.into();
    }

    pub fn get_near_chain_id(&self) -> U128 {
        self.near_chain_id.into()
    }

    pub fn set_map_chain_id(&mut self, map_chain_id: U128) {
        self.assert_caller_is_owner();
        self.assert_contract_paused();

        self.map_chain_id = map_chain_id.into();
    }

    pub fn get_map_chain_id(&self) -> U128 {
        self.map_chain_id.into()
    }

    pub fn set_map_relay_address(&mut self, map_relay_address: String) {
        self.assert_caller_is_owner();
        self.assert_contract_paused();

        self.map_bridge_address = validate_eth_address(map_relay_address);
    }

    pub fn get_map_relay_address(&self) -> String {
        hex::encode(self.map_bridge_address)
    }

    pub fn set_base_gas(&mut self, chain_id: U128, base_limit: U64) {
        self.assert_caller_is_owner();
        let mut info = self.registered_chains.get(&chain_id.into()).unwrap_or_default();
        info.base_gas = base_limit.into();
        self.registered_chains.insert(&chain_id.into(), &info);
    }

    pub fn set_chain_gas_price_in_near(&mut self, chain_id: U128, price: U128) {
        self.assert_caller_is_owner();
        let mut info = self.registered_chains.get(&chain_id.into()).unwrap_or_default();
        info.gas_price_in_near = price;
        self.registered_chains.insert(&chain_id.into(), &info);
    }

    pub fn set_fee_receiver(&mut self, receiver: AccountId) {
        self.assert_caller_is_owner();
        self.fee_receiver = receiver;
    }

    pub fn upgrade_self(&mut self, code: Base64VecU8) {
        self.assert_caller_is_owner();
        self.assert_contract_paused();

        let current_id = env::current_account_id();
        let promise_id = env::promise_batch_create(&current_id);
        env::promise_batch_action_deploy_contract(promise_id, &code.0);
        env::promise_batch_action_function_call(
            promise_id,
            "migrate",
            &[],
            NO_DEPOSIT,
            env::prepaid_gas() - env::used_gas() - GAS_FOR_UPGRADE_SELF_DEPLOY,
        );
    }
}
