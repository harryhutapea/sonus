package com.example.sonus

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ─── FIX: Keyboard lambat di MIUI/Xiaomi ────────────────────────────
        //
        // Root cause: MIUI menggunakan ViewRootImplStubImpl custom yang tetap
        // menjalankan insets animation callbacks (onAnimationUpdate) ke Flutter
        // di setiap frame animasi keyboard — terlepas dari setting adjustPan
        // maupun adjustResize di manifest.
        //
        // Setiap callback tersebut memicu Flutter untuk redraw + upload frame
        // baru ke GPU (gralloc4 @set_metadata), yang membuat keyboard terasa
        // sangat lambat saat muncul dan tertutup.
        //
        // SOFT_INPUT_ADJUST_NOTHING = Android tidak mengirim perubahan window
        // apapun ke view hierarchy saat IME muncul/hilang. Flutter tidak pernah
        // menerima insets changes → tidak ada redraw per-frame → keyboard
        // terasa instan. Keyboard IME itu sendiri tetap animasi normal karena
        // animasinya dikelola oleh aplikasi keyboard, bukan oleh window kita.
        //
        @Suppress("DEPRECATION")
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING)
    }
}