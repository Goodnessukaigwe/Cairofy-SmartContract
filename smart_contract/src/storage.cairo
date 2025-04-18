use starknet::ContractAddress;

// Define the Song struct to hold song-related information
#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct Song {
    id: u256,  // Unique identifier for the song
    title: felt252,  // Title of the song
    artist_id: u256,  // Reference to the artist who created the song
    duration: u64,  // Duration of the song in seconds
    release_date: u64,  // Unix timestamp for release date
    price: u256,  // Price in the contract's native token
    enabled: bool,  // Flag to indicate if the song is available for purchase
}

// Define the Artist struct to hold artist-related information
#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct Artist {
    id: u256,  // Unique identifier for the artist
    name: felt252,  // Name of the artist
    verified: bool,  // Flag to indicate if the artist is verified
    wallet_address: ContractAddress,  // Wallet address for royalty payments
    registration_date: u64,  // Unix timestamp for registration date
}

// Define the User struct to hold user-related information
#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct User {
    address: ContractAddress,  // User's wallet address
    registration_date: u64,  // Unix timestamp for registration date
    subscription_tier: u8,  // Subscription tier level (0 = none, 1 = basic, 2 = premium, etc.)
    active: bool,  // Flag to indicate if the user account is active
}
