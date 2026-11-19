use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct ArtistProfile {
    pub address: ContractAddress,
    pub name: felt252,
    pub registered: bool,
    pub total_streams: u256,
    pub unclaimed_rewards: u256,
    pub total_claimed: u256,
}

#[starknet::interface]
pub trait IArtist<TContractState> {
    /// Register the caller as an artist with the given name.
    fn register_artist(ref self: TContractState, name: felt252);

    /// Update the registered artist's display name.
    fn update_artist_name(ref self: TContractState, new_name: felt252);

    /// Record a stream event and credit reward tokens to the artist.
    /// Only callable by an authorised song/marketplace component.
    fn record_stream(ref self: TContractState, artist: ContractAddress, streams: u256);

    /// Claim all accumulated reward tokens for the caller.
    fn claim_rewards(ref self: TContractState);

    // ── View functions ──────────────────────────────────────────────────────

    /// Return the full profile for a given artist address.
    fn get_artist_profile(self: @TContractState, artist: ContractAddress) -> ArtistProfile;

    /// Return whether an address is a registered artist.
    fn is_registered(self: @TContractState, artist: ContractAddress) -> bool;

    /// Return unclaimed reward balance for an artist.
    fn get_unclaimed_rewards(self: @TContractState, artist: ContractAddress) -> u256;

    /// Return total streams recorded for an artist.
    fn get_total_streams(self: @TContractState, artist: ContractAddress) -> u256;

    /// Calculate the reward for a given stream count using the current rate.
    fn calculate_reward(self: @TContractState, streams: u256) -> u256;
}
