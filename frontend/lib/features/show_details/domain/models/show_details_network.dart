import 'package:equatable/equatable.dart';

final class ShowDetailsNetwork extends Equatable {
  const ShowDetailsNetwork({
    required this.tmdbId,
    required this.name,
    required this.originCountry,
    this.logoPath,
    this.logoUrl,
  });

  final int tmdbId;

  final String name;

  final String? logoPath;
  final String? logoUrl;

  final String originCountry;

  @override
  List<Object?> get props => <Object?>[
    tmdbId,
    name,
    logoPath,
    logoUrl,
    originCountry,
  ];
}
