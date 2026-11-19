/// ArtistComponent — handles artist registration, profile management,
/// stream tracking and reward calculation/claiming.
#[starknet::component]
pub mod ArtistComponent {
    use core::starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess,
        StoragePathEntry, Map,
    };
    use starknet::{ContractAddress, get_caller_address};
    use super::super::super::interfaces::iartist::ArtistProfile;

    // Reward tokens credited per stream (1 token per 1 000 streams).
    const REWARD_RATE_PER_1000_STREAMS: u256 = 1_u256;

    // ── Storage ────────────────────────────────────────────────────────────

    #[storage]
    pub struct Storage {
        artists: Map<ContractAddress, ArtistProfile>,
    }

    // ── Events ─────────────────────────────────────────────────────────────

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ArtistRegistered: ArtistRegistered,
        ArtistNameUpdated: ArtistNameUpdated,
        StreamRecorded: StreamRecorded,
        RewardsClaimed: RewardsClaimed,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ArtistRegistered {
        #[key]
        pub artist: ContractAddress,
        pub name: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ArtistNameUpdated {
        #[key]
        pub artist: ContractAddress,
        pub old_name: felt252,
        pub new_name: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct StreamRecorded {
        #[key]
        pub artist: ContractAddress,
        pub streams: u256,
        pub reward_credited: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct RewardsClaimed {
        #[key]
        pub artist: ContractAddress,
        pub amount: u256,
    }

    // ── Internal helpers ───────────────────────────────────────────────────

    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
    > of InternalTrait<TContractState> {
        fn _assert_registered(self: @ComponentState<TContractState>, artist: ContractAddress) {
            let profile = self.artists.entry(artist).read();
            assert(profile.registered, 'Artist: not registered');
        }

        fn _calculate_reward(self: @ComponentState<TContractState>, streams: u256) -> u256 {
            (streams * REWARD_RATE_PER_1000_STREAMS) / 1000_u256
        }
    }

    // ── IArtist implementation ─────────────────────────────────────────────

    #[embeddable_as(ArtistImpl)]
    pub impl Artist<
        TContractState,
        +HasComponent<TContractState>,
    > of super::super::super::interfaces::iartist::IArtist<ComponentState<TContractState>> {
        fn register_artist(ref self: ComponentState<TContractState>, name: felt252) {
            let caller = get_caller_address();
            let existing = self.artists.entry(caller).read();
            assert(!existing.registered, 'Artist: already registered');
            assert(name != 0, 'Artist: name cannot be empty');

            self.artists.entry(caller).write(
                ArtistProfile {
                    address: caller,
                    name,
                    registered: true,
                    total_streams: 0_u256,
                    unclaimed_rewards: 0_u256,
                    total_claimed: 0_u256,
                }
            );

            self.emit(ArtistRegistered { artist: caller, name });
        }

        fn update_artist_name(ref self: ComponentState<TContractState>, new_name: felt252) {
            let caller = get_caller_address();
            self._assert_registered(caller);
            assert(new_name != 0, 'Artist: name cannot be empty');

            let mut profile = self.artists.entry(caller).read();
            let old_name = profile.name;
            profile.name = new_name;
            self.artists.entry(caller).write(profile);

            self.emit(ArtistNameUpdated { artist: caller, old_name, new_name });
        }

        fn record_stream(
            ref self: ComponentState<TContractState>,
            artist: ContractAddress,
            streams: u256,
        ) {
            self._assert_registered(artist);
            assert(streams > 0_u256, 'Artist: streams must be > 0');

            let reward = self._calculate_reward(streams);
            let mut profile = self.artists.entry(artist).read();
            profile.total_streams += streams;
            profile.unclaimed_rewards += reward;
            self.artists.entry(artist).write(profile);

            self.emit(StreamRecorded { artist, streams, reward_credited: reward });
        }

        fn claim_rewards(ref self: ComponentState<TContractState>) {
            let caller = get_caller_address();
            self._assert_registered(caller);

            let mut profile = self.artists.entry(caller).read();
            let amount = profile.unclaimed_rewards;
            assert(amount > 0_u256, 'Artist: no rewards to claim');

            profile.unclaimed_rewards = 0_u256;
            profile.total_claimed += amount;
            self.artists.entry(caller).write(profile);

            self.emit(RewardsClaimed { artist: caller, amount });
        }

        fn get_artist_profile(
            self: @ComponentState<TContractState>,
            artist: ContractAddress,
        ) -> ArtistProfile {
            self.artists.entry(artist).read()
        }

        fn is_registered(self: @ComponentState<TContractState>, artist: ContractAddress) -> bool {
            self.artists.entry(artist).read().registered
        }

        fn get_unclaimed_rewards(
            self: @ComponentState<TContractState>,
            artist: ContractAddress,
        ) -> u256 {
            self.artists.entry(artist).read().unclaimed_rewards
        }

        fn get_total_streams(
            self: @ComponentState<TContractState>,
            artist: ContractAddress,
        ) -> u256 {
            self.artists.entry(artist).read().total_streams
        }

        fn calculate_reward(self: @ComponentState<TContractState>, streams: u256) -> u256 {
            self._calculate_reward(streams)
        }
    }
}
