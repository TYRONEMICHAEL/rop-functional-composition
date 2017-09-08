// Result type

enum Result<T, Error: Swift.Error> {
    case success(T)
    case failure(Error)
    
    func map<U>(_ transform: (T) -> U) -> Result<U, Error> {
        return flatMap { .success(transform($0)) }
    }
    
    func flatMap<U>(_ transform: (T) -> Result<U, Error>) -> Result<U, Error> {
        switch self {
        case let .success(value): return transform(value)
        case let .failure(error): return .failure(error)
        }
    }
}



// Error type

enum EmojiError: Error {
    case 😩(String)
}

// Functional Result Helpers

func pure<A>(_ x: A) -> Result<A, EmojiError> {
    return .success(x)
}

precedencegroup LeftAssociativity {
     associativity: left
}

infix operator <*> : LeftAssociativity

func <*><A, B>(f: Result<(A) -> B, EmojiError>, x: Result<A, EmojiError>) -> Result<B, EmojiError> {
    switch (f, x) {
    case let (.success(f), _): return x.map(f)
    case let (.failure(e), .success): return .failure(e)
    case let (.failure(_), .failure(e2)): return .failure(e2)
    }
}

func <*><A, B>(f: Result<(A) -> B, EmojiError>, x: Result<A, EmojiError>) -> Result<(B, A), EmojiError> {
    switch (f, x) {
    case let (.success(r1), .success(r2)): return x.map { v in (r1(v), r2) }
    case let (.failure(e), .success): return .failure(e)
    case let (_, .failure(e)): return .failure(e)
    }
}

func <*><A, B, C>(f: Result<((B) -> C, A), EmojiError>, x:  Result<(A) -> Result<B, EmojiError>, EmojiError>) -> Result<(C, B), EmojiError> {
    switch (f, x) {
    case let (.success(r1), .success(r2)): return r2(r1.1).map { v in (r1.0(v), v) }
    case let (.failure(e), .success): return .failure(e)
    case let (_, .failure(e)): return .failure(e)
    }
}

func <*><A, B, C>(f: Result<((B) -> C, A), EmojiError>, x:  Result<(A) -> Result<B, EmojiError>, EmojiError>) -> Result<C, EmojiError> {
    switch (f, x) {
    case let (.success(r1), .success(r2)): return r2(r1.1).map { v in r1.0(v) }
    case let (.failure(e), .success): return .failure(e)
    case let (_, .failure(e)): return .failure(e)
    }
}


// Models

struct User {
    let id: String?
    let name: String
}

struct Tweet {
    let id: String?
    let message: String
    let userId: String
}

struct TweetSentiment {
    let id: String
    let isPositive: Bool
    let tweetId: String
}

// Data model

struct TweetDetails {
    private let user: User
    private let tweet: Tweet
    private let sentiment: TweetSentiment
    
    init(user: User, tweet: Tweet, sentiment: TweetSentiment) {
        self.user = user
        self.tweet = tweet
        self.sentiment = sentiment
    }
    
    var expressedMessage: String {
        let sentimentDescription = sentiment.isPositive ? "positive" : "negative"
        return "\(user.name) said \(tweet.message) which has a \(sentimentDescription) statement"
    }
}

let createTweetDetails = {
    user in {
        tweet in {
            sentiment in
            TweetDetails(
                user: user,
                tweet: tweet,
                sentiment: sentiment
            )
        }
    }
}

// Repository

class TwitterRepository {
    
    func getTweetDetails(for userId: String) -> Result<TweetDetails, EmojiError> {
        return pure(createTweetDetails)
            <*> getUser()
            <*> pure(getLatestTweet)
            <*> pure(getTweetSentiment)
    }
    
    func getUser() -> Result<User, EmojiError> {
        return .success(User(id: "234", name: "Tyrone"))
    }
    
    func getLatestTweet(for user: User?) -> Result<Tweet, EmojiError> {
        guard let userId = user?.id else { return .failure(.😩("User not found")) }
        return .success(Tweet(id: "123", message: "Wahoo", userId: userId))
    }
    
    func getTweetSentiment(for tweet: Tweet?) -> Result<TweetSentiment, EmojiError> {
        guard let tweetId = tweet?.id  else { return .failure(.😩("Tweet not found")) }
        return .success(TweetSentiment(id: "123", isPositive: true, tweetId: tweetId))
    }
    
}



// Usage

let repo = TwitterRepository()
let tweetDetailsResult = repo.getTweetDetails(for: "1234")

switch tweetDetailsResult {
case let .success(value): print(value.expressedMessage)
case let .failure(error):
    switch error {
    case let .😩(value): assertionFailure(value)
    }
}

