/**
 * Production-Ready React Native CLI FCM Setup Configuration & Code Snippets
 * 
 * Target: React Native CLI (Android First)
 * Package: @react-native-firebase/app & @react-native-firebase/messaging
 */

export const REACT_NATIVE_INDEX_JS_SNIPPET = `
import { AppRegistry } from 'react-native';
import messaging from '@react-native-firebase/messaging';
import App from './App';
import { name as appName } from './app.json';

// 1. Register background messaging handler for Killed/Background state
messaging().setBackgroundMessageHandler(async remoteMessage => {
  console.log('[FCM Background Service] Message received in background/killed state:', remoteMessage);
  // Optional: Trigger local notification or sync background tasks
});

AppRegistry.registerComponent(appName, () => App);
`;

export const ANDROID_MANIFEST_XML_SNIPPET = `
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- FCM Push Notification Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
      android:name=".MainApplication"
      android:label="@string/app_name"
      android:icon="@mipmap/ic_launcher"
      android:roundIcon="@mipmap/ic_launcher_round"
      android:allowBackup="false"
      android:theme="@style/AppTheme">

      <!-- FCM Default Channel Settings -->
      <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@drawable/ic_notification" />
      <meta-data
        android:name="com.google.firebase.messaging.default_notification_color"
        android:resource="@color/colorAccent" />
      <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="rexo_high_importance_channel" />

      <activity
        android:name=".MainActivity"
        android:label="@string/app_name"
        android:configChanges="keyboard|keyboardHidden|orientation|screenLayout|screenSize|smallestScreenSize|uiMode"
        android:launchMode="singleTask"
        android:windowSoftInputMode="adjustResize"
        android:exported="true">
        <intent-filter>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent-filter>
      </activity>
    </application>
</manifest>
`;

export const ANDROID_BUILD_GRADLE_SNIPPET = `
// android/build.gradle
buildscript {
    dependencies {
        classpath('com.android.tools.build:gradle:8.1.1')
        classpath('com.google.gms:google-services:4.4.0') // Google Services plugin for FCM
    }
}

// android/app/build.gradle
apply plugin: 'com.android.application'
apply plugin: 'com.google.gms.google-services' // Apply Google Services plugin

dependencies {
    implementation project(':react-native-firebase_app')
    implementation project(':react-native-firebase_messaging')
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
}
`;
