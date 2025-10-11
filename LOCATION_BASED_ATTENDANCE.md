# Location-Based Attendance System

## Overview
This system implements GPS location verification for employee attendance tracking, ensuring workers can only clock in/out when they are physically present at the designated job location.

## 🔑 Key Features

### ✅ **Geolocation Verification**
- **Real-time GPS tracking** during clock-in/out
- **Geofencing validation** with configurable radius
- **High accuracy location** (±5 meters) for reliable verification
- **Fallback handling** when GPS is unavailable

### ✅ **Comprehensive Location Models**
- **Location class**: Basic GPS coordinates with accuracy, timestamp, altitude
- **JobLocation class**: Extends Location with geofencing radius and validation
- **LocationValidationResult**: Detailed validation outcomes with distance calculations

### ✅ **Backend Integration**
- **Location storage** in attendance records
- **Distance calculation** using Haversine formula
- **Automatic validation** on clock-in/out API calls
- **Location history tracking** for audit purposes

### ✅ **Mobile Permissions**
- **iOS permissions**: Location access with user-friendly descriptions
- **Android permissions**: Fine and coarse location access
- **Permission handling**: Graceful request and fallback flows

## 📱 Mobile Implementation

### Location Service (`LocationService`)
```dart
// Get high-accuracy location for attendance
final location = await LocationService.instance.getHighAccuracyLocation();

// Validate worker location against job location
final validation = await LocationService.instance.validateCurrentLocationForJob(jobLocation);
```

### Key Methods:
- `getCurrentLocation()`: Get current GPS coordinates
- `getHighAccuracyLocation()`: Get location with ±5m accuracy
- `validateCurrentLocationForJob()`: Check if worker is within allowed radius
- `getLocationStream()`: Real-time location tracking stream

### Attendance Integration
Clock-in/out automatically includes location data:
```dart
// Automatically gets location and validates against job location
await appState.clockInWorkerAttendance(recordId);
```

## 🔧 Backend Implementation

### Database Schema
```javascript
// Location tracking fields in AttendanceRecord
jobLocation: {
  latitude: Number,
  longitude: Number,
  allowedRadius: Number, // meters
  name: String,
  isActive: Boolean
},
clockInLocation: { /* GPS data when clocking in */ },
clockOutLocation: { /* GPS data when clocking out */ },
locationValidated: Boolean,
locationValidationMessage: String,
clockInDistance: Number, // meters from job location
clockOutDistance: Number
```

### API Validation
```javascript
// Clock-in endpoint validates location
POST /api/attendance/:recordId/clock-in
{
  "latitude": 37.7749,
  "longitude": -122.4194,
  "accuracy": 5.0
}

// Returns 400 error if outside allowed radius
{
  "status": "fail",
  "message": "Worker is 150.5m away from job location (max allowed: 100.0m)"
}
```

## 🛡️ Security Features

### **Strict Enforcement**
- Clock-in/out **rejected** if outside geofence
- **Real-time validation** prevents location spoofing
- **Audit trail** of all location attempts

### **Privacy Protection**
- Location data **only collected** during clock-in/out
- **No continuous tracking** outside work hours
- **Encrypted transmission** of GPS coordinates

### **Accuracy Validation**
- **Minimum accuracy** requirements (±50m max)
- **GPS signal strength** validation
- **Timeout handling** for poor signal areas

## 📊 Data Insights

### **Location Analytics**
- **Distance tracking**: How far workers are from job sites
- **Accuracy monitoring**: GPS signal quality metrics
- **Validation rates**: Success/failure statistics
- **Time-to-fix**: How long GPS takes to acquire location

### **Compliance Reporting**
- **Location compliance** rates per worker
- **Geofence violations** with timestamps
- **Audit logs** for regulatory compliance

## 🔧 Configuration

### **Job Location Setup**
```dart
final jobLocation = JobLocation(
  latitude: 37.7749,
  longitude: -122.4194,
  allowedRadius: 100.0, // 100 meter radius
  name: "Main Office",
  isActive: true,
);
```

### **Accuracy Settings**
- **High accuracy**: ±5 meters (default for attendance)
- **Medium accuracy**: ±10-50 meters (fallback)
- **Timeout**: 15 seconds for location acquisition

## 📋 Installation & Setup

### 1. **Add Dependencies**
```yaml
dependencies:
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
```

### 2. **Configure Permissions**

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to verify your attendance at work.</string>
```

### 3. **Initialize Service**
```dart
// LocationService is automatically initialized as singleton
final location = await LocationService.instance.getCurrentLocation();
```

## 🚀 Usage Examples

### **Basic Location Verification**
```dart
// Check if worker is at job location
final validation = await LocationService.instance.validateCurrentLocationForJob(jobLocation);

if (validation.isValid) {
  print('✅ Worker is at job location');
} else {
  print('❌ Worker is ${validation.distanceDescription} away');
}
```

### **Real-time Location Tracking**
```dart
// Stream location updates
LocationService.instance.getLocationStream().listen((location) {
  print('Current location: ${location.coordinatesString}');
});
```

### **Error Handling**
```dart
try {
  final location = await LocationService.instance.getCurrentLocation();
} on LocationException catch (e) {
  // Handle location-specific errors
  print('Location error: $e');
} catch (e) {
  // Handle general errors
  print('General error: $e');
}
```

## 🔍 Troubleshooting

### **Common Issues**

1. **Permission Denied**
   - Solution: Guide user to app settings
   - Code: `LocationService.instance.openAppSettings()`

2. **Location Services Disabled**
   - Solution: Guide user to device settings
   - Code: `LocationService.instance.openLocationSettings()`

3. **Poor GPS Signal**
   - Solution: Increase timeout or use lower accuracy
   - Code: Use fallback accuracy settings

4. **Indoor Location Issues**
   - Solution: Increase geofence radius for indoor locations
   - Configuration: Set `allowedRadius` to 150-200 meters

### **Performance Optimization**
- **Cache job locations** to avoid repeated API calls
- **Batch location requests** when possible
- **Use appropriate accuracy** levels for different scenarios
- **Implement timeout handling** for poor signal areas

## 📈 Future Enhancements

### **Planned Features**
- **Beacon support** for indoor location tracking
- **WiFi-based location** as GPS fallback
- **Machine learning** for location pattern analysis
- **Geo-temporal** attendance rules (time + location)

### **Integration Opportunities**
- **Facial recognition** combined with location
- **NFC/QR codes** for additional verification
- **Wearable device** integration
- **Vehicle tracking** for mobile work locations

## 🧪 Testing

### **Location Simulation**
```dart
// For testing, you can mock locations
final mockLocation = Location(
  latitude: 37.7749,
  longitude: -122.4194,
  accuracy: 5.0,
  timestamp: DateTime.now(),
);
```

### **Validation Testing**
```dart
// Test various distances from job location
final jobLocation = JobLocation(/* job coordinates */);
final testLocations = [
  Location(/* 50m away */),
  Location(/* 150m away */),
  Location(/* exact location */),
];

for (final location in testLocations) {
  final result = jobLocation.validateAttendanceLocation(location);
  print('Distance: ${result.distanceDescription}, Valid: ${result.isValid}');
}
```

This implementation provides a robust, secure, and user-friendly location-based attendance system that ensures workers are physically present at their designated work locations when clocking in and out.