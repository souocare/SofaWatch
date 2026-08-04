import 'package:equatable/equatable.dart';

class ServerConfiguration extends Equatable {
  const ServerConfiguration({
    required this.serverName,
    required this.serverUrl,
    this.acceptSelfSignedCertificates = false,
  });
  factory ServerConfiguration.fromJson(Map<String, dynamic> json) {
    return ServerConfiguration(
      serverName: json['serverName'] as String,
      serverUrl: Uri.parse(json['serverUrl'] as String),
      acceptSelfSignedCertificates:
          json['acceptSelfSignedCertificates'] as bool? ?? false,
    );
  }

  final String serverName;

  final Uri serverUrl;

  final bool acceptSelfSignedCertificates;

  @override
  List<Object> get props => [
    serverName,
    serverUrl,
    acceptSelfSignedCertificates,
  ];

  ServerConfiguration copyWith({
    String? serverName,
    Uri? serverUrl,
    bool? acceptSelfSignedCertificates,
  }) {
    return ServerConfiguration(
      serverName: serverName ?? this.serverName,
      serverUrl: serverUrl ?? this.serverUrl,
      acceptSelfSignedCertificates:
          acceptSelfSignedCertificates ?? this.acceptSelfSignedCertificates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverName': serverName,
      'serverUrl': serverUrl.toString(),
      'acceptSelfSignedCertificates': acceptSelfSignedCertificates,
    };
  }
}
