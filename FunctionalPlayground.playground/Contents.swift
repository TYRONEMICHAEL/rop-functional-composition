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

// Functional Result functions

func curry<A, B, C, D>(_ function: @escaping (A, B, C) -> D) -> (A) -> (B) -> (C) -> D {
    return { (a: A) -> (B) -> (C) -> D in { (b: B) -> (C) -> D in { (c: C) -> D in function(a, b, c) } } }
}

func applyResult<A, B>(of result: Result<A, EmojiError>, to action: (A) -> B) -> Result<(result: A, action: B), EmojiError> {
    return result.flatMap { value in
        .success((value, action(value)))
    }
}

func applyResult<A, B, C>(of fn: @escaping (C) -> Result<A, EmojiError>) -> (_ input: C, _ action: (A) -> B) -> Result<(result: A, action: B), EmojiError> {
    return { input, action in
        return fn(input).flatMap { value in
            .success((value, action(value)))
        }
    }
}

func applyResult<A, B, C>(of fn: @escaping (C) -> Result<A, EmojiError>) -> (_ input: C, _ action: (A) -> B) -> Result<B, EmojiError> {
    return { input, action in
        return fn(input).flatMap { value in
            .success(action(value))
        }
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

// Repository

class TwitterRepository {
    
    func getTweetDetails(for userId: String) -> Result<TweetDetails, EmojiError> {
        let tweetDetails = curry(TweetDetails.init)
        return applyResult(of: getUser(), to: tweetDetails)
            .flatMap(applyResult(of: getLatestTweet))
            .flatMap(applyResult(of: getTweetSentiment))
    }
    
    func getUser() -> Result<User, EmojiError> {
        return .success(User(id: "123", name: "Tyrone"))
    }
    
    func getLatestTweet(for user: User?) -> Result<Tweet, EmojiError> {
        guard let userId = user?.id else {
            return .failure(.😩("User not found"))
        }
        return .success(Tweet(id: "123", message: "Wahoo", userId: userId))
    }
    
    func getTweetSentiment(for tweet: Tweet?) -> Result<TweetSentiment, EmojiError> {
        guard let tweetId = tweet?.id  else {
            return .failure(.😩("Tweet not found"))
        }
        return .success(TweetSentiment(id: "123", isPositive: true, tweetId: tweetId))
    }
    
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

func createTweetDetails(user: User) -> (_ tweet: Tweet) -> (_ sentiment: TweetSentiment) -> TweetDetails {
    return { tweet in
        return { sentiment in
            return TweetDetails(user: user, tweet: tweet, sentiment: sentiment)
        }
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