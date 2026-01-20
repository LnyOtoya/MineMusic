class CustomLyricsApiConfig {
  final String name;
  final String baseUrl;
  final String searchEndpoint;
  final String lyricEndpoint;
  final String searchMethod; // GET or POST
  final String lyricMethod; // GET or POST
  final Map<String, String> searchParams; // 参数映射
  final Map<String, String> lyricParams; // 参数映射
  final String songIdField; // 歌曲ID字段名
  final String titleField; // 歌名字段名
  final String artistField; // 艺术家字段名
  final String lyricField; // 歌词字段名
  final String translationField; // 翻译字段名
  final String successCode; // 成功响应码
  final String dataField; // 数据字段名
  final String artistPath; // 艺术家路径，如 'singer[0].name'
  final bool isEnabled;

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