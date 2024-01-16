import SwiftUI
import UIKit
import WebKit

struct VerseDetailView: View {
    var slug: String
    var name: String
    
    @State private var selectedTab = 0
    @State private var verseDetails: VerseDetails?
        @State var height: CGFloat = .zero
    
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
//                            HTMLTextView(htmlString: selectedTab == 0 ? verse.kjv : verse.esv)
//                                .frame(height: 100) // Adjust the height as needed
                            WebViewHTMLContent(dynamicHeight: $height, htmlString: selectedTab == 0 ? verse.kjv : verse.esv)
                                            .frame(height: height)
                        }
                    }
                }
            }
            .onAppear {
                fetchVerseDetails()
            }
            .navigationBarTitle(name, displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
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

struct WebViewHTMLContent: UIViewRepresentable {
    @Binding var dynamicHeight: CGFloat
    let htmlString: String
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let htmlStart = """
        <html>
        <head>
            <meta name=\"viewport\" content=\"width=device-width,minimum-scale=1.0, maximum-scale=1.0\" />
            <style>
                @font-face {
                    font-family: 'NotoSans';
                    font-weight: normal;
                    src: url("NotoSans-Regular.ttf") format('truetype');
                }
                @font-face {
                    font-family: "NotoSans";
                    font-weight: bold;
                    src: url("NotoSans-Bold.ttf")
                }
                * {
                    font-family: 'NotoSans';
                    font-size: 14;
                    margin: 0;
                    padding: 0;
                }
                img {
                    display: inline;
                    height:auto;
                    max-width: 100%;
                }
            </style>
        </head>
        <body>
"""
        let htmlEnd = "</body></html>"
        uiView.loadHTMLString(htmlStart + htmlString + htmlEnd, baseURL: Bundle.main.bundleURL)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewHTMLContent
        init(_ parent: WebViewHTMLContent) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if webView.isLoading == false {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in
                        if complete != nil {
                            webView.evaluateJavaScript("document.documentElement.scrollHeight", completionHandler: { (height, error) in
                                if error == nil {
                                    guard let height = height as? CGFloat else { return }
                                    webView.frame.size.height = height
                                    self.parent.dynamicHeight = height
                                }
                            })
                        }
                        webView.sizeToFit()
                    })
                }
            }
        }
    }
}
       
////Example Usage
//struct VerseDetailView: View {
//    @State var height: CGFloat = .zero
//    let htmlContent = "<h1>My First Heading</h1><p>My first paragraph.</p>"
//
//    var body: some View {
//        VStack {
//            WebViewHTMLContent(dynamicHeight: $height, htmlString: htmlContent)
//                .frame(height: height)
//        }
//    }
//}
