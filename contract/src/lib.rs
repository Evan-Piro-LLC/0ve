use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::collections::{UnorderedMap, UnorderedSet, Vector};
use near_sdk::serde::{self, Deserialize, Serialize};
// use near_sdk::serde_json::Value::String;
use near_sdk::env::log;
use near_sdk::{env, log, near_bindgen, BorshStorageKey, PanicOnDefault, Promise};
use std::collections::HashMap;

near_sdk::setup_alloc!();

#[derive(BorshStorageKey, BorshSerialize)]
pub enum StorageKeys {
    Posts,
    Categories,
    AccountReactions,
    People,
}

#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize, PanicOnDefault)]
pub struct Contract {
    // posts by name
    pub threads: UnorderedMap<String, UnorderedMap<String, Post>>,
    pub people: UnorderedMap<String, Person>,
    pub fees: Fees,
    pub operator: String,
}

#[derive(BorshDeserialize, BorshSerialize)]
pub struct Person {
    account: String,
    text: Option<String>,
    cid: Option<String>,
    created_timestamp: u64,
    // Friend request can optionally store a message
    friend_requests: UnorderedMap<String, Option<String>>,
    friends: UnorderedSet<String>,
}

#[derive(Serialize, Deserialize, BorshDeserialize, BorshSerialize, Debug)]
#[serde(crate = "near_sdk::serde")]
pub struct JsonPerson {
    account: String,
    text: Option<String>,
    cid: Option<String>,
    created_timestamp: u64,
    friends: Vec<String>,
}

#[derive(Serialize, Deserialize, BorshDeserialize, BorshSerialize, Debug)]
#[serde(crate = "near_sdk::serde")]
pub struct JsonFriendRequest {
    account: String,
    message: Option<String>,
}

impl Person {
    pub fn to_json_person(&self) -> JsonPerson {
        JsonPerson {
            account: self.account.clone(),
            friends: self.friends.to_vec().clone(),
            text: self.text.clone(),
            cid: self.cid.clone(),
            created_timestamp: self.created_timestamp,
        }
    }
}

#[derive(Serialize, Deserialize, BorshDeserialize, BorshSerialize, Debug)]
#[serde(crate = "near_sdk::serde")]
pub struct Post {
    id: String,
    text: String,
    tags: Vec<String>,
    account: String,
    cid: Option<String>,
    ad: Option<Ad>,
    created_timestamp: u64,
    pub reactions: HashMap<String, AccountReaction>,
}

#[derive(Serialize, Deserialize, BorshDeserialize, BorshSerialize, Debug, Clone)]
#[serde(crate = "near_sdk::serde")]
pub struct Fees {
    post_fee: u128,
    thread_fee: u128,
    profile_fee: u128,
    friend_fee: u128,
}

#[derive(Serialize, Deserialize, BorshDeserialize, BorshSerialize, Debug, Clone)]
#[serde(crate = "near_sdk::serde")]
pub struct JsonFees {
    post_fee: String,
    thread_fee: String,
    profile_fee: String,
    friend_fee: String,
}

impl Fees {
    pub fn to_json_fees(&self) -> JsonFees {
        JsonFees {
            post_fee: self.post_fee.to_string(),
            thread_fee: self.thread_fee.to_string(),
            profile_fee: self.profile_fee.to_string(),
            friend_fee: self.friend_fee.to_string(),
        }
    }
}

impl Post {
    pub fn to_json_post(&self) -> JsonPost {
        JsonPost {
            id: self.id.clone(),
            text: self.text.clone(),
            tags: self.tags.clone(),
            account: self.account.clone(),
            cid: self.cid.clone(),
            ad: None,
            created_timestamp: self.created_timestamp,
            reactions: self
                .reactions
                .clone()
                .into_iter()
                .map(|(_id, val)| val)
                .collect(),
        }
    }
}

#[derive(Serialize, Deserialize, BorshDeserialize, BorshSerialize, Debug)]
#[serde(crate = "near_sdk::serde")]
pub struct JsonThreadMetadata {
    name: String,
    size: u64,
}

#[derive(Serialize, Deserialize, BorshDeserialize, BorshSerialize, Debug)]
#[serde(crate = "near_sdk::serde")]
pub struct JsonPost {
    id: String,
    text: String,
    tags: Vec<String>,
    account: String,
    cid: Option<String>,
    ad: Option<Ad>,
    created_timestamp: u64,
    pub reactions: Vec<AccountReaction>,
}

#[derive(BorshDeserialize, BorshSerialize, Deserialize, Serialize, Debug, PartialEq, Clone)]
#[serde(crate = "near_sdk::serde")]
pub enum Reaction {
    Like,
    Dislike,
    Flag,
}

#[derive(Serialize, Deserialize, BorshDeserialize, BorshSerialize, Debug, Clone)]
#[serde(crate = "near_sdk::serde")]
pub struct AccountReaction {
    reaction: Reaction,
    created_timestamp: u64,
    account: String,
}

#[derive(Serialize, Deserialize, BorshDeserialize, BorshSerialize, Debug)]
#[serde(crate = "near_sdk::serde")]
pub struct Ad {
    text: String,
    url: String,
    account: String,
}

#[near_bindgen]
impl Contract {
    #[init]
    pub fn new() -> Self {
        Self {
            threads: UnorderedMap::new(StorageKeys::Categories),
            people: UnorderedMap::new(StorageKeys::People),
            fees: Fees {
                post_fee: 10_000_000_000_000_000_000_000,
                friend_fee: 10_000_000_000_000_000_000_000,
                profile_fee: 10_000_000_000_000_000_000_000,
                thread_fee: 10_000_000_000_000_000_000_000,
            },
            operator: env::signer_account_id(),
        }
    }
    pub fn set_fees(&mut self, fees: Fees) {
        assert_eq!(self.operator, env::signer_account_id());
        self.fees = fees
    }

    pub fn delete_thread(&mut self, thread_name: String) {
        assert_eq!(self.operator, env::signer_account_id());
        let mut post = self.threads.remove(&thread_name);
    }

    pub fn delete_post(&mut self, thread_name: String, post_id: String) {
        assert_eq!(self.operator, env::signer_account_id());
        self.threads
            .get(&thread_name)
            .expect("channel doesn't exist")
            .remove(&post_id);
    }

    #[payable]
    pub fn add_thread(&mut self, thread_name: String) -> String {
        self.apply_fee(self.fees.thread_fee);
        assert_eq!(self.threads.get(&thread_name).is_none(), true);
        let thread = UnorderedMap::new(thread_name.as_bytes());
        self.threads.insert(&thread_name, &thread);
        thread_name
    }

    pub fn get_friend_requests(
        &self,
        account: String,
        from_index: u64,
        limit: u64,
    ) -> Vec<JsonFriendRequest> {
        let requests = self
            .people
            .get(&account)
            .expect("person not found")
            .friend_requests;
        let vals = &requests.values_as_vector();
        let keys = &requests.keys_as_vector();
        (from_index..std::cmp::min(from_index + limit, requests.len()))
            .map(|index| JsonFriendRequest {
                account: keys.get(index).unwrap(),
                message: vals.get(index).unwrap(),
            })
            .collect()
    }

    #[payable]
    pub fn send_friend_request(&mut self, to_account: String, message: Option<String>) {
        self.apply_fee(self.fees.friend_fee);
        let from_account = env::signer_account_id();
        let mut to_person = self.people.get(&to_account).expect("person not found");

        to_person.friend_requests.insert(&from_account, &message);
        self.people.insert(&to_account, &to_person);
    }

    #[payable]
    pub fn accept_friend_request(&mut self, from_account: String) {
        self.apply_fee(self.fees.friend_fee);
        let to_account = env::signer_account_id();
        let mut to_person = self.people.get(&to_account).expect("person not found");

        to_person.friend_requests.remove(&from_account);
        to_person.friends.insert(&from_account);

        self.people.insert(&to_account, &to_person);

        let mut from_person = self.people.get(&from_account).expect("person not found");
        from_person.friends.insert(&to_account);

        self.people.insert(&from_account, &from_person);
    }

    pub fn reject_friend_request(&mut self, from_account: String) {
        let to_account = env::signer_account_id();
        let mut person = self.people.get(&to_account).expect("person not found");

        person.friend_requests.remove(&from_account);

        self.people.insert(&to_account, &person);
    }

    pub fn get_person(&self, account: String) -> Option<JsonPerson> {
        self.people
            .get(&account)
            .map(|person| person.to_json_person())
    }

    pub fn get_fees(&self) -> JsonFees {
        self.fees.to_json_fees()
    }

    fn apply_fee(&self, fee: u128) {
        let attached_deposit = env::attached_deposit();
        if attached_deposit < fee {
            Promise::new(env::predecessor_account_id()).transfer(attached_deposit);
            // let msg = "The attached deposit is less than the fee of "
            panic!(
                "The attached deposit is less than the fee of {}. Deposit has been refunded.",
                fee
            );
        };
    }

    pub fn put_person(&mut self, text: Option<String>, cid: Option<String>) -> JsonPerson {
        let account = env::signer_account_id();
        let mut existing_person = self.people.get(&account);
        match existing_person {
            Some(mut person) => {
                person.text = text;
                person.cid = cid;
                self.people.insert(&account, &person);
                person.to_json_person()
            }
            None => {
                let friend_request_prefix = env::signer_account_id() + "fr";
                let friends_prefix = env::signer_account_id() + "f";
                let person = Person {
                    account: env::signer_account_id(),
                    friend_requests: UnorderedMap::new(friend_request_prefix.into_bytes()),
                    friends: UnorderedSet::new(friends_prefix.into_bytes()),
                    text,
                    cid,
                    created_timestamp: env::block_timestamp(),
                };
                self.people.insert(&account, &person);
                person.to_json_person()
            }
        }
    }

    #[payable]
    pub fn add_post(&mut self, thread_name: String, text: String, cid: Option<String>) {
        self.apply_fee(self.fees.post_fee);
        let mut thread = self.threads.get(&thread_name).expect("thread not found");
        let account = env::signer_account_id();
        let created_timestamp = env::block_timestamp();
        let id = env::signer_account_id() + "-" + &created_timestamp.to_string();
        let post = Post {
            id: id.clone(),
            text,
            tags: vec![],
            account,
            cid,
            ad: None,
            created_timestamp: env::block_timestamp(),
            reactions: HashMap::new(),
        };

        thread.insert(&id, &post);
        self.threads.insert(&thread_name, &thread);
    }

    pub fn react_to_post(&mut self, thread_name: String, post_id: String, reaction: Reaction) {
        let mut post = self
            .threads
            .get(&thread_name)
            .unwrap()
            .get(&post_id)
            .expect("post doesn't exist");

        let account = env::signer_account_id();

        let account_reaction = AccountReaction {
            account,
            reaction,
            created_timestamp: env::block_timestamp(),
        };

        post.reactions
            .insert(env::signer_account_id(), account_reaction);
        self.threads
            .get(&thread_name)
            .unwrap()
            .insert(&post.id, &post);
    }

    pub fn unreact_to_post(&mut self, thread_name: String, post_id: String) {
        let mut post = self
            .threads
            .get(&thread_name)
            .expect("channel doesn't exist")
            .get(&post_id)
            .expect("post doesn't exist");

        post.reactions
            .remove(env::signer_account_id().as_str())
            .unwrap();
        self.threads
            .get(&thread_name)
            .expect("channel doesn't exist")
            .insert(&post.id, &post);
    }

    pub fn get_people(&self, from_index: u64, limit: u64) -> Vec<JsonPerson> {
        let vals = self.people.values_as_vector();
        (from_index..std::cmp::min(from_index + limit, self.people.len()))
            .rev()
            .map(|index| vals.get(index).unwrap().to_json_person())
            .collect()
    }

    pub fn get_threads(&self, from_index: u64, limit: u64) -> Vec<JsonThreadMetadata> {
        let vals = self.threads.values_as_vector();
        let keys = self.threads.keys_as_vector();
        (from_index..std::cmp::min(from_index + limit, self.threads.len()))
            .rev()
            .map(|index| JsonThreadMetadata {
                name: keys.get(index).unwrap(),
                size: vals.get(index).unwrap().len(),
            })
            .collect()
    }

    pub fn get_thread(&self, thread_name: String, from_index: u64, limit: u64) -> Vec<JsonPost> {
        let thread = self.threads.get(&thread_name).expect("channel not found");

        let values = &thread.values_as_vector();

        (from_index..std::cmp::min(from_index + limit, thread.len().clone()))
            .rev()
            .map(|index| values.get(index).unwrap().to_json_post())
            .collect()
    }
}

const TEST_SIGNER_ACCOUNT: &str = "bob_near";
const TEST_CURRENT_ACCOUNT: &str = "alice_near";
const TEST_PREDECESSOR_ACCOUNT: &str = "carol_near";
const TEST_THREAD_NAME: &str = "test_cat";

#[cfg(not(target_arch = "wasm32"))]
#[cfg(test)]
mod tests {
    use super::*;
    use near_sdk::MockedBlockchain;
    use near_sdk::{testing_env, VMContext};

    fn get_context(input: Vec<u8>, is_view: bool) -> VMContext {
        VMContext {
            current_account_id: TEST_CURRENT_ACCOUNT.to_string(),
            signer_account_id: TEST_SIGNER_ACCOUNT.to_string(),
            signer_account_pk: vec![0, 1, 2],
            predecessor_account_id: TEST_PREDECESSOR_ACCOUNT.to_string(),
            input,
            block_index: 0,
            block_timestamp: 0,
            account_balance: 0,
            account_locked_balance: 0,
            storage_usage: 0,
            attached_deposit: 0,
            prepaid_gas: 10u64.pow(18),
            random_seed: vec![0, 1, 2],
            is_view,
            output_data_receivers: vec![],
            epoch_height: 0,
        }
    }

    #[test]
    fn test_add_post() {
        let text = String::from("test message");
        let cid = String::from("abcdefg");
        let context = get_context(vec![], false);
        testing_env!(context);
        let mut contract = Contract::default();
        contract.add_post(TEST_NAME.to_string(), text.to_string(), Some(text));
        assert_eq!(
            text,
            contract
                .get_thread(TEST_THREAD_NAME.to_string(), 0, 1)
                .unwrap()
                .get_thread(0, 1)
                .get(0)
                .unwrap()
                .text
        );
    }

    #[test]
    fn test_react_to_post() {
        let text = String::from("test message");
        let cid = String::from("abcdefg");
        let context = get_context(vec![], false);
        testing_env!(context);
        let mut contract = Contract::default();

        contract.add_post(
            TEST_NAME.to_string(),
            text.to_string(),
            Some(cid.to_string()),
        );
        let get_thread_result = contract.get_thread(TEST_NAME.to_string(), 0, 1);
        let post = get_thread_result.get(0).unwrap();

        contract.react_to_post(TEST_NAME.to_string(), post.id.clone(), Reaction::Like);

        assert_eq!(
            Reaction::Like,
            contract
                .get_thread(TEST_NAME.to_string(), 0, 1)
                .unwrap()
                .reactions
                .get(TEST_SIGNER_ACCOUNT)
                .expect("Test account not found")
                .reaction
        );
    }
}
