# Google Places API Integration for Location-Based Attendance

## Overview

This document explains how the Google Places API is integrated with the attendance tracking system to enforce location-based attendance using precise latitude/longitude coordinates and configurable radius validation.

## 🎯 System Architecture

### **Location Selection Flow**
1. **Employer** uses `WorkLocationPicker` to search and select job locations via Google Places API
2. **Google Places API** returns precise GPS coordinates (latitude/longitude) for the selected location
3. **System** stores these coordinates along with an employer-defined allowed radius
4. **Worker** attempts to clock in/out and system validates their GPS location against the job location
5. **Attendance** is only allowed if worker is within the specified radius

## 🗺️ Google Places API Integration

### **WorkLocationPicker Component**

The `WorkLocationPicker` widget provides a complete interface for location selection:

```dart
class WorkLocationPickerResult {
  const WorkLocationPickerResult({
    required this.place,              // PlaceDetails from Google Places API
    required this.allowedRadius,      // Employer-set radius (10m - 5000m)
    this.notes,                       // Optional notes for workers
  });

  final PlaceDetails place;           // Contains lat/lng coordinates
  final double allowedRadius;         // Geofencing radius in meters
  final String? notes;
}
```

### **Location Search Process**

1. **Autocomplete Search**:
   ```dart
   // Real-time search as user types
   final suggestions = await _placesService.fetchAutocomplete(
     input: searchText,
     sessionToken: _sessionToken,
   );
   ```

2. **Place Details Retrieval**:
   ```dart
   // Get precise coordinates for selected location
   final details = await _placesService.fetchPlaceDetails(
     placeId: suggestion.placeId,
     sessionToken: _sessionToken,
   );
   ```

3. **Coordinate Extraction**:
   ```dart
   // PlaceDetails contains exact GPS coordinates
   class PlaceDetails {
     final LatLng location;        // Google Maps LatLng
     final String name;            // Place name
     final String formattedAddress; // Full address
     
     double get latitude => location.latitude;   // Precise latitude
     double get longitude => location.longitude; // Precise longitude
   }
   ```

## 🎯 Location Storage and Configuration

### **Coordinate Storage**
When a location is selected, the system stores:

```dart
{
  'label': place.name,                    // "ABC Company Office"
  'formattedAddress': place.formattedAddress, // Full Google address
  'latitude': place.latitude,             // 25.7617 (precise GPS)
  'longitude': place.longitude,           // -80.1918 (precise GPS)
  'placeId': place.placeId,              // Google Place ID
  'allowedRadius': allowedRadius,         // 150.0 (meters)
  'notes': notes,                        // Optional worker instructions
}
```

### **Radius Configuration**
- **Minimum Radius**: 10 meters (high precision work sites)
- **Maximum Radius**: 5000 meters (large campuses/facilities)
- **Default Radius**: 150 meters (typical office/retail settings)
- **Interactive Slider**: Employers can adjust radius with real-time map preview

```dart
// Configurable radius with validation
double _radiusMeters = 150;
static const _minRadius = 10.0;
static const _maxRadius = 5000.0;

// Visual feedback on map
Circle(
  circleId: const CircleId('radius'),
  center: place.location,
  radius: _radiusMeters,            // Shows allowed area
  fillColor: Colors.blue.withOpacity(0.12),
  strokeColor: Colors.blue.withOpacity(0.5),
)
```

## 🎯 Attendance Validation System

### **JobLocation Model**
Stores job location with geofencing capabilities:

```dart
class JobLocation extends Location {
  const JobLocation({
    required super.latitude,        // From Google Places API
    required super.longitude,       // From Google Places API
    required this.allowedRadius,    // Employer-set radius
    this.name,                     // Location name
    this.isActive = true,          // Can workers clock in here?
  });

  final double allowedRadius;      // Geofencing radius in meters
  final bool isActive;            // Location status

  // Validates if worker is within allowed radius
  bool isValidAttendanceLocation(Location workerLocation) {
    if (!isActive) return false;
    return workerLocation.isWithinRadius(this, allowedRadius);
  }
}
```

### **Real-Time Location Validation**

When a worker attempts to clock in/out:

```dart
// 1. Get worker's current high-accuracy GPS location
final currentLocation = await LocationService.instance.getHighAccuracyLocation();

// 2. Validate against job location using Haversine formula
final validation = jobLocation.validateAttendanceLocation(currentLocation);

// 3. Check validation result
if (validation.isValid) {
  // ✅ Allow attendance - worker is within radius
  await clockInWorker(recordId, currentLocation);
} else {
  // ❌ Block attendance - show distance error
  showError('You are ${validation.distanceDescription} away from work location');
}
```

### **Distance Calculation**
Uses Haversine formula for precise distance calculation:

```dart
// Calculate distance between two GPS points
double distanceTo(Location other) {
  const double earthRadius = 6371000; // Earth's radius in meters
  
  final lat1Rad = latitude * pi / 180;
  final lat2Rad = other.latitude * pi / 180;
  final deltaLatRad = (other.latitude - latitude) * pi / 180;
  final deltaLngRad = (other.longitude - longitude) * pi / 180;

  final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
      cos(lat1Rad) * cos(lat2Rad) *
      sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
  
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c; // Distance in meters
}
```

## 🎯 Attendance Record Integration

### **AttendanceRecord Model**
Stores both job location and actual worker locations:

```dart
class AttendanceRecord {
  // Job location (from Google Places API)
  final JobLocation? jobLocation;        // Designated work location
  
  // Worker's actual locations during attendance
  final Location? clockInLocation;       // GPS when clocking in
  final Location? clockOutLocation;      // GPS when clocking out
  
  // Validation results
  final bool? locationValidated;         // Did validation pass?
  final String? locationValidationMessage; // Detailed result
  
  // Helper methods for location checking
  bool get isClockInLocationValid => 
    jobLocation?.isValidAttendanceLocation(clockInLocation!) ?? true;
    
  double? get clockInDistance => 
    jobLocation?.distanceTo(clockInLocation!);
}
```

### **Clock-In/Out Process**

```dart
// Clock-in with location validation
Future<AttendanceRecord> clockIn(String recordId) async {
  // 1. Get current GPS location with high accuracy
  final currentLocation = await LocationService.instance.getHighAccuracyLocation();
  
  // 2. Get job location from attendance record
  final record = await getAttendanceRecord(recordId);
  final jobLocation = record.jobLocation;
  
  // 3. Validate worker location against job location
  if (jobLocation != null) {
    final validation = jobLocation.validateAttendanceLocation(currentLocation);
    
    if (!validation.isValid) {
      throw LocationValidationException(
        'Cannot clock in: ${validation.reason}'
      );
    }
  }
  
  // 4. Store clock-in with location data
  return await updateAttendance(recordId, {
    'clockIn': DateTime.now().toIso8601String(),
    'clockInLocation': currentLocation.toJson(),
    'locationValidated': true,
    'status': 'clocked_in'
  });
}
```

## 🎯 Backend Database Storage

### **Database Schema for Location Storage**

The longitude and latitude coordinates are stored in the backend database in multiple collections:

#### **1. Job Locations Collection**
```javascript
// jobs collection - stores designated work locations
{
  "_id": "job_123",
  "title": "Office Manager Position",
  "businessId": "business_456",
  "location": {
    "latitude": 25.7617,        // From Google Places API
    "longitude": -80.1918,      // From Google Places API
    "address": "123 Business St, Miami, FL",
    "name": "ABC Company Office",
    "placeId": "ChIJd8BlQ2BZwokRAFQEcDuMONE",
    "allowedRadius": 150.0,     // Employer-set radius in meters
    "isActive": true,           // Location status
    "notes": "Main office entrance",
    "createdAt": "2025-10-04T10:00:00.000Z"
  }
}
```

#### **2. Attendance Records Collection**
```javascript
// attendance collection - stores actual worker locations during clock-in/out
{
  "_id": "att_789",
  "workerId": "worker_123",
  "jobId": "job_456",
  "businessId": "business_789",
  
  // Designated job location (from Google Places API)
  "jobLocation": {
    "latitude": 25.7617,       // Job's designated coordinates
    "longitude": -80.1918,
    "allowedRadius": 150.0,
    "name": "ABC Company Office"
  },
  
  // Worker's actual location when clocking in
  "clockInLocation": {
    "latitude": 25.7612,       // Worker's actual GPS coordinates
    "longitude": -80.1915,
    "accuracy": 5.0,           // GPS accuracy in meters
    "timestamp": "2025-10-04T09:00:00.000Z"
  },
  
  // Worker's actual location when clocking out
  "clockOutLocation": {
    "latitude": 25.7614,       // Worker's GPS when leaving
    "longitude": -80.1916,
    "accuracy": 6.2,
    "timestamp": "2025-10-04T17:00:00.000Z"
  },
  
  // Validation results
  "locationValidated": true,
  "clockInDistance": 45.2,     // Distance in meters from job location
  "clockOutDistance": 38.7,
  "locationValidationMessage": "Location validated successfully",
  
  "scheduledStart": "2025-10-04T09:00:00.000Z",
  "scheduledEnd": "2025-10-04T17:00:00.000Z",
  "clockIn": "2025-10-04T09:02:00.000Z",
  "clockOut": "2025-10-04T17:01:00.000Z",
  "status": "completed"
}
```

#### **3. Location History Collection (Audit Trail)**
```javascript
// location_history collection - detailed audit trail
{
  "_id": "loc_hist_456",
  "attendanceId": "att_789",
  "workerId": "worker_123",
  "jobId": "job_456",
  "action": "clock_in",        // or "clock_out"
  
  // Coordinates stored for audit purposes
  "workerLocation": {
    "latitude": 25.7612,       // Worker's exact position
    "longitude": -80.1915,
    "accuracy": 5.0,
    "altitude": 10.5,
    "heading": 180.0,
    "speed": 0.0
  },
  
  "jobLocation": {
    "latitude": 25.7617,       // Job's designated position
    "longitude": -80.1918,
    "allowedRadius": 150.0
  },
  
  "validation": {
    "isValid": true,
    "distance": 45.2,          // Calculated distance in meters
    "reason": "Worker within allowed radius",
    "timestamp": "2025-10-04T09:02:15.000Z"
  },
  
  "metadata": {
    "deviceId": "device_abc123",
    "appVersion": "1.2.3",
    "platform": "iOS"
  }
}
```

## 🎯 Backend API Integration

### **Attendance API Endpoints**

**Clock-In with Location**:
```javascript
POST /api/attendance/:recordId/clock-in
Content-Type: application/json

{
  "latitude": 25.7617,      // Worker's current GPS coordinates
  "longitude": -80.1918,
  "accuracy": 5.0,          // GPS accuracy in meters
  "timestamp": "2025-10-04T10:00:00.000Z"
}
```

### **Backend Database Operations**

#### **Storing Job Location (from Google Places API)**
```javascript
// When employer creates/updates job location
const jobLocationData = {
  latitude: placeDetails.latitude,     // From Google Places API
  longitude: placeDetails.longitude,   // From Google Places API
  address: placeDetails.formattedAddress,
  name: placeDetails.name,
  placeId: placeDetails.placeId,
  allowedRadius: employerSetRadius,    // 10-5000 meters
  isActive: true,
  notes: employerNotes,
  createdAt: new Date(),
  updatedAt: new Date()
};

// Store in jobs collection
await db.collection('jobs').updateOne(
  { _id: jobId },
  { $set: { location: jobLocationData } }
);
```

#### **Storing Attendance Location (Worker's GPS)**
```javascript
// When worker clocks in/out
const attendanceUpdate = {
  clockInLocation: {
    latitude: workerGPS.latitude,      // Worker's actual coordinates
    longitude: workerGPS.longitude,    // From device GPS
    accuracy: workerGPS.accuracy,
    timestamp: new Date()
  },
  locationValidated: validationResult.isValid,
  clockInDistance: calculatedDistance,
  locationValidationMessage: validationResult.reason
};

// Store in attendance collection
await db.collection('attendance').updateOne(
  { _id: attendanceId },
  { $set: attendanceUpdate }
);

// Also store in audit trail
await db.collection('location_history').insertOne({
  attendanceId: attendanceId,
  workerId: workerId,
  action: 'clock_in',
  workerLocation: workerGPS,
  jobLocation: jobLocationData,
  validation: validationResult,
  timestamp: new Date()
});
```

**Response - Success**:
```javascript
{
  "status": "success",
  "data": {
    "attendanceRecord": {
      "id": "att_123",
      "status": "clocked_in",
      "clockInLocation": {
        "latitude": 25.7617,
        "longitude": -80.1918,
        "accuracy": 5.0
      },
      "locationValidated": true,
      "clockInDistance": 45.2  // Distance from job location in meters
    }
  }
}
```

**Response - Location Validation Failed**:
```javascript
{
  "status": "fail",
  "error": {
    "code": "LOCATION_VALIDATION_FAILED",
    "message": "Worker is 250.5m away from job location (max allowed: 150.0m)",
    "details": {
      "currentDistance": 250.5,
      "allowedRadius": 150.0,
      "jobLocation": {
        "latitude": 25.7600,
        "longitude": -80.1900,
        "name": "ABC Company Office"
      }
    }
  }
}
```

## 🎯 Location Accuracy and Reliability

### **GPS Accuracy Requirements**
- **High Accuracy Mode**: ±5 meters precision for attendance validation
- **Timeout Handling**: 15-second timeout for GPS acquisition
- **Fallback Strategy**: Lower accuracy accepted if high accuracy unavailable

```dart
// Get high-precision location for attendance
Future<Location?> getHighAccuracyLocation({
  Duration timeout = const Duration(seconds: 15),
}) async {
  return getCurrentLocation(
    timeout: timeout,
    desiredAccuracy: 5.0, // 5 meter accuracy requirement
  );
}
```

### **Error Handling and Fallbacks**

1. **Expired Place IDs**: Automatic retry with fresh Place ID lookup
2. **GPS Unavailable**: Graceful degradation with user notification
3. **Network Issues**: Offline support with sync when connected
4. **Permission Denied**: Clear instructions for enabling location access

```dart
// Fallback handling for expired Google Place IDs
Future<void> _handleExpiredPlaceId(PlaceSuggestion suggestion) async {
  try {
    // Search for fresh Place ID using original location description
    final freshSuggestions = await _placesService.fetchAutocomplete(
      input: suggestion.description ?? suggestion.primaryText,
      sessionToken: _sessionToken,
    );
    
    if (freshSuggestions.isNotEmpty) {
      final freshDetails = await _placesService.fetchPlaceDetails(
        placeId: freshSuggestions.first.placeId,
        sessionToken: _sessionToken,
      );
      
      // Use fresh location data
      setState(() => _selectedPlace = freshDetails);
    }
  } catch (error) {
    // Show user-friendly error message
    _showSnackBar('Unable to load this location. Please try another.');
  }
}
```

## 🎯 User Experience Features

### **Visual Feedback**
- **Interactive Map**: Real-time preview of selected location with radius circle
- **Distance Indicator**: Shows exact distance when validation fails
- **Zoom Adjustment**: Automatic map zoom based on radius size
- **Location Search**: Real-time autocomplete with Google Places suggestions

### **Configuration Options**
- **Flexible Radius**: 10m to 5km range for different work environments
- **Location Notes**: Custom instructions for workers
- **Location Status**: Enable/disable locations for attendance
- **Multiple Locations**: Support for businesses with multiple work sites

### **Mobile Permissions**
- **iOS Location Permission**: Clear description of why location access is needed
- **Android Permissions**: Fine and coarse location access
- **Settings Integration**: Direct links to device location settings

## 🎯 Security and Privacy

### **Data Protection**
- **Encrypted Storage**: All GPS coordinates encrypted in transit and at rest
- **Minimal Data**: Only collect location data during attendance events
- **Audit Trail**: Complete history of location validation attempts
- **User Consent**: Clear opt-in for location tracking features

### **Accuracy Safeguards**
- **Multiple Validation**: Cross-check GPS accuracy with distance calculations
- **Geofencing Logic**: Sophisticated radius validation prevents spoofing
- **Time Correlation**: Location timestamps prevent replay attacks
- **Device Validation**: Ensure location data comes from legitimate devices

## 🎯 Business Benefits

### **Prevents Time Theft**
- **Geofencing**: Workers can only clock in when physically present
- **Real-time Validation**: Immediate feedback prevents invalid attendance
- **Audit Trail**: Complete location history for compliance and disputes

### **Flexible Configuration**
- **Multiple Radius Options**: Accommodates different business types
- **Easy Setup**: Google Places integration makes location selection simple
- **Scalable**: Supports businesses with multiple locations

### **Accurate Reporting**
- **Distance Tracking**: Know exactly how far workers are from job sites
- **Location History**: Complete audit trail for attendance verification
- **Compliance Ready**: Meet labor law requirements for location tracking

## 🎯 Implementation Summary

The integration provides a comprehensive location-based attendance system that:

1. **Uses Google Places API** for accurate location selection and coordinate retrieval
2. **Stores precise GPS coordinates** (latitude/longitude) in multiple database collections:
   - **Jobs Collection**: Designated work locations from Google Places API
   - **Attendance Collection**: Worker's actual GPS coordinates during clock-in/out
   - **Location History Collection**: Complete audit trail of all location events
3. **Validates worker location** in real-time during clock-in/out attempts
4. **Provides visual feedback** through interactive maps and distance calculations
5. **Handles edge cases** like expired Place IDs and GPS unavailability
6. **Maintains audit trails** for compliance and dispute resolution
7. **Ensures security** through encrypted data and validation safeguards

### **Database Storage Summary**
- **Job Locations**: Stored with precise lat/lng from Google Places API in `jobs.location`
- **Worker Attendance**: Actual GPS coordinates stored in `attendance.clockInLocation` and `attendance.clockOutLocation`
- **Audit Trail**: Complete location history in `location_history` collection
- **Validation Results**: Distance calculations and validation status stored with each attendance record

This system effectively prevents time theft while providing flexibility for different business environments and clear feedback for both employers and workers.