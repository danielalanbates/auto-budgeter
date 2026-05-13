import SwiftUI
import UniformTypeIdentifiers
import AppKit

// MARK: - Color Theme

extension Color {
    static let appPrimary = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 1) // Lighter blue for dark mode
        } else {
            return NSColor(red: 0.12, green: 0.16, blue: 0.24, alpha: 1)
        }
    })
    
    static let appSecondary = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(red: 0.4, green: 0.8, blue: 0.6, alpha: 1)
        } else {
            return NSColor(red: 0.28, green: 0.68, blue: 0.48, alpha: 1)
        }
    })
    
    static let appAccent = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(red: 0.5, green: 0.85, blue: 1.0, alpha: 1)
        } else {
            return NSColor(red: 0.38, green: 0.76, blue: 0.92, alpha: 1)
        }
    })
    
    static let appHighlight = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(red: 1.0, green: 0.8, blue: 0.5, alpha: 1)
        } else {
            return NSColor(red: 0.96, green: 0.72, blue: 0.36, alpha: 1)
        }
    })
    
    static let appBackground = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor.windowBackgroundColor
        } else {
            return NSColor(red: 0.99, green: 0.97, blue: 0.95, alpha: 1)
        }
    })
    
    static let appCardBackground = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor.controlBackgroundColor
        } else {
            return NSColor(red: 0.97, green: 0.93, blue: 0.90, alpha: 1)
        }
    })
    
    static let appSidebar = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor.windowBackgroundColor
        } else {
            return NSColor(red: 0.93, green: 0.88, blue: 0.84, alpha: 1)
        }
    })
}

// MARK: - Menu Bar

private struct MenuBarContentView: View {
    @ObservedObject var dataStore: BudgetDataStore
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                openWindow(id: "main")
                NSApplication.shared.activate(ignoringOtherApps: true)
            } label: {
                Label("Open BudgetAutopilot", systemImage: "rectangle.on.rectangle")
            }
            
            Divider()
            
            Button {
                NotificationCenter.default.post(name: .addTransaction, object: nil)
                openWindow(id: "main")
                NSApplication.shared.activate(ignoringOtherApps: true)
            } label: {
                Label("Add Transaction…", systemImage: "plus.circle")
            }
            
            Button {
                NotificationCenter.default.post(name: .importFile, object: "csv")
                openWindow(id: "main")
                NSApplication.shared.activate(ignoringOtherApps: true)
            } label: {
                Label("Import CSV…", systemImage: "arrow.down.doc")
            }
            
            Divider()
            
            Button(role: .destructive) {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit BudgetAutopilot", systemImage: "power")
            }
            
            NavigationLink(value: SidebarItem.budgetPlanner) {
                HStack {
                    Text("Budget Autopilot")
                    Spacer()
                    Image(systemName: "sparkles")
                        .foregroundColor(.appSecondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 220, alignment: .leading)
    }
}

private struct StatusBarIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.primary.opacity(0.65), lineWidth: 1.2)
                .frame(width: 18, height: 18)
            
            VStack(spacing: 2) {
                Capsule()
                    .fill(Color.primary.opacity(0.9))
                    .frame(width: 5, height: 6)
                Capsule()
                    .fill(Color.primary.opacity(0.9))
                    .frame(width: 5, height: 9)
                Capsule()
                    .fill(Color.primary.opacity(0.9))
                    .frame(width: 5, height: 12)
            }
            .offset(x: -4)
            
            VStack(spacing: 2) {
                Capsule()
                    .fill(Color.primary.opacity(0.55))
                    .frame(width: 5, height: 4)
                Capsule()
                    .fill(Color.primary.opacity(0.55))
                    .frame(width: 5, height: 6)
                Capsule()
                    .fill(Color.primary.opacity(0.55))
                    .frame(width: 5, height: 10)
            }
            .offset(x: 4)
        }
        .padding(2)
    }
}

private struct SplashView: View {
    @Binding var showSplash: Bool
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 18) {
                Text("BudgetAutopilot")
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)
                Text("Launching your budget in seconds…")
                    .foregroundColor(.secondary)
                
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding(.top, 8)
                
                if let logo = BudgetTrackerApp.loadLogo() {
                    Image(nsImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 8, y: 4)
                        .padding(24)
                }
                
                Button("Skip") {
                    showSplash = false
                }
                .buttonStyle(.bordered)
                .padding(.top, 6)
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showSplash = false
            }
        }
    }
}

// MARK: - Main App

enum SidebarItem: String, CaseIterable, Hashable {
    case dashboard
    case transactions
    case budgetPlanner
    case settings
}

@main
struct BudgetTrackerApp: App {
    @StateObject private var dataStore = BudgetDataStore()
    
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Preload assets and update icon with a small delay to ensure macOS Dock is ready
        _ = BudgetTrackerApp.loadLogo()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            BudgetTrackerApp.updateAppIcon()
        }
    }
    
    static func updateAppIcon() {
        // For the dock icon, prioritize image.jpg (square high-res girl logo) 
        // falling back to image.png (the wide girl logo).
        let bundle = Bundle.module
        var dockLogo: NSImage?
        
        if let url = bundle.url(forResource: "image", withExtension: "jpg"),
           let img = NSImage(contentsOf: url) {
            dockLogo = img
        } else if let url = bundle.url(forResource: "image", withExtension: "png"),
                  let img = NSImage(contentsOf: url) {
            dockLogo = img
        } else {
            dockLogo = loadLogo()
        }
        
        guard let logo = dockLogo else { 
            print("Failed to load logo for dock icon")
            return 
        }
        
        // Create a 1024x1024 square canvas for the dock icon
        let canvasSize: CGFloat = 1024
        let dockIcon = NSImage(size: NSSize(width: canvasSize, height: canvasSize), flipped: false) { rect in
            let srcSize = logo.representations.first.map { NSSize(width: $0.pixelsWide, height: $0.pixelsHigh) } ?? logo.size
            let ratio = srcSize.width / max(1, srcSize.height)
            
            // Calculate scale to fit the logo within the square canvas while preserving aspect ratio
            var dW = rect.width
            var dH = rect.height
            
            if ratio > 1 {
                // Wide logo (like image.png)
                dH = rect.width / ratio
            } else {
                // Tall or square logo (like image.jpg)
                dW = rect.height * ratio
            }
            
            // Center it in the canvas
            let lx = (rect.width - dW) / 2
            let ly = (rect.height - dH) / 2
            
            logo.draw(in: NSRect(x: lx, y: ly, width: dW, height: dH),
                      from: NSRect(origin: .zero, size: logo.size),
                      operation: .sourceOver,
                      fraction: 1.0)
            
            return true
        }
        
        // 1. Update global app icon
        NSApp.applicationIconImage = dockIcon
        
        // 2. Force refresh the dock tile using a custom view for maximum reliability
        let dockImageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 512, height: 512))
        dockImageView.image = dockIcon
        dockImageView.imageScaling = .scaleProportionallyUpOrDown
        
        NSApp.dockTile.contentView = dockImageView
        NSApp.dockTile.display()
        
        print("Dock icon synced with girl logo: \(logo.size) -> \(dockIcon.size)")
    }
    
    var body: some Scene {
        WindowGroup("BudgetAutopilot", id: "main") {
            MainContentView()
                .environmentObject(dataStore)
        }
        .defaultSize(width: 1100, height: 750)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Transaction") {
                    NotificationCenter.default.post(name: .addTransaction, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .newItem) {
                Divider()
                
                Button("Import CSV...") {
                    NotificationCenter.default.post(name: .importFile, object: "csv")
                }
                .keyboardShortcut("i", modifiers: .command)
                
                Button("Import PDF...") {
                    NotificationCenter.default.post(name: .importFile, object: "pdf")
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                
                Button("Import Spreadsheet...") {
                    NotificationCenter.default.post(name: .importFile, object: "xlsx")
                }
            }
            
            CommandGroup(replacing: .sidebar) {
                Button("Show Dashboard") {
                    NotificationCenter.default.post(name: .showTab, object: 0)
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Show Transactions") {
                    NotificationCenter.default.post(name: .showTab, object: 1)
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Show Budget Planner") {
                    NotificationCenter.default.post(name: .showTab, object: 2)
                }
                .keyboardShortcut("3", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView(dataStore: dataStore)
        }
    }
}

extension BudgetTrackerApp {
    private static func createAppIcon() -> NSImage {
        let size = NSSize(width: 256, height: 256)
        let image = NSImage(size: size)
        image.lockFocus()
        
        let rect = NSRect(origin: .zero, size: size)
        let corner: CGFloat = 36
        let bg = NSBezierPath(roundedRect: rect.insetBy(dx: 8, dy: 8), xRadius: corner, yRadius: corner)
        NSColor(calibratedRed: 0.12, green: 0.16, blue: 0.24, alpha: 1).setFill()
        bg.fill()
        
        // Bars
        func drawBar(x: CGFloat, height: CGFloat, color: NSColor) {
            let barWidth: CGFloat = 38
            let barRect = NSRect(x: x, y: 32, width: barWidth, height: height)
            let path = NSBezierPath(roundedRect: barRect, xRadius: 10, yRadius: 10)
            color.setFill()
            path.fill()
        }
        
        drawBar(x: 48, height: 110, color: NSColor(calibratedRed: 0.38, green: 0.76, blue: 0.92, alpha: 1))
        drawBar(x: 110, height: 160, color: NSColor(calibratedRed: 0.28, green: 0.68, blue: 0.48, alpha: 1))
        drawBar(x: 172, height: 200, color: NSColor(calibratedRed: 0.96, green: 0.72, blue: 0.36, alpha: 1))
        
        // Outline
        NSColor(calibratedWhite: 1, alpha: 0.08).setStroke()
        bg.lineWidth = 6
        bg.stroke()
        
        image.unlockFocus()
        return image
    }
    
    private static var _cachedLogo: NSImage?
    private static var _isLogoLoading = false
    
    static func loadLogo() -> NSImage? {
        if let cached = _cachedLogo { return cached }
        
        guard !_isLogoLoading else { return nil }
        
        _isLogoLoading = true
        defer { _isLogoLoading = false }
        
        let bundle = Bundle.module
        // Prioritize image.png which the user confirmed is the correct girl logo
        let resources = ["image.png", "image.jpg", "budget_tracker_icon.png"]
        
        for res in resources {
            let name = (res as NSString).deletingPathExtension
            let ext = (res as NSString).pathExtension
            if let url = bundle.url(forResource: name, withExtension: ext),
               let img = NSImage(contentsOf: url) {
                
                // Set reasonable point size for SwiftUI layout while keeping high-res data
                let ratio = img.size.width / max(1, img.size.height)
                if ratio > 1.2 {
                    img.size = NSSize(width: 150, height: 100)
                } else {
                    img.size = NSSize(width: 100, height: 100)
                }
                
                _cachedLogo = img
                return img
            }
        }
        return nil
    }
    
    static func preloadAssets() {
        DispatchQueue.global(qos: .userInteractive).async {
            _ = loadLogo()
        }
    }
    
    static func getTrueAspectRatio(of image: NSImage) -> CGFloat {
        if let rep = image.representations.first {
            let pW = CGFloat(rep.pixelsWide)
            let pH = CGFloat(rep.pixelsHigh)
            if pW > 0 && pH > 0 {
                return pW / pH
            }
        }
        return image.size.width / max(1, image.size.height)
    }
    
    private static var _cachedMenuBarIcon: NSImage?
    static func createSquareMenuBarIcon() -> NSImage? {
        if let cached = _cachedMenuBarIcon { return cached }
        guard let logo = loadLogo() else { return nil }
        
        let canvasSide: CGFloat = 22
        let targetSize = NSSize(width: canvasSide, height: canvasSide)
        let icon = NSImage(size: targetSize)
        
        icon.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        
        let logoRatio: CGFloat = 1.5 // Enforce consistency
        let maxDim = canvasSide * 0.9
        
        let drawWidth = maxDim
        let drawHeight = maxDim / logoRatio
        
        let x = (canvasSide - drawWidth) / 2
        let y = (canvasSide - drawHeight) / 2
        
        logo.draw(in: NSRect(x: x, y: y, width: drawWidth, height: drawHeight),
                  from: NSRect(origin: .zero, size: logo.size),
                  operation: .sourceOver,
                  fraction: 1.0)
        
        icon.unlockFocus()
        icon.isTemplate = false
        _cachedMenuBarIcon = icon
        return icon
    }
}
// MARK: - Notifications

extension Notification.Name {
    static let addTransaction = Notification.Name("addTransaction")
    static let importFile = Notification.Name("importFile")
    static let showTab = Notification.Name("showTab")
}

// MARK: - Main Content View

struct MainContentView: View {
    @EnvironmentObject var dataStore: BudgetDataStore
    @State private var selectedTab = 0
    @State private var showingImporter = false
    @State private var importFileType: String = "csv"
    @State private var showingAddTransaction = false
    @State private var importedTransactions: [Transaction] = []
    @State private var showingImportPreview = false
    @State private var isParsingImport = false
    @State private var showSplash = true
    
    var body: some View {
        NavigationSplitView {
            // Sidebar Column
            List(selection: $selectedTab) {
                Section("Overview") {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                        .tag(0)
                    Label("Transactions", systemImage: "list.bullet.rectangle.fill")
                        .tag(1)
                    Label("Budget Planner", systemImage: "target")
                        .tag(2)
                    Label("Settings", systemImage: "gearshape.fill")
                        .tag(3)
                }
                
                Section("Quick Actions") {
                    Button(action: { showingAddTransaction = true }) {
                        Label("Add Transaction", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { importFileType = "csv"; showingImporter = true }) {
                        Label("Import File", systemImage: "doc.badge.plus")
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Color.appSidebar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Sidebar Logo Footer - pinned to bottom left
                VStack(alignment: .leading, spacing: 6) {
                    if let logo = BudgetTrackerApp.loadLogo() {
                        ZStack {
                            Color.clear
                                .frame(width: 54, height: 36)
                            Image(nsImage: logo)
                                .renderingMode(.original)
                                .resizable()
                                .aspectRatio(1.5, contentMode: .fit)
                        }
                        .frame(height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Text("BudgetAutopilot")
                        .font(.headline)
                        .foregroundColor(.appPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Color.appSidebar
                        .shadow(.drop(color: Color(nsColor: .shadowColor).opacity(0.2), radius: 5, y: -5))
                )
            }
            .frame(minWidth: 220)
        } detail: {
            // Main content
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                switch selectedTab {
                case 0:
                    DashboardView(dataStore: dataStore)
                case 1:
                    TransactionsView(dataStore: dataStore)
                case 2:
                    BudgetPlannerView(dataStore: dataStore)
                case 3:
                    SettingsView(dataStore: dataStore)
                default:
                    DashboardView(dataStore: dataStore)
                }
            }
            .overlay {
                if isParsingImport {
                    ZStack {
                        Color.black.opacity(0.35).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView("Importing...")
                                .progressViewStyle(.circular)
                            Text("Parsing file, please wait")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                    }
                }
            }
        }
        .navigationTitle(tabTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddTransaction = true }) {
                    Label("Add", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Import CSV...") { importFileType = "csv"; showingImporter = true }
                    Button("Import PDF...") { importFileType = "pdf"; showingImporter = true }
                    Button("Import Excel...") { importFileType = "xlsx"; showingImporter = true }
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showingAddTransaction) {
            TransactionEditorView(dataStore: dataStore, transaction: nil)
        }
        .sheet(isPresented: $showingImportPreview) {
            ImportPreviewView(transactions: $importedTransactions, dataStore: dataStore)
        }
        .sheet(isPresented: $showSplash) {
            SplashView(showSplash: $showSplash)
                .frame(minWidth: 500, minHeight: 420)
        }
        .onReceive(NotificationCenter.default.publisher(for: .addTransaction)) { _ in
            showingAddTransaction = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .importFile)) { notification in
            if let type = notification.object as? String {
                importFileType = type
                showingImporter = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showTab)) { notification in
            if let tab = notification.object as? Int {
                selectedTab = tab
            }
        }
        .onAppear {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    
    private var tabTitle: String {
        switch selectedTab {
        case 0: return "" // Hide navigation title for Dashboard to avoid duplicates
        case 1: return "Transactions"
        case 2: return "Budget Planner"
        default: return "Budget Tracker"
        }
    }
    
    private var allowedTypes: [UTType] {
        [.commaSeparatedText, .pdf, .spreadsheet, .plainText]
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            isParsingImport = true
            Task {
                do {
                    importedTransactions = try await FileImportManager.parseAsync(url: url)
                    if !importedTransactions.isEmpty {
                        showingImportPreview = true
                    }
                } catch {
                    print("Import error: \(error)")
                }
                isParsingImport = false
            }
            
        case .failure(let error):
            print("File selection error: \(error)")
        }
    }
}

// MARK: - Import Preview

struct ImportPreviewView: View {
    @Binding var transactions: [Transaction]
    @ObservedObject var dataStore: BudgetDataStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📥 Import Preview")
                    .font(.title2.bold())
                Spacer()
                Text("\(transactions.count) transactions found")
                    .foregroundColor(.secondary)
            }
            
            List {
                ForEach(transactions) { transaction in
                    HStack {
                        Image(systemName: transaction.category.icon)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading) {
                            Text(transaction.description)
                                .lineLimit(1)
                            Text(transaction.category.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(transaction.isIncome ? "+$\(transaction.amount, specifier: "%.2f")" : "$\(transaction.amount, specifier: "%.2f")")
                            .foregroundColor(transaction.isIncome ? .green : .primary)
                    }
                }
            }
            .frame(height: 300)
            
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Import All") {
                    dataStore.importTransactions(transactions)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .background(Color.appBackground)
        .frame(width: 600, height: 450)
    }
}
