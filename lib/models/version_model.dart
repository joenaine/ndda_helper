class VersionModel {
  final String? androidVersion;
  final String? iosVersion;
  final bool? isReleased;
  final bool? isRequiredAndroid;
  final bool? isRequiredIos;
  final String? title;
  final String? content;

  VersionModel({
    this.androidVersion,
    this.iosVersion,
    this.isReleased,
    this.isRequiredAndroid,
    this.isRequiredIos,
    this.title,
    this.content,
  });

  factory VersionModel.fromJson(Map<String, dynamic> json) {
    return VersionModel(
      androidVersion: json['androidVersion'] as String?,
      iosVersion: json['iosVersion'] as String?,
      isReleased: json['isReleased'] as bool?,
      isRequiredAndroid: json['isRequiredAndroid'] as bool?,
      isRequiredIos: json['isRequiredIos'] as bool?,
      title: json['title'] as String?,
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'androidVersion': androidVersion,
      'iosVersion': iosVersion,
      'isReleased': isReleased,
      'isRequiredAndroid': isRequiredAndroid,
      'isRequiredIos': isRequiredIos,
      'title': title,
      'content': content,
    };
  }
}

