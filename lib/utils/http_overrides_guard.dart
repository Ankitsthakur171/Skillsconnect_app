// lib/utils/http_overrides_guard.dart
import 'dart:async';                 // unawaited
import 'dart:convert' show Encoding; // Encoding
import 'dart:io';
import 'session_guard.dart';

class GuardedHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final base = super.createHttpClient(context);
    return _GuardedHttpClient(base);
  }
}

class _GuardedHttpClient implements HttpClient {
  final HttpClient _i;
  _GuardedHttpClient(this._i);

  // ---- basic delegated properties ----
  @override
  bool get autoUncompress => _i.autoUncompress;
  @override
  set autoUncompress(bool v) => _i.autoUncompress = v;

  @override
  Duration? get connectionTimeout => _i.connectionTimeout;
  @override
  set connectionTimeout(Duration? v) => _i.connectionTimeout = v;

  @override
  Duration get idleTimeout => _i.idleTimeout;
  @override
  set idleTimeout(Duration v) => _i.idleTimeout = v;

  @override
  int? get maxConnectionsPerHost => _i.maxConnectionsPerHost;
  @override
  set maxConnectionsPerHost(int? v) => _i.maxConnectionsPerHost = v;

  @override
  String? get userAgent => _i.userAgent;
  @override
  set userAgent(String? v) => _i.userAgent = v;

  // ---- new in recent SDKs: connectionFactory & keyLog setters ----
  @override
  set connectionFactory(
      Future<ConnectionTask<Socket>> Function(Uri, String?, int?)? f,
      ) => _i.connectionFactory = f;

  @override
  set keyLog(void Function(String line)? f) => _i.keyLog = f;

  // ---- auth/proxy (ONLY setters — some SDKs don't expose getters) ----
  @override
  set badCertificateCallback(
      bool Function(X509Certificate cert, String host, int port)? cb,
      ) => _i.badCertificateCallback = cb;

  @override
  set findProxy(
      String Function(Uri url)? f,
      ) => _i.findProxy = f;

  @override
  set authenticate(
      Future<bool> Function(Uri url, String scheme, String? realm)? f,
      ) => _i.authenticate = f;

  @override
  set authenticateProxy(
      Future<bool> Function(String host, int port, String scheme, String? realm)? f,
      ) => _i.authenticateProxy = f;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) =>
      _i.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) =>
      _i.addProxyCredentials(host, port, realm, credentials);

  // ---- open methods (wrap to intercept request.close) ----
  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) async =>
      _wrap(await _i.open(method, host, port, path));

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _wrap(await _i.openUrl(method, url));

  @override
  Future<HttpClientRequest> get(String host, int port, String path) async =>
      _wrap(await _i.get(host, port, path));

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _wrap(await _i.getUrl(url));

  @override
  Future<HttpClientRequest> post(String host, int port, String path) async =>
      _wrap(await _i.post(host, port, path));

  @override
  Future<HttpClientRequest> postUrl(Uri url) async =>
      _wrap(await _i.postUrl(url));

  @override
  Future<HttpClientRequest> put(String host, int port, String path) async =>
      _wrap(await _i.put(host, port, path));

  @override
  Future<HttpClientRequest> putUrl(Uri url) async =>
      _wrap(await _i.putUrl(url));

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) async =>
      _wrap(await _i.delete(host, port, path));

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async =>
      _wrap(await _i.deleteUrl(url));

  @override
  Future<HttpClientRequest> head(String host, int port, String path) async =>
      _wrap(await _i.head(host, port, path));

  @override
  Future<HttpClientRequest> headUrl(Uri url) async =>
      _wrap(await _i.headUrl(url));

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) async =>
      _wrap(await _i.patch(host, port, path));

  @override
  Future<HttpClientRequest> patchUrl(Uri url) async =>
      _wrap(await _i.patchUrl(url));

  @override
  void close({bool force = false}) => _i.close(force: force);

  HttpClientRequest _wrap(HttpClientRequest r) => _GuardedHttpClientRequest(r);
}

class _GuardedHttpClientRequest implements HttpClientRequest {
  final HttpClientRequest _r;
  _GuardedHttpClientRequest(this._r);

  // 🔎 intercept here
  @override
  Future<HttpClientResponse> close() async {
    final res = await _r.close();
    unawaited(SessionGuard.scan(statusCode: res.statusCode));
    return res;
  }

  // ---- forwards (keep minimal; no deadline in modern SDK) ----
  @override
  Encoding get encoding => _r.encoding;
  @override
  set encoding(Encoding v) => _r.encoding = v;

  @override
  bool get bufferOutput => _r.bufferOutput;
  @override
  set bufferOutput(bool v) => _r.bufferOutput = v;

  @override
  int get contentLength => _r.contentLength;
  @override
  set contentLength(int v) => _r.contentLength = v;

  @override
  bool get followRedirects => _r.followRedirects;
  @override
  set followRedirects(bool v) => _r.followRedirects = v;

  @override
  int get maxRedirects => _r.maxRedirects;
  @override
  set maxRedirects(int v) => _r.maxRedirects = v;

  @override
  bool get persistentConnection => _r.persistentConnection;
  @override
  set persistentConnection(bool v) => _r.persistentConnection = v;

  @override
  HttpConnectionInfo? get connectionInfo => _r.connectionInfo;
  @override
  List<Cookie> get cookies => _r.cookies;
  @override
  Future<HttpClientResponse> get done => _r.done;
  @override
  HttpHeaders get headers => _r.headers;
  @override
  String get method => _r.method;
  @override
  Uri get uri => _r.uri;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) => _r.abort(exception, stackTrace);
  @override
  void add(List<int> data) => _r.add(data);
  @override
  void addError(Object error, [StackTrace? stackTrace]) => _r.addError(error, stackTrace);
  @override
  Future addStream(Stream<List<int>> stream) => _r.addStream(stream);
  @override
  Future<void> flush() => _r.flush();
  @override
  void write(Object? obj) => _r.write(obj);
  @override
  void writeAll(Iterable objects, [String sep = ""]) => _r.writeAll(objects, sep);
  @override
  void writeCharCode(int charCode) => _r.writeCharCode(charCode);
  @override
  void writeln([Object? obj = ""]) => _r.writeln(obj);
}
