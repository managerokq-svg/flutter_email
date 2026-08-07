// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

abstract class SConstants {
  ///your super up base domain url
  ///like this (example.com) not start https// or any sub domains example [superupdev.com]
  static String productionBaseUrl = "superupdev.online";

  //your local network ip for local development run
  static const localBaseUrl = "192.168.1.101:3000";

  ///your app name
  static const appName = "Superup";

  ///android and ios admob ids [https://developers.google.com/admob/flutter/quick-start] [https://developers.google.com/ad-manager/mobile-ads-sdk/flutter/quick-start]
  ///if it null it will stop showing for the banners
  static String? androidBannerAdsUnitId =
      "ca-app-pub-5480704135551772/8580865464";
  static String? iosBannerAdsUnitId = "ca-app-pub-5480704135551772/8802805861";

  ///set the Interstitial id if it null it will stop showing
  static String? androidInterstitialId =
      "ca-app-pub-5480704135551772/1264061343";
  static String? iosInterstitialId = "ca-app-pub-5480704135551772/5139727176";

  ///get from https://console.firebase.google.com/project/_/settings/cloudmessaging
  ///follow this https://firebase.flutter.dev/docs/messaging/usage/#web-tokens
  static String? webVapidKey =
      "BJ8SCv1OwHuR1Q26dYygkFgtQ6Kaoa6U4XVQe1x0m8BG-OJn6Xgje8YsA3rJinUcYydFJooKdPmyjbb43W4pjoA";

  ///setup video and voice calls [https://agora.io]
  ///update this with your agora app id
  static const agoraAppId = "1b7727fb86e846d79xxxxxxxxxxxxxxx";

  ///change this to your google maps api key to enable google maps location picker
  static const googleMapsApiKey = "AIzaSyAP-yGIutctMXp1XXXXXXXXXXXXXXXXXXX";

  ///Giphy API key for GIF picker [https://developers.giphy.com/dashboard]
  static const giphyApiKey = "e9biBMxxxxxxxxxxxxxxxxxxxxxx";

  ///set the onesignal id for push notifications [https://onesignal.com]
  ///update this with your onesignal app id  static const oneSignalAppId = "xxxxxxxx-xxxxxxxx-xxxxxxxx-xxxxxxxx-xxxxxxxx";
  static const oneSignalAppId = "xxxxx-xxxxx-xxxxxx-xxxxxxx";

  ///don't update update only if you use server ip just return your server ip with port [12.xxx.xxx:80/]
  static String get baseMediaUrl {
    ///if you don't setup domain yet you can return the server ip like this [return Uri.parse("http://ip:port/");]

    if (productionBaseUrl.contains("192.")) {
      return "http://$productionBaseUrl/";
    }
    // return "http://$_productionBaseUrl/";
    return "https://api.$productionBaseUrl/";
  }

  ///don't update update only if you use server ip just return your server ip with port [12.xxx.xxx:80/api/v1]
  static Uri get sApiBaseUrl {
    ///if you don't setup domain yet you can return the server ip like this [return Uri.parse("http://ip:port/api/v1");]
    if (productionBaseUrl.contains("192.")) {
      //this means you run on your local server
      return Uri.parse("http://$productionBaseUrl/api/v1");
    }
    return Uri.parse("https://api.$productionBaseUrl/api/v1");
  }
}
