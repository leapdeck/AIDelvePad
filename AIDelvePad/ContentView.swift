//
//  ContentView.swift
//  StackUpAI
//
//  Created by modview on 3/14/25.
//

import SwiftUI

struct ContentItem: Identifiable, Codable, Hashable {
    let id: String // Changed to String for stable IDs
    let title: String
    let subject: String
    let platform: String
    let mins: Int
    let year: Int
    let views: Int
    let url: String?
    
    // Helper to ensure stable IDs based on title
    static func makeId(title: String) -> String {
        return title.replacingOccurrences(of: " ", with: "-").lowercased()
    }
    
    init(title: String, subject: String, platform: String, mins: Int, year: Int, views: Int = 0, url: String? = nil) {
        self.id = ContentItem.makeId(title: title) // Use stable ID based on title
        self.title = title
        self.subject = subject
        self.platform = platform
        self.mins = mins
        self.year = year
        self.views = views
        self.url = url
    }
    
    static func == (lhs: ContentItem, rhs: ContentItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ContentView: View {
    @State private var contentItems: [ContentItem] = []
    @State private var customItems: [ContentItem] = []
    @State private var favoriteIds = Set<String>()
    @State private var completedIds = Set<String>()
    @State private var selectedTab = 0
    
    // Add app-level timers to periodically save data
    @State private var saveTimer: Timer? = nil
    
    // Computed property to combine all content items
    var allContentItems: [ContentItem] {
        return contentItems + customItems
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // New Glossary Tab
            GlossaryView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Glossary")
                }
                .tag(0)
            
            // LLM Overview
            TechInfoView()
                .tabItem {
                    Image(systemName: "speedometer")
                    Text("LLM Process")
                }
                .tag(1)
            // Tutorial Add-ons Tab
            
            CustomCardsView(
                customItems: $customItems,
                favoriteIds: $favoriteIds,
                completedIds: $completedIds,
                onToggleFavorite: saveFavorite
            )
            .tabItem {
                Image(systemName: "square.stack.3d.down.right")
                Text("Tutorial Add-Ons")
            }
            .tag(2)
            
        // Favs Tab
            
            FavoritesView(
                contentItems: allContentItems,
                favoriteIds: $favoriteIds,
                completedIds: $completedIds,
                onToggleFavorite: saveFavorite,
                onToggleCompleted: saveCompleted
            )
            .tabItem {
                Image(systemName: "star.fill")
                Text("Favs")
            }
            .tag(3)
            
            
//            // A.I. Tutorials Tab
//            ResourcesListView(
//                contentItems: contentItems,
//                favoriteIds: $favoriteIds,
//                onToggleFavorite: saveFavorite
//            )
//            .tabItem {
//                Image(systemName: "slider.horizontal.below.rectangle")
//                Text("A.I. Tutorials")
//            }
//            .tag(3)
            
            // Dashboard Tab
            
            SettingsView(
                favoriteIds: favoriteIds,
                completedIds: completedIds,
                contentItems: allContentItems
            )
            .tabItem {
                Image(systemName: "chart.pie")
                Text("Dashboard")
            }
            .tag(4)
            

            

            

        }
        .onAppear {
            print("ContentView appeared - loading data")
            loadData()
            loadCustomCards()
            loadFavoritesSimple()
            loadCompletedSimple()
            
            // Setup timer for periodic saving
            saveTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
                saveAllData()
            }
            
            // Print current state
            print("Current favorites (\(favoriteIds.count)): \(Array(favoriteIds))")
        }
        .onDisappear {
            // Clean up timer
            saveTimer?.invalidate()
            saveTimer = nil
        }
        // Add scene phase monitoring for app lifecycle events
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive || newPhase == .background {
                print("App moving to background - saving data")
                saveAllData()
            }
        }
    }
    
    // Add scene phase property to track app lifecycle
    @Environment(\.scenePhase) var scenePhase
    
    // Very simple toggle and save function
    func saveFavorite(_ id: String) {
        // Toggle the state
        if favoriteIds.contains(id) {
            favoriteIds.remove(id)
        } else {
            favoriteIds.insert(id)
        }
        
        // Save directly to UserDefaults as a string array
        UserDefaults.standard.set(Array(favoriteIds), forKey: "favoriteItems")
        UserDefaults.standard.synchronize()
        
        print("Saved favorites: \(Array(favoriteIds))")
    }
    
    // Very simple toggle and save function for completed
    func saveCompleted(_ id: String) {
        // Toggle the state
        if completedIds.contains(id) {
            completedIds.remove(id)
        } else {
            completedIds.insert(id)
        }
        
        // Save directly to UserDefaults as a string array
        UserDefaults.standard.set(Array(completedIds), forKey: "completedItems")
        UserDefaults.standard.synchronize()
    }
    
    // Load favorites using the simple method
    func loadFavoritesSimple() {
        if let savedFavorites = UserDefaults.standard.stringArray(forKey: "favoriteItems") {
            favoriteIds = Set(savedFavorites)
            print("Loaded favorites: \(Array(favoriteIds))")
        } else {
            print("No saved favorites found")
        }
    }
    
    // Load completed items using the simple method
    func loadCompletedSimple() {
        if let savedCompleted = UserDefaults.standard.stringArray(forKey: "completedItems") {
            completedIds = Set(savedCompleted)
        }
    }
    
    // Save all data using multiple methods for redundancy
    func saveAllData() {
        // Method 1: Using JSONEncoder (original method)
        if let encoded = try? JSONEncoder().encode(Array(favoriteIds)) {
            UserDefaults.standard.set(encoded, forKey: "favoriteIds")
        }
        
        // Method 2: Direct array storage as backup
        UserDefaults.standard.set(Array(favoriteIds), forKey: "favoriteArray")
        
        // Method 3: Individual boolean flags as last resort
        for id in contentItems.map({ $0.id }) {
            UserDefaults.standard.set(favoriteIds.contains(id), forKey: "fav_\(id)")
        }
        
        // Method 4: Save as single string for extreme simplicity
        let favoriteString = favoriteIds.joined(separator: ",")
        UserDefaults.standard.set(favoriteString, forKey: "favoritesString")
        
        // Save completed IDs
        if let encoded = try? JSONEncoder().encode(Array(completedIds)) {
            UserDefaults.standard.set(encoded, forKey: "completedIds")
        }
        UserDefaults.standard.set(Array(completedIds), forKey: "completedArray")
        
        // Force synchronize
        UserDefaults.standard.synchronize()
        
        print("Saved data with \(favoriteIds.count) favorites using multiple methods")
    }
    
    private func loadData() {
    // Sample data
        contentItems = [
            /*
        // New LLM resources
        ContentItem(title: "ChatGPT and GenAI For Beginners", subject: "A.I.", platform: "Udemy", mins: 120, year: 2024, views: 1540, url: "https://www.udemy.com/course/generative-ai-course-master-chatgpt-genai-for-beginners/"),
 
        ContentItem(title: "Practical Introduction to ChatGPT", subject: "A.I.", platform: "Udemy", mins: 40, year: 2024, views: 1250, url: "https://www.udemy.com/course/practical-introduction-to-chatgpt-ai-academy/"),
        ContentItem(title: "AI for everything: Video Generation to Realistic Song", subject: "A.I.", platform: "Udemy", mins: 58, year: 2024, views: 875, url: "https://www.udemy.com/course/ai-for-everything-video-generation-to-realistic-song/"),
        
        ContentItem(title: "Machine Learning Concepts Explained", subject: "A.I.", platform: "Youtube", mins: 22, year: 2025, views: 875, url: "https://www.youtube.com/watch?v=Fa_V9fP2tpU"),
        
        ContentItem(title: "Mastering Generative AI for Developer Productivity", subject: "A.I.", platform: "Udemy", mins: 61, year: 2024, views: 980, url: "https://www.udemy.com/course/mastering-generative-ai-for-developer-productivity/"),
        
        ContentItem(title: "Training Your Own AI Model Is Not As Hard As You Think", subject: "A.I.", platform: "Youtube", mins: 11, year: 2024, views: 875, url: "https://www.youtube.com/watch?v=fCUkvL0mbxI"),
        
        ContentItem(title: "Generative A.I. & Prompt Engineering", subject: "A.I.", platform: "Udemy", mins: 117, year: 2024, views: 2100, url: "https://www.udemy.com/course/aim810-genai/"),
        
        ContentItem(title: "Intro to Google AI Studio", subject: "A.I.", platform: "Youtube", mins: 26, year: 2025, views: 2100, url: "https://www.youtube.com/watch?v=13EPujO40iE"),
        
        ContentItem(title: "Beginner Intro to A.I.", subject: "A.I.", platform: "Udemy", mins: 105, year: 2024, views: 760, url: "https://www.udemy.com/course/highschooler-intro-to-ai-course/"),
        ContentItem(title: "Introduction to RAG: Retrieval Augmented Generation", subject: "A.I.", platform: "Youtube", mins: 6, year: 2025, views: 760, url: " https://www.youtube.com/watch?v=tLGjvhLUqaY"),
        ContentItem(title: "Learn LangChain: Build LLM Applications with LangChain", subject: "A.I.", platform: "Udemy", mins: 107, year: 2024, views: 1820, url: "https://www.udemy.com/course/learn-langchain-build-llm-applications-with-langchain/"),
        ContentItem(title: "SLM's : What's a Small Language Model?", subject: "A.I.", platform: "Youtube", mins: 7, year: 2024, views: 760, url: "https://www.youtube.com/watch?v=ssVILYrZifQ"),
        ContentItem(title: "Become an AI-Powered Engineer: ChatGPT, Github Copilot", subject: "A.I.", platform: "Udemy", mins: 120, year: 2024, views: 690, url: "https://www.udemy.com/course/become-an-ai-powered-engineer-chatgpt-github-copilot/"),
        ContentItem(title: "Introduction to Generative AI", subject: "A.I.", platform: "Youtube", mins: 19, year: 2025, views: 690, url: "https://www.youtube.com/watch?v=-n3UAKECGAU"),
        ContentItem(title: "AI For Teachers and Educators", subject: "A.I.", platform: "Udemy", mins: 60, year: 2024, views: 950, url: "https://www.udemy.com/course/ai-for-teachers-and-educators/"),
        
        ContentItem(title: "Multiuser Python Jupyter Notebooks for Gen AI, ML & DS", subject: "A.I.", platform: "Udemy", mins: 60, year: 2024, views: 580, url: "https://www.udemy.com/course/multiuser-python-jupyter-notebooks-for-gen-ai-ml-ds/"),
        
        // YouTube resources
        ContentItem(title: "Large Language Models Explained", subject: "A.I.", platform: "YouTube", mins: 8, year: 2025, views: 15400, url: "https://www.youtube.com/watch?v=LPZh9BOjkQs&t=214s"),
        ContentItem(title: "Beginner and Basics of AI", subject: "A.I.", platform: "YouTube", mins: 10, year: 2025, views: 9800, url: "https://www.youtube.com/watch?v=nVyD6THcvDQ"),
        ContentItem(title: "Generative A.I. Overview", subject: "A.I.", platform: "YouTube", mins: 9, year: 2024, views: 12500, url: "https://www.youtube.com/watch?v=2p5OHDxR2l8"),
        ContentItem(title: "Large Language Models - Everything You Need to Know", subject: "A.I.", platform: "YouTube", mins: 25, year: 2024, views: 18700, url: "https://www.youtube.com/watch?v=osKyvYJ3PRM"),
        ContentItem(title: "Introduction to Large Language Models", subject: "A.I.", platform: "YouTube", mins: 15, year: 2024, views: 8100, url: "https://www.youtube.com/watch?v=zizonToFXDs"),
        ContentItem(title: "Introduction to Generative A.I. - Course Intro", subject: "A.I.", platform: "YouTube", mins: 20, year: 2025, views: 10600, url: "https://www.youtube.com/watch?v=Xz9asEJ4CB4"),
        ContentItem(title: "Model Context Protocol", subject: "A.I.", platform: "YouTube", mins: 12, year: 2025, views: 7500, url: "https://www.youtube.com/watch?v=xyVTbv209a4"),
        ContentItem(title: "Machine Learning Algorithms Explained", subject: "A.I.", platform: "YouTube", mins: 17, year: 2024, views: 21000, url: "https://www.youtube.com/watch?v=E0Hmnixke2g"),
        ContentItem(title: "Introduction to Generative A.I.", subject: "A.I.", platform: "YouTube", mins: 18, year: 2024, views: 11200, url: "https://www.youtube.com/watch?v=cZaNf2rA30k")
                          */
    ]
    }
    
    // New function to save custom cards
    func saveCustomCards() {
        if let encoded = try? JSONEncoder().encode(customItems) {
            UserDefaults.standard.set(encoded, forKey: "customItems")
            UserDefaults.standard.synchronize()
            print("Saved \(customItems.count) custom cards")
        }
    }
    
    // New function to load custom cards
    func loadCustomCards() {
        if let data = UserDefaults.standard.data(forKey: "customItems"),
           let decoded = try? JSONDecoder().decode([ContentItem].self, from: data) {
            customItems = decoded
            print("Loaded \(customItems.count) custom cards")
        }
    }
}

struct ResourcesListView: View {
    let contentItems: [ContentItem]
    @Binding var favoriteIds: Set<String>
    let onToggleFavorite: (String) -> Void
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // Determine if we're in landscape mode
    private var isLandscape: Bool {
        return verticalSizeClass == .compact
    }
    
    // Add a property to detect if the device is an iPad
    private var isIPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image - keeping dpad3
                Image("dpad3")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.4)
                
                VStack(spacing: 0) {
                    // Fixed title header - always visible at top
                    VStack(spacing: 4) {
                        HStack {
                            Text("A.I.")
                                .font(isLandscape ? .headline : .title)
                                .fontWeight(.bold)
                            
                            Image("dpad4icons1")
                                .resizable()
                                .scaledToFit()
                                .frame(height: isLandscape ? 20 : 30)
                            
                            Text("DelvePad")
                                .font(isLandscape ? .headline : .title)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, isLandscape ? 4 : 8)
                    .background(Color.white.opacity(0.7))
                    .shadow(radius: 2)
                    
                    // Scrollable content area with adjusted insets
                    ScrollView(showsIndicators: true) {
                        // For iPad, add 40% more padding between title and first row
                        if isIPad {
                            Spacer()
                                .frame(height: isLandscape ? 21 : 28)  // Increased by 40%
                        } else {
                            Spacer()
                                .frame(height: isLandscape ? 15 : 20)  // Standard padding for iPhone
                        }
                        
                        // Adjust columns for iPad - 3 columns in landscape, 2 in portrait
                        let columns = isIPad ? 
                            (isLandscape ? 
                                Array(repeating: GridItem(.flexible(), spacing: 15), count: 3) : 
                                Array(repeating: GridItem(.flexible(), spacing: 15), count: 2)) :
                            (isLandscape ? 
                                Array(repeating: GridItem(.flexible(), spacing: 12), count: 2) : 
                                [GridItem(.flexible())])
                        
                        LazyVGrid(columns: columns, spacing: isIPad ? 20 : (isLandscape ? 12 : 20)) {
                            ForEach(contentItems) { item in
                                ZStack(alignment: .topTrailing) {
                                    // Card with 20% reduced height
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .aspectRatio(isIPad ? 2.6 : 2.6, contentMode: .fit) // Increased from 1.9 to 2.3 for shorter height
                                        .frame(height: isIPad ? 103 : (isLandscape ? 83 : 129)) // Reduced by 20% from 129 to 103
                                        .overlay(
                                            ContentCardOverlay(
                                                item: item,
                                                isLandscape: isLandscape,
                                                isIPad: isIPad
                                            )
                                        )
                                        .shadow(radius: 2)
                                        .padding(.horizontal, 4)
                                    
                                    // Favorite button at 30px from top
                                    Button(action: {
                                        onToggleFavorite(item.id)
                                    }) {
                                        Image(systemName: favoriteIds.contains(item.id) ? "star.fill" : "star")
                                            .imageScale(.large)
                                            .foregroundColor(.yellow)
                                    }
                                    .padding(.top, 10)
                                    .padding(.trailing, 8)
                                }
                            }
                        }
                        .padding(.horizontal, isIPad ? 20 : (isLandscape ? 10 : 16))
                        
                        // Add 700px of padding after the grid
                        Spacer()
                            .frame(height: 200)
                    }
                }
                .edgesIgnoringSafeArea(.bottom) // Make sure bottom edge is ignored in all orientations
            }
        }
    }
}

struct FavoritesView: View {
    let contentItems: [ContentItem]  // This now includes both built-in and custom items
    @Binding var favoriteIds: Set<String>
    @Binding var completedIds: Set<String>
    let onToggleFavorite: (String) -> Void
    let onToggleCompleted: (String) -> Void
    @State private var showingShareSheet = false
    @State private var showUnfavoriteAlert = false
    @State private var itemToUnfavorite: String? = nil
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // Determine if we're in landscape mode
    private var isLandscape: Bool {
        return verticalSizeClass == .compact
    }
    
    private var isIPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // This filtered list will now include both built-in and custom favorited items
    var filteredFavorites: [ContentItem] {
        return contentItems.filter { favoriteIds.contains($0.id) }
    }
    
    // Property to collect all URLs from favorited items
    private var favoriteUrls: [URL] {
        return filteredFavorites.compactMap { item in
            guard let urlString = item.url else { return nil }
            return URL(string: urlString)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background image - keeping dpad3
                Image("dpad3")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.4)
                
                VStack(spacing: 0) {
                    // Fixed title header - always visible at top
                    VStack(spacing: 4) {
                            HStack {
                                Text("A.I.")
                                .font(isLandscape ? .headline : .title)
                                    .fontWeight(.bold)
                                
                                Image("dpad4icons1")
                                    .resizable()
                                    .scaledToFit()
                                .frame(height: isLandscape ? 20 : 30)
                                
                                Text("DelvePad")
                                .font(isLandscape ? .headline : .title)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, isLandscape ? 4 : 8)
                    .background(Color.white.opacity(0.7))
                    //.shadow(radius: 2)
                    .frame(alignment: .top)
            
                    
                    // ZStack for fixed share button positioning
                    ZStack(alignment: .topTrailing) {
//                        if filteredFavorites.isEmpty {
//                                Spacer()
//                                .frame(height: 400)
//                            Text("Add favorites to fill.")
//                                //.foregroundColor(.gray)
//                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
//                                .multilineTextAlignment(.leading)
//                                .padding(.vertical, 100)
//                                .padding(.horizontal, 100)
//                            Spacer()
//                        }
                        if filteredFavorites.isEmpty {
                            ScrollView {
                                VStack {
                                    Spacer().frame(height: 100)
                                    Text("Add favorites to fill.")
                                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                                        .multilineTextAlignment(.center)
                                        .padding()
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                            }
                        }
                        
                        else {
                            ScrollView(showsIndicators: true) {
                                // Space for share button
                                Spacer()
                                    .frame(height: 50)
                                
                                let columns = isIPad ? 
                                    (isLandscape ? 
                                        Array(repeating: GridItem(.flexible(), spacing: 15), count: 3) : 
                                        Array(repeating: GridItem(.flexible(), spacing: 15), count: 2)) :
                                    (isLandscape ? 
                                        Array(repeating: GridItem(.flexible(), spacing: 12), count: 2) : 
                                        [GridItem(.flexible())])
                                
                                LazyVGrid(columns: columns, spacing: isIPad ? 20 : (isLandscape ? 12 : 20)) {
                                    ForEach(filteredFavorites) { item in
                                        ZStack(alignment: .topTrailing) {
                                            // Card with consistent sizing - explicitly declaring all dimensions
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .aspectRatio(isIPad ? 1.9 : 1.9, contentMode: .fit)
                                                .frame(height: isIPad ? 161 : 161) // Use consistent height
                                                .overlay(
                                                    FavoriteCardOverlay(
                                                        item: item,
                                                        isCompleted: completedIds.contains(item.id),
                                                        toggleCompleted: { onToggleCompleted(item.id) },
                                                        isLandscape: isLandscape,
                                                        isIPad: isIPad
                                                    )
                                                )
                                                .scrollTransition(.animated) { content, phase in

                                                    content
                                                        .opacity(phase.isIdentity ? 1.0 : 0.3)
                                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.3)

                                                }
                                                .shadow(radius: 2)
                                                .padding(.horizontal, 4)
                                            
                                            // Favorite button at exactly 30px from top
                                            Button(action: {
                                                itemToUnfavorite = item.id
                                                showUnfavoriteAlert = true
                                            }) {
                                                Image(systemName: "star.fill")
                                                    .imageScale(.large)
                                                    .foregroundColor(.yellow)
                                            }
                                            .padding(.top, 30) // Exact 30px from top
                                            .padding(.trailing, 8)
                                        }
                                    }
                                }
                                .padding(.horizontal, isIPad ? 20 : (isLandscape ? 10 : 16))
                                
                                // Add 700px of padding after the grid
                            Spacer()
                                    .frame(height: 700)
                            }
                        }
                        
                        // Share button with icon moved to the right side of text
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            HStack {
                                Text("Share A.I. Links")
                                    .font(.subheadline)
                                
                                    Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18))
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 15)
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                        }
                        .frame(width: geometry.size.width * 0.36) // 60% of 60% of screen width
                        .disabled(favoriteUrls.isEmpty)
                        .opacity(favoriteUrls.isEmpty ? 0.6 : 1)
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            // Share sheet for the links
            .sheet(isPresented: $showingShareSheet) {
                if #available(iOS 16.0, *) {
                    let urlStrings = favoriteUrls.map { $0.absoluteString }
                    let text = "Checkout these free A.I. vids:\n\n" + urlStrings.joined(separator: "\n\n")
                    ShareSheet(items: [text])
                } else {
                    // Fallback for older iOS versions
                    let urlStrings = favoriteUrls.map { $0.absoluteString }
                    let text = "Checkout these free A.I. vids:\n\n" + urlStrings.joined(separator: "\n\n")
                    ShareSheet(items: [text])
                }
            }
        }
        .alert(isPresented: $showUnfavoriteAlert) {
            Alert(
                title: Text("Remove from Favorites?"),
                message: Text("Are you sure you want to remove this item from your favorites?"),
                primaryButton: .destructive(Text("Remove")) {
                    if let id = itemToUnfavorite {
                        onToggleFavorite(id)
                        itemToUnfavorite = nil
                    }
                },
                secondaryButton: .cancel {
                    itemToUnfavorite = nil
                }
            )
        }
    }
}

// ShareSheet struct to handle sharing functionality
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Adjust the content overlays for 40% reduced height on iPad
struct ContentCardOverlay: View {
    let item: ContentItem
    var isLandscape: Bool = false
    var isIPad: Bool = false
    @State private var copied = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Title and other text content at the top
                VStack(alignment: .leading, spacing: isIPad ? 1 : (isLandscape ? 1 : 2)) {
                    Text("Title: \(item.title)")
                        .font(isIPad ? .subheadline : (isLandscape ? .subheadline : .headline))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .padding(.trailing, 30)
                    
                    HStack {
                        Text("Platform: \(item.platform)")
                            .font(isIPad ? .caption : (isLandscape ? .caption : .subheadline))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Mins: \(item.mins)")
                            .font(isIPad ? .caption : (isLandscape ? .caption : .subheadline))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Year: \(String(item.year))")
                            .font(isIPad ? .caption : (isLandscape ? .caption : .subheadline))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(isIPad ? (isLandscape ? 6 : 8) : (isLandscape ? 6 : 10))
                
                // Browse button in bottom right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = item.url ?? "https://www.google.com"
                            withAnimation(.easeInOut(duration: 1)) {
                                copied = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.easeInOut(duration: 1)) {
                                    copied = false
                                }
                            }
                        }) {
                            if let _ = UIImage(named: "browseicon1") {
                               // Image("browseicon1")
                                Image(systemName: "square.on.square")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: isIPad ? 23 : 20)
                            } else {
                                Image(systemName: "safari")
                                    .imageScale(.large)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 8)
                        .padding(.bottom, 8)
                    }
                }
                
                // Copy animation overlay
                if copied {
                    Text("Tutorial Link Copied!")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue.cornerRadius(20))
                        .position(x: geo.frame(in: .local).width/2, y: 20)
                        .opacity(0.7)
                      //  .transition(.move(edge: .top))
                }
            }
            .animation(.easeInOut(duration: 1), value: copied)
        }
    }
}

struct FavoriteCardOverlay: View {
    let item: ContentItem
    let isCompleted: Bool
    let toggleCompleted: () -> Void
    var isLandscape: Bool = false
    var isIPad: Bool = false
    @State private var copied = false
    
    var body: some View {
        GeometryReader { geo in
        ZStack {
                // Title and other text content at the top
                VStack(alignment: .leading, spacing: isIPad ? 1 : (isLandscape ? 1 : 2)) {
                    Text("Title: \(item.title)")
                        .font(isIPad ? .subheadline : (isLandscape ? .subheadline : .headline))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .padding(.trailing, 30)
                    
                    HStack {
                        Text("Platform: \(item.platform)")
                            .font(isIPad ? .caption : (isLandscape ? .caption : .subheadline))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Mins: \(item.mins)")
                            .font(isIPad ? .caption : (isLandscape ? .caption : .subheadline))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Year: \(String(item.year))")
                            .font(isIPad ? .caption : (isLandscape ? .caption : .subheadline))
                            .foregroundColor(.white)
                    }
                    
                    // Status button
                    HStack {
                        Text("Viewed/Completed:")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Button(action: toggleCompleted) {
                            Text(isCompleted ? "Viewed" : "Course Status")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(isCompleted ? Color.yellow.opacity(0.8) : Color.blue.opacity(0.8))
                                .cornerRadius(4)
                        }
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(isIPad ? (isLandscape ? 6 : 8) : (isLandscape ? 6 : 10))
                
                // Browse button in bottom right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = item.url ?? "https://www.google.com"
                            withAnimation(.easeInOut(duration: 1)) {
                                copied = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.easeInOut(duration: 1)) {
                                    copied = false
                                }
                            }
                        }) {
                            if let _ = UIImage(named: "browseicon1") {
                               // Image("browseicon1")
                                Image(systemName: "square.on.square")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: isIPad ? 23 : 20)
                            } else {
                                Image(systemName: "safari")
                                    .imageScale(.large)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 8)
                        .padding(.bottom, 8)
                    }

                }
                
                // Copy animation overlay
                if copied {
                    Text("Tutorial Link Copied!")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue.cornerRadius(20))
                        .position(x: geo.frame(in: .local).width/2, y: 20)
                        .opacity(0.7)
                       // .transition(.move(edge: .top))
                }
            }
            .animation(.easeInOut(duration: 1), value: copied)
        }
    }
}

struct SettingsView: View {
    let favoriteIds: Set<String>
    let completedIds: Set<String>
    let contentItems: [ContentItem]
    
    // Calculate statistics
    var totalItems: Int {
        return contentItems.count
    }
    
    var favoritedItems: Int {
        return favoriteIds.count
    }
    
    var completedItems: Int {
        // Only count items that are both completed AND still in favorites
        return completedIds.filter { favoriteIds.contains($0) }.count
    }
    
    var progressPercentage: CGFloat {
        if favoritedItems == 0 {
            return 0.001 // Avoid division by zero
        } else {
            return CGFloat(completedItems) / CGFloat(favoritedItems)
        }
    }
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // Determine if we're in landscape mode
    private var isLandscape: Bool {
        return verticalSizeClass == .compact
    }
    
    // Add a property to detect if the device is an iPad
    private var isIPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image - keeping dpad3
                Image("dpad3")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.4)
                
                VStack(spacing: 0) {
                    // Fixed title header - always visible at top
                    VStack(spacing: 4) {
                        HStack {
                            Text("A.I.")
                                .font(isLandscape ? .headline : .title)
                                .fontWeight(.bold)
                            
                            Image("dpad4icons1")
                                .resizable()
                                .scaledToFit()
                                .frame(height: isLandscape ? 20 : 30)
                            
                            Text("DelvePad")
                                .font(isLandscape ? .headline : .title)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, isLandscape ? 4 : 8)
                    .background(Color.white.opacity(0.7))
                    .shadow(radius: 2)
                    
                    // Content adjusted for better landscape visibility
                    ScrollView(showsIndicators: true) {
                        // Add exactly 200px of padding between title and graph for iPad
                        if isIPad {
                            Spacer()
                                .frame(height: 200)  // Exactly 200px as requested
                        } else {
                            // Standard padding for iPhone
                            Spacer()
                                .frame(height: isLandscape ? 21 : 25)
                        }
                        
                        if isLandscape {
                            // Landscape layout
                            HStack(alignment: .center, spacing: 20) {
                                donutChartView
                                    .frame(width: geometry.size.width * 0.35, height: geometry.size.height * 0.6)
                                    .padding(.leading)
                                
                                legendView
                                    .padding(.trailing)
                            }
                            // Apply default padding unless it's iPad
                            .padding(.bottom, isIPad ? 0 : 100)
                        } else {
                            // Portrait layout
                            VStack(alignment: .center, spacing: 20) {
                                donutChartView
                                    .padding(.horizontal)
                                    .frame(height: 200)
                                
                                legendView
                            }
                            .padding()
                            // Apply default padding unless it's iPad
                            .padding(.bottom, isIPad ? 0 : 50)
                        }
                        
                        // Add 900px padding specifically for iPad in landscape mode
                        if isIPad && isLandscape {
                            Spacer()
                                .frame(height: 900) // 900px for iPad in landscape
                        } else if isIPad {
                            Spacer()
                                .frame(height: 700) // Maintain 700px for iPad in portrait
                        } else {
                            Spacer()
                                .frame(height: 700) // Maintain 700px for iPhone
                        }
                    }
                    .padding(.top, 0)
                }
                .edgesIgnoringSafeArea(.bottom)
            }
        }
    }
    
    private var donutChartView: some View {
        ZStack {
            // Outer ring (total favorited)
            Circle()
                .stroke(Color.blue.opacity(0.5), lineWidth: 40)
                .frame(width: 200, height: 200)
            
            // Inner ring (completed/viewed)
            Circle()
                .trim(from: 0, to: progressPercentage)
                .stroke(Color.green, lineWidth: 40)
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
            
            // Center white circle for donut effect
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 120, height: 120)
            
            // Text for stats
            VStack {
                Text("\(completedItems)/\(favoritedItems)")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Viewed")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 20)
        .animation(.easeInOut, value: progressPercentage)
    }
    
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.5))
                    .frame(width: 20, height: 20)
                
                Text("Favorited Tutorials: \(favoritedItems)")
            }
            
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green)
                    .frame(width: 20, height: 20)
                
                Text("Viewed Tutorials: \(completedItems)")
            }
            
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 20, height: 20)
                
                Text("Total Tutorials: \(totalItems)")
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(10)
        .padding()
    }
}

// New view for the 4th tab
struct CustomCardsView: View {
    @Binding var customItems: [ContentItem]
    @Binding var favoriteIds: Set<String>
    @Binding var completedIds: Set<String>
    let onToggleFavorite: (String) -> Void
    
    @State private var showingAddSheet = false
    @State private var title = ""
    @State private var platform = ""
    @State private var mins = ""
    @State private var year = ""
    @State private var url = ""
    
    // Device properties
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var isLandscape: Bool {
        let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
        return orientation?.isLandscape ?? false
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image to match other tabs
                Image("dpad3")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.4)
                
                VStack(spacing: 0) {
                    // Title section to match other tabs
                    VStack(alignment: .center, spacing: 4) {
                        HStack {
                            Text("A.I.")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Image("dpad4icons1")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 30)
                            
                            Text("DelvePad")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, 16)
                    
                    // Add button
                    Button(action: {
                        // Reset fields and show add sheet
                        title = ""
                        platform = ""
                        mins = ""
                        year = ""
                        url = ""
                        showingAddSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Tutorial Entry")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.vertical, 10)
                    
                    // Display custom cards in a grid matching other tabs
                    ScrollView(showsIndicators: true) {
                        // Grid layout
                        let columns = isIPad 
                            ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                            : (isLandscape 
                               ? [GridItem(.flexible()), GridItem(.flexible())]
                               : [GridItem(.flexible())])
                        
                        if customItems.isEmpty {
                            // Empty state with darker grey text
                            VStack {
                                Spacer()
                                    .frame(height: 40)
                                
                                Text("Hub for A.I. tutorials added")
                                    .font(.title2)
                                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3)) // Darker grey color
                                
                                Text("Tap button to add your entries")
                                    .font(.body)
                                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3)) // Darker grey color
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                    .padding(.top, 8)
                                
                                Spacer()
                            }
                            .frame(height: 200)
                        } else {
                            // Custom cards grid
                            LazyVGrid(columns: columns, spacing: isIPad ? 20 : (isLandscape ? 12 : 20)) {
                                ForEach(customItems) { item in
                                    ZStack {
                                        // Card with consistent sizing
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .aspectRatio(isIPad ? 1.9 : 1.9, contentMode: .fit)
                                            .frame(height: isIPad ? 161 : nil) // Use same height on iPad
                                            .overlay(
                                                // Custom overlay with delete button
                                                ZStack {
                                                    // Regular content overlay
                                                    ContentCardOverlay(
                                                        item: item,
                                                        isLandscape: isLandscape,
                                                        isIPad: isIPad
                                                    )
                                                    
                                                    // Delete button at bottom left
                                                    VStack {
                                                        Spacer()
                                                        HStack {
                                                            Button(action: {
                                                                deleteCard(item)
                                                            }) {
                                                                Image(systemName: "trash")
                                                                    .imageScale(.medium)
                                                                    .foregroundColor(.gray) // Grey color
                                                            }
                                                            .padding(.leading, 10)
                                                            .padding(.bottom, 8)
                                                            
                                                            Spacer()
                                                        }
                                                    }
                                                }
                                            )
                                            .scrollTransition(.animated) { content, phase in

                                                content
                                                    .opacity(phase.isIdentity ? 1.0 : 0.3)
                                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.3)

                                            }
                                            .shadow(radius: 2)
                                            .padding(.horizontal, 4)
                                        
                                        // Favorite button (top right)
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Button(action: {
                                                    onToggleFavorite(item.id)
                                                }) {
                                                    Image(systemName: favoriteIds.contains(item.id) ? "star.fill" : "star")
                                                        .imageScale(.large)
                                                        .foregroundColor(.yellow)
                                                        .padding(.top, 8)
                                                        .padding(.trailing, 8)
                                                }
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, isIPad ? 20 : (isLandscape ? 10 : 16))
                        }
                        
                        // Add padding at bottom matching other tabs
                        Spacer()
                            .frame(height: 700)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                CustomCardInputView(isPresented: $showingAddSheet, contentItems: $customItems)
                    .clearModalBackground()
            }
        }
    }
    
    // Function to add a new card
    private func addNewCard() {
        // Parse mins and year as Int values
        let minsInt = Int(mins) ?? 0
        let yearInt = Int(year) ?? Calendar.current.component(.year, from: Date())
        let viewsInt = 0
        
        // Create the new card without explicit id parameter
        var newCard = ContentItem(
            title: title,
            subject: "Custom",
            platform: platform,
            mins: minsInt,
            year: yearInt,
            views: viewsInt,
            url: url.isEmpty ? "https://www.example.com" : url
        )
        
        // Optionally set a custom ID if the structure allows it
        // (uncomment this if ContentItem has a mutable id property)
        // newCard.id = "custom-\(UUID().uuidString)"
        
        // Add to list and save
        customItems.append(newCard)
        saveCustomCards()
    }
    
    // Function to delete a card and clean up associated data
    private func deleteCard(_ item: ContentItem) {
        // Remove the card from customItems
        if let index = customItems.firstIndex(where: { $0.id == item.id }) {
            customItems.remove(at: index)
            
            // Also remove from favorites if it was favorited
            if favoriteIds.contains(item.id) {
                favoriteIds.remove(item.id)
            }
            
            // Also remove from completed if it was viewed
            if completedIds.contains(item.id) {
                completedIds.remove(item.id)
            }
            
            // Save all changes
            saveCustomCards()
            saveFavoritesAndCompleted()
        }
    }
    
    // Function to save custom cards
    private func saveCustomCards() {
        if let encoded = try? JSONEncoder().encode(customItems) {
            UserDefaults.standard.set(encoded, forKey: "customItems")
            UserDefaults.standard.synchronize()
        }
    }
    
    // Function to save favorites and completed
    private func saveFavoritesAndCompleted() {
        // Save favorites
        UserDefaults.standard.set(Array(favoriteIds), forKey: "favoriteItems")
        
        // Save completed
        UserDefaults.standard.set(Array(completedIds), forKey: "completedItems")
        
        // Force synchronize
        UserDefaults.standard.synchronize()
    }
}

// Add this struct before CustomCardInputView
struct CustomTextField: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .font(.system(size: 14))
            .autocapitalization(.none)
            .disableAutocorrection(true)
    }
}

// Rest of your CustomCardInputView remains the same...
struct CustomCardInputView: View {
    @Binding var isPresented: Bool
    @Binding var contentItems: [ContentItem]
    
    @State private var title: String = ""
    @State private var platform: String = ""
    @State private var year: String = ""
    @State private var mins: String = ""
    @State private var url: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent black overlay
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        isPresented = false
                    }
                
                // Input window
                VStack(spacing: 15) {
                    Text("Add Tutorial Entry")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    CustomTextField(text: $title, placeholder: "Title")
                        .frame(height: 35)
                    
                    CustomTextField(text: $platform, placeholder: "Platform (Youtube, Udemy, Coursera, etc.)")
                        .frame(height: 35)
                    
                    CustomTextField(text: $year, placeholder: "Year")
                        .frame(height: 35)
                        .keyboardType(.numberPad)
                    
                    CustomTextField(text: $mins, placeholder: "Minutes")
                        .frame(height: 35)
                        .keyboardType(.numberPad)
                    
                    CustomTextField(text: $url, placeholder: "URL")
                        .frame(height: 35)
                    
                    HStack(spacing: 20) {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .foregroundColor(.red)
                        
                        Button("Save") {
                            let newItem = ContentItem(
                                title: title,
                                subject: "",
                                platform: platform,
                                mins: Int(mins) ?? 0,
                                year: Int(year) ?? 0,
                                views: 0,
                                url: url
                            )
                            contentItems.append(newItem)
                            isPresented = false
                        }
                        .disabled(title.isEmpty || platform.isEmpty || year.isEmpty || mins.isEmpty || url.isEmpty)
                    }
                    .padding(.top, 10)
                }
                .frame(height: 400)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 10)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .background(Color.clear)
    }
}

// Add this extension to make the sheet background transparent
extension View {
    func clearModalBackground() -> some View {
        if #available(iOS 16.4, *) {
            return self.presentationBackground(.clear)
        } else {
            return self.interactiveDismissDisabled()
        }
    }
}

// New Glossary View
struct GlossaryView: View {
    @State private var selectedCategory = "LLM"
    let categories = [
        "Machine Learning", "Deep Learning", "LLM", "LLM Training",
        "Fine-tuning", "Parameter", "Vector", "Embeddings",
        "Tokenization", "Transformers", "Attention Mechanisms",
        "Inference", "LLM Temperature", "Frequency Parameter",
        "Sampling", "Top-k Sampling", "RLHF",
        "Decoding Strategies", "Language Model Prompting",
        "Autoregressive Models"
    ]
    
    let definitions: [String: String] = [
        "Machine Learning": "A subset of artificial intelligence that enables systems to learn and improve from experience without being explicitly programmed.",
        "Deep Learning": "A type of machine learning based on artificial neural networks that can learn representations of data with multiple levels of abstraction.",
        "LLM": "Large Language Models are advanced AI models trained on vast amounts of text data to understand and generate human-like text.",
        "LLM Training": "The process of teaching language models using large datasets to understand and generate human-like text.",
        "Fine-tuning": "The process of further training a pre-trained model on a specific dataset to adapt it for a particular task.",
        "Parameter": "Variables in a machine learning model that are learned during training.",
        "Vector": "A mathematical representation of data in multiple dimensions.",
        "Embeddings": "Dense vector representations of discrete variables, capturing semantic meanings.",
        "Tokenization": "The process of converting text into smaller units (tokens) for processing.",
        "Transformers": "Neural network architecture that uses self-attention mechanisms for processing sequential data.",
        "Attention Mechanisms": "Components that allow models to focus on different parts of the input when producing output.",
        "Inference": "The process of using a trained model to make predictions on new data.",
        "LLM Temperature": "A parameter controlling the randomness of model outputs.",
        "Frequency Parameter": "Controls how likely the model is to repeat common patterns in its output.",
        "Sampling": "The process of generating text by selecting tokens based on their predicted probabilities.",
        "Top-k Sampling": "A text generation method that considers only the k most likely next tokens.",
        "RLHF": "Reinforcement Learning from Human Feedback - A method to align AI models with human preferences.",
        "Decoding Strategies": "Methods used to generate text from language models.",
        "Language Model Prompting": "Techniques for effectively instructing language models to perform specific tasks.",
        "Autoregressive Models": "Models that generate output sequences one element at a time."
    ]

    var body: some View {
        GeometryReader { geometry in
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad Layout
        ZStack {
                    // Background
            Image("dpad3")
                .resizable()
                        .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                        .opacity(0.2)
                    
                    VStack(spacing: 0) {
                        // Title section
                        VStack(alignment: .center, spacing: 4) {
//                            HStack {
//                                Text("A.I.")
//                                    .font(.title)
//                                    .fontWeight(.bold)
//                                
//                                Image("dpad4icons1")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(height: 30)
//                                
//                                Text("DelvePad")
//                                    .font(.title)
//                                    .fontWeight(.bold)
//                            }
//                            .frame(maxWidth: .infinity, alignment: .center)
//                            Text("A.I. Terms and Definitions")
//                                .font(.headline)
//                                .padding(.bottom, 8)
                            HStack {
                                Text("A.I.")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                Image("dpad4icons1")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 30)
                                
                                Text("DelvePad")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, geometry.safeAreaInsets.top + 20)
                            .padding(.bottom, 20)
                        }
                        .padding(.top, 16)
                        
                        // Blue buttons at top for iPad
                        FlowLayout() {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    withAnimation {
                                        selectedCategory = category
                                    }
                                }) {
                                    Text(category)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(selectedCategory == category ? Color.blue.opacity(0.8) : Color.blue)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                        // Green definitions starting at Y 200
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(categories, id: \.self) { category in
                                    if let definition = definitions[category] {
                                        GlossaryItem(
                                            term: category,
                                            definition: definition
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
//                            if UIDevice.current.userInterfaceIdiom == .pad {
//                                        Spacer()
//                                            .frame(minHeight: 1000)
//                                    }
                            
                            // Added space at bottom of iPads
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                Spacer()
                                .frame(height:1500, alignment: .topLeading)}
                        }
                        .padding(.top, 25)
                    }
                }.ignoresSafeArea(edges: .all)
            } else {
                // iPhone Layout (unchanged)
                ZStack {
                    // Background
                    Image("dpad3")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                        .opacity(0.2)
                    
                    ScrollViewReader { scrollProxy in
                        VStack(spacing: 0) {
                            // Title section
                            VStack(alignment: .center, spacing: 4) {
                                HStack {
                                    Text("A.I.")
                                        .font(.title)
                                        .fontWeight(.bold)
                                    
                                    Image("dpad4icons1")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 30)
                                    
                                    Text("DelvePad")
                                        .font(.title)
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                
                                Text("A.I. Terms and Definitions")
                                    .font(.headline)
                                    .padding(.bottom, 8)
                            }
                            .padding(.top, 16)
                            
                            // Blue buttons with wrapping
                            FlowLayout() {
                                ForEach(categories, id: \.self) { category in
                                    Button(action: {
                                        withAnimation {
                                            selectedCategory = category
                                            scrollProxy.scrollTo("topAnchor", anchor: .top)
                                        }
                                    }) {
                                        Text(category)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .fill(selectedCategory == category ? Color.blue.opacity(0.8) : Color.blue)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(Color.white, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            
                            // Green definition cards
                            ScrollView {
                                VStack(spacing: 16) {
                                    Color.clear
                                        .frame(height: 0)
                                        .id("topAnchor")
                                    
                                    if let selectedDef = definitions[selectedCategory] {
                                        GlossaryItem(
                                            term: selectedCategory,
                                            definition: selectedDef
                                        )
                                    }
                                    
                                    ForEach(categories.filter { $0 != selectedCategory }, id: \.self) { category in
                                        if let definition = definitions[category] {
                                            GlossaryItem(
                                                term: category,
                                                definition: definition
                                            )
                                        }
                                    }
                                    
                        Spacer()
                                        .frame(height: 100)
                    }
                                
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                }
                            
            }
        }
                }
            }
        }
    }
}

struct GlossaryItem: View {
    let term: String
    let definition: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(term)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(definition)
                .font(.body)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.9))
        )
    }
}

struct FlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var position = CGPoint.zero
        var maxHeight: CGFloat = 0
        let spacing: CGFloat = 8
        
        for size in sizes {
            if position.x + size.width > (proposal.width ?? 0) {
                position.x = 0
                position.y += size.height + spacing
            }
            position.x += size.width + spacing
            maxHeight = max(maxHeight, position.y + size.height)
        }
        
        return CGSize(width: proposal.width ?? 0, height: maxHeight + spacing)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var position = CGPoint(x: bounds.minX, y: bounds.minY)
        let spacing: CGFloat = 8
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if position.x + size.width > bounds.maxX {
                position.x = bounds.minX
                position.y += size.height + spacing
            }
            
            subview.place(
                at: CGPoint(x: position.x, y: position.y),
                proposal: ProposedViewSize(size)
            )
            
            position.x += size.width + spacing
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct TechInfoView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("dpad3")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.4)
                
                VStack(spacing: 0) {
                    // Fixed Header - always at top
                    HStack {
                        Text("A.I.")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Image("dpad4icons1")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                        
                        Text("DelvePad")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, geometry.safeAreaInsets.top + 20)
                    .padding(.bottom, 20)
                    
                    // Scrollable Content - starts from top
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 30) {
                            // Introduction Card
                            VStack(alignment: .leading, spacing: 15) {
                                Text("LLM Process ")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                Text("In the process of creating an LLM, there are 3 parts of the process : ")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                Text("-Pre-training\n-Fine-tuning\n-Reinforcement Learning")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                Text("During Pre-training, large amounts of data are processed by the A.I. model to create its language base. Then in Fine-tuning, it's trained to give more goal-driven outputs from user input. Then Reinforcement Learning is applied, where its responses are given a series of rankings in order to have the LLM  give more appropriate output and answers. The process its further described below : ")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white)
                                    .shadow(radius: 5)
                            )
                            .padding(.horizontal, 20)
                            
                            // Content Card
                            VStack(alignment: .leading, spacing: 25) {
                                // First Paragraph
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("1. Pre-training")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    Text("In the pre-training phase, Large Language Models (LLMs) are trained as next-word predictors using vast, unstructured text data sourced from the internet. This includes books, websites, articles, forums, and code repositories to ensure language diversity. The text data is cleaned to remove HTML tags, noise, and irrelevant sections. After preprocessing, it's tokenized into smaller units like subwords using methods like Byte-Pair Encoding (BPE) or WordPiece. These token sequences are then input into transformer-based architectures, which are highly effective at handling long-range dependencies in language. The model learns to generate fluent, coherent sequences based on contextual clues.\n\nThis unsupervised learning task teaches the LLM general language understanding—grammar, semantics, and factual associations—without any explicit labeling. However, at this stage, the model doesn’t truly comprehend instructions or distinguish between question-answer formats and casual text. It’s simply learned to mimic patterns from its training data, meaning it may complete prompts with plausible text but not necessarily aligned responses. For example, asking “What is the capital of France?” might result in a continuation like “...is a common geography question.” Thus, pre-training creates a powerful language base, but additional steps are needed to guide it toward useful, goal-oriented behavior.")
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                }
                                
                                Divider()
                                    .background(Color.gray)
                                
                                // Second Paragraph
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("2. Fine-tuning")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    Text("Fine-tuning, or Supervised Fine-Tuning (SFT), builds upon the pre-trained model by introducing it to task-specific or instruction-following behavior. In this phase, a curated dataset containing pairs of user instructions and ideal responses (often written by AI trainers) is used. The model is trained to minimize the error between its output and these ground truth responses, helping it learn how to behave more like a helpful assistant. Unlike pre-training, which is general-purpose, fine-tuning ensures the model can respond meaningfully to specific prompts like “Summarize this article” or “Translate this sentence.”\n\nThis phase allows the model to associate user inputs with clear, goal-driven outputs. If the training data includes, for instance, “What is the capital of Brazil?” and the correct answer “Brasilia,” the model learns to respond accordingly. It also begins to understand the structure of instruction-response conversations, enabling it to provide answers instead of continuing random sentences. Fine-tuning introduces more consistency, accuracy, and contextual awareness. However, while the model becomes better at task execution, it may still generate factually incorrect or biased outputs, and it might not fully align with human preferences—this is where reinforcement learning becomes essential.")
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                }
                                
                                Divider()
                                    .background(Color.gray)
                                
                                // Second Paragraph
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("3. Reinforcement Learning")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    Text("Reinforcement Learning from Human Feedback (RLHF) is applied after fine-tuning to align the model with human values and expectations. First, the model generates multiple outputs for the same prompt, and human labelers rank these outputs from best to worst. These rankings are used to train a separate model called the reward model, which learns to predict how humans would rate new responses. The goal is to reward helpful, honest, and harmless (HHH) outputs and decrease harmful or unhelpful ones, essentially teaching the model human judgment at scale.\n\nOnce the reward model is trained, it’s used in a reinforcement learning loop to further fine-tune the main LLM. Using algorithms like Proximal Policy Optimization (PPO), the model is trained to maximize the reward signal predicted by the reward model. This process improves the assistant’s ability to stay on-topic, refuse unsafe requests, and avoid hallucinating false information. RLHF is what transforms a “smart” model into a “safe” one—ensuring it not only understands language and instructions, but responds in a way that’s aligned with human expectations. ")
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                }
                                //                                if UIDevice.current.userInterfaceIdiom == .pad {
                                //                                    Spacer()
                                //                                    .frame(height: 500)}
                            }
                            .padding(20)
                            
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white)
                                    .shadow(radius: 5)
                            )
                            .padding(.horizontal, 20)
                            
                            // Added space at bottom of iPads
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                Spacer()
                                    .frame(height:1500, alignment: .topLeading)
                            }
                            
                            if UIDevice.current.userInterfaceIdiom == .phone {
                                Spacer()
                                    .frame(height:1000, alignment: .topLeading)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                    .scrollDisabled(false)
                    
                }
                .edgesIgnoringSafeArea(.top)
            }
            
        }
        .tabItem {
            Image(systemName: "speedometer")
            Text("LLM Process")
        }
    }
}


