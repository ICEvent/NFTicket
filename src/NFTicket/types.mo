module {
    public type TokenId = Nat;
    public type NFTType = {
        #ticket;
        #attendance;
    };

    public type Metadata = {
        eventId : Text;
        eventDate : Int; // timestamp
        eventName : Text;
        eventLocation : Text;
        image : Text; // url of the image
        attributes : [AttributeTrait];
    };

    public type AttributeTrait = {
        trait_type : Text;
        value : Text;
    };

    public type NFT = {
        owner : Principal;
        nftType : NFTType;
        metadata : Metadata;
    };
};
