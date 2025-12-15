import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class DioHelper {
  static DioHelper? _instance;
  late Dio _dio;
  final CookieJar? _cookieJar = kIsWeb ? null : CookieJar();

  DioHelper._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Add pretty logger interceptor
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );

    // Add cookie management interceptor (skip on web)
    if (!kIsWeb) {
      final cookieJar = _cookieJar;
      if (cookieJar != null) {
        _dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              // Add cookies from jar
              final uri = options.uri;
              final cookies = await cookieJar.loadForRequest(uri);
              if (cookies.isNotEmpty) {
                options.headers['Cookie'] = cookies
                    .map((c) => '${c.name}=${c.value}')
                    .join('; ');
              }
              return handler.next(options);
            },
            onResponse: (response, handler) async {
              // Save cookies from response
              final uri = response.requestOptions.uri;
              final setCookieHeaders = response.headers['set-cookie'];
              if (setCookieHeaders != null) {
                for (final setCookie in setCookieHeaders) {
                  final cookie = Cookie.fromSetCookieValue(setCookie);
                  await cookieJar.saveFromResponse(uri, [cookie]);
                }
              }
              return handler.next(response);
            },
          ),
        );
      }
    }
  }

  static DioHelper get instance {
    _instance ??= DioHelper._internal();
    return _instance!;
  }

  Dio get dio => _dio;

  // Get method
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _dio.get(
      url,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  // Post method
  Future<Response> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _dio.post(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  // Put method
  Future<Response> put(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await _dio.put(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  // Delete method
  Future<Response> delete(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.delete(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // Clear all cookies
  Future<void> clearCookies() async {
    if (!kIsWeb) {
      final cookieJar = _cookieJar;
      if (cookieJar != null) {
        await cookieJar.deleteAll();
      }
    }
  }

  // Get cookies for a specific URL
  Future<List<Cookie>> getCookies(Uri uri) async {
    if (!kIsWeb) {
      final cookieJar = _cookieJar;
      if (cookieJar != null) {
        return await cookieJar.loadForRequest(uri);
      }
    }
    return [];
  }
}
