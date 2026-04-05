# Lessons Learned

## Flutter iOS Scene Delegate
- Modern Flutter uses `FlutterImplicitEngineDelegate` with scene-based lifecycle
- `FlutterImplicitEngineBridge` does NOT expose `.engine` property directly
- Register platform channels via `FlutterPlugin` pattern using `registrar(forPlugin:)`
- The registrar may be optional — always unwrap with `if let`

## Dependencies
- `image_gallery_saver_plus` latest may not always be on pub.dev — check exact version
- `google_fonts` handles bundled font loading via network, good for v1 but consider bundling assets for offline

## iOS Config
- Must add `LSApplicationQueriesSchemes` with `instagram-stories` to Info.plist
- Must add `FacebookAppID` to Info.plist
- Photo library permissions need both `NSPhotoLibraryAddUsageDescription` and `NSPhotoLibraryUsageDescription`
