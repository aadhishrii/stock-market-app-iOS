import SwiftUI
import Combine

struct PortfolioStock: Decodable, Identifiable {
    let id = UUID()  // Add a unique identifier for SwiftUI List
    let _id: String
    let ticker: String
    let totalCost: Double
    let quantity: Int
    var currentPrice: Double?  // Current price to be fetched
    var change: Double?        // Change to be fetched
    var changePercentage: Double? // Change percentage to be fetched
}

struct StockDetail: Decodable {
    let c: Double // Current price
    let d: Double // Change
    let dp: Double // Change percentage
}

struct FavoriteStock: Decodable, Identifiable {
    let id: String
    let ticker: String
    // Define coding keys to map the JSON keys to your struct's properties
        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case ticker
        }
}
struct ContentView: View {
    @ObservedObject private var searchTextObserver = SearchTextObserver()
    @State private var autoCompleteResults: [String] = [];
    @State private var autoCompleteCancellable: AnyCancellable?
    @State private var cashBalance: Double = 0.0 // Will be updated from the API
    @State private var stocks: [PortfolioStock] = []  // Store the stocks from the API
    @State private var stockDetails = [String: StockDetail]()
    @State private var favoriteStocks: [FavoriteStock] = []
    @State private var isEditing = false
    @State private var editMode: EditMode = .inactive
    @State private var selectedTicker: String?
    @State private var mark: Double = 0.0
    @State private var isAuto = false
    
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        return formatter
    }()
    
    private func fetchAutoCompleteResults(for searchString: String) {
        let autoCompleteURL = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/searchutil/\(searchString)")!
        let task = URLSession.shared.dataTask(with: autoCompleteURL) { data, response, error in
            if let error = error {
                print("Error fetching autocomplete results:", error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Unexpected response:", response ?? "No response")
                return
            }
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let results = try decoder.decode([Company].self, from: data)
                    DispatchQueue.main.async {
                        self.autoCompleteResults = results.map { "\($0.displaySymbol) - \($0.description)" }
                    }
                } catch {
                    print("Error decoding autocomplete results:", error)
                }
            }
        }
        task.resume()
    }
    
    private func fetchCashBalance() {
        guard let url = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/wallet") else {
            print("Invalid URL")
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching cash balance:", error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Unexpected response:", response ?? "No response")
                return
            }
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(Balance.self, from: data)
                    DispatchQueue.main.async {
                        self.cashBalance = result.balance
                    }
                } catch {
                    print("Error decoding cash balance:", error)
                }
            }
        }
        task.resume()
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
                            self.fetchFavoriteStockDetails()
                        }
                    } catch {
                        print("Error decoding favorite stocks:", error)
                    }
                }
            }.resume()
        }
    private func fetchFavoriteStockDetails() {
            for stock in favoriteStocks {
                fetchStockDetail(for: stock.ticker)
//                print(stock)
            }
        }
    
    private func fetchStocks() {
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
                            self.stocks = fetchedStocks
                            self.fetchAllStockDetails()  // Fetch details for all stocks
                        }
                    } catch {
                        print("Error decoding portfolio stocks:", error)
                    }
                }
            }
            task.resume()
        }
    
    private func fetchStockDetail(for ticker: String) {
        let stockDetailURL = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/latestprice/\(ticker)")!
        URLSession.shared.dataTask(with: stockDetailURL) { data, response, error in
            if let data = data, let stockDetail = try? JSONDecoder().decode(StockDetail.self, from: data) {
                DispatchQueue.main.async {
                    self.stockDetails[ticker] = stockDetail
                }
            } else {
                print("Failed to fetch or decode stock detail for ticker \(ticker)")
            }
        }.resume()
    }
    
    enum NetworkError: Error {
        case invalidURL
        case invalidResponse
        case statusCode(Int)
    }
    
    private func deleteStockFromWatchlist(ticker: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Create the URL
        guard let url = URL(string: "https://csci571hw2-414320.de.r.appspot.com/api/v1.0.0/watchlist/\(ticker)") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Create the data task
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                completion(.failure(NetworkError.statusCode(httpResponse.statusCode)))
                return
            }
            
            // Success
            completion(.success(()))
        }.resume()
    }
    
    // Call this method after fetching the stocks
    private func fetchAllStockDetails() {
        for stock in stocks {
            fetchStockDetail(for: stock.ticker)
        }
    }
    private func deleteFavoriteStock(at offsets: IndexSet, ticker: String, keyword: String) {
            favoriteStocks.remove(atOffsets: offsets)
            // Handle the deletion in your data model and potentially on your backend
        if (keyword == "watchlist"){
            print(ticker)
            guard let firstIndex = offsets.first else {
                    return
                }
                let stockToDelete = favoriteStocks[firstIndex]
                
                // Call the function to delete the stock from the watchlist
                deleteStockFromWatchlist(ticker: stockToDelete.ticker) { result in
                    switch result {
                    case .success:
                        // Handle success
                        print("Stock deleted successfully from watchlist")
                    case .failure(let error):
                        // Handle error
                        print("Error deleting stock from watchlist: \(error)")
                    }
                }
        }
        }
        
        private func moveFavoriteStock(from source: IndexSet, to destination: Int) {
            favoriteStocks.move(fromOffsets: source, toOffset: destination)
            // Handle the reordering in your data model and potentially on your backend
        }
    
    var body: some View {
        NavigationStack{
            VStack{
                Form{
                    TextField("Search", text: $searchTextObserver.searchText)
                        .padding(8) // Adds padding to expand the clickable area of the TextField
                        .background(Color.gray.opacity(0.2)) // Sets the background color of the TextField
                        .cornerRadius(8) // Rounded corners for the TextField
                        .onChange(of: searchTextObserver.searchText) { newValue in
                            autoCompleteCancellable?.cancel()
                            autoCompleteCancellable = Timer.publish(every: 0.5, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    fetchAutoCompleteResults(for: searchTextObserver.searchText)
                                }
                        }
                    List(autoCompleteResults.prefix(6), id: \.self) { result in
                        NavigationLink(destination: CompanyDetailView(displaySymbol: result)) {
                            Text(result)
                                .padding(.vertical, 5)
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    Section{
                        Text(dateFormatter.string(from: Date()))
                            .font(.title)
                            .bold()
                            .foregroundColor(.gray)
                            .padding()
                    }.background(Color.white)
                    
                    Section(header: Text("PORTFOLIO")) {
                        let amt = cashBalance
                        let chng = 0.0
                        HStack {
                            VStack {
                                Text("Net Worth")
                                    .font(.title2)
                                // Calculate net worth if needed
                                Text("$25000.00")
                                    .font(.title2)
                                    .bold()
                            }
                            .padding()
                            Spacer()
                            VStack {
                                Text("Cash Balance")
                                    .font(.title2)
                                Text("$\(cashBalance, specifier: "%.2f")")
                                    .font(.title2)
                                    .bold()
                            }
                            .padding()
                        }
                        ForEach(stocks) { stock in
                            if let stockDetail = self.stockDetails[stock.ticker] {
                                NavigationLink(destination: CompanyDetailView(displaySymbol: stock.ticker), tag: stock.ticker, selection: $selectedTicker) {
                                    HStack {
                                        Text(stock.ticker)
                                        Spacer()
                                        VStack(alignment: .trailing) {
                                            let mark = Double(stockDetail.c)*Double(stock.quantity)
                                            Text("$\(mark, specifier: "%.2f")")
                                                .bold()
                                            HStack(spacing: 4) {
                                                Image(systemName: "triangle.fill")
                                                    .resizable()
                                                    .frame(width: 10, height: 10)
                                                    .foregroundColor(stockDetail.d < 0 ? .red : .green)
                                                    .rotationEffect(.degrees(stockDetail.d < 0 ? 180 : 0))
                                                Text("\(stockDetail.d, specifier: "%.2f") (\(stockDetail.dp, specifier: "%.2f")%)")
                                                    .foregroundColor(stockDetail.d < 0 ? .red : .green)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 5)
                            } else {
                                Text("Fetching data for \(stock.ticker)...")
                            }
                        }.onDelete { indexSet in
                            guard let firstIndex = indexSet.first else {
                                return
                            }
                            
                            let tickerToDelete = stocks[firstIndex].ticker
                            deleteFavoriteStock(at: indexSet, ticker: tickerToDelete, keyword: "portfolio")
                        }

                            .onMove(perform: moveFavoriteStock)
                            .listRowBackground(self.editMode == .active ? Color.white : Color.clear)
                    }
                        
                        Section(header: Text("FAVORITES")) {
                            ForEach(favoriteStocks) { stock in
                                if let stockDetail = self.stockDetails[stock.ticker] {
                                    NavigationLink(destination: CompanyDetailView(displaySymbol: stock.ticker), tag: stock.ticker, selection: $selectedTicker) {
                                        HStack {
                                            Text(stock.ticker)
                                            Spacer()
                                            VStack(alignment: .trailing) {
                                                Text("$\(stockDetail.c, specifier: "%.2f")")
                                                    .bold()
                                                HStack(spacing: 4) {
                                                    Image(systemName: "triangle.fill")
                                                        .resizable()
                                                        .frame(width: 10, height: 10)
                                                        .foregroundColor(stockDetail.d < 0 ? .red : .green)
                                                        .rotationEffect(.degrees(stockDetail.d < 0 ? 180 : 0))
                                                    Text("\(stockDetail.d, specifier: "%.2f") (\(stockDetail.dp, specifier: "%.2f")%)")
                                                        .foregroundColor(stockDetail.d < 0 ? .red : .green)
                                                }
                                            }
                                        }
                                                        }
                                                        .padding(.vertical, 5)
                                                    } else {
                                                        Text("Fetching data for \(stock.ticker)...")
                                                    }
                                                }
                                                .onDelete { indexSet in
                                                guard let firstIndex = indexSet.first else {
                                                    return
                                                }
                                                
                                                let tickerToDelete = favoriteStocks[firstIndex].ticker
                                                deleteFavoriteStock(at: indexSet, ticker: tickerToDelete, keyword: "watchlist")
                                                }
                                                .onMove(perform: moveFavoriteStock)
                                                .listRowBackground(self.editMode == .active ? Color.white : Color.clear)
                                           }
                                    
                        Section{
                            Button(action: {
                                if let url = URL(string: "https://finnhub.io/") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Powered by Finnhub.io")
                                    .foregroundColor(.gray)
                                    .font(.footnote)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }.navigationTitle("Stock")
                    .toolbar {
                        if autoCompleteResults.isEmpty {}else{
                            Button("Cancel") {
                                                    autoCompleteResults.removeAll()
                                                }
                        }
                        Button(isEditing ? "Done" : "Edit") {
                            withAnimation {
                                isEditing.toggle()
                            }
                        }
                        .environment(\.editMode, $editMode)
                }
                Spacer() // Pushes everything to the top
            }.background(Color.gray)
                .onAppear {
                    self.fetchCashBalance() // Fetch cash balance on view appearance
                    self.fetchStocks()
                    self.fetchStocks()
                    self.fetchFavoriteStocks()
                    
                }
                
                }
        }
    }
    
    struct Company: Decodable {
        let description: String
        let displaySymbol: String
    }
    
    struct Balance: Decodable {
        let balance: Double
    }
    
    class SearchTextObserver: ObservableObject {
        @Published var searchText: String = ""
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }

