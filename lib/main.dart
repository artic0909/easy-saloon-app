import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/theme/app_theme.dart';
import 'package:easysaloonapp/features/auth/presentation/pages/splash_screen.dart';
import 'package:easysaloonapp/features/auth/presentation/pages/login_screen.dart';
import 'package:easysaloonapp/features/auth/presentation/pages/register_screen.dart';
import 'package:easysaloonapp/features/home/presentation/pages/home_page.dart';
import 'package:easysaloonapp/features/home/presentation/pages/notifications_screen.dart';
import 'package:easysaloonapp/features/home/presentation/pages/coupons_screen.dart';
import 'package:easysaloonapp/features/home/presentation/pages/services_screen.dart';
import 'package:easysaloonapp/features/home/presentation/pages/packages_screen.dart';
import 'package:easysaloonapp/features/home/presentation/pages/category_screen.dart';
import 'package:easysaloonapp/features/home/presentation/pages/profile_screen.dart';
import 'package:easysaloonapp/features/home/presentation/pages/service_detail_screen.dart';
import 'package:easysaloonapp/features/home/presentation/pages/package_detail_screen.dart';
import 'package:easysaloonapp/features/home/presentation/pages/custom_package_screen.dart';
import 'package:easysaloonapp/features/home/presentation/pages/checkout_screen.dart';
import 'package:easysaloonapp/features/home/presentation/pages/wallet/wallet.dart';
import 'package:easysaloonapp/features/home/presentation/pages/wallet/transactions.dart';
import 'package:easysaloonapp/features/home/presentation/pages/bookings/mybookings.dart';
import 'package:easysaloonapp/features/home/presentation/pages/bookings/booking_details.dart';
import 'package:easysaloonapp/features/staff/dashboard.dart';
import 'package:easysaloonapp/features/staff/bookings/upcoming.dart';
import 'package:easysaloonapp/features/staff/bookings/pending.dart';
import 'package:easysaloonapp/features/staff/bookings/today.dart';
import 'package:easysaloonapp/features/staff/bookings/complete.dart';
import 'package:easysaloonapp/features/staff/bookings/cancel.dart';
import 'package:easysaloonapp/features/staff/bookings/booking_details.dart';
import 'package:easysaloonapp/features/admin/dashboard.dart';
import 'package:easysaloonapp/features/admin/bookings/open.dart';
import 'package:easysaloonapp/features/admin/bookings/ontheway.dart';
import 'package:easysaloonapp/features/admin/bookings/complete.dart';
import 'package:easysaloonapp/features/admin/bookings/cancel.dart';
import 'package:easysaloonapp/features/admin/bookings/booking_details.dart';
import 'package:easysaloonapp/features/admin/coupons/coupons.dart';
import 'package:easysaloonapp/features/admin/coupons/add_edit.dart';
import 'package:easysaloonapp/features/admin/staff/staff.dart';
import 'package:easysaloonapp/features/admin/staff/add_edit.dart';
import 'package:easysaloonapp/features/admin/services/categories/all_show.dart';
import 'package:easysaloonapp/features/auth/data/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync(() => AuthService().init());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Easy Saloon',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const SplashScreen()),
            GetPage(name: '/login', page: () => const LoginScreen()),
            GetPage(name: '/register', page: () => const RegisterScreen()),
            GetPage(name: '/home', page: () => const HomePage()),
            GetPage(name: '/notifications', page: () => const NotificationsScreen()),
            GetPage(name: '/coupons', page: () => const CouponsScreen()),
            GetPage(name: '/services', page: () => const ServicesScreen()),
            GetPage(name: '/categories', page: () => const CategoryScreen()),
            GetPage(name: '/profile', page: () => const ProfileScreen()),
            GetPage(name: '/packages', page: () => const PackagesScreen()),
            GetPage(name: '/service-detail', page: () => const ServiceDetailScreen()),
            GetPage(name: '/package-detail', page: () => const PackageDetailScreen()),
            GetPage(name: '/custom-package', page: () => const CustomPackageScreen()),
            GetPage(name: '/checkout', page: () => const CheckoutScreen()),
            GetPage(name: '/wallet', page: () => const WalletScreen()),
            GetPage(name: '/wallet-transactions', page: () => const WalletTransactionsScreen()),
            GetPage(name: '/my-bookings', page: () => const MyBookingsPage()),
            GetPage(name: '/booking-details', page: () => const BookingDetailsPage()),
            GetPage(name: '/staff-dashboard', page: () => const StaffDashboard()),
            GetPage(name: '/staff-bookings-upcoming', page: () => const StaffUpcomingBookingsPage()),
            GetPage(name: '/staff-bookings-today', page: () => const StaffTodayBookingsPage()),
            GetPage(name: '/staff-bookings-pending', page: () => const StaffPendingBookingsPage()),
            GetPage(name: '/staff-bookings-complete', page: () => const StaffCompleteBookingsPage()),
            GetPage(name: '/staff-bookings-cancel', page: () => const StaffCancelBookingsPage()),
            GetPage(name: '/staff-booking-details', page: () => const StaffBookingDetailsPage()),
            GetPage(name: '/admin-dashboard', page: () => const AdminDashboard()),
            GetPage(name: '/admin-bookings-open', page: () => const AdminOpenBookingsPage()),
            GetPage(name: '/admin-bookings-ontheway', page: () => const AdminOnTheWayBookingsPage()),
            GetPage(name: '/admin-bookings-complete', page: () => const AdminCompleteBookingsPage()),
            GetPage(name: '/admin-bookings-cancel', page: () => const AdminCancelBookingsPage()),
            GetPage(name: '/admin-booking-details', page: () => const AdminBookingDetailsPage()),
            GetPage(name: '/admin-manage-offers', page: () => const AdminCouponsScreen()),
            GetPage(name: '/admin-add-edit-offer', page: () => const AdminAddEditCouponScreen()),
            GetPage(name: '/admin-manage-staffs', page: () => const AdminManageStaffScreen()),
            GetPage(name: '/admin-add-edit-staff', page: () => const AdminAddEditStaffScreen()),
            GetPage(name: '/admin-manage-services', page: () => CategoryListScreen()),
          ],
        );
      },
    );
  }
}
