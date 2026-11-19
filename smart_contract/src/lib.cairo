/// Interface representing `HelloContract`.
/// This interface allows modification and retrieval of the contract balance.
#[starknet::interface]
pub trait IHelloStarknet<TContractState> {
    /// Increase contract balance.
    fn increase_balance(ref self: TContractState, amount: felt252);
    /// Retrieve contract balance.
    fn get_balance(self: @TContractState) -> felt252;
}

/// Simple contract for managing balance.
#[starknet::contract]
mod HelloStarknet {
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        balance: felt252,
    }

    #[abi(embed_v0)]
    impl HelloStarknetImpl of super::IHelloStarknet<ContractState> {
        fn increase_balance(ref self: ContractState, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            self.balance.write(self.balance.read() + amount);
        }

        fn get_balance(self: @ContractState) -> felt252 {
            self.balance.read()
        }
    }
}

// ── Module tree ────────────────────────────────────────────────────────────

pub mod interfaces {
    pub mod iartist;
}

pub mod Components {
    pub mod artist;
}

// ── Cairofy contract (wraps ArtistComponent for integration use) ───────────

use interfaces::iartist::IArtist;

#[starknet::contract]
pub mod CairofyArtist {
    use Components::artist::ArtistComponent;

    component!(path: ArtistComponent, storage: artist, event: ArtistEvent);

    #[abi(embed_v0)]
    impl ArtistImpl = ArtistComponent::ArtistImpl<ContractState>;
    impl ArtistInternalImpl = ArtistComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        artist: ArtistComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ArtistEvent: ArtistComponent::Event,
    }
}
