import Iter "mo:base/Iter";
import List "mo:base/List";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

actor {
    // public type Message = Text;
    public type Message = {
        text: Text;
        time: Time.Time;
    };

    public type Microblog = actor {
        follow : shared (Principal) -> async ();
        follows : shared query () -> async [Principal];
        post : shared (Text) -> async ();
        posts : shared query () -> async [Message];
        timeline : shared () -> async [Message];
    };

    stable var followed : List.List<Principal> = List.nil();
    stable var messages : List.List<Message> = List.nil();

    public shared func follow(id : Principal) : async () {
        followed := List.push(id, followed);
    };

    public shared query func follows() : async [Principal] {
        return List.toArray(followed);
    };

    public shared func post(text: Text) : async () {
        let payload : Message = {
            text = text;
            time = Time.now();
        };
        messages := List.push(payload, messages);
    };

    public shared query func posts(since : Time.Time) : async [Message] {
        var payload : List.List<Message> = List.nil();

        for (msg in Iter.fromList(messages)) {
            if (msg.time >= since) {
                payload := List.push(msg, payload);
            };
        };

        return List.toArray(payload);
    };

    public shared func timeline(since : Time.Time) : async [Message] {
        var all : List.List<Message> = List.nil();

        for (id in Iter.fromList(followed)) {
            let canister : Microblog = actor(Principal.toText(id));
            let msgs = await canister.posts();

            for (msg in Iter.fromArray(msgs)) {
                if (msg.time >= since) {
                    all := List.push(msg, all);
                };
            };
        };

        return List.toArray(all);
    };

};