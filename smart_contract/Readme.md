# CAIROFY

Cairofy is a platform for music stores where artists publish their songs for consumers to stream or purchase. consumers can only listen to the songs on the platform by subscribing, which requires paying the platform a specific amount of stark tokens in order to utilize the network.

# Work flow

### Personals

**The Artist**
1. Artists register on the platform, which in turn adds their song and other personal information.
2. Rewards are given based on how many people listen to the artist's music.
3. Artists also have the option to sell their songs through the platform.

**The Contract**
1. It should be able to send NFT to artists that integrate ipfs, allowing them to store their song and take ownership of it.
2. Artists (as owners) should be able to list their songs for sale on the platform, thereby relinquishing ownership once the song is purchased.
3. The contract should also enable users to purchase songs—transferring the NFT to the buyer—if the artist has listed the song for sale.

**The User**
1. They should be able to listen to songs on the platform after subscribing.
2. Users should be able to purchase songs if they are listed for sale.
3. As new owners of a song, users should have the ability to list their purchased songs for sale.

### Key Functionality of the Contract
The contract should enable users to **"stream"** music on the platform, pay a **"subscription"** fee to gain access to the songs, and **"purchase ownership"** of a song if it is listed for sale.

**Subscription**
1. Listeners(users) pay a fee to be able to access the platfrom.
2. The subscription fee is then transferred to the contract owner as compensation for using the platform.
3. The subscription is valid for a specific duration, after which it expires and requires the user to renew it in order to regain access to the platform and its features.

**Streaming**

* Users should be able to stream any song on the platform after paying the subscription fee.
* The more listeners (users) stream an artist's song, the greater the artist's compensation.
For example, there will be a function to increase the stream count based on the number of listeners. The equation for calculating the artist's incentive will be:
Incentive Reward = Count / Guess Value. This formula determines how the artist is compensated based on the number of streams.

**Buying and sell of songs**
- Artists (owners) should be able to list their songs for sale. 
- Listeners (users) should be able to purchase songs if they are available for sale. 
- Users who purchase an artist’s song will start receiving incentives from that song on the platform, and the listener count for that song will reset to zero after the purchase.

# Cairofy Contract Structure

**Core Structs**

struct Song {
    id: felt252,
    title: felt252,
    artist_id: felt252,
    ipfs_hash: felt252,
    price: u256,  // Price if listed for sale (0 if not for sale)
    stream_count: u64,
    is_for_sale: bool,
    owner: ContractAddress
}

struct Artist {
    id: felt252,
    name: felt252,
    total_streams: u64,
    pending_rewards: u256,
    song_count: u64
}

struct User {
    address: ContractAddress,
    subscription_expiry: u64,  // Timestamp when subscription expires
    is_subscribed: bool
}

**Storage Variables**

// Mappings
songs: LegacyMap<felt252, Song>,
song_ids: Array<felt252>,
artists: LegacyMap<felt252, Artist>,
users: LegacyMap<ContractAddress, User>,
artist_songs: LegacyMap<(felt252, u64), felt252>,  // Maps artist_id and index to song_id

// Contract configuration
subscription_fee: u256,
subscription_duration: u64,  // Duration in seconds
platform_owner: ContractAddress,
incentive_guess_value: u64,  // Divisor for incentive calculation

# Function Signatures

**Song Management**

#[external]
fn register_song(title: felt252, ipfs_hash: felt252) -> felt252

#[external]
fn list_song_for_sale(song_id: felt252, price: u256)

#[external]
fn cancel_listing(song_id: felt252)

#[external]
fn get_song(song_id: felt252) -> Song

#[view]
fn get_all_songs() -> Array<Song>

#[view]
fn get_artist_songs(artist_id: felt252) -> Array<Song>

**Artist Management**

#[external]
fn register_artist(name: felt252) -> felt252

#[external]
fn claim_rewards()

#[view]
fn get_artist(artist_id: felt252) -> Artist

#[view]
fn get_pending_rewards(artist_id: felt252) -> u256

**User Subscription**

#[external]
fn subscribe() 

#[view]
fn is_subscribed(user: ContractAddress) -> bool

#[view]
fn get_subscription_details(user: ContractAddress) -> User

**Streaming**

#[external]
fn stream_song(song_id: felt252)

#[internal]
fn calculate_incentive(stream_count: u64) -> u256

#[view]
fn get_song_stream_count(song_id: felt252) -> u64

**Marketplace**

#[external]
fn buy_song(song_id: felt252)

#[view]
fn get_songs_for_sale() -> Array<Song>

**Admin Functions**

#[external]
fn set_subscription_fee(new_fee: u256)

#[external]
fn set_subscription_duration(new_duration: u64)

#[external]
fn set_incentive_guess_value(new_value: u64)

#[external]
fn withdraw_platform_fees()

**Events**

#[event]
fn SongRegistered(song_id: felt252, artist_id: felt252, title: felt252)

#[event]
fn SongListed(song_id: felt252, price: u256)

#[event]
fn SongUnlisted(song_id: felt252)

#[event]
fn SongPurchased(song_id: felt252, buyer: ContractAddress, price: u256)

#[event]
fn ArtistRegistered(artist_id: felt252, name: felt252)

#[event]
fn RewardsClaimed(artist_id: felt252, amount: u256)

#[event]
fn UserSubscribed(user: ContractAddress, expiry: u64)

#[event]
fn SongStreamed(song_id: felt252, user: ContractAddress)

