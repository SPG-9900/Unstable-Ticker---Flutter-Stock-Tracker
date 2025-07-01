# Unstable Ticker - Flutter Stock Tracker

This is a Flutter application designed to track stock prices from an unstable WebSocket feed. It demonstrates robust error handling, data validation, and performance optimization in a challenging real-world scenario.

## Setup Instructions

Follow these steps to get the application up and running on your local machine.

### Prerequisites

*   Flutter SDK (version 3.x.x or later recommended)
*   Dart SDK (comes with Flutter SDK)

### Running the Mock Server

The application consumes data from a provided unreliable WebSocket server. You must run this server first.

1.  Open your terminal or command prompt.
2.  Navigate to the root directory of this project (`assignment/`).
3.  Execute the following command to start the mock server:
    ```bash
    dart run lib/mock_server.dart
    ```
    You should see output similar to: `Server listening on ws://127.0.0.1:8080`. Keep this terminal window open as long as you want the server to run.

### Running the Flutter Application

1.  Open a **new** terminal or command prompt (separate from the mock server).
2.  Navigate to the root directory of this project (`assignment/`).
3.  Run the Flutter application on your desired device or emulator:
    ```bash
    flutter run
    ```
    This will build and launch the application.

## Architectural Decisions

The application's architecture is designed to address the challenges of an unreliable data feed, maintain responsiveness, and ensure code maintainability.

### State Management

We utilize Flutter's built-in `ValueNotifier` and `ValueListenableBuilder`/`AnimatedBuilder` for state management.

*   **`ValueNotifier<T>`**: Each `Stock` object now contains `ValueNotifier<double>` for its price and `ValueNotifier<bool>` for its anomaly status. This allows for granular updates. When a stock's price or anomaly status changes, only its specific `ValueNotifier` is updated.
*   **`ValueListenableBuilder`**: In `main.dart`, `ValueListenableBuilder` listens to the `StockService`'s `connectionStatusNotifier` and `stocksNotifier`. This ensures that the connection status chip and the overall list of stocks (if a new stock is added or removed) rebuild only when necessary.
*   **`AnimatedBuilder`**: In `StockListItem`, `AnimatedBuilder` listens to the individual `stock.priceNotifier` and `stock.isAnomalousNotifier`. This is crucial for performance. When a stock's price updates, only the `Text` widget displaying the price and the `Icon` widget (for anomaly) are rebuilt and repainted. The parent `Card` widget and other static parts of the list item remain untouched, significantly reducing unnecessary rebuilds.

This approach prevents the entire `ListView` or even entire `Card` widgets from rebuilding on every price update, leading to a highly performant and smooth UI.

### Project Structure and Separation of Concerns

The project follows a clear separation of concerns, organized into logical directories:

*   **`lib/models/`**: Contains the `Stock` class, which is a pure data model encapsulating stock-related properties and their reactive `ValueNotifier`s. It has no UI or service logic.
*   **`lib/services/`**: Houses the `StockService` class. This layer is responsible for all data acquisition logic (WebSocket connection, reconnection, message parsing), data validation (anomaly detection), and managing the state of all `Stock` objects. It exposes `ValueNotifier`s that the UI consumes, abstracting away the complexities of the data source.
*   **`lib/widgets/`**: Contains `StockListItem`, a dedicated widget for rendering a single stock. It's a `StatelessWidget` that receives a `Stock` object and is solely concerned with its visual representation and internal animations (price flashing). This promotes reusability and keeps the UI logic encapsulated.
*   **`lib/main.dart`**: Acts as the application's entry point and orchestrator. It initializes the `StockService` and builds the top-level UI structure, including the `AppBar` and the `ListView` that displays `StockListItem`s. It reacts to high-level state changes from the `StockService` but delegates fine-grained updates to the individual stock list items.

This modular structure enhances readability, testability (services can be easily mocked), and maintainability, making the codebase easier to understand and extend.

## Anomaly Detection Heuristic

### Rule Description

The implemented heuristic for detecting anomalous prices is based on a significant percentage change from the last known valid price.

*   **Rule:** If a new stock price for a given ticker deviates by more than **50%** (either increasing or decreasing) from its `last known valid price`, it is flagged as anomalous.
    *   Formula: `| (newPrice - lastValidPrice) / lastValidPrice | > 0.50`
*   **Behavior on Anomaly:**
    *   The anomalous price is **not** displayed. The last known valid price continues to be shown.
    *   A **warning icon (orange)** is displayed next to the stock to visually flag it as suspect.
    *   A message indicating the anomaly is printed to the debug console.

### Trade-offs of the Chosen Heuristic

This simple percentage-based heuristic offers a straightforward way to detect large, sudden fluctuations, which are common indicators of corrupted or nonsensical data. However, it comes with several trade-offs:

*   **During a Real, Legitimate Market Crash (or Boom):**
    *   **False Positives:** A real, legitimate market crash (or a significant surge) could easily trigger this heuristic. If a stock genuinely drops by more than 50% in a short period, it would be incorrectly flagged as anomalous, and the user would not see the real, updated (but drastically lower) price. This is a significant drawback for a real-world trading application.
    *   **Mitigation:** For a production system, this heuristic would need to be much more sophisticated, possibly involving:
        *   **Dynamic thresholds:** Adjusting the acceptable percentage change based on market volatility or the stock's typical behavior.
        *   **Multiple data points:** Analyzing trends over a longer window, rather than just two consecutive prices.
        *   **External validation:** Cross-referencing with other reliable data sources.
        *   **Domain-specific rules:** Applying different rules for different types of assets.

*   **Potential False Positives:**
    *   **Highly Volatile Stocks:** Stocks known for extreme volatility might legitimately experience large swings that trigger the alert, even if the data is correct.
    *   **Low-Value Stocks:** For very low-priced stocks, a small absolute change can represent a large percentage change, potentially leading to false positives.

*   **Potential False Negatives:**
    *   **Slow, Consistent Drops/Rises:** If a stock's price steadily drops (or rises) by 10% every second over five seconds, the total drop would be 50%, but individual changes might not exceed the 50% threshold, thus not triggering the anomaly detection.
    *   **Syntactically Valid but Logically Incorrect "Valid" Data:** The rule only checks for *percentage change*. It doesn't validate if a price is negative (which our mock server handles by `max(0, price + change)`), or if it falls within a plausible range for a given stock.

In summary, the 50% change heuristic is a simple and effective demonstration of anomaly detection for this assignment's purpose. For a production-grade system, it would serve as a baseline requiring significant refinement and additional complexity to be truly reliable.

## Performance Analysis

To analyze the performance of this application and observe how architectural choices contribute to a smooth UI, you will use Flutter DevTools.

1.  **Run your application** (with the mock server running).
2.  **Open Flutter DevTools** by navigating to the URL provided in your `flutter run` terminal output.
3.  Go to the **"Performance"** tab.
4.  Click the **"Record"** button and let the app run for 10-20 seconds, allowing prices to update.
5.  Click **"Stop"**.

**Include a screenshot of the "Widget Rebuild Stats" section from the "Performance" tab here.**

### Analysis of Architectural Choices for Performance

Our architectural choices, particularly the use of `ValueNotifier` and `AnimatedBuilder`, directly contribute to keeping the UI and Raster threads green (i.e., preventing UI jank) by minimizing unnecessary widget rebuilds.

*   **Localized Rebuilds with `ValueNotifier` and `AnimatedBuilder`**:
    *   Instead of calling `setState()` on the entire `_MyAppState` for every price update, we update the `priceNotifier` and `isAnomalousNotifier` within each `Stock` object.
    *   The `StockListItem`'s `AnimatedBuilder` is specifically configured to listen *only* to these individual `ValueNotifier`s. This means that when a stock's price or anomaly status changes, only the small subtree within `StockListItem` (the `Text` widget for price and the `Icon` for warning) is marked as dirty and rebuilt.
    *   The `Card` widget wrapping each stock, along with other elements in the `StockListItem` that don't change, are not rebuilt. This drastically reduces the amount of work the Flutter engine needs to do on each frame.
*   **Reduced Overhead for `ListView.builder`**: The `stocksNotifier` in `StockService` only triggers a rebuild of the `ListView.builder` in `main.dart` if the *number* of stocks changes (i.e., a new stock is added or existing ones are cleared). Individual price updates do not cause the entire list to rebuild, further optimizing performance.

This granular approach ensures that the CPU spends less time on widget tree traversals and diffing, and the GPU (via the Raster thread) spends less time redrawing unchanging pixels. This directly translates to smoother animations, higher frame rates, and a more responsive user experience, even with a high frequency of data updates from the unstable WebSocket feed. The Performance Overlay in DevTools should clearly show fewer "build" operations and more efficient rendering when compared to a naive `setState` approach on the main widget.
