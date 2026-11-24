import Foundation
import Security
import CommonCrypto

enum AuthError: LocalizedError {
    case emptyName, invalidEmail, weakPassword, mismatch, wrongCredentials, wrongCurrentPassword, noAccount, keychain

    var errorDescription: String? {
        switch self {
        case .emptyName: return "Please enter your name."
        case .invalidEmail: return "Please enter a valid email address."
        case .weakPassword: return "Your password must be at least 8 characters."
        case .mismatch: return "The passwords don't match."
        case .wrongCredentials: return "Incorrect email or password."
        case .wrongCurrentPassword: return "Your current password is incorrect."
        case .noAccount: return "There is no account on this device yet."
        case .keychain: return "Couldn't save your account securely. Please try again."
        }
    }
}

/// Local-only account. The password is never stored: only a salted PBKDF2 hash, kept in the Keychain.
final class AuthStore: ObservableObject {

    private struct Record: Codable {
        var email: String
        var salt: Data
        var hash: Data
    }

    @Published private(set) var isLoggedIn: Bool
    @Published private(set) var hasAccount: Bool

    private let loggedInKey = "auth.loggedIn"
    private var record: Record?

    init() {
        record = Keychain.load()
        hasAccount = record != nil
        isLoggedIn = record != nil && UserDefaults.standard.bool(forKey: loggedInKey)
    }

    var email: String { record?.email ?? "" }

    // MARK: - Actions

    func signUp(name: String, email: String, password: String, confirm: String) throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { throw AuthError.emptyName }
        let cleanEmail = try Self.validated(email)
        guard password.count >= 8 else { throw AuthError.weakPassword }
        guard password == confirm else { throw AuthError.mismatch }

        let salt = Self.randomSalt()
        let new = Record(email: cleanEmail, salt: salt, hash: Self.hash(password, salt: salt))
        guard Keychain.save(new) else { throw AuthError.keychain }
        record = new
        hasAccount = true
        setLoggedIn(true)
    }

    func logIn(email: String, password: String) throws {
        guard let record else { throw AuthError.noAccount }
        let given = email.trimmingCharacters(in: .whitespaces).lowercased()
        let hashOK = Self.constantTimeEqual(Self.hash(password, salt: record.salt), record.hash)
        guard given == record.email, hashOK else { throw AuthError.wrongCredentials }
        setLoggedIn(true)
    }

    func logOut() { setLoggedIn(false) }

    func changePassword(current: String, new: String, confirm: String) throws {
        guard var record else { throw AuthError.noAccount }
        guard Self.constantTimeEqual(Self.hash(current, salt: record.salt), record.hash) else {
            throw AuthError.wrongCurrentPassword
        }
        guard new.count >= 8 else { throw AuthError.weakPassword }
        guard new == confirm else { throw AuthError.mismatch }
        record.salt = Self.randomSalt()
        record.hash = Self.hash(new, salt: record.salt)
        guard Keychain.save(record) else { throw AuthError.keychain }
        self.record = record
    }

    func updateEmail(_ email: String) throws {
        guard var record else { throw AuthError.noAccount }
        record.email = try Self.validated(email)
        guard Keychain.save(record) else { throw AuthError.keychain }
        self.record = record
        objectWillChange.send()
    }

    /// Removes the account (the caller erases the rest of the data).
    func deleteAccount() {
        Keychain.delete()
        record = nil
        hasAccount = false
        setLoggedIn(false)
    }

    // MARK: - Helpers

    private func setLoggedIn(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: loggedInKey)
        isLoggedIn = value
    }

    private static func validated(_ email: String) throws -> String {
        let clean = email.trimmingCharacters(in: .whitespaces).lowercased()
        let pattern = #"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$"#
        guard clean.range(of: pattern, options: .regularExpression) != nil else { throw AuthError.invalidEmail }
        return clean
    }

    private static func randomSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    private static func hash(_ password: String, salt: Data) -> Data {
        var out = [UInt8](repeating: 0, count: 32)
        let pw = Array(password.utf8)
        _ = salt.withUnsafeBytes { saltBytes in
            CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                pw.map { Int8(bitPattern: $0) }, pw.count,
                saltBytes.bindMemory(to: UInt8.self).baseAddress, salt.count,
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                100_000, &out, out.count
            )
        }
        return Data(out)
    }

    private static func constantTimeEqual(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        return zip(a, b).reduce(0) { $0 | ($1.0 ^ $1.1) } == 0
    }
}

private enum Keychain {
    private static let service = "com.habits.account"
    private static let account = "local-user"

    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    static func save(_ record: Codable & Any) -> Bool {
        guard let data = try? JSONEncoder().encode(AnyEncodable(record)) else { return false }
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
    }

    fileprivate static func load<T: Decodable>() -> T? {
        var q = query
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    static func delete() { SecItemDelete(query as CFDictionary) }
}

private struct AnyEncodable: Encodable {
    let value: Encodable
    init(_ value: Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}
