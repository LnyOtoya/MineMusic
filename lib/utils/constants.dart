// 项目常量定义

// API 相关常量
const String API_VERSION = '1.16.0';
const String APP_NAME = 'MyMusicPlayer';
const String API_FORMAT = 'xml';

// 缓存相关常量
const String CACHE_KEY_PREFIX = 'subsonic_cache_';
const int CACHE_EXPIRATION_HOURS = 24;

// 网络相关常量
const int MAX_CONCURRENT_REQUESTS = 3;
const int REQUEST_TIMEOUT_SECONDS = 30;
const int MAX_RETRY_COUNT = 3;

// UI 相关常量
const int DEFAULT_SONG_COUNT = 20;
const int DEFAULT_ALBUM_COUNT = 20;
const int DEFAULT_ARTIST_COUNT = 20;
const int MAX_SEARCH_RESULTS = 50;

// 错误消息常量
const String ERROR_NETWORK_TIMEOUT = '网络连接超时，请检查网络设置';
const String ERROR_NETWORK_CONNECTION = '网络连接失败，请检查网络设置';
const String ERROR_LOGIN_FAILED = '登录失败，请检查用户名和密码';
const String ERROR_NO_PERMISSION = '没有权限执行此操作';
const String ERROR_RESOURCE_NOT_FOUND = '请求的资源不存在';
const String ERROR_SERVER_ERROR = '服务器内部错误，请稍后重试';
const String ERROR_PARSE_FAILED = '数据解析失败，请稍后重试';
const String ERROR_PASSWORD_ERROR = '密码错误，请检查输入';
const String ERROR_DEFAULT = '操作失败';

// 成功消息常量
const String SUCCESS_LOGIN = '登录成功';
const String SUCCESS_LOGOUT = '退出登录成功';
const String SUCCESS_PLAYLIST_CREATED = '歌单创建成功';
const String SUCCESS_PLAYLIST_UPDATED = '歌单更新成功';
const String SUCCESS_PLAYLIST_DELETED = '歌单删除成功';
const String SUCCESS_SONG_ADDED = '歌曲已添加到歌单';
const String SUCCESS_SONG_REMOVED = '歌曲已从歌单中删除';

// 路由相关常量
const String ROUTE_HOME = '/';
const String ROUTE_LOGIN = '/login';
const String ROUTE_PLAYER = '/player';
const String ROUTE_SEARCH = '/search';
const String ROUTE_SETTINGS = '/settings';
const String ROUTE_DETAIL = '/detail';
const String ROUTE_ARTISTS = '/artists';
const String ROUTE_PLAYLISTS = '/playlists';
const String ROUTE_ABOUT = '/about';
