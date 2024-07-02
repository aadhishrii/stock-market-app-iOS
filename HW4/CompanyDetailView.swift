import SwiftUI
import Foundation
import WebKit

//struct HighchartsWebView: UIViewRepresentable {
//    var ticker: String
//    var htmlFilename: String
//    
//    func makeUIView(context: Context) -> WKWebView {
//        let webView = WKWebView()
//        if let filePath = Bundle.main.path(forResource: htmlFilename, ofType: "html") {
//            let fileURL = URL(fileURLWithPath: filePath)
//            webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
//        } else {
//            print("Failed to find charts.html file")
//        }
//        return webView
//    }
//
//    func updateUIView(_ uiView: WKWebView, context: Context) {
//        // Ensure the ticker is being updated whenever the view updates
//        let script = "fetchData('\(ticker)');"
//        uiView.evaluateJavaScript(script) { (result, error) in
//            if let error = error {
//                print("Error executing JavaScript: \(error.localizedDescription)")
//            }
//        }
//    }
//}
struct HighchartsWebView: UIViewRepresentable {
    var ticker: String
    var htmlFilename: String
    var key: Int

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        loadChart(webView: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        loadChart(webView: uiView)
    }

    private func loadChart(webView: WKWebView) {
            if let filePath = Bundle.main.path(forResource: htmlFilename, ofType: "html") {
                let baseUrl = URL(fileURLWithPath: filePath)
                let urlWithTicker = URL(string: "?ticker=\(ticker)", relativeTo: baseUrl)
                webView.loadFileURL(urlWithTicker!, allowingReadAccessTo: baseUrl.deletingLastPathComponent())
            } else {
                print("Failed to find \(htmlFilename).html file")
            }
        }
}

struct CompanyDetailView: View {
    let displaySymbol: String
    @State private var companyMetadata: CompanyMetadata?
    @State private var latestPrice: LatestPrice?
    @State private var isLoadingMetadata: Bool = false
    @State private var isLoadingPrice: Bool = false
    @State private var errorMessage: String?
    @State private var isLoadingNews: Bool = false
    @State private var news:[NewsArticle]?
    @State private var insiderTradingData: InsiderTradingData?
    @State private var selectedArticle: NewsArticle?
    @State private var showingNewsDetail = false
    @State private var isShowingTradeView = false
    @State private var chartData: String = ""
    @State var stocks: [PortfolioStock] = []
    @State private var htmlFilename: String = "charts"
    @State private var selectedIndex: Int = 1
    @State private var key: Int = 1 // Initialize with a unique key
    @State private var peers = [String]()
    @State private var favoriteStocks: [FavoriteStock] = []
    @State private var isToastShowing = false
    @State private var toastMessage = ""


    // Computed property to extract the display symbol
    var extractedDisplaySymbol: String {
        let components = displaySymbol.components(separatedBy: "-")
        if let firstComponent = components.first {
            return firstComponent.trimmingCharacters(in: .whitespaces)
        } else {
            return displaySymbol
        }
    }

    var body: some View {
        NavigationView {
            ScrollView{
                VStack {
                    if isLoadingMetadata || isLoadingPrice {
                        ProgressView("Loading...")
                    } else if let metadata = companyMetadata, let price = latestPrice, let insiderData = insiderTradingData, let newsData = news {
                        VStack {
                            HStack{
                                Text("\(metadata.name)")
                                    .padding(.horizontal)
                                    .padding(.bottom)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            HStack {
                                       // Current Price
                                       Text(String(format: "$%.2f", price.c))
                                           .font(.title)
                                           .bold()
                                           .padding(.horizontal)

                                       // Arrow indicating direction of change
                                       Image(systemName: price.d >= 0 ? "arrow.up" : "arrow.down")
                                           .foregroundColor(price.d >= 0 ? .green : .red)
                                           .font(.title3) // Ensure the arrow scales appropriately

                                       // Dollar Change
                                       Text(String(format: "$%.2f", abs(price.d)))
                                           .font(.title3)
                                           .foregroundColor(price.d >= 0 ? .green : .red)

                                       // Percent Change
                                       Text(String(format: "(%.2f%%)", abs(price.dp)))
                                           .font(.title3)
                                           .foregroundColor(price.d >= 0 ? .green : .red)

                                       Spacer()
                                   }
                        }
                        
                            Section(){
//                                HighchartsWebView(ticker: chartData, htmlFilename: "charts")
//                                    .frame(height: 150)
//                                Picker("Select Chart", selection: $htmlFilename) {
//                                                            Text("Hourly").tag("charts3")
//                                                            Text("Historical").tag("charts")
//                                                        }
//                                                        .pickerStyle(SegmentedPickerStyle())
//                                                        .padding()
//
//                                                        HighchartsWebView(ticker: chartData, htmlFilename: htmlFilename)
//                                                            .frame(height: 300)
                                
                                VStack {
                                    
                                    Text("\(metadata.ticker) \(selectedIndex == 1 ? "Historical" : "Hourly Price Variation")")
                                                    .font(.title)
                                                    .fontWeight(.bold)
                                                    .frame(maxWidth: .infinity, alignment: .center)
                                                    .padding()
                                           // Your HighchartsWebView might look like this
                                           HighchartsWebView(ticker: "chartData", htmlFilename: htmlFilename, key: key)
                                               .frame(height: 350)

                                           // Custom segmented control
                                           HStack {
                                               ForEach(0..<2) { index in
                                                   VStack {
                                                       Image(systemName: index == 0 ? "clock" : "calendar")
                                                           .font(.system(size: 16))
                                                       Text(index == 0 ? "Hourly" : "Historical")
                                                           .font(.system(size: 12))
                                                   }
                                                   .padding(.vertical, 10)
                                                   .padding(.horizontal, 20)
                                                   .foregroundColor(selectedIndex == index ? .white : .blue)
                                                   .background(selectedIndex == index ? Color.blue : Color.white)
                                                   .cornerRadius(8)
                                                   .overlay(
                                                       RoundedRectangle(cornerRadius: 8)
                                                           .stroke(Color.blue, lineWidth: 1)
                                                   )
                                                   .onTapGesture {
                                                       self.selectedIndex = index
                                                       switch index {
                                                       case 0:
                                                           self.htmlFilename = "charts3" // Hourly
                                                           self.key = 0
                                                       case 1:
                                                           self.htmlFilename = "charts" // Historical
                                                           self.key = 1
                                                       default:
                                                           break
                                                       }
                                                   }
                                               }
                                           }
                                           .frame(maxWidth: .infinity)
                                           .padding(.horizontal)

                                           Spacer()
                                       }
                            }
                            .padding()
                        
                        Section(header: Text("Portfoilio")){
                            HStack{
                                VStack{
                                    if let stock = stocks.first(where: { $0.ticker == extractedDisplaySymbol }) {
                                                    VStack(alignment: .leading) {
                                                        HStack{
                                                            Text("Shares Owned:").bold()
                                                            Text("\(stock.quantity)")
                                                        }
                                                        HStack{
                                                            Text("Avg. Cost/Share:").bold()
                                                            if stock.quantity != 0 {
                                                                let avg = (stock.totalCost / Double(stock.quantity))
                                                                Text(String(format: "%.2f", Double(avg)))
                                                            } else {
                                                                Text("Undefined") // or handle the zero quantity case differently
                                                            }                                                        }
                                                        HStack{
                                                            Text("Total Cost:").bold()
                                                            Text(String(format: "%.2f", Double(stock.totalCost)))
                                                        }
                                                        HStack{
                                                            Text("Change:").bold()
                                                            if stock.quantity != 0 {
                                                                let chng = price.c - (stock.totalCost / Double(stock.quantity))
                                                        Text(String(format: "%.2f", Double(chng)))
                                                            }
                                                        }
                                                        HStack{
                                                            Text("Market Value:").bold()
                                                            Text(String(format: "%.2f", Double(price.c)))
                                                        }
                                                        
                                                    }
                                                    .padding()
                                                } else {
                                                    Text("You have 0 shares of \(extractedDisplaySymbol). Start Trading!")
                                                }
                                }
                                VStack{
                                    Button(action: {
                                        // Action to perform when the button is tapped
                                        isShowingTradeView = true
                                    }) {
                                        Text("Trade")
                                            .foregroundColor(.white)
                                            .padding()
                                            .frame(maxWidth:.infinity)
                                            .background(Color.green)
                                            .cornerRadius(25)
                                    }.frame(width:120)
                                    .sheet(isPresented: $isShowingTradeView) {
                                        TradePopupView(symbol: metadata.name, ticker: extractedDisplaySymbol,isPresented:$isShowingTradeView, latestPrice: price.c)
                                    }
                                }
                            }
                        }
                        .padding()
                        Section(header: Text("Stats")){
                            HStack{
                                VStack(alignment: .leading){
                                    HStack{
                                        Text("High Price:")
                                        Text(String(format: "$%.2f", abs(price.d)))
                                            .foregroundColor(.gray)
                                    }
                                    HStack{
                                        Text("Low Price:")
                                        Text(String(format: "$%.2f", abs(price.l)))
                                            .foregroundColor(.gray)
                                    }
                                }
                                VStack(alignment: .leading){
                                    HStack{
                                        Text("Open Price:")
                                        Text(String(format: "$%.2f", abs(price.o)))
                                            .foregroundColor(.gray)
                                    }
                                    HStack{
                                        Text("Prev Price:")
                                        Text(String(format: "$%.2f", abs(price.pc)))
                                            .foregroundColor(.gray)
                                    }
                                    
                                }
                            }
                        }
                        Section(header: Text("About")){
                            HStack{
                                VStack(alignment: .leading){
                                    Text("IPO Start Date:")
                                        .bold()
                                    Text("Industry:")
                                        .bold()
                                    Text("Webpage:")
                                        .bold()
                                    Text("Company Peers:")
                                        .bold()
                                    
                                }
                                VStack(alignment: .leading){
                                    
                                    Text("\(metadata.ipo)")
                                        .foregroundColor(.gray)
                                    Text("\(metadata.finnhubIndustry)")
                                        .foregroundColor(.gray)
                                    Button(action: {
                                        // Open the URL when the button is tapped
                                        if let url = URL(string: metadata.weburl) {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Text("\(metadata.weburl)")
                                    }
                                    ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack(spacing: 20) {
                                                        ForEach(peers, id: \.self) { peer in
                                                            NavigationLink(destination: CompanyDetailView(displaySymbol: "\(peer) - AAPLE ISSPORT")) {
                                                                                Text(peer)
                                                                                
                                                            }
                                                            
                                                        }
                                                    }
                                                    .padding(.horizontal)
                                                }
                                                .frame(height: 50)
                                }
                                
                            }
                        }.padding()
                        Section(header: Text("Insider")) {
                            VStack(spacing: 10) {
                                
                                
                                Text("Insider Sentiments").bold()
                                HStack {
                                    VStack{
                                        Text("Apple Inc").bold()
                                        Divider()
                                    }
                                    Spacer()
                                    VStack {
                                        Text("MSPR").bold()
                                        Divider() // Horizontal divider for the header
                                    }
                                    Spacer()
                                    VStack {
                                        Text("Change").bold()
                                        Divider() // Horizontal divider for the header
                                    }
                                }
                                HStack {
                                    VStack{
                                        Text("Total")
                                        Divider()
                                    }
                                    Spacer()
                                    VStack{
                                        Text(insiderData.msprAggregate)
                                        Divider()
                                    }
                                    Spacer()
                                    VStack{
                                        Text(insiderData.totalChange.formatted())
                                        Divider()
                                    }
                                }
                                HStack {
                                    VStack{
                                        Text("Positive")
                                        Divider()
                                    }
                                    Spacer()
                                    VStack{
                                        Text(insiderData.positivemspr)
                                        Divider()
                                    }
                                    Spacer()
                                    VStack{
                                        Text(insiderData.positiveChange.formatted())
                                        Divider()
                                    }
                                }
                                
                                HStack {
                                    VStack{
                                        Text("Negative")
                                        Divider()
                                    }
                                    Spacer()
                                    VStack{
                                        Text(insiderData.negativemspr)
                                        Divider()
                                    }
                                    Spacer()
                                    VStack{
                                        Text(insiderData.negativeChange.formatted())
                                        Divider()
                                    }
                                }
                            }.padding()
                        }
                        Section(header: Text("").bold()){
                            HighchartsWebView(ticker: chartData, htmlFilename: "charts2", key: key)
                                .frame(height: 750)
                            
                        }
//                        Section(header: Text("Historical EPS Surprises").bold()){
//                      
//                        }
                        Section(header: Text("News")){
                            ForEach(newsData.indices, id: \.self) { index in
                                let article = newsData[index]
                                VStack(alignment: .leading, spacing: 8) {
                                            if index == 0 {
                                                if let imageUrl = URL(string: article.image), let imageData = try? Data(contentsOf: imageUrl), let uiImage = UIImage(data: imageData) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(height: 200) // Adjust the height of the first image
                                                        .clipped()
                                                        .cornerRadius(8)
                                                } else {
                                                    Rectangle()
                                                        .fill(Color.secondary)
                                                        .frame(height: 200) // Adjust the height of the first image
                                                        .cornerRadius(8)
                                                }
                                            }
                                    HStack(alignment: .top) {
                                        if index != 0 {
                                            if let imageUrl = URL(string: article.image), let imageData = try? Data(contentsOf: imageUrl), let uiImage = UIImage(data: imageData) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 80, height: 60)
                                                    .clipped()
                                                    .cornerRadius(8)
                                            } else {
                                                Rectangle()
                                                    .fill(Color.secondary)
                                                    .frame(width: 80, height: 60)
                                                    .cornerRadius(8)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(article.source)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            Text(article.headline)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                                .lineLimit(3)
                                            
                                            Text(timeAgoSinceUnix(article.datetime))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    }.onTapGesture {
                                        self.selectedArticle = article
                                        self.showingNewsDetail = true
                                    }
                                    .padding(.horizontal)
                                }
                        }.padding(.vertical)
                            .sheet(isPresented: $showingNewsDetail, onDismiss: {
                                        self.selectedArticle = nil
                                    }) {
                                        // Ensure that the sheet content is not optional
                                        if let article = selectedArticle {
                                            NewsDetailModalView(article: article)
                                        }
                                    }
                        
                        // Display more metadata properties as needed
                        
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                    }
                    Spacer()
                }.overlay(
                    VStack {
                        
                        ToastView(message: toastMessage, isShowing1: $isToastShowing)
                        Spacer()
                    }
                )
                
            }
            .navigationTitle(companyMetadata?.ticker ?? "")
            .onAppear {
                    fetchCompanyMetadata()
                    fetchLatestPrice()
                    fetchInsiderTradingData()
                    fetchNews()
                    fetchChartData()
                    fetchStocks()
                fetchFavoriteStocks()
                fetchPeers(forTicker: extractedDisplaySymbol)
                }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Handle button tap
                        if let stock = favoriteStocks.first(where: { $0.ticker == extractedDisplaySymbol }) {
                            showToast(message: "Removing \(extractedDisplaySymbol) to Favorites")
                        }
                        else{
                            showToast(message: "Adding \(extractedDisplaySymbol) to Favorites")
                        }
                        
                        addToWatchlist(ticker:extractedDisplaySymbol) { result in
                                switch result {
                                case .success(let message):
                                    print("Success: \(message)")
                                    // Handle success
                                case .failure(let error):
                                    print("Error: \(error)")
                                    // Handle error
                                }
                            }
                    }) {
                        if let stock = favoriteStocks.first(where: { $0.ticker == extractedDisplaySymbol }) {
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2) // Blue border
                                    .frame(width: 25, height: 25) // Adjust circle size as needed
                                    .background(Circle().fill(Color.blue))
                                Text("+")
                                    .font(.title)
                                    .foregroundColor(.white) // Blue plus sign
                                    .frame(width: 15, height: 15)
                            }
                        }else{
                            ZStack {
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2) // Blue border
                                    .frame(width: 25, height: 25) // Adjust circle size as needed
                                
                                Circle()
                                    .fill(Color.white) // White circle inside
                                    .frame(width: 20, height: 20) // Adjust size to leave room for border
                                
                                Text("+")
                                    .font(.title)
                                    .foregroundColor(.blue) // Blue plus sign
                                    .frame(width: 15, height: 15)
                            }
                        }
                    }
                    
                }
            }
            
            
            
        }
    }
    private func showToast(message: String) {
            toastMessage = message
            isToastShowing = true
        }
    private func fetchFavoriteStocks() {
            guard let url = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/watchlist") else {
                print("Invalid URL for watchlist")
                return
            }

            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error fetching favorite stocks:", error)
                    return
                }
                if let data = data {
                    do {
                        let favorites = try JSONDecoder().decode([FavoriteStock].self, from: data)
                        DispatchQueue.main.async {
                            self.favoriteStocks = favorites
                            
                        }
                    } catch {
                        print("Error decoding favorite stocks:", error)
                    }
                }
            }.resume()
        }
    func timeAgoSinceUnix(_ unixTimestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unixTimestamp))
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: date, to: now)

        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        if hour > 0 {
            return "\(hour) hr, \(minute) min"
        } else {
            return "\(minute) min"
        }
    }
    func fetchPeers(forTicker ticker: String) {
            guard let url = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/peers/\(ticker)") else {
                print("Invalid URL")
                return
            }

            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error fetching data: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    print("No data received")
                    return
                }

                if let decodedResponse = try? JSONDecoder().decode([String].self, from: data) {
                    DispatchQueue.main.async {
                        self.peers = decodedResponse
                    }
                } else {
                    print("Failed to decode response")
                }
            }

            task.resume()
        }
    func fetchStocks() {
        guard let url = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/portfolio") else {
            print("Invalid URL for portfolio")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching stocks:", error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Unexpected response status code:", response ?? "No response")
                return
            }
            if let data = data {
                do {
                    let fetchedStocks = try JSONDecoder().decode([PortfolioStock].self, from: data)
                    DispatchQueue.main.async {
                        self.stocks = fetchedStocks// Fetch details for all stocks
                        print(self.stocks)
                    }
                } catch {
                    print("Error decoding portfolio stocks:", error)
                }
            }
        }
        task.resume()
        }
    func addToWatchlist(ticker: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Define the URL
        let urlString = "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/watchlistpost"

        // Create the URL object
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1, userInfo: nil)))
            return
        }

        // Create the data to send in the request body
        let tickerData = ["ticker": ticker]

        do {
            // Convert data to JSON format
            let jsonData = try JSONSerialization.data(withJSONObject: tickerData, options: [])

            // Create the request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            // Create and start a URLSession data task
            URLSession.shared.dataTask(with: request) { data, response, error in
                // Check for errors
                if let error = error {
                    completion(.failure(error))
                    return
                }

                // Check the response status code
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(NSError(domain: "InvalidResponse", code: -1, userInfo: nil)))
                    return
                }

                // Handle the response data if needed
                if let data = data {
                    // Parse and use the response data
                    do {
                        let responseString = String(data: data, encoding: .utf8) ?? ""
                        completion(.success(responseString))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }.resume() // Resume the data task
        } catch {
            completion(.failure(error))
        }
    }

    
    func fetchChartData() {
            let today = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let formattedDate = formatter.string(from: today)
            guard let url = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/histcharts/\(extractedDisplaySymbol)/date/\(formattedDate)") else { return }

            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self.chartData = jsonString
                        }
                    }
                }
            }.resume()
        }
    
    func fetchCompanyMetadata() {
        isLoadingMetadata = true
        guard let metadataURL = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/metadata/\(extractedDisplaySymbol)") else {
            errorMessage = "Invalid metadata URL"
            isLoadingMetadata = false
            return
        }
        
        let task = URLSession.shared.dataTask(with: metadataURL) { data, response, error in
            DispatchQueue.main.async {
                isLoadingMetadata = false
                if let error = error {
                    errorMessage = "Error fetching metadata: \(error.localizedDescription)"
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    errorMessage = "Unexpected metadata response: \(response?.description ?? "No response")"
                    return
                }
                guard let data = data else {
                    errorMessage = "No metadata received"
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    companyMetadata = try decoder.decode(CompanyMetadata.self, from: data)
                } catch {
                    errorMessage = "Error decoding company metadata: \(error.localizedDescription)"
                }
            }
        }
        task.resume()
    }
    
    func fetchInsiderTradingData() {
           isLoadingMetadata = true
           guard let url = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/insider/\(extractedDisplaySymbol)") else {
               errorMessage = "Invalid insider data URL"
               isLoadingMetadata = false
               return
           }
           let task = URLSession.shared.dataTask(with: url) { data, response, error in
               DispatchQueue.main.async {
                   isLoadingMetadata = false
                   if let error = error {
                       errorMessage = "Error fetching insider data: \(error.localizedDescription)"
                       return
                   }
                   guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                       errorMessage = "Unexpected insider data response: \(response?.description ?? "No response")"
                       return
                   }
                   guard let data = data else {
                       errorMessage = "No insider data received"
                       return
                   }
                   do {
                       let decoder = JSONDecoder()
                       insiderTradingData = try decoder.decode(InsiderTradingData.self, from: data)
                   } catch {
                       errorMessage = "Error decoding insider data: \(error.localizedDescription)"
                   }
               }
           }
           task.resume()
       }

    func fetchLatestPrice() {
        isLoadingPrice = true
        guard let priceURL = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/latestprice/\(extractedDisplaySymbol)") else {
            errorMessage = "Invalid price URL"
            isLoadingPrice = false
            return
        }
        
        let task = URLSession.shared.dataTask(with: priceURL) { data, response, error in
            DispatchQueue.main.async {
                isLoadingPrice = false
                if let error = error {
                    errorMessage = "Error fetching latest price: \(error.localizedDescription)"
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    errorMessage = "Unexpected price response: \(response?.description ?? "No response")"
                    return
                }
                guard let data = data else {
                    errorMessage = "No price data received"
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    latestPrice = try decoder.decode(LatestPrice.self, from: data)
                } catch {
                    errorMessage = "Error decoding latest price: \(error.localizedDescription)"
                }
            }
        }
        task.resume()
    }
    

    func fetchNews() {
        isLoadingNews = true
        guard let newsURL = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/news/\(extractedDisplaySymbol)") else {
            errorMessage = "Invalid news URL"
            isLoadingNews = false
            return
        }

        let task = URLSession.shared.dataTask(with: newsURL) { data, response, error in
            DispatchQueue.main.async {
                isLoadingNews = false
                if let error = error {
                    errorMessage = "Error fetching news: \(error.localizedDescription)"
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    errorMessage = "Unexpected news response: \(response?.description ?? "No response")"
                    return
                }
                guard let data = data else {
                    errorMessage = "No news data received"
                    return
                }
                do {
                    // Decode the data into the correct structure
                    if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
                        var articles = [NewsArticle]()
                        for element in jsonArray {
                            // Assume each element in the array is itself an array where the second item is a dictionary
                            if let elementArray = element as? [Any], let articleDict = elementArray[1] as? [String: Any] {
                                let jsonData = try JSONSerialization.data(withJSONObject: articleDict)
                                let newsArticle = try JSONDecoder().decode(NewsArticle.self, from: jsonData)
                                articles.append(newsArticle)
                            }
                        }
                        // Take the first 10 articles
                        self.news = Array(articles.prefix(10))
                    }
                    else {
                        self.errorMessage = "Error decoding news: JSON structure did not match expected format."
                    }
                }
                    catch {
                    errorMessage = "Error decoding news: \(error.localizedDescription)"
                }
            }
        }
        task.resume()
    }
}

struct TradePopupView: View {
    var symbol: String
    var ticker: String
    @Binding var isPresented: Bool
    var latestPrice: Double
    @State private var quantityText = ""
    @State private var totalPrice = "0.00"
    @State private var isLoading = false
    @State private var isLoading1 = false
    @State private var walletBalance: WalletBalance?
    @State private var isToastShowing = false
        @State private var toastMessage = ""
    @State var stocks: [PortfolioStock] = []
    @State private var isShowingCongratulationSheet = false
    @State private var congratulationMessage = "message"
    @State private var isSell = false
    
    var body: some View {
        NavigationStack{
            VStack{
                Text("Trade \(symbol) shares")
                Spacer()
                HStack{
                    TextField("0", text: $quantityText)
                        .onChange(of: quantityText) { newValue in
                            updateTotal()
                        }
                        .keyboardType(.decimalPad)  // Use decimal pad for numeric input
                        // Padding inside the TextField for better touch area
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)  // Optional: Add rounded corner
                            .stroke(Color.gray.opacity(0.5), lineWidth: 0)  // Light gray stroke to subtly indicate the area
                        )
                        .font(.system(size: 85))
                        .padding(.horizontal)
                    
                    Text("Shares")
                        .font(.title)
                        .padding()
                }
                HStack {
                    Spacer() // Pushes the content to the right
                    Text("X $\(latestPrice)/share = $\(totalPrice)")
                        .padding()
                }
                Spacer()
                HStack{
                    if let balance = walletBalance {
                        Text("$\(balance.balance , specifier: "%.2f") available to buy \(ticker)")
                    }
                }
               
                HStack {
                    
                    Button(action: {
                        // Action for buy button
                        if validateInput() {
                                                // Action for sell button
                            if let balance = walletBalance?.balance {
                                if let tp = Double(totalPrice){
                                        if(tp>balance){
                                            showToast(message: "Not enough money to buy")
                                        }else{
                                            
                                        }
                                    buyStock()
                                    isSell = false
                                    
                                    // Present the congratulation sheet
                                    isShowingCongratulationSheet = true
                                    
                                }
                            }
                        }else if let q = Int(quantityText){
                            if q <= 0{
                                showToast(message: "Cannot buy non-positive shares")
                            }
                            
                        }
                        else {
                                                showToast(message: "Please enter a valid amount")
                                            }
                    }) {
                        Text("Buy")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth:.infinity)
                            .background(Color.green)
                            .cornerRadius(25)
                    }
                    .sheet(isPresented: $isShowingCongratulationSheet) {
                        CongratulationSheetView(message: "\(ticker)", isShowingCongratulationSheet: $isShowingCongratulationSheet, isPresented: $isPresented,quantity: $quantityText, isSell: $isSell)
                    }
                    Button(action: {
                        // Action for sell button
                        if validateInput() {
                                                // Action for sell button
                            if let stock = stocks.first(where: { $0.ticker == ticker }) {
                                if let qt = Int(quantityText){
                                    if (stock.quantity < qt){
                                        showToast(message: "Not enough shares to sell")
                                    }
                                    else{
                                        sellStock()
//                                        congratulationMessage = "You've successfully sold \(qt) shares of
                                        isSell = true
                                        // Present the congratulation sheet
                                        isShowingCongratulationSheet = true
                                    }
                                    
                                }
                            }
                            else {
                                    showToast(message: "Not enough shares to sell")
                                }
                            
                                            }
                        else if let q = Int(quantityText){
                            if q <= 0{
                                showToast(message: "Cannot sell non-positive shares")
                            }
                            
                        }
                        else {
                                                showToast(message: "Please enter a valid amount")
                                            }
                    }) {
                        Text("Sell")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth:.infinity)
                            .background(Color.green)
                            .cornerRadius(25)
                    }
                    .sheet(isPresented: $isShowingCongratulationSheet) {
                        CongratulationSheetView(message: "\(ticker)", isShowingCongratulationSheet: $isShowingCongratulationSheet, isPresented: $isPresented,quantity: $quantityText, isSell: $isSell)
                    }
                }.padding()
                .toolbar {
                    Button("X") {
                        // The dismiss action will go here
                        isPresented = false
                    }
                }
                .overlay(
                            VStack {
                                
                                ToastView(message: toastMessage, isShowing1: $isToastShowing)
                                Spacer()
                            }
                        )
            }.onAppear {
                fetchWalletBalance()
                fetchStocks()
            }
        }
    }
    private func sellStock() {
            guard validateInput() else {
                showToast(message: "Please check your input values.")
                return
            }

            if let totalP = Double(totalPrice), let quantity = Int(quantityText) {
                if let currentBalance = walletBalance?.balance {
                    let newBalance = currentBalance + totalP
                    updateWalletBalance(newBalance: newBalance)
                }
                let postData = StockPurchase(ticker: ticker, totalCost: totalP, quantity: quantity, isBuy: false)
                postStockData(postData: postData)
            } else {
                showToast(message: "Invalid total price or quantity.")
            }
        }
    private func buyStock() {
            guard validateInput() else {
                showToast(message: "Please check your input values.")
                return
            }

            if let totalP = Double(totalPrice), let quantity = Int(quantityText) {
                if let balance = walletBalance?.balance, totalP > balance {
                    showToast(message: "Not enough money to buy")
                    return
                }
                if let currentBalance = walletBalance?.balance {
                    let newBalance = currentBalance - totalP
                    updateWalletBalance(newBalance: newBalance)
                }
                let postData = StockPurchase(ticker: ticker, totalCost: totalP, quantity: quantity, isBuy: true)
                postStockData(postData: postData)
            } else {
                showToast(message: "Invalid total price or quantity.")
            }
        }
    private func updateWalletBalance(newBalance: Double) {
        guard let url = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/walletupdate") else {
            print("Invalid URL for wallet update")
            return
        }

        let walletData: [String: Any] = ["balance": newBalance]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: walletData, options: [])
        } catch {
            print("Error encoding wallet data:", error)
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error updating wallet balance:", error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Unexpected response status code:", response ?? "No response")
                return
            }
            print("Wallet balance updated successfully")
        }
        task.resume()
    }

    private func postStockData(postData: StockPurchase) {
            guard let url = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/portfolio") else {
                print("Invalid URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                request.httpBody = try JSONEncoder().encode(postData)
            } catch {
                print("Failed to encode data:", error)
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error during URLSession data task:", error)
                    return
                }
                
                if let data = data, let response = try? JSONDecoder().decode(PostResponse.self, from: data) {
                    print(response.message)  // Process the response message
                } else {
                    print("Failed to decode response or no data.")
                }
            }.resume()
        }
    func fetchStocks() {
        guard let url = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/portfolio") else {
            print("Invalid URL for portfolio")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching stocks:", error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Unexpected response status code:", response ?? "No response")
                return
            }
            if let data = data {
                do {
                    let fetchedStocks = try JSONDecoder().decode([PortfolioStock].self, from: data)
                    DispatchQueue.main.async {
                        self.stocks = fetchedStocks// Fetch details for all stocks
                        print(self.stocks)
                    }
                } catch {
                    print("Error decoding portfolio stocks:", error)
                }
            }
        }
        task.resume()
        }
    func validateInput() -> Bool {
            guard let quantity = Double(quantityText) else { return false }
            return quantity > 0
        }
    private func showToast(message: String) {
            toastMessage = message
            isToastShowing = true
        }
    func updateTotal() {
            if let quantity = Double(quantityText) {
                totalPrice = String(format: "%.2f", quantity * latestPrice)
            }
        }
    func fetchWalletBalance() {
            guard let url = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/wallet") else { return }
            
            isLoading = true
            URLSession.shared.dataTask(with: url) { data, response, error in
                defer { isLoading = false }
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let walletBalance = try decoder.decode(WalletBalance.self, from: data)
                        DispatchQueue.main.async {
                            self.walletBalance = walletBalance
                        }
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                }
            }.resume()
        }
}
struct CongratulationSheetView: View {
    let message: String
    @Binding var isShowingCongratulationSheet : Bool
    @Binding var isPresented: Bool
    
    @Binding var quantity: String
    @Binding var isSell: Bool
    
    var body: some View {
        ZStack {
            Color.green.edgesIgnoringSafeArea(.all)
            VStack {
                Text("Congratulations!")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                var msg = ""
                if isSell{
                    Text("You have successfully sold \(quantity) shares of \(message)")
                        .foregroundColor(.white)
                        .padding()
                }else{
                    Text("You have successfully bought \(quantity) shares of \(message)")
                        .foregroundColor(.white)
                        .padding()
                }
               
                    
                
                Button("Done") {
                    // Action for Done button
                    isShowingCongratulationSheet = false
                    isPresented = false
                }
                .padding()
                .foregroundColor(.green)
                .background(Color.white)
                .cornerRadius(10)
            }.padding()
        }
    }
}

struct ToastView: View {
    let message: String
    @Binding var isShowing1: Bool
    

    var body: some View {
        Text(message)
            .padding()
            .foregroundColor(.white)
            .background(Color.gray.opacity(0.8))
            .cornerRadius(10)
            .opacity(isShowing1 ? 1 : 0)
            .animation(.easeInOut(duration: 0.3))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    print("execute")
                    isShowing1 = false
                }
            }
    }
}


struct StockPurchase: Codable {
    let ticker: String
    let totalCost: Double
    let quantity: Int
    let isBuy: Bool
}

struct CompanyMetadata: Decodable {
    let name: String
    let exchange: String
    let finnhubIndustry: String
    let ticker: String
    let ipo: String
    let weburl: String
    // Add more metadata properties as needed
}
struct PostResponse: Codable {
    let message: String
}

struct LatestPrice: Decodable {
    let c: Double // Current price
    let d: Double
    let dp: Double
    let h: Double
    let l: Double
    let o: Double
    let pc: Double
    // Add more price properties as needed
}

struct NewsArticle: Decodable {
    let category: String
    let datetime: Int
    let headline: String
    let id: Int
    let image: String
    let related: String
    let source: String
    let summary: String
    let url: String
}

struct InsiderTradingData: Decodable {
    let positiveChange: Int
    let negativeChange: Int
    let totalChange: Int
    let positivemspr: String
    let negativemspr: String
    let msprAggregate: String
}

struct WalletBalance: Decodable {
    let balance: Double
}

struct Article {
    var datetime: Int
}

struct CompanyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CompanyDetailView(displaySymbol: "TSLA - AAPLE ISSPORT") // Pass sample display symbol for preview
    }
}


