import Foundation

// MARK: - WhatsNew

/// A WhatsNew object
public struct WhatsNew {
    
    // MARK: Properties
    
    /// The Version
    public var version: Version
    
    /// The Title
    public var title: Title
    
    /// The Features
    public var features: [Feature]
    
    /// The PrimaryAction
    public var primaryAction: PrimaryAction
    
    /// The optional SecondaryAction
    public var secondaryAction: SecondaryAction?
    
    /// The code block that is run when migrating to that version
    public var migration: (() async -> Void)?
    
    // MARK: Initializer
    
    /// Creates a new instance of `WhatsNew`
    /// - Parameters:
    ///   - version: The Version. Default value `.current()`
    ///   - title: The Title
    ///   - features: The Features
    ///   - primaryAction: The PrimaryAction. Default value `.init()`
    ///   - secondaryAction: The optional SecondaryAction. Default value `nil`
    ///   - migration: The code block that is run when migrating to that version
    public init(
        version: Version = .current(),
        title: Title,
        features: [Feature],
        primaryAction: PrimaryAction = .init(),
        secondaryAction: SecondaryAction? = nil,
        migration: (() async -> Void)? = nil
    ) {
        self.version = version
        self.title = title
        self.features = features
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.migration = migration
    }
    
}

// MARK: - Identifiable

extension WhatsNew: Identifiable {
    
    /// The stable identity of the entity associated with this instance.
    public var id: Version {
        self.version
    }
    
}
