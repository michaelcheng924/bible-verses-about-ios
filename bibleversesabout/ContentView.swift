//
//  ContentView.swift
//  bibleversesabout
//
//  Created by Michael Cheng on 1/16/24.
//

import SwiftUI

struct ContentView: View {
    @State private var verses: [VerseData] = [] // Store the fetched data
    @State private var searchText = ""
    @State private var selectedVerse: VerseData? // Store the selected verse

    var filteredVerses: [VerseData] {
        if searchText.isEmpty {
            return verses
        } else {
            return verses.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                Text("Bible Verses About")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Lists of Bible verses about thousands of topics")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("Search Bible Verses", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                List(filteredVerses, id: \.slug) { verse in
                    NavigationLink(destination: VerseDetailView(slug: verse.slug, name: verse.name)) {
                        Text(verse.name)
                    }
                }
            }
            .onAppear {
                fetchBibleVerseData()
            }
            .navigationBarTitle("", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func fetchBibleVerseData() {
//        if let url = URL(string: "https://bible-verses-about.vercel.app/slugs-name.json") {
        if let url = URL(string: "http://localhost:3007/slugs-name.json") {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                } else if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let verses = try decoder.decode([VerseData].self, from: data)
                        // Update the @State variable with fetched data
                        DispatchQueue.main.async {
                            self.verses = verses
                        }
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                }
            }
            task.resume()
        }
    }
}

struct VerseData: Decodable {
    let slug: String
    let name: String
}

#Preview {
    ContentView()
}
