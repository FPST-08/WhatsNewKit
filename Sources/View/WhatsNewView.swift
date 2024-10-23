import SwiftUI
import OSLog

// MARK: - WhatsNewView

/// A WhatsNewView
public struct WhatsNewView {
    
    // MARK: Properties
    
    /// The WhatsNew object
    private let whatsNew: WhatsNew
    
    /// The WhatsNewVersionStore
    private let whatsNewVersionStore: WhatsNewVersionStore?
    
    /// The WhatsNew Layout
    private let layout: WhatsNew.Layout
    
    @State private var migrationStatus: MigrationStatus = .notStarted
    
    @State private var remainingMigrationSteps = 0
    
    @State private var continueButtonPressed = false
    
    /// The View that is presented by the SecondaryAction
    @State
    private var secondaryActionPresentedView: WhatsNew.SecondaryAction.Action.PresentedView?
    
    /// The PresentationMode
    @Environment(\.presentationMode)
    private var presentationMode
    
    
    @Environment(\.whatsNew)
    private var whatsNewEnvironment
    
    /// The action to run when presented
    let action: (() -> Void)?
    
    // MARK: Initializer
    
    /// Creates a new instance of `WhatsNewView`
    /// - Parameters:
    ///   - whatsNew: The WhatsNew object
    ///   - versionStore: The optional WhatsNewVersionStore. Default value `nil`
    ///   - layout: The WhatsNew Layout. Default value `.default`
    ///   - action: The action to run when presented
    public init(
        whatsNew: WhatsNew,
        versionStore: WhatsNewVersionStore? = nil,
        layout: WhatsNew.Layout = .default,
        action: (() -> Void)? = nil
    ) {
        self.whatsNew = whatsNew
        self.whatsNewVersionStore = versionStore
        self.layout = layout
        self.action = action
    }
    
}

// MARK: - View

extension WhatsNewView: View {
    
    /// The content and behavior of the view.
    public var body: some View {
        ZStack {
            // Content ScrollView
            ScrollView(
                .vertical,
                showsIndicators: self.layout.showsScrollViewIndicators
            ) {
                // Content Stack
                VStack(
                    spacing: self.layout.contentSpacing
                ) {
                    // Title
                    self.title
                    // Feature List
                    VStack(
                        alignment: .leading,
                        spacing: self.layout.featureListSpacing
                    ) {
                        // Feature
                        ForEach(
                            self.whatsNew.features,
                            id: \.self,
                            content: self.feature
                        )
                    }
                    .modifier(FeaturesPadding())
                    .padding(self.layout.featureListPadding)
                }
                .padding(.horizontal)
                .padding(self.layout.contentPadding)
                // ScrollView bottom content inset
                Color.clear
                    .padding(
                        .bottom,
                        self.layout.scrollViewBottomContentInset
                    )
            }
            #if os(iOS)
            .alwaysBounceVertical(false)
            #endif
            // Footer
            VStack {
                Spacer()
                self.footer
                    .modifier(FooterPadding())
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .sheet(
            item: self.$secondaryActionPresentedView,
            content: { $0.view }
        )
        .onDisappear {
            // Save presented WhatsNew Version, if available
            self.whatsNewVersionStore?.save(
                presentedVersion: self.whatsNew.version
            )
        }
        .task {
            // Set migration status to running
            self.migrationStatus = .running
            
            if whatsNewEnvironment.whatsNewVersionStore.presentedVersions.isEmpty && whatsNewEnvironment.initialBehaviour == .custom {
                self.migrationStatus = .finished
                self.whatsNewVersionStore?.save(presentedVersion: .current())
                return
            }
            
            // Version store is required to check for versions
            guard let whatsNewVersionStore else {
                Logger(subsystem: Bundle.main.bundleIdentifier!, category: "WhatsNew").error("Version store not found")
                return
            }
            
            let versions = whatsNewEnvironment.whatsNewCollection
            
            // Iterate over all versions
            for version in versions {
                // If version has not been shown before
                if !whatsNewVersionStore.hasPresented(version) {
                    // If Migration was provided
                    if let migration = version.migration {
                        // Perform migration
                        await migration()
                    }
                }
            }
            
            self.migrationStatus = .finished
            // If button was previously pressed
            if continueButtonPressed {
                // Close the sheet
                self.presentationMode.wrappedValue.dismiss()
            }
            
        }
        // Disable swipe down while migration is running
        .interactiveDismissDisabled(migrationStatus != .finished)
    }
    
}

// MARK: - Title

private extension WhatsNewView {
    
    /// The Title View
    var title: some View {
        Text(
            whatsNewText: self.whatsNew.title.text
        )
        .font(.largeTitle.bold())
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
    
}

// MARK: - Feature

private extension WhatsNewView {
    
    /// The Feature View
    /// - Parameter feature: A WhatsNew Feature
    func feature(
        _ feature: WhatsNew.Feature
    ) -> some View {
        HStack(
            alignment: self.layout.featureHorizontalAlignment,
            spacing: self.layout.featureHorizontalSpacing
        ) {
            feature
                .image
                .view()
                .frame(width: self.layout.featureImageWidth)
            VStack(
                alignment: .leading,
                spacing: self.layout.featureVerticalSpacing
            ) {
                Text(
                    whatsNewText: feature.title
                )
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                Text(
                    whatsNewText: feature.subtitle
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.leading)
        }.accessibilityElement(children: .combine)
    }
    
}

// MARK: - Footer

private extension WhatsNewView {
    
    /// The Footer View
    var footer: some View {
        VStack(
            spacing: self.layout.footerActionSpacing
        ) {
            // Check if a secondary action is available
            if let secondaryAction = self.whatsNew.secondaryAction {
                // Secondary Action Button
                Button(
                    action: {
                        // Invoke HapticFeedback, if available
                        secondaryAction.hapticFeedback?()
                        // Switch on Action
                        switch secondaryAction.action {
                        case .present(let view):
                            // Set secondary action presented view
                            self.secondaryActionPresentedView = .init(view: view)
                        case .custom(let action):
                            // Invoke action with PresentationMode
                            action(self.presentationMode)
                        }
                    }
                ) {
                    Text(
                        whatsNewText: secondaryAction.title
                    )
                }
                #if os(macOS)
                .buttonStyle(
                    PlainButtonStyle()
                )
                #endif
                .foregroundColor(secondaryAction.foregroundColor)
            }
            // Primary Action Button
            Button(
                action: {
                    if let action {
                        action()
                    }
                    self.continueButtonPressed = true
                    if migrationStatus == .finished {
                        // Invoke HapticFeedback, if available
                        self.whatsNew.primaryAction.hapticFeedback?()
                        // Dismiss
                        self.presentationMode.wrappedValue.dismiss()
                        // Invoke on dismiss, if available
                        self.whatsNew.primaryAction.onDismiss?()
                    }
                    
                    
                }
            ) {
                if continueButtonPressed {
                    // Show progressview if migration is running and button was pressed
                    ProgressView()
                } else {
                    Text(
                        whatsNewText: self.whatsNew.primaryAction.title
                    )
                }
            }
            .buttonStyle(
                PrimaryButtonStyle(
                    primaryAction: self.whatsNew.primaryAction,
                    layout: self.layout,
                    loading: migrationStatus == .running && continueButtonPressed // Visually indicate running migration after button press
                )
            )
            .disabled(continueButtonPressed)
            #if os(macOS)
            .keyboardShortcut(.defaultAction)
            #endif
        }
    }
    
}


enum MigrationStatus {
    case running, finished, notStarted
}
