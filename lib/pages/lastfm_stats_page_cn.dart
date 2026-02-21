import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/lastfm_api.dart';

enum TimePeriod {
  week('7day', '周'),
  month('1month', '月'),
  year('12month', '年');

  final String value;
  final String label;
  const TimePeriod(this.value, this.label);
}

class LastFMStatsPageCN extends StatefulWidget {
  const LastFMStatsPageCN({super.key});

  @override
  State<LastFMStatsPageCN> createState() => _LastFMStatsPageCNState();
}

class _LastFMStatsPageCNState extends State<LastFMStatsPageCN> {
  final LastFMApi _api = LastFMApi();
  
  TimePeriod _selectedPeriod = TimePeriod.week;
  bool _isLoading = true;
  
  Map<String, dynamic>? _userInfo;
  List<Map<String, dynamic>> _topTracks = [];
  List<Map<String, dynamic>> _topArtists = [];
  
  String _totalPlayTime = '0h 0m';
  int _totalPlays = 0;
  List<int> _activeHours = List.filled(24, 0);
  
  List<int> _dailyPlays = [0, 0, 0, 0, 0, 0, 0];
  
  Map<String, dynamic>? _topTrack;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading data for period: ${_selectedPeriod.value}');
      
      final results = await Future.wait([
        _api.getUserInfo(),
        _api.getTopTracks(limit: 50, period: _selectedPeriod.value),
        _api.getTopArtists(limit: 10, period: _selectedPeriod.value),
      ]);

      final userInfo = results[0] as Map<String, dynamic>;
      final tracks = (results[1] as Map<String, dynamic>)['tracks'] as List<dynamic>? ?? [];
      final artists = (results[2] as Map<String, dynamic>)['artists'] as List<dynamic>? ?? [];

      print('Loaded ${tracks.length} tracks for period ${_selectedPeriod.value}');
      if (tracks.isNotEmpty) {
        print('Top track: ${tracks[0]['name']} - ${tracks[0]['playcount']} plays');
      }

      int totalPlays = 0;
      for (var track in tracks) {
        totalPlays += int.tryParse(track['playcount'] ?? '0') ?? 0;
      }
      final totalMinutes = totalPlays * 3;
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;

      final activeHours = List.filled(24, 0);
      
      switch (_selectedPeriod) {
        case TimePeriod.week:
          for (int i = 0; i < 24; i++) {
            if (i >= 7 && i <= 23) {
              activeHours[i] = ((totalPlays / 20) * (i % 4 + 1)).toInt().clamp(1, 10);
            }
          }
          break;
        case TimePeriod.month:
          for (int i = 0; i < 24; i++) {
            if (i >= 6 && i <= 24) {
              activeHours[i] = ((totalPlays / 25) * (i % 3 + 1)).toInt().clamp(1, 10);
            }
          }
          break;
        case TimePeriod.year:
          for (int i = 0; i < 24; i++) {
            if (i >= 5 && i <= 25) {
              activeHours[i] = ((totalPlays / 30) * (i % 2 + 1)).toInt().clamp(1, 10);
            }
          }
          break;
      }

      final dailyPlays = List.generate(7, (index) {
        final baseValue = totalPlays / 7;
        final variance = (index - 3).abs() * 0.2;
        return (baseValue * (1 + variance)).toInt();
      });

      final topTrack = tracks.isNotEmpty ? tracks.first : null;

      setState(() {
        _userInfo = userInfo;
        _topTracks = tracks.cast<Map<String, dynamic>>();
        _topArtists = artists.cast<Map<String, dynamic>>();
        _totalPlayTime = '$hours h $minutes m';
        _totalPlays = totalPlays;
        _activeHours = activeHours;
        _dailyPlays = dailyPlays;
        _topTrack = topTrack;
        _isLoading = false;
      });
      
      print('Data loaded successfully. Total plays: $totalPlays');
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    }
  }

  void _onPeriodChanged(TimePeriod period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final greenColor = const Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('听歌历程'),
        backgroundColor: greenColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: greenColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: TimePeriod.values.asMap().entries.map((entry) {
                          final index = entry.key;
                          final period = entry.value;
                          final isSelected = _selectedPeriod == period;
                          final isFirst = index == 0;
                          final isLast = index == TimePeriod.values.length - 1;
                          
                          return GestureDetector(
                            onTap: () => _onPeriodChanged(period),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? greenColor : Colors.transparent,
                                borderRadius: BorderRadius.only(
                                  topLeft: isFirst ? const Radius.circular(19) : Radius.zero,
                                  bottomLeft: isFirst ? const Radius.circular(19) : Radius.zero,
                                  topRight: isLast ? const Radius.circular(19) : Radius.zero,
                                  bottomRight: isLast ? const Radius.circular(19) : Radius.zero,
                                ),
                                border: index > 0
                                    ? Border(left: BorderSide(
                                        color: isSelected ? Colors.white : greenColor,
                                        width: 1,
                                      ))
                                    : null,
                              ),
                              child: Text(
                                period.label,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : greenColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '最顶歌曲',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_topTrack == null)
                                  const Center(
                                    child: Text(
                                      '暂无数据',
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          image: _topTrack!['image'] != null && (_topTrack!['image'] as List).isNotEmpty && (_topTrack!['image'] as List).isNotEmpty
                                              ? DecorationImage(
                                                  image: CachedNetworkImageProvider(
                                                    (_topTrack!['image'] as List).last as String,
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                          color: greenColor.withOpacity(0.1),
                                        ),
                                        child: _topTrack == null || _topTrack!['image'] == null || (_topTrack!['image'] as List).isEmpty
                                            ? const Icon(
                                                Icons.music_note,
                                                size: 40,
                                                color: Colors.grey,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _topTrack!['name'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              _topTrack!['artist'] ?? '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '数据概览',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          const Text(
                                            '播放总时长',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _totalPlayTime,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          const Text(
                                            '记录次数',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '$_totalPlays',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '活跃时间',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 40,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(24, (hour) {
                                      final intensity = (_activeHours[hour] / 10.0).clamp(0.0, 1.0);
                                      final periodColor = _getPeriodColor();
                                      return Container(
                                        width: 2,
                                        height: 40 * intensity,
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: BoxDecoration(
                                          color: periodColor.withOpacity(intensity),
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          if (_selectedPeriod == TimePeriod.week)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '听歌趋势',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 200,
                                    child: BarChart(
                                      BarChartData(
                                        alignment: BarChartAlignment.spaceAround,
                                        maxY: _dailyPlays.isNotEmpty
                                            ? _dailyPlays.reduce((a, b) => a > b ? a : b) * 1.2
                                            : 20,
                                        minY: 0,
                                        barGroups: _dailyPlays.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final value = entry.value;
                                          
                                          return BarChartGroupData(
                                            x: index,
                                            barRods: [
                                              BarChartRodData(
                                                toY: value.toDouble(),
                                                color: greenColor,
                                                width: 20,
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(4),
                                                  topRight: Radius.circular(4),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                final days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
                                                if (value.toInt() >= days.length) {
                                                  return const SizedBox.shrink();
                                                }
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 8),
                                                  child: Text(
                                                    days[value.toInt()],
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                );
                                              },
                                              reservedSize: 30,
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 40,
                                              getTitlesWidget: (value, meta) {
                                                return Text(
                                                  value.toInt().toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.black,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          topTitles: AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          rightTitles: AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        gridData: FlGridData(show: true),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 16),
                          
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    _getHotTracksTitle(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                ..._topTracks.take(5).toList().asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final track = entry.value;
                                  
                                  return ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: greenColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: greenColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      track['name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    subtitle: Text(
                                      track['artist'] ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Color _getPeriodColor() {
    switch (_selectedPeriod) {
      case TimePeriod.week:
        return const Color(0xFF2196F3);
      case TimePeriod.month:
        return const Color(0xFFFF9800);
      case TimePeriod.year:
        return const Color(0xFF9C27B0);
    }
  }

  String _getHotTracksTitle() {
    switch (_selectedPeriod) {
      case TimePeriod.week:
        return '本周热歌';
      case TimePeriod.month:
        return '本月热歌';
      case TimePeriod.year:
        return '本年热歌';
    }
  }
}
