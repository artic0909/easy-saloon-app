import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:get/get.dart';

class ScratchCardModal extends StatefulWidget {
  final int totalConfirmedBookings;
  
  const ScratchCardModal({super.key, required this.totalConfirmedBookings});

  @override
  State<ScratchCardModal> createState() => _ScratchCardModalState();
}

class _ScratchCardModalState extends State<ScratchCardModal> {
  final ApiService _apiService = ApiService();
  bool _isClaimed = false;
  bool _isLoading = false;
  String? _claimMessage;

  String _getSuffix(int number) {
    if ([11, 12, 13].contains(number % 100)) {
      return 'th';
    }
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  Future<void> _claimReward() async {
    if (_isClaimed || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.dio.post('/user/claim-scratch-card');
      if (response.data['status'] == true) {
        setState(() {
          _isClaimed = true;
          _isLoading = false;
          _claimMessage = response.data['message'] ?? 'Reward claimed!';
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        Get.snackbar('Oops', response.data['message'] ?? 'Failed to claim reward');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error claiming scratch card: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    int nextBooking = widget.totalConfirmedBookings + 1;
    String currentBookingText = '${widget.totalConfirmedBookings}${_getSuffix(widget.totalConfirmedBookings)}';
    String nextBookingText = '$nextBooking${_getSuffix(nextBooking)} Booking';
    bool isFreeBookingReward = widget.totalConfirmedBookings > 1 && widget.totalConfirmedBookings % 10 == 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
                fontFamily: 'Playfair Display',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scratch the card below to reveal your surprise reward for your $currentBookingText booking!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Scratcher(
                  brushSize: 40,
                  threshold: 40,
                  color: AppColors.primary,
                  onThreshold: _claimReward,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    color: const Color(0xFFFDFBF7),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isFreeBookingReward ? 'FREE' : 'REWARD',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          isFreeBookingReward ? '$nextBookingText!' : 'Wallet Cash!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.primary),
            ],
            if (_isClaimed) ...[
              const SizedBox(height: 24),
              Text(
                _claimMessage ?? (isFreeBookingReward ? 'You have unlocked a FREE eligible service on your next booking!' : 'Better luck next time!'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'AWESOME!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
