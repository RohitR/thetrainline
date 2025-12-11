# TheTrainline Search

This project simulates a small, extensible search client for
Trainline-style journey results.\
It is structured to make swapping between mock data and a real API
client straightforward.

------------------------------------------------------------------------

## Goals

-   Provide a clean API:

``` ruby
Bot::Thetrainline.find(from, to, departure_at)
```

-   Work entirely offline using mock JSON fixtures stored in `data/`.

-   Allow a future HTTP or Playwright client without modifying core
    logic.

-   Use small, single-responsibility classes:

    -   `Search`
    -   `FareCalculator`
    -   `HourlySegmentSelector`
    -   `SearchResponse`
    -   `Clients::FileClient`

-   Include tests for each part.

------------------------------------------------------------------------

## Architecture Overview

### 1. Client Layer

A client feeds data into the system. It must respond to:

``` ruby
client.search_journeys(from:, to:, departure_at:)
```

Used by:

``` ruby
client = Clients::ClientFactory.build
service = Core::Search.new(from: from, to: to, departure_at: departure_at, client: client)
```

Two clients exist or are planned:

### **Clients::FileClient**

Loads JSON files under `data/`, shaped exactly like Trainline's real
journey-search API.
Used for: 
- Local development
- Offline execution

### **Clients::HttpClient** *(future)*

Will hit the real Trainline API.\
Should return the same JSON shape so the rest of the app stays
unchanged.

------------------------------------------------------------------------

### 2. Response Adapter: `Response`

Reduces hash navigation noise.\
Instead of writing:

``` ruby
raw.dig("data", "journeySearch", "journeys")
```

You do:

``` ruby
response.journeys
```

Also exposes: - `sections` - `alternatives`

------------------------------------------------------------------------

### 3. Core Logic: `Search`

Main responsibilities:

1.  Fetch raw data from client
2.  Wrap it in `Response`
3.  Build `Segment` objects
4.  Use `FareCalculator` to compute all fare combinations
5.  Use `HourlySegmentSelector` to choose the next journeys
6.  Return the resulting list of `Segment` objects

------------------------------------------------------------------------

### 4. Fare Calculation: `FareCalculator`

Given: - journey - sections hash - alternatives hash

It produces every possible combination: - choose 1 alternative per
section - sum prices - return all fares sorted by price

------------------------------------------------------------------------

### 5. Hourly Selection: `HourlySegmentSelector`

Trainline usually shows one journey per hour.\
This component:

-   Groups segments by departure hour
-   Picks one per hour moving forward
-   Fills remaining slots with earliest journeys if needed

------------------------------------------------------------------------

### 6. Domain Models

#### **Segment**

Contains: 
 - departure_station
 - departure_at
 - arrival_station
 - arrival_at
 - service_agencies
 - duration_in_minutes
 - changeovers
 - products
 - fares

#### **Fare**

Contains: 
- name
- price_in_cents
- currency
- meta

Pure data objects, no business logic.

------------------------------------------------------------------------

## Mock Data Generation

A helper script:

    mock_data_generator.rb

Generates files like:

    data/
      berlin_paris.json
      hamburg_munich.json

These mirror the exact Trainline API structure:

    https://www.thetrainline.com/api/journey-search/

You can generate mock files with:

    ruby mock_data_generator.rb berlin paris 3

This creates 3 journeys.

`Clients::FileClient` loads these during searches.

------------------------------------------------------------------------

## Running the App

### Install dependencies:

    bundle install

### Run in interactive mode:

    bundle exec irb

Then inside IRB:

``` ruby
require_relative "lib/bot/thetrainline"
Bot::Thetrainline.find("berlin", "paris", Time.now)
```

This uses the appropriate mock file in `data/`.

------------------------------------------------------------------------

## Running Tests

    bundle exec rspec

------------------------------------------------------------------------

## Folder Structure

    .
    ├── lib/
    │   ├── bot/
    │   │   └── thetrainline.rb
    │   ├── core/
    │   │   ├── search.rb
    │   │   ├── fare_calculator.rb
    │   │   ├── hourly_segment_selector.rb
    │   │   └── response.rb
    │   ├── clients/
    │   │   ├── file_client.rb
    │   │   └── client_factory.rb
    │   └── models/
    │       ├── segment.rb
    │       └── fare.rb
    │
    ├── data/
    │   └── *.json
    │
    ├── mock_data_generator.rb
    │
    └── spec


------------------------------------------------------------------------

## Notes

-   All mock responses match the real Trainline API shape.
-   A real API client can be plugged in later without modifying core
    logic.
