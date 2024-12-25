import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Hash "mo:base/Hash";

import Types "types";

shared (install) actor class NFTicket() = this {
    // Types
    type TokenId = Types.TokenId;
    type NFT = Types.NFT;
    type NFTType = Types.NFTType;
    type Metadata = Types.Metadata;
    type AttributeTrait = Types.AttributeTrait;

    private func customNatHash(n : Nat) : Hash.Hash {
        Text.hash(Nat.toText(n));
    };
    private stable var nextTokenId : TokenId = 0;
    private stable var nftEntries : [(TokenId, NFT)] = [];
    private var whitelist = HashMap.HashMap<Principal, Bool>(1, Principal.equal, Principal.hash);
    private stable var whitelistEntries : [(Principal, Bool)] = [];

    private var nfts = HashMap.HashMap<TokenId, NFT>(1, Nat.equal, customNatHash);

    // Upgrade and downgrade
    system func preupgrade() {
        nftEntries := Iter.toArray(nfts.entries());
        whitelistEntries := Iter.toArray(whitelist.entries());
    };

    system func postupgrade() {
        nfts := HashMap.fromIter<TokenId, NFT>(
            nftEntries.vals(),
            1,
            Nat.equal,
            customNatHash,
        );
        whitelist := HashMap.fromIter<Principal, Bool>(whitelistEntries.vals(), 1, Principal.equal, Principal.hash);
        nftEntries := [];
        whitelistEntries := [];
    };

    public query func name() : async Text {
        "ICEvent NFTicket";
    };

    public query func symbol() : async Text {
        "ICEFT";
    };
    
    public query func supply() : async Nat {
        nextTokenId;
    };

    public shared (msg) func addToWhitelist(user : Principal) : async Bool {
        assert (msg.caller == install.caller);
        whitelist.put(user, true);
        true;
    };

    public query func isWhitelisted(user : Principal) : async Bool {
        switch (whitelist.get(user)) {
            case (?status) { status };
            case null { false };
        };
    };

    
    // Mint new ticket NFT
    public shared (msg) func mintTicket(metadata : Metadata) : async TokenId {
        let isAllowed = switch (whitelist.get(msg.caller)) {
            case (?status) { status };
            case null { false };
        };

        assert (isAllowed);

        let token : NFT = {
            owner = msg.caller;
            nftType = #ticket;
            metadata = metadata;
        };

        let tokenId = nextTokenId;
        nfts.put(tokenId, token);
        nextTokenId += 1;
        tokenId;
    };

    // Convert ticket to attendance NFT during check-in
    public shared (msg) func convertToAttendance(tokenId : TokenId) : async Bool {
        switch (nfts.get(tokenId)) {
            case (null) { return false };
            case (?token) {
                if (token.owner != msg.caller) { return false };
                if (token.nftType != #ticket) { return false };

                let attendanceNFT : NFT = {
                    owner = token.owner;
                    nftType = #attendance;
                    metadata = token.metadata;
                };

                nfts.put(tokenId, attendanceNFT);
                return true;
            };
        };
    };

    // Get NFT details
    public query func getNFT(tokenId : TokenId) : async ?NFT {
        nfts.get(tokenId);
    };

    // Get user's NFTs
    public query func getUserNFTs(user : Principal) : async [(TokenId, NFT)] {
        let userNFTs = Array.filter<(TokenId, NFT)>(
            Iter.toArray(nfts.entries()),
            func(item) { item.1.owner == user },
        );
        userNFTs;
    };

    // Transfer ticket NFT (only if it's not converted to attendance)
    public shared (msg) func transfer(to : Principal, tokenId : TokenId) : async Bool {
        switch (nfts.get(tokenId)) {
            case (null) { return false };
            case (?token) {
                if (token.owner != msg.caller) { return false };
                if (token.nftType != #ticket) { return false };

                let updatedNFT : NFT = {
                    owner = to;
                    nftType = token.nftType;
                    metadata = token.metadata;
                };

                nfts.put(tokenId, updatedNFT);
                return true;
            };
        };
    };
};
