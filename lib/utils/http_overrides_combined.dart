// // lib/utils/http_overrides_combined.dart
// import 'dart:async' show unawaited, StreamSubscription;
// import 'dart:convert' as conv;    // for utf8 decode
// import 'dart:convert' show Encoding;
// import 'dart:io';
//
// import 'session_guard.dart';
//
// class CombinedHttpOverrides extends HttpOverrides {
//   @override
//   HttpClient createHttpClient(SecurityContext? context) {
//     final base = super.createHttpClient(context);
//     return _CombinedHttpClient(base);
//   }
// }
//
// class _CombinedHttpClient implements HttpClient {
//   final HttpClient _i;
//   _CombinedHttpClient(this._i);
//
//   // ---- delegated props/setters ----
//   @override bool get autoUncompress => _i.autoUncompress;
//   @override set autoUncompress(bool v) => _i.autoUncompress = v;
//
//   @override Duration? get connectionTimeout => _i.connectionTimeout;
//   @override set connectionTimeout(Duration? v) => _i.connectionTimeout = v;
//
//   @override Duration get idleTimeout => _i.idleTimeout;
//   @override set idleTimeout(Duration v) => _i.idleTimeout = v;
//
//   @override int? get maxConnectionsPerHost => _i.maxConnectionsPerHost;
//   @override set maxConnectionsPerHost(int? v) => _i.maxConnectionsPerHost = v;
//
//   @override String? get userAgent => _i.userAgent;
//   @override set userAgent(String? v) => _i.userAgent = v;
//
//   // Recent SDK setters
//   @override set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri, String?, int?)? f)
//   => _i.connectionFactory = f;
//   @override set keyLog(void Function(String line)? f) => _i.keyLog = f;
//
//   // Auth/proxy setters
//   @override set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? cb)
//   => _i.badCertificateCallback = cb;
//   @override set findProxy(String Function(Uri url)? f) => _i.findProxy = f;
//   @override set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f)
//   => _i.authenticate = f;
//   @override set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f)
//   => _i.authenticateProxy = f;
//
//   @override void addCredentials(Uri url, String realm, HttpClientCredentials credentials)
//   => _i.addCredentials(url, realm, credentials);
//   @override void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials)
//   => _i.addProxyCredentials(host, port, realm, credentials);
//
//   // ---- open methods (wrap to intercept) ----
//   @override Future<HttpClientRequest> open(String m, String h, int p, String path) async => _wrap(await _i.open(m, h, p, path));
//   @override Future<HttpClientRequest> openUrl(String m, Uri u) async => _wrap(await _i.openUrl(m, u));
//   @override Future<HttpClientRequest> get(String h, int p, String path) async => _wrap(await _i.get(h, p, path));
//   @override Future<HttpClientRequest> getUrl(Uri u) async => _wrap(await _i.getUrl(u));
//   @override Future<HttpClientRequest> post(String h, int p, String path) async => _wrap(await _i.post(h, p, path));
//   @override Future<HttpClientRequest> postUrl(Uri u) async => _wrap(await _i.postUrl(u));
//   @override Future<HttpClientRequest> put(String h, int p, String path) async => _wrap(await _i.put(h, p, path));
//   @override Future<HttpClientRequest> putUrl(Uri u) async => _wrap(await _i.putUrl(u));
//   @override Future<HttpClientRequest> delete(String h, int p, String path) async => _wrap(await _i.delete(h, p, path));
//   @override Future<HttpClientRequest> deleteUrl(Uri u) async => _wrap(await _i.deleteUrl(u));
//   @override Future<HttpClientRequest> head(String h, int p, String path) async => _wrap(await _i.head(h, p, path));
//   @override Future<HttpClientRequest> headUrl(Uri u) async => _wrap(await _i.headUrl(u));
//   @override Future<HttpClientRequest> patch(String h, int p, String path) async => _wrap(await _i.patch(h, p, path));
//   @override Future<HttpClientRequest> patchUrl(Uri u) async => _wrap(await _i.patchUrl(u));
//
//   @override void close({bool force = false}) => _i.close(force: force);
//
//   HttpClientRequest _wrap(HttpClientRequest r) => _CombinedHttpClientRequest(r);
// }
//
// class _CombinedHttpClientRequest implements HttpClientRequest {
//   final HttpClientRequest _r;
//   _CombinedHttpClientRequest(this._r);
//
//   @override
//   Future<HttpClientResponse> close() async {
//     final res = await _r.close();
//     // Response ko wrap karo: body tee + SessionGuard.scan(status, body)
//     return _TeeHttpClientResponse(res);
//   }
//
//   // ---- forwards (minimal) ----
//   @override Encoding get encoding => _r.encoding;
//   @override set encoding(Encoding v) => _r.encoding = v;
//   @override bool get bufferOutput => _r.bufferOutput;
//   @override set bufferOutput(bool v) => _r.bufferOutput = v;
//   @override int get contentLength => _r.contentLength;
//   @override set contentLength(int v) => _r.contentLength = v;
//   @override bool get followRedirects => _r.followRedirects;
//   @override set followRedirects(bool v) => _r.followRedirects = v;
//   @override int get maxRedirects => _r.maxRedirects;
//   @override set maxRedirects(int v) => _r.maxRedirects = v;
//   @override bool get persistentConnection => _r.persistentConnection;
//   @override set persistentConnection(bool v) => _r.persistentConnection = v;
//   @override HttpConnectionInfo? get connectionInfo => _r.connectionInfo;
//   @override List<Cookie> get cookies => _r.cookies;
//   @override Future<HttpClientResponse> get done => _r.done;
//   @override HttpHeaders get headers => _r.headers;
//   @override String get method => _r.method;
//   @override Uri get uri => _r.uri;
//
//   @override void abort([Object? exception, StackTrace? stackTrace]) => _r.abort(exception, stackTrace);
//   @override void add(List<int> data) => _r.add(data);
//   @override void addError(Object error, [StackTrace? stackTrace]) => _r.addError(error, stackTrace);
//   @override Future addStream(Stream<List<int>> stream) => _r.addStream(stream);
//   @override Future<void> flush() => _r.flush();
//   @override void write(Object? obj) => _r.write(obj);
//   @override void writeAll(Iterable objects, [String sep = ""]) => _r.writeAll(objects, sep);
//   @override void writeCharCode(int charCode) => _r.writeCharCode(charCode);
//   @override void writeln([Object? obj = ""]) => _r.writeln(obj);
// }
//
// class _TeeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
//   final HttpClientResponse _inner;
//   final List<int> _buf = [];
//   _TeeHttpClientResponse(this._inner);
//
//   // ---- HttpClientResponse forwards ----
//   @override X509Certificate? get certificate => _inner.certificate;
//   @override HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;
//   @override int get contentLength => _inner.contentLength;
//   @override List<Cookie> get cookies => _inner.cookies;
//   @override HttpHeaders get headers => _inner.headers;
//   @override bool get isRedirect => _inner.isRedirect;
//   @override bool get persistentConnection => _inner.persistentConnection;
//   @override String get reasonPhrase => _inner.reasonPhrase;
//   @override List<RedirectInfo> get redirects => _inner.redirects;
//   @override int get statusCode => _inner.statusCode;
//   @override HttpClientResponseCompressionState get compressionState => _inner.compressionState;
//   @override Future<Socket> detachSocket() => _inner.detachSocket();
//   @override
//   Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followLoops]) {
//     // redirected response ko bhi tee/wrap karo
//     return _inner.redirect(method, url, followLoops)
//         .then((res) => _TeeHttpClientResponse(res));
//   }
//
//   // ---- Stream tee ----
//   @override
//   StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
//       {Function? onError, void Function()? onDone, bool? cancelOnError}) {
//     return _inner.listen((chunk) {
//       _buf.addAll(chunk);               // copy for tee
//       if (onData != null) onData(chunk); // forward to consumer
//     }, onError: onError, onDone: () async {
//       try {
//         final body = _safeDecodeUtf8(_buf);
//         unawaited(SessionGuard.scan(statusCode: statusCode, body: body));
//       } catch (_) {
//         unawaited(SessionGuard.scan(statusCode: statusCode));
//       }
//       if (onDone != null) onDone();
//     }, cancelOnError: cancelOnError);
//   }
//
//   String _safeDecodeUtf8(List<int> bytes) {
//     try {
//       return conv.utf8.decode(bytes);
//     } catch (_) {
//       return String.fromCharCodes(bytes);
//     }
//   }
// }
