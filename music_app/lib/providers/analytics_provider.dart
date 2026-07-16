import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CountryData {
  final String country;
  final int count;
  final double percentage;

  CountryData({
    required this.country,
    required this.count,
    required this.percentage,
  });

  factory CountryData.fromJson(Map<String, dynamic> json) {
    return CountryData(
      country: json['country'] ?? 'Desconocido',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class DailyData {
  final String date;
  final int views;

  DailyData({required this.date, required this.views});

  factory DailyData.fromJson(Map<String, dynamic> json) {
    return DailyData(
      date: json['date'] ?? '',
      views: json['views'] ?? 0,
    );
  }
}

class SongPercentage {
  final String id;
  final String title;
  final int plays;
  final double percentage;

  SongPercentage({
    required this.id,
    required this.title,
    required this.plays,
    required this.percentage,
  });

  factory SongPercentage.fromJson(Map<String, dynamic> json) {
    return SongPercentage(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      plays: json['plays'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class TopSong {
  final int rank;
  final String id;
  final String title;
  final int plays;

  TopSong({
    required this.rank,
    required this.id,
    required this.title,
    required this.plays,
  });

  factory TopSong.fromJson(Map<String, dynamic> json) {
    return TopSong(
      rank: json['rank'] ?? 0,
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      plays: json['plays'] ?? 0,
    );
  }
}

class HourlyData {
  final int hour;
  final int views;

  HourlyData({required this.hour, required this.views});

  factory HourlyData.fromJson(Map<String, dynamic> json) {
    return HourlyData(
      hour: json['hour'] ?? 0,
      views: json['views'] ?? 0,
    );
  }
}

class WeekdayData {
  final String day;
  final int views;

  WeekdayData({required this.day, required this.views});

  factory WeekdayData.fromJson(Map<String, dynamic> json) {
    return WeekdayData(
      day: json['day'] ?? '',
      views: json['views'] ?? 0,
    );
  }
}

class SummaryData {
  final int totalStreamsLast30;
  final int avgDaily;
  final String bestDayDate;
  final int bestDayViews;

  SummaryData({
    required this.totalStreamsLast30,
    required this.avgDaily,
    required this.bestDayDate,
    required this.bestDayViews,
  });

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    return SummaryData(
      totalStreamsLast30: json['totalStreamsLast30'] ?? 0,
      avgDaily: json['avgDaily'] ?? 0,
      bestDayDate: json['bestDay']?['date'] ?? '',
      bestDayViews: json['bestDay']?['views'] ?? 0,
    );
  }
}

class AnalyticsData {
  final int totalSongs;
  final int totalPlays;
  final List<SongPercentage> songsWithPercentage;
  final List<DailyData> dailyChart;
  final List<TopSong> topSongs;
  final List<CountryData> countries;
  final List<HourlyData> hourlyChart;
  final List<WeekdayData> weekdayChart;
  final SummaryData summary;

  AnalyticsData({
    required this.totalSongs,
    required this.totalPlays,
    required this.songsWithPercentage,
    required this.dailyChart,
    required this.topSongs,
    required this.countries,
    required this.hourlyChart,
    required this.weekdayChart,
    required this.summary,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      totalSongs: json['totalSongs'] ?? 0,
      totalPlays: json['totalPlays'] ?? 0,
      songsWithPercentage: (json['songsWithPercentage'] as List?)
              ?.map((e) => SongPercentage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dailyChart: (json['dailyChart'] as List?)
              ?.map((e) => DailyData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topSongs: (json['topSongs'] as List?)
              ?.map((e) => TopSong.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      countries: (json['countries'] as List?)
              ?.map((e) => CountryData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      hourlyChart: (json['hourlyChart'] as List?)
              ?.map((e) => HourlyData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      weekdayChart: (json['weekdayChart'] as List?)
              ?.map((e) => WeekdayData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summary: SummaryData.fromJson(json['summary'] ?? {}),
    );
  }
}

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsData? _data;
  bool _isLoading = false;
  String? _error;

  AnalyticsData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMetrics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final json = await ApiService.get('/analytics/creator');
      _data = AnalyticsData.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      _error = e.toString();
      _data = null;
    }

    _isLoading = false;
    notifyListeners();
  }
}