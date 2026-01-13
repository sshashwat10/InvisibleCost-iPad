# Outfit Font Setup

The Invisible Cost iPad app uses the **Outfit** font from Google Fonts.

## Download

1. Go to: https://fonts.google.com/specimen/Outfit
2. Click "Download family" button
3. Unzip the downloaded file

## Required Font Files

Copy these `.ttf` files to this folder:

- `Outfit-Thin.ttf` (100)
- `Outfit-ExtraLight.ttf` (200) ← PRIMARY
- `Outfit-Light.ttf` (300) ← PRIMARY  
- `Outfit-Regular.ttf` (400)
- `Outfit-Medium.ttf` (500) ← PRIMARY

## Add to Xcode

1. Drag the `.ttf` files into this `Fonts` folder in Xcode
2. Make sure "Copy items if needed" is checked
3. Make sure your iPad target is selected in "Add to targets"

## Info.plist Entry

Add this to your iPad target's Info.plist (or via Xcode target settings):

```xml
<key>UIAppFonts</key>
<array>
    <string>Outfit-Thin.ttf</string>
    <string>Outfit-ExtraLight.ttf</string>
    <string>Outfit-Light.ttf</string>
    <string>Outfit-Regular.ttf</string>
    <string>Outfit-Medium.ttf</string>
</array>
```

Or in Xcode:
1. Select your iPad target
2. Go to "Info" tab
3. Add row: "Fonts provided by application"
4. Add each font filename as an item

## Verify

After building, you can verify the font loaded by checking the console for font-related errors, or by running:

```swift
for family in UIFont.familyNames.sorted() {
    if family.contains("Outfit") {
        print("Family: \(family)")
        for name in UIFont.fontNames(forFamilyName: family) {
            print("  - \(name)")
        }
    }
}
```

