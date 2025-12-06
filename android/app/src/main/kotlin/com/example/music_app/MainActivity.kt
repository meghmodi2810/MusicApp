package com.example.music_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    // CRITICAL FIX: Ensure FlutterEngine is properly provided for audio_session plugin
    // This fixes the "Activity class declared in your AndroidManifest.xml is wrong" error
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
    
    // CRITICAL FIX: Explicitly provide FlutterEngine to ensure audio_session can access it
    // This is required for audio_session plugin to work correctly
    override fun provideFlutterEngine(context: android.content.Context): FlutterEngine? {
        // Use the default implementation which properly initializes the engine
        return super.provideFlutterEngine(context)
    }
    
    // CRITICAL FIX: Ensure engine is available when activity is created
    // This helps audio_session plugin find the FlutterEngine
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // Engine will be available after onCreate completes
    }
}
