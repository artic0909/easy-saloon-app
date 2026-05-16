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
import 'package:easysaloonapp/features/home/presentation/pages/service_detail_screen.dart';
import 'package:easysaloonapp/features/dashboard/presentation/pages/staff_dashboard.dart';
import 'package:easysaloonapp/features/dashboard/presentation/pages/admin_dashboard.dart';
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
            GetPage(name: '/packages', page: () => const PackagesScreen()),
            GetPage(name: '/service-detail', page: () => const ServiceDetailScreen()),
            GetPage(name: '/staff-dashboard', page: () => const StaffDashboard()),
            GetPage(name: '/admin-dashboard', page: () => const AdminDashboard()),
          ],
        );
      },
    );
  }
}
