class AdxCommon {
  static const String gdprTypePopupLocation = "popup_location";
  static const String gdprTypePopupDebug = "popup_debug";
  static const String gdprTypeDirectConfirm = "direct_confirm";
  static const String gdprTypeDirectDenied = "direct_denied";
  static const String gdprTypeDirectNotRequired = "direct_not_required";
  static const String gdprTypeDirectUnknown = "direct_unknown";

  static const String size_320x50 = "320x50";
  static const String size_320x100 = "320x100";
  static const String size_300x250 = "300x250";
  static const String size_728x90 = "728x90";

  static const String positionTopCenter = "top_center";
  static const String positionTopLeft = "top_left";
  static const String positionTopRight = "top_right";
  static const String positionCenter = "center";
  static const String positionCenterLeft = "center_left";
  static const String positionCenterRight = "center_right";
  static const String positionBottomCenter = "bottom_center";
  static const String positionBottomLeft = "bottom_left";
  static const String positionBottomRight = "bottom_right";
}

class AdxInitResult {
  bool? result;
  int? consent;

  AdxInitResult(resultFlag, consentStatus) {
    result = resultFlag;
    consent = consentStatus;
  }
}