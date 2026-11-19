use starknet::ContractAddress;
use starknet::contract_address_const;

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait,
    start_cheat_caller_address, stop_cheat_caller_address,
};

use smart_contract::interfaces::iartist::{IArtistDispatcher, IArtistDispatcherTrait};

fn artist_addr() -> ContractAddress {
    contract_address_const::<0x1>()
}

fn other_addr() -> ContractAddress {
    contract_address_const::<0x2>()
}

fn deploy_cairofy_artist() -> IArtistDispatcher {
    let contract = declare("CairofyArtist").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    IArtistDispatcher { contract_address }
}

// ── register_artist ────────────────────────────────────────────────────────

#[test]
fn test_register_artist_succeeds() {
    let dispatcher = deploy_cairofy_artist();
    let artist = artist_addr();

    start_cheat_caller_address(dispatcher.contract_address, artist);
    dispatcher.register_artist('Alice');
    stop_cheat_caller_address(dispatcher.contract_address);

    assert(dispatcher.is_registered(artist), 'Should be registered');
    let profile = dispatcher.get_artist_profile(artist);
    assert(profile.name == 'Alice', 'Name mismatch');
    assert(profile.total_streams == 0_u256, 'Streams should be 0');
    assert(profile.unclaimed_rewards == 0_u256, 'Rewards should be 0');
}

#[test]
#[should_panic(expected: ('Artist: already registered',))]
fn test_register_artist_twice_panics() {
    let dispatcher = deploy_cairofy_artist();
    let artist = artist_addr();

    start_cheat_caller_address(dispatcher.contract_address, artist);
    dispatcher.register_artist('Alice');
    dispatcher.register_artist('Alice Again');
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
#[should_panic(expected: ('Artist: name cannot be empty',))]
fn test_register_artist_empty_name_panics() {
    let dispatcher = deploy_cairofy_artist();
    let artist = artist_addr();

    start_cheat_caller_address(dispatcher.contract_address, artist);
    dispatcher.register_artist(0);
    stop_cheat_caller_address(dispatcher.contract_address);
}

// ── update_artist_name ─────────────────────────────────────────────────────

#[test]
fn test_update_artist_name_succeeds() {
    let dispatcher = deploy_cairofy_artist();
    let artist = artist_addr();

    start_cheat_caller_address(dispatcher.contract_address, artist);
    dispatcher.register_artist('Alice');
    dispatcher.update_artist_name('Alice v2');
    stop_cheat_caller_address(dispatcher.contract_address);

    let profile = dispatcher.get_artist_profile(artist);
    assert(profile.name == 'Alice v2', 'Name should be updated');
}

#[test]
#[should_panic(expected: ('Artist: not registered',))]
fn test_update_name_unregistered_panics() {
    let dispatcher = deploy_cairofy_artist();
    let artist = artist_addr();

    start_cheat_caller_address(dispatcher.contract_address, artist);
    dispatcher.update_artist_name('Ghost');
    stop_cheat_caller_address(dispatcher.contract_address);
}

// ── record_stream ──────────────────────────────────────────────────────────

#[test]
fn test_record_stream_credits_rewards() {
    let dispatcher = deploy_cairofy_artist();
    let artist = artist_addr();

    start_cheat_caller_address(dispatcher.contract_address, artist);
    dispatcher.register_artist('Alice');
    stop_cheat_caller_address(dispatcher.contract_address);

    dispatcher.record_stream(artist, 1000_u256);

    assert(dispatcher.get_total_streams(artist) == 1000_u256, 'Streams should be 1000');
    assert(dispatcher.get_unclaimed_rewards(artist) == 1_u256, 'Reward should be 1');
}

#[test]
fn test_record_stream_accumulates() {
    let dispatcher = deploy_cairofy_artist();
    let artist = artist_addr();

    start_cheat_caller_address(dispatcher.contract_address, artist);
    dispatcher.register_artist('Alice');
    stop_cheat_caller_address(dispatcher.contract_address);

    dispatcher.record_stream(artist, 1000_u256);
    dispatcher.record_stream(artist, 2000_u256);

    assert(dispatcher.get_total_streams(artist) == 3000_u256, 'Streams should accumulate');
    assert(dispatcher.get_unclaimed_rewards(artist) == 3_u256, 'Rewards should accumulate');
}

#[test]
#[should_panic(expected: ('Artist: not registered',))]
fn test_record_stream_unregistered_panics() {
    let dispatcher = deploy_cairofy_artist();
    dispatcher.record_stream(artist_addr(), 1000_u256);
}

// ── claim_rewards ──────────────────────────────────────────────────────────

#[test]
fn test_claim_rewards_clears_unclaimed() {
    let dispatcher = deploy_cairofy_artist();
    let artist = artist_addr();

    start_cheat_caller_address(dispatcher.contract_address, artist);
    dispatcher.register_artist('Alice');
    stop_cheat_caller_address(dispatcher.contract_address);

    dispatcher.record_stream(artist, 5000_u256);

    start_cheat_caller_address(dispatcher.contract_address, artist);
    dispatcher.claim_rewards();
    stop_cheat_caller_address(dispatcher.contract_address);

    assert(dispatcher.get_unclaimed_rewards(artist) == 0_u256, 'Unclaimed should be 0');
    let profile = dispatcher.get_artist_profile(artist);
    assert(profile.total_claimed == 5_u256, 'total_claimed should be 5');
}

#[test]
#[should_panic(expected: ('Artist: no rewards to claim',))]
fn test_claim_rewards_with_nothing_panics() {
    let dispatcher = deploy_cairofy_artist();
    let artist = artist_addr();

    start_cheat_caller_address(dispatcher.contract_address, artist);
    dispatcher.register_artist('Alice');
    dispatcher.claim_rewards();
    stop_cheat_caller_address(dispatcher.contract_address);
}

// ── calculate_reward ───────────────────────────────────────────────────────

#[test]
fn test_calculate_reward_rate() {
    let dispatcher = deploy_cairofy_artist();
    assert(dispatcher.calculate_reward(1000_u256) == 1_u256, 'Rate: 1 per 1000');
    assert(dispatcher.calculate_reward(500_u256) == 0_u256, 'Rate: 0 for <1000');
    assert(dispatcher.calculate_reward(10000_u256) == 10_u256, 'Rate: 10 for 10000');
}

// ── is_registered ──────────────────────────────────────────────────────────

#[test]
fn test_is_registered_false_for_unknown() {
    let dispatcher = deploy_cairofy_artist();
    assert(!dispatcher.is_registered(other_addr()), 'Should not be registered');
}
