use near_sdk::ext_contract;
use map_light_client::proof::ReceiptProof;

#[ext_contract(ext_map_light_client)]
pub trait MapLightClient {
    fn verify_proof_data(&self, receipt_proof: ReceiptProof);
}