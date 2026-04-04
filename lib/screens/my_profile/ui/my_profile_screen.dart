import 'package:arianth/screens/my_profile/ui/buyer_profile_screen.dart';
import 'package:arianth/screens/my_profile/ui/craftsman_profile_screen.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:flutter/material.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = SharedPreferencesHelper().getString("role") ?? '';
    
    if (role == 'craftsman') {
      return const CraftsmanProfileScreen();
    } else {
      return const BuyerProfileScreen();
    }
  }
}
