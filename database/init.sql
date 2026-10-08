
-- 1. Enable PostGIS extension for spatial queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Communities table (closed network whitelist)
CREATE TABLE IF NOT EXISTS communities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    allowed_domains TEXT[] NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    community_id INT REFERENCES communities(id) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'MEMBER', -- 'MEMBER' or 'ADMIN'
    verification_status VARCHAR(20) DEFAULT 'PENDING', -- 'PENDING', 'VERIFIED', 'SUSPENDED'
    trust_score NUMERIC(3, 2) DEFAULT 5.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Vehicles table (for drivers)
CREATE TABLE IF NOT EXISTS vehicles (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    color VARCHAR(30) NOT NULL,
    license_plate VARCHAR(20) UNIQUE NOT NULL,
    seat_capacity INT NOT NULL CHECK (seat_capacity > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Trips table (driver's planned journey with spatial coordinates)
CREATE TABLE IF NOT EXISTS trips (
    id SERIAL PRIMARY KEY,
    driver_id INT REFERENCES users(id) ON DELETE CASCADE,
    community_id INT REFERENCES communities(id) ON DELETE RESTRICT,
    vehicle_id INT REFERENCES vehicles(id) ON DELETE SET NULL,
    origin_name VARCHAR(150) NOT NULL,
    origin_geom GEOMETRY(Point, 4326) NOT NULL,
    destination_name VARCHAR(150) NOT NULL,
    destination_geom GEOMETRY(Point, 4326) NOT NULL,
    departure_time TIMESTAMP WITH TIME ZONE NOT NULL,
    flexibility_window_mins INT DEFAULT 15,
    total_seats INT NOT NULL CHECK (total_seats > 0),
    available_seats INT NOT NULL CHECK (available_seats >= 0),
    estimated_cost NUMERIC(8, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'PUBLISHED', -- 'DRAFT', 'PUBLISHED', 'FULL', 'COMPLETED', 'CANCELLED'
    is_recurring BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Spatial Indexes for fast proximity queries
CREATE INDEX IF NOT EXISTS idx_trips_origin ON trips USING GIST(origin_geom);
CREATE INDEX IF NOT EXISTS idx_trips_destination ON trips USING GIST(destination_geom);

-- 6. Ride Requests table
CREATE TABLE IF NOT EXISTS ride_requests (
    id SERIAL PRIMARY KEY,
    trip_id INT REFERENCES trips(id) ON DELETE CASCADE,
    passenger_id INT REFERENCES users(id) ON DELETE CASCADE,
    pickup_name VARCHAR(150) NOT NULL,
    pickup_geom GEOMETRY(Point, 4326) NOT NULL,
    dropoff_name VARCHAR(150) NOT NULL,
    dropoff_geom GEOMETRY(Point, 4326) NOT NULL,
    requested_seats INT DEFAULT 1 CHECK (requested_seats > 0),
    status VARCHAR(20) DEFAULT 'REQUESTED', -- 'REQUESTED', 'ACCEPTED', 'CONFIRMED', 'REJECTED', 'CANCELLED'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed a sample test community
INSERT INTO communities (name, allowed_domains) 
VALUES ('Main Campus Community', ARRAY['@college.edu', '@univ.ac.in', '@campus.org']);
