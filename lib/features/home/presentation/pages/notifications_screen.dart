import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await _apiService.dio.get('/notifications');
      if (response.data['status'] == 'success') {
        setState(() {
          _notifications = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching notifications: $e");
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _apiService.dio.post('/notifications/$id/read');
      _fetchNotifications(); // Refresh list
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Notifications",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: EdgeInsets.all(24.w),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return _buildNotificationItem(item);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 64, color: Colors.white10),
          SizedBox(height: 16.h),
          Text("All caught up!", style: TextStyle(color: Colors.white38, fontSize: 14.sp)),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(dynamic item) {
    final bool isUnread = item['read_at'] == null;
    
    return InkWell(
      onTap: () {
        if (isUnread) _markAsRead(item['id']);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread ? AppColors.primary.withValues(alpha: 0.1) : Colors.white10,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUnread ? AppColors.primary.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(item['icon']),
                color: isUnread ? AppColors.primary : Colors.white38,
                size: 20,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['title'] ?? 'Notification',
                        style: TextStyle(
                          color: isUnread ? Colors.white : Colors.white60,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        item['created_at'] ?? '',
                        style: TextStyle(color: Colors.white24, fontSize: 10.sp),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item['message'] ?? '',
                    style: TextStyle(
                      color: isUnread ? Colors.white70 : Colors.white38,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'bell':
        return Icons.notifications;
      case 'card':
        return Icons.credit_card;
      case 'gift':
        return Icons.card_giftcard;
      case 'cut':
        return Icons.content_cut;
      default:
        return Icons.info_outline;
    }
  }
}
