class CustomLyricsApiConfig {
  final String name;
  final String baseUrl;
  final String searchEndpoint;
  final String lyricEndpoint;
  final String searchMethod;
  final String lyricMethod;
  final Map<String, String> searchParams;
  final Map<String, String> lyricParams;
  final String songIdField;
  final String titleField;
  final String artistField;
  final String lyricField;
  final String translationField;
  final String successCode;
  final String dataField;
  final String artistPath;
  final bool isEnabled;
  final bool useQrcFormat;

  const CustomLyricsApiConfig({
    required this.name,
    required this.baseUrl,
    required this.searchEndpoint,
    required this.lyricEndpoint,
    this.searchMethod = 'GET',
    this.lyricMethod = 'GET',
    this.searchParams = const {},
    this.lyricParams = const {},
    this.songIdField = 'mid',
    this.titleField = 'title',
    this.artistField = 'artist',
    this.lyricField = 'lyric',
    this.translationField = 'trans',
    this.successCode = '200',
    this.dataField = 'data',
    this.artistPath = 'artist',
    this.isEnabled = true,
    this.useQrcFormat = false,
  });

  // 从JSON创建配置
  factory CustomLyricsApiConfig.fromJson(Map<String, dynamic> json) {
    return CustomLyricsApiConfig(
      name: json['name'] ?? '',
      baseUrl: json['baseUrl'] ?? '',
      searchEndpoint: json['searchEndpoint'] ?? '',
      lyricEndpoint: json['lyricEndpoint'] ?? '',
      searchMethod: json['searchMethod'] ?? 'GET',
      lyricMethod: json['lyricMethod'] ?? 'GET',
      searchParams: Map<String, String>.from(json['searchParams'] ?? {}),
      lyricParams: Map<String, String>.from(json['lyricParams'] ?? {}),
      songIdField: json['songIdField'] ?? 'mid',
      titleField: json['titleField'] ?? 'title',
      artistField: json['artistField'] ?? 'artist',
      lyricField: json['lyricField'] ?? 'lyric',
      translationField: json['translationField'] ?? 'trans',
      successCode: json['successCode']?.toString() ?? '200',
      dataField: json['dataField'] ?? 'data',
      artistPath: json['artistPath'] ?? 'artist',
      isEnabled: json['isEnabled'] ?? true,
      useQrcFormat: json['useQrcFormat'] ?? false,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'baseUrl': baseUrl,
      'searchEndpoint': searchEndpoint,
      'lyricEndpoint': lyricEndpoint,
      'searchMethod': searchMethod,
      'lyricMethod': lyricMethod,
      'searchParams': searchParams,
      'lyricParams': lyricParams,
      'songIdField': songIdField,
      'titleField': titleField,
      'artistField': artistField,
      'lyricField': lyricField,
      'translationField': translationField,
      'successCode': successCode,
      'dataField': dataField,
      'artistPath': artistPath,
      'isEnabled': isEnabled,
      'useQrcFormat': useQrcFormat,
    };
  }

  // 创建副本
  CustomLyricsApiConfig copyWith({
    String? name,
    String? baseUrl,
    String? searchEndpoint,
    String? lyricEndpoint,
    String? searchMethod,
    String? lyricMethod,
    Map<String, String>? searchParams,
    Map<String, String>? lyricParams,
    String? songIdField,
    String? titleField,
    String? artistField,
    String? lyricField,
    String? translationField,
    String? successCode,
    String? dataField,
    String? artistPath,
    bool? isEnabled,
    bool? useQrcFormat,
  }) {
    return CustomLyricsApiConfig(
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      searchEndpoint: searchEndpoint ?? this.searchEndpoint,
      lyricEndpoint: lyricEndpoint ?? this.lyricEndpoint,
      searchMethod: searchMethod ?? this.searchMethod,
      lyricMethod: lyricMethod ?? this.lyricMethod,
      searchParams: searchParams ?? this.searchParams,
      lyricParams: lyricParams ?? this.lyricParams,
      songIdField: songIdField ?? this.songIdField,
      titleField: titleField ?? this.titleField,
      artistField: artistField ?? this.artistField,
      lyricField: lyricField ?? this.lyricField,
      translationField: translationField ?? this.translationField,
      successCode: successCode ?? this.successCode,
      dataField: dataField ?? this.dataField,
      artistPath: artistPath ?? this.artistPath,
      isEnabled: isEnabled ?? this.isEnabled,
      useQrcFormat: useQrcFormat ?? this.useQrcFormat,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomLyricsApiConfig &&
        other.name == name &&
        other.baseUrl == baseUrl &&
        other.searchEndpoint == searchEndpoint &&
        other.lyricEndpoint == lyricEndpoint;
  }

  @override
  int get hashCode {
    return Object.hash(name, baseUrl, searchEndpoint, lyricEndpoint);
  }

  @override
  String toString() {
    return 'CustomLyricsApiConfig(name: $name, baseUrl: $baseUrl)';
  }
}
