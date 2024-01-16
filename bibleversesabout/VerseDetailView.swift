import SwiftUI
import UIKit

struct VerseDetailView: View {
    var slug: String
    var name: String
    
    @State private var selectedTab = 0
    @State private var verseDetails: VerseDetails?
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Choose Version", selection: $selectedTab) {
                    Text("KJV").tag(0)
                    Text("ESV").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if let verseDetails = verseDetails {
                    List(verseDetails.verses, id: \.verse) { verse in
                        VStack(alignment: .leading) {
                            Text(verse.verse)
                                .font(.headline)
                            HTMLTextView(htmlString: selectedTab == 0 ? verse.kjv : verse.esv)
                                .frame(height: 100) // Adjust the height as needed
                        }
                    }
                }
            }
            .onAppear {
                fetchVerseDetails()
            }
            .navigationBarTitle(name, displayMode: .inline)
        }
    }
    
    func fetchVerseDetails() {
        if let url = URL(string: "http://localhost:3007/verses-json/\(slug).json") {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                } else if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let verseDetails = try decoder.decode(VerseDetails.self, from: data)
                        DispatchQueue.main.async {
                            self.verseDetails = verseDetails
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

struct VerseDetails: Decodable {
    let verses: [Verse]
}

struct Verse: Decodable {
    let verse: String
    let esv: String
    let kjv: String
}

struct HTMLTextView: UIViewRepresentable {
    let htmlString: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if let attributedString = htmlString.attributedStringFromHTML {
            uiView.attributedText = attributedString
        }
    }
}

extension String {
    var attributedStringFromHTML: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
