package com.example.sonus

import android.os.Build
import android.os.Bundle
import android.view.WindowInsets
import android.view.WindowInsetsAnimation
import android.view.WindowManager
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    // Flag: true saat keyboard sedang animasi masuk/keluar
    private var imeAnimating = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Baseline: cegah window dari resize/pan saat keyboard muncul.
        // MIUI mengabaikan ini untuk animasinya sendiri, tapi tetap berguna
        // sebagai fallback di device non-MIUI.
        @Suppress("DEPRECATION")
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING)

        // Interceptor khusus untuk MIUI — hanya aktif di Android 11+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            installImeInterceptor()
        }
    }

    /**
     * Dua-lapis interceptor untuk mencegah Flutter redraw per-frame saat
     * keyboard animasi di MIUI:
     *
     * Lapis 1 — WindowInsetsAnimation.Callback:
     *   Melacak kapan animasi IME mulai (onPrepare) dan selesai (onEnd).
     *   Di onEnd, kita paksa satu refresh final agar Flutter tahu posisi
     *   keyboard yang sebenarnya.
     *
     * Lapis 2 — ViewCompat.setOnApplyWindowInsetsListener:
     *   Selama imeAnimating=true, kembalikan WindowInsetsCompat.CONSUMED.
     *   Ini mencegah ViewGroup.dispatchApplyWindowInsets meneruskan insets
     *   ke child views (termasuk FlutterView) → Flutter tidak redraw per-frame.
     *   Saat imeAnimating=false, insets mengalir normal.
     */
    @Suppress("NewApi")
    private fun installImeInterceptor() {
        val decor = window.decorView

        // Lapis 1: lacak state animasi IME
        decor.setWindowInsetsAnimationCallback(
            object : WindowInsetsAnimation.Callback(DISPATCH_MODE_CONTINUE_ON_SUBTREE) {

                override fun onPrepare(animation: WindowInsetsAnimation) {
                    // Animasi IME akan mulai — mulai blokir insets ke Flutter
                    if (animation.typeMask and WindowInsets.Type.ime() != 0) {
                        imeAnimating = true
                    }
                }

                override fun onProgress(
                    insets: WindowInsets,
                    running: MutableList<WindowInsetsAnimation>
                ): WindowInsets = insets  // tidak ada pemrosesan per-frame

                override fun onEnd(animation: WindowInsetsAnimation) {
                    super.onEnd(animation)
                    if (animation.typeMask and WindowInsets.Type.ime() != 0) {
                        // Animasi selesai — cabut blokir
                        imeAnimating = false
                        // Kirim satu insets refresh agar Flutter mendapat state
                        // keyboard final (terbuka penuh atau tertutup penuh)
                        decor.requestApplyInsets()
                    }
                }
            }
        )

        // Lapis 2: blokir insets ke FlutterView selama animasi berlangsung
        ViewCompat.setOnApplyWindowInsetsListener(decor) { v, insets ->
            if (imeAnimating) {
                // CONSUMED → ViewGroup tidak meneruskan ke child views.
                // FlutterView tidak menerima insets → tidak ada redraw per-frame.
                WindowInsetsCompat.CONSUMED
            } else {
                // Di luar animasi: aliran insets normal
                ViewCompat.onApplyWindowInsets(v, insets)
            }
        }
    }
}