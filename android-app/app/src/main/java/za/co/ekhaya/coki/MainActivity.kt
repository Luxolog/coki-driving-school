package za.co.ekhaya.coki

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView

class MainActivity : Activity() {
    private lateinit var webView: WebView
    private lateinit var progress: ProgressBar
    private lateinit var errorPanel: LinearLayout

    private val siteUrl = "https://luxolog.github.io/coki-driving-school/"
    private val siteHost = "luxolog.github.io"

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.rgb(0, 122, 61)
        window.navigationBarColor = Color.rgb(16, 27, 21)
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
        }
        progress = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            isIndeterminate = true
            setVisibility(View.GONE)
        }
        webView = WebView(this).apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.loadsImagesAutomatically = true
            settings.javaScriptCanOpenWindowsAutomatically = false
            settings.allowFileAccess = false
            settings.allowContentAccess = false
            settings.setSupportMultipleWindows(false)
            webViewClient = object : WebViewClient() {
                override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                    progress.setVisibility(View.VISIBLE)
                    errorPanel.setVisibility(View.GONE)
                    webView.setVisibility(View.VISIBLE)
                }

                override fun onPageFinished(view: WebView?, url: String?) {
                    progress.setVisibility(View.GONE)
                }

                override fun onReceivedError(view: WebView?, request: WebResourceRequest?, error: WebResourceError?) {
                    if (request?.isForMainFrame == true) showError()
                }

                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    val uri = request?.url ?: return true
                    return if (uri.scheme == "https" && uri.host == siteHost) {
                        false
                    } else {
                        try { startActivity(Intent(Intent.ACTION_VIEW, uri)) } catch (_: Exception) {}
                        true
                    }
                }
            }
            webChromeClient = WebChromeClient()
        }
        errorPanel = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(36, 36, 36, 36)
            setVisibility(View.GONE)
            addView(TextView(this@MainActivity).apply {
                text = "Unable to load Coki K53"
                textSize = 22f
                setTextColor(Color.rgb(16, 27, 21))
                gravity = Gravity.CENTER
            })
            addView(TextView(this@MainActivity).apply {
                text = "Please check your internet connection and try again."
                textSize = 15f
                setTextColor(Color.DKGRAY)
                gravity = Gravity.CENTER
                setPadding(0, 12, 0, 20)
            })
            addView(Button(this@MainActivity).apply {
                text = "Try again"
                setOnClickListener { webView.loadUrl(siteUrl) }
            })
        }

        root.addView(progress, LinearLayout.LayoutParams(-1, 5))
        root.addView(webView, LinearLayout.LayoutParams(-1, 0, 1f))
        root.addView(errorPanel, LinearLayout.LayoutParams(-1, 0, 1f))
        setContentView(root)

        if (savedInstanceState != null) webView.restoreState(savedInstanceState) else webView.loadUrl(siteUrl)
    }

    private fun showError() {
        progress.setVisibility(View.GONE)
        webView.setVisibility(View.GONE)
        errorPanel.setVisibility(View.VISIBLE)
    }

    override fun onSaveInstanceState(outState: Bundle) {
        webView.saveState(outState)
        super.onSaveInstanceState(outState)
    }

    @Deprecated("Deprecated in Android")
    override fun onBackPressed() {
        if (::webView.isInitialized && webView.canGoBack()) webView.goBack() else super.onBackPressed()
    }

    override fun onDestroy() {
        if (::webView.isInitialized) webView.destroy()
        super.onDestroy()
    }
}
