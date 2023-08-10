use ethabi::{ParamType, Token};
use map_light_client::header::Address;
use map_light_client::proof::LogEntry;
use near_sdk::json_types::{U128, U64};
use near_sdk::serde::{Deserialize, Serialize};
use near_sdk::{log, AccountId, CryptoHash};
use rlp::{Encodable, RlpStream};
use crate::evm::{EthEventParams, EVMEvent};

const MSG_OUT_TYPE: &str = "ca1cf8cebf88499429cca8f87cbca15ab8dafd06702259a5344ddce89ef3f3a5";

/*
    struct MessageData {
        bool relay;
        MessageType msgType;
        bytes target;
        bytes payload;
        uint256 gasLimit;
        uint256 value;
    }
 */


#[derive(Serialize, Deserialize, Debug, Eq, PartialEq, Clone)]
#[serde(crate = "near_sdk::serde")]
pub struct NearCallData {
    pub relay: bool,
    pub msg_type: u8,
    pub target: AccountId,
    pub method: String,
    pub payload: Vec<u8>,
    pub gas_limit: U64,
    pub value: U128,
}

#[derive(Serialize, Deserialize, Debug, Eq, PartialEq, Clone)]
#[serde(crate = "near_sdk::serde")]
pub struct MessageData {
    pub relay: bool,
    pub msg_type: u8,
    #[serde(with = "crate::bytes::hexstring")]
    pub target: Vec<u8>,
    #[serde(with = "crate::bytes::hexstring")]
    pub payload: Vec<u8>,
    pub gas_limit: U64,
    pub value: U128,
}

impl MessageData {
    pub fn abi_decode(data: Vec<u8>) -> Option<Self> {
        let param_type = vec![
            ParamType::Bool,
            ParamType::Uint(8),
            ParamType::Bytes,
            ParamType::Bytes,
            ParamType::Uint(64),
            ParamType::Uint(128),
        ];

        let tokens = ethabi::decode(param_type.as_slice(), data.as_slice()).ok()?;
        if tokens.len() != param_type.len() {
            return None;
        }
        let relay = tokens[0].clone().to_bool()?;
        let msg_type = tokens[1].clone().to_uint()?.as_u32() as u8;
        let target = tokens[2].clone().to_bytes()?;
        let payload = tokens[3].clone().to_bytes()?;
        let gas_limit = U64::from(tokens[4].clone().to_uint()?.as_u64());
        let value = U128::from(tokens[5].clone().to_uint()?.as_u128());
        Some(Self {
            relay,
            msg_type,
            target,
            payload,
            gas_limit,
            value
        })
    }

    pub fn abi_encode(&self) -> Vec<u8> {
        let tokens: Vec<Token> = vec![
            Token::Bool(self.relay),
            Token::Uint(self.msg_type.into()),
            Token::Bytes(self.target.clone()),
            Token::Bytes(self.payload.clone()),
            Token::Uint(self.gas_limit.0.into()),
            Token::Uint(self.value.0.into()),
        ];

        ethabi::encode(tokens.as_slice())
    }

    pub fn to_near_call_data(&self) -> Option<NearCallData> {
        let target = String::from_utf8(self.target.clone()).ok()?.parse().ok()?;

        Some(NearCallData {
            relay: self.relay,
            msg_type: self.msg_type,
            // TODO: method
            method: "".to_string(),
            target,
            payload: self.payload.clone(),
            gas_limit: self.gas_limit,
            value: self.value,
        })
    }
}

/*
    event mapMessageOut(uint256 indexed fromChain, uint256 indexed toChain, bytes32 orderId, bytes fromAddrss, bytes callData);
 */
#[derive(Serialize, Deserialize, Debug, Clone, PartialEq, Eq)]
#[serde(crate = "near_sdk::serde")]
pub struct MapMessageOutEvent {
    pub from_chain: U128,
    pub to_chain: U128,
    #[serde(with = "crate::bytes::hexstring")]
    pub order_id: CryptoHash,
    pub from: Vec<u8>,
    pub call_data: Vec<u8>,
}

impl MapMessageOutEvent {
    fn event_params() -> EthEventParams {
        vec![
            ("fromChain".to_string(), ParamType::Uint(256), true),
            ("toChain".to_string(), ParamType::Uint(256), true),
            ("orderId".to_string(), ParamType::FixedBytes(32), false),
            ("from".to_string(), ParamType::Bytes, false),
            ("data".to_string(), ParamType::Bytes, false),
        ]
    }

    /// Parse raw log entry data.
    pub fn from_log_entry_data(data: &LogEntry) -> Option<(Address, Self)> {
        let event = EVMEvent::from_log_entry_data("mapMessageOut", Self::event_params(), data)?;
        let from_chain = event.log.params[0]
            .value
            .clone()
            .to_uint()?
            .as_u128()
            .into();
        let to_chain = event.log.params[1]
            .value
            .clone()
            .to_uint()?
            .as_u128()
            .into();
        let order_id: CryptoHash = event.log.params[2]
            .value
            .clone()
            .to_fixed_bytes()?
            .try_into()
            .ok()?;
        let from = event.log.params[3].value.clone().to_bytes()?;
        let call_data = event.log.params[4].value.clone().to_bytes()?;
        Some((
            event.address,
            Self {
                from_chain,
                to_chain,
                order_id,
                from,
                call_data
            },
        ))
    }

    pub fn emit(&self) {
        log!("msg out: {}", serde_json::to_string(self).unwrap());
        log!("{}{}", MSG_OUT_TYPE, self);
    }
}

impl Encodable for MapMessageOutEvent {
    fn rlp_append(&self, s: &mut RlpStream) {
        s.begin_list(5);

        s.append(&self.from_chain.0);
        s.append(&self.to_chain.0);
        s.append(&self.order_id.as_ref());
        s.append(&self.from);
        s.append(&self.call_data);
    }
}

impl std::fmt::Display for MapMessageOutEvent {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", hex::encode(rlp::encode(self)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::validate_eth_address;
    use hex;
    use near_sdk::AccountId;
    use std::str::FromStr;
    use std::string;
    use std::string::String;
    use ethabi::{param_type::Writer, Token};
    use map_light_client::{header::Hash as MapHash, traits::FromVec};
    use tiny_keccak::{Keccak,keccak256};

    impl TransferOutEvent {
        pub fn to_log_entry_data(&self, map_bridge_address: Address) -> LogEntry {
            EVMEvent::to_log_entry_data(
                "mapTransferOut",
                TransferOutEvent::event_params(),
                map_bridge_address,
                vec![
                    self.from_chain.0.clone().to_be_bytes().to_vec(),
                    self.to_chain.0.clone().to_be_bytes().to_vec(),
                ],
                vec![
                    Token::FixedBytes(self.order_id.clone().to_vec()),
                    Token::Bytes(self.token.clone()),
                    Token::Bytes(self.from.clone()),
                    Token::Bytes(self.to.clone()),
                    Token::Uint(self.amount.0.into()),
                    Token::Bytes(self.to_chain_token.clone()),
                ],
            )
        }
    }

    impl SwapOutEvent {
        pub fn to_log_entry_data(&self, map_bridge_address: Address) -> LogEntry {
            EVMEvent::to_log_entry_data(
                "mapSwapOut",
                SwapOutEvent::event_params(),
                map_bridge_address,
                vec![
                    self.from_chain.0.clone().to_be_bytes().to_vec(),
                    self.to_chain.0.clone().to_be_bytes().to_vec(),
                ],
                vec![
                    Token::FixedBytes(self.order_id.clone().to_vec()),
                    Token::Bytes(self.token.clone()),
                    Token::Bytes(self.from.clone()),
                    Token::Bytes(self.to.clone()),
                    Token::Uint(self.amount.0.into()),
                    Token::Bytes(self.swap_data.clone()),
                ],
            )
        }
    }

    #[test]
    fn test_decode_transfer_event_data() {
        let logs_str = r#"[
            {
                "address": "0xe2123fa0c94db1e5baeff348c0e7aecd15a11b45",
                "topics": [
                    "0x44ff77018688dad4b245e8ab97358ed57ed92269952ece7ffd321366ce078622",
                    "0x00000000000000000000000000000000000000000000000000000000000000d4",
                    "0x000000000000000000000000000000000000000000000000000000004e454153"
                ],
                "data": "0x64e604787cbf194841e7b68d7cd28786f6c9a0a3ab9f8b0a0e87cb4387ab010700000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000006400000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000014ec3e016916ba9f10762e33e03e8556409d096fb40000000000000000000000000000000000000000000000000000000000000000000000000000000000000014223e016916ba9f10762e33e03e8556409d096f22000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f70616e646172722e746573746e6574000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000196d63735f746f6b656e5f302e6d63732e746573742e6e65617200000000000000"
            }
        ]"#;

        let logs: Vec<LogEntry> = serde_json::from_str(&logs_str).unwrap();
        assert_eq!(1, logs.len(), "should have only 1 log");

        let (mcs, event) = TransferOutEvent::from_log_entry_data(logs.get(0).unwrap()).unwrap();
        assert_eq!(
            "ec3e016916ba9f10762e33e03e8556409d096fb4",
            hex::encode(event.token.clone())
        );
        assert_eq!(
            "223e016916ba9f10762e33e03e8556409d096f22",
            hex::encode(event.from.clone())
        );
        assert_eq!(212, event.from_chain.0);
        assert_eq!(1313161555, event.to_chain.0);
        assert_eq!(
            "pandarr.testnet",
            String::from_utf8(event.to.clone()).unwrap()
        );
        assert_eq!(100, event.amount.0);
        assert_eq!(
            "mcs_token_0.mcs.test.near",
            String::from_utf8(event.to_chain_token.clone()).unwrap()
        );
        assert_eq!(
            "e2123fa0c94db1e5baeff348c0e7aecd15a11b45".to_lowercase(),
            hex::encode(mcs)
        );

        let data = event.to_log_entry_data(mcs);
        let result = TransferOutEvent::from_log_entry_data(&data).unwrap();
        assert_eq!(result.1, event);
    }

    #[test]
    fn test_encode_transfer_event() {
        let event = TransferOutEvent {
            from_chain: U128(212),
            to_chain: U128(1313161555),
            order_id: keccak256("123".as_bytes()),
            token: hex::decode("ec3e016916ba9f10762e33e03e8556409d096fb4").unwrap(),
            from: hex::decode("223e016916ba9f10762e33e03e8556409d096f22").unwrap(),
            to: "pandarr.test.near".as_bytes().to_vec(),
            amount: U128(100),
            to_chain_token: "wrap.test.near".as_bytes().to_vec(),
        };

        let data = event.to_log_entry_data([1; 20]);
        let result = TransferOutEvent::from_log_entry_data(&data).unwrap();
        assert_eq!(result.0, [1; 20]);
        assert_eq!(result.1, event);

        println!("{:?}", serde_json::to_string(&data).unwrap());
    }

    #[test]
    fn test_swap_event_data() {
        let mut swap_param: Vec<SwapParam> = Vec::new();
        swap_param.push(SwapParam {
            amount_in: U128(0),
            min_amount_out: U128(1),
            path: "usdc.map007.testnetXwrap.testnet".as_bytes().to_vec(),
            router_index: U64(1786),
        });

        let raw_swap_data = SwapData {
            swap_param,
            target_token: "wrap.testnet".as_bytes().to_vec(),
        };
        let event = SwapOutEvent {
            from_chain: U128(212),
            to_chain: U128(1360100178526210),
            order_id: [8; 32],
            token: vec![1; 20],
            from: vec![2; 20],
            to: "pandarr.testnet".as_bytes().to_vec(),
            amount: U128(100000),
            swap_data: raw_swap_data.abi_encode(),
            raw_swap_data,
            src_token: "".to_string(),
            src_amount: U128(0),
            // dst_token: vec![],
        };

        let mcs = validate_eth_address("630105189c7114667a7179Aa57f07647a5f42B7F".to_string());

        let data = event.to_log_entry_data(mcs);
        let result = SwapOutEvent::from_log_entry_data(&data).unwrap();
        assert_eq!(result.0, mcs);
        assert_eq!(result.1, event);

        println!("{}", serde_json::to_string(&data).unwrap());
        println!("{}", serde_json::to_string(&event.raw_swap_data).unwrap())
    }

    #[test]
    fn test_encode_swap_data() {
        let exp = "00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010558cae75be61b3e8000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000006fb0000000000000000000000000000000000000000000000000000000000000020757364632e6d61703030372e746573746e657458777261702e746573746e6574000000000000000000000000000000000000000000000000000000000000002a30783030303030303030303030303030303030303030303030303030303030303030303030303030303000000000000000000000000000000000000000000000";

        let mut swap_param: Vec<SwapParam> = Vec::new();
        swap_param.push(SwapParam {
            amount_in: U128(0),
            min_amount_out: U128(301312398990044673000),
            path: hex::decode("757364632e6d61703030372e746573746e657458777261702e746573746e6574").unwrap(),
            router_index: U64(1787),
        });

        let swap_data = SwapData {
            swap_param,
            target_token: hex::decode("307830303030303030303030303030303030303030303030303030303030303030303030303030303030").unwrap(),
        };

        let byte_str = hex::encode(swap_data.abi_encode().as_slice());
        assert_eq!(exp, byte_str);

        let swap_data_dec = SwapData::abi_decode(hex::decode(exp).unwrap()).unwrap();
        assert_eq!(swap_data, swap_data_dec)
    }

    #[test]
    fn test_decode_swap_event_data() {
        let logs_str = r#"[
            {
                "address": "0xe2123fa0c94db1e5baeff348c0e7aecd15a11b45",
                "topics": [
                    "0xca1cf8cebf88499429cca8f87cbca15ab8dafd06702259a5344ddce89ef3f3a5",
                    "0x00000000000000000000000000000000000000000000000000000000000000d4",
                    "0x000000000000000000000000000000000000000000000000000000004e454153"
                ],
                "data": "0x010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000027b46536c66c8e30000000000000000000000000000000000000000000000000000000000000000000180000000000000000000000000000000000000000000000000000000000000000e757364632e746573742e6e65617200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000140202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000001170616e646172722e746573742e6e65617200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000160000000000000000000000000040404040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000021e19e0c9bab240000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001d757364632e746573742e6e65617258777261702e746573742e6e656172000000000000000000000000000000000000000000000000000000000000000000000e777261702e746573742e6e656172000000000000000000000000000000000000"
            }
        ]"#;

        let logs: Vec<LogEntry> = serde_json::from_str(&logs_str).unwrap();
        assert_eq!(1, logs.len(), "should have only 1 log");

        let (mcs, mut event) = SwapOutEvent::from_log_entry_data(logs.get(0).unwrap()).unwrap();

        event.basic_check("wrap.testnet".parse().unwrap());
        assert_eq!(
            "usdc.test.near",
            String::from_utf8(event.token.clone()).unwrap()
        );
        assert_eq!(
            "0202020202020202020202020202020202020202",
            hex::encode(event.from.clone())
        );
        assert_eq!(212, event.from_chain.0);
        assert_eq!(1313161555, event.to_chain.0);
        assert_eq!(
            "pandarr.test.near",
            String::from_utf8(event.to.clone()).unwrap()
        );
        assert_eq!(3000000000000000000000000, event.amount.0);
        assert_eq!(
            "e2123fa0c94db1e5baeff348c0e7aecd15a11b45".to_lowercase(),
            hex::encode(mcs)
        );

        let data = event.to_log_entry_data(mcs);
        let result = SwapOutEvent::from_log_entry_data(&data).unwrap();
        assert_eq!(result.1, event);
    }
}
