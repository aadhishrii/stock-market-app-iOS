import SwiftUI

struct NewsDetailModalView: View {
    let article: NewsArticle

    // Function to format the date
    func formattedDate(from unixTime: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unixTime))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        return dateFormatter.string(from: date)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text(article.source)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top)

                    Text(formattedDate(from: article.datetime))
                        .font(.subheadline)
                        .padding(.top)

                    Text(article.headline)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.vertical)

                    Text(article.summary)
                        .font(.body)
                        .padding(.bottom)

                    if let articleURL = URL(string: article.url) {
                        HStack {
                            Text("For more details click")
                            Text("here")
                                .underline()
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    UIApplication.shared.open(articleURL)
                                }
                        }
                        .padding(.bottom)
                    }

                    // Social Sharing Buttons HStack moved here
                    HStack {
                        // Facebook Share Button using external image
                        Button(action: {
                            shareOnFacebook(url: article.url)
                        }) {
                            AsyncImage(url: URL(string: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT2DxLE9XHPDHjBNQwyrGAJDR_uv4etRrNb0FG5VsGBCQ&s")) { image in
                                image.resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 60, height: 60) // Adjust size as needed
                            .foregroundColor(.blue)
                        }

                        // Twitter Share Button using external image
                        Button(action: {
                            shareOnTwitter(url: article.url, text: article.headline)
                        }) {
                            AsyncImage(url: URL(string: "https://img.freepik.com/premium-vector/new-twitter-logo-x-2023-twitter-x-logo-official-vector-download_691560-10797.jpg")) { image in
                                image.resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 60, height: 60) // Adjust size as needed
                            .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle(Text("News"), displayMode: .inline)
            .toolbar {
                Button("Close") {
                    // The dismiss action will go here
                }
            }
        }
    }

    // Helper functions for sharing
    private func shareOnFacebook(url: String) {
        if let url = URL(string: "https://www.facebook.com/sharer/sharer.php?u=\(encodeURIComponent(url))") {
            UIApplication.shared.open(url)
        }
    }

    private func shareOnTwitter(url: String, text: String) {
        if let url = URL(string: "https://twitter.com/intent/tweet?url=\(encodeURIComponent(url))&text=\(encodeURIComponent(text))") {
            UIApplication.shared.open(url)
        }
    }

    // URL encoding helper
    private func encodeURIComponent(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }
}

// Define a PreviewProvider for NewsDetailModalView
struct NewsDetailModalView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a sample article for the preview
        NewsDetailModalView(article: NewsArticle(category: "category",
                                                 datetime: 1714311840, // An example Unix timestamp
                                                 headline: "Example Headline",
                                                 id: 1,
                                                 image: "https://via.placeholder.com/150",
                                                 related: "AAPL",
                                                 source: "Example Source",
                                                 summary: "This is an example summary of the article.",
                                                 url: "https://www.example.com"
        ))
    }
}

