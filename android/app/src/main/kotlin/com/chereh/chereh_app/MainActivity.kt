package com.chereh.chereh_app

import android.os.Bundle
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import com.android.installreferrer.api.ReferrerDetails
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.chereh.chereh_app/install_referrer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getInstallReferrer") {
                    readInstallReferrer(result)
                } else {
                    result.notImplemented()
                }
            }
    }

    /**
     * Lit le paramètre `referrer` transmis par le Play Store lors de l'installation.
     * En cas de succès, renvoie la valeur brute (ex: "chereh_token=abc123...").
     * En cas d'échec, renvoie null sans erreur pour ne pas bloquer l'app.
     */
    private fun readInstallReferrer(result: MethodChannel.Result) {
        val client = InstallReferrerClient.newBuilder(this).build()

        client.startConnection(object : InstallReferrerStateListener {
            override fun onInstallReferrerSetupFinished(responseCode: Int) {
                when (responseCode) {
                    InstallReferrerClient.InstallReferrerResponse.OK -> {
                        try {
                            val response: ReferrerDetails = client.installReferrer
                            val referrerUrl = response.installReferrer
                            client.endConnection()
                            result.success(referrerUrl)
                        } catch (e: Exception) {
                            client.endConnection()
                            result.success(null)
                        }
                    }
                    else -> {
                        client.endConnection()
                        result.success(null)
                    }
                }
            }

            override fun onInstallReferrerServiceDisconnected() {
                result.success(null)
            }
        })
    }
}
