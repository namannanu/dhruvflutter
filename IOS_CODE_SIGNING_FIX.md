# iOS Code Signing Fix Guide

## Error Analysis
The error indicates that your app has:
- **Invalid code signature**
- **Inadequate entitlements** 
- **Profile has not been explicitly trusted by the user**

## 🔧 Step-by-Step Fix

### 1. Open Xcode Workspace
```bash
cd /Users/mrmad/Dhruv/dhruv_flutter
open ios/Runner.xcworkspace
```

### 2. Configure Code Signing in Xcode

#### A. Select Team and Bundle Identifier
1. In Xcode, select the **Runner** project in the navigator
2. Select the **Runner** target
3. Go to **Signing & Capabilities** tab
4. **Enable "Automatically manage signing"**
5. Select your **Development Team** (Apple Developer Account)
6. Ensure **Bundle Identifier** is unique: `com.mrmad.dhruv.talent`

#### B. Fix Common Issues
- **Team**: Make sure you're signed in to your Apple ID in Xcode
- **Bundle ID**: Must be unique and match your provisioning profile
- **Deployment Target**: Set to iOS 12.0 or higher

### 3. Trust Developer Certificate on Device

#### On Your iPhone (Daksh's iPhone):
1. Go to **Settings** → **General** → **VPN & Device Management**
2. Find your developer certificate under **Developer App**
3. Tap on your certificate
4. Tap **"Trust [Your Developer Name]"**
5. Confirm by tapping **"Trust"**

### 4. Update iOS Project Configuration

Check your `ios/Runner.xcodeproj/project.pbxproj` for:
- Correct Bundle Identifier
- Valid Development Team ID
- Proper provisioning profile

### 5. Clean and Rebuild

Run these commands in terminal:
```bash
cd /Users/mrmad/Dhruv/dhruv_flutter
flutter clean
cd ios
rm -rf Pods
rm Podfile.lock
cd ..
flutter pub get
cd ios
pod install
cd ..
```

### 6. Build and Run from Xcode

1. In Xcode, ensure your device is selected as the target
2. Click **Product** → **Clean Build Folder** (Cmd+Shift+K)
3. Click **Product** → **Run** (Cmd+R)

### 7. Alternative: Run from Flutter with Specific Profile

If you have a specific provisioning profile:
```bash
flutter run --release --flavor production
```

## 🚨 Common Solutions

### Issue: "No Development Team"
**Solution:** 
1. Open Xcode → Preferences → Accounts
2. Add your Apple ID
3. Download Manual Profiles if needed

### Issue: "Bundle Identifier Not Available"
**Solution:** 
1. Change bundle identifier in `ios/Runner.xcodeproj`
2. Update in `ios/Runner/Info.plist`
3. Use a unique identifier like `com.yourname.dhruv.talent`

### Issue: "Profile Not Trusted"
**Solution:** 
1. On device: Settings → General → VPN & Device Management
2. Trust your developer certificate
3. May need to be done each time you install

### Issue: "Entitlements"
**Solution:** 
Check `ios/Runner/Runner.entitlements` exists and has proper format:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
</dict>
</plist>
```

## 🎯 Quick Fix Commands

Run these if you want to try the automated approach:

```bash
# Clean everything
flutter clean
rm -rf ios/Pods ios/Podfile.lock

# Reinstall dependencies  
flutter pub get
cd ios && pod install && cd ..

# Try running again
flutter run --release
```

## 📱 Device Trust Verification

After fixing code signing, verify on your iPhone:
1. **Settings** → **General** → **VPN & Device Management**
2. Should see your app listed under **Developer App**
3. Certificate should show as **"Trusted"**

## ✅ Success Indicators

You'll know it's fixed when:
- Xcode shows green checkmark next to Runner target
- No signing errors in Xcode
- App installs and launches on device
- Flutter run completes without ProcessException

## 🔄 If Still Having Issues

Try these advanced solutions:
1. **Create new Apple ID** for development
2. **Use different Bundle Identifier**
3. **Reset iOS device trust settings**
4. **Check Apple Developer account status**

The key is getting the code signing configured properly in Xcode first, then Flutter should work correctly.